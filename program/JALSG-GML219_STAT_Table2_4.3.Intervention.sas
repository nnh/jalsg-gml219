**********************************************************************;
* Project           : JALSG-GML219
*
* Program name      : JALSG-GML219_Table2_4.3.Interventions.sas
*
* Author            : AKIKO SAITO
*
* Date created      : 20251209 
* Date updated      : 20251209 
* Description        : JALSG-GML219 Table 2　試験治療
**********************************************************************;

/*** initial setting ***/

title ;
footnote ;
proc datasets library = work kill nolist; quit;

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

libname libraw  "&_wk_path.\input\ads"  access = readonly;
libname libext  "&_wk_path.\input\ext"      access = readonly;
libname libout  "&_wk_path.\output";

%let output = &_wk_path.\output ;
%let log = &_wk_path.\log;
%let ext = &_wk_path.\input\ext;
%let raw = &_wk_path.\input\rawdata;
%let ads = &_wk_path.\input\ads;
%let template = &_wk_path.\output\template;

proc printto log="&log.\JALSG-GML219_STAT_Table2_&DATE.log" new ; run;

options  validvarname=v7
         fmtsearch = (libout work)
         sasautos = ("&_wk_path.\program\macro") cmdmac
         nofmterr
         nomlogic nosymbolgen nomprint
         ls = 100 missing = "" pageno = 1;


/*** Data Reading ***/
data  gml219;
  set  libraw.gml219;
run ;

/*　FAS */
data FAS ;  set gml219;
 if FASFL = "Y" ;run ;

TITLE1 'JALSG-GML219' ;

ods rtf file="&output.\JALSG-GML219 Table2_&DATE.rtf" style=listing;
ods escapechar='^';
/*footnote1  "^S={just=c} ^{thispage} / ^{lastpage} ";*/
footnote2  "^S={just=r} 出力日 &DATE"  ;
options nodate nonumber;


title2 '治療 (FAS)' ;
title3 '寛解導入療法1 (FAS)' ;

proc tabulate data=FAS missing;
  var i1_AraCdose i1_AraCdays i1_DNRdose i1_DNRdays;
  table 
    (i1_AraCdose i1_AraCdays i1_DNRdose i1_DNRdays),
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

title3 '寛解導入療法2 (FAS)' ;

proc tabulate data=FAS missing;
  var i2_AraCdose i2_AraCdays i2_DNRdose i2_DNRdays;
  table 
    (i2_AraCdose i2_AraCdays i2_DNRdose i2_DNRdays),
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


title3 '地固め療法1 (FAS)' ;

proc tabulate data=FAS missing;
  var c1_AraCdose c1_AraCdays c1_MITdose c1_MITdays;
  table 
    (c1_AraCdose c1_AraCdays c1_MITdose c1_MITdays),
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


title3 '地固め療法2 (FAS)' ;

proc tabulate data=FAS missing;
  var c2_AraCdose c2_AraCdays c2_DNRdose c2_DNRdays;
  table 
    (c2_AraCdose c2_AraCdays c2_DNRdose c2_DNRdays),
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

title3 '地固め療法3 (FAS)' ;

proc tabulate data=FAS missing;
  var c3_ACRdose c3_ACRdays c3_AraCdose c3_AraCdays;
  table 
    (c3_ACRdose c3_ACRdays c3_AraCdose c3_AraCdays),
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

proc printto ; run;
