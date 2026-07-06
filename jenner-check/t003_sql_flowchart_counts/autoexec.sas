options obs=100;

/* ------------------------------------------------------------------ *
 * jenner-check autoexec for t003_sql_flowchart_counts
 *
 * The upstream flowchart program reads GML219 from an external library
 * (libname libraw "...\input\ads") absent from the public repository.
 * This autoexec supplies a small synthetic GML219 with the per-course
 * disposition flags the flowchart counts on: fasfl and the course
 * flags ind2fl, c1fl, c2fl, c3fl, plus ppsfl. Values are fabricated
 * for the demo; only the structure matters.
 * ------------------------------------------------------------------ */
data gml219;
  length USUBJID $12 fasfl $1 ind2fl $1 c1fl $1 c2fl $1 c3fl $1 ppsfl $1;
  input USUBJID $ fasfl $ ind2fl $ c1fl $ c2fl $ c3fl $ ppsfl $;
  datalines;
GML219-0001 Y Y Y Y Y Y
GML219-0002 Y Y Y Y Y Y
GML219-0003 Y Y Y Y N Y
GML219-0004 Y Y Y N N Y
GML219-0005 Y Y N N N N
GML219-0006 Y N N N N Y
GML219-0007 Y Y Y Y Y Y
GML219-0008 Y Y Y Y N Y
GML219-0009 Y Y Y N N Y
GML219-0010 Y N N N N N
GML219-0011 Y Y Y Y Y Y
GML219-0012 Y Y Y Y Y Y
GML219-0013 Y Y Y Y N Y
GML219-0014 Y Y Y N N Y
GML219-0015 Y Y N N N Y
GML219-0016 Y N N N N N
GML219-0017 Y Y Y Y Y Y
GML219-0018 Y Y Y Y Y Y
GML219-0019 Y Y Y Y N Y
GML219-0020 Y Y Y N N Y
GML219-0021 N N N N N N
GML219-0022 N N N N N N
GML219-0023 N N N N N N
GML219-0024 N N N N N N
;
run;
