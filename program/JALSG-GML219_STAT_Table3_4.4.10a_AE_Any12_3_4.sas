**********************************************************************;
* Project           : JALSG-GML219
*
* Program name  : JALSG-GML219_Table3_4.4.10a.AE grade(Any, 1-2, 3, 4).sas
*
* Author             : AKIKO SAITO
*
* Date created    : 20251209
* Date updated    : 20251209 
* Description      : JALSG-GML219 Table 3　AE2 (Any, Grade1-2, Grade3, Grade4)
**********************************************************************;

/*** initial setting ***/

title ;
footnote ;

*前回の作業で残っている一時的データ（Workライブラリの中身）を削除;
proc datasets library=work kill nolist ;
quit ;

*結果ウィンドウやログウィンドウを空にする;
dm 'output; clear; log; clear;';
options nonumber notes nodate nomprint ls=100 ps=9999 formdlim="" center ;
ods listing close;


*プロジェクトフォルダの場所を探すマクロ:setexecpath;
%let execpath = " ";
%let Path = " ";
%macro setexecpath;
  %let execpath = %sysfunc(getoption(sysin));
  %if %length(&execpath) = 0 %then
    %let execpath = %sysget(sas_execfilepath);
  data _null_;
    do i = length("&execpath") to 1 by -1;
      if substr("&execpath", i, 1) = "\" then do;
        do j = i-1 to 1 by -1;
          if substr("&execpath", j, 1) = "\" then do;
            call symput("Path", substr("&execpath", 1, j));
            stop;
          end;
        end;
      end;
    end;
  run;
%mend setexecpath;
%setexecpath;

*解析データセットを読み込む;
%put &path;
libname ads "&path.input\ads\";
options fmtsearch=(ads);
options sasautos=(sasautos "&path.program\macro" );

proc datasets lib=ads nolist;
  copy out=work;
run;quit;

/*proc freq data=gml219;*/
/*tables i1stum i2stum c1stum c2stum c3stum;*/
/*run;*/

/************************************************************************
* 表作成
************************************************************************/
proc contents data=gml219; run;

proc freq data=gml219;
  where saffl="Y";
  table i1stum / nocum;
  ods output onewayfreqs=tmp1;
run;

data _null_;
  set tmp1;
  if i1stum="Y" then call symput("n_c1", compress(frequency));
run;

proc freq data=gml219;
  where saffl="Y";
  table i2stum / nocum;
  ods output onewayfreqs=tmp2;
run;

data _null_;
  set tmp2;
  if i2stum="Y" then call symput("n_c2", compress(frequency));
run;

proc freq data=gml219;
  where saffl="Y";
  table c1stum / nocum;
  ods output onewayfreqs=tmp3;
run;

data _null_;
  set tmp3;
  if c1stum="Y" then call symput("n_c3", compress(frequency));
run;

proc freq data=gml219;
  where saffl="Y";
  table c2stum / nocum;
  ods output onewayfreqs=tmp4;
run;

data _null_;
  set tmp4;
  if c2stum="Y" then call symput("n_c4", compress(frequency));
run;

proc freq data=gml219;
  where saffl="Y";
  table c3stum / nocum;
  ods output onewayfreqs=tmp5;
run;

data _null_;
  set tmp5;
  if c3stum="Y" then call symput("n_c5", compress(frequency));
run;

%macro AE(cycle);

data tmp1;
  set gml219;
  where saffl="Y";
run;

proc freq data=tmp1;
  table &cycle.stum / nocum;
  ods output onewayfreqs=tmp2;
run;

data _null_;
  set tmp2;
  if &cycle.stum="Y" then call symput("n", compress(frequency));
run;


%macro AE_sub(var, name);

proc freq data=tmp1;
  table &var&cycle / nocum;
  ods output onewayfreqs=mac1;
run;

proc transpose data=mac1 out=mac2;
  id &var&cycle;
  var frequency;
run;

data &var;
  set mac2;
  length _0 _1 _2 _3 _4 8. c1 c2 c3 c4 c5 $256.;
  c1="  &name";
  any=sum(_1, _2, _3, _4);
  _12=sum(_1, _2);
  _3=sum(_3);
  _4=sum(_4);
  c2=compress(put(any,8.))||" ("||compress(put(round(any/&n*100,.1),8.1))||'%)';
  c3=compress(put(_12,8.))||" ("||compress(put(round(_12/&n*100,.1),8.1))||'%)';
  c4=compress(put(_3,8.))||" ("||compress(put(round(_3/&n*100,.1),8.1))||'%)';
  c5=compress(put(_4,8.))||" ("||compress(put(round(_4/&n*100,.1),8.1))||'%)';
run;

proc datasets lib=work nolist;
  delete mac: ;
run;quit;

%mend;

%AE_sub(ae1, Catheter related infection);
%AE_sub(ae2, Urinary tract infection);
%AE_sub(ae3, Urticaria);
%AE_sub(ae4, Rash maculo-papular);
%AE_sub(ae5, Blood bilirubin increased);
%AE_sub(ae6, Allergic reaction);
%AE_sub(ae7, Febrile neutropenia);
%AE_sub(ae8, Anorectal infection);
%AE_sub(ae9, Disseminated intravascular coagulation);
%AE_sub(ae10, Cardiac disorders - Other);
%AE_sub(ae11, Hepatic failure);
%AE_sub(ae12, Diarrhea);
%AE_sub(ae13, Hyperglycemia);
%AE_sub(ae14, Lower gastrointestinal hemorrhage);
%AE_sub(ae15, Mucositis oral);
%AE_sub(ae16, Nausea);
%AE_sub(ae17, Ileus);
%AE_sub(ae18, Pancreatitis);
%AE_sub(ae19, Upper gastrointestinal hemorrhage);
%AE_sub(ae20, Vomiting);
%AE_sub(ae21, Peripheral motor neuropathy);
%AE_sub(ae22, Peripheral sensory neuropathy);
%AE_sub(ae23, Serum amylase increased);
%AE_sub(ae24, Lung infection);
%AE_sub(ae25, Sepsis);
%AE_sub(ae26, Alanine aminotransferase increased);
%AE_sub(ae27, Aspartate aminotransferase increased);
%AE_sub(ae28, Thromboembolic event);
%AE_sub(ae29, Creatinine increased);
%AE_sub(ae30, Tumor lysis syndrome);
%AE_sub(ae31, Uterine hemorrhage);
%AE_sub(ae32, Bronchopulmonary hemorrhage);
%AE_sub(ae33, Intracranial hemorrhage);

data t4_4_10_&cycle;
  set ae1 ae2 ae3 ae4 ae5 ae6 ae7 ae8 ae9 ae10
       ae11 ae12 ae13 ae14 ae15 ae16 ae17 ae18 ae19  ae20
       ae21 ae22 ae23 ae24 ae25 ae26 ae27 ae28 ae29  ae30
       ae31 ae32 ae33;
  if c2=' (%)' then c2='0 (0.0%)';
  if c3=' (%)' then c3='0 (0.0%)';
  if c4=' (%)' then c4='0 (0.0%)';
  if c5=' (%)' then c5='0 (0.0%)';
  label c1="有害事象名" c2="any" c3="1-2" c4="3" c5="4";
run;

proc datasets lib=work nolist;
  delete tmp1 tmp2 ae1-ae50;
run;quit;
%mend;

%AE(i1);
%AE(i2);
%AE(c1);
%AE(c2);
%AE(c3);



data _NULL_;
  date=today(); 
  call symput("today",put(date,yymmdd10.)); 
run;

options orientation=portrait;
ods escapechar='^';
ods rtf file="&path.output\JALSG-GML219 Table3 AE_&DATE.rtf" style=custom;

title1 "GML219";
title2 "4.4.10a (1) 有害事象 (寛解導入療法1の最悪グレードの頻度集計)";
title3 "解析対象集団: 安全性解析対象集団";
footnote1 j=c "^{thispage} / ^{lastpage}" j=r "出力日:&today"; 

proc report data=t4_4_10_i1 split="|" style(header) = {just=center asis = on} style(column) = {just=center asis = on};
  column c1 
         ("^S={borderbottomwidth=1pt}寛解導入療法1投与開始例 (n=&n_c1)|Grade" c2 c3 c4 c5) 
  ;
  define c1  / style(header)=[width=8.0cm just=l] style(column)=[just=l];
  define c2  / style(header)=[width=2.1cm];
  define c3  / style(header)=[width=2.1cm];
  define c4  / style(header)=[width=2.1cm];
  define c5  / style(header)=[width=2.1cm];
run;

title2 "4.4.10a (2) 有害事象 (寛解導入療法2の最悪グレードの頻度集計)";
title3 "解析対象集団: 安全性解析対象集団";
footnote1 j=c "^{thispage} / ^{lastpage}" j=r "出力日:&today"; 

proc report data=t4_4_10_i2 split="|" style(header) = {just=center asis = on} style(column) = {just=center asis = on};
  column c1 
         ("^S={borderbottomwidth=1pt}寛解導入療法2投与開始例 (n=&n_c2)|Grade" c2 c3 c4 c5) 
  ;
  define c1  / style(header)=[width=8.0cm just=l] style(column)=[just=l];
  define c2  / style(header)=[width=2.1cm];
  define c3  / style(header)=[width=2.1cm];
  define c4  / style(header)=[width=2.1cm];
  define c5  / style(header)=[width=2.1cm];
run;

title2 "4.4.10a (3) 有害事象 (地固め療法1の最悪グレードの頻度集計)";
title3 "解析対象集団: 安全性解析対象集団";
footnote1 j=c "^{thispage} / ^{lastpage}" j=r "出力日:&today"; 

proc report data=t4_4_10_c1 split="|" style(header) = {just=center asis = on} style(column) = {just=center asis = on};
  column c1 
         ("^S={borderbottomwidth=1pt}地固め療法1投与開始例 (n=&n_c3)|Grade" c2 c3 c4 c5) 
  ;
  define c1  / style(header)=[width=8.0cm just=l] style(column)=[just=l];
  define c2  / style(header)=[width=2.1cm];
  define c3  / style(header)=[width=2.1cm];
  define c4  / style(header)=[width=2.1cm];
  define c5  / style(header)=[width=2.1cm];
run;

title2 "4.4.10a (4) 有害事象 (地固め療法2の最悪グレードの頻度集計)";
title3 "解析対象集団: 安全性解析対象集団";
footnote1 j=c "^{thispage} / ^{lastpage}" j=r "出力日:&today"; 

proc report data=t4_4_10_c2 split="|" style(header) = {just=center asis = on} style(column) = {just=center asis = on};
  column c1 
         ("^S={borderbottomwidth=1pt}地固め療法サイクル2投与開始例 (n=&n_c4)|Grade" c2 c3 c4 c5) 
  ;
  define c1  / style(header)=[width=8.0cm just=l] style(column)=[just=l];
  define c2  / style(header)=[width=2.1cm];
  define c3  / style(header)=[width=2.1cm];
  define c4  / style(header)=[width=2.1cm];
  define c5  / style(header)=[width=2.1cm];
run;

title2 "4.4.10a (5) 有害事象 (地固め療法3の最悪グレードの頻度集計)";
title3 "解析対象集団: 安全性解析対象集団";
footnote1 j=c "^{thispage} / ^{lastpage}" j=r "出力日:&today"; 

proc report data=t4_4_10_c3 split="|" style(header) = {just=center asis = on} style(column) = {just=center asis = on};
  column c1 
         ("^S={borderbottomwidth=1pt}地固め療法サイクル3投与開始例 (n=&n_c5)|Grade" c2 c3 c4 c5) 
  ;
  define c1  / style(header)=[width=8.0cm just=l] style(column)=[just=l];
  define c2  / style(header)=[width=2.1cm];
  define c3  / style(header)=[width=2.1cm];
  define c4  / style(header)=[width=2.1cm];
  define c5  / style(header)=[width=2.1cm];
run;

ods rtf close;

