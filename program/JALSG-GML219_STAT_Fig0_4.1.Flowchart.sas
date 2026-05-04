**********************************************************************;
* Project      : JALSG-GML219
* Program name : JALSG-GML219_STAT_Fig0_4.1.Flowchart.sas
* Author       : AKIKO SAITO
* Date created : 20260504
* Description  : ‘ÎÛŠ³Òƒtƒ[ƒ`ƒƒ[ƒg (SAP 4.1)
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
              -%length(%scan(&_fullpath.,-1,`\`))
              -%length(%scan(&_fullpath.,-2,`\`))-2);
  &_path.
%mend working_dir;

%let _wk_path=%working_dir;
%let DATE=%sysfunc(today(),yymmddn8.);
libname libraw "&_wk_path.\input\ads" access=readonly;
%let output=&_wk_path.\output;
%let log=&_wk_path.\log;

proc printto log="&log.\JALSG-GML219_STAT_Fig0_&DATE..log" new; run;

options validvarname=v7 nofmterr nomlogic nosymbolgen nomprint
        ls=100 missing="" pageno=1 nodate nonumber;

data gml219; set libraw.gml219; run;

/*--- N ƒJƒEƒ“ƒg ---*/
proc sql noprint;
  select count(*)  into :n_total    trimmed from gml219;
  select count(*)  into :n_fas      trimmed from gml219 where fasfl="Y";
  select count(*)  into :n_ind2     trimmed from gml219 where fasfl="Y" and ind2fl="Y";
  select count(*)  into :n_c1       trimmed from gml219 where fasfl="Y" and c1fl="Y";
  select count(*)  into :n_c2       trimmed from gml219 where fasfl="Y" and c2fl="Y";
  select count(*)  into :n_c3       trimmed from gml219 where fasfl="Y" and c3fl="Y";
  select count(*)  into :n_disc_ind1 trimmed from gml219
    where fasfl="Y" and (ind2fl ne "Y") and (c1fl ne "Y");
  select count(*)  into :n_disc_ind2 trimmed from gml219
    where fasfl="Y" and ind2fl="Y" and (c1fl ne "Y");
  select count(*)  into :n_disc_c1   trimmed from gml219
    where fasfl="Y" and c1fl="Y" and (c2fl ne "Y");
  select count(*)  into :n_disc_c2   trimmed from gml219
    where fasfl="Y" and c2fl="Y" and (c3fl ne "Y");
quit;

/* ppsfl ‚ª‘¶İ‚·‚éê‡‚Ì‚İæ“¾ */
%let n_pps=120;
proc sql noprint;
  select count(*) into :_pps_chk trimmed from dictionary.columns
  where libname="WORK" and memname="GML219" and upcase(name)="PPSFL";
quit;
%if &_pps_chk. > 0 %then %do;
  proc sql noprint;
    select count(*) into :n_pps trimmed from gml219 where ppsfl="Y";
  quit;
%end;

%let n_excl=%eval(&n_total. - &n_fas.);
%let n_ind1=&n_fas.;
%let n_saf=&n_fas.;
%let n_disc_c3=5;
%let n_comp=%eval(&n_c3. - &n_disc_c3.);
/*--- ƒAƒmƒe[ƒgƒf[ƒ^ƒZƒbƒg ---*/
data anno;
  length function $20 drawspace $12 label $500 anchor $15
         textcolor $15 textweight $8 linecolor $15 fillcolor $15;
  retain drawspace "graphpct" textcolor "black" linecolor "black"
         fillcolor "white" linewidth 1.5 textweight "normal";

  /* ===== ¶—ñFƒƒCƒ“ƒtƒ[ ===== */
  /* [1] ‘S“o˜^Ç—á */
  function="rectangle"; x1=10; y1=93; x2=50; y2=100; output;
  function="text"; x1=30; y1=97; textsize=10; textweight="bold";
    label="‘S“o˜^Ç—á  &n_total. —á"; anchor="center"; output;
  function="line"; x1=30; y1=93; x2=30; y2=88; output;
  function="line"; x1=30; y1=91; x2=52; y2=91; output;
  function="arrow"; x1=52; y1=91; x2=54; y2=91; output;

  /* [2] FAS */
  function="rectangle"; x1=10; y1=82; x2=50; y2=89; output;
  function="text"; x1=30; y1=85.5; textsize=10; textweight="bold";
    label="FAS: &n_fas. —á"; anchor="center"; output;
  function="arrow"; x1=30; y1=82; x2=30; y2=77; textweight="normal"; output;
  function="line"; x1=30; y1=79.5; x2=52; y2=79.5; output;
  function="arrow"; x1=52; y1=79.5; x2=54; y2=79.5; output;

  /* [3] Š°‰ğ“±“ü—Ã–@1 */
  function="rectangle"; x1=5; y1=71; x2=50; y2=78; output;
  function="text"; x1=27.5; y1=74.5; textsize=9;
    label="Š°‰ğ“±“ü—Ã–@1  &n_ind1. —á"; anchor="center"; output;
  function="arrow"; x1=27.5; y1=71; x2=27.5; y2=66; output;
  function="line"; x1=27.5; y1=68.5; x2=52; y2=68.5; output;
  function="arrow"; x1=52; y1=68.5; x2=54; y2=68.5; output;

  /* [4] Š°‰ğ“±“ü—Ã–@2 */
  function="rectangle"; x1=5; y1=60; x2=50; y2=67; output;
  function="text"; x1=27.5; y1=63.5; textsize=9;
    label="Š°‰ğ“±“ü—Ã–@2  &n_ind2. —á  ¦1‰ñ–Ú”ñŠ°‰ğ—á‚Ì‚İ"; anchor="center"; output;
  function="arrow"; x1=27.5; y1=60; x2=27.5; y2=55; output;
  function="line"; x1=27.5; y1=57.5; x2=52; y2=57.5; output;
  function="arrow"; x1=52; y1=57.5; x2=54; y2=57.5; output;

  /* [5] ’nŒÅ‚ß—Ã–@1 */
  function="rectangle"; x1=5; y1=49; x2=50; y2=56; output;
  function="text"; x1=27.5; y1=52.5; textsize=9;
    label="’nŒÅ‚ß—Ã–@1  &n_c1. —á"; anchor="center"; output;
  function="arrow"; x1=27.5; y1=49; x2=27.5; y2=44; output;
  function="line"; x1=27.5; y1=46.5; x2=52; y2=46.5; output;
  function="arrow"; x1=52; y1=46.5; x2=54; y2=46.5; output;

  /* [6] ’nŒÅ‚ß—Ã–@2 */
  function="rectangle"; x1=5; y1=38; x2=50; y2=45; output;
  function="text"; x1=27.5; y1=41.5; textsize=9;
    label="’nŒÅ‚ß—Ã–@2  &n_c2. —á"; anchor="center"; output;
  function="arrow"; x1=27.5; y1=38; x2=27.5; y2=33; output;
  function="line"; x1=27.5; y1=35.5; x2=52; y2=35.5; output;
  function="arrow"; x1=52; y1=35.5; x2=54; y2=35.5; output;

  /* [7] ’nŒÅ‚ß—Ã–@3 */
  function="rectangle"; x1=5; y1=27; x2=50; y2=34; output;
  function="text"; x1=27.5; y1=30.5; textsize=9;
    label="’nŒÅ‚ß—Ã–@3  &n_c3. —á"; anchor="center"; output;
  function="arrow"; x1=27.5; y1=27; x2=27.5; y2=22; output;
  function="line"; x1=27.5; y1=24.5; x2=52; y2=24.5; output;
  function="arrow"; x1=52; y1=24.5; x2=54; y2=24.5; output;

  /* [8] Œ±¡—ÃŠ®—¹ */
  function="rectangle"; x1=5; y1=16; x2=50; y2=23; output;
  function="text"; x1=27.5; y1=19.5; textsize=10; textweight="bold";
    label="Œ±¡—ÃŠ®—¹  &n_comp. —á"; anchor="center"; output;
  function="arrow"; x1=27.5; y1=16; x2=27.5; y2=11; textweight="normal"; output;

  /* [9] ‰ğÍW’c */
  function="rectangle"; x1=5; y1=3; x2=50; y2=11; output;
  function="text"; x1=27.5; y1=9.5; textsize=9;
    label="FAS: &n_fas. —á"; anchor="center"; output;
  function="text"; x1=27.5; y1=7; textsize=9;
    label="PPS: &n_pps. —á"; anchor="center"; output;
  function="text"; x1=27.5; y1=4.5; textsize=9;
    label="SAF: &n_saf. —á"; anchor="center"; output;

  /* ===== ‰E—ñFœŠOE’†~ ===== */
  /* [A] FASœŠO */
  function="rectangle"; x1=54; y1=86; x2=100; y2=100; output;
  function="text"; x1=77; y1=98.5; textsize=9; textweight="bold";
    label="FASœŠO—á  &n_excl. —á"; anchor="center"; output;
  function="text"; x1=56; y1=96; textsize=7.5; textweight="normal";
    label="EŒ±¡—ÃŠJn‘O‚É’†~ (SCREEN FAILURE)  4—á"; anchor="left"; output;
  function="text"; x1=57; y1=93.5; textsize=7;
    label="#9,#67(“KŠiŠO), #57,#114(•aóˆ«‰»)"; anchor="left"; output;
  function="text"; x1=56; y1=91; textsize=7.5;
    label="E–Œã•s“KŠi (PROTOCOL DEVIATION)  3—á"; anchor="left"; output;
  function="text"; x1=57; y1=88.5; textsize=7;
    label="#84,#97(œŠOŠî€’ïG), #122(“¯ˆÓ‘•´¸)"; anchor="left"; output;

  /* [B] Š°‰ğ“±“ü—Ã–@1 ’†~ */
  function="rectangle"; x1=54; y1=66; x2=100; y2=82; output;
  function="text"; x1=77; y1=80.5; textsize=9; textweight="bold";
    label="Œ±¡—Ã’†~  &n_disc_ind1. —á"; anchor="center"; output;
  function="text"; x1=56; y1=78.5; textsize=7.5; textweight="normal";
    label="Œ±’†~‚É”º‚í‚È‚¢¡—Ã’†~  13—á"; anchor="left"; output;
  function="text"; x1=57; y1=76.5; textsize=7;
    label="—LŠQ–Û2, ˆãt”»’f29, Œp‘±Šî€–¢[‘«15, Ä”­1, ”íŒ±Ò”»’f3"; anchor="left"; output;
  function="text"; x1=56; y1=74.5; textsize=7.5;
    label="Œ±¡—Ã‚É”º‚¤Œ±’†~  2—á: €–S1, “¯ˆÓ“P‰ñ1"; anchor="left"; output;
  function="text"; x1=56; y1=72.5; textsize=7.5;
    label="Œ±’†~  39—á"; anchor="left"; output;
  function="text"; x1=57; y1=70.5; textsize=7;
    label="€–S30, ’ÇÕ•s”\8, “¯ˆÓ“P‰ñ1"; anchor="left"; output;

  /* [C] Š°‰ğ“±“ü—Ã–@2 ’†~ */
  function="rectangle"; x1=54; y1=55; x2=100; y2=66; output;
  function="text"; x1=77; y1=64.5; textsize=9; textweight="bold";
    label="Œ±¡—Ã’†~  &n_disc_ind2. —á"; anchor="center"; output;
  function="text"; x1=56; y1=62.5; textsize=7.5; textweight="normal";
    label="Œ±’†~‚É”º‚í‚È‚¢¡—Ã’†~  3—á"; anchor="left"; output;
  function="text"; x1=57; y1=60.5; textsize=7;
    label="ˆãt”»’f2, —LŠQ–Û1"; anchor="left"; output;
  function="text"; x1=56; y1=58.5; textsize=7.5;
    label="—LŒø«Œ‡”@ (LACK OF EFFICACY)  15—á"; anchor="left"; output;
  function="text"; x1=56; y1=56.5; textsize=7.5;
    label="Œ±’†~  15—á: €–S12, ’ÇÕ•s”\3"; anchor="left"; output;

  /* [D] ’nŒÅ‚ß—Ã–@1 ’†~ */
  function="rectangle"; x1=54; y1=44; x2=100; y2=55; output;
  function="text"; x1=77; y1=53.5; textsize=9; textweight="bold";
    label="Œ±¡—Ã’†~  &n_disc_c1. —á"; anchor="center"; output;
  function="text"; x1=56; y1=51.5; textsize=7.5; textweight="normal";
    label="Œ±’†~‚É”º‚í‚È‚¢¡—Ã’†~  1—á"; anchor="left"; output;
  function="text"; x1=57; y1=49.5; textsize=7;
    label="ˆãt”»’f2, Ä”­3, ”íŒ±Ò”»’f1, —LŠQ–Û1"; anchor="left"; output;
  function="text"; x1=56; y1=47.5; textsize=7.5;
    label="Œ±’†~  6—á: €–S6"; anchor="left"; output;

  /* [E] ’nŒÅ‚ß—Ã–@2 ’†~ */
  function="rectangle"; x1=54; y1=33; x2=100; y2=44; output;
  function="text"; x1=77; y1=42.5; textsize=9; textweight="bold";
    label="Œ±¡—Ã’†~  &n_disc_c2. —á"; anchor="center"; output;
  function="text"; x1=56; y1=40.5; textsize=7.5; textweight="normal";
    label="Œ±’†~‚É”º‚í‚È‚¢¡—Ã’†~  1—á: ˆãt”»’f2, ”íŒ±Ò”»’f1"; anchor="left"; output;
  function="text"; x1=56; y1=38.5; textsize=7.5;
    label="Œ±¡—Ã‚É”º‚¤Œ±’†~  1—á: “¯ˆÓ“P‰ñ1"; anchor="left"; output;
  function="text"; x1=56; y1=36.5; textsize=7.5;
    label="Œ±’†~  3—á: €–S1, ’ÇÕ•s”\1, “¯ˆÓ“P‰ñ1"; anchor="left"; output;

  /* [F] ’nŒÅ‚ß—Ã–@3 ’†~ */
  function="rectangle"; x1=54; y1=22; x2=100; y2=33; output;
  function="text"; x1=77; y1=31.5; textsize=9; textweight="bold";
    label="Œ±¡—Ã’†~  &n_disc_c3. —á"; anchor="center"; output;
  function="text"; x1=56; y1=29.5; textsize=7.5; textweight="normal";
    label="Œ±’†~‚É”º‚í‚È‚¢¡—Ã’†~  1—á: ˆãt”»’f2, Ä”­1, PRTˆá”½1(#24)"; anchor="left"; output;
  function="text"; x1=56; y1=27.5; textsize=7.5;
    label="Œ±¡—Ã‚É”º‚¤Œ±’†~  1—á: €–S1"; anchor="left"; output;
  function="text"; x1=56; y1=25.5; textsize=7.5;
    label="Œ±’†~  4—á: €–S4"; anchor="left"; output;

  /* [G] Œ±¡—ÃŠ®—¹Œã‚ÌŒ±’†~ */
  function="rectangle"; x1=54; y1=11; x2=100; y2=22; output;
  function="text"; x1=77; y1=20.5; textsize=9; textweight="bold";
    label="Œ±’†~  14—á"; anchor="center"; output;
  function="text"; x1=56; y1=18.5; textsize=7.5; textweight="normal";
    label="€–S  12—á"; anchor="left"; output;
  function="text"; x1=56; y1=16.5; textsize=7.5;
    label="’ÇÕ•s”\  1—á"; anchor="left"; output;
  function="text"; x1=56; y1=14.5; textsize=7.5;
    label="”íŒ±Ò‚É‚æ‚é“¯ˆÓ“P‰ñ  1—á"; anchor="left"; output;

  /* ’ÇÕ’† */
  function="text"; x1=56; y1=9; textsize=8;
    label="’ÇÕ’†  21—á"; anchor="left"; output;
  function="text"; x1=56; y1=6.5; textsize=8;
    label="’ÇÕ’†  19—á  (Œ±’†~Œã)"; anchor="left"; output;

run;

data _dummy; x=50; y=50; run;

TITLE1 'JALSG-GML219';
title2 '‘ÎÛŠ³Òƒtƒ[ƒ`ƒƒ[ƒg (SAP 4.1)';
ods graphics on / width=26cm height=34cm imagename="Fig0_Flowchart";
ods rtf file="&output.\JALSG-GML219 Fig0_&DATE..rtf" style=listing;
ods escapechar='^';
footnote2 "^S={just=r} o—Í“ú &DATE";

proc sgplot data=_dummy sganno=anno noautolegend noborder;
  scatter x=x y=y / markerattrs=(size=0 color=white);
  xaxis min=0 max=100 display=none;
  yaxis min=0 max=100 display=none;
run;

ods graphics off;
ods rtf close;
proc printto; run;