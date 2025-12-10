**********************************************************************;
* Project            : JALSG-GML219
*
* Program name   : JALSG-GML219_Table1_4.2.PtCharacteristics.sas
*
* Author             : AKIKO SAITO
*
* Date created      : 20251208 
* Date updated      : 20251209 
* Description        : JALSG-GML219 Table 1Å@ä≥é“îwåi
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

/*proc printto log="&log.\JALSG-GML219_STAT_Table1_&DATE.log" new ; run;*/

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

ods rtf file="&output.\JALSG-GML219 Table1_&DATE..rtf" style=listing;
ods escapechar='^';
footnote2  "^S={just=r} èoóÕì˙ &DATE"  ;
options nodate nonumber;

/*** Format ***/
proc format ;
 value $SEXfm  'F'='èóê´' 'M'='íjê´' ;
 value $cd   'N'='Ç»Çµ' 'Y'='Ç†ÇË';
 value $bl_cnsyn   'N'='Ç»Çµ' 'Y'='Ç†ÇË' 'NA'='ï]âøïsî\' ' '='ï]âøñ¢é{çs' ;
 value $bl_ocnsyn   'N'='Ç»Çµ' 'Y'='Ç†ÇË' 'NA'='ï]âøïsî\' ' '='ï]âøñ¢é{çs' ;
 value $bl_cd   'NEGATIVE'='âAê´' 'POSITIVE'='ózê´' ' '='åüç∏ñ¢é{çs' ;
 value $bl_chrom   'N'='Ç»Çµ' 'P'='Ç†ÇË' ' '='åüç∏ñ¢é{çs' ;

run ;

title2 'ä≥é“îwåi (FAS)' ;

proc tabulate data=FAS missing; 
  class SEX ECOGPS dxmhterm dxmhtermc dxmhtermfab dxmhtermfabc 
          bl_chromdel5qyn
          bl_chrominv16yn
          bl_chrominv3yn
          bl_chrommns17abnyn
          bl_chrommns5yn
          bl_chrommns7yn
          bl_chromt122p13qyn
          bl_chromt1616yn
          bl_chromt69yn
          bl_chromt821yn
          bl_chromt911yn
          bl_chromt922yn
          bl_chromtv11q233yn
		  bl_chromcta3kmyn
          bl_cd10yn
          bl_cd117yn
          bl_cd11byn
          bl_cd13yn
          bl_cd14yn
          bl_cd16yn
          bl_cd19yn
          bl_cd20yn
          bl_cd2yn
          bl_cd33yn
          bl_cd34yn
          bl_cd3yn
          bl_cd41ayn
          bl_cd4yn
          bl_cd56yn
          bl_cd5yn
          bl_cd7yn
          bl_cd8yn
          bl_cdglcfayn
          bl_cdhladryn
		  bl_geneCEBPAyn
          bl_geneKITyn
          bl_geneSF3B1yn
          bl_geneflt3yn
          bl_genenpm1yn
          bl_generunx1yn
          bl_cnsyn bl_cns_fastat bl_ocnsyn bl_ocns_fastat;
  table 
    (SEX ECOGPS dxmhterm dxmhtermc dxmhtermfab dxmhtermfabc 
          bl_chromdel5qyn
          bl_chrominv16yn
          bl_chrominv3yn
          bl_chrommns17abnyn
          bl_chrommns5yn
          bl_chrommns7yn
          bl_chromt122p13qyn
          bl_chromt1616yn
          bl_chromt69yn
          bl_chromt821yn
          bl_chromt911yn
          bl_chromt922yn
          bl_chromtv11q233yn
		  bl_chromcta3kmyn
          bl_cd10yn
          bl_cd117yn
          bl_cd11byn
          bl_cd13yn
          bl_cd14yn
          bl_cd16yn
          bl_cd19yn
          bl_cd20yn
          bl_cd2yn
          bl_cd33yn
          bl_cd34yn
          bl_cd3yn
          bl_cd41ayn
          bl_cd4yn
          bl_cd56yn
          bl_cd5yn
          bl_cd7yn
          bl_cd8yn
          bl_cdglcfayn
          bl_cdhladryn
		  bl_geneCEBPAyn
          bl_geneKITyn
          bl_geneSF3B1yn
          bl_geneflt3yn
          bl_genenpm1yn
          bl_generunx1yn
          bl_cnsyn bl_cns_fastat bl_ocnsyn bl_ocns_fastat),
    all='ëSëÃ' * (n pctn='%'*f=8.1)
  / misstext='0';
 format SEX $SEXfm.;
 format bl_chromcta3kmyn
          bl_chromdel5qyn
          bl_chrominv16yn
          bl_chrominv3yn
          bl_chrommns17abnyn
          bl_chrommns5yn
          bl_chrommns7yn
          bl_chromt122p13qyn
          bl_chromt1616yn
          bl_chromt69yn
          bl_chromt821yn
          bl_chromt911yn
          bl_chromt922yn
          bl_chromtv11q233yn $bl_chrom. 
          bl_cd10yn
          bl_cd117yn
          bl_cd11byn
          bl_cd13yn
          bl_cd14yn
          bl_cd16yn
          bl_cd19yn
          bl_cd20yn
          bl_cd2yn
          bl_cd33yn
          bl_cd34yn
          bl_cd3yn
          bl_cd41ayn
          bl_cd4yn
          bl_cd56yn
          bl_cd5yn
          bl_cd7yn
          bl_cd8yn
          bl_cdglcfayn
          bl_cdhladryn $bl_cd.;
 format bl_geneCEBPAyn
          bl_geneKITyn
          bl_geneSF3B1yn
          bl_geneflt3yn
          bl_genenpm1yn
          bl_generunx1yn  $bl_cd.;
 format bl_cnsyn bl_ocnsyn $bl_cnsyn.;
run;

proc tabulate data=FAS missing;
  var age bl_bblast bl_pblast bl_wbc bl_plat bl_ptinr;
  table 
    (age bl_bblast bl_pblast bl_wbc bl_plat bl_ptinr),
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

title2 'é{ê›ï ìoò^êî (FAS)' ;
proc tabulate data=FAS missing; 
  class sitenm;
  table 
    (sitenm),
    all='ëSëÃ' * (n pctn='%'*f=8.1)
  / misstext='0';
run;

ods rtf close;

proc printto ; run;
