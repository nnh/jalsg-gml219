**********************************************************************;
* Project      : JALSG-GML219
* Program name : JALSG-GML219_STAT_Table8_4.4.10d.PostTx.sas
* Author       : AKIKO SAITO
* Date created : 20260505
* Description  : 後治療 (SAP 4.4.10d / 5.4.17)
*                放射線療法・造血細胞移植・移植時病期・移植片種類・
*                ドナー・HLA一致度・前処置・JMDP登録・TRUMP番号
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

%let output = &_wk_path.\output;
%let log    = &_wk_path.\log;

proc printto log="&log.\JALSG-GML219_STAT_Table8_&DATE..log" new; run;

options validvarname=v7 fmtsearch=(libout work) nofmterr
        nomlogic nosymbolgen nomprint ls=180 missing="" pageno=1
        nodate nonumber;

data SAF;
  set libraw.gml219;
  where saffl = "Y";
run;

proc sql noprint;
  select count(*) into :n_saf trimmed from SAF;
quit;

proc format;
  value $ynfm 'N'='なし' 'Y'='あり' 'NA'='評価不能' ' '='-';
  value $jmdpfm
       'Y'='あり'
       'N'='なし'
       'No'='なし'
       'Yes'='あり'
       'NA'='不明'
       ' '='-';
run;

TITLE1 'JALSG-GML219';
ods rtf file="&output.\JALSG-GML219 Table8_&DATE..rtf" style=listing;
ods escapechar='^';
footnote2 "^S={just=r} 出力日 &DATE";

/*=====================================================================*/
/* (1) 放射線療法 / 造血細胞移植 実施有無                               */
/*=====================================================================*/
title2 "(1) 放射線療法・造血細胞移植 実施有無 (SAF n=&n_saf)";
proc tabulate data=SAF missing;
  class pttx_radio_fl pttx_hsct_fl;
  table (pttx_radio_fl pttx_hsct_fl),
        all='全体' * (n pctn='%'*f=8.1)
  / misstext='0';
  format pttx_radio_fl pttx_hsct_fl $ynfm.;
run;

/*=====================================================================*/
/* (2) 移植時病期（pttx_beftrans：1CR/2CR/NON-CR/その他）              */
/*=====================================================================*/
title2 "(2) 移植時病期 (移植実施例のみ)";
proc tabulate data=SAF(where=(pttx_hsct_fl="Y")) missing;
  class pttx_beftrans / order=data;
  table pttx_beftrans,
        all='全体' * (n pctn='%'*f=8.1)
  / misstext='0';
run;

/*=====================================================================*/
/* (3) 移植片種類（pttx_graft：骨髄/末梢血/臍帯血/その他）              */
/*=====================================================================*/
title2 "(3) 移植片種類 (移植実施例のみ)";
proc tabulate data=SAF(where=(pttx_hsct_fl="Y")) missing;
  class pttx_graft / order=data;
  table pttx_graft,
        all='全体' * (n pctn='%'*f=8.1)
  / misstext='0';
run;

/*=====================================================================*/
/* (4) ドナー情報（pttx_donor：血縁/非血縁）                            */
/*=====================================================================*/
title2 "(4) ドナー情報 (移植実施例のみ)";
proc tabulate data=SAF(where=(pttx_hsct_fl="Y")) missing;
  class pttx_donor / order=data;
  table pttx_donor,
        all='全体' * (n pctn='%'*f=8.1)
  / misstext='0';
run;

/*=====================================================================*/
/* (5) HLA一致度（pttx_hla：6/6, 5/6, 4/6, 半合致）                    */
/*=====================================================================*/
title2 "(5) HLA一致度 (移植実施例のみ)";
proc tabulate data=SAF(where=(pttx_hsct_fl="Y")) missing;
  class pttx_hla / order=data;
  table pttx_hla,
        all='全体' * (n pctn='%'*f=8.1)
  / misstext='0';
run;

/*=====================================================================*/
/* (6) 移植前処置（pttx_cond：骨髄破壊的/非破壊的）                    */
/*=====================================================================*/
title2 "(6) 移植前処置 (移植実施例のみ)";
proc tabulate data=SAF(where=(pttx_hsct_fl="Y")) missing;
  class pttx_cond / order=data;
  table pttx_cond,
        all='全体' * (n pctn='%'*f=8.1)
  / misstext='0';
run;

/*=====================================================================*/
/* (7) JMDPバンク登録                                                   */
/*=====================================================================*/
title2 "(7) JMDPバンク登録 (SAF n=&n_saf)";
proc tabulate data=SAF missing;
  class pttx_jmdp;
  table pttx_jmdp,
        all='全体' * (n pctn='%'*f=8.1)
  / misstext='0';
  format pttx_jmdp $jmdpfm.;
run;

/*=====================================================================*/
/* (8) 後治療 一覧（個別症例レベル）                                    */
/*=====================================================================*/
title2 "(8) 後治療 一覧（実施例のみ）";
proc print data=SAF(where=(pttx_radio_fl="Y" or pttx_hsct_fl="Y")) noobs label;
  var usubjid
      pttx_radio_fl pttx_radio_dt
      pttx_hsct_fl  pttx_hsct_dt
      pttx_beftrans pttx_graft pttx_donor pttx_hla pttx_cond pttx_cond_dt
      pttx_jmdp pttx_trump;
run;

ods rtf close;
proc printto; run;