**********************************************************************;
* Project      : JALSG-GML219
* Program name : JALSG-GML219_STAT_Table7_4.4.10c.Death.sas
* Author       : AKIKO SAITO
* Date created : 20260505
* Description  : 死亡の詳細 (SAP 4.4.10c / 5.4.16)
*                腫瘍死 / 移植関連死 / 非腫瘍死 (移植関連以外) 内訳
**********************************************************************;

title;
footnote;
proc datasets library=work kill nolist; quit;

%macro working_dir;
    %local _fullpath _path;
    %let   _fullpath = ;
    %let   _path     = ;
    %if %length(%sysfunc(getoption(sysin))) = 0 %then
        %let _fullpath = %sysget(sas_execfilepath);
    %else
        %let _fullpath = %sysfunc(getoption(sysin));
    %let _path = %substr(   &_fullpath., 1, %length(&_fullpath.)
                          - %length(%scan(&_fullpath.,-1,'\'))
                          - %length(%scan(&_fullpath.,-2,'\'))
                          - 2 );
    &_path.
%mend working_dir;

%let _wk_path = %working_dir;
%let DATE = %sysfunc(today(), yymmddn8.);

libname libraw "&_wk_path.\input\ads" access=readonly;
libname libout "&_wk_path.\output";

%let output  = &_wk_path.\output;
%let log     = &_wk_path.\log;
%let rawdir  = &_wk_path.\input\rawdata;

proc printto log="&log.\JALSG-GML219_STAT_Table7_&DATE..log" new; run;

options validvarname=v7 fmtsearch=(libout work) nofmterr
        nomlogic nosymbolgen nomprint ls=180 missing="" pageno=1
        nodate nonumber;

/*--- 入力データ ---*/
data gml219;
  set libraw.gml219;
  where saffl = "Y";
run;

%macro impcsv(dsnm);
  proc import out=&dsnm
    datafile="&rawdir.\&dsnm..csv"
    dbms=csv replace;
    getnames=yes; datarow=2; guessingrows=max;
  run;
%mend;
%impcsv(AE);

/*--- 死亡例の抽出（DS withdrawal で DEATH） ---*/
data deaths;
  set gml219;
  where upcase(strip(dsterm2)) = "DEATH";
  length dthcat $40.;
  if upcase(strip(prcdth)) = "TUMOR DEATH" then dthcat = "腫瘍死";
  else if index(upcase(prcdth), "TRANSPLANTATION RELATED") > 0 then dthcat = "移植関連死";
  else if index(upcase(prcdth), "NON TUMOR DEATH") > 0 then dthcat = "非腫瘍死(移植関連以外)";
  else dthcat = "不明";
  label dthcat = "死亡分類";
run;

proc sql noprint;
  select count(*) into :n_saf  trimmed from gml219;
  select count(*) into :n_dth  trimmed from deaths;
quit;
%put NOTE: SAF=&n_saf, Deaths=&n_dth;

TITLE1 'JALSG-GML219';
ods rtf file="&output.\JALSG-GML219 Table7_&DATE..rtf" style=listing;
ods escapechar='^';
footnote2 "^S={just=r} 出力日 &DATE";

/*=====================================================================*/
/* (1) 死亡分類 n(%)（分母=SAF）                                        */
/*=====================================================================*/
title2 "(1) 死亡分類 n(%) (SAF n=&n_saf)";

proc tabulate data=deaths missing;
  class dthcat / order=data;
  table dthcat, n='件数'*f=8. pctn<dthcat>='%(対SAF)'*f=8.1
  / misstext='0';
run;

/*--- 計算用：分母 SAF=128 で % を表示するため 直接計算 ---*/
proc sql;
  create table dth_summary as
    select dthcat,
           count(*) as n_dth,
           round(100*count(*)/&n_saf, 0.1) as pct format=8.1
    from deaths
    group by dthcat
    order by case dthcat
              when "腫瘍死" then 1
              when "移植関連死" then 2
              when "非腫瘍死(移植関連以外)" then 3
              else 4
            end;
quit;

title3 "（参考）SAF=&n_saf を分母とした割合";
proc print data=dth_summary noobs label;
  label dthcat='死亡分類' n_dth='件数' pct='%';
run;

/*=====================================================================*/
/* (2) 非腫瘍死の死因詳細（AE AESDTH="Y" の AEDECOD 別）                 */
/*=====================================================================*/
data ae_dth(keep=usubjid aedecod);
  set AE;
  where upcase(aesdth) = "Y" and aedecod ne "";
  length aedecod $200.;
run;
proc sort data=ae_dth nodupkey; by usubjid aedecod; run;

/* 非腫瘍死症例のみに絞る */
proc sort data=deaths(keep=usubjid dthcat) out=deaths_key; by usubjid; run;
proc sort data=ae_dth; by usubjid; run;

data ae_dth_join;
  merge ae_dth(in=a) deaths_key(in=b);
  by usubjid;
  if a and b;
run;

title2 '(2) 非腫瘍死 死因詳細（AE AESDTH="Y" 由来）';
title3 "全死亡 n=&n_dth のうち AE 死因記録あり症例";
proc freq data=ae_dth_join order=freq;
  tables aedecod / nocum;
run;

/*=====================================================================*/
/* (3) 死亡一覧（個別症例レベル）                                       */
/*=====================================================================*/
title2 '(3) 死亡一覧（個別症例レベル）';
proc print data=deaths noobs label;
  var usubjid dsstdt2 dthcat prcdth;
  label usubjid='被験者ID' dsstdt2='死亡日' dthcat='死亡分類' prcdth='Primary Cause of Death';
run;

ods rtf close;
proc printto; run;