**********************************************************************;
* Project      : JALSG-GML219
* Program name : JALSG-GML219_STAT_Table3_4.4.7.CRrate.sas
* Author       : AKIKO SAITO
* Date created : 20260504
* Description  : CR率（LFS率・治療不応率）(SAP 4.4.7)
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

proc printto log="&log.\JALSG-GML219_STAT_Table3_&DATE..log" new; run;

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

/*--- CR到達日までの日数 ---*/
data FAS;
  set FAS;
  if crfl = "Y" and crdt ne . then daysto1cr = crdt - rfstdt + 1;
  label daysto1cr = "初回CR到達までの日数";
run;

proc format;
  value $respfm 'CR'='CR（完全寛解）' 'PR'='PR（部分寛解）'
                'SD'='SD' 'PD'='PD（進行）' 'NE'='NE（評価不可）' ' '='未評価';
  value $crflfm 'Y'='CR到達' 'N'='CR非到達';
run;

TITLE1 'JALSG-GML219';
ods rtf file="&output.\JALSG-GML219 Table3_&DATE..rtf" style=listing;
ods escapechar='^';
footnote2 "^S={just=r} 出力日 &DATE";

/*--- 寛解導入1後の効果判定 ---*/
title2 'CR率・LFS率 (FAS)';
title3 '寛解導入療法1後の効果判定';
proc tabulate data=FAS missing;
  class rs_ev1;
  table
    (rs_ev1),
    all='全例' * (n pctn='%'*f=8.1)
  / misstext='0';
  format rs_ev1 $respfm.;
run;

/*--- 寛解導入2後の効果判定 ---*/
title3 '寛解導入療法2後の効果判定（2コース実施例のみ）';
proc tabulate data=FAS(where=(ind2fl="Y")) missing;
  class rs_ev2;
  table
    (rs_ev2),
    all='全例' * (n pctn='%'*f=8.1)
  / misstext='0';
  format rs_ev2 $respfm.;
run;

/*--- 総合CR達成フラグ ---*/
title3 '総合CR達成状況（全コース通じて）';
proc tabulate data=FAS missing;
  class crfl;
  table
    (crfl),
    all='全例' * (n pctn='%'*f=8.1)
  / misstext='0';
  format crfl $crflfm.;
run;

/*--- CR到達までの日数 ---*/
title3 'CR到達までの日数（CR到達例）';
proc tabulate data=FAS(where=(crfl="Y")) missing;
  var daysto1cr;
  table
    (daysto1cr),
    (n*f=8.
     mean*f=8.1
     std='SD'*f=8.1
     min*f=8.1
     q1='25%点'*f=8.1
     median*f=8.1
     q3='75%点'*f=8.1
     max*f=8.1)
  / misstext='.';
run;

ods rtf close;
proc printto; run;