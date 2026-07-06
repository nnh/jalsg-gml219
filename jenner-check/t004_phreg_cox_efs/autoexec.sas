options obs=100;

/* ------------------------------------------------------------------ *
 * jenner-check autoexec for t004_phreg_cox_efs
 *
 * The upstream Cox program reads its analysis dataset from an external
 * library (libname libraw "...\input\ads") absent from the public
 * repository. This autoexec supplies a small synthetic dataset with
 * the columns the univariate Cox models read: the event-free-survival
 * time/censor pair (EFS_y, EFS_c), the FAS flag, and the two class
 * covariates used below (SEX, bl_wbcc). Values are fabricated for the
 * demo; only the structure matters.
 * ------------------------------------------------------------------ */
data gml219;
  length USUBJID $12 FASFL $1 SEX $1 bl_wbcc $20;
  input USUBJID $ FASFL $ SEX $ bl_wbcc & $20. EFS_y EFS_c;
  datalines;
GML219-0001 Y M 3,000/uL or more   0.45 1
GML219-0002 Y F under 3,000/uL     4.80 0
GML219-0003 Y M 3,000/uL or more   1.20 1
GML219-0004 Y F under 3,000/uL     5.00 0
GML219-0005 Y M 3,000/uL or more   0.80 1
GML219-0006 Y F under 3,000/uL     3.60 0
GML219-0007 Y M 3,000/uL or more   2.10 1
GML219-0008 Y F under 3,000/uL     4.95 0
GML219-0009 Y M 3,000/uL or more   0.30 1
GML219-0010 Y F under 3,000/uL     5.00 0
GML219-0011 Y M 3,000/uL or more   1.75 1
GML219-0012 Y F under 3,000/uL     4.20 0
GML219-0013 Y M 3,000/uL or more   2.90 1
GML219-0014 Y F under 3,000/uL     5.00 0
GML219-0015 Y M 3,000/uL or more   0.95 1
GML219-0016 Y F under 3,000/uL     3.10 0
GML219-0017 Y M under 3,000/uL     4.40 0
GML219-0018 Y F 3,000/uL or more   1.50 1
GML219-0019 Y M under 3,000/uL     2.65 0
GML219-0020 Y F 3,000/uL or more   5.00 0
GML219-0021 Y M under 3,000/uL     0.60 1
GML219-0022 Y F 3,000/uL or more   4.85 0
GML219-0023 Y M under 3,000/uL     3.30 1
GML219-0024 Y F 3,000/uL or more   5.00 0
GML219-0025 Y M under 3,000/uL     1.05 1
GML219-0026 Y F 3,000/uL or more   2.40 0
GML219-0027 Y M under 3,000/uL     4.10 0
GML219-0028 Y F 3,000/uL or more   0.70 1
GML219-0029 Y M under 3,000/uL     3.95 0
GML219-0030 Y F 3,000/uL or more   5.00 0
;
run;
