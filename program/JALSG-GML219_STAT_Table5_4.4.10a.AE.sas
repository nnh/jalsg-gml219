**********************************************************************;
* Project      : JALSG-GML219
* Program name : JALSG-GML219_STAT_Table5_4.4.10a.AE.sas
* Author       : AKIKO SAITO
* Date created : 20260504
* Date updated : 20260505
* Description  : 有害事象詳細（コース別）(SAP 4.4.10a / 5.4.10)
*                Section 1: AE 頻度（Any/G1-2/G3/G4）
*                Section 2: 血液所見最低値（WBC/Neut/Hb/PLT）
*                Section 3: 好中球<1000/μL 持続日数
*                Section 4: 深在性真菌症（EORTC/MSG）
*                Section 5: 感染症起因菌
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
libname librawdata "&_wk_path.\input\rawdata";
libname libout "&_wk_path.\output";

%let output = &_wk_path.\output;
%let log    = &_wk_path.\log;
%let rawdir = &_wk_path.\input\rawdata;

proc printto log="&log.\JALSG-GML219_STAT_Table5_&DATE..log" new; run;

options validvarname=v7 fmtsearch=(libout work) nofmterr
        nomlogic nosymbolgen nomprint ls=200 missing="" pageno=1
        nodate nonumber;

data gml219;
  set libraw.gml219;
run;

/* SAFと FAS は同義（プロトコル） */
data SAF;
  set gml219;
  where saffl = "Y";
run;

/*--- LB / FA / MB を rawdata から再インポート（Section 2-4 用） ---*/
%macro impcsv(dsnm);
  proc import out=&dsnm
    datafile="&rawdir.\&dsnm..csv"
    dbms=csv replace;
    getnames=yes; datarow=2; guessingrows=max;
  run;
%mend;
%impcsv(LB);
%impcsv(FA);

TITLE1 'JALSG-GML219';
ods rtf file="&output.\JALSG-GML219 Table5_&DATE..rtf" style=listing;
ods escapechar='^';
footnote2 "^S={just=r} 出力日 &DATE";

/*=====================================================================*/
/* Section 1: AE 頻度（コース別 × Any/G1-2/G3/G4/G5）                     */
/*=====================================================================*/

%macro ae_row(num, name);
  data ae&num;
    length c1 $200. c2-c6 $30.;
    retain g1 g2 g3 g4 g5 0;
    set tmp_pop end=eof;
    if _gae&num&_cycl_ = 1 then g1 + 1;
    if _gae&num&_cycl_ = 2 then g2 + 1;
    if _gae&num&_cycl_ = 3 then g3 + 1;
    if _gae&num&_cycl_ = 4 then g4 + 1;
    if _gae&num&_cycl_ = 5 then g5 + 1;
    if eof then do;
      any = g1 + g2 + g3 + g4 + g5;
      g12 = g1 + g2;
      c1 = "  &name";
      if any = 0 then c2 = '0 (0.0%)';
      else c2 = compress(put(any, 8.)) || ' (' ||
                compress(put(round(any / &_nn_ * 100, .1), 8.1)) || '%)';
      if g12 = 0 then c3 = '0 (0.0%)';
      else c3 = compress(put(g12, 8.)) || ' (' ||
                compress(put(round(g12 / &_nn_ * 100, .1), 8.1)) || '%)';
      if g3 = 0 then c4 = '0 (0.0%)';
      else c4 = compress(put(g3, 8.)) || ' (' ||
                compress(put(round(g3 / &_nn_ * 100, .1), 8.1)) || '%)';
      if g4 = 0 then c5 = '0 (0.0%)';
      else c5 = compress(put(g4, 8.)) || ' (' ||
                compress(put(round(g4 / &_nn_ * 100, .1), 8.1)) || '%)';
      if g5 = 0 then c6 = '0 (0.0%)';
      else c6 = compress(put(g5, 8.)) || ' (' ||
                compress(put(round(g5 / &_nn_ * 100, .1), 8.1)) || '%)';
       keep c1-c6;
      output;
    end;
  run;
%mend ae_row;

%macro ae_table(cycle, filter, ctitle);
  %global _cycl_ _nn_;
  %let _cycl_ = &cycle;

  data tmp_pop;
    set gml219;
    where &filter;
  run;

  data _null_;
    set tmp_pop end=eof;
    if eof then call symput("_nn_", compress(put(_n_, 8.)));
  run;

  %ae_row(01, ALT増加)
  %ae_row(02, アレルギー反応)
  %ae_row(03, 肛門直腸感染)
  %ae_row(04, AST増加)
  %ae_row(05, ビリルビン増加)
  %ae_row(06, 気管支肺出血)
  %ae_row(07, 心臓障害-その他)
  %ae_row(08, カテーテル関連感染)
  %ae_row(09, クレアチニン増加)
  %ae_row(10, 下痢)
  %ae_row(11, 播種性血管内凝固)
  %ae_row(12, 発熱性好中球減少症)
  %ae_row(13, 肝不全)
  %ae_row(14, 高血糖)
  %ae_row(15, イレウス)
  %ae_row(16, 頭蓋内出血)
  %ae_row(17, 下部消化管出血)
  %ae_row(18, 肺感染)
  %ae_row(19, 口腔粘膜炎)
  %ae_row(20, 悪心)
  %ae_row(21, 膵炎)
  %ae_row(22, 末梢性運動ニューロパチー)
  %ae_row(23, 末梢性感覚ニューロパチー)
  %ae_row(24, 斑状丘疹状?疹)
  %ae_row(25, 敗血症)
  %ae_row(26, 血清アミラーゼ増加)
  %ae_row(27, 血栓塞栓症)
  %ae_row(28, 腫瘍崩壊症候群)
  %ae_row(29, 上部消化管出血)
  %ae_row(30, 尿路感染)
  %ae_row(31, 蕁麻疹)
  %ae_row(32, 子宮出血)
  %ae_row(33, 嘔吐)

  data t5_&cycle;
    set ae01 ae02 ae03 ae04 ae05 ae06 ae07 ae08 ae09 ae10
        ae11 ae12 ae13 ae14 ae15 ae16 ae17 ae18 ae19 ae20
        ae21 ae22 ae23 ae24 ae25 ae26 ae27 ae28 ae29 ae30
        ae31 ae32 ae33;
    label c1 = '有害事象' c2 = 'Any' c3 = '1-2' c4 = '3' c5 = '4' c6 = '5';
  run;

  proc datasets lib=work nolist;
    delete ae01 ae02 ae03 ae04 ae05 ae06 ae07 ae08 ae09 ae10
           ae11 ae12 ae13 ae14 ae15 ae16 ae17 ae18 ae19 ae20
           ae21 ae22 ae23 ae24 ae25 ae26 ae27 ae28 ae29 ae30
           ae31 ae32 ae33 tmp_pop;
  run; quit;

  title2 "(1) 有害事象頻度 ― &ctitle (n=&_nn_)";
  title3 "解析対象集団: 全安全性解析対象集団";

  proc report data=t5_&cycle split="|"
    style(header)=[just=center asis=on]
    style(column)=[just=center asis=on];
    column c1
           ("^S={borderbottomwidth=1pt}&ctitle (n=&_nn_)|Grade" c2 c3 c4 c5 c6);
    define c1 / style(header)=[width=7.5cm just=l]
                style(column)=[just=l];
    define c2 / style(header)=[width=2.2cm];
    define c3 / style(header)=[width=2.2cm];
    define c4 / style(header)=[width=2.2cm];
    define c5 / style(header)=[width=2.2cm];
    define c6 / style(header)=[width=2.2cm];
  run;

  proc datasets lib=work nolist;
    delete t5_&cycle;
  run; quit;

%mend ae_table;

%ae_table(i1, %str(fasfl="Y"),  寛解導入1)
%ae_table(i2, %str(ind2fl="Y"), 寛解導入2)
%ae_table(c1, %str(c1fl="Y"),   地固め1)
%ae_table(c2, %str(c2fl="Y"),   地固め2)
%ae_table(c3, %str(c3fl="Y"),   地固め3)


/*=====================================================================*/
/* Section 2: 血液所見最低値（WBC/Neut/Hb/PLT）? LB の各コース AE 時点 */
/*=====================================================================*/
data lb_nadir;
  set LB;
  where lbspid in ("induction1ae","induction2ae","consolidation1ae","consolidation2ae","consolidation3ae")
        and lbtestcd in ("WBC","NEUT","HGB","PLAT");
  length cycle $4. testlbl $30.;
  if      lbspid = "induction1ae"     then cycle = "i1";
  else if lbspid = "induction2ae"     then cycle = "i2";
  else if lbspid = "consolidation1ae" then cycle = "c1";
  else if lbspid = "consolidation2ae" then cycle = "c2";
  else if lbspid = "consolidation3ae" then cycle = "c3";
  if      lbtestcd = "WBC"  then testlbl = "白血球数最低値（/μL）";
  else if lbtestcd = "NEUT" then testlbl = "好中球数最低値（/μL）";
  else if lbtestcd = "HGB"  then testlbl = "ヘモグロビン最低値（g/dL）";
  else if lbtestcd = "PLAT" then testlbl = "血小板数最低値（×10^4/μL）";
  lbnum = input(lborres, best.);
run;

proc sort data=lb_nadir; by cycle lbtestcd; run;

title2 '(2) 骨髄抑制（コース別、nadir）';
title3 '解析対象集団: 全安全性解析対象集団';
proc tabulate data=lb_nadir missing;
  class cycle testlbl / order=data;
  var lbnum;
  table cycle * testlbl='',
        (n*f=8.
         mean*f=10.1
         std='SD'*f=10.1
         min*f=10.1
         q1='25%点'*f=10.1
         median*f=10.1
         q3='75%点'*f=10.1
         max*f=10.1) * lbnum=''
  / misstext='.';
run;


/*=====================================================================*/
/* Section 3: 好中球<1000/μL 持続日数（FA DURATION, FAOBJ=Neutrophil） */
/*=====================================================================*/
data neut_dur;
  set FA;
  where fatestcd = "DURATION" and faobj = "Neutrophil count decreased"
        and faspid in ("induction1ae","induction2ae","consolidation1ae","consolidation2ae","consolidation3ae");
  length cycle $4.;
  if      faspid = "induction1ae"     then cycle = "i1";
  else if faspid = "induction2ae"     then cycle = "i2";
  else if faspid = "consolidation1ae" then cycle = "c1";
  else if faspid = "consolidation2ae" then cycle = "c2";
  else if faspid = "consolidation3ae" then cycle = "c3";
  ndays = input(faorres, best.);
run;

title2 '(3) 好中球数 <1000/μL 持続日数（コース別）';
title3 '解析対象集団: 全安全性解析対象集団';
proc tabulate data=neut_dur missing;
  class cycle / order=data;
  var ndays;
  table cycle='',
        (n*f=8.
         mean*f=8.1
         std='SD'*f=8.1
         min*f=8.1
         q1='25%点'*f=8.1
         median*f=8.1
         q3='75%点'*f=8.1
         max*f=8.1) * ndays=''
  / misstext='.';
run;


/*=====================================================================*/
/* Section 4: 深在性真菌症（FA DPFUNINF, EORTC/MSG）                    */
/*=====================================================================*/
data fungal;
  set FA;
  where fatestcd = "DPFUNINF"
        and faspid in ("induction1ae","induction2ae","consolidation1ae","consolidation2ae","consolidation3ae");
  length cycle $4. fdiag $20.;
  if      faspid = "induction1ae"     then cycle = "i1";
  else if faspid = "induction2ae"     then cycle = "i2";
  else if faspid = "consolidation1ae" then cycle = "c1";
  else if faspid = "consolidation2ae" then cycle = "c2";
  else if faspid = "consolidation3ae" then cycle = "c3";
  /* faorres 値正規化 */
  if upcase(strip(faorres)) in ("Y","CR","CONFIRMED","PROVEN") then fdiag = "確定";
  else if upcase(strip(faorres)) = "PROBABLE" then fdiag = "Probable";
  else if upcase(strip(faorres)) = "POSSIBLE" then fdiag = "Possible";
  else if upcase(strip(faorres)) in ("N","NO","NEGATIVE") then fdiag = "なし";
  else if strip(faorres) ne "" then fdiag = strip(faorres);
  else fdiag = "-";
run;

title2 '(4) 深在性真菌症の診断分布（EORTC/MSG 基準）';
title3 '解析対象集団: 全安全性解析対象集団';
proc tabulate data=fungal missing;
  class cycle fdiag / order=data;
  table cycle='',
        fdiag * (n='件数' colpctn='%'*f=8.1) all='合計' * n
  / misstext='0';
run;


/*=====================================================================*/
/* Section 5: 感染症起因菌一覧（コース別、MB ドメイン由来）            */
/*=====================================================================*/
data mb_listing;
  set gml219(keep=usubjid mb_i1 mb_i2 mb_c1 mb_c2 mb_c3);
  where (mb_i1 ne "") or (mb_i2 ne "") or (mb_c1 ne "")
     or (mb_c2 ne "") or (mb_c3 ne "");
  label mb_i1 = '寛解導入1'
        mb_i2 = '寛解導入2'
        mb_c1 = '地固め1'
        mb_c2 = '地固め2'
        mb_c3 = '地固め3';
run;

title2 '(5) 感染症起因菌一覧（コース別、MB ドメイン由来）';
title3 '解析対象集団: 全安全性解析対象集団（起因菌が記録された症例のみ）';
proc print data=mb_listing noobs label width=min;
  var usubjid mb_i1 mb_i2 mb_c1 mb_c2 mb_c3;
run;

ods rtf close;
proc printto; run;