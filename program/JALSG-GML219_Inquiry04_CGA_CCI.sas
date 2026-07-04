/******************************************************************************
* Project       : JALSG-GML219
* Program       : JALSG-GML219_Inquiry04_CGA_CCI.sas
* Author        : Akiko Saito
* Created       : 2026/05/24
*
* Purpose       : 主治医照会 (4) CGA7・CCI と試験中止 / 治療反応性 / 治療関連合併症
*
*   CGA7 カットオフ (推奨セット A1-1～A7-1):
*     CGA1 Vitality        : screen+ = CGA1A="N"  / 確定 = CGA1B ? 7
*     CGA2 Cognitive-Repeat: screen+ = CGA2A="N"  / 確定 = CGA2B ? 23 (MMSE代用)
*     CGA3 IADL-Transport  : screen+ = CGA3A="N"  / 確定 = CGA3B 満点未満
*     CGA4 Cognitive-Delay : screen+ = CGA4A="N"  / 確定 = CGA4B ? 25 (MoCA-J総点)
*     CGA5 ADL-Bathing     : screen+ = CGA5A="Y"  / 確定 = CGA5B < 5
*     CGA6 ADL-Excretion   : screen+ = CGA6A="Y"  / 確定 = CGA6B < 20
*     CGA7 GDS-15          : screen+ = CGA7A="Y"  / 確定 = CGA7B ? 6
*   Frailty 分類 (CGA-screen+ 項目数による3群分類):
*     Robust     = screen+ 0項目
*     Vulnerable = screen+ 1-2項目
*     Frail      = screen+ ?3項目
*
*   治療関連合併症 (B1-d × B2-b × B3-c × B4-a):
*     [指標A] 主要10AE × CTCAE Grade>=3 (comp_any)
*         FN=ae7, Sepsis=ae25, Lung infection=ae24, Catheter inf=ae1,
*         BP hemorrhage=ae32, IC hemorrhage=ae33, Hepatic failure=ae11,
*         TLS=ae30, DIC=ae9, Anorectal infection=ae8
*         ※ AE変数番号はADSのラベル (PROC CONTENTS) に準拠。
*           Table5本解析の %ae_row( ) のラベル一覧は _gae 系変数の表示順で
*           ae 系変数とは別系統 ? Table5ラベル一覧では参照しないこと。
*     [指標B] 全33AE × Grade>=3 any (comp_all): 治療関連合併症全体
*     コース別 (i1,i2,c1,c2,c3) と 患者単位 any-Gr3+ を集計
*
*   治療反応性 (C-2):
*     CR / Non-CR/Non-PD / Other(PD/未評価) の3カテゴリ
*
* 対象          : FAS (n=121)
* 入力          : input\ads\202512 data\gml219.sas7bdat
* 出力          : output\JALSG-GML219_Inquiry04_CGA_CCI.rtf
* ログ          : log\JALSG-GML219_Inquiry04_CGA_CCI.log
******************************************************************************/

options nofmterr ls=160 ps=80 nodate nonumber missing=" ";

%let root = C:\Users\AkikoSaito\Data\NMC\Stat\JALSG-GML219;
libname olda "&root.\input\ads\202512 data" access=readonly;

proc printto log="&root.\log\JALSG-GML219_Inquiry04_CGA_CCI.log"
             print="&root.\log\JALSG-GML219_Inquiry04_CGA_CCI.lst" new; run;

ods rtf file="&root.\output\JALSG-GML219_Inquiry04_CGA_CCI.rtf" style=listing bodytitle;
ods escapechar='^';
title  "JALSG-GML219 研究代表医師照会への回答資料 (4) CGA7・CCI";
title2 "出力日: %sysfunc(today(),yymmddn8.)";

/*-----------------------------------------------------------------------------
  STEP 1: 解析用データセットの構築
-----------------------------------------------------------------------------*/
data work.ana;
    set olda.gml219;
    where FASFL="Y";

    /*--- EFSイベント分類 ---*/
    length efs_first $40;
    if cr1yn = "NON-CR/NON-PD" then efs_first = "1_非寛解(治療不応)";
    else if cr1yn = "CR" and RLyn = "Y" then efs_first = "2_CR後再発";
    /* cr1yn未評価のまま死亡した2例もここに含まれるため「CR後死亡」ではなく
       「再発/治療不応判定確定前死亡」とする (伊藤先生ご照会2026-06-26 Q2-4回答) */
    else if upcase(dsterm2) = "DEATH" then efs_first = "3_再発/治療不応判定確定前死亡";
    else efs_first = "0_打ち切り";

    /*--- 試験中止フラグ ---*/
    length discont_fl $1;
    if upcase(dsterm2) = "COMPLETED" then discont_fl = "N";
    else if dsterm2 = "" then discont_fl = " ";
    else discont_fl = "Y";

    /*--- 治療反応性 (C-2) ---*/
    length treatresp $20;
    if cr1yn = "CR" then treatresp = "1_CR";
    else if cr1yn = "NON-CR/NON-PD" then treatresp = "2_NonCR/NonPD";
    else treatresp = "3_Other/PD/missing";

    /*--- 患者背景区分 ---*/
    length age_c $10;
    if age = . then age_c = " ";
    else if age <= 69 then age_c = "65-69";
    else age_c = "70-74";

    length blcci_c $20;
    if blcci = . then blcci_c = " ";
    else if blcci = 2 then blcci_c = "2 (白血病のみ)";
    else if blcci >= 3 then blcci_c = "3+ (併存症あり)";
    else blcci_c = "0-1";

    /*--- CGA7 各項目: screen+ と confirmed ---*/
    length cga1_scr cga1_cnf cga2_scr cga2_cnf cga3_scr cga3_cnf
           cga4_scr cga4_cnf cga5_scr cga5_cnf cga6_scr cga6_cnf
           cga7_scr cga7_cnf $1;

    /* CGA1-4 は yn="N" が screen+ */
    if cga1yn = "N" then cga1_scr = "Y"; else if cga1yn = "Y" then cga1_scr = "N"; else cga1_scr = " ";
    if cga2yn = "N" then cga2_scr = "Y"; else if cga2yn = "Y" then cga2_scr = "N"; else cga2_scr = " ";
    if cga3yn = "N" then cga3_scr = "Y"; else if cga3yn = "Y" then cga3_scr = "N"; else cga3_scr = " ";
    if cga4yn = "N" then cga4_scr = "Y"; else if cga4yn = "Y" then cga4_scr = "N"; else cga4_scr = " ";

    /* CGA5-7 は yn="Y" が screen+ */
    if cga5yn = "Y" then cga5_scr = "Y"; else if cga5yn = "N" then cga5_scr = "N"; else cga5_scr = " ";
    if cga6yn = "Y" then cga6_scr = "Y"; else if cga6yn = "N" then cga6_scr = "N"; else cga6_scr = " ";
    if cga7yn = "Y" then cga7_scr = "Y"; else if cga7yn = "N" then cga7_scr = "N"; else cga7_scr = " ";

    /* 確定スコア基準 (B値が -1=未評価 でないとき) */
    if cga1 ne . and cga1 ne -1 and cga1 <= 7  then cga1_cnf = "Y";
    else if cga1 ne . and cga1 ne -1           then cga1_cnf = "N"; else cga1_cnf = " ";
    if cga2 ne . and cga2 ne -1 and cga2 <= 23 then cga2_cnf = "Y";
    else if cga2 ne . and cga2 ne -1           then cga2_cnf = "N"; else cga2_cnf = " ";
    if cga3 ne . and cga3 ne -1 and cga3 < 4   then cga3_cnf = "Y";
    else if cga3 ne . and cga3 ne -1           then cga3_cnf = "N"; else cga3_cnf = " ";
    if cga4 ne . and cga4 ne -1 and cga4 <= 25 then cga4_cnf = "Y";
    else if cga4 ne . and cga4 ne -1           then cga4_cnf = "N"; else cga4_cnf = " ";
    if cga5 ne . and cga5 ne -1 and cga5 < 5   then cga5_cnf = "Y";
    else if cga5 ne . and cga5 ne -1           then cga5_cnf = "N"; else cga5_cnf = " ";
    if cga6 ne . and cga6 ne -1 and cga6 < 20  then cga6_cnf = "Y";
    else if cga6 ne . and cga6 ne -1           then cga6_cnf = "N"; else cga6_cnf = " ";
    if cga7 ne . and cga7 ne -1 and cga7 >= 6  then cga7_cnf = "Y";
    else if cga7 ne . and cga7 ne -1           then cga7_cnf = "N"; else cga7_cnf = " ";

    /*--- Frailty 分類 (CGA-screen+ 項目数による3群分類) ---*/
    cga_pos_n = 0;
    if cga1_scr = "Y" then cga_pos_n + 1;
    if cga2_scr = "Y" then cga_pos_n + 1;
    if cga3_scr = "Y" then cga_pos_n + 1;
    if cga4_scr = "Y" then cga_pos_n + 1;
    if cga5_scr = "Y" then cga_pos_n + 1;
    if cga6_scr = "Y" then cga_pos_n + 1;
    if cga7_scr = "Y" then cga_pos_n + 1;

    length cga_frail_class $15 cga_any $1;
    if cga_pos_n = 0 then cga_frail_class = "1_Robust";
    else if cga_pos_n in (1,2) then cga_frail_class = "2_Vulnerable";
    else if cga_pos_n >= 3 then cga_frail_class = "3_Frail";
    if cga_pos_n >= 1 then cga_any = "Y"; else cga_any = "N";

    /*--- 治療関連合併症 (主要10AE Gr?3) ---*/
    /* コース別フラグ */
    /* 主要10AE: FN=ae7 Sep=ae25 Lung=ae24 Cath=ae1 BPH=ae32 ICH=ae33 Hep=ae11 TLS=ae30 DIC=ae9 Anorec=ae8 */
    array a_i1 ae7i1 ae25i1 ae24i1 ae1i1 ae32i1 ae33i1 ae11i1 ae30i1 ae9i1 ae8i1;
    array a_i2 ae7i2 ae25i2 ae24i2 ae1i2 ae32i2 ae33i2 ae11i2 ae30i2 ae9i2 ae8i2;
    array a_c1 ae7c1 ae25c1 ae24c1 ae1c1 ae32c1 ae33c1 ae11c1 ae30c1 ae9c1 ae8c1;
    array a_c2 ae7c2 ae25c2 ae24c2 ae1c2 ae32c2 ae33c2 ae11c2 ae30c2 ae9c2 ae8c2;
    array a_c3 ae7c3 ae25c3 ae24c3 ae1c3 ae32c3 ae33c3 ae11c3 ae30c3 ae9c3 ae8c3;

    length comp_i1 comp_i2 comp_c1 comp_c2 comp_c3 comp_any $1;
    comp_i1 = "N"; do i = 1 to dim(a_i1); if a_i1[i] >= 3 then comp_i1 = "Y"; end;
    comp_i2 = "N"; do i = 1 to dim(a_i2); if a_i2[i] >= 3 then comp_i2 = "Y"; end;
    comp_c1 = "N"; do i = 1 to dim(a_c1); if a_c1[i] >= 3 then comp_c1 = "Y"; end;
    comp_c2 = "N"; do i = 1 to dim(a_c2); if a_c2[i] >= 3 then comp_c2 = "Y"; end;
    comp_c3 = "N"; do i = 1 to dim(a_c3); if a_c3[i] >= 3 then comp_c3 = "Y"; end;
    comp_any = "N";
    if comp_i1 = "Y" or comp_i2 = "Y" or comp_c1 = "Y" or comp_c2 = "Y" or comp_c3 = "Y"
       then comp_any = "Y";

    /*--- 治療関連合併症 [指標B]: 全33AE × Gr>=3 any ---*/
    array all_i1 ae1i1 ae2i1 ae3i1 ae4i1 ae5i1 ae6i1 ae7i1 ae8i1 ae9i1 ae10i1 ae11i1 ae12i1 ae13i1 ae14i1 ae15i1 ae16i1 ae17i1 ae18i1 ae19i1 ae20i1 ae21i1 ae22i1 ae23i1 ae24i1 ae25i1 ae26i1 ae27i1 ae28i1 ae29i1 ae30i1 ae31i1 ae32i1 ae33i1;
    array all_i2 ae1i2 ae2i2 ae3i2 ae4i2 ae5i2 ae6i2 ae7i2 ae8i2 ae9i2 ae10i2 ae11i2 ae12i2 ae13i2 ae14i2 ae15i2 ae16i2 ae17i2 ae18i2 ae19i2 ae20i2 ae21i2 ae22i2 ae23i2 ae24i2 ae25i2 ae26i2 ae27i2 ae28i2 ae29i2 ae30i2 ae31i2 ae32i2 ae33i2;
    array all_c1 ae1c1 ae2c1 ae3c1 ae4c1 ae5c1 ae6c1 ae7c1 ae8c1 ae9c1 ae10c1 ae11c1 ae12c1 ae13c1 ae14c1 ae15c1 ae16c1 ae17c1 ae18c1 ae19c1 ae20c1 ae21c1 ae22c1 ae23c1 ae24c1 ae25c1 ae26c1 ae27c1 ae28c1 ae29c1 ae30c1 ae31c1 ae32c1 ae33c1;
    array all_c2 ae1c2 ae2c2 ae3c2 ae4c2 ae5c2 ae6c2 ae7c2 ae8c2 ae9c2 ae10c2 ae11c2 ae12c2 ae13c2 ae14c2 ae15c2 ae16c2 ae17c2 ae18c2 ae19c2 ae20c2 ae21c2 ae22c2 ae23c2 ae24c2 ae25c2 ae26c2 ae27c2 ae28c2 ae29c2 ae30c2 ae31c2 ae32c2 ae33c2;
    array all_c3 ae1c3 ae2c3 ae3c3 ae4c3 ae5c3 ae6c3 ae7c3 ae8c3 ae9c3 ae10c3 ae11c3 ae12c3 ae13c3 ae14c3 ae15c3 ae16c3 ae17c3 ae18c3 ae19c3 ae20c3 ae21c3 ae22c3 ae23c3 ae24c3 ae25c3 ae26c3 ae27c3 ae28c3 ae29c3 ae30c3 ae31c3 ae32c3 ae33c3;
    length comp_all_i1 comp_all_i2 comp_all_c1 comp_all_c2 comp_all_c3 comp_all $1;
    comp_all_i1 = "N"; do i = 1 to dim(all_i1); if all_i1[i] >= 3 then comp_all_i1 = "Y"; end;
    comp_all_i2 = "N"; do i = 1 to dim(all_i2); if all_i2[i] >= 3 then comp_all_i2 = "Y"; end;
    comp_all_c1 = "N"; do i = 1 to dim(all_c1); if all_c1[i] >= 3 then comp_all_c1 = "Y"; end;
    comp_all_c2 = "N"; do i = 1 to dim(all_c2); if all_c2[i] >= 3 then comp_all_c2 = "Y"; end;
    comp_all_c3 = "N"; do i = 1 to dim(all_c3); if all_c3[i] >= 3 then comp_all_c3 = "Y"; end;
    comp_all = "N";
    if comp_all_i1="Y" or comp_all_i2="Y" or comp_all_c1="Y" or comp_all_c2="Y" or comp_all_c3="Y"
       then comp_all = "Y";

    /* AE別 患者単位 max grade */
    %macro mxg(short, vars);
        max_&short = max(of &vars);
        length any_&short $1;
        if max_&short >= 3 then any_&short = "Y";
        else if max_&short ne . then any_&short = "N";
        else any_&short = " ";
    %mend;
    %mxg(fn,    ae7i1 ae7i2 ae7c1 ae7c2 ae7c3);     /* Febrile neutropenia */
    %mxg(sep,   ae25i1 ae25i2 ae25c1 ae25c2 ae25c3);  /* Sepsis */
    %mxg(lung,  ae24i1 ae24i2 ae24c1 ae24c2 ae24c3);  /* Lung infection */
    %mxg(cath,  ae1i1 ae1i2 ae1c1 ae1c2 ae1c3);     /* Catheter related infection */
    %mxg(bph,   ae32i1 ae32i2 ae32c1 ae32c2 ae32c3);  /* Bronchopulmonary hemorrhage */
    %mxg(ich,   ae33i1 ae33i2 ae33c1 ae33c2 ae33c3);  /* Intracranial hemorrhage */
    %mxg(hep,   ae11i1 ae11i2 ae11c1 ae11c2 ae11c3);  /* Hepatic failure */
    %mxg(tls,   ae30i1 ae30i2 ae30c1 ae30c2 ae30c3);  /* Tumor lysis syndrome */
    %mxg(dic,   ae9i1 ae9i2 ae9c1 ae9c2 ae9c3);     /* DIC */
    %mxg(anorec,ae8i1 ae8i2 ae8c1 ae8c2 ae8c3);     /* Anorectal infection */

    drop i;

    label
        efs_first       = "EFSイベント分類"
        discont_fl      = "試験中止フラグ"
        treatresp       = "治療反応性 (3群)"
        age_c           = "年齢区分"
        blcci_c         = "ベースラインCCI区分"
        cga1_scr        = "CGA1 意欲 screen+"
        cga2_scr        = "CGA2 認知-復唱 screen+"
        cga3_scr        = "CGA3 IADL-Transport screen+"
        cga4_scr        = "CGA4 認知-遅延 screen+"
        cga5_scr        = "CGA5 ADL-入浴 screen+"
        cga6_scr        = "CGA6 ADL-排泄 screen+"
        cga7_scr        = "CGA7 抑うつ screen+"
        cga_pos_n       = "CGA screen+ 項目数 (0-7)"
        cga_frail_class = "Frailty 分類"
        cga_any         = "CGAいずれか screen+"
        comp_i1         = "寛解導入1 Gr3+ 主要AE"
        comp_i2         = "寛解導入2 Gr3+ 主要AE"
        comp_c1         = "地固め1 Gr3+ 主要AE"
        comp_c2         = "地固め2 Gr3+ 主要AE"
        comp_c3         = "地固め3 Gr3+ 主要AE"
        comp_any        = "全期間 Gr3+ 主要10AE any"
        comp_all_i1     = "寛解導入1 Gr3+ 全33AE any"
        comp_all_i2     = "寛解導入2 Gr3+ 全33AE any"
        comp_all_c1     = "地固め1 Gr3+ 全33AE any"
        comp_all_c2     = "地固め2 Gr3+ 全33AE any"
        comp_all_c3     = "地固め3 Gr3+ 全33AE any"
        comp_all        = "全期間 Gr3+ 全33AE any"
        any_fn          = "Febrile neutropenia Gr3+"
        any_sep         = "Sepsis Gr3+"
        any_lung        = "Lung infection Gr3+"
        any_cath        = "Catheter related infection Gr3+"
        any_bph         = "Bronchopulmonary hemorrhage Gr3+"
        any_ich         = "Intracranial hemorrhage Gr3+"
        any_hep         = "Hepatic failure Gr3+"
        any_tls         = "Tumor lysis syndrome Gr3+"
        any_dic         = "DIC Gr3+"
        any_anorec      = "Anorectal infection Gr3+"
    ;
run;

/*-----------------------------------------------------------------------------
  STEP 2: CGA7 項目別の問題あり分布
-----------------------------------------------------------------------------*/
title3 "(4-1) CGA7 各項目: screen+ × confirmed の対応";
proc freq data=ana;
    tables cga1_scr*cga1_cnf cga2_scr*cga2_cnf cga3_scr*cga3_cnf
           cga4_scr*cga4_cnf cga5_scr*cga5_cnf cga6_scr*cga6_cnf
           cga7_scr*cga7_cnf / list missing;
run;

title3 "(4-2) Frailty 分類分布 (FAS, n=121)";
proc freq data=ana;
    tables cga_pos_n cga_frail_class / missing;
run;

/*-----------------------------------------------------------------------------
  STEP 3: CGA / CCI / 年齢 × 主要アウトカム
-----------------------------------------------------------------------------*/
%macro xs(var, lbl);
    title3 "(4) &lbl × 主要アウトカム";
    title4 "vs 中止 / EFSイベント / 治療反応性 / Gr3+主要10AE / Gr3+全33AE / 最終転帰";
    proc freq data=ana;
        tables &var.*discont_fl
               &var.*efs_first
               &var.*treatresp
               &var.*comp_any
               &var.*comp_all
               &var.*dsterm2 / list missing;
    run;
%mend;

%xs(cga1_scr,        CGA1 意欲);
%xs(cga2_scr,        CGA2 認知-復唱);
%xs(cga3_scr,        CGA3 IADL-Transport);
%xs(cga4_scr,        CGA4 認知-遅延);
%xs(cga5_scr,        CGA5 ADL-入浴);
%xs(cga6_scr,        CGA6 ADL-排泄);
%xs(cga7_scr,        CGA7 抑うつ);
%xs(cga_frail_class, Frailty分類);
%xs(cga_any,         CGAいずれかscreen+);
%xs(blcci_c,         ベースラインCCI区分);
%xs(age_c,           年齢区分);

/*-----------------------------------------------------------------------------
  STEP 4: 治療関連合併症の集計
-----------------------------------------------------------------------------*/
title3 "(4-3) コース別 Gr3+ 発生: 主要10AE (comp_*) / 全33AE (comp_all_*)";
proc freq data=ana;
    tables comp_i1 comp_i2 comp_c1 comp_c2 comp_c3 comp_any
           comp_all_i1 comp_all_i2 comp_all_c1 comp_all_c2 comp_all_c3 comp_all / missing;
run;

title3 "(4-4) 主要10AE別 患者単位 Gr3+ 発生";
proc freq data=ana;
    tables any_fn any_sep any_lung any_cath any_bph any_ich
           any_hep any_tls any_dic any_anorec / missing;
run;

%macro aex(var, lbl);
    title3 "(4-5) &lbl × アウトカム";
    proc freq data=ana;
        tables &var.*treatresp &var.*efs_first &var.*discont_fl / list missing;
    run;
%mend;
%aex(any_fn,    Febrile neutropenia Gr3+);
%aex(any_sep,   Sepsis Gr3+);
%aex(any_lung,  Lung infection Gr3+);
%aex(any_cath,  Catheter infection Gr3+);
%aex(any_bph,   BP hemorrhage Gr3+);
%aex(any_ich,   IC hemorrhage Gr3+);
%aex(any_hep,   Hepatic failure Gr3+);
%aex(any_tls,   TLS Gr3+);
%aex(any_dic,   DIC Gr3+);
%aex(any_anorec,Anorectal infection Gr3+);
%aex(comp_any,  全期間 Gr3+主要AE);

/*-----------------------------------------------------------------------------
  STEP 5: 治療反応性 × Frailty × 合併症 × CCI
-----------------------------------------------------------------------------*/
title3 "(4-6) 治療反応性 × (合併症 / Frailty / CCI)";
proc freq data=ana;
    tables treatresp*comp_any treatresp*cga_frail_class treatresp*blcci_c / list missing;
run;

title3 "(4-7) Frailty / CCI / 年齢 × 合併症 (主要10AE と 全33AE 両指標)";
proc freq data=ana;
    tables cga_frail_class*comp_any cga_frail_class*comp_all
           blcci_c*comp_any         blcci_c*comp_all
           age_c*comp_any           age_c*comp_all / list missing;
run;

/*-----------------------------------------------------------------------------
  STEP 6: Frailty 3群 × アウトカム 検定
    - Frailty は順序 (Robust<Vulnerable<Frail)、群サイズ小 (Frail n=18)、
      一部 0セルあるため Fisher's exact を主検定とし、二値アウトカムでは
      Cochran-Armitage trend を併記。多値アウトカムでは CMH を併記。
-----------------------------------------------------------------------------*/
data ana_cr;
    set ana;
    length cr_bin $1;
    if treatresp = "1_CR" then cr_bin = "Y";
    else cr_bin = "N";
run;

title3 "(4-8) Frailty 3群 × アウトカム 検定";

title4 "(a) Frailty × 試験中止 (3x2)  ─ Cochran-Armitage trend + Fisher's exact";
proc freq data=ana;
    tables cga_frail_class*discont_fl / chisq trend nocum;
    exact fisher trend;
run;

title4 "(b) Frailty × CR達成 (3x2, CR=Y vs その他=N)  ─ Cochran-Armitage trend + Fisher's exact";
proc freq data=ana_cr;
    tables cga_frail_class*cr_bin / chisq trend nocum;
    exact fisher trend;
run;

title4 "(c) Frailty × 治療反応性 (3x3)  ─ CMH (行スコア=順序) + Fisher's exact";
proc freq data=ana;
    tables cga_frail_class*treatresp / chisq cmh nocum;
    exact fisher;
run;

title4 "(d) Frailty × EFS 初発イベント (3x4)  ─ Fisher's exact (RxC) + CMH";
proc freq data=ana;
    tables cga_frail_class*efs_first / chisq cmh nocum;
    exact fisher;
run;

title4 "(e) Frailty × Gr3+ 主要10AE (3x2, 極小セル)  ─ Fisher's exact + Cochran-Armitage trend";
proc freq data=ana;
    tables cga_frail_class*comp_any / chisq trend nocum;
    exact fisher trend;
run;

title4 "(f) Frailty × Gr3+ 全33AE (3x2)  ─ Fisher's exact + Cochran-Armitage trend";
proc freq data=ana;
    tables cga_frail_class*comp_all / chisq trend nocum;
    exact fisher trend;
run;

/*-----------------------------------------------------------------------------
  STEP 7: CCI区分 (2 vs 3+) × アウトカム 検定
    - 予測子は二値 (CCI=2 vs CCI?3) のため Fisher's exact を主検定。
      多値アウトカム (治療反応性3群, EFS 4群) は Fisher's exact (RxC) を主、
      治療反応性は列順序ありとして CMH 相関も併記。
-----------------------------------------------------------------------------*/
title3 "(4-9) CCI区分 (2 vs 3+) × アウトカム 検定";

title4 "(g) CCI × 試験中止 (2x2)  ─ Fisher's exact";
proc freq data=ana;
    tables blcci_c*discont_fl / chisq nocum;
    exact fisher;
run;

title4 "(h) CCI × CR達成 (2x2, CR=Y vs その他=N)  ─ Fisher's exact";
proc freq data=ana_cr;
    tables blcci_c*cr_bin / chisq nocum;
    exact fisher;
run;

title4 "(i) CCI × 治療反応性 (2x3)  ─ Fisher's exact (RxC) + CMH 相関 (列順序)";
proc freq data=ana;
    tables blcci_c*treatresp / chisq cmh nocum;
    exact fisher;
run;

title4 "(j) CCI × EFS 初発イベント (2x4)  ─ Fisher's exact (RxC)";
proc freq data=ana;
    tables blcci_c*efs_first / chisq cmh nocum;
    exact fisher;
run;

title4 "(k) CCI × Gr3+ 主要10AE (2x2)  ─ Fisher's exact";
proc freq data=ana;
    tables blcci_c*comp_any / chisq nocum;
    exact fisher;
run;

title4 "(l) CCI × Gr3+ 全33AE (2x2)  ─ Fisher's exact";
proc freq data=ana;
    tables blcci_c*comp_all / chisq nocum;
    exact fisher;
run;

/*-----------------------------------------------------------------------------
  STEP 8: 年齢区分 (65-69 vs 70-74) × アウトカム 検定
-----------------------------------------------------------------------------*/
title3 "(4-10) 年齢区分 (65-69 vs 70-74) × アウトカム 検定";

title4 "(m) 年齢 × 試験中止 (2x2)  ─ Fisher's exact";
proc freq data=ana;
    tables age_c*discont_fl / chisq nocum;
    exact fisher;
run;

title4 "(n) 年齢 × CR達成 (2x2, CR=Y vs その他=N)  ─ Fisher's exact";
proc freq data=ana_cr;
    tables age_c*cr_bin / chisq nocum;
    exact fisher;
run;

title4 "(o) 年齢 × 治療反応性 (2x3)  ─ Fisher's exact (RxC) + CMH 相関 (列順序)";
proc freq data=ana;
    tables age_c*treatresp / chisq cmh nocum;
    exact fisher;
run;

title4 "(p) 年齢 × EFS 初発イベント (2x4)  ─ Fisher's exact (RxC)";
proc freq data=ana;
    tables age_c*efs_first / chisq cmh nocum;
    exact fisher;
run;

title4 "(q) 年齢 × Gr3+ 主要10AE (2x2)  ─ Fisher's exact";
proc freq data=ana;
    tables age_c*comp_any / chisq nocum;
    exact fisher;
run;

title4 "(r) 年齢 × Gr3+ 全33AE (2x2)  ─ Fisher's exact";
proc freq data=ana;
    tables age_c*comp_all / chisq nocum;
    exact fisher;
run;

ods rtf close;
proc printto; run;

%put NOTE: 出力 - &root.\output\JALSG-GML219_Inquiry04_CGA_CCI.rtf;
