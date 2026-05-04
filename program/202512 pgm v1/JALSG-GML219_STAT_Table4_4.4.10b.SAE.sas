**********************************************************************;
* Project           : JALSG-GML219
*
* Program name  : JALSG-GML219_Table4_4.4.10b.SAE.sas
*
* Author             : AKIKO SAITO
*
* Date created    : 20251209 
* Date updated    : 20251209 
* Description      : JALSG-APL219R Table 4　SAE
**********************************************************************;

title ;
footnote ;

proc datasets library=work kill nolist ;
quit ;

dm 'output; clear; log; clear;';
options nonumber notes nodate nomprint ls=100 ps=9999 formdlim="" center ;
ods listing close;


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

%put &path;
libname ads "&path.input\ads\";
options fmtsearch=(ads);
options sasautos=(sasautos "&path.program\macro" );

proc datasets lib=ads nolist;
  copy out=work;
run;quit;


/************************************************************************
* 表作成
************************************************************************/

data tmp1;
  set gml219_sae;
  where saffl="Y";
run;

/*各グループの例数*/
proc freq data=tmp1;
  table saffl / nocum;
  ods output onewayfreqs=tmp2;
run;

data _null_;
  set tmp2;
  if saffl="Y" then call symput("n", compress(frequency));
run;

%macro SAE(saenm);
proc freq data=tmp1;
  table &saenm / nocum;
  ods output onewayfreqs=mac1;
run;

proc contents data=mac1;
  ods output Variables=mac2;
run;

data _null_;
  set mac2;
  if Variable="&saenm" then call symput("label",Label);
run;

data &saenm;
  length c1 c2 $256.;
  set mac1;
  where &saenm="Y";
  c1="&label";
  c2=compress(put(frequency,8.))||" ("||compress(put(round(frequency/&n.*100,.1),8.1))||'%)';
run;

proc datasets lib=work nolist;
  delete mac: ;
run;quit;
%mend;

%SAE(anysae);
%SAE(sae1);
%SAE(sae2);
%SAE(sae3);
%SAE(sae4);
%SAE(sae5);
%SAE(sae6);
%SAE(sae7);
%SAE(sae8);
%SAE(sae9);
%SAE(sae10);
%SAE(sae11);
%SAE(sae12);
%SAE(sae13);
%SAE(sae14);
%SAE(sae15);
%SAE(sae16);
%SAE(sae17);
%SAE(sae18);
%SAE(sae19);

data blk;
  length c1 $256.;
  c1="";
run;


data t4_4_1b;
  set anysae blk sae1 sae2 sae3 sae4 sae5 sae6 sae7 sae8 sae9 sae10 sae11 sae12 sae13 sae14 sae15 sae16 sae17 sae18 sae19;
  label c1="有害事象名" c2="評価例数 (n=&n)| 発現例数 (発現割合)";
run;


data _NULL_;
  date=today(); 
  call symput("today",put(date,yymmdd10.)); 
run;

options orientation=portrait;
ods escapechar='^';
ods rtf file="&path.output\JALSG-GML219 Table4_&DATE.rtf" style=custom;

title1 "JALSG-GML219";
title2 "4.4.1b 重篤な有害事象";
title3 "解析対象集団: 安全性解析対象集団";
footnote1 j=c "^{thispage} / ^{lastpage}" j=r "出力日:&today"; 
proc print data=T4_4_1b noobs label split="|";
  var c1 c2;
run;

ods rtf close;

