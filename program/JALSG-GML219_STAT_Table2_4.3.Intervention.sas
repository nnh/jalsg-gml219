**********************************************************************;
* Project      : JALSG-GML219
* Program name : JALSG-GML219_STAT_Table2_4.3.Intervention.sas
* Author       : AKIKO SAITO
* Date created : 20260504
* Date updated : 20260505
* Description  : 投与状況（寛解導入・地固め）＋治療実施割合 (SAP 4.3, 4.4.11)
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

proc printto log="&log.\JALSG-GML219_STAT_Table2_&DATE..log" new; run;

options validvarname=v7 fmtsearch=(libout work) nofmterr
        nomlogic nosymbolgen nomprint ls=120 missing="" pageno=1
        nodate nonumber;

data gml219;
  set libraw.gml219;
run;

/*--- 投与日数を派生 ---*/
data FAS;
  set gml219;
  where FASFL = "Y";
  if ind1stdt ne . and ind1enddt ne . then ind1days = ind1enddt - ind1stdt + 1;
  if ind2stdt ne . and ind2enddt ne . then ind2days = ind2enddt - ind2stdt + 1;
  if c1stdt   ne . and c1enddt   ne . then c1days   = c1enddt   - c1stdt   + 1;
  if c2stdt   ne . and c2enddt   ne . then c2days   = c2enddt   - c2stdt   + 1;
  if c3stdt   ne . and c3enddt   ne . then c3days   = c3enddt   - c3stdt   + 1;
  label ind1days = "寛解導入1 投与期間（日）"
        ind2days = "寛解導入2 投与期間（日）"
        c1days   = "地固め1 投与期間（日）"
        c2days   = "地固め2 投与期間（日）"
        c3days   = "地固め3 投与期間（日）";
run;

proc format;
  value $ynfm 'N'='なし' 'Y'='あり';
run;

TITLE1 'JALSG-GML219';
ods rtf file="&output.\JALSG-GML219 Table2_&DATE..rtf" style=listing;
ods escapechar='^';
footnote2 "^S={just=r} 出力日 &DATE";

/*=====================================================================*/
/* (1) 治療実施フラグ（コース別）                                       */
/*=====================================================================*/
title2 '(1) 治療実施フラグ (FAS)';
proc tabulate data=FAS missing;
  class ind1fl ind2fl c1fl c2fl c3fl titfl;
  table (ind1fl ind2fl c1fl c2fl c3fl titfl),
        all='全体' * (n pctn='%'*f=8.1)
  / misstext='0';
  format ind1fl ind2fl c1fl c2fl c3fl titfl $ynfm.;
run;

/*=====================================================================*/
/* (2) 寛解導入1 (DNR + Ara-C)：用量・期間                              */
/*=====================================================================*/
title2 '(2) 寛解導入療法1 (DNR + Ara-C) ― 投与量・期間';
proc tabulate data=FAS(where=(ind1fl="Y")) missing;
  var ind1dnrdose ind1aradose ind1days;
  table (ind1dnrdose ind1aradose ind1days),
    (n*f=8. mean*f=8.1 std='SD'*f=8.1 min*f=8.1
     q1='25%点'*f=8.1 median*f=8.1 q3='75%点'*f=8.1 max*f=8.1)
  / misstext='.';
run;

/*=====================================================================*/
/* (3) 寛解導入2 (DNR + Ara-C)：用量・期間                              */
/*=====================================================================*/
title2 '(3) 寛解導入療法2 (DNR + Ara-C) ― 投与量・期間';
proc tabulate data=FAS(where=(ind2fl="Y")) missing;
  var ind2dnrdose ind2aradose ind2days;
  table (ind2dnrdose ind2aradose ind2days),
    (n*f=8. mean*f=8.1 std='SD'*f=8.1 min*f=8.1
     q1='25%点'*f=8.1 median*f=8.1 q3='75%点'*f=8.1 max*f=8.1)
  / misstext='.';
run;

/*=====================================================================*/
/* (4) 地固め1 (MIT + Ara-C)：用量・期間                                */
/*=====================================================================*/
title2 '(4) 地固め療法1 (MIT + Ara-C) ― 投与量・期間';
proc tabulate data=FAS(where=(c1fl="Y")) missing;
  var c1mitdose c1aradose c1days;
  table (c1mitdose c1aradose c1days),
    (n*f=8. mean*f=8.1 std='SD'*f=8.1 min*f=8.1
     q1='25%点'*f=8.1 median*f=8.1 q3='75%点'*f=8.1 max*f=8.1)
  / misstext='.';
run;

/*=====================================================================*/
/* (5) 地固め2 (DNR + Ara-C)：用量・期間                                */
/*=====================================================================*/
title2 '(5) 地固め療法2 (DNR + Ara-C) ― 投与量・期間';
proc tabulate data=FAS(where=(c2fl="Y")) missing;
  var c2dnrdose c2aradose c2days;
  table (c2dnrdose c2aradose c2days),
    (n*f=8. mean*f=8.1 std='SD'*f=8.1 min*f=8.1
     q1='25%点'*f=8.1 median*f=8.1 q3='75%点'*f=8.1 max*f=8.1)
  / misstext='.';
run;

/*=====================================================================*/
/* (6) 地固め3 (ACR + Ara-C)：用量・期間                                */
/*=====================================================================*/
title2 '(6) 地固め療法3 (ACR + Ara-C) ― 投与量・期間';
proc tabulate data=FAS(where=(c3fl="Y")) missing;
  var c3acrdose c3aradose c3days;
  table (c3acrdose c3aradose c3days),
    (n*f=8. mean*f=8.1 std='SD'*f=8.1 min*f=8.1
     q1='25%点'*f=8.1 median*f=8.1 q3='75%点'*f=8.1 max*f=8.1)
  / misstext='.';
run;

ods rtf close;
proc printto; run;