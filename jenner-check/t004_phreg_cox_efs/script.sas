/**********************************************************************
* Adapted from: program/202512 pgm v1/JALSG-GML219_STAT_Table6_4.x.x.EFSf_cox.sas
* Original author: AKIKO SAITO  (JALSG-GML219)
*
* Univariate Cox proportional-hazards models for event-free survival
* (EFS). The upstream Table6 program fits a series of single-covariate
* PROC PHREG models of the form
*     proc phreg data=fas; class <covar> (ref='...');
*     model EFS_y*EFS_c(0) = <covar> / rl; run;
* one per baseline factor, each reporting the hazard ratio with its
* Wald 95% confidence limits (the RL option). This bundle keeps two of
* those models (SEX and the baseline WBC category bl_wbcc) exactly as
* written upstream.
*
* Changes from the original are mechanical only: the Windows
* libname / %working_dir / proc printto plumbing has been removed and
* the analysis dataset is provided by the bundle autoexec. The CLASS
* reference coding, the MODEL time*censor(0)=covar form and the RL
* option are upstream-verbatim.
**********************************************************************/

data FAS;
  set gml219;
  where FASFL = "Y";
run;

TITLE1 'JALSG-GML219';

/*--- Univariate Cox: SEX ---*/
title2 'Univariate Cox PH model: EFS by SEX';
proc phreg data=FAS;
  class SEX (ref='M');
  model EFS_y*EFS_c(0) = SEX / rl;
run;

/*--- Univariate Cox: baseline WBC category ---*/
title2 'Univariate Cox PH model: EFS by baseline WBC category';
proc phreg data=FAS;
  class bl_wbcc (ref='3,000/uL or more');
  model EFS_y*EFS_c(0) = bl_wbcc / rl;
run;
