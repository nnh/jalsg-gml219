**********************************************************************;
* Project      : JALSG-GML219
* Program name : JALSG-GML219_STAT_Fig10_4.4.8b.ELNrisk_OS_EFS_RFS.sas
* Author       : AKIKO SAITO
* Date created : 20260705
* Description  : ELNリスク分類別 OS・EFS・RFS（eln2017:SAP記載のプライマリ分類、
*                eln2022:Dohner et al. Blood 2022に準拠した追加分類）
**********************************************************************;

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

proc printto log="&log.\JALSG-GML219_STAT_Fig10_&DATE..log" new; run;

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

data FAS_cr;
  set gml219;
  where FASFL = "Y" and crfl = "Y";
run;

TITLE1 'JALSG-GML219';

ods rtf file="&output.\JALSG-GML219 Fig10_&DATE..rtf" style=listing;
ods escapechar='^';
footnote2 "^S={just=r} 出力日 &DATE";

/*=====================================================================*/
/* 限界事項の注記（本文に1回だけ表示）。                                */
/* ★文言を更新する場合は、下の ods text= の引用符内のみを編集すること★ */
/*=====================================================================*/
ods text =
"本解析ではeln2017（SAP記載のプライマリ分類）とeln2022（Dohner et al. Blood 2022の
2022年改訂ELN基準に沿った追加分類）の両方でOS・EFS・RFSを層別する。
eln2022は本試験でEDC収集済みの染色体異常8項目（t(8;21), inv(16), t(16;16),
t(9;11), t(1;22)(p13;q13), t(6;9), t(9;22), inv(3)/t(3;3), -5, del(5q), -7,
-17/abn(17p), 複合核型3種以上, その他染色体異常）および分子マーカー5項目
（NPM1, FLT3-ITD, CEBPA, RUNX1, SF3B1）のみに基づく。TP53, ASXL1, BCOR, EZH2,
SRSF2, STAG2, U2AF1, ZRSR2変異、モノソーマル核型、t(8;16)/KAT6A::CREBBP、
広義MECOM再構成（inv(3)/t(3;3)以外）、複合核型からの高2倍体除外規定は、
本試験で未収集のため判定に含まれない。
本データセットではeln2017とeln2022はGML219-0058の1例（FLT3-ITD陽性・NPM1野生型、
他に予後不良因子なし）を除き完全に一致する（Adverse→Intermediateへ変更。
ELN2022でFLT3-ITDのアレル比を問わずIntermediateとする変更点に対応）。";

title2 'ELNリスク分類の内訳 (FAS, n=121)';
proc freq data=FAS;
  tables eln2017 eln2022 / missing nocum;
run;

%macro km_strata(ds, tvar, grpvar, yr);
  data _s&yr.y;
    set &ds.;
    where &tvar. <= &yr.;
  run;
  proc sort data=_s&yr.y; by &grpvar. &tvar.; run;
  data _e&yr.y(keep=year &grpvar. survival SDF_LCL SDF_UCL);
    set _s&yr.y;
    by &grpvar.;
    if last.&grpvar.;
    year = &yr.;
  run;
%mend;

%macro eln_km(ds=, tvar=, cvar=, grpvar=, poplabel=, endlabel=, imgname=);
  title2 "ELNリスク分類別 &endlabel.（2年・5年）: &grpvar.";
  title3 "解析対象集団: &poplabel.";

  ods graphics on / width=18cm height=14cm imagename="&imgname.";
  proc lifetest data=&ds. plots=survival(atrisk cl) notable;
    time &tvar.*&cvar.(0);
    strata &grpvar.;
  run;
  ods graphics off;

  title2 "&endlabel. 時点別推定値（&grpvar.）";
  title3 ' ';
  ods select none;
  proc lifetest data=&ds. alpha=0.05 outsurv=_surv_tmp;
    time &tvar.*&cvar.(0);
    strata &grpvar.;
  run;
  ods select all;
  %km_strata(_surv_tmp, &tvar., &grpvar., 2);
  %km_strata(_surv_tmp, &tvar., &grpvar., 5);
  data _est_tmp; set _e2y _e5y; run;
  proc sort data=_est_tmp; by &grpvar. year; run;
  proc print data=_est_tmp label noobs;
    label year='経過年数' survival='生存確率' SDF_LCL='95%CI下限' SDF_UCL='95%CI上限';
    var &grpvar. year survival SDF_LCL SDF_UCL;
    format survival SDF_LCL SDF_UCL 8.4;
  run;
%mend;

/*=====================================================================*/
/* (1) RFS（CR達成例, FAS_cr）: eln2017（プライマリ）→ eln2022（追加）    */
/*=====================================================================*/
%eln_km(ds=FAS_cr, tvar=RFS_y, cvar=rfs_c, grpvar=eln2017, poplabel=FAS CR達成例, endlabel=Relapse-free Survival, imgname=Fig10_RFS_byELN2017);
%eln_km(ds=FAS_cr, tvar=RFS_y, cvar=rfs_c, grpvar=eln2022, poplabel=FAS CR達成例, endlabel=Relapse-free Survival, imgname=Fig10_RFS_byELN2022);

/*=====================================================================*/
/* (2) OS（FAS）: eln2017（プライマリ）→ eln2022（追加）                 */
/*=====================================================================*/
%eln_km(ds=FAS, tvar=OS_y, cvar=os_c, grpvar=eln2017, poplabel=FAS, endlabel=Overall Survival, imgname=Fig10_OS_byELN2017);
%eln_km(ds=FAS, tvar=OS_y, cvar=os_c, grpvar=eln2022, poplabel=FAS, endlabel=Overall Survival, imgname=Fig10_OS_byELN2022);

/*=====================================================================*/
/* (3) EFS（FAS）: eln2017（プライマリ）→ eln2022（追加）                */
/*=====================================================================*/
%eln_km(ds=FAS, tvar=EFS_y, cvar=efs_c, grpvar=eln2017, poplabel=FAS, endlabel=Event-free Survival, imgname=Fig10_EFS_byELN2017);
%eln_km(ds=FAS, tvar=EFS_y, cvar=efs_c, grpvar=eln2022, poplabel=FAS, endlabel=Event-free Survival, imgname=Fig10_EFS_byELN2022);

ods rtf close;
proc printto; run;

%put NOTE: 出力 - &output.\JALSG-GML219 Fig10_&DATE..rtf;
