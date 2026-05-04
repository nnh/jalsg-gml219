**********************************************************************;
* Project      : JALSG-GML219
* Program name : JALSG-GML219_STAT_Table3_4.4.7.CRrate.sas
* Author       : AKIKO SAITO
* Date created : 20260504
* Date updated : 20260505
* Description  : CR率・LFS率・治療不応率 (SAP 4.4.7 / 5.4.3, PRT v2.4 §8.1.3)
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

/*--- 派生変数：CR・LFS 到達までの日数 ---*/
data FAS;
  set FAS;
  if crfl  = "Y" and crdt  ne . then daysto1cr  = crdt  - rfstdt + 1;
  if lfsfl = "Y" and lfsdt ne . then daysto1lfs = lfsdt - rfstdt + 1;
  label daysto1cr  = "登録日からCR到達までの日数"
        daysto1lfs = "登録日からLFS到達までの日数";
run;

proc format;
  value $respfm 'CR'='CR（完全寛解）'
                'NON-CR/NON-PD'='NON-CR/NON-PD（不完全寛解）'
                'NE'='NE（評価不能）'
                ' '='未評価';
  value $crflfm 'Y'='達成' 'N'='未達成';
  value $tffm   'Y'='治療不応' 'N'='非治療不応';
  value $tftypef 'R'='治療抵抗性' 'A'='骨髄無形成' 'U'='判定不能/暫定' ' '='-';
run;

TITLE1 'JALSG-GML219';
ods rtf file="&output.\JALSG-GML219 Table3_&DATE..rtf" style=listing;
ods escapechar='^';
footnote2 "^S={just=r} 出力日 &DATE";

/*=====================================================================*/
/* (1) 寛解導入1コース後の効果判定                                     */
/*=====================================================================*/
title2 '寛解導入療法1コース後の効果判定 (FAS)';
proc tabulate data=FAS missing;
  class rs_ev1;
  table
    (rs_ev1),
    all='全体' * (n pctn='%'*f=8.1)
  / misstext='0';
  format rs_ev1 $respfm.;
run;

/*=====================================================================*/
/* (2) 寛解導入2コース後の効果判定（2コース実施例のみ）                 */
/*=====================================================================*/
title2 '寛解導入療法2コース後の効果判定（2コース実施例のみ）';
proc tabulate data=FAS(where=(ind2fl="Y")) missing;
  class rs_ev2;
  table
    (rs_ev2),
    all='全体' * (n pctn='%'*f=8.1)
  / misstext='0';
  format rs_ev2 $respfm.;
run;

/*=====================================================================*/
/* (3) CR 達成率（PRT v2.4 §8.1.3 厳密 CR：5条件全て満たす）            */
/*=====================================================================*/
title2 'CR 達成率 (FAS) ― PRT v2.4 §8.1.3 厳密CR';
proc tabulate data=FAS missing;
  class crfl;
  table
    (crfl),
    all='全体' * (n pctn='%'*f=8.1)
  / misstext='0';
  format crfl $crflfm.;
run;

/* CR率 95% CI（二項分布） */
title3 'CR率 95% 信頼区間（二項分布）';
proc freq data=FAS;
  tables crfl / binomial(level="Y") cl alpha=0.05;
run;

/*=====================================================================*/
/* (4) LFS 達成率（PRT v2.4 §8.1.3 LFS：骨髄芽球<5% かつ 髄外病変なし） */
/*    現実装：CR ⊃ LFS のため lfsfl は crfl と同等（暫定）              */
/*=====================================================================*/
title2 'LFS 達成率 (FAS) ― PRT v2.4 §8.1.3';
proc tabulate data=FAS missing;
  class lfsfl;
  table
    (lfsfl),
    all='全体' * (n pctn='%'*f=8.1)
  / misstext='0';
  format lfsfl $crflfm.;
run;

title3 'LFS率 95% 信頼区間（二項分布）';
proc freq data=FAS;
  tables lfsfl / binomial(level="Y") cl alpha=0.05;
run;

/*=====================================================================*/
/* (5) 治療不応率（PRT v2.4 §8.1.3 暫定：CR 未達成）                   */
/*=====================================================================*/
title2 '治療不応率 (FAS) ― PRT v2.4 §8.1.3 暫定（CR 未達成）';
proc tabulate data=FAS missing;
  class tffl tftype;
  table
    (tffl tftype),
    all='全体' * (n pctn='%'*f=8.1)
  / misstext='0';
  format tffl $tffm. tftype $tftypef.;
run;

title3 '治療不応率 95% 信頼区間（二項分布）';
proc freq data=FAS;
  tables tffl / binomial(level="Y") cl alpha=0.05;
run;

/*=====================================================================*/
/* (6) CR 達成までの日数（CR 達成例）                                  */
/*=====================================================================*/
title2 'CR 達成までの日数 (CR 達成例)';
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

/*=====================================================================*/
/* (7) LFS 到達までの日数（LFS 到達例）                                */
/*=====================================================================*/
title2 'LFS 到達までの日数 (LFS 到達例)';
proc tabulate data=FAS(where=(lfsfl="Y")) missing;
  var daysto1lfs;
  table
    (daysto1lfs),
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