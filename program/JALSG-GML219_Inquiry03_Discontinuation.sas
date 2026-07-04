/******************************************************************************
* Project       : JALSG-GML219
* Program       : JALSG-GML219_Inquiry03_Discontinuation.sas
* Author        : Akiko Saito
* Created       : 2026/05/24
*
* Purpose       : 主治医照会 (3) 試験中止理由の内訳とEFSへの扱い
*                 - DSTERM (治療フェーズ中止理由) と dsterm2 (最終転帰) の集計
*                 - 各中止理由が EFS イベント/打ち切りどちらに分類されるかを提示
*                 - AZA+VEN療法登場期との時系列対比のため登録年別も併出力
*
* 対象          : FAS (n=121)
* 入力          : input\ads\202512 data\gml219.sas7bdat
* 出力          : output\JALSG-GML219_Inquiry03_Discontinuation.rtf
* ログ          : log\JALSG-GML219_Inquiry03_Discontinuation.log
******************************************************************************/

options nofmterr ls=160 ps=80 nodate nonumber missing=" ";

%let root = C:\Users\AkikoSaito\Data\NMC\Stat\JALSG-GML219;
libname olda "&root.\input\ads\202512 data" access=readonly;

proc printto log="&root.\log\JALSG-GML219_Inquiry03_Discontinuation.log"
             print="&root.\log\JALSG-GML219_Inquiry03_Discontinuation.lst" new; run;

ods rtf file="&root.\output\JALSG-GML219_Inquiry03_Discontinuation.rtf" style=listing bodytitle;
ods escapechar='^';
title  "JALSG-GML219 研究代表医師照会への回答資料 (3) 試験中止理由";
title2 "出力日: %sysfunc(today(),yymmddn8.)";

/*-----------------------------------------------------------------------------
  STEP 1: 解析用データセット (EFSイベント分類変数を付加)
-----------------------------------------------------------------------------*/
data work.dc;
    set olda.gml219;
    where FASFL="Y";

    length efs_first $40;
    if cr1yn = "NON-CR/NON-PD" then efs_first = "1_非寛解(治療不応)";
    else if cr1yn = "CR" and RLyn = "Y" then efs_first = "2_CR後再発";
    /* cr1yn未評価のまま死亡した2例もここに含まれるため「CR後死亡」ではなく
       「再発/治療不応判定確定前死亡」とする (伊藤先生ご照会2026-06-26 Q2-4回答) */
    else if upcase(dsterm2) = "DEATH" then efs_first = "3_再発/治療不応判定確定前死亡";
    else efs_first = "0_打ち切り";

    /* 登録年 */
    if rfstdt ne . then enroll_year = year(rfstdt);

    label efs_first   = "EFS初発イベント分類"
          enroll_year = "登録年";
run;

/*-----------------------------------------------------------------------------
  STEP 2: 中止理由の集計
-----------------------------------------------------------------------------*/
title3 "(3-1) 治療フェーズ中止理由 (DSTERM) ? DS.csv の discontinuation 段";
proc freq data=dc;
    tables DSTERM / missing;
run;

title3 "(3-2) 最終転帰 (dsterm2) ? DS.csv の withdrawal 段";
proc freq data=dc;
    tables dsterm2 / missing;
run;

title3 "(3-3) 治療中止理由 × 最終転帰";
proc freq data=dc;
    tables DSTERM*dsterm2 / list missing;
run;

/*-----------------------------------------------------------------------------
  STEP 3: 中止理由とEFSイベント分類の対応
    EFSの定義は「非寛解 / 再発 / 死亡 のいずれか最初」のため、
    中止理由そのものではなく上記イベントの有無が分類を決める。
-----------------------------------------------------------------------------*/
title3 "(3-4) 治療中止理由 × EFSイベント分類";
proc freq data=dc;
    tables DSTERM*efs_first / list missing;
run;

title3 "(3-5) 最終転帰 × EFSイベント分類";
proc freq data=dc;
    tables dsterm2*efs_first / list missing;
run;

/*-----------------------------------------------------------------------------
  STEP 4: 登録年別 中止理由 (AZA+VEN療法登場前後の確認)
-----------------------------------------------------------------------------*/
title3 "(3-6) 登録年 × 治療フェーズ中止理由";
proc freq data=dc;
    tables enroll_year*DSTERM / norow nocol nopercent missing;
run;

title3 "(3-7) 登録年 × EFSイベント分類";
proc freq data=dc;
    tables enroll_year*efs_first / norow nocol nopercent missing;
run;

/*-----------------------------------------------------------------------------
  STEP 5: 「医師判断による中止」のEFS打ち切り例の特定
-----------------------------------------------------------------------------*/
title3 "(3-8) 医師判断による中止 (DSTERM='DISCONTINUATION BY PHYSICIAN DECISION') の症例リスト";
proc print data=dc noobs label;
    where DSTERM = "DISCONTINUATION BY PHYSICIAN DECISION";
    var subjid age enroll_year cr1yn RLyn dsterm2 efs_first DSTERM dsstdt2;
    label subjid="被験者番号" age="年齢" enroll_year="登録年"
          cr1yn="導入1+2効果" RLyn="再発" dsterm2="最終転帰"
          efs_first="EFS初発" DSTERM="治療中止理由"
          dsstdt2="最終確認/死亡日";
run;

ods rtf close;
proc printto; run;

%put NOTE: 出力 - &root.\output\JALSG-GML219_Inquiry03_Discontinuation.rtf;
