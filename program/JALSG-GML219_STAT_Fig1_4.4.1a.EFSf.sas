**********************************************************************;
* Project           : JALSG-GML219
*
* Program name      : JALSG-GML219_STAT_Fig1_4.4.1a_EFSf.sas
*
* Author            : AKIKO SAITO
*
* Date created      : 20251208
* Date modified      : 20251209
*
**********************************************************************;

/*** initial setting ***/

proc datasets library = work kill nolist; quit;

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

libname libraw  "&_wk_path.\input\ads"  access = readonly;
libname libext  "&_wk_path.\input\ext"      access = readonly;
libname libout  "&_wk_path.\output";

%let output = &_wk_path.\output ;
%let log = &_wk_path.\log;
%let ext = &_wk_path.\input\ext;
%let raw = &_wk_path.\input\rawdata;
%let ads = &_wk_path.\input\ads;
%let template = &_wk_path.\output\template;

options  validvarname=v7
         fmtsearch = (libout work)
         sasautos = ("&_wk_path.\program\macro") cmdmac
         nofmterr
         nomlogic nosymbolgen nomprint
         ls = 100 missing = "" pageno = 1;

proc printto log="&log.\JALSG-GML219_STAT_Fig1_&DATE.log" new ; run;
options nodate nonumber;


/*** Data Reading ***/
data gml219;
   set libraw. gml219;
run;

proc freq data=gml219;
tables usubjid*fasfl;
where fasfl="N";
run;


/*　FAS */
data FAS ;  set gml219;
 if FASFL = "Y" ;run ;


/*** 解析結果 ***/
TITLE1 'JALSG-GML219' ;

ods rtf file="&output.\JALSG-GML219 Fig1_&DATE.rtf" style=listing;
ods escapechar='^';
footnote2  "^S={just=r} 出力日 &DATE"  ;

options nodate nonumber;

title2 'Event free survival' ;
title3 '解析対象集団: FAS' ;

proc lifetest data=fas plot=survival(atrisk) notable;
 time EFS_y*efs_c(0) ;
run;

ods select none ;


/*--- 1, 2, 3年EFS率の計算 ---*/
TITLE2 '無イベント生存率';
TITLE3 ' '; /* サブタイトルをクリア */

/* PROC LIFETESTを実行し、全生存率データをout_s0に出力 */
/* (結果は表示しない) */
ods select none;
proc lifetest data=fas alpha=0.05 outsurv=out_s0;
    time EFS_y*efs_c(0);
run;
ods select all;

/* 1年時点の推定値を計算 */
data out_s1y; set out_s0;
    where EFS_y <= 1.0; /* 1年以下のデータのみを抽出 */
run;
proc sort data=out_s1y; by EFS_y; run;
data Eout_s1y (keep=year survival SDF_LCL SDF_UCL);
    set out_s1y end=final; by EFS_y;
    if final; /* 1年以下で最後のレコード（=1年時点の推定値）を取得 */
    year=1.0;
run;

/* 2年時点の推定値を計算 */
data out_s2y; set out_s0;
    where EFS_y <= 2.0; /* 2年以下のデータのみを抽出 */
run;
proc sort data=out_s2y; by EFS_y; run;
data Eout_s2y (keep=year survival SDF_LCL SDF_UCL);
    set out_s2y end=final; by EFS_y;
    if final; /* 2年以下で最後のレコード（=2年時点の推定値）を取得 */
    year=2.0;
run;

/* 3年時点の推定値を計算 */
data out_s3y; set out_s0;
    where EFS_y <= 3.0; /* 3年以下のデータのみを抽出 */
run;
proc sort data=out_s3y; by EFS_y; run;
data Eout_s3y (keep=year survival SDF_LCL SDF_UCL);
    set out_s3y end=final; by EFS_y;
    if final; /* 3年以下で最後のレコード（=3年時点の推定値）を取得 */
    year=3.0;
run;

/* 1, 2, 3年時点の結果を一つのデータセットに結合 */
data final_estimates;
    set Eout_s1y Eout_s2y Eout_s3y;
run;

/* 最終的な表出力 */
proc print data=final_estimates label noobs;
    label year='経過年数' survival='生存確率' SDF_LCL='95%CI下限' SDF_UCL='95%CI上限';
    var year survival SDF_LCL SDF_UCL;
    format survival SDF_LCL SDF_UCL 8.2;
run;

ods rtf close;

proc printto ; run;

