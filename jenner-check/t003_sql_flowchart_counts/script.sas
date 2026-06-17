/**********************************************************************
* Adapted from: program/JALSG-GML219_STAT_Fig0_4.1.Flowchart.sas
* Original author: AKIKO SAITO  (JALSG-GML219)
*
* Subject-disposition flowchart counts (SAP 4.1). The analytical core
* of the upstream Fig0 program is the PROC SQL block that derives every
* box count in the CONSORT-style flowchart with
* "select count(*) into :macrovar trimmed from gml219 where ...".
* This bundle keeps that SQL counting logic verbatim and assembles the
* counts into a small disposition table (PROC SQL select + PROC PRINT)
* instead of the upstream SGPLOT/annotate rendering.
*
* Changes from the original are mechanical only: the Windows
* libname / %working_dir / proc printto plumbing has been removed and
* GML219 is provided by the bundle autoexec. The SQL count expressions
* and the %eval derivations are exactly as written upstream.
**********************************************************************/

/*--- N counts (upstream SQL) ---*/
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
  select count(*)  into :n_pps      trimmed from gml219 where ppsfl="Y";
quit;

%let n_excl=%eval(&n_total. - &n_fas.);
%let n_ind1=&n_fas.;
%let n_saf=&n_fas.;
%let n_disc_c3=5;
%let n_comp=%eval(&n_c3. - &n_disc_c3.);

%put NOTE: n_total=&n_total n_fas=&n_fas n_excl=&n_excl n_comp=&n_comp;

/*--- Assemble the disposition counts into a table ---*/
data flowchart;
  length step $40 n 8;
  step="All registered";          n=&n_total.; output;
  step="FAS (excluded: &n_excl.)"; n=&n_fas.;  output;
  step="Induction course 1";      n=&n_ind1.;  output;
  step="Induction course 2";      n=&n_ind2.;  output;
  step="Consolidation course 1";  n=&n_c1.;    output;
  step="Consolidation course 2";  n=&n_c2.;    output;
  step="Consolidation course 3";  n=&n_c3.;    output;
  step="Completed treatment";     n=&n_comp.;  output;
  step="PPS";                     n=&n_pps.;   output;
run;

TITLE1 'JALSG-GML219';
title2 'Subject disposition flowchart counts (SAP 4.1)';

proc print data=flowchart noobs label;
  label step='Disposition step' n='N';
  var step n;
run;
