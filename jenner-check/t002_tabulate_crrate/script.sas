/**********************************************************************
* Adapted from: program/JALSG-GML219_STAT_Table3_4.4.7.CRrate.sas
* Original author: AKIKO SAITO  (JALSG-GML219)
*
* CR rate / LFS rate / treatment-failure rate table (SAP 4.4.7).
* The analysis core is PROC TABULATE for the categorical response
* summaries and PROC FREQ with the BINOMIAL CL option for the exact
* binomial 95% confidence intervals on the achievement rates, plus a
* PROC TABULATE summary of the derived "days to CR / LFS" measures.
*
* Changes from the original are mechanical only: the Windows
* libname / %working_dir / proc printto / ods rtf plumbing has been
* removed, GML219 is provided by the bundle autoexec, and the Japanese
* PROC FORMAT value labels are transliterated to ASCII so the listing
* is legible in any locale. The derivation DATA step, the TABULATE
* CLASS / VAR layout and the FREQ BINOMIAL(level="Y") CL calls are
* exactly as written upstream.
**********************************************************************/

data FAS;
  set gml219;
  where FASFL = "Y";
run;

/*--- Derived variables: days from enrollment to CR / LFS ---*/
data FAS;
  set FAS;
  if crfl  = "Y" and crdt  ne . then daysto1cr  = crdt  - rfstdt + 1;
  if lfsfl = "Y" and lfsdt ne . then daysto1lfs = lfsdt - rfstdt + 1;
  label daysto1cr  = "Days from enrollment to CR"
        daysto1lfs = "Days from enrollment to LFS";
run;

proc format;
  value $respfm 'CR'='CR (complete remission)'
                'NON-CR/NON-PD'='NON-CR/NON-PD'
                'NE'='NE (not evaluable)'
                ' '='Not assessed';
  value $crflfm 'Y'='Achieved' 'N'='Not achieved';
  value $tffm   'Y'='Treatment failure' 'N'='No treatment failure';
  value $tftypef 'R'='Resistant' 'A'='Early death' 'U'='Indeterminate' ' '='-';
run;

TITLE1 'JALSG-GML219';

/*--- (1) Response after induction course 1 ---*/
title2 'Response after induction course 1 (FAS)';
proc tabulate data=FAS missing;
  class rs_ev1;
  table
    (rs_ev1),
    all='Total' * (n pctn='%'*f=8.1)
  / misstext='0';
  format rs_ev1 $respfm.;
run;

/*--- (2) Response after induction course 2 (2-course recipients only) ---*/
title2 'Response after induction course 2 (2-course recipients)';
proc tabulate data=FAS(where=(ind2fl="Y")) missing;
  class rs_ev2;
  table
    (rs_ev2),
    all='Total' * (n pctn='%'*f=8.1)
  / misstext='0';
  format rs_ev2 $respfm.;
run;

/*--- (3) CR achievement + exact binomial 95% CI ---*/
title2 'CR achievement (FAS)';
proc tabulate data=FAS missing;
  class crfl;
  table
    (crfl),
    all='Total' * (n pctn='%'*f=8.1)
  / misstext='0';
  format crfl $crflfm.;
run;

title3 'CR rate 95% confidence interval (binomial)';
proc freq data=FAS;
  tables crfl / binomial(level="Y") cl alpha=0.05;
run;

/*--- (4) LFS achievement + exact binomial 95% CI ---*/
title2 'LFS achievement (FAS)';
proc tabulate data=FAS missing;
  class lfsfl;
  table
    (lfsfl),
    all='Total' * (n pctn='%'*f=8.1)
  / misstext='0';
  format lfsfl $crflfm.;
run;

title3 'LFS rate 95% confidence interval (binomial)';
proc freq data=FAS;
  tables lfsfl / binomial(level="Y") cl alpha=0.05;
run;

/*--- (6) Days to CR (CR achievers) ---*/
title2 'Days from enrollment to CR (CR achievers)';
proc tabulate data=FAS(where=(crfl="Y")) missing;
  var daysto1cr;
  table
    (daysto1cr),
    (n*f=8.
     mean*f=8.1
     std='SD'*f=8.1
     min*f=8.1
     q1='25%'*f=8.1
     median*f=8.1
     q3='75%'*f=8.1
     max*f=8.1)
  / misstext='.';
run;
