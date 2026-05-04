**********************************************************************;
* Project      : JALSG-GML219
* Program name : JALSG-GML219_STAT_Table6_4.4.10b.SAE.sas
* Author       : AKIKO SAITO
* Date created : 20260505
* Description  : 重篤有害事象 (SAE) (SAP 4.4.10b / 5.4.11)
*                各コース投与終了から 28 日以内の SAE 発生例数 n(%)
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

proc printto log="&log.\JALSG-GML219_STAT_Table6_&DATE..log" new; run;

options validvarname=v7 fmtsearch=(libout work) nofmterr
        nomlogic nosymbolgen nomprint ls=180 missing="" pageno=1
        nodate nonumber;

/*--- 入力データ：gml219（コース終了日）と gml219_sae（SAE 一覧） ---*/
data gml219;
  set libraw.gml219;
  where saffl = "Y";
  keep usubjid saffl ind1fl ind2fl c1fl c2fl c3fl
       ind1enddt ind2enddt c1enddt c2enddt c3enddt;
run;

data sae_long;
  set libraw.gml219_sae;
run;

/*--- コース終了日と SAE 発生日を結合し、28 日以内のコースを判定 ---*/
proc sort data=gml219;   by usubjid; run;
proc sort data=sae_long; by usubjid; run;

data sae_with_courses;
  merge sae_long(in=a) gml219(in=b);
  by usubjid;
  if a;  /* SAE のあった患者のみ */
  array enddt{5} ind1enddt ind2enddt c1enddt c2enddt c3enddt;
  array d28{5}   d28_i1 d28_i2 d28_c1 d28_c2 d28_c3;
  array cycnm{5} $4 _temporary_ ('i1' 'i2' 'c1' 'c2' 'c3');
  do i = 1 to 5;
    if enddt{i} ne . and aestdt ne . and 0 <= aestdt - enddt{i} <= 28 then d28{i} = 1;
    else d28{i} = 0;
  end;
  d28_any = max(of d28_i1 d28_i2 d28_c1 d28_c2 d28_c3);
  drop i;
run;

/*--- 各コースの SAF 母数を集計（n_i1, n_i2, n_c1, n_c2, n_c3） ---*/
proc sql noprint;
  select count(*) into :n_saf  trimmed from gml219;
  select count(*) into :n_i1   trimmed from gml219 where ind1fl="Y";
  select count(*) into :n_i2   trimmed from gml219 where ind2fl="Y";
  select count(*) into :n_c1   trimmed from gml219 where c1fl  ="Y";
  select count(*) into :n_c2   trimmed from gml219 where c2fl  ="Y";
  select count(*) into :n_c3   trimmed from gml219 where c3fl  ="Y";
quit;

%put NOTE: SAF=&n_saf, ind1=&n_i1, ind2=&n_i2, c1=&n_c1, c2=&n_c2, c3=&n_c3;

TITLE1 'JALSG-GML219';
ods rtf file="&output.\JALSG-GML219 Table6_&DATE..rtf" style=listing;
ods escapechar='^';
footnote2 "^S={just=r} 出力日 &DATE";

/*=====================================================================*/
/* (1) SAE 発生例（コース問わず）n(%)                                   */
/*=====================================================================*/
title2 '(1) 重篤有害事象 (SAE) 発生例数 ― 全コース';
title3 "解析対象集団: 全安全性解析対象集団 (n=&n_saf)";

proc sql;
  create table any_sae_pt as
    select saept,
           count(distinct usubjid) as n_pat
    from sae_with_courses
    group by saept
    order by saept;
quit;

data any_sae_pt;
  set any_sae_pt;
  length pct $20.;
  pct = compress(put(n_pat,8.)) || ' (' ||
        compress(put(round(n_pat/&n_saf*100,.1),8.1)) || '%)';
  label saept = '基本語 (PT)' pct = "発生例数 n(%)";
run;

proc print data=any_sae_pt noobs label;
  var saept pct;
run;

/*=====================================================================*/
/* (2) コース別：投与終了から 28 日以内の SAE 発生例数 n(%)             */
/*=====================================================================*/
title2 '(2) コース別 SAE 発生例数（投与終了 28 日以内）';

%macro sae_cycle(cyc, cycname, n);
  proc sql;
    create table sae_&cyc as
      select saept,
             count(distinct usubjid) as n_pat
      from sae_with_courses
      where d28_&cyc = 1
      group by saept
      order by saept;
  quit;

  data sae_&cyc;
    set sae_&cyc;
    length pct $20.;
    pct = compress(put(n_pat,8.)) || ' (' ||
          compress(put(round(n_pat/&n*100,.1),8.1)) || '%)';
    label saept = '基本語 (PT)'
          pct   = "&cycname (n=&n)";
  run;

  title3 "&cycname (n=&n)";
  proc print data=sae_&cyc noobs label;
    var saept pct;
  run;

%mend;

%sae_cycle(i1, 寛解導入1, &n_i1)
%sae_cycle(i2, 寛解導入2, &n_i2)
%sae_cycle(c1, 地固め1,   &n_c1)
%sae_cycle(c2, 地固め2,   &n_c2)
%sae_cycle(c3, 地固め3,   &n_c3)

/*=====================================================================*/
/* (3) SAE 一覧（症例ごとに発生した SAE PT, 発生日, 直前コース）         */
/*=====================================================================*/
title2 '(3) SAE 一覧（個別症例レベル）';
proc print data=sae_with_courses noobs label;
  var usubjid aeseq saept aestdt
      d28_i1 d28_i2 d28_c1 d28_c2 d28_c3 d28_any;
  label usubjid='被験者ID' aeseq='AE Seq' saept='SAE PT' aestdt='発生日'
        d28_i1='Ind1 28日内' d28_i2='Ind2 28日内'
        d28_c1='Cons1 28日内' d28_c2='Cons2 28日内' d28_c3='Cons3 28日内'
        d28_any='いずれかコースで28日内';
run;

ods rtf close;
proc printto; run;