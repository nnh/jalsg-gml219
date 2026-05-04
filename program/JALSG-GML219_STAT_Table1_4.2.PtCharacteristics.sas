**********************************************************************;
* Project      : JALSG-GML219
* Program name : JALSG-GML219_STAT_Table1_4.2.PtCharacteristics.sas
* Author       : AKIKO SAITO
* Date created : 20260504
* Description  : Š³Ò”wŒi (Table 1 / SAP 4.2)
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

proc printto log="&log.\JALSG-GML219_STAT_Table1_&DATE..log" new; run;

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
  value $SEXfm   'F'='—«'    'M'='’j«';
  value $ynfm    'N'='‚È‚µ'    'Y'='‚ ‚è';
  value $cdfm    'NEGATIVE'='‰A«' 'POSITIVE'='—z«' ' '='ŒŸ¸–¢{s';
  value $chromfm 'N'='‚È‚µ'    'P'='‚ ‚è'    ' '='ŒŸ¸–¢{s';
  value $cnsfm   'N'='‚È‚µ'    'Y'='‚ ‚è'    'NA'='•]‰¿•s‰Â' ' '='•]‰¿–¢{s';
run;

TITLE1 'JALSG-GML219';
ods rtf file="&output.\JALSG-GML219 Table1_&DATE..rtf" style=listing;
ods escapechar='^';
footnote2 "^S={just=r} o—Í“ú &DATE";

/*--- ˜A‘±•Ï”F”N—îEŒŸ¸’l ---*/
title2 'Š³Ò”wŒi (FAS) - ˜A‘±•Ï”';
proc tabulate data=FAS missing;
  var age cci_bl bl_bblast bl_pblast bl_wbc bl_hgb bl_plat
      bl_ldh bl_ast bl_alt bl_ptinr;
  table
    (age cci_bl bl_bblast bl_pblast bl_wbc bl_hgb bl_plat
     bl_ldh bl_ast bl_alt bl_ptinr),
    (n*f=8.
     mean*f=8.1
     std='SD'*f=8.1
     min*f=8.1
     q1='25%“_'*f=8.1
     median*f=8.1
     q3='75%“_'*f=8.1
     max*f=8.1)
  / misstext='.';
run;

/*--- ƒJƒeƒSƒŠ•Ï” ---*/
title2 'Š³Ò”wŒi (FAS) - ƒJƒeƒSƒŠ•Ï”';
proc tabulate data=FAS missing;
  class SEX agegrp ECOGPS
        dxmhterm dxmhtermc dxmhtermfab dxmhtermfabc
        flt3itd npm1
        bl_geneCEBPAyn bl_geneKITyn bl_generunx1yn bl_geneSF3B1yn
        bl_chromcta3kmyn
        bl_chromdel5qyn bl_chrominv16yn bl_chrominv3yn
        bl_chrommns17abnyn bl_chrommns5yn bl_chrommns7yn
        bl_chromt122p13qyn bl_chromt1616yn bl_chromt69yn
        bl_chromt821yn bl_chromt911yn bl_chromt922yn bl_chromtv11q233yn
        bl_cd33yn bl_cd34yn bl_cd117yn bl_cdhladryn
        bl_cnsyn bl_ocnsyn;
  table
    (SEX agegrp ECOGPS
     dxmhterm dxmhtermc dxmhtermfab dxmhtermfabc
     flt3itd npm1
     bl_geneCEBPAyn bl_geneKITyn bl_generunx1yn bl_geneSF3B1yn
     bl_chromcta3kmyn
     bl_chromdel5qyn bl_chrominv16yn bl_chrominv3yn
     bl_chrommns17abnyn bl_chrommns5yn bl_chrommns7yn
     bl_chromt122p13qyn bl_chromt1616yn bl_chromt69yn
     bl_chromt821yn bl_chromt911yn bl_chromt922yn bl_chromtv11q233yn
     bl_cd33yn bl_cd34yn bl_cd117yn bl_cdhladryn
     bl_cnsyn bl_ocnsyn),
    all='‘S—á' * (n pctn='%'*f=8.1)
  / misstext='0';
  format SEX $SEXfm.
         flt3itd npm1 $cdfm.
         bl_cd33yn bl_cd34yn bl_cd117yn bl_cdhladryn $cdfm.
         bl_chromcta3kmyn bl_chromdel5qyn bl_chrominv16yn bl_chrominv3yn
         bl_chrommns17abnyn bl_chrommns5yn bl_chrommns7yn
         bl_chromt122p13qyn bl_chromt1616yn bl_chromt69yn
         bl_chromt821yn bl_chromt911yn bl_chromt922yn bl_chromtv11q233yn $chromfm.
         bl_geneCEBPAyn bl_geneKITyn bl_generunx1yn bl_geneSF3B1yn $ynfm.
         bl_cnsyn bl_ocnsyn $cnsfm.;
run;

/*--- {İ•Ê ---*/
title2 '{İ•Ê“o˜^” (FAS)';
proc tabulate data=FAS missing;
  class sitenm;
  table
    (sitenm),
    all='‘S—á' * (n pctn='%'*f=8.1)
  / misstext='0';
run;

ods rtf close;
proc printto; run;