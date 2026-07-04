/******************************************************************************
* Project       : JALSG-GML219
* Program       : JALSG-GML219_Inquiry02_EFS_OS.sas
* Author        : Akiko Saito
* Created       : 2026/05/24
*
* Purpose       : 主治医照会 (2) EFSとOSの差の内訳
*                 - EFSイベントを 非寛解(治療不応) / CR後再発 / CR後死亡(再発前) /
*                   打ち切り に4分類して内訳を提示
*                 - 1年以内のイベント発生有無 (再発・非寛解・死亡)
*                 - EFSとOSの差を生む要因 (非死亡EFSイベントの内訳) を可視化
*
* 対象          : FAS (n=121)
* 入力          : input\ads\202512 data\gml219.sas7bdat
* 出力          : output\JALSG-GML219_Inquiry02_EFS_OS.rtf
* ログ          : log\JALSG-GML219_Inquiry02_EFS_OS.log
******************************************************************************/

options nofmterr ls=160 ps=80 nodate nonumber missing=" ";

%let root = C:\Users\AkikoSaito\Data\NMC\Stat\JALSG-GML219;
libname olda "&root.\input\ads\202512 data" access=readonly;

proc printto log="&root.\log\JALSG-GML219_Inquiry02_EFS_OS.log"
             print="&root.\log\JALSG-GML219_Inquiry02_EFS_OS.lst" new; run;

ods rtf file="&root.\output\JALSG-GML219_Inquiry02_EFS_OS.rtf" style=listing bodytitle;
ods escapechar='^';
title  "JALSG-GML219 研究代表医師照会への回答資料 (2) EFSとOSの差";
title2 "出力日: %sysfunc(today(),yymmddn8.)";

/*-----------------------------------------------------------------------------
  STEP 1: EFSイベントの初発分類
-----------------------------------------------------------------------------*/
data work.efs;
    set olda.gml219;
    where FASFL="Y";

    length efs_first $25;
    /* 優先順: 非寛解 > CR後再発 > CR後死亡 > 打ち切り */
    if cr1yn = "NON-CR/NON-PD" then efs_first = "1_非寛解(治療不応)";
    else if cr1yn = "CR" and RLyn = "Y" then efs_first = "2_CR後再発";
    else if upcase(dsterm2) = "DEATH" then efs_first = "3_CR後死亡(再発前)";
    else efs_first = "0_打ち切り";

    length noncr_fl relapse_fl death_fl $1;
    if cr1yn = "NON-CR/NON-PD" then noncr_fl = "Y"; else noncr_fl = "N";
    if RLyn = "Y" then relapse_fl = "Y"; else relapse_fl = "N";
    if upcase(dsterm2) = "DEATH" then death_fl = "Y"; else death_fl = "N";

    /* 1年以内のイベント発生 */
    length rel_1y dthbef_1y noncr_1y efsev_1y $1;
    if cr1yn = "CR" and RLyn = "Y" and (RLdt - rfstdt) <= 365.25
        then rel_1y = "Y"; else rel_1y = "N";
    if cr1yn = "CR" and RLyn ne "Y" and upcase(dsterm2) = "DEATH"
        and (dsstdt2 - rfstdt) <= 365.25
        then dthbef_1y = "Y"; else dthbef_1y = "N";
    if cr1yn = "NON-CR/NON-PD" and (cr1yndt - rfstdt) <= 365.25
        then noncr_1y = "Y"; else noncr_1y = "N";
    if EFS_c = 1 and (efsdt - rfstdt) <= 365.25
        then efsev_1y = "Y"; else efsev_1y = "N";

    label
        efs_first  = "EFS初発イベント分類"
        noncr_fl   = "非寛解フラグ"
        relapse_fl = "再発フラグ"
        death_fl   = "全死亡フラグ"
        rel_1y     = "1年以内CR後再発"
        dthbef_1y  = "1年以内CR後死亡(再発前)"
        noncr_1y   = "1年以内非寛解"
        efsev_1y   = "1年以内EFSイベント"
    ;
run;

title3 "(2-1) EFS初発イベント分類 (FAS, n=121)";
proc freq data=efs;
    tables efs_first / missing nocum;
run;

title3 "(2-2) 個別イベントフラグ: 非寛解 / 再発 / 全死亡";
proc freq data=efs;
    tables noncr_fl relapse_fl death_fl / missing;
run;

title3 "(2-3) クロス: 非寛解 × 再発 × 全死亡";
proc freq data=efs;
    tables noncr_fl*relapse_fl*death_fl / list missing;
run;

title3 "(2-4) 1年以内のイベント発生有無";
proc freq data=efs;
    tables rel_1y dthbef_1y noncr_1y efsev_1y efs_first*rel_1y / missing;
run;

/*-----------------------------------------------------------------------------
  STEP 2: EFS / OS のKM曲線と1年・2年推定値
-----------------------------------------------------------------------------*/
title3 "(2-5) EFS Kaplan-Meier (1年・2年推定値)";
proc lifetest data=efs outsurv=km_efs conftype=loglog noprint;
    time efs_y*EFS_c(0);
run;
proc lifetest data=efs outsurv=km_os conftype=loglog noprint;
    time os_y*OS_c(0);
run;

%macro km_lm(insurv=, timevar=, year=, label=, out=);
    data _l;
        set &insurv;
        where &timevar <= &year;
    run;
    proc sort data=_l; by &timevar; run;
    data &out (keep=endpoint year survival SDF_LCL SDF_UCL);
        length endpoint $10;
        set _l end=eof;
        by &timevar;
        if eof;
        year = &year;
        endpoint = "&label";
    run;
%mend;

%km_lm(insurv=km_efs, timevar=efs_y, year=1.0, label=EFS, out=lm_efs_1);
%km_lm(insurv=km_efs, timevar=efs_y, year=2.0, label=EFS, out=lm_efs_2);
%km_lm(insurv=km_os,  timevar=os_y,  year=1.0, label=OS,  out=lm_os_1);
%km_lm(insurv=km_os,  timevar=os_y,  year=2.0, label=OS,  out=lm_os_2);

data summary_efsos;
    set lm_efs_1 lm_efs_2 lm_os_1 lm_os_2;
run;

proc print data=summary_efsos noobs label;
    var endpoint year survival SDF_LCL SDF_UCL;
    label endpoint="エンドポイント" year="経過年" survival="推定確率"
          SDF_LCL="95pctCI下限" SDF_UCL="95pctCI上限";
    format survival SDF_LCL SDF_UCL 8.4;
    title4 "EFS と OS の 1年・2年 KM 推定値";
run;

ods rtf close;
proc printto; run;

%put NOTE: 出力 - &root.\output\JALSG-GML219_Inquiry02_EFS_OS.rtf;
