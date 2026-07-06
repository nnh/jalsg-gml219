options obs=100;

/* ------------------------------------------------------------------ *
 * jenner-check autoexec for t002_tabulate_crrate
 *
 * The upstream program reads the analysis dataset GML219 from an
 * external library (libname libraw "...\input\ads") absent from the
 * public repository. This autoexec supplies a small synthetic GML219
 * with the columns the CR-rate program reads: the response-evaluation
 * variables (rs_ev1, rs_ev2, ind2fl), the achievement flags
 * (crfl, lfsfl, tffl, tftype) and the dates used to derive the
 * "days to CR / LFS" measures (rfstdt, crdt, crfl, lfsdt, lfsfl).
 * Dates are stored as SAS date values via the yymmdd informat.
 * Values are fabricated for the demo; only the structure matters.
 * ------------------------------------------------------------------ */
data gml219;
  length USUBJID $12 FASFL $1 ind2fl $1
         rs_ev1 $13 rs_ev2 $13
         crfl $1 lfsfl $1 tffl $1 tftype $1;
  informat rfstdtc crdtc lfsdtc yymmdd10.;
  format   rfstdt  crdt  lfsdt  yymmdd10.;
  input USUBJID $ FASFL $ ind2fl $ rs_ev1 $ rs_ev2 $
        crfl $ lfsfl $ tffl $ tftype $
        rfstdtc :yymmdd10. crdtc :yymmdd10. lfsdtc :yymmdd10.;
  rfstdt = rfstdtc;
  crdt   = crdtc;
  lfsdt  = lfsdtc;
  drop rfstdtc crdtc lfsdtc;
  datalines;
GML219-0001 Y Y CR            CR            Y Y N R 2024-01-10 2024-02-20 2024-02-20
GML219-0002 Y Y CR            NON-CR/NON-PD Y N N R 2024-01-15 2024-03-01 .
GML219-0003 Y N NON-CR/NON-PD .             N N Y A 2024-02-01 .          .
GML219-0004 Y Y CR            CR            Y Y N R 2024-02-10 2024-03-25 2024-03-25
GML219-0005 Y Y NE            NE            N N Y U 2024-03-01 .          .
GML219-0006 Y Y CR            CR            Y Y N R 2024-03-15 2024-04-30 2024-04-30
GML219-0007 Y N CR            .             Y Y N R 2024-04-01 2024-05-10 2024-05-10
GML219-0008 Y Y NON-CR/NON-PD CR            Y N N R 2024-04-10 2024-06-01 .
GML219-0009 Y Y CR            CR            Y Y N R 2024-05-01 2024-06-12 2024-06-12
GML219-0010 Y N NE            .             N N Y A 2024-05-15 .          .
GML219-0011 Y Y CR            CR            Y Y N R 2024-06-01 2024-07-15 2024-07-15
GML219-0012 Y Y CR            NON-CR/NON-PD Y N N R 2024-06-10 2024-07-20 .
GML219-0013 Y N CR            .             Y Y N R 2024-07-01 2024-08-10 2024-08-10
GML219-0014 Y Y NON-CR/NON-PD NE            N N Y U 2024-07-15 .          .
GML219-0015 Y Y CR            CR            Y Y N R 2024-08-01 2024-09-05 2024-09-05
GML219-0016 Y N CR            .             Y Y N R 2024-08-10 2024-09-18 2024-09-18
GML219-0017 Y Y CR            CR            Y Y N R 2024-09-01 2024-10-10 2024-10-10
GML219-0018 Y Y NE            NE            N N Y A 2024-09-15 .          .
GML219-0019 Y N CR            .             Y N N R 2024-10-01 2024-11-12 .
GML219-0020 Y Y CR            CR            Y Y N R 2024-10-10 2024-11-20 2024-11-20
;
run;
