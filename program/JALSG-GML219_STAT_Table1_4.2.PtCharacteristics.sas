**********************************************************************;
* Project      : JALSG-GML219
* Program name : JALSG-GML219_STAT_Table1_4.2.PtCharacteristics.sas
* Author       : AKIKO SAITO
* Date created : 20260504
* Date updated : 20260505
* Description  : Š³Ò”wŒi (Table 1 / SAP 4.2 / 5.2.1)
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
        nomlogic nosymbolgen nomprint ls=120 missing="" pageno=1
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
  value $ynfm    'N'='‚È‚µ'    'Y'='‚ ‚è' 'NA'='•]‰¿•s”\' ' '='•]‰¿–¢À{';
  value $cdfm    'NEGATIVE'='‰A«' 'POSITIVE'='—z«' ' '='ŒŸ¸–¢À{';
  value $chromfm 'N'='‚È‚µ'    'P'='‚ ‚è' 'Y'='‚ ‚è' ' '='ŒŸ¸–¢À{';
  value $cnsfm   'N'='‚È‚µ'    'Y'='‚ ‚è' 'NA'='•]‰¿•s”\' ' '='•]‰¿–¢À{';
  value $compfm  'Myeloablative Conditioning'='œ‘”j‰ó“I'
                 'Reduced-toxicity Conditioning'='œ‘”ñ”j‰ó“I'
                 ' '='-';
run;

TITLE1 'JALSG-GML219';
ods rtf file="&output.\JALSG-GML219 Table1_&DATE..rtf" style=listing;
ods escapechar='^';
footnote2 "^S={just=r} o—Í“ú &DATE";

/*=====================================================================*/
/* (1) ˜A‘±•Ï”F”N—îEg’·E‘ÌdEBMIECCIEŒŒ‰tŒŸ¸E¶‰»ŠwEWT-1ECGA */
/*=====================================================================*/
title2 'Š³Ò”wŒi (FAS) - ˜A‘±•Ï”';
proc tabulate data=FAS missing;
  var age height weight bmi cci_bl
      bl_wbc bl_neut bl_hgb bl_plat bl_retirbc
      bl_blastle bl_myblale
      bl_ldh bl_ast bl_alt bl_alp bl_bili bl_creat bl_crp bl_alb
      bl_inr bl_ua bl_wt1mrna;
  table
    (age height weight bmi cci_bl
     bl_wbc bl_neut bl_hgb bl_plat bl_retirbc
     bl_blastle bl_myblale
     bl_ldh bl_ast bl_alt bl_alp bl_bili bl_creat bl_crp bl_alb
     bl_inr bl_ua bl_wt1mrna),
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

/*=====================================================================*/
/* (2) ƒJƒeƒSƒŠ•Ï”FŠî–{”wŒiEPSEWHO/FABEŠù‰ECNSZ              */
/*=====================================================================*/
title2 'Š³Ò”wŒi (FAS) - Šî–{‘®«EWHO/FAB•ª—Ş';
proc tabulate data=FAS missing;
  class SEX agegrp ecogps echo_result ecg_intp
        dxwhoterm fabclass fabgrp whogrp eln2017 eln2022
        bl_bldabn bl_traml bl_infect8w
        bl_cnsstat bl_cnsyn bl_ocnsstat bl_ocnsyn;
  table
    (SEX agegrp ecogps echo_result ecg_intp
     dxwhoterm fabclass fabgrp whogrp eln2017 eln2022
     bl_bldabn bl_traml bl_infect8w
     bl_cnsstat bl_cnsyn bl_ocnsstat bl_ocnsyn),
    all='‘S‘Ì' * (n pctn='%'*f=8.1)
  / misstext='0';
  format SEX $SEXfm.
         bl_bldabn bl_traml bl_infect8w $ynfm.
         bl_cnsyn bl_ocnsyn $cnsfm.;
run;

/*=====================================================================*/
/* (3) õF‘ÌˆÙíEˆâ“`q•ÏˆÙ                                          */
/*=====================================================================*/
title2 'Š³Ò”wŒi (FAS) - õF‘ÌˆÙíEˆâ“`q•ÏˆÙ';
proc tabulate data=FAS missing;
  class chroabno
        t821 inv16 t1616 t911 t69 t122p13q t922 inv3
        mns5 del5q mns7 mns17abn cta3km otchrabn
        flt3itd npm1 cebpa kit runx1 sf3b1;
  table
    (chroabno
     t821 inv16 t1616 t911 t69 t122p13q t922 inv3
     mns5 del5q mns7 mns17abn cta3km otchrabn
     flt3itd npm1 cebpa kit runx1 sf3b1),
    all='‘S‘Ì' * (n pctn='%'*f=8.1)
  / misstext='0';
  format chroabno
         t821 inv16 t1616 t911 t69 t122p13q t922 inv3
         mns5 del5q mns7 mns17abn cta3km otchrabn $chromfm.
         flt3itd npm1 cebpa kit runx1 sf3b1 $cdfm.;
run;

/*=====================================================================*/
/* (4) ×–E•\–Êƒ}[ƒJ[iCDEHLA-DREMPOEœ‘×–E–§“xj                */
/*=====================================================================*/
title2 'Š³Ò”wŒi (FAS) - ×–E•\–Êƒ}[ƒJ[';
proc tabulate data=FAS missing;
  class CD2 CD3 CD4 CD5 CD7 CD8 CD10 CD11b CD13 CD14 CD16 CD19 CD20
        CD33 CD34 CD41a CD56 CD117 HLADR glycoina mpo_cm cellular;
  table
    (CD2 CD3 CD4 CD5 CD7 CD8 CD10 CD11b CD13 CD14 CD16 CD19 CD20
     CD33 CD34 CD41a CD56 CD117 HLADR glycoina mpo_cm cellular),
    all='‘S‘Ì' * (n pctn='%'*f=8.1)
  / misstext='0';
  format CD2 CD3 CD4 CD5 CD7 CD8 CD10 CD11b CD13 CD14 CD16 CD19 CD20
         CD33 CD34 CD41a CD56 CD117 HLADR glycoina $cdfm.;
run;

/*=====================================================================*/
/* (5) Charlson Comorbidity Index (CCI) “à–ó                           */
/*=====================================================================*/
title2 'Š³Ò”wŒi (FAS) - Charlson Comorbidity Index (“o˜^)';
proc tabulate data=FAS missing;
  class cci_bl_fl
        cci_bl_MI cci_bl_CHF cci_bl_PVD cci_bl_CVD cci_bl_Dem cci_bl_CLD
        cci_bl_Col cci_bl_PU cci_bl_MLiv cci_bl_SLiv cci_bl_DC cci_bl_Hemi
        cci_bl_SR cci_bl_Met cci_bl_Leu cci_bl_Lym cci_bl_AIDS;
  table
    (cci_bl_fl
     cci_bl_MI cci_bl_CHF cci_bl_PVD cci_bl_CVD cci_bl_Dem cci_bl_CLD
     cci_bl_Col cci_bl_PU cci_bl_MLiv cci_bl_SLiv cci_bl_DC cci_bl_Hemi
     cci_bl_SR cci_bl_Met cci_bl_Leu cci_bl_Lym cci_bl_AIDS),
    all='‘S‘Ì' * (n pctn='%'*f=8.1)
  / misstext='0';
  format cci_bl_MI cci_bl_CHF cci_bl_PVD cci_bl_CVD cci_bl_Dem cci_bl_CLD
         cci_bl_Col cci_bl_PU cci_bl_MLiv cci_bl_SLiv cci_bl_DC cci_bl_Hemi
         cci_bl_SR cci_bl_Met cci_bl_Leu cci_bl_Lym cci_bl_AIDS $ynfm.;
run;

/*=====================================================================*/
/* (6) CGA7 ƒTƒu€–Úi“o˜^‚Ì‚İj                                     */
/*=====================================================================*/
title2 'Š³Ò”wŒi (FAS) - CGA7 ƒTƒu€–Ú (“o˜^)';
proc tabulate data=FAS missing;
  class cga1a_bl cga2a_bl cga3a_bl cga4a_bl cga5a_bl cga6a_bl cga7a_bl;
  table
    (cga1a_bl cga2a_bl cga3a_bl cga4a_bl cga5a_bl cga6a_bl cga7a_bl),
    all='‘S‘Ì' * (n pctn='%'*f=8.1)
  / misstext='0';
run;

/*=====================================================================*/
/* (7) {İ•Ê“o˜^”                                                    */
/*=====================================================================*/
title2 '{İ•Ê“o˜^” (FAS)';
proc tabulate data=FAS missing;
  class sitenm;
  table
    (sitenm),
    all='‘S‘Ì' * (n pctn='%'*f=8.1)
  / misstext='0';
run;

ods rtf close;
proc printto; run;
