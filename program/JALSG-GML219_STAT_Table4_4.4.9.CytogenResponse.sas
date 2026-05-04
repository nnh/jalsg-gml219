**********************************************************************;
* Project      : JALSG-GML219
* Program name : JALSG-GML219_STAT_Table4_4.4.9.CytogenResponse.sas
* Author       : AKIKO SAITO
* Date created : 20260504
* Description  : 細胞遺伝学的反応性 WT-1 mRNA (SAP 4.4.9)
**********************************************************************;
title; footnote;
proc datasets library=work kill nolist; quit;

%macro working_dir;
  %local _fullpath _path;
  %let _fullpath=; %let _path=;
  %if %length(%sysfunc(getoption(sysin)))=0 %then
      %let _fullpath=%sysget(sas_execfilepath);
  %else %let _fullpath=%sysfunc(getoption(sysin));
  %let _path=%substr(&_fullpath.,1,%length(&_fullpath.)
              -%length(%scan(&_fullpath.,-1,\))
              -%length(%scan(&_fullpath.,-2,\))-2);
  &_path.
%mend working_dir;

%let _wk_path=%working_dir;
%let DATE=%sysfunc(today(),yymmddn8.);
libname libraw "&_wk_path.\input\ads" access=readonly;
%let output=&_wk_path.\output;
%let log=&_wk_path.\log;

proc printto log="&log.\JALSG-GML219_STAT_Table4_&DATE..log" new; run;

options validvarname=v7 nofmterr nomlogic nosymbolgen nomprint
        ls=100 missing="" pageno=1 nodate nonumber;

data gml219; set libraw.gml219; run;
data FAS; set gml219; where fasfl="Y"; run;

/*--- WT-1 mRNA を縦持ちに変換 ---*/
data wt1_long;
  set FAS;
  length timepoint  ord 8.;

  if wt1_bl ne . then do;
    timepoint="Baseline"; ord=1; wt1=wt1_bl; output;
  end;
  if wt1_ev1 ne . then do;
    timepoint="評価1（寛解導入1回後）"; ord=2; wt1=wt1_ev1; output;
  end;
  if wt1_ev2 ne . then do;
    timepoint="評価2（寛解導入2回後）"; ord=3; wt1=wt1_ev2; output;
  end;
  if wt1_ev3 ne . then do;
    timepoint="評価3（地固め1回後）"; ord=4; wt1=wt1_ev3; output;
  end;
  if wt1_ev4 ne . then do;
    timepoint="評価4（地固め2回後）"; ord=5; wt1=wt1_ev4; output;
  end;
  if wt1_ev5 ne . then do;
    timepoint="評価5（地固め3回後）"; ord=6; wt1=wt1_ev5; output;
  end;
  if wt1_relapse ne . then do;
    timepoint="再発時"; ord=7; wt1=wt1_relapse; output;
  end;

  keep usubjid ord timepoint wt1;
run;

proc sort data=wt1_long; by ord; run;

TITLE1 'JALSG-GML219';
ods rtf file="&output.\JALSG-GML219 Table4_&DATE..rtf" style=listing;
ods escapechar='^';
footnote2 "^S={just=r} 出力日 &DATE";

title2 'WT-1 mRNA 測定値 (SAP 4.4.9)';
title3 '解析対象集団: FAS';

/*--- 各時点の記述統計 ---*/
proc tabulate data=wt1_long;
  class ord timepoint;
  var wt1;
  table
    ord*timepoint,
    wt1 * (n*f=8.
            mean*f=10.1
            std='SD'*f=10.1
            q1='Q1'*f=10.1
            median*f=10.1
            q3='Q3'*f=10.1
            min*f=10.1
            max*f=10.1)
  / misstext='.';
  label wt1='WT-1 mRNA（コピー/μg RNA）'
        timepoint='評価時点';
run;

/*--- ベースラインからの変化量（CR例） ---*/
title3 'WT-1 mRNA ベースラインからの変化量（CR到達例）';

data wt1_cr;
  set FAS;
  where crfl="Y" and wt1_bl ne .;
  chg_ev1 = wt1_ev1 - wt1_bl;
  chg_ev2 = wt1_ev2 - wt1_bl;
  chg_ev3 = wt1_ev3 - wt1_bl;
  chg_ev4 = wt1_ev4 - wt1_bl;
  chg_ev5 = wt1_ev5 - wt1_bl;
  label
    chg_ev1='変化量: Baseline→評価1'
    chg_ev2='変化量: Baseline→評価2'
    chg_ev3='変化量: Baseline→評価3'
    chg_ev4='変化量: Baseline→評価4'
    chg_ev5='変化量: Baseline→評価5';
run;

proc tabulate data=wt1_cr;
  var chg_ev1 chg_ev2 chg_ev3 chg_ev4 chg_ev5;
  table
    (chg_ev1 chg_ev2 chg_ev3 chg_ev4 chg_ev5),
    (n*f=8. mean*f=10.1 std='SD'*f=10.1 median*f=10.1
     min*f=10.1 max*f=10.1)
  / misstext='.';
run;

ods rtf close;
proc printto; run;