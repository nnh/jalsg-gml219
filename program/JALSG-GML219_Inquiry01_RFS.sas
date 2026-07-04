/******************************************************************************
* Project       : JALSG-GML219
* Program       : JALSG-GML219_Inquiry01_RFS.sas
* Author        : Akiko Saito
* Created       : 2026/05/24
*
* Purpose       : 主治医からの照会 (1) RFS数値の前回・今回の差異検証
*                 - 12月版解析プログラム (program\202512 pgm v1\) のDFS定義は
*                   「再発のみイベント」だった
*                 - 「再発 OR 全死亡」をイベントとする正しいRFS定義に修正し
*                   両者を比較する
*
* 対象          : FAS かつ 寛解導入1+2コースでCR達成 (cr1yn="CR")
* 入力          : input\ads\202512 data\gml219.sas7bdat
* 出力          : output\JALSG-GML219_Inquiry01_RFS.rtf
* ログ          : log\JALSG-GML219_Inquiry01_RFS.log
******************************************************************************/

options nofmterr ls=160 ps=80 nodate nonumber missing=" ";

%let root = C:\Users\AkikoSaito\Data\NMC\Stat\JALSG-GML219;
libname olda "&root.\input\ads\202512 data" access=readonly;

proc printto log="&root.\log\JALSG-GML219_Inquiry01_RFS.log"
             print="&root.\log\JALSG-GML219_Inquiry01_RFS.lst" new; run;

ods rtf file="&root.\output\JALSG-GML219_Inquiry01_RFS.rtf" style=listing bodytitle;
ods escapechar='^';
title  "JALSG-GML219 研究代表医師照会への回答資料 (1) RFS";
title2 "出力日: %sysfunc(today(),yymmddn8.)";

/*-----------------------------------------------------------------------------
  STEP 1: 旧解析と同じ DFS_y / DFS_c を再現
-----------------------------------------------------------------------------*/
title3 "(1-1) 12月版解析と同じ DFS 定義 (再発のみイベント)";

proc freq data=olda.gml219;
    where FASFL="Y" and cr1yn="CR";
    tables dfs_c*RLyn*dsterm2 / list missing;
    title4 "DFS_c (旧定義) × 再発 × 最終転帰  (FAS+CR, n=69)";
run;

proc lifetest data=olda.gml219 outsurv=km_old conftype=loglog noprint;
    where FASFL="Y" and cr1yn="CR";
    time dfs_y*dfs_c(0);
run;

/*-----------------------------------------------------------------------------
  STEP 2: RFS定義を修正 (再発 OR 全死亡をイベント)
-----------------------------------------------------------------------------*/
data work.fix;
    set olda.gml219;
    where FASFL="Y" and cr1yn="CR";
    if RLyn = "Y" then dfs_c2 = 1;
    else if upcase(dsterm2) = "DEATH" then dfs_c2 = 1;
    else dfs_c2 = 0;
    dfs_y2 = dfs_y;
    label
        dfs_c2 = "修正RFSイベントフラグ (1=再発 or 全死亡, 0=打ち切り)"
        dfs_y2 = "RFS期間 (年, CR日起点)"
    ;
run;

title3 "(1-2) 修正版 DFS 定義 (再発 OR 全死亡をイベント)";

proc freq data=fix;
    tables dfs_c2*RLyn*dsterm2 / list missing;
    title4 "DFS_c2 (修正) × 再発 × 最終転帰  (FAS+CR, n=69)";
run;

proc lifetest data=fix outsurv=km_fix conftype=loglog noprint;
    time dfs_y2*dfs_c2(0);
run;

/*-----------------------------------------------------------------------------
  STEP 3: 1年・2年KM推定値を旧定義 vs 修正定義で並列表示
-----------------------------------------------------------------------------*/
%macro km_landmark(insurv=, timevar=, year=, out=);
    data _land;
        set &insurv;
        where &timevar <= &year;
    run;
    proc sort data=_land; by &timevar; run;
    data &out (keep=year survival SDF_LCL SDF_UCL);
        set _land end=eof;
        by &timevar;
        if eof;
        year = &year;
    run;
%mend;

%km_landmark(insurv=km_old, timevar=dfs_y, year=1.0, out=land_old_1);
%km_landmark(insurv=km_old, timevar=dfs_y, year=2.0, out=land_old_2);
%km_landmark(insurv=km_fix, timevar=dfs_y2, year=1.0, out=land_fix_1);
%km_landmark(insurv=km_fix, timevar=dfs_y2, year=2.0, out=land_fix_2);

data summary;
    length defn $60;
    set land_old_1 (in=a) land_old_2 (in=b) land_fix_1 (in=c) land_fix_2 (in=d);
    if a or b then defn = "[旧] 再発のみイベント (12月解析)";
    else           defn = "[修正] 再発 OR 全死亡をイベント (今回解析)";
run;

title3 "(1-3) RFS 1年・2年 KM 推定値の比較";
title4;
proc print data=summary noobs label;
    var defn year survival SDF_LCL SDF_UCL;
    label defn      = "RFSイベント定義"
          year      = "経過年"
          survival  = "生存確率"
          SDF_LCL   = "95pctCI下限"
          SDF_UCL   = "95pctCI上限";
    format survival SDF_LCL SDF_UCL 8.4;
run;

ods rtf close;
proc printto; run;

%put NOTE: 出力 - &root.\output\JALSG-GML219_Inquiry01_RFS.rtf;
