**********************************************************************;
* Project           : JALSG-GML219
*
* Program name      : JALSG-GML219_Table5_4.4.7.CRrate.sas
*
* Author            : AKIKO SAITO
*
* Date created      : 20251209
* Date updated      : 20251209 
* Description        : JALSG-GML219 Table 5Å@CRó¶
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

proc printto log="&log.\JALSG-GML219_STAT_Table5_&DATE.log" new ; run;

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

/*Å@FAS */
data FAS ;  set gml219;
 if FASFL = "Y" ;run ;

TITLE1 'JALSG-GML219' ;

ods rtf file="&output.\JALSG-GML219 Table5_&DATE..rtf" style=listing;
/*ods rtf file="&_PATH.\output\JALSG-APL219R baseline_&DATE..doc" style=listing ;*/
ods escapechar='^';
/*footnote1  "^S={just=c} ^{thispage} / ^{lastpage} ";*/
footnote2  "^S={just=r} èoóÕì˙ &DATE"  ;
options nodate nonumber;

/*** Format ***/
proc format ;
 value $SEXfm  'F'='èóê´' 'M'='íjê´' ;
 value $ATRAsynfm  'N'='Ç»Çµ' 'Y'='Ç†ÇË';
 value $hrlyn_bl    'N'='çƒî≠Ç»Çµ' 'Y'='çƒî≠Ç†ÇË' ' '='åüç∏ñ¢é{çs';
 value $mrlyn_bl   'N'='çƒî≠Ç»Çµ' 'Y'='çƒî≠Ç†ÇË' ' '='åüç∏ñ¢é{çs';
 value $pretxt   'N'='Ç»Çµ' 'Y'='Ç†ÇË';
 value $bl_cnsyn   'N'='Ç»Çµ' 'Y'='Ç†ÇË' 'NA'='ï]âøïsî\' ' '='ï]âøñ¢é{çs' ;
 value $bl_ocnsyn   'N'='Ç»Çµ' 'Y'='Ç†ÇË' 'NA'='ï]âøïsî\' ' '='ï]âøñ¢é{çs' ;
 value $bl_cd56yn   'NEGATIVE'='âAê´' 'POSITIVE'='ózê´' ' '='åüç∏ñ¢é{çs' ;
 value $ri_cnsyn    'N'='Ç»Çµ' 'Y'='Ç†ÇË' 'NA'='ï]âøïsî\' ' '='ï]âøñ¢é{çs' ;
 value $ri_ocnsyn   'N'='Ç»Çµ' 'Y'='Ç†ÇË' 'NA'='ï]âøïsî\' ' '='ï]âøñ¢é{çs' ;
 value $kankai   'N'='îÒä∞â' 'Y'='ä∞â' 'NA'='ï]âøïsî\' ' '='ï]âøñ¢é{çs' ;
 value $kensa   'NOT DONE'='ï]âøñ¢é{çs';
 
run ;


title2 'ä∞âì±ì¸ó¶ (FAS)' ;

proc tabulate data=FAS missing; 
  class Ind1_oryn CR1yn;
  table 
    (Ind1_oryn i1_cnsyn i1_ocnsyn CR1yn),
    all='ëSëÃ' * (n pctn='%'*f=8.1)
  / misstext='0';
  format Ind1oryn cr1yn $kankai.;
run;

proc tabulate data=FAS missing;
  var daysto1cr days;
  table 
    (daysto1cr ),
    (n*f=8. 
     mean*f=8.1 
     std='SD'*f=8.1 
     min*f=8.1 
     q1='25%ì_'*f=8.1 
     median*f=8.1 
     q3='75%ì_'*f=8.1 
     max*f=8.1)
  / misstext='.';
run;

ods rtf close;

proc printto ; run;

