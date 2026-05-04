/**************************************************************************************************
programmer   :AKIKO SAITO
file name    :JALSG-GML219_CSVtoSASDS.sas
date created :2026/05/03
description  :SDTMライクCSVから1症例1行の解析用データセット（gml219）を作成する
comment      :APL219R_CSVtoSASDS_rev2.sas を参考に GML219 用に新規作成
              ラベルに付けている情報は元データ列、変数変更時は確認必要
**************************************************************************************************/

title ;
footnote ;

proc datasets library=work kill nolist ;
quit ;

dm 'output; clear; log; clear;';

options nonumber notes nomprint ls=100 ps=9999 formdlim="-" center ;

ods listing;

/*====================================================================================*/
/* プロジェクトルートパスの定義（ここだけを環境に合わせて修正）                       */
/*====================================================================================*/
%let _root = /Users/akiko/Projects/NMC/Stat/JALSG-GML219;

/*====================================================================================*/
/* ログファイル出力設定                                                               */
/*====================================================================================*/
proc printto log="&_root./log/JALSG-GML219_CSVtoSASDS.log" new;
run;

/*====================================================================================*/
/* カットオフ日付（データ固定日：2025年12月5日）                                       */
/*====================================================================================*/
%let cutdt = '05DEC2025'd;

/*====================================================================================*/
/* libname                                                                            */
/*====================================================================================*/
libname adslib "&_root./input/ads/202512 data";

/*====================================================================================*/
/* CSVファイルインポート用マクロ                                                     */
/* %sasds_sdtm: SDTM固定データフォルダ                                               */
/* %sasds_ext:  外部ファイルフォルダ                                                 */
/*====================================================================================*/
%macro sasds_sdtm(dsnm);
proc import out= &dsnm
  datafile= "&_root./input/rawdata/20251205 fixed data/GML219_cdisc_251205_1446/&dsnm..csv"
  dbms=csv replace ;
  getnames=yes ;
  datarow=2 ;
  guessingrows=max ;
run ;
%mend;

%macro sasds_ext(dsnm);
proc import out= &dsnm
  datafile= "&_root./input/ext/&dsnm..csv"
  dbms=csv replace ;
  getnames=yes ;
  datarow=2 ;
  guessingrows=max ;
run ;
%mend;

/* SDTM ドメイン */
%sasds_sdtm(AE);
%sasds_sdtm(CE);
%sasds_sdtm(CM);
%sasds_sdtm(DD);
%sasds_sdtm(DM);
%sasds_sdtm(DS);
%sasds_sdtm(EC);
%sasds_sdtm(EG);
%sasds_sdtm(FA);
%sasds_sdtm(LB);
%sasds_sdtm(MH);
%sasds_sdtm(PE);
%sasds_sdtm(QS);
%sasds_sdtm(RS);
%sasds_sdtm(SC);
%sasds_sdtm(VS);

/* 外部ファイル */
%sasds_ext(facilities);
%sasds_ext(diseases);
%sasds_ext(saihi);


/***===================================================================================***/
/*** 1. 患者基本情報（DM + 施設 + 解析対象集団フラグ）                                ***/
/***===================================================================================***/

/* 1a. DM ドメイン：人口統計情報 */
data tmp1a(keep=usubjid subjid rfstdt rficdt brthdt age sex race siteid);
  set DM;
  length rfstdt rficdt brthdt age 8.;
  rfstdt = input(rfstdtc, yymmdd10.);
  rficdt = input(rficdtc, yymmdd10.);
  brthdt = input(brthdtc, yymmdd10.);
  age    = int(yrdif(brthdt, rficdt, 'AGE'));
  format rfstdt rficdt brthdt yymmdd10.;
  label rfstdt = "登録日"
        rficdt = "同意取得日"
        brthdt = "生年月日"
        age    = "同意取得時年齢"
        sex    = "性別"
        race   = "人種"
        siteid = "医療機関コード";
run;

/* 1b. 施設名（facilities.csv のヘッダーは日本語のため var1/var2 で取得） */
data tmp1b(keep=siteid sitenm);
  set facilities;
  length siteid $11. sitenm $100.;
  siteid = var1;
  sitenm = var2;
  label sitenm = "医療機関名";
run;

proc sort data=tmp1a; by siteid; run;
proc sort data=tmp1b; by siteid; run;

data tmp1c;
  merge tmp1a(in=a) tmp1b;
  by siteid;
  if a;
run;

/* 1d. 解析対象集団フラグ（saihi.csv） */
data tmp1d(keep=usubjid fasfl saffl ppsfl);
  set saihi;
  label fasfl = "FAS解析採用"
        saffl = "安全性解析対象集団採用"
        ppsfl = "PPS解析採用";
run;

proc sort data=tmp1c; by usubjid; run;
proc sort data=tmp1d; by usubjid; run;

data tmp1;
  merge tmp1c tmp1d;
  by usubjid;
run;


/***===================================================================================***/
/*** 2. 疾患情報（MH ドメイン：WHO/FAB診断、既往歴、CCI）                             ***/
/***===================================================================================***/

/* 2a. WHO分類（PRIMARY DIAGNOSIS） */
data tmp2a_who(keep=usubjid dxwhocd dxwhoterm);
  set MH;
  where mhcat = "PRIMARY DIAGNOSIS" and mhoccur = "Y";
  length dxwhocd $10. dxwhoterm $80.;
  dxwhocd  = strip(mhterm);
  /* 疾患コードから英語名に変換 */
  select (dxwhocd);
    when ('10300') dxwhoterm = "AML with t(8;21); RUNX1-RUNX1T1";
    when ('10310') dxwhoterm = "AML with inv(16)/t(16;16); CBFB-MYH11";
    when ('10350') dxwhoterm = "AML with inv(3)/t(3;3); GATA2,MECOM";
    when ('10370') dxwhoterm = "AML with mutated NPM1";
    when ('10390') dxwhoterm = "AML with myelodysplasia-related changes (MRC)";
    when ('10400') dxwhoterm = "Therapy-related myeloid neoplasms (t-MN)";
    when ('10420') dxwhoterm = "AML with minimal differentiation (M0)";
    when ('10430') dxwhoterm = "AML without maturation (M1)";
    when ('10440') dxwhoterm = "AML with maturation (M2)";
    when ('10450') dxwhoterm = "Acute myelomonocytic leukemia (M4)";
    when ('10460') dxwhoterm = "Acute monoblastic/monocytic leukemia (M5)";
    when ('11670') dxwhoterm = "AML with BCR-ABL1";
    otherwise      dxwhoterm = "";
  end;
  label dxwhocd   = "WHO分類コード"
        dxwhoterm = "WHO分類名（英語）";
run;

/* 2b. FAB分類 */
data tmp2b_fab(keep=usubjid fabclass);
  set MH;
  where mhcat = "FAB CRITERIA" and mhoccur = "Y";
  length fabclass $20.;
  fabclass = strip(mhterm);
  label fabclass = "FAB分類";
run;

/* 2c. 一般既往（GENERAL） */
data tmp2c_gen(keep=usubjid bl_bldabn bl_traml bl_infect8w);
  set MH;
  where mhcat = "GENERAL" and mhspid = "baseline1";
  length bl_bldabn bl_traml bl_infect8w $3.;
  retain bl_bldabn bl_traml bl_infect8w;
  by usubjid;
  if first.usubjid then call missing(bl_bldabn, bl_traml, bl_infect8w);
  if mhterm = "Presence or absence of prior blood abnormalities"
    then bl_bldabn = mhoccur;
  else if mhterm = "Have a history of suspected treatment-related AML"
    then bl_traml = mhoccur;
  else if mhterm = "Whether there is an infection that was treated with a drip within 8 weeks"
    then bl_infect8w = mhoccur;
  if last.usubjid;
  label bl_bldabn  = "前血球異常の既往"
        bl_traml   = "治療関連AML疑い既往"
        bl_infect8w= "登録8週以内の点滴治療を要した感染症";
run;

/* 2d. CCI（Charlson Comorbidity Index）各項目の重みを付けてスコア計算 */
/* baseline_cci と consoli1_cci（名称の表記ゆれに対応） */
data tmp2d_cci_items;
  set MH;
  where mhspid in ("baseline_cci","consoli1_cci");

  length ccispid $20. cciterm_std $50. cciweight 8.;
  ccispid = mhspid;

  /* 名称の表記ゆれを統一し、CCI重みを割り当て */
  select (mhterm);
    when ("Myocardial infarction")              do; cciterm_std="MI";         cciweight=1; end;
    when ("Congestive heart failure")           do; cciterm_std="CHF";        cciweight=1; end;
    when ("Peripheral vascular disease")        do; cciterm_std="PVD";        cciweight=1; end;
    when ("Cerebral vascular disease")          do; cciterm_std="CVD";        cciweight=1; end;
    when ("Dementia")                           do; cciterm_std="Dementia";   cciweight=1; end;
    when ("Chronic lung disease")               do; cciterm_std="CLD";        cciweight=1; end;
    when ("Collagen disease")                   do; cciterm_std="Collagen";   cciweight=1; end;
    when ("Peptic ulcer")                       do; cciterm_std="PepticUlcer";cciweight=1; end;
    when ("Mild liver disease")                 do; cciterm_std="MildLiver";  cciweight=1; end;
    when ("Diabetic complication")              do; cciterm_std="DiabComp";   cciweight=2; end;
    when ("Hemiplegia")                         do; cciterm_std="Hemiplegia"; cciweight=2; end;
    when ("Moderate to severe Renal dysfunction",
          "Renal dysfunction")                  do; cciterm_std="SevRenal";   cciweight=2; end;
    when ("Leukemia")                           do; cciterm_std="Leukemia";   cciweight=2; end;
    when ("Lymphoid tumor",
          "Lymphatic tumor")                    do; cciterm_std="Lymphoma";   cciweight=2; end;
    when ("Metastatic solid tumor",
          "Solid cancer metastasis")            do; cciterm_std="Metastasis"; cciweight=6; end;
    when ("Moderate to severe liver dysfunction",
          "Moderate to high degree of liver dysfunction")
                                                do; cciterm_std="SevLiver";   cciweight=3; end;
    when ("Acquired immunodeficiency syndrome") do; cciterm_std="AIDS";       cciweight=6; end;
    otherwise do; cciterm_std=""; cciweight=0; end;
  end;
run;

/* CCI スコア集計（"Y"＝該当、"N"/""/not done＝非該当） */
proc summary data=tmp2d_cci_items nway;
  where mhoccur = "Y" and cciterm_std ne "";
  class usubjid ccispid;
  var cciweight;
  output out=tmp2d_cci_sum(drop=_type_ _freq_) sum=ccisum;
run;

proc transpose data=tmp2d_cci_sum out=tmp2d_cci_t prefix=cci;
  by usubjid;
  id ccispid;
  var ccisum;
run;

data tmp2d_cci(keep=usubjid cci_bl cci_c1);
  set tmp2d_cci_t;
  length cci_bl cci_c1 8.;
  if cmiss(ccibaseline_cci) then cci_bl = 0; else cci_bl = ccibaseline_cci;
  if cmiss(cciconsoli1_cci) then cci_c1 = 0; else cci_c1 = cciconsoli1_cci;
  label cci_bl = "Charlson合併症スコア（登録時）"
        cci_c1 = "Charlson合併症スコア（地固め1後）";
run;


/***===================================================================================***/
/*** 3. ベースライン臨床検査値（LB ドメイン、LBSPID="baseline2"）                     ***/
/***===================================================================================***/

data tmp3_lb;
  set LB;
  where lbspid = "baseline2";
  length lbval $50.;
  lbval = strip(lborres);
run;

proc sort data=tmp3_lb; by usubjid lbtestcd; run;

proc transpose data=tmp3_lb out=tmp3_lb_t prefix=_lb_;
  by usubjid;
  id lbtestcd;
  var lbval;
run;

/* 必要な変数を取り出して型変換 */
data tmp3_labs(keep=usubjid
    bl_wbc bl_neut bl_hgb bl_plat bl_retirbc bl_blastle bl_myblale
    bl_mpo bl_ldh bl_ast bl_alt bl_alp bl_bili bl_creat bl_crp bl_alb bl_inr bl_ua
    bl_wt1mrna
    /* 遺伝子異常（文字変数） */
    flt3itd npm1 cebpa kit runx1 sf3b1
    /* 染色体異常（文字変数） */
    t821 inv16 t1616 t911 t69 t122p13q t922 inv3 mns5 del5q mns7 mns17abn cta3km otchrabn chroabno
    /* セルマーカー（文字変数） */
    cd2 cd3 cd4 cd5 cd7 cd8 cd10 cd11b cd13 cd14 cd16 cd19 cd20 cd33 cd34 cd41a cd56 cd117
    hladr glycoina mpo_cm cellular);

  set tmp3_lb_t;
  length
    bl_wbc bl_neut bl_hgb bl_plat bl_retirbc bl_blastle bl_myblale
    bl_mpo bl_ldh bl_ast bl_alt bl_alp bl_bili bl_creat bl_crp bl_alb bl_inr bl_ua
    bl_wt1mrna 8.
    flt3itd npm1 cebpa kit runx1 sf3b1 $20.
    t821 inv16 t1616 t911 t69 t122p13q t922 inv3 mns5 del5q mns7 mns17abn cta3km otchrabn chroabno $3.
    cd2 cd3 cd4 cd5 cd7 cd8 cd10 cd11b cd13 cd14 cd16 cd19 cd20 cd33 cd34 cd41a cd56 cd117 $20.
    hladr glycoina mpo_cm cellular $20.;

  /* 数値検査値 */
  bl_wbc     = input(_lb_WBC,     best.);
  bl_neut    = input(_lb_NEUT,    best.);
  bl_hgb     = input(_lb_HGB,     best.);
  bl_plat    = input(_lb_PLAT,    best.);
  bl_retirbc = input(_lb_RETIRBC, best.);
  bl_blastle = input(_lb_BLASTLE, best.);
  bl_myblale = input(_lb_MYBLALE, best.);
  bl_mpo     = input(_lb_MPO,     best.);
  bl_ldh     = input(_lb_LDH,     best.);
  bl_ast     = input(_lb_AST,     best.);
  bl_alt     = input(_lb_ALT,     best.);
  bl_alp     = input(_lb_ALP,     best.);
  bl_bili    = input(_lb_BILI,    best.);
  bl_creat   = input(_lb_CREAT,   best.);
  bl_crp     = input(_lb_CRP,     best.);
  bl_alb     = input(_lb_ALB,     best.);
  bl_inr     = input(_lb_INR,     best.);
  bl_ua      = input(_lb_CYURIAC, best.);
  bl_wt1mrna = input(_lb_WT1MRNA, best.);

  /* 遺伝子変異（POSITIVE/NEGATIVE/NOT DONE） */
  flt3itd = strip(_lb_FLT3_ITD);  /* CSV読み込み時にFLT3-ITD→FLT3_ITD に変換される */
  npm1    = strip(_lb_NPM1);
  cebpa   = strip(_lb_CEBPA);
  kit     = strip(_lb_KIT);
  runx1   = strip(_lb_RUNX1);
  sf3b1   = strip(_lb_SF3B1);

  /* 染色体異常（Y/N/""） */
  t821     = strip(_lb_T821);
  inv16    = strip(_lb_INV16);
  t1616    = strip(_lb_T1616);
  t911     = strip(_lb_T911);
  t69      = strip(_lb_T69);
  t122p13q = strip(_lb_T122P13Q);
  t922     = strip(_lb_T922);
  inv3     = strip(_lb_INV3);
  mns5     = strip(_lb_MNS5);
  del5q    = strip(_lb_DEL5Q);
  mns7     = strip(_lb_MNS7);
  mns17abn = strip(_lb_MNS17ABN);
  cta3km   = strip(_lb_CTA_3KM_);
  otchrabn = strip(_lb_OTCHRABN);
  chroabno = strip(_lb_CHROABNO);

  /* セルマーカー */
  cd2    = strip(_lb_CD2);
  cd3    = strip(_lb_CD3);
  cd4    = strip(_lb_CD4);
  cd5    = strip(_lb_CD5);
  cd7    = strip(_lb_CD7);
  cd8    = strip(_lb_CD8);
  cd10   = strip(_lb_CD10);
  cd11b  = strip(_lb_CD11B);
  cd13   = strip(_lb_CD13);
  cd14   = strip(_lb_CD14);
  cd16   = strip(_lb_CD16);
  cd19   = strip(_lb_CD19);
  cd20   = strip(_lb_CD20);
  cd33   = strip(_lb_CD33);
  cd34   = strip(_lb_CD34);
  cd41a  = strip(_lb_CD41a);
  cd56   = strip(_lb_CD56);
  cd117  = strip(_lb_CD117);
  hladr  = strip(_lb_HLADR);
  glycoina = strip(_lb_GLYCOINA);
  mpo_cm   = strip(_lb_MPO);
  cellular = strip(_lb_CELLULAR);

  label
    bl_wbc     = "Baseline WBC（/μL）"
    bl_neut    = "Baseline 好中球数（/μL）"
    bl_hgb     = "Baseline Hgb（g/dL）"
    bl_plat    = "Baseline 血小板（万/μL）"
    bl_retirbc = "Baseline 網赤血球数"
    bl_blastle = "Baseline 末梢血芽球比率（%）"
    bl_myblale = "Baseline 骨髄芽球比率（%）"
    bl_mpo     = "Baseline MPO（IU/L）"
    bl_ldh     = "Baseline LDH（IU/L）"
    bl_ast     = "Baseline AST（IU/L）"
    bl_alt     = "Baseline ALT（IU/L）"
    bl_alp     = "Baseline ALP（IU/L）"
    bl_bili    = "Baseline ビリルビン（mg/dL）"
    bl_creat   = "Baseline クレアチニン（mg/dL）"
    bl_crp     = "Baseline CRP（mg/dL）"
    bl_alb     = "Baseline アルブミン（g/dL）"
    bl_inr     = "Baseline INR"
    bl_ua      = "Baseline 尿酸（mg/dL）"
    bl_wt1mrna = "Baseline WT-1 mRNA（コピー/μgRNA）"
    flt3itd    = "FLT3-ITD変異"
    npm1       = "NPM1変異"
    cebpa      = "CEBPA変異"
    kit        = "KIT変異"
    runx1      = "RUNX1変異"
    sf3b1      = "SF3B1変異"
    t821       = "t(8;21)"
    inv16      = "inv(16)"
    t1616      = "t(16;16)"
    t911       = "t(9;11)"
    t69        = "t(6;9)"
    t122p13q   = "t(12;p13q)"
    t922       = "t(9;22)"
    inv3       = "inv(3)"
    mns5       = "モノソミー5"
    del5q      = "del(5q)"
    mns7       = "モノソミー7"
    mns17abn   = "17p異常"
    cta3km     = "複合核型（?3異常）"
    otchrabn   = "その他染色体異常"
    chroabno   = "染色体異常（有無）"
    cd2="CD2" cd3="CD3" cd4="CD4" cd5="CD5" cd7="CD7" cd8="CD8"
    cd10="CD10" cd11b="CD11b" cd13="CD13" cd14="CD14" cd16="CD16"
    cd19="CD19" cd20="CD20" cd33="CD33" cd34="CD34" cd41a="CD41a"
    cd56="CD56" cd117="CD117" hladr="HLA-DR" glycoina="グリコフォリンA"
    mpo_cm="MPO（フローサイトメトリー）" cellular="CELLマーカー";
run;


/***===================================================================================***/
/*** 4. ELN 2017 リスク分類（遺伝子・染色体データから導出）                           ***/
/***===================================================================================***/

data tmp4_eln(keep=usubjid eln2017);
  set tmp3_labs;
  length eln2017 $20.;

  /* Favorable */
  if t821='Y' or inv16='Y' or t1616='Y' then eln2017='Favorable';       /* CBF-AML */
  else if npm1='POSITIVE' and flt3itd='NEGATIVE' then eln2017='Favorable'; /* NPM1 mut/FLT3neg */
  else if cebpa='POSITIVE' then eln2017='Favorable';                     /* CEBPA （二対立遺伝子変異想定） */

  /* Adverse */
  else if inv3='Y' or t69='Y' or t922='Y' then eln2017='Adverse';
  else if mns5='Y' or del5q='Y' or mns7='Y' then eln2017='Adverse';
  else if cta3km='Y' then eln2017='Adverse';                             /* 複合核型 */
  else if mns17abn='Y' then eln2017='Adverse';
  else if runx1='POSITIVE' then eln2017='Adverse';
  else if npm1='NEGATIVE' and flt3itd='POSITIVE' then eln2017='Adverse'; /* WT NPM1 + FLT3-ITD */

  /* Intermediate */
  else eln2017='Intermediate';

  /* 評価不能 */
  if npm1='' and flt3itd='' and cebpa='' and
     t821='' and inv16='' and t1616='' and
     runx1='' and chroabno='' then eln2017='Unknown';

  label eln2017 = "ELN 2017 リスク分類";
run;


/***===================================================================================***/
/*** 5. バイタルサイン（VS）・ECOG PS（QS）・心機能（PE, EG）                         ***/
/***===================================================================================***/

/* 5a. 身長・体重・BMI */
data tmp5a_vs(keep=usubjid height weight bmi);
  set VS;
  where vsspid = "baseline2";
  length height weight bmi 8.;
  retain height weight;
  by usubjid;
  if first.usubjid then call missing(height, weight);
  if vstestcd = "HEIGHT" then height = input(vsorres, best.);
  else if vstestcd = "WEIGHT" then weight = input(vsorres, best.);
  if last.usubjid;
  if height > 0 then bmi = weight / (height/100)**2;
  label height = "身長（cm）"
        weight = "体重（kg）"
        bmi    = "BMI（kg/m?）";
run;

/* 5b. ECOG PS */
data tmp5b_ecog(keep=usubjid ecogps);
  set QS;
  where qstestcd = "ECOG101" and qsspid = "baseline2";
  length ecogps 8.;
  ecogps = input(qsorres, best.);
  label ecogps = "ECOG Performance Status（登録時）";
run;

/* 5c. 心エコー所見（PE） */
data tmp5c_echo(keep=usubjid echo_result);
  set PE;
  where pespid = "baseline2" and petestcd = "ECHO";
  length echo_result $100.;
  echo_result = strip(peorres);
  label echo_result = "心エコー所見";
run;

/* 5d. 心電図所見（EG） */
data tmp5d_ecg(keep=usubjid ecg_intp);
  set EG;
  where egspid = "baseline2" and egtestcd = "INTP";
  length ecg_intp $100.;
  ecg_intp = strip(egorres);
  label ecg_intp = "心電図判定";
run;


/***===================================================================================***/
/*** 6. CGA7（QS ドメイン：baseline_cga および consoli1_cga）                         ***/
/***===================================================================================***/

data tmp6_cga;
  set QS;
  where qscat = "CGA7";
  length cga_phase $20.;
  if qsspid = "baseline_cga"  then cga_phase = "bl";
  else if qsspid = "consoli1_cga" then cga_phase = "c1";
  else delete;
run;

proc sort data=tmp6_cga; by usubjid qsspid qstestcd; run;

proc transpose data=tmp6_cga out=tmp6_cga_t;
  by usubjid;
  id qstestcd cga_phase;
  var qsorres;
run;

data tmp6_cga_final(drop=_name_);
  set tmp6_cga_t;
  /* 変数名を小文字化してラベル付け */
  rename
    CGA1A_bl=cga1a_bl CGA1B_bl=cga1b_bl
    CGA2A_bl=cga2a_bl CGA2B_bl=cga2b_bl
    CGA3A_bl=cga3a_bl CGA3B_bl=cga3b_bl
    CGA4A_bl=cga4a_bl CGA4B_bl=cga4b_bl
    CGA5A_bl=cga5a_bl CGA5B_bl=cga5b_bl
    CGA6A_bl=cga6a_bl CGA6B_bl=cga6b_bl
    CGA7A_bl=cga7a_bl CGA7B_bl=cga7b_bl
    CGA1A_c1=cga1a_c1 CGA1B_c1=cga1b_c1
    CGA2A_c1=cga2a_c1 CGA2B_c1=cga2b_c1
    CGA3A_c1=cga3a_c1 CGA3B_c1=cga3b_c1
    CGA4A_c1=cga4a_c1 CGA4B_c1=cga4b_c1
    CGA5A_c1=cga5a_c1 CGA5B_c1=cga5b_c1
    CGA6A_c1=cga6a_c1 CGA6B_c1=cga6b_c1
    CGA7A_c1=cga7a_c1 CGA7B_c1=cga7b_c1;
run;

proc datasets library=work nolist;
  modify tmp6_cga_final;
  label
    cga1a_bl = "活気（登録時）" cga1b_bl = "活気指数 VitalityIndex（登録時）"
    cga2a_bl = "認知機能-復唱（登録時）" cga2b_bl = "MoCA-J スコア（登録時）"
    cga3a_bl = "IADL-交通機関（登録時）" cga3b_bl = "IADL 合計（登録時）"
    cga4a_bl = "認知機能-遅延再生（登録時）" cga4b_bl = "MoCA-J 遅延再生（登録時）"
    cga5a_bl = "ADL-入浴（登録時）" cga5b_bl = "Barthel Index（登録時）"
    cga6a_bl = "ADL-排泄（登録時）" cga6b_bl = "Barthel Index 合計（登録時）"
    cga7a_bl = "気分（登録時）" cga7b_bl = "GDS-15 スコア（登録時）"
    cga1a_c1 = "活気（地固め1後）" cga1b_c1 = "活気指数 VitalityIndex（地固め1後）"
    cga2a_c1 = "認知機能-復唱（地固め1後）" cga2b_c1 = "MoCA-J スコア（地固め1後）"
    cga3a_c1 = "IADL-交通機関（地固め1後）" cga3b_c1 = "IADL 合計（地固め1後）"
    cga4a_c1 = "認知機能-遅延再生（地固め1後）" cga4b_c1 = "MoCA-J 遅延再生（地固め1後）"
    cga5a_c1 = "ADL-入浴（地固め1後）" cga5b_c1 = "Barthel Index（地固め1後）"
    cga6a_c1 = "ADL-排泄（地固め1後）" cga6b_c1 = "Barthel Index 合計（地固め1後）"
    cga7a_c1 = "気分（地固め1後）" cga7b_c1 = "GDS-15 スコア（地固め1後）";
quit;


/***===================================================================================***/
/*** 7. CNS浸潤・その他髄外浸潤（FA ドメイン、FASPID="baseline2"）                   ***/
/***===================================================================================***/

data tmp7_ext(keep=usubjid bl_cnsyn bl_cnsstat bl_ocnsyn bl_ocnsstat);
  set FA;
  where faspid = "baseline2";
  length bl_cnsyn bl_cnsstat bl_ocnsyn bl_ocnsstat $20.;
  retain bl_cnsyn bl_cnsstat bl_ocnsyn bl_ocnsstat;
  by usubjid;
  if first.usubjid then call missing(bl_cnsyn, bl_cnsstat, bl_ocnsyn, bl_ocnsstat);
  if faobj = "CNS involvement" then do;
    bl_cnsyn   = strip(faorres);
    bl_cnsstat = strip(fastat);
  end;
  else if faobj = "Other extramedullary involvement" then do;
    bl_ocnsyn   = strip(faorres);
    bl_ocnsstat = strip(fastat);
  end;
  if last.usubjid;
  label bl_cnsyn   = "Baseline CNS浸潤有無"
        bl_cnsstat = "Baseline CNS浸潤評価実施有無"
        bl_ocnsyn  = "Baseline その他髄外浸潤有無"
        bl_ocnsstat= "Baseline その他髄外浸潤評価実施有無";
run;


/***===================================================================================***/
/*** 8. 効果判定（RS ドメイン）：評価1?5の Overall Response と CR到達日              ***/
/***===================================================================================***/

data tmp8_rs;
  set RS;
  where rstestcd = "OVRLRESP";
  length rsdt 8.;
  rsdt = input(rsdtc, yymmdd10.);
  format rsdt yymmdd10.;
run;

proc sort data=tmp8_rs; by usubjid rsspid; run;

/* 評価ごとに transpose */
proc transpose data=tmp8_rs out=tmp8_rs_rsorres prefix=rs_ev;
  by usubjid;
  id rsspid;
  var rsorres;
run;

proc transpose data=tmp8_rs out=tmp8_rs_rsdt prefix=rsdt_ev;
  by usubjid;
  id rsspid;
  var rsdt;
run;

data tmp8_rsresp(drop=_name_);
  set tmp8_rs_rsorres;
  rename
    rs_evevaluation1=rs_ev1 rs_evevaluation2=rs_ev2
    rs_evevaluation3=rs_ev3 rs_evevaluation4=rs_ev4
    rs_evevaluation5=rs_ev5;
  label
    rs_evevaluation1 = "効果判定1（寛解導入1後）"
    rs_evevaluation2 = "効果判定2（寛解導入2後）"
    rs_evevaluation3 = "効果判定3（地固め1後）"
    rs_evevaluation4 = "効果判定4（地固め2後）"
    rs_evevaluation5 = "効果判定5（地固め3後）";
run;

data tmp8_rsdt(drop=_name_);
  set tmp8_rs_rsdt;
  format rsdt_evevaluation1 rsdt_evevaluation2 rsdt_evevaluation3
         rsdt_evevaluation4 rsdt_evevaluation5 yymmdd10.;
  rename
    rsdt_evevaluation1=rsdt_ev1 rsdt_evevaluation2=rsdt_ev2
    rsdt_evevaluation3=rsdt_ev3 rsdt_evevaluation4=rsdt_ev4
    rsdt_evevaluation5=rsdt_ev5;
  label
    rsdt_evevaluation1 = "効果判定日1（寛解導入1後）"
    rsdt_evevaluation2 = "効果判定日2（寛解導入2後）"
    rsdt_evevaluation3 = "効果判定日3（地固め1後）"
    rsdt_evevaluation4 = "効果判定日4（地固め2後）"
    rsdt_evevaluation5 = "効果判定日5（地固め3後）";
run;

proc sort data=tmp8_rsresp; by usubjid; run;
proc sort data=tmp8_rsdt;   by usubjid; run;

data tmp8_rsfull;
  merge tmp8_rsresp tmp8_rsdt;
  by usubjid;
run;

/* CR到達日（最初にCRを記録した評価の日付） */
data tmp8_crdt(keep=usubjid crfl crdt);
  set RS;
  where rstestcd = "OVRLRESP" and rsorres = "CR";
  length crdt 8.;
  crdt = input(rsdtc, yymmdd10.);
  format crdt yymmdd10.;
run;

proc sort data=tmp8_crdt; by usubjid crdt; run;

data tmp8_cr(keep=usubjid crfl crdt);
  set tmp8_crdt;
  by usubjid;
  if first.usubjid;
  crfl = "Y";
  label crfl = "CR到達（Y/N）"
        crdt = "初回CR評価日（LFS起算日）";
run;


/***===================================================================================***/
/*** 9. 再発（CE ドメイン）                                                           ***/
/***===================================================================================***/

data tmp9_relapse(keep=usubjid relapse reldt);
  set CE;
  where cespid = "relapse" and ceoccur = "Y";
  length reldt 8.;
  relapse = "Y";
  reldt = input(cedtc, yymmdd10.);
  format reldt yymmdd10.;
  label relapse = "再発（Y）"
        reldt   = "再発日";
run;

/* 再発が複数記録されている場合は最初のみ使用 */
proc sort data=tmp9_relapse; by usubjid reldt; run;

data tmp9_relapse;
  set tmp9_relapse;
  by usubjid;
  if first.usubjid;
run;


/***===================================================================================***/
/*** 10. 転帰（DS, DD ドメイン）                                                      ***/
/***===================================================================================***/

/* 10a. 投与完了/中止（DS, DSSPID="discontinuation"） */
data tmp10a_disc(keep=usubjid dsterm dsstdt);
  set DS;
  where dsspid = "discontinuation";
  length dsstdt 8.;
  dsstdt = input(dsstdtc, yymmdd10.);
  format dsstdt yymmdd10.;
  label dsterm = "治験薬投与完了/中止理由"
        dsstdt = "治験薬投与完了/中止日";
run;

/* 10b. 試験参加完了/中止（DS, DSSPID="withdrawal"）：最終観察日/死亡日 */
data tmp10b_with(keep=usubjid dsterm2 dsstdt2);
  set DS;
  where dsspid = "withdrawal";
  length dsterm2 $60. dsstdt2 8.;
  dsterm2 = strip(dsterm);
  dsstdt2 = input(dsstdtc, yymmdd10.);
  format dsstdt2 yymmdd10.;
  label dsterm2 = "試験完了/中止理由（生存/死亡）"
        dsstdt2 = "最終生存確認日/死亡日";
run;

/* 10c. 死亡原因（DD ドメイン） */
data tmp10c_dd(keep=usubjid prcdth);
  set DD;
  where ddspid = "withdrawal" and ddtestcd = "PRCDTH";
  length prcdth $100.;
  prcdth = strip(ddorres);
  label prcdth = "主な死亡原因";
run;

proc sort data=tmp10a_disc; by usubjid; run;
proc sort data=tmp10b_with; by usubjid; run;
proc sort data=tmp10c_dd;   by usubjid; run;


/***===================================================================================***/
/*** 11. 治療情報（EC ドメイン）：各コース開始日・終了日・投与量                       ***/
/***===================================================================================***/

data tmp11_ec;
  set EC;
  length ecstdt ecendt 8.;
  ecstdt = input(ecstdtc, yymmdd10.);
  ecendt = input(ecendtc, yymmdd10.);
  format ecstdt ecendt yymmdd10.;
  dose_n = input(ecdose, best.);
run;

/* 寛解導入1（DNR） */
data tmp11a_i1dnr(keep=usubjid ind1stdt ind1enddt ind1dnrdose);
  set tmp11_ec;
  where ecspid = "induction1" and ectrt = "DAUNORUBICIN HYDROCHLORIDE";
  ind1stdt   = ecstdt;
  ind1enddt  = ecendt;
  ind1dnrdose= dose_n;
  format ind1stdt ind1enddt yymmdd10.;
  label ind1stdt   = "寛解導入1開始日"
        ind1enddt  = "寛解導入1終了日"
        ind1dnrdose= "寛解導入1 DNR総投与量（mg/m?）";
run;

/* 寛解導入1（AraC） */
data tmp11b_i1ara(keep=usubjid ind1aradose);
  set tmp11_ec;
  where ecspid = "induction1" and ectrt = "CYTARABINE";
  ind1aradose = dose_n;
  label ind1aradose = "寛解導入1 AraC総投与量（mg/m?）";
run;

/* 寛解導入2（DNR） */
data tmp11c_i2dnr(keep=usubjid ind2stdt ind2enddt ind2dnrdose);
  set tmp11_ec;
  where ecspid = "induction2" and ectrt = "DAUNORUBICIN HYDROCHLORIDE";
  ind2stdt   = ecstdt;
  ind2enddt  = ecendt;
  ind2dnrdose= dose_n;
  format ind2stdt ind2enddt yymmdd10.;
  label ind2stdt   = "寛解導入2開始日"
        ind2enddt  = "寛解導入2終了日"
        ind2dnrdose= "寛解導入2 DNR総投与量（mg/m?）";
run;

/* 寛解導入2（AraC） */
data tmp11d_i2ara(keep=usubjid ind2aradose);
  set tmp11_ec;
  where ecspid = "induction2" and ectrt = "CYTARABINE";
  ind2aradose = dose_n;
  label ind2aradose = "寛解導入2 AraC総投与量（mg/m?）";
run;

/* 地固め1（MIT） */
data tmp11e_c1mit(keep=usubjid c1stdt c1enddt c1mitdose);
  set tmp11_ec;
  where ecspid = "consolidation1" and ectrt = "MITOXANTRONE HYDROCHLORIDE";
  c1stdt   = ecstdt;
  c1enddt  = ecendt;
  c1mitdose= dose_n;
  format c1stdt c1enddt yymmdd10.;
  label c1stdt   = "地固め1開始日"
        c1enddt  = "地固め1終了日"
        c1mitdose= "地固め1 MIT総投与量（mg/m?）";
run;

/* 地固め1（AraC） */
data tmp11f_c1ara(keep=usubjid c1aradose);
  set tmp11_ec;
  where ecspid = "consolidation1" and ectrt = "CYTARABINE";
  c1aradose = dose_n;
  label c1aradose = "地固め1 AraC総投与量（mg/m?）";
run;

/* 地固め2（DNR） */
data tmp11g_c2dnr(keep=usubjid c2stdt c2enddt c2dnrdose);
  set tmp11_ec;
  where ecspid = "consolidation2" and ectrt = "DAUNORUBICIN HYDROCHLORIDE";
  c2stdt   = ecstdt;
  c2enddt  = ecendt;
  c2dnrdose= dose_n;
  format c2stdt c2enddt yymmdd10.;
  label c2stdt   = "地固め2開始日"
        c2enddt  = "地固め2終了日"
        c2dnrdose= "地固め2 DNR総投与量（mg/m?）";
run;

/* 地固め2（AraC） */
data tmp11h_c2ara(keep=usubjid c2aradose);
  set tmp11_ec;
  where ecspid = "consolidation2" and ectrt = "CYTARABINE";
  c2aradose = dose_n;
  label c2aradose = "地固め2 AraC総投与量（mg/m?）";
run;

/* 地固め3（ACR） */
data tmp11i_c3acr(keep=usubjid c3stdt c3enddt c3acrdose);
  set tmp11_ec;
  where ecspid = "consolidation3" and ectrt = "ACLARUBICIN HYDROCHLORIDE";
  c3stdt   = ecstdt;
  c3enddt  = ecendt;
  c3acrdose= dose_n;
  format c3stdt c3enddt yymmdd10.;
  label c3stdt   = "地固め3開始日"
        c3enddt  = "地固め3終了日"
        c3acrdose= "地固め3 ACR総投与量（mg/m?）";
run;

/* 地固め3（AraC） */
data tmp11j_c3ara(keep=usubjid c3aradose);
  set tmp11_ec;
  where ecspid = "consolidation3" and ectrt = "CYTARABINE";
  c3aradose = dose_n;
  label c3aradose = "地固め3 AraC総投与量（mg/m?）";
run;

/* 髄注（TIT：INTRATHECAL）*/
data tmp11k_tit(keep=usubjid titfl);
  set tmp11_ec;
  where ecspid = "consolidation3" and ectrt = "INTRATHECAL";
  length titfl $3.;
  titfl = strip(ecoccur);
  if titfl = "" then titfl = strip(ecdose);  /* ECOCCURが空の場合はECDOSEを確認 */
  label titfl = "髄注実施（Y/N）";
run;

%macro sort_ec(ds);
proc sort data=&ds; by usubjid; run;
%mend;

%sort_ec(tmp11a_i1dnr); %sort_ec(tmp11b_i1ara);
%sort_ec(tmp11c_i2dnr); %sort_ec(tmp11d_i2ara);
%sort_ec(tmp11e_c1mit); %sort_ec(tmp11f_c1ara);
%sort_ec(tmp11g_c2dnr); %sort_ec(tmp11h_c2ara);
%sort_ec(tmp11i_c3acr); %sort_ec(tmp11j_c3ara);
%sort_ec(tmp11k_tit);

data tmp11_tx;
  merge tmp11a_i1dnr tmp11b_i1ara
        tmp11c_i2dnr tmp11d_i2ara
        tmp11e_c1mit tmp11f_c1ara
        tmp11g_c2dnr tmp11h_c2ara
        tmp11i_c3acr tmp11j_c3ara
        tmp11k_tit;
  by usubjid;
run;


/***===================================================================================***/
/*** 12. 有害事象グレード（FA ドメイン）：コース別×AE項目 転置                         ***/
/***===================================================================================***/

data tmp12_fa;
  set FA;
  where fatest = "Grade";
  length grade 8.;
  grade = input(faorres, best.);

  /* コース別短縮コード */
  length phase_cd $3.;
  if      faspid = "induction1ae"     then phase_cd = "i1";
  else if faspid = "induction2ae"     then phase_cd = "i2";
  else if faspid = "consolidation1ae" then phase_cd = "c1";
  else if faspid = "consolidation2ae" then phase_cd = "c2";
  else if faspid = "consolidation3ae" then phase_cd = "c3";
  else delete;

  /* AE項目コード */
  length ae_cd $5.;
  if      faobj = "Alanine aminotransferase increased"   then ae_cd = "ae01";
  else if faobj = "Allergic reaction"                    then ae_cd = "ae02";
  else if faobj = "Anorectal infection"                  then ae_cd = "ae03";
  else if faobj = "Aspartate aminotransferase increased" then ae_cd = "ae04";
  else if faobj = "Blood bilirubin increased"            then ae_cd = "ae05";
  else if faobj = "Bronchopulmonary hemorrhage"          then ae_cd = "ae06";
  else if faobj = "Cardiac disorders - Other"            then ae_cd = "ae07";
  else if faobj = "Catheter related infection"           then ae_cd = "ae08";
  else if faobj = "Creatinine increased"                 then ae_cd = "ae09";
  else if faobj = "Diarrhea"                             then ae_cd = "ae10";
  else if faobj = "Disseminated intravascular coagulation" then ae_cd = "ae11";
  else if faobj = "Febrile neutropenia"                  then ae_cd = "ae12";
  else if faobj = "Hepatic failure"                      then ae_cd = "ae13";
  else if faobj = "Hyperglycemia"                        then ae_cd = "ae14";
  else if faobj = "Ileus"                                then ae_cd = "ae15";
  else if faobj = "Intracranial hemorrhage"              then ae_cd = "ae16";
  else if faobj = "Lower gastrointestinal hemorrhage"    then ae_cd = "ae17";
  else if faobj = "Lung infection"                       then ae_cd = "ae18";
  else if faobj = "Mucositis oral"                       then ae_cd = "ae19";
  else if faobj = "Nausea"                               then ae_cd = "ae20";
  else if faobj = "Pancreatitis"                         then ae_cd = "ae21";
  else if faobj = "Peripheral motor neuropathy"          then ae_cd = "ae22";
  else if faobj = "Peripheral sensory neuropathy"        then ae_cd = "ae23";
  else if faobj = "Rash maculo-papular"                  then ae_cd = "ae24";
  else if faobj = "Sepsis"                               then ae_cd = "ae25";
  else if faobj = "Serum amylase increased"              then ae_cd = "ae26";
  else if faobj = "Thromboembolic event"                 then ae_cd = "ae27";
  else if faobj = "Tumor lysis syndrome"                 then ae_cd = "ae28";
  else if faobj = "Upper gastrointestinal hemorrhage"    then ae_cd = "ae29";
  else if faobj = "Urinary tract infection"              then ae_cd = "ae30";
  else if faobj = "Urticaria"                            then ae_cd = "ae31";
  else if faobj = "Uterine hemorrhage"                   then ae_cd = "ae32";
  else if faobj = "Vomiting"                             then ae_cd = "ae33";
  else delete;
run;

proc sort data=tmp12_fa; by usubjid ae_cd phase_cd; run;

proc transpose data=tmp12_fa out=tmp12_fa_t prefix=_g;
  by usubjid;
  id ae_cd phase_cd;
  var grade;
run;

data tmp12_ae(drop=_name_);
  set tmp12_fa_t;
  label
    _gae01i1="ALT増加 寛解導入1 Gr" _gae01i2="ALT増加 寛解導入2 Gr"
    _gae01c1="ALT増加 地固め1 Gr" _gae01c2="ALT増加 地固め2 Gr" _gae01c3="ALT増加 地固め3 Gr"
    _gae02i1="アレルギー反応 寛解導入1 Gr" _gae02i2="アレルギー反応 寛解導入2 Gr"
    _gae02c1="アレルギー反応 地固め1 Gr" _gae02c2="アレルギー反応 地固め2 Gr" _gae02c3="アレルギー反応 地固め3 Gr"
    _gae03i1="肛門周囲感染 寛解導入1 Gr" _gae03i2="肛門周囲感染 寛解導入2 Gr"
    _gae03c1="肛門周囲感染 地固め1 Gr" _gae03c2="肛門周囲感染 地固め2 Gr" _gae03c3="肛門周囲感染 地固め3 Gr"
    _gae04i1="AST増加 寛解導入1 Gr" _gae04i2="AST増加 寛解導入2 Gr"
    _gae04c1="AST増加 地固め1 Gr" _gae04c2="AST増加 地固め2 Gr" _gae04c3="AST増加 地固め3 Gr"
    _gae05i1="ビリルビン増加 寛解導入1 Gr" _gae05i2="ビリルビン増加 寛解導入2 Gr"
    _gae05c1="ビリルビン増加 地固め1 Gr" _gae05c2="ビリルビン増加 地固め2 Gr" _gae05c3="ビリルビン増加 地固め3 Gr"
    _gae06i1="気管支肺出血 寛解導入1 Gr" _gae06i2="気管支肺出血 寛解導入2 Gr"
    _gae06c1="気管支肺出血 地固め1 Gr" _gae06c2="気管支肺出血 地固め2 Gr" _gae06c3="気管支肺出血 地固め3 Gr"
    _gae07i1="心臓障害-その他 寛解導入1 Gr" _gae07i2="心臓障害-その他 寛解導入2 Gr"
    _gae07c1="心臓障害-その他 地固め1 Gr" _gae07c2="心臓障害-その他 地固め2 Gr" _gae07c3="心臓障害-その他 地固め3 Gr"
    _gae08i1="カテーテル関連感染 寛解導入1 Gr" _gae08i2="カテーテル関連感染 寛解導入2 Gr"
    _gae08c1="カテーテル関連感染 地固め1 Gr" _gae08c2="カテーテル関連感染 地固め2 Gr" _gae08c3="カテーテル関連感染 地固め3 Gr"
    _gae09i1="クレアチニン増加 寛解導入1 Gr" _gae09i2="クレアチニン増加 寛解導入2 Gr"
    _gae09c1="クレアチニン増加 地固め1 Gr" _gae09c2="クレアチニン増加 地固め2 Gr" _gae09c3="クレアチニン増加 地固め3 Gr"
    _gae10i1="下痢 寛解導入1 Gr" _gae10i2="下痢 寛解導入2 Gr"
    _gae10c1="下痢 地固め1 Gr" _gae10c2="下痢 地固め2 Gr" _gae10c3="下痢 地固め3 Gr"
    _gae11i1="DIC 寛解導入1 Gr" _gae11i2="DIC 寛解導入2 Gr"
    _gae11c1="DIC 地固め1 Gr" _gae11c2="DIC 地固め2 Gr" _gae11c3="DIC 地固め3 Gr"
    _gae12i1="発熱性好中球減少症 寛解導入1 Gr" _gae12i2="発熱性好中球減少症 寛解導入2 Gr"
    _gae12c1="発熱性好中球減少症 地固め1 Gr" _gae12c2="発熱性好中球減少症 地固め2 Gr" _gae12c3="発熱性好中球減少症 地固め3 Gr"
    _gae13i1="肝不全 寛解導入1 Gr" _gae13i2="肝不全 寛解導入2 Gr"
    _gae13c1="肝不全 地固め1 Gr" _gae13c2="肝不全 地固め2 Gr" _gae13c3="肝不全 地固め3 Gr"
    _gae14i1="高血糖 寛解導入1 Gr" _gae14i2="高血糖 寛解導入2 Gr"
    _gae14c1="高血糖 地固め1 Gr" _gae14c2="高血糖 地固め2 Gr" _gae14c3="高血糖 地固め3 Gr"
    _gae15i1="イレウス 寛解導入1 Gr" _gae15i2="イレウス 寛解導入2 Gr"
    _gae15c1="イレウス 地固め1 Gr" _gae15c2="イレウス 地固め2 Gr" _gae15c3="イレウス 地固め3 Gr"
    _gae16i1="頭蓋内出血 寛解導入1 Gr" _gae16i2="頭蓋内出血 寛解導入2 Gr"
    _gae16c1="頭蓋内出血 地固め1 Gr" _gae16c2="頭蓋内出血 地固め2 Gr" _gae16c3="頭蓋内出血 地固め3 Gr"
    _gae17i1="下部消化管出血 寛解導入1 Gr" _gae17i2="下部消化管出血 寛解導入2 Gr"
    _gae17c1="下部消化管出血 地固め1 Gr" _gae17c2="下部消化管出血 地固め2 Gr" _gae17c3="下部消化管出血 地固め3 Gr"
    _gae18i1="肺感染 寛解導入1 Gr" _gae18i2="肺感染 寛解導入2 Gr"
    _gae18c1="肺感染 地固め1 Gr" _gae18c2="肺感染 地固め2 Gr" _gae18c3="肺感染 地固め3 Gr"
    _gae19i1="口腔粘膜炎 寛解導入1 Gr" _gae19i2="口腔粘膜炎 寛解導入2 Gr"
    _gae19c1="口腔粘膜炎 地固め1 Gr" _gae19c2="口腔粘膜炎 地固め2 Gr" _gae19c3="口腔粘膜炎 地固め3 Gr"
    _gae20i1="悪心 寛解導入1 Gr" _gae20i2="悪心 寛解導入2 Gr"
    _gae20c1="悪心 地固め1 Gr" _gae20c2="悪心 地固め2 Gr" _gae20c3="悪心 地固め3 Gr"
    _gae21i1="膵炎 寛解導入1 Gr" _gae21i2="膵炎 寛解導入2 Gr"
    _gae21c1="膵炎 地固め1 Gr" _gae21c2="膵炎 地固め2 Gr" _gae21c3="膵炎 地固め3 Gr"
    _gae22i1="末梢運動神経障害 寛解導入1 Gr" _gae22i2="末梢運動神経障害 寛解導入2 Gr"
    _gae22c1="末梢運動神経障害 地固め1 Gr" _gae22c2="末梢運動神経障害 地固め2 Gr" _gae22c3="末梢運動神経障害 地固め3 Gr"
    _gae23i1="末梢感覚神経障害 寛解導入1 Gr" _gae23i2="末梢感覚神経障害 寛解導入2 Gr"
    _gae23c1="末梢感覚神経障害 地固め1 Gr" _gae23c2="末梢感覚神経障害 地固め2 Gr" _gae23c3="末梢感覚神経障害 地固め3 Gr"
    _gae24i1="皮疹（紅斑性丘疹） 寛解導入1 Gr" _gae24i2="皮疹（紅斑性丘疹） 寛解導入2 Gr"
    _gae24c1="皮疹（紅斑性丘疹） 地固め1 Gr" _gae24c2="皮疹（紅斑性丘疹） 地固め2 Gr" _gae24c3="皮疹（紅斑性丘疹） 地固め3 Gr"
    _gae25i1="敗血症 寛解導入1 Gr" _gae25i2="敗血症 寛解導入2 Gr"
    _gae25c1="敗血症 地固め1 Gr" _gae25c2="敗血症 地固め2 Gr" _gae25c3="敗血症 地固め3 Gr"
    _gae26i1="血清アミラーゼ増加 寛解導入1 Gr" _gae26i2="血清アミラーゼ増加 寛解導入2 Gr"
    _gae26c1="血清アミラーゼ増加 地固め1 Gr" _gae26c2="血清アミラーゼ増加 地固め2 Gr" _gae26c3="血清アミラーゼ増加 地固め3 Gr"
    _gae27i1="血栓塞栓症 寛解導入1 Gr" _gae27i2="血栓塞栓症 寛解導入2 Gr"
    _gae27c1="血栓塞栓症 地固め1 Gr" _gae27c2="血栓塞栓症 地固め2 Gr" _gae27c3="血栓塞栓症 地固め3 Gr"
    _gae28i1="腫瘍崩壊症候群 寛解導入1 Gr" _gae28i2="腫瘍崩壊症候群 寛解導入2 Gr"
    _gae28c1="腫瘍崩壊症候群 地固め1 Gr" _gae28c2="腫瘍崩壊症候群 地固め2 Gr" _gae28c3="腫瘍崩壊症候群 地固め3 Gr"
    _gae29i1="上部消化管出血 寛解導入1 Gr" _gae29i2="上部消化管出血 寛解導入2 Gr"
    _gae29c1="上部消化管出血 地固め1 Gr" _gae29c2="上部消化管出血 地固め2 Gr" _gae29c3="上部消化管出血 地固め3 Gr"
    _gae30i1="尿路感染 寛解導入1 Gr" _gae30i2="尿路感染 寛解導入2 Gr"
    _gae30c1="尿路感染 地固め1 Gr" _gae30c2="尿路感染 地固め2 Gr" _gae30c3="尿路感染 地固め3 Gr"
    _gae31i1="蕁麻疹 寛解導入1 Gr" _gae31i2="蕁麻疹 寛解導入2 Gr"
    _gae31c1="蕁麻疹 地固め1 Gr" _gae31c2="蕁麻疹 地固め2 Gr" _gae31c3="蕁麻疹 地固め3 Gr"
    _gae32i1="子宮出血 寛解導入1 Gr" _gae32i2="子宮出血 寛解導入2 Gr"
    _gae32c1="子宮出血 地固め1 Gr" _gae32c2="子宮出血 地固め2 Gr" _gae32c3="子宮出血 地固め3 Gr"
    _gae33i1="嘔吐 寛解導入1 Gr" _gae33i2="嘔吐 寛解導入2 Gr"
    _gae33c1="嘔吐 地固め1 Gr" _gae33c2="嘔吐 地固め2 Gr" _gae33c3="嘔吐 地固め3 Gr";
run;

/* 好中球減少期間（DURATION） */
data tmp12_neutdur;
  set FA;
  where fatest = "Duration" and faobj = "Neutrophil count decreased";
  length neut_dur_n 8. phase_cd $3.;
  neut_dur_n = input(faorres, best.);
  if      faspid = "induction1ae"     then phase_cd = "i1";
  else if faspid = "induction2ae"     then phase_cd = "i2";
  else if faspid = "consolidation1ae" then phase_cd = "c1";
  else if faspid = "consolidation2ae" then phase_cd = "c2";
  else if faspid = "consolidation3ae" then phase_cd = "c3";
  else delete;
run;

proc sort data=tmp12_neutdur; by usubjid phase_cd; run;

proc transpose data=tmp12_neutdur out=tmp12_neutdur_t prefix=neutdur_;
  by usubjid;
  id phase_cd;
  var neut_dur_n;
run;

data tmp12_neutdur_f(drop=_name_);
  set tmp12_neutdur_t;
  rename neutdur_i1=neutdur_i1 neutdur_i2=neutdur_i2
         neutdur_c1=neutdur_c1 neutdur_c2=neutdur_c2 neutdur_c3=neutdur_c3;
  label
    neutdur_i1 = "好中球減少期間 寛解導入1（日）"
    neutdur_i2 = "好中球減少期間 寛解導入2（日）"
    neutdur_c1 = "好中球減少期間 地固め1（日）"
    neutdur_c2 = "好持球減少期間 地固め2（日）"
    neutdur_c3 = "好中球減少期間 地固め3（日）";
run;

/* 深在性真菌感染（DPFUNINF）*/
data tmp12_dpf;
  set FA;
  where fatestcd = "DPFUNINF" and facat = "PRE-SPECIFIED AE";
  length dpf_cd $3.;
  if      faspid = "induction1ae"     then dpf_cd = "i1";
  else if faspid = "induction2ae"     then dpf_cd = "i2";
  else if faspid = "consolidation1ae" then dpf_cd = "c1";
  else if faspid = "consolidation2ae" then dpf_cd = "c2";
  else if faspid = "consolidation3ae" then dpf_cd = "c3";
  else delete;
run;

proc sort data=tmp12_dpf; by usubjid dpf_cd; run;

proc transpose data=tmp12_dpf out=tmp12_dpf_t prefix=dpfinf_;
  by usubjid;
  id dpf_cd;
  var faorres;
run;

data tmp12_dpfinf(drop=_name_);
  set tmp12_dpf_t;
  label
    dpfinf_i1 = "深在性真菌感染 寛解導入1（YES/NO）"
    dpfinf_i2 = "深在性真菌感染 寛解導入2（YES/NO）"
    dpfinf_c1 = "深在性真菌感染 地固め1（YES/NO）"
    dpfinf_c2 = "深在性真菌感染 地固め2（YES/NO）"
    dpfinf_c3 = "深在性真菌感染 地固め3（YES/NO）";
run;

proc sort data=tmp12_ae;      by usubjid; run;
proc sort data=tmp12_neutdur_f; by usubjid; run;
proc sort data=tmp12_dpfinf;  by usubjid; run;

data tmp12_aefull;
  merge tmp12_ae tmp12_neutdur_f tmp12_dpfinf;
  by usubjid;
run;


/***===================================================================================***/
/*** 13. WT-1 mRNA 時系列（LB ドメイン、各評価時点）                                  ***/
/***===================================================================================***/

data tmp13_wt1;
  set LB;
  where lbtestcd = "WT1MRNA";
  length wt1_n 8.;
  wt1_n = input(lborres, best.);
run;

proc sort data=tmp13_wt1; by usubjid lbspid; run;

proc transpose data=tmp13_wt1 out=tmp13_wt1_t prefix=wt1_;
  by usubjid;
  id lbspid;
  var wt1_n;
run;

data tmp13_wt1f(drop=_name_);
  set tmp13_wt1_t;
  rename
    wt1_baseline2   = wt1_bl
    wt1_evaluation1 = wt1_ev1
    wt1_evaluation2 = wt1_ev2
    wt1_evaluation3 = wt1_ev3
    wt1_evaluation4 = wt1_ev4
    wt1_evaluation5 = wt1_ev5
    wt1_relapse     = wt1_relapse;
  label
    wt1_baseline2   = "WT-1 mRNA Baseline（コピー/μgRNA）"
    wt1_evaluation1 = "WT-1 mRNA 評価1（寛解導入1後）"
    wt1_evaluation2 = "WT-1 mRNA 評価2（寛解導入2後）"
    wt1_evaluation3 = "WT-1 mRNA 評価3（地固め1後）"
    wt1_evaluation4 = "WT-1 mRNA 評価4（地固め2後）"
    wt1_evaluation5 = "WT-1 mRNA 評価5（地固め3後）"
    wt1_relapse     = "WT-1 mRNA 再発時";
run;

proc sort data=tmp13_wt1f; by usubjid; run;


/***===================================================================================***/
/*** 14. SAE 情報（AE ドメイン）                                                       ***/
/***===================================================================================***/

data tmp14_sae(keep=usubjid anysae);
  set AE;
  length anysae $3.;
  if AESER = "Y" then anysae = "Y";
  label anysae = "重篤有害事象あり（Y）";
run;

/* 1症例1行に集約（Y/Nどちらか） */
proc sort data=tmp14_sae; by usubjid descending anysae; run;

data tmp14_sae;
  set tmp14_sae;
  by usubjid;
  if first.usubjid;
run;


/***===================================================================================***/
/*** 15. すべての一時データセットをマージして中間データセット（tmpall）を作成           ***/
/***===================================================================================***/

/* 全 tmpXX データセットをソート */
%macro sortt(ds);
  proc sort data=&ds; by usubjid; run;
%mend;
%sortt(tmp1);
%sortt(tmp2a_who); %sortt(tmp2b_fab); %sortt(tmp2c_gen); %sortt(tmp2d_cci);
%sortt(tmp3_labs); %sortt(tmp4_eln);
%sortt(tmp5a_vs); %sortt(tmp5b_ecog); %sortt(tmp5c_echo); %sortt(tmp5d_ecg);
%sortt(tmp6_cga_final);
%sortt(tmp7_ext);
%sortt(tmp8_rsfull); %sortt(tmp8_cr);
%sortt(tmp9_relapse);
%sortt(tmp10a_disc); %sortt(tmp10b_with); %sortt(tmp10c_dd);
%sortt(tmp11_tx);
%sortt(tmp12_aefull);
%sortt(tmp13_wt1f);
%sortt(tmp14_sae);

data tmpall;
  merge tmp1
        tmp2a_who tmp2b_fab tmp2c_gen tmp2d_cci
        tmp3_labs tmp4_eln
        tmp5a_vs tmp5b_ecog tmp5c_echo tmp5d_ecg
        tmp6_cga_final
        tmp7_ext
        tmp8_rsfull tmp8_cr
        tmp9_relapse
        tmp10a_disc tmp10b_with tmp10c_dd
        tmp11_tx
        tmp12_aefull
        tmp13_wt1f
        tmp14_sae;
  by usubjid;
run;


/***===================================================================================***/
/*** 16. イベント判定：EFS, OS, RFS                                                   ***/
/***===================================================================================***/

/* EFS（無イベント生存期間：登録日起算）
     イベント：再発(CE) OR 治療不応（DSdiscont: LACK OF EFFICACY/FAILURE TO MEET CONTINUATION CRITERIA）
               OR 死亡（DSwithdrawal: DEATH）
     打ち切り：カットオフ日 */
data tmp_efs(keep=usubjid efs_c efsdt);
  set tmpall;

  length edt_relapse edt_fail edt_death 8.;
  edt_relapse = .; edt_fail = .; edt_death = .;

  /* 再発日 */
  if relapse = "Y" then edt_relapse = reldt;

  /* 治療不応日（DS discontinuation） */
  if dsterm in ("LACK OF EFFICACY","FAILURE TO MEET CONTINUATION CRITERIA")
    then edt_fail = dsstdt;

  /* 死亡日（DS withdrawal） */
  if UPCASE(strip(dsterm2)) = "DEATH" then edt_death = dsstdt2;

  /* 最も早いイベント日 */
  edt_earliest = min(edt_relapse, edt_fail, edt_death);

  if edt_earliest = . then do;
    efs_c = 0;
    efsdt = &cutdt.;
  end;
  else do;
    efs_c = 1;
    efsdt = edt_earliest;
  end;

  format efsdt yymmdd10.;
  label efs_c = "EFSイベント（1=event, 0=打ち切り）"
        efsdt = "EFS評価確認日";
run;

/* OS（全生存期間：登録日起算）
     イベント：死亡（DSwithdrawal: DEATH）
     打ち切り：カットオフ日 */
data tmp_os(keep=usubjid os_c osdt);
  set tmpall;

  if UPCASE(strip(dsterm2)) = "DEATH" then do;
    os_c = 1;
    osdt = dsstdt2;
  end;
  else do;
    os_c = 0;
    osdt = &cutdt.;
  end;

  format osdt yymmdd10.;
  label os_c = "OSイベント（1=event, 0=打ち切り）"
        osdt = "OS評価確認日";
run;

/* RFS（無再発生存期間：初回CR日起算、CR例のみ）
     イベント：再発(CE) OR 死亡（DSwithdrawal: DEATH）
     打ち切り：カットオフ日 */
data tmp_rfs(keep=usubjid rfs_c rfsdt);
  set tmpall;

  /* CR到達例のみ対象 */
  if crfl ne "Y" then delete;

  length edt_rel_rfs edt_death_rfs 8.;
  edt_rel_rfs = .; edt_death_rfs = .;

  if relapse = "Y" then edt_rel_rfs = reldt;
  if UPCASE(strip(dsterm2)) = "DEATH" then edt_death_rfs = dsstdt2;

  edt_rfs_earliest = min(edt_rel_rfs, edt_death_rfs);

  if edt_rfs_earliest = . then do;
    rfs_c = 0;
    rfsdt = &cutdt.;
  end;
  else do;
    rfs_c = 1;
    rfsdt = edt_rfs_earliest;
  end;

  format rfsdt yymmdd10.;
  label rfs_c = "RFSイベント（1=event, 0=打ち切り）"
        rfsdt = "RFS評価確認日";
run;

proc sort data=tmp_efs; by usubjid; run;
proc sort data=tmp_os;  by usubjid; run;
proc sort data=tmp_rfs; by usubjid; run;


/***===================================================================================***/
/*** 17. 最終データセット作成：生存時間計算と派生変数の追加                           ***/
/***===================================================================================***/

data tmpall2;
  merge tmpall tmp_efs tmp_os tmp_rfs;
  by usubjid;
run;

data gml219;
  set tmpall2;

  /* コース実施有無 */
  length ind1fl ind2fl c1fl c2fl c3fl $3.;
  if ind1stdt ne . then ind1fl = "Y"; else ind1fl = "N";
  if ind2stdt ne . then ind2fl = "Y"; else ind2fl = "N";
  if c1stdt   ne . then c1fl   = "Y"; else c1fl   = "N";
  if c2stdt   ne . then c2fl   = "Y"; else c2fl   = "N";
  if c3stdt   ne . then c3fl   = "Y"; else c3fl   = "N";

  /* CR未到達フラグ補完 */
  if crfl = "" then crfl = "N";

  /* EFS 生存時間（日・月・年） */
  efs_d = efsdt  - rfstdt + 1;
  efs_m = efs_d / (365.25/12);
  efs_y = efs_d / 365.25;

  /* OS 生存時間 */
  os_d  = osdt   - rfstdt + 1;
  os_m  = os_d  / (365.25/12);
  os_y  = os_d  / 365.25;

  /* RFS 生存時間（CR例のみ、crdt から） */
  if crfl = "Y" and crdt ne . then do;
    rfs_d = rfsdt - crdt + 1;
    rfs_m = rfs_d / (365.25/12);
    rfs_y = rfs_d / 365.25;
  end;

  /* 年齢カテゴリ（65-69歳 vs 70-74歳） */
  length agegrp $20.;
  if      65 <= age <= 69 then agegrp = "65-69";
  else if 70 <= age <= 74 then agegrp = "70-74";
  else agegrp = "";

  /* FAB/WHO 分類グループ（SAP 4.4.3：M0/M6/M7 vs Others） */
  /* SAP では WHO分類に基づく大分類（t-MN, AML-MRC vs Others）も使用 */
  length fabgrp $20. whogrp $30.;
  if fabclass in ("M0","M6","M7","Unknown") then fabgrp = "M0/M6/M7/Unknown";
  else if fabclass ne "" then fabgrp = "Others";
  else fabgrp = "";

  if dxwhocd = "10400" then whogrp = "t-MN";         /* therapy-related */
  else if dxwhocd = "10390" then whogrp = "AML-MRC";  /* myelodysplasia-related */
  else if dxwhocd ne "" then whogrp = "Others";
  else whogrp = "";

  /* 分子病型（Fig9 サブグループ） */
  length molgrp $20.;
  if flt3itd = "POSITIVE" then molgrp = "FLT3-ITD";
  else if npm1 = "POSITIVE" then molgrp = "NPM1";
  else molgrp = "Other";

  label
    ind1fl = "寛解導入1実施（Y/N）"
    ind2fl = "寛解導入2実施（Y/N）"
    c1fl   = "地固め1実施（Y/N）"
    c2fl   = "地固め2実施（Y/N）"
    c3fl   = "地固め3実施（Y/N）"
    efs_d  = "EFS期間（日）"
    efs_m  = "EFS期間（月）"
    efs_y  = "EFS期間（年）"
    os_d   = "OS期間（日）"
    os_m   = "OS期間（月）"
    os_y   = "OS期間（年）"
    rfs_d  = "RFS期間（日）"
    rfs_m  = "RFS期間（月）"
    rfs_y  = "RFS期間（年）"
    agegrp = "年齢グループ（65-69/70-74）"
    fabgrp = "FABグループ（M0/M6/M7 vs Others）"
    whogrp = "WHOグループ（t-MN/AML-MRC vs Others）"
    molgrp = "分子病型グループ（FLT3-ITD/NPM1/Other）";
run;


/***===================================================================================***/
/*** 18. データセットのエクスポート                                                   ***/
/***===================================================================================***/

/* SAS データセット（adslib） */
proc copy in=work out=adslib;
  select gml219;
run;

/* Excel ファイル */
proc export
  data=work.gml219
  outfile= "&_root./input/ads/202512 data/gml219_new.xlsx"
  dbms=xlsx
  replace;
run;

libname adslib clear;

/*====================================================================================*/
/* ログリセット                                                                       */
/*====================================================================================*/
proc printto;
run;
