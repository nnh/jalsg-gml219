options obs=100;

/* ------------------------------------------------------------------ *
 * jenner-check autoexec for t001_lifetest_os_km
 *
 * The upstream program reads the analysis dataset GML219 from an
 * external library (libname libraw "...\input\ads") that is not part
 * of the public repository. This autoexec stands in a small, synthetic
 * GML219 dataset with the same columns the program reads
 * (FASFL, OS_y, os_c) so the survival analysis runs in isolation.
 * The numbers are fabricated for the demo; only the structure matters.
 * ------------------------------------------------------------------ */
data gml219;
  length USUBJID $12 FASFL $1;
  input USUBJID $ FASFL $ OS_y os_c;
  datalines;
GML219-0001 Y 0.45 1
GML219-0002 Y 4.80 0
GML219-0003 Y 1.20 1
GML219-0004 Y 5.00 0
GML219-0005 Y 0.80 1
GML219-0006 Y 3.60 0
GML219-0007 Y 2.10 1
GML219-0008 Y 4.95 0
GML219-0009 Y 0.30 1
GML219-0010 Y 5.00 0
GML219-0011 Y 1.75 1
GML219-0012 Y 4.20 0
GML219-0013 Y 2.90 1
GML219-0014 Y 5.00 0
GML219-0015 Y 0.95 1
GML219-0016 Y 3.10 0
GML219-0017 Y 4.40 0
GML219-0018 Y 1.50 1
GML219-0019 Y 2.65 0
GML219-0020 Y 5.00 0
GML219-0021 Y 0.60 1
GML219-0022 Y 4.85 0
GML219-0023 Y 3.30 1
GML219-0024 Y 5.00 0
GML219-0025 Y 1.05 1
GML219-0026 Y 2.40 0
GML219-0027 Y 4.10 0
GML219-0028 Y 0.70 1
GML219-0029 Y 3.95 0
GML219-0030 Y 5.00 0
GML219-0031 Y 1.30 1
GML219-0032 Y 4.55 0
GML219-0033 Y 2.20 1
GML219-0034 Y 5.00 0
GML219-0035 Y 0.50 1
GML219-0036 Y 3.75 0
GML219-0037 Y 4.30 0
GML219-0038 Y 1.90 1
GML219-0039 Y 2.80 0
GML219-0040 Y 5.00 0
GML219-0041 N 0.40 1
GML219-0042 N 1.10 0
;
run;
