**********************************************************************;
* Project      : JALSG-GML219
* Program name : JALSG-GML219_STAT_Table2_4.3.Intervention.sas
* Author       : AKIKO SAITO
* Date created : 20260504
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
        nomlogic nosymbolgen nomprint ls=100 missing="" pageno=1
        nodate nonumber;

data gml219;
  set libraw.gml219;
run;

data FAS;
  set gml219;
  where FASFL = "Y";
run;

proc format;
  value $ynfm 'N'='なし' 'Y'='あり';
run;

TITLE1 'JALSG-GML219';
ods rtf file="&output.\JALSG-GML219 Table2_&DATE..rtf" style=listing;
ods escapechar='^';
footnote2 "^S={just=r} 出力日 &DATE";

/*--- 治療実施コース数 ---*/
title2 '投与状況 (FAS)';
title3 '治療実施フラグ';
proc tabulate data=FAS missing;
  class ind1fl ind2fl c1fl c2fl c3fl;
  table (ind1fl ind2fl c1fl c2fl c3fl),
        all='全例' * (n pctn='%'*f=8.1)
  / misstext='0';
  format ind1fl ind2fl c1fl c2fl c3fl $ynfm.;
run;

/*--- 寛解導入1 用量・日数 ---*/
title3 '寛解導入療法1（Ara-C・DNR）';
proc tabulate data=FAS(where=(ind1fl="Y")) missing;
  var i1_AraCdose i1_AraCdays i1_DNRdose i1_DNRdays;
  table (i1_AraCdose i1_AraCdays i1_DNRdose i1_DNRdays),
    (n*f=8. mean*f=8.1 std='SD'*f=8.1 min*f=8.1
     q1='25%点'*f=8.1 median*f=8.1 q3='75%点'*f=8.1 max*f=8.1)
  / misstext='.';
run;

/*--- 寛解導入2 ---*/
title3 '寛解導入療法2（Ara-C・DNR）';
proc tabulate data=FAS(where=(ind2fl="Y")) missing;
  var i2_AraCdose i2_AraCdays i2_DNRdose i2_DNRdays;
  table (i2_AraCdose i2_AraCdays i2_DNRdose i2_DNRdays),
    (n*f=8. mean*f=8.1 std='SD'*f=8.1 min*f=8.1
     q1='25%点'*f=8.1 median*f=8.1 q3='75%点'*f=8.1 max*f=8.1)
  / misstext='.';
run;

/*--- 地固め1 ---*/
title3 '地固め療法1（Ara-C・MIT）';
proc tabulate data=FAS(where=(c1fl="Y")) missing;
  var c1_AraCdose c1_AraCdays c1_MITdose c1_MITdays;
  table (c1_AraCdose c1_AraCdays c1_MITdose c1_MITdays),
    (n*f=8. mean*f=8.1 std='SD'*f=8.1 min*f=8.1
     q1='25%点'*f=8.1 median*f=8.1 q3='75%点'*f=8.1 max*f=8.1)
  / misstext='.';
run;

/*--- 地固め2 ---*/
title3 '地固め療法2（Ara-C・DNR）';
proc tabulate data=FAS(where=(c2fl="Y")) missing;
  var c2_AraCdose c2_AraCdays c2_DNRdose c2_DNRdays;
  table (c2_AraCdose c2_AraCdays c2_DNRdose c2_DNRdays),
    (n*f=8. mean*f=8.1 std='SD'*f=8.1 min*f=8.1
     q1='25%点'*f=8.1 median*f=8.1 q3='75%点'*f=8.1 max*f=8.1)
  / misstext='.';
run;

/*--- 地固め3 ---*/
title3 '地固め療法3（Ara-C・ACR）';
proc tabulate data=FAS(where=(c3fl="Y")) missing;
  var c3_AraCdose c3_AraCdays c3_ACRdose c3_ACRdays;
  table (c3_AraCdose c3_AraCdays c3_ACRdose c3_ACRdays),
    (n*f=8. mean*f=8.1 std='SD'*f=8.1 min*f=8.1
     q1='25%点'*f=8.1 median*f=8.1 q3='75%点'*f=8.1 max*f=8.1)
  / misstext='.';
run;

ods rtf close;
proc printto; run;