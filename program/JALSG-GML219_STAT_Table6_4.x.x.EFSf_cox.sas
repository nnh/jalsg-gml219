**********************************************************************;
* Project           : JALSG-APL219R
*
* Program name      : JALSG-APL219R_STAT_Table6_5.4.8.EFSf_cox.sas
*
* Author            : AKIKO SAITO
*
* Date created      : 20250730
* Date modified      : 20250730
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

/*proc printto log="&log.\JALSG-APL219R_STAT_Table6_&DATE.log" new ; run;*/
options nodate nonumber;


/*** Data Reading ***/
data apl219r;
   set libraw. apl219r;
run;

/*　FAS */
data FAS ;  set apl219r;
 if FASFL = "Y" ;run ;

* 再発フラグの作成
* DSTERM 列が 'RELAPSE' の場合に relapse = 1、それ以外は 0 とする新しい変数を作成;
DATA work.apl_data_prepared;
    SET work.apl219r;
    IF EFS_c = 1 THEN relapse = 1;
    ELSE relapse = 0;
    /* 解析に必要な列のみを保持 */
    KEEP USUBJID bl_pmlrara relapse;
    /* bl_pmlrara が欠損しているレコードは除外 */
    IF bl_pmlrara NE .;
RUN;

* ロジスティック回帰とROC分析の実行
* bl_pmlrara を説明変数、relapse を目的変数としてモデルを構築します。
* OUTROC= オプションでROC曲線の座標データ（各閾値での感度・特異度）をroc_dataというデータセットに出力;

* 3. ロジスティック回帰とROC分析の実行;
proc logistic data=Fas plots=roc(id=prob);
      model EFS_c(event='1') = bl_pmlrara / nofit;
      roc 'PML-RARalpha' bl_pmlrara;
   run;



proc logistic data=Data1 plots(only)=(roc(id=obs) effect);
      model disease/n=age / scale=none
                            clparm=wald
                            clodds=pl
                            rsquare;
      units age=10;
   run;


* 4. Youden's Indexの計算;
DATA work.roc_with_youden;
    SET work.roc_data;
    /* _PROB_は閾値を指す */
    youden_j = _SENSIT_ - (1 - _SPECIF_);
    LABEL _PROB_ = "Threshold"
          _SENSIT_ = "Sensitivity"
          _SPECIF_ = "Specificity"
          youden_j = "Youden's Index";
RUN;

* 5. 最適閾値の特定と結果の表示;
PROC SORT DATA=work.roc_with_youden;
    BY DESCENDING youden_j;
RUN;


DATA work.optimal_threshold;
    SET work.roc_with_youden;
    BY DESCENDING youden_j;
    IF FIRST.youden_j;
RUN;

PROC PRINT DATA=work.optimal_threshold NOOBS LABEL;
    VAR _PROB_ _SENSIT_ _SPECIF_ youden_j;
    TITLE "PML-RARAの最適閾値 (Youden's Indexによる)";
RUN;


/*** 解析結果 ***/
TITLE1 'JALSG-APL219R' ;

ods rtf file="&output.\JALSG-APL219R Table5c_&DATE.rtf" style=listing;
ods escapechar='^';
footnote2  "^S={just=r} 出力日 &DATE"  ;

options nodate nonumber;

title2 '非寛解又は再発と前治療歴' ;


proc freq data=FAS order=data;
  tables (pret_am80 pret_ato pret_atra pret_go) * EFS_c / nopercent norow exact missing;
  format pret_am80 pret_ato pret_atra pret_go $pretxt.;
run;

ods rtf close;



/*** 解析結果 ***/
TITLE1 'JALSG-APL219R' ;

ods rtf file="&output.\JALSG-APL219R Fig1_&DATE.rtf" style=listing;
ods escapechar='^';
footnote2  "^S={just=r} 出力日 &DATE"  ;

options nodate nonumber;

title2 'Event free survival' ;
title3 '解析対象集団: FAS' ;

proc lifetest data=fas plot=survival(atrisk) notable;
 time EFS_y*efs_c(0) ;
run;

ods rtf close;



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

proc lifetest data=fas plot=survival(atrisk) notable;
 time EFS_y*efs_c(0) ;
run;
proc contents data=fas; run;

proc sort data=fas;by EFS_y;run;
proc means median min max data=fas; var bl_pmlrar;by EFS_c;run;
/*Cox analyses*/

/*Univariate analysis*/
proc phreg data=fas; class SEX (ref='M');  
model EFS_y*EFS_c(0) = SEX / rl; run;
proc phreg data=fas; class frlagec (ref='60歳未満');  
model EFS_y*EFS_c(0)=frlagec/rl;run;
proc phreg data=fas; class bl_wbcc (ref='3,000/μL未満');  
model EFS_y*EFS_c(0)=bl_wbcc /rl;run;
proc phreg data=fas; class bl_platc (ref='50,000/μL未満');
model EFS_y*EFS_c(0)=bl_platc /rl;run;
proc phreg data=fas; class cd56yn (ref='陰性');
model EFS_y*EFS_c(0)=cd56yn /rl;run;
proc phreg data=fas; class ATRAsyn (ref='N');
model EFS_y*EFS_c(0)=ATRAsyn /rl;run;
proc phreg data=fas; class hylyn_bl (ref=' ');
model EFS_y*EFS_c(0)=hylyn_bl /rl;run;
proc phreg data=fas; class mrlyn_bl (ref=' ');
model EFS_y*EFS_c(0)=mrlyn_bl /rl;run;
proc phreg data=fas;class pret_am80 (ref='N');
model EFS_y*EFS_c(0)=pret_am80 /rl;run;
proc phreg data=fas;class pret_ato (ref='N');
model EFS_y*EFS_c(0)=pret_ato /rl;run;
proc phreg data=fas;class pret_atra (ref='N');
model EFS_y*EFS_c(0)=pret_atra /rl;run;
proc phreg data=fas;class pret_go (ref='N');
model EFS_y*EFS_c(0)=pret_go /rl;run;
proc phreg data=fas;class dur_fcrc (ref='5年未満');
model EFS_y*EFS_c(0)=dur_fcrc /rl;run;


proc lifetest data=fas plot=survival(atrisk) notable;
 strata SEX;
 time EFS_y*efs_c(0) ;
run;
proc lifetest data=fas plot=survival(atrisk) notable;
 strata frlagec;
 time EFS_y*efs_c(0) ;
run;
proc lifetest data=fas plot=survival(atrisk) notable;
 strata bl_wbcc;
 time EFS_y*efs_c(0) ;
run;
proc lifetest data=fas plot=survival(atrisk) notable;
 strata bl_platc;
 time EFS_y*efs_c(0) ;
run;
proc lifetest data=fas plot=survival(atrisk) notable;
 strata cd56yn;
 time EFS_y*efs_c(0) ;
run;
proc lifetest data=fas plot=survival(atrisk) notable;
 strata ATRAsyn;
 time EFS_y*efs_c(0) ;
run;
proc lifetest data=fas plot=survival(atrisk) notable;
 strata hylyn_bl;
 time EFS_y*efs_c(0) ;
run;
proc lifetest data=fas plot=survival(atrisk) notable;
 strata mrlyn_bl;
 time EFS_y*efs_c(0) ;
run;
proc lifetest data=fas plot=survival(atrisk) notable;
 strata pret_am80;
 time EFS_y*efs_c(0) ;
run;
proc lifetest data=fas plot=survival(atrisk) notable;
 strata pret_atra;
 time EFS_y*efs_c(0) ;
run;
proc lifetest data=fas plot=survival(atrisk) notable;
 strata pret_ato;
 time EFS_y*efs_c(0) ;
run;
proc lifetest data=fas plot=survival(atrisk) notable;
 strata pret_go;
 time EFS_y*efs_c(0) ;
run;
proc lifetest data=fas plot=survival(atrisk) notable;
 strata dur_fcrc;
 time EFS_y*efs_c(0) ;
run;

proc phreg data=data2I;model OSy*OS_c(0)=IKZFN0Y1 Agec IKZF_Agec/rl;
IKZF_Agec=IKZFN0Y1*Agec;
run;
proc phreg data=data2I;model OSy*OS_c(0)=IKZFN0Y1 WBCc IKZF_WBCc/rl;
IKZF_WBCc=IKZFN0Y1*WBCc;
run;
proc phreg data=data2I;model OSy*OS_c(0)=IKZFN0Y1 male1 IKZF_male1/rl;
IKZF_Male1=IKZFN0Y1*male1;
run;
proc phreg data=data2I;model OSy*OS_c(0)=IKZFN0Y1 NCIS0H1 IKZF_NCI/rl;
IKZF_NCI=IKZFN0Y1*NCIS0H1;
run;
proc phreg data=data2I;model OSy*OS_c(0)=IKZFN0Y1 PGR0PPR1 IKZF_PSL/rl;
IKZF_PSL=IKZFN0Y1*PGR0PPR1;
run;
proc phreg data=data2I;model OSy*OS_c(0)=IKZFN0Y1 CRLFL0H1 IKZF_CRLF/rl;
IKZF_CRLF=IKZFN0Y1*CRLFL0H1;
run;
proc phreg data=data2;model OSy*OS_c(0)=IKZFN0Y1 CRLFL0H1 IKZF_CRLF/rl;
IKZF_CRLF=IKZFN0Y1*CRLFL0H1;
run;
proc phreg data=data2I; model OSy*OS_c(0)=IKZFN0Y1 Agec WBCc NCIS0H1 PGR0PPR1 CRLFL0H1/rl include=1 selection=forward;run;
proc phreg data=data2I; model OSy*OS_c(0)=IKZFN0Y1 Agec WBCc NCIS0H1 PGR0PPR1 CRLFL0H1/rl ;run;
proc phreg data=data2I; model EFSy*EFS_c(0)=IKZFN0Y1 NCIS0H1 PGR0PPR1 CRLFL0H1/rl ;run;
proc phreg data=data2I; model OSy*OS_c(0)=IKZFN0Y1 NCIS0H1 PGR0PPR1 CRLFL0H1/rl ;run;
