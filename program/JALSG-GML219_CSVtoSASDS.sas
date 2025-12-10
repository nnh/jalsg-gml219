/**************************************************************************************************
programmer   :AKIKO SAITO
file name       :JPLSG-GML219_sasds.sas
date created  :2025/12/04
data modified  :2025/12/09
description     :SDTMからSASデータセットを作成
comment        ★が付いている箇所は後日データ修正が入った場合に確認必要
**************************************************************************************************/

*出力結果のタイトルとフッターをクリア。以前に設定されたタイトルやフッターが新しい出力に表示されないように設定;
title ;
footnote ;

*WORKライブラリ内のすべてのデータセット、カタログ、ビューなどを削除;
proc datasets library=work kill nolist ;
quit ;

*display managerコマンドの実行。出力ウィンドウ、ログウィンドウの内容をクリア;
dm 'output; clear; log; clear;';

*SASシステムオプションの設定;
/*nonumber: 出力にページ番号を付けない。*/
/*notes: ログにNOTE（注釈）を表示する。*/
/*nomprint: 実行されたマクロのSASステートメントをログに出力しない。*/
/*ls=100: 行サイズ（1行の文字数）を100に設定する。*/
/*ps=9999: ページサイズ（1ページの行数）を9999に設定する。*/
/*formdlim="-": ODS LISTINGで生成されるテキスト出力の区切り文字をハイフンに設定する。*/
/*center: 出力を中央揃えにする。*/
options nonumber notes nomprint ls=100 ps=9999 formdlim="-" center ;

*Output Delivery System (ODS)設定;
/*ODSの出力先として、従来のテキストベースのLISTING（出力ウィンドウ）を有効にする。*/
ods listing;

/* *マクロ　FIND_WDの設定において、現在実行しているSASプログラムが置かれているディレクトリの総体パスを指定; */
%macro FIND_WD;
  %local _fullpath _path;
  %let _fullpath = %sysfunc(getoption(sysin));
  %if %length(&_fullpath) = 0 %then %let _fullpath = %sysget(sas_execfilepath);
  %if %length(&_fullpath) = 0 %then %let _fullpath = %superq(_SASPROGRAMFILE);
  %let _path = %sysfunc(prxchange(s/(\\[^\\]+){2}$//, -1, &_fullpath));
  &_path.
%mend FIND_WD;


%let cwd=%FIND_WD;
%put &cwd;




%macro sasds(folder,dsnm);
proc import out= &dsnm
  datafile= "&cwd.\input\&folder.\&dsnm..csv" dbms=csv replace ;
  getnames=yes ; *CSVファイルの1行目を、列名（SASデータセットの変数名）として使用する;
  datarow=2 ; *実際のデータが2行目から始まるか指定;
  guessingrows=max ; *列のデータ型（数値か文字か）や文字長を判断する際、ファイル全体をスキャンして最適型と長さを決定;
run ;
%mend;

%sasds(rawdata,AE);
%sasds(rawdata,CE);
%sasds(rawdata,CM);
%sasds(rawdata,CO);
%sasds(rawdata,DD);
%sasds(rawdata,DM);
%sasds(rawdata,DS);
%sasds(rawdata,EC);
%sasds(rawdata,EG);
%sasds(rawdata,FA);
%sasds(rawdata,LB);
%sasds(rawdata,MB);
%sasds(rawdata,MH);
%sasds(rawdata,PE);
%sasds(rawdata,PR);
%sasds(rawdata,QS);
%sasds(rawdata,RELREC);
%sasds(rawdata,RS);
%sasds(rawdata,SC);
%sasds(rawdata,VS);
%sasds(ext,facilities);
%sasds(ext,saihi);
%sasds(ext,diseases);

data tmp1a(keep=usubjid subjid rficdt brthdt sex race age rfstdt siteid);
  set DM;
  length 
      rfstdt rficdt brthdt age 8.;
  rfstdt=input(rfstdtc,yymmdd10.);
  rficdt=input(rficdtc,yymmdd10.);
  brthdt=input(brthdtc,yymmdd10.);
  age   =int(yrdif(brthdt, rficdt, 'AGE'));
  format rfstdt rficdt brthdt yymmdd10.;
  label rficdt="同意取得日" 
        brthdt="生年月日" 
        sex="性別"
        race="人種"
        rfstdt="症例登録日"
        age="同意取得時年齢"
        siteid="医療機関コード";
run;

data tmp1b(keep=siteid sitenm);
  set facilities;
  length siteid $11. sitenm $100.;
  siteid=var1;
  sitenm=var2;
  label sitenm="医療機関名";
run;

proc sort data=tmp1a;
  by siteid;
run;
proc sort data=tmp1b;
  by siteid;
run;
data tmp1c;
  merge tmp1a(in=a) tmp1b;
  by siteid;
  if a;
run;

data tmp1d(keep=usubjid fasfl saffl ppsfl);
  length usubjid $14.;
  set saihi;
  label fasfl="FAS解析採用"
        saffl="安全性解析対象集団採用"
        ppsfl="PPS解析採用";
run;

proc sort data=tmp1c;
  by usubjid;
run;
proc sort data=tmp1d;
  by usubjid;
run;

*★;
data tmp1;
  merge tmp1c tmp1d;
  by usubjid;
run;

*MHの疾患名が一部コードになっている箇所を修正する;
proc freq data=MH;
tables mhterm;
where MHSPID="baseline1" and MHCAT="PRIMARY DIAGNOSIS";
run;

proc print data=diseases;
	var code name_en;
	where code in (10010
10300
10310
10350
10370
10390
10400
10420
10430
10440
10450
10460
11670);
run;

data MH_converted;
  set MH;
  length mhterm_dname $120.;

   if MHTERM = '10010' then mhterm_dname= 'Chronic myeloid leukemia (CML), BCR-ABL1(+)';
   else if MHTERM = '10300' then mhterm_dname= 'AML with t(8;21)(q22;q22.1);RUNX1-RUNX1T1';
   else if MHTERM = '10310' then mhterm_dname= 'AML with inv(16)(p13.1q22) or t(16;16)(p13.1;q22);CBFB-MYH11'; 
   else if MHTERM = '10350' then mhterm_dname= 'AML with inv(3)(q21.3q26.2) or t(3;3)(q21.3;q26.2); GATA2, MECOM'; 
   else if MHTERM = '10370' then mhterm_dname= 'AML with mutated NPM1'; 
   else if MHTERM = '10390' then mhterm_dname= 'AML with myelodysplasia-related changes'; 
   else if MHTERM = '10400' then mhterm_dname= 'Therapy-related myeloid neoplasms';
   else if MHTERM = '10420' then mhterm_dname= 'AML with minimal differentiation';
   else if MHTERM = '10430' then mhterm_dname= 'AML without maturation';
   else if MHTERM = '10440' then mhterm_dname= 'AML with maturation';
   else if MHTERM = '10450' then mhterm_dname= 'Acute myelomonocytic leukemia';
   else if MHTERM = '10460' then mhterm_dname= 'Acute monoblastic/monocytic leukemia'; 
   else if MHTERM = '11670' then mhterm_dname= 'AML with BCR-ABL1';
   else  mhterm_dname = mhterm; 
run;

/*診断日データを取っていないため、dxdt使わない　data tmp1e_dx(keep=usubjid dxmhterm dxdt);*/
data tmp1e_dx(keep=usubjid dxmhterm);
  set MH_converted;
  length dxmhterm $120.;

  where mhcat="PRIMARY DIAGNOSIS" and mhoccur="Y";
  dxmhterm=mhterm_dname;
/*  dxdt=input(mhstdtc,yymmdd10.);*/
  format dxdt yymmdd10.;
  label dxmhterm="初発診断名";
run;

/*proc freq data=tmp1e_dx;*/
/*tables dxmhterm;run;*/

*★;
/*data tmp1e_dx2(keep=usubjid dxmhterm dxdt dxmhtermc);*/
data tmp1e_dx2(keep=usubjid dxmhterm dxmhtermc);
  set tmp1e_dx;
  retain dxmhtermc;
  length dxmhtermc $120.;

  if dxmhterm in ('Therapy-related myeloid neoplasms' 'AML with myelodysplasia-related changes') then dxmhtermc='TRMS_AMLMRC';
  else dxmhtermc='others';
  label dxmhtermc="WHOカテゴリ";
run;

data tmp1e_fab(keep=usubjid dxmhtermfab);
  set MH_converted;
  length dxmhtermfab $120.;
  where mhcat="FAB CRITERIA" and mhoccur="Y";
  dxmhtermfab=mhterm_dname;
  label dxmhtermfab="FAB分類";
run;

*★;
data tmp1e_fabc(keep=usubjid dxmhtermfab dxmhtermfabc);
 set tmp1e_fab;
 retain dxmhtermfabc;
 length dxmhtermfabc $120.;
  if dxmhtermfab in ('M0' 'M6' 'M7') then dxmhtermfabc='M0_M6_M7';
  else dxmhtermfabc='others';
  label dxmhtermfabc="FAB分類カテゴリ";
run;

/*proc freq data=mh_converted;
 tables mhterm_dname*mhspid/ nocol nopercent norow;
  where mhcat="CHARLSON COMORBIDITIES" and mhoccur="Y";
run;
proc print data=mh_converted; var usubjid mhcat mhterm mhspid mhterm_dname;
where mhterm_dname in ('Solid cancer metastasis' 'Metastatic solid tumor');
run; 

※同じCCIの要素なのに、MHTERMが異なっているため、CCIの論理式が書きにくい。
proc print data=mh_converted; var usubjid mhcat mhterm mhspid mhterm_dname;
where mhterm_dname in ('Solid cancer metastasis' 'Metastatic solid tumor') and mhspid= "consoli1_cci";
run; 
proc print data=mh_converted; var usubjid mhcat mhterm mhspid mhterm_dname;
where mhterm_dname in ('Solid cancer metastasis' 'Metastatic solid tumor') and mhspid= "baseline_cci";
run;
*/ 

proc sort data=MH_converted out=mh_sorted;
    by usubjid;
run;

data tmp1e_blccic(keep=usubjid blcci_aids blcci_cvs blcci_cld blcci_cd blcci_chf blcci_d blcci_dc blcci_l blcci_lt blcci_scm blcci_mld blcci_mi blcci_pvd);
    set mh_sorted; /* ステップ1でソートされたデータセットを使用 */
    
    /* 1. BYステートメントでusubjidのグループ化を指示 */
    by usubjid;
    
    /* 2. スコアリング変数を保持し、かつ0で初期化 */
    retain blcci_aids blcci_cvs blcci_cld blcci_cd blcci_chf blcci_d blcci_dc blcci_l blcci_lt blcci_scm blcci_mld blcci_mi blcci_pvd 0;
    
    /* 3. 新しいUSUBJIDグループの開始時に、スコア変数を全て0にリセット */
    if first.usubjid then do;
        blcci_aids = 0; blcci_cvs = 0; blcci_cld = 0; blcci_cd = 0; blcci_chf = 0; 
        blcci_d = 0; blcci_dc = 0; blcci_l = 0; blcci_lt = 0; blcci_scm = 0; 
        blcci_mld = 0; blcci_mi = 0; blcci_pvd = 0;
    end;
    
    /* フィルタリング */
    where mhcat="CHARLSON COMORBIDITIES" and mhoccur="Y" and mhspid="baseline_cci";
    
    /* スコアリング処理: 条件に合致する場合、0を上書きしてスコアを代入 */
    if mhterm="Acquired immunodeficiency syndrome" then blcci_AIDS=6;
    else if mhterm="Cerebral vascular disease" then blcci_CVS=1;
    else if mhterm="Chronic lung disease" then blcci_CLD=1;
    else if mhterm="Collagen disease" then blcci_CD=1;
    else if mhterm="Congestive heart failure" then blcci_CHF=1;
    else if mhterm="Dementia" then blcci_D=1;
    else if mhterm="Diabetic complication" then blcci_DC=2;
    else if mhterm="Leukemia" then blcci_L=2;
    else if mhterm="Lymphoid tumor" then blcci_LT=2;
    else if mhterm="Metastatic solid tumor" then blcci_SCM=6;
    else if mhterm="Mild liver disease" then blcci_MLD=1;
    else if mhterm="Myocardial infarction" then blcci_MI=1;
    else if mhterm="Peripheral vascular disease" then blcci_PVD=1;

    /* 4. usubjidグループの最後のレコードに到達した時のみ行を出力 */
    if last.usubjid then output;
    
    label blcci_AIDS="blcci_Acquired immunodeficiency syndrome"
          blcci_CVS="blcci_Cerebral vascular disease"
          blcci_CLD="blcci_Chronic lung disease"
          blcci_CD="blcci_Collagen disease"
          blcci_CHF="blcci_Congestive heart failure"
          blcci_D="blcci_Dementia"
          blcci_DC="blcci_Diabetic complication"
          blcci_L="blcci_Leukemia"
          blcci_LT="blcci_Lymphoid tumor"
          blcci_SCM="blcci_Metastatic solid tumor"
          blcci_MLD="blcci_Mild liver disease"
          blcci_MI="blcci_Myocardial infarction"
          blcci_PVD="blcci_Peripheral vascular disease";
run;

data tmp1e_blccit(keep=usubjid blcci);
 set tmp1e_blccic;
 blcci=blcci_aids+blcci_cvs+blcci_cld+blcci_cd+blcci_chf+blcci_d+blcci_dc+blcci_l+blcci_lt+blcci_scm+blcci_mld+blcci_mi+blcci_pvd;
 label blcci="baseline CCI";
run;

proc sort data=tmp1e_blccic;
  by usubjid;
run;
proc sort data=tmp1e_blccit;
  by usubjid;
run;
data tmp1e_blcci;
  merge tmp1e_blccic tmp1e_blccit;
  by usubjid;
run;

data tmp1e_consccic(keep=usubjid conscci_aids conscci_cvs conscci_cld conscci_cd conscci_chf conscci_d conscci_dc conscci_l conscci_lt conscci_scm conscci_mld conscci_mi conscci_pvd);
    set mh_sorted; /* ステップ1でソートされたデータセットを使用 */
    
    /* 1. BYステートメントでusubjidのグループ化を指示 */
    by usubjid;
    
    /* 2. スコアリング変数を保持し、かつ0で初期化 */
    retain  conscci_aids conscci_cvs conscci_cld conscci_cd conscci_chf conscci_d conscci_dc conscci_l conscci_lt conscci_scm conscci_mld conscci_mi conscci_pvd 0;
    
    /* 3. 新しいUSUBJIDグループの開始時に、スコア変数を全て0にリセット */
    if first.usubjid then do;
        conscci_aids = 0; conscci_cvs = 0; conscci_cld = 0; conscci_cd = 0; conscci_chf = 0; 
        conscci_d = 0; conscci_dc = 0; conscci_l = 0; conscci_lt = 0; conscci_scm = 0; 
        conscci_mld = 0; conscci_mi = 0; conscci_pvd = 0;
    end;
    
    /* フィルタリング */
    where mhcat="CHARLSON COMORBIDITIES" and mhoccur="Y" and mhspid="consoli1_cci";
    
    /* スコアリング処理: 条件に合致する場合、0を上書きしてスコアを代入 */
    if mhterm="Acquired immunodeficiency syndrome" then conscci_AIDS=6;
    else if mhterm="Cerebral vascular disease" then conscci_CVS=1;
    else if mhterm="Chronic lung disease" then conscci_CLD=1;
    else if mhterm="Collagen disease" then conscci_CD=1;
    else if mhterm="Congestive heart failure" then conscci_CHF=1;
    else if mhterm="Dementia" then conscci_D=1;
    else if mhterm="Diabetic complication" then conscci_DC=2;
    else if mhterm="Leukemia" then conscci_L=2;
    else if mhterm="Lymphoid tumor" then conscci_LT=2;
    else if mhterm="Solid cancer metastasis" then conscci_SCM=6;
    else if mhterm="Mild liver disease" then conscci_MLD=1;
    else if mhterm="Myocardial infarction" then conscci_MI=1;
    else if mhterm="Peripheral vascular disease" then conscci_PVD=1;

    /* 4. usubjidグループの最後のレコードに到達した時のみ行を出力 */
    if last.usubjid then output;
    
    label conscci_AIDS="conscci_Acquired immunodeficiency syndrome"
          conscci_CVS="conscci_Cerebral vascular disease"
          conscci_CLD="conscci_Chronic lung disease"
          conscci_CD="conscci_Collagen disease"
          conscci_CHF="conscci_Congestive heart failure"
          conscci_D="conscci_Dementia"
          conscci_DC="conscci_Diabetic complication"
          conscci_L="conscci_Leukemia"
          conscci_LT="conscci_Lymphoid tumor"
          conscci_SCM="conscci_Metastatic solid tumor"
          conscci_MLD="conscci_Mild liver disease"
          conscci_MI="conscci_Myocardial infarction"
          conscci_PVD="conscci_Peripheral vascular disease";
run;

data tmp1e_consccit(keep=usubjid conscci);
 set tmp1e_consccic;
 conscci=conscci_aids+conscci_cvs+conscci_cld+conscci_cd+conscci_chf+conscci_d+conscci_dc+conscci_l+conscci_lt+conscci_scm+conscci_mld+conscci_mi+conscci_pvd;
 label conscci="consolidation CCI";
run;

proc sort data=tmp1e_consccic;
  by usubjid;
run;
proc sort data=tmp1e_consccit;
  by usubjid;
run;
data tmp1e_conscci;
  merge tmp1e_consccic tmp1e_consccit;
  by usubjid;
run;

proc sort data=tmp1e_blcci;
  by usubjid;
run;
proc sort data=tmp1e_conscci;
  by usubjid;
run;

*★;
data tmp1e_cci;
  merge tmp1e_blcci tmp1e_conscci;
  by usubjid;
run;


data tmp1e_mhp(keep=usubjid medhis_pba);
 set mh;
    length medhis_pba $120.;
    where mhcat="GENERAL" and mhoccur="Y" and mhspid="baseline1";
    if mhterm='Presence or absence of prior blood abnormalities' then medhis_pba='Y';   
    label medhis_pba="先行血液異常の有無";
run;

data tmp1e_mhs(keep=usubjid medhis_sTRAML);
 set mh;
    length  medhis_sTRAML $120.;
    where mhcat="GENERAL" and mhoccur="Y" and mhspid="baseline1";
    if mhterm='Have a history of suspected treatment-related AML' then medhis_sTRAML='Y';   
    label medhis_sTRAML="治療関連AMLを疑う既往";
run;

data tmp1e_mhi(keep=usubjid medhis_infec);
 set mh;
    length  medhis_infec $120.;
    where mhcat="GENERAL" and mhoccur="Y" and mhspid="baseline1";
    if mhterm='Whether there is an infection that was treated with a drip within 8 weeks' then medhis_infec='Y';   
    label medhis_infec="8週以内に点滴治療を行った感染症の有無";
run;

proc sort data=tmp1e_mhp; by usubjid; run;
proc sort data=tmp1e_mhs; by usubjid; run;
proc sort data=tmp1e_mhi; by usubjid; run;
*★;
data tmp1e_mh;
 merge tmp1e_mhp tmp1e_mhs tmp1e_mhi;
 by usubjid;
run;

proc sort data=lb;
    by usubjid;
run;
 
data tmp1e_bm(keep=usubjid i1_bblast i1_bblastyn i1_bblastdt i2_bblast i2_bblastyn i2_bblastdt c1_bblast c1_bblastyn c1_bblastdt
                       c2_bblast c2_bblastyn c2_bblastdt c3_bblast c3_bblastyn c3_bblastdt rl_bblast rl_bblastyn rl_bblastdt);
length  i1_bblastyn i2_bblastyn c1_bblastyn c2_bblastyn c3_bblastyn rl_bblastyn  $20.;
set lb;
    by usubjid;

    retain i1_bblast i1_bblastyn i1_bblastdt i2_bblast i2_bblastyn i2_bblastdt c1_bblast c1_bblastyn c1_bblastdt
                       c2_bblast c2_bblastyn c2_bblastdt c3_bblast c3_bblastyn c3_bblastdt rl_bblast rl_bblastyn rl_bblastdt;

    if first.usubjid then call missing(of i1_bblast i1_bblastyn i1_bblastdt i2_bblast i2_bblastyn i2_bblastdt c1_bblast c1_bblastyn c1_bblastdt
                       c2_bblast c2_bblastyn c2_bblastdt c3_bblast c3_bblastyn c3_bblastdt rl_bblast rl_bblastyn rl_bblastdt);

    where LBTESTCD = "MYBLALE";
    if LBSPID = "evaluation1" and LBLNKGRP="INDUC1E" then do;
        i1_bblastyn=lbstat;
        i1_bblast=lborres;
        i1_bblastdt=input(lbdtc,yymmdd10.);
    end;
    else if LBSPID = "evaluation2" and LBLNKGRP="INDUC2E" then do;
        i2_bblastyn=lbstat;
        i2_bblast=lborres;
        i2_bblastdt=input(lbdtc,yymmdd10.);
    end;
    else if LBSPID = "evaluation3" and LBLNKGRP="CONS1E" then do;
        c1_bblastyn=lbstat;
        c1_bblast=lborres;
        c1_bblastdt=input(lbdtc,yymmdd10.);
    end;
    else if LBSPID = "evaluation4" and LBLNKGRP="CONS2E" then do;
        c2_bblastyn=lbstat;
        c2_bblast=lborres;
        c2_bblastdt=input(lbdtc,yymmdd10.);
    end;
    else if LBSPID = "evaluation5" and LBLNKGRP="CONS3E" then do;
        c3_bblastyn=lbstat;
        c3_bblast=lborres;
        c3_bblastdt=input(lbdtc,yymmdd10.);
    end;
    else if LBSPID = "relapse" and LBLNKGRP="RELAPSE" then do;
        rl_bblastyn=lbstat;
        rl_bblast=lborres;
        rl_bblastdt=input(lbdtc,yymmdd10.);
    end;
 
    if last.usubjid;

    format i1_bblastdt i2_bblastdt c1_bblastdt c2_bblastdt c3_bblastdt rl_bblastdt yymmdd10.;

    label i1_bblastyn="寛解導入1後 骨髄検査有無";
    label i1_bblastdt="寛解導入1後 骨髄検査日";
    label i1_bblast="寛解導入1後 骨髄芽球%";
    label i2_bblastyn="寛解導入2後 骨髄検査有無";
    label i2_bblastdt="寛解導入2後 骨髄検査日";
    label i2_bblast="寛解導入2後 骨髄芽球%";
    label c1_bblastyn="地固め1後 骨髄検査有無";
    label c1_bblastdt="地固め1後 骨髄検査日";
    label c1_bblast="地固め1後 骨髄芽球%";
    label c2_bblastyn="地固め2後 骨髄検査有無";
    label c2_bblastdt="地固め2後 骨髄検査日";
    label c2_bblast="地固め2後 骨髄芽球%";
    label c3_bblastyn="地固め3後 骨髄検査有無";
    label c3_bblastdt="地固め3後 骨髄検査日";
    label c3_bblast="地固め3後 骨髄芽球%";
	label rl_bblastyn="再発時 骨髄検査有無";
    label rl_bblastdt="再発時 骨髄検査日";
    label rl_bblast="再発時 骨髄芽球%";

run;

proc sort data=FA;
    by usubjid;
run;
 
*★;
data tmp1e_cns(keep=usubjid bl_cnsyn bl_cns_fadt bl_cns_fastat i1_cnsyn i1_cns_fadt i1_cns_fastat i2_cnsyn i2_cns_fadt i2_cns_fastat
                        c1_cnsyn c1_cns_fadt c1_cns_fastat c2_cnsyn c2_cns_fadt c2_cns_fastat c3_cnsyn c3_cns_fadt c3_cns_fastat rl_cnsyn rl_cns_fadt rl_cns_fastat);
length bl_cnsyn bl_cns_fastat i1_cnsyn i1_cns_fastat i2_cnsyn i2_cns_fastat c1_cnsyn c1_cns_fastat c2_cnsyn c2_cns_fastat c3_cnsyn c3_cns_fastat rl_cnsyn rl_cns_fastat $20.;
set fa;
    by usubjid;

    retain bl_cnsyn bl_cns_fadt bl_cns_fastat i1_cnsyn i1_cns_fadt i1_cns_fastat i2_cnsyn i2_cns_fadt i2_cns_fastat
        c1_cnsyn c1_cns_fadt c1_cns_fastat c2_cnsyn c2_cns_fadt c2_cns_fastat c3_cnsyn c3_cns_fadt c3_cns_fastat rl_cnsyn rl_cns_fadt rl_cns_fastat;

    if first.usubjid then call missing(of bl_cnsyn bl_cns_fadt bl_cns_fastat i1_cnsyn i1_cns_fadt i1_cns_fastat i2_cnsyn i2_cns_fadt i2_cns_fastat
        c1_cnsyn c1_cns_fadt c1_cns_fastat c2_cnsyn c2_cns_fadt c2_cns_fastat c3_cnsyn c3_cns_fadt c3_cns_fastat rl_cnsyn rl_cns_fadt rl_cns_fastat);

    where faobj="CNS involvement";
    if FASPID = "baseline2" then do;
        bl_cnsyn=faorres;
        bl_cns_fastat=fastat;
        bl_cns_fadt=input(fadtc,yymmdd10.);
    end;
    else if FASPID = "evaluation1" and FALNKGRP="INDUC1E" then do;
        i1_cnsyn=faorres;
        i1_cns_fastat=fastat;
        i1_cns_fadt=input(fadtc,yymmdd10.);
    end;
    else if FASPID = "evaluation2" and FALNKGRP="INDUC2E" then do;
        i2_cnsyn=faorres;
        i2_cns_fastat=fastat;
        i2_cns_fadt=input(fadtc,yymmdd10.);
    end;
    else if FASPID = "evaluation3" and FALNKGRP="CONS1E" then do;
        c1_cnsyn=faorres;
        c1_cns_fastat=fastat;
        c1_cns_fadt=input(fadtc,yymmdd10.);
    end;
    else if FASPID = "evaluation4" and FALNKGRP="CONS2E" then do;
        c2_cnsyn=faorres;
        c2_cns_fastat=fastat;
        c2_cns_fadt=input(fadtc,yymmdd10.);
    end;
    else if FASPID = "evaluation5" and FALNKGRP="CONS3E" then do;
        c3_cnsyn=faorres;
        c3_cns_fastat=fastat;
        c3_cns_fadt=input(fadtc,yymmdd10.);
    end;
    else if FASPID = "relapse" and FALNKGRP="RELAPSE" then do;
        rl_cnsyn=faorres;
        rl_cns_fastat=fastat;
        rl_cns_fadt=input(fadtc,yymmdd10.);
    end;

    if last.usubjid;

    format bl_cns_fadt i1_cns_fadt i2_cns_fadt c1_cns_fadt c2_cns_fadt c3_cns_fadt rl_cns_fadt yymmdd10.;

    label bl_cns_fastat="Baseline CNS浸潤評価有無";
    label bl_cnsyn="Baseline CNS浸潤有無";
    label bl_cns_fadt="Baseline CNS浸潤評価日";
    label i1_cns_fastat="寛解導入1後 CNS浸潤評価有無";
    label i1_cnsyn="寛解導入1後 CNS浸潤有無";
    label i1_cns_fadt="寛解導入1後 CNS浸潤評価日";
    label i2_cns_fastat="寛解導入2後 CNS浸潤評価有無";
    label i2_cnsyn="寛解導入2後 CNS浸潤有無";
    label i2_cns_fadt="寛解導入2後 CNS浸潤評価日";
    label c1_cns_fastat="地固め1後 CNS浸潤評価有無";
    label c1_cnsyn="地固め1後 CNS浸潤有無";
    label c1_cns_fadt="地固め1後 CNS浸潤評価日";
    label c2_cns_fastat="地固め2後 CNS浸潤評価有無";
    label c2_cnsyn="地固め2後 CNS浸潤有無";
    label c2_cns_fadt="地固め2後 CNS浸潤評価日";
    label c3_cns_fastat="地固め3後 CNS浸潤評価有無";
    label c3_cnsyn="地固め3後 CNS浸潤有無";
    label c3_cns_fadt="地固め3後 CNS浸潤評価日";
    label rl_cns_fastat="再発時 CNS浸潤評価有無";
    label rl_cnsyn="再発時 CNS浸潤有無";
    label rl_cns_fadt="再発時 CNS浸潤評価日";

run;

*★;
data tmp1e_ocns(keep=usubjid bl_ocnsyn bl_ocns_fadt bl_ocns_fastat i1_ocnsyn i1_ocns_fadt i1_ocns_fastat i2_ocnsyn i2_ocns_fadt i2_ocns_fastat
                        c1_ocnsyn c1_ocns_fadt c1_ocns_fastat c2_ocnsyn c2_cns_fadt c2_ocns_fastat c3_ocnsyn c3_ocns_fadt c3_ocns_fastat rl_ocnsyn rl_ocns_fadt rl_ocns_fastat);
length bl_ocnsyn bl_ocns_fastat i1_ocnsyn i1_ocns_fastat i2_ocnsyn i2_ocns_fastat c1_ocnsyn c1_ocns_fastat c2_ocnsyn c2_ocns_fastat c3_ocnsyn c3_ocns_fastat rl_ocnsyn rl_ocns_fastat $20.;
set fa;
    by usubjid;

    retain bl_ocnsyn bl_ocns_fadt bl_ocns_fastat i1_ocnsyn i1_ocns_fadt i1_ocns_fastat i2_ocnsyn i2_ocns_fadt i2_ocns_fastat
            c1_ocnsyn c1_ocns_fadt c1_ocns_fastat c2_ocnsyn c2_cns_fadt c2_ocns_fastat c3_ocnsyn c3_ocns_fadt c3_ocns_fastat rl_ocnsyn rl_ocns_fadt rl_ocns_fastat;

    if first.usubjid then call missing(of bl_ocnsyn bl_ocns_fadt bl_ocns_fastat i1_ocnsyn i1_ocns_fadt i1_ocns_fastat i2_ocnsyn i2_ocns_fadt i2_ocns_fastat
            c1_ocnsyn c1_ocns_fadt c1_ocns_fastat c2_ocnsyn c2_cns_fadt c2_ocns_fastat c3_ocnsyn c3_ocns_fadt c3_ocns_fastat rl_ocnsyn rl_ocns_fadt rl_ocns_fastat);

    where faobj="Other extramedullary involvement";
    if FASPID = "baseline2" then do;
        bl_ocnsyn=faorres;
        bl_ocns_fastat=fastat;
        bl_ocns_fadt=input(fadtc,yymmdd10.);
    end;
    else if FASPID = "evaluation1" and FALNKGRP="INDUC1E" then do;
        i1_ocnsyn=faorres;
        i1_ocns_fastat=fastat;
        i1_ocns_fadt=input(fadtc,yymmdd10.);
    end;
    else if FASPID = "evaluation2" and FALNKGRP="INDUC2E" then do;
        i2_ocnsyn=faorres;
        i2_ocns_fastat=fastat;
        i2_ocns_fadt=input(fadtc,yymmdd10.);
    end;
    else if FASPID = "evaluation3" and FALNKGRP="CONS1E" then do;
        c1_ocnsyn=faorres;
        c1_ocns_fastat=fastat;
        c1_ocns_fadt=input(fadtc,yymmdd10.);
    end;
    else if FASPID = "evaluation4" and FALNKGRP="CONS2E" then do;
        c2_ocnsyn=faorres;
        c2_ocns_fastat=fastat;
        c2_ocns_fadt=input(fadtc,yymmdd10.);
    end;
    else if FASPID = "evaluation5" and FALNKGRP="CONS3E" then do;
        c3_ocnsyn=faorres;
        c3_ocns_fastat=fastat;
        c3_ocns_fadt=input(fadtc,yymmdd10.);
    end;
    else if FASPID = "relapse" and FALNKGRP="RELAPSE" then do;
        rl_ocnsyn=faorres;
        rl_ocns_fastat=fastat;
        rl_ocns_fadt=input(fadtc,yymmdd10.);
    end;

    if last.usubjid;

    format bl_ocns_fadt i1_ocns_fadt i2_ocns_fadt c1_ocns_fadt c2_ocns_fadt c3_ocns_fadt rl_ocns_fadt yymmdd10.;

    label bl_ocns_fastat="Baseline その他の髄外浸潤評価有無";
    label bl_ocnsyn="Baseline その他の髄外浸潤有無";
    label bl_ocns_fadt="Baseline その他の髄外浸潤評価日";
    label i1_ocns_fastat="寛解導入1後 その他の髄外浸潤評価有無";
    label i1_ocnsyn="寛解導入1後 その他の髄外浸潤有無";
    label i1_ocns_fadt="寛解導入1後 その他の髄外浸潤評価日";
    label i2_ocns_fastat="寛解導入2後 その他の髄外浸潤評価有無";
    label i2_ocnsyn="寛解導入2後 その他の髄外浸潤有無";
    label i2_ocns_fadt="寛解導入2後 その他の髄外浸潤評価日";
    label c1_ocns_fastat="地固め1後 その他の髄外浸潤評価有無";
    label c1_ocnsyn="地固め1後 その他の髄外浸潤有無";
    label c1_ocns_fadt="地固め1後 その他の髄外浸潤評価日";
    label c2_ocns_fastat="地固め2後 その他の髄外浸潤評価有無";
    label c2_ocnsyn="地固め2後 その他の髄外浸潤有無";
    label c2_ocns_fadt="地固め2後 その他の髄外浸潤評価日";
    label c3_ocns_fastat="地固め3後 その他の髄外浸潤評価有無";
    label c3_ocnsyn="地固め3後 その他の髄外浸潤有無";
    label c3_ocns_fadt="地固め3後 その他の髄外浸潤評価日";
    label rl_ocns_fastat="再発時 その他の髄外浸潤評価有無";
    label rl_ocnsyn="再発時 その他の髄外浸潤有無";
    label rl_ocns_fadt="再発時 その他の髄外浸潤評価日";
run;

proc sort data=tmp1;
  by usubjid;
run;
proc sort data=tmp1e_dx2;
  by usubjid;
run;
proc sort data=tmp1e_fabc;
  by usubjid;
run;
proc sort data=tmp1e_cci;
  by usubjid;
run;
proc sort data=tmp1e_cns;
  by usubjid;
run;
proc sort data=tmp1e_ocns;
  by usubjid;
run;
proc sort data=tmp1e_bm;
  by usubjid;
run;


*★★;
data tmp1f;
  merge tmp1 tmp1e_dx2 tmp1e_fabc tmp1e_cci tmp1e_cns tmp1e_ocns tmp1e_bm;
  by usubjid;
run;


/*Baselineデータのまとめを症例毎に作成*/
*ECOG PS;
*★★;
data tmp1h_ps(keep=usubjid ecogps);
 set qs;
 length ecogps $20;
 where QSTESTCD = "ECOG101";
 ecogps=QSORRES;
 label ecogps="ECOG Performance Status";
run;

*CGA7-1;
data tmp1h_cga1a(keep=usubjid cga1yn);
  set qs;
  length cga1yn $20;
  where QSSPID = "baseline_cga" and QSTESTCD='CGA1A';
  cga1yn = QSORRES; 
  label cga1yn="CGA1 意欲";
 run;

data tmp1h_cga1b(keep=usubjid cga1);
  set qs;
  length cga1 8.;
  where QSSPID = "baseline_cga" and QSTESTCD='CGA1B';
  cga1 = input(QSORRES, best.);
  label cga1="CGA1 Vitality Index";
 run;

proc sort data=tmp1h_cga1a; by usubjid; run;
proc sort data=tmp1h_cga1b; by usubjid; run;
data tmp1h_cga1;
  merge tmp1h_cga1a tmp1h_cga1b; by usubjid;
run;

*CGA7-2;
data tmp1h_cga2a(keep=usubjid cga2yn);
  set qs;
  length cga2yn $20;
  where QSSPID = "baseline_cga" and QSTESTCD='CGA2A';
  cga2yn = QSORRES; 
  label cga2yn="CGA2 認知機能_復唱";
 run;

data tmp1h_cga2b(keep=usubjid cga2);
  set qs;
  length cga2 8.;
  where QSSPID = "baseline_cga" and QSTESTCD='CGA2B';
  cga2 = input(QSORRES, best.);
  label cga2="CGA2 MocA-J";
 run;

proc sort data=tmp1h_cga2a; by usubjid; run;
proc sort data=tmp1h_cga2b; by usubjid; run;
data tmp1h_cga2;
  merge tmp1h_cga2a tmp1h_cga2b; by usubjid;
run;

*CGA7-3;
data tmp1h_cga3a(keep=usubjid cga3yn);
  set qs;
  length cga3yn $20;
  where QSSPID = "baseline_cga" and QSTESTCD='CGA3A';
  cga3yn = QSORRES; 
  label cga3yn="CGA3 手動的ADL_交通手段の利用";
 run;

data tmp1h_cga3b(keep=usubjid cga3);
  set qs;
  length cga3 8.;
  where QSSPID = "baseline_cga" and QSTESTCD='CGA3B';
  cga3 = input(QSORRES, best.);
  label cga3="CGA3 IADL";
 run;

proc sort data=tmp1h_cga3a; by usubjid; run;
proc sort data=tmp1h_cga3b; by usubjid; run;
data tmp1h_cga3;
  merge tmp1h_cga3a tmp1h_cga3b; by usubjid;
run;

*CGA7-4;
data tmp1h_cga4a(keep=usubjid cga4yn);
  set qs;
  length cga4yn $20;
  where QSSPID = "baseline_cga" and QSTESTCD='CGA4A';
  cga4yn = QSORRES; 
  label cga4yn="CGA4 認知機能_遅延再生";
 run;

data tmp1h_cga4b(keep=usubjid cga4);
  set qs;
  length cga4 8.;
  where QSSPID = "baseline_cga" and QSTESTCD='CGA4B';
  cga4 = input(QSORRES, best.);
  label cga4="CGA4 MocA-J";
 run;

proc sort data=tmp1h_cga4a; by usubjid; run;
proc sort data=tmp1h_cga4b; by usubjid; run;
data tmp1h_cga4;
  merge tmp1h_cga4a tmp1h_cga4b; by usubjid;
run;

*CGA7-5;
data tmp1h_cga5a(keep=usubjid cga5yn);
  set qs;
  length cga5yn $20;
  where QSSPID = "baseline_cga" and QSTESTCD='CGA5A';
  cga5yn = QSORRES; 
  label cga5yn="CGA5 基本的ADL_入浴";
 run;

data tmp1h_cga5b(keep=usubjid cga5);
  set qs;
  length cga5 8.;
  where QSSPID = "baseline_cga" and QSTESTCD='CGA5B';
  cga5 = input(QSORRES, best.);
  label cga5="CGA5 Barthel Index";
 run;

proc sort data=tmp1h_cga5a; by usubjid; run;
proc sort data=tmp1h_cga5b; by usubjid; run;
data tmp1h_cga5;
  merge tmp1h_cga5a tmp1h_cga5b; by usubjid;
run;

*CGA7-6;
data tmp1h_cga6a(keep=usubjid cga6yn);
  set qs;
  length cga6yn $20;
  where QSSPID = "baseline_cga" and QSTESTCD='CGA6A';
  cga6yn = QSORRES; 
  label cga6yn="CGA6 基本的ADL_排泄";
 run;

data tmp1h_cga6b(keep=usubjid cga6);
  set qs;
  length cga6 8.;
  where QSSPID = "baseline_cga" and QSTESTCD='CGA6B';
  cga6 = input(QSORRES, best.);
  label cga6="CGA6 Barthel Index";
 run;

proc sort data=tmp1h_cga6a; by usubjid; run;
proc sort data=tmp1h_cga6b; by usubjid; run;
data tmp1h_cga6;
  merge tmp1h_cga6a tmp1h_cga6b; by usubjid;
run;

*CGA7-7;
data tmp1h_cga7a(keep=usubjid cga7yn);
  set qs;
  length cga7yn $20;
  where QSSPID = "baseline_cga" and QSTESTCD='CGA7A';
  cga7yn = QSORRES; 
  label cga7yn="CGA7 情緒";
 run;

data tmp1h_cga7b(keep=usubjid cga7);
  set qs;
  length cga7 8.;
  where QSSPID = "baseline_cga" and QSTESTCD='CGA7B';
  cga7 = input(QSORRES, best.);
  label cga7="CGA7 GDS-15";
 run;

proc sort data=tmp1h_cga7a; by usubjid; run;
proc sort data=tmp1h_cga7b; by usubjid; run;
data tmp1h_cga7;
  merge tmp1h_cga7a tmp1h_cga7b; by usubjid;
run;

proc sort data=tmp1h_cga1; by usubjid; run;
proc sort data=tmp1h_cga2; by usubjid; run;
proc sort data=tmp1h_cga3; by usubjid; run;
proc sort data=tmp1h_cga4; by usubjid; run;
proc sort data=tmp1h_cga5; by usubjid; run;
proc sort data=tmp1h_cga6; by usubjid; run;
proc sort data=tmp1h_cga7; by usubjid; run;

*★★;
data tmp1h_cga;
  merge tmp1h_cga1 tmp1h_cga2 tmp1h_cga3 tmp1h_cga4 tmp1h_cga5 tmp1h_cga6 tmp1h_cga7; by usubjid;
run;


*血液学的検査WBC;
data tmp1i_wbc(keep=usubjid bl_wbc);
  set lb;
  length bl_wbc 8.;
  where LBSPID = "baseline2" and lbtestcd = "WBC";
  bl_wbc=lborres;
  label bl_wbc="Baseline 白血球数";
run;

*血液学的検査PLT;
data tmp1i_plt(keep=usubjid bl_plat);
  set lb;
  length bl_plat 8.;
  where LBSPID = "baseline2" and lbtestcd = "PLAT";
  bl_plat=lborres;
  label bl_plat="Baseline 血小板数";
run;

*血液学的検査PT-INR;
data tmp1i_ptinr(keep=usubjid bl_ptinr);
  set lb;
  length bl_ptinr 8.;
  where LBSPID = "baseline2" and lbtestcd = "INR";
  bl_ptinr=lborres;
  label bl_ptinr="Baseline PT-INR";
run;


*末梢血芽球数;
data tmp1i_pblst(keep=usubjid bl_pblast bl_pblastyn);
  set lb;
  length bl_pblast 8. bl_pblastyn $200;
  where LBSPID = "baseline2" and lbtestcd = "BLASTLE";
  bl_pblast=lborres;
  bl_pblastyn=lbstat;
  label bl_pblast="Baseline 末梢血中芽球細胞";
  label bl_pblastyn="Baseline 末梢血中芽球細胞評価有無";

run;

*骨髄芽球数;
data tmp1i_bblst(keep=usubjid bl_bblast bl_bblastyn);
  set lb;
  length bl_bblast 8. bl_bblastyn $200;
  where LBSPID = "baseline2" and lbtestcd = "MYBLALE";
  bl_bblast=lborres;
  bl_bblastyn=lbstat;
  label bl_bblast="Baseline 骨髄血中芽球細胞";
  label bl_bblastyn="Baseline 骨髄血中芽球細胞評価有無";
run;

*細胞表面マーカー;
data tmp1i_cd2(keep=usubjid bl_cd2yn lbstat_bl_cd2);
  set lb;
  length bl_cd2yn lbstat_bl_cd2 $200;
  where LBSPID = "baseline2" and lbtestcd = "CD2";
  bl_cd2yn = strip(lborres);
  lbstat_bl_cd2=lbstat;
  label bl_cd2yn="Baseline CD2";
  label lbstat_bl_cd2="Baseline CD2検査施行有無";
run;

data tmp1i_cd3(keep=usubjid bl_cd3yn lbstat_bl_cd3);
  set lb;
  length bl_cd3yn lbstat_bl_cd3 $200;
  where LBSPID = "baseline2" and lbtestcd = "CD3";
  bl_cd3yn = strip(lborres);
  lbstat_bl_cd3=lbstat;
  label bl_cd3yn="Baseline CD3";
  label lbstat_bl_cd3="Baseline CD3検査施行有無";
run;

data tmp1i_cd4(keep=usubjid bl_cd4yn lbstat_bl_cd4);
  set lb;
  length bl_cd4yn lbstat_bl_cd4 $200;
  where LBSPID = "baseline2" and lbtestcd = "CD4";
  bl_cd4yn = strip(lborres);
  lbstat_bl_cd4=lbstat;
  label bl_cd4yn="Baseline CD4";
  label lbstat_bl_cd4="Baseline CD4検査施行有無";
run;

data tmp1i_cd5(keep=usubjid bl_cd5yn lbstat_bl_cd5);
  set lb;
  length bl_cd5yn lbstat_bl_cd5 $200;
  where LBSPID = "baseline2" and lbtestcd = "CD5";
  bl_cd5yn = strip(lborres);
  lbstat_bl_cd5=lbstat;
  label bl_cd5yn="Baseline CD5";
  label lbstat_bl_cd5="Baseline CD5検査施行有無";
run;

data tmp1i_cd7(keep=usubjid bl_cd7yn lbstat_bl_cd7);
  set lb;
  length bl_cd7yn lbstat_bl_cd7 $200;
  where LBSPID = "baseline2" and lbtestcd = "CD7";
  bl_cd7yn = strip(lborres);
  lbstat_bl_cd7=lbstat;
  label bl_cd7yn="Baseline CD7";
  label lbstat_bl_cd7="Baseline CD7検査施行有無";
run;

data tmp1i_cd8(keep=usubjid bl_cd8yn lbstat_bl_cd8);
  set lb;
  length bl_cd8yn lbstat_bl_cd8 $200;
  where LBSPID = "baseline2" and lbtestcd = "CD8";
  bl_cd8yn = strip(lborres);
  lbstat_bl_cd8=lbstat;
  label bl_cd8yn="Baseline CD8";
  label lbstat_bl_cd8="Baseline CD8検査施行有無";
run;

data tmp1i_cd10(keep=usubjid bl_cd10yn lbstat_bl_cd10);
  set lb;
  length bl_cd10yn lbstat_bl_cd10 $200;
  where LBSPID = "baseline2" and lbtestcd = "CD10";
  bl_cd10yn = strip(lborres);
  lbstat_bl_cd10=lbstat;
  label bl_cd10yn="Baseline CD10";
  label lbstat_bl_cd10="Baseline CD10検査施行有無";
run;

data tmp1i_cd11b(keep=usubjid bl_cd11byn lbstat_bl_cd11b);
  set lb;
  length bl_cd11byn lbstat_bl_cd11b $200;
  where LBSPID = "baseline2" and lbtestcd = "CD11B";
  bl_cd11byn = strip(lborres);
  lbstat_bl_cd11b=lbstat;
  label bl_cd11byn="Baseline CD11b";
  label lbstat_bl_cd11b="Baseline CD11b検査施行有無";
run;

data tmp1i_cd13(keep=usubjid bl_cd13yn lbstat_bl_cd13);
  set lb;
  length bl_cd13yn lbstat_bl_cd13 $200;
  where LBSPID = "baseline2" and lbtestcd = "CD13";
  bl_cd13yn = strip(lborres);
  lbstat_bl_cd13=lbstat;
  label bl_cd13yn="Baseline CD13";
  label lbstat_bl_cd13="Baseline CD13検査施行有無";
run;

data tmp1i_cd14(keep=usubjid bl_cd14yn lbstat_bl_cd14);
  set lb;
  length bl_cd14yn lbstat_bl_cd14 $200;
  where LBSPID = "baseline2" and lbtestcd = "CD14";
  bl_cd14yn = strip(lborres);
  lbstat_bl_cd14=lbstat;
  label bl_cd14yn="Baseline CD14";
  label lbstat_bl_cd14="Baseline CD14検査施行有無";
run;

data tmp1i_cd16(keep=usubjid bl_cd16yn lbstat_bl_cd16);
  set lb;
  length bl_cd16yn lbstat_bl_cd16 $200;
  where LBSPID = "baseline2" and lbtestcd = "CD16";
  bl_cd16yn = strip(lborres);
  lbstat_bl_cd16=lbstat;
  label bl_cd16yn="Baseline CD16";
  label lbstat_bl_cd16="Baseline CD16検査施行有無";
run;

data tmp1i_cd19(keep=usubjid bl_cd19yn lbstat_bl_cd19);
  set lb;
  length bl_cd19yn lbstat_bl_cd19 $200;
  where LBSPID = "baseline2" and lbtestcd = "CD19";
  bl_cd19yn = strip(lborres);
  lbstat_bl_cd19=lbstat;
  label bl_cd19yn="Baseline CD19";
  label lbstat_bl_cd19="Baseline CD19検査施行有無";
run;

data tmp1i_cd20(keep=usubjid bl_cd20yn lbstat_bl_cd20);
  set lb;
  length bl_cd20yn lbstat_bl_cd20 $200;
  where LBSPID = "baseline2" and lbtestcd = "CD20";
  bl_cd20yn = strip(lborres);
  lbstat_bl_cd20=lbstat;
  label bl_cd20yn="Baseline CD20";
  label lbstat_bl_cd20="Baseline CD20検査施行有無";
run;

data tmp1i_cd33(keep=usubjid bl_cd33yn lbstat_bl_cd33);
  set lb;
  length bl_cd33yn lbstat_bl_cd33 $200;
  where LBSPID = "baseline2" and lbtestcd = "CD33";
  bl_cd33yn = strip(lborres);
  lbstat_bl_cd33=lbstat;
  label bl_cd33yn="Baseline CD33";
  label lbstat_bl_cd33="Baseline CD33検査施行有無";
run;

data tmp1i_cd34(keep=usubjid bl_cd34yn lbstat_bl_cd34);
  set lb;
  length bl_cd34yn lbstat_bl_cd34 $200;
  where LBSPID = "baseline2" and lbtestcd = "CD34";
  bl_cd34yn = strip(lborres);
  lbstat_bl_cd34=lbstat;
  label bl_cd34yn="Baseline CD34";
  label lbstat_bl_cd34="Baseline CD34検査施行有無";
run;

data tmp1i_cd41a(keep=usubjid bl_cd41ayn lbstat_bl_cd41a);
  set lb;
  length bl_cd41ayn lbstat_bl_cd41a $200;
  where LBSPID = "baseline2" and lbtestcd = "CD41a";
  bl_cd41ayn = strip(lborres);
  lbstat_bl_cd41a=lbstat;
  label bl_cd41ayn="Baseline CD41a";
  label lbstat_bl_cd41a="Baseline CD41a検査施行有無";
run;

data tmp1i_cd56(keep=usubjid bl_cd56yn lbstat_bl_cd56);
  set lb;
  length bl_cd56yn lbstat_bl_cd56 $200;
  where LBSPID = "baseline2" and lbtestcd = "CD56";
  bl_cd56yn = strip(lborres);
  lbstat_bl_cd56=lbstat;
  label bl_cd56yn="Baseline CD56";
  label lbstat_bl_cd56="Baseline CD56検査施行有無";
run;

data tmp1i_cd117(keep=usubjid bl_cd117yn lbstat_bl_cd117);
  set lb;
  length bl_cd117yn lbstat_bl_cd117 $200;
  where LBSPID = "baseline2" and lbtestcd = "CD117";
  bl_cd117yn = strip(lborres);
  lbstat_bl_cd117=lbstat;
  label bl_cd117yn="Baseline CD117";
  label lbstat_bl_cd117="Baseline CD117検査施行有無";
run;

data tmp1i_cdhladr(keep=usubjid bl_cdhladryn lbstat_bl_cdhladr);
  set lb;
  length bl_cdhladryn lbstat_bl_cdhladr $200;
  where LBSPID = "baseline2" and lbtestcd = "HLADR";
  bl_cdhladryn = strip(lborres);
  lbstat_bl_cdhladr=lbstat;
  label bl_cdhladryn="Baseline HLA-DR";
  label lbstat_bl_cdhladr="Baseline HLA-DR検査施行有無";
run;

data tmp1i_cdglcfa(keep=usubjid bl_cdglcfayn lbstat_bl_cdglcfa);
  set lb;
  length bl_cdglcfayn lbstat_bl_cdglcfa $200;
  where LBSPID = "baseline2" and lbtestcd = "GLYCOINA";
  bl_cdglcfayn = strip(lborres);
  lbstat_bl_cdglcfa=lbstat;
  label bl_cdglcfayn="Baseline Glycophorin A";
  label lbstat_bl_cdglcfa="Baseline Glycophorin A検査施行有無";
run;

proc sort data=tmp1i_cd2;  by usubjid; run;
proc sort data=tmp1i_cd3;  by usubjid; run;
proc sort data=tmp1i_cd4;  by usubjid; run;
proc sort data=tmp1i_cd5;  by usubjid; run;
proc sort data=tmp1i_cd7;  by usubjid; run;
proc sort data=tmp1i_cd8;  by usubjid; run;
proc sort data=tmp1i_cd10;  by usubjid; run;
proc sort data=tmp1i_cd11b;  by usubjid; run;
proc sort data=tmp1i_cd13;  by usubjid; run;
proc sort data=tmp1i_cd14;  by usubjid; run;
proc sort data=tmp1i_cd16;  by usubjid; run;
proc sort data=tmp1i_cd19;  by usubjid; run;
proc sort data=tmp1i_cd20;  by usubjid; run;
proc sort data=tmp1i_cd33;  by usubjid; run;
proc sort data=tmp1i_cd34;  by usubjid; run;
proc sort data=tmp1i_cd41a;  by usubjid; run;
proc sort data=tmp1i_cd56;  by usubjid; run;
proc sort data=tmp1i_cd117;  by usubjid; run;
proc sort data=tmp1i_cdhladr;  by usubjid; run;
proc sort data=tmp1i_cdglcfa;  by usubjid; run;

*★★;
data tmp1i_cd;
  merge tmp1i_cd2 tmp1i_cd3 tmp1i_cd4 tmp1i_cd5 tmp1i_cd7 tmp1i_cd8 tmp1i_cd10 tmp1i_cd11b tmp1i_cd13
    tmp1i_cd14 tmp1i_cd16 tmp1i_cd19 tmp1i_cd20 tmp1i_cd33 tmp1i_cd34 tmp1i_cd41a tmp1i_cd56
    tmp1i_cd117 tmp1i_cdhladr tmp1i_cdglcfa;
  by usubjid;
run;

data tmp1i_chrom(keep=usubjid bl_chromyn lbstat_bl_chrom);
  set lb;
  length bl_chromyn lbstat_bl_chrom $200;
  where LBSPID = "baseline2" and lbtestcd = "CHROABNO";
  bl_chromyn = strip(lborres);
  lbstat_bl_chrom=lbstat;
  label bl_chromyn="Baseline 染色体異常";
  label lbstat_bl_chrom="Baseline 染色体検査施行有無";
run;

data tmp1i_chromt821(keep=usubjid bl_chromt821yn);
  set lb;
  length bl_chromt821yn $200;
  where LBSPID = "baseline2" and lbtestcd = "T821";
  bl_chromt821yn = strip(lborres);
  label bl_chromt821yn="Baseline t(8;21)";
run;
data tmp1i_chrominv16(keep=usubjid bl_chrominv16yn);
  set lb;
  length bl_chrominv16yn $200;
  where LBSPID = "baseline2" and lbtestcd = "INV16";
  bl_chrominv16yn = strip(lborres);
  label bl_chrominv16yn="Baseline inv(16)";
run;
data tmp1i_chromt1616(keep=usubjid bl_chromt1616yn);
  set lb;
  length bl_chromt1616yn $200;
  where LBSPID = "baseline2" and lbtestcd = "T1616";
  bl_chromt1616yn = strip(lborres);
  label bl_chromt1616yn="Baseline t(16;16)";
run;

data tmp1i_chromt911(keep=usubjid bl_chromt911yn);
  set lb;
  length bl_chromt911yn $200;
  where LBSPID = "baseline2" and lbtestcd = "T911";
  bl_chromt911yn = strip(lborres);
  label bl_chromt911yn="Baseline t(9;11)";
run;
data tmp1i_chromt122p13q(keep=usubjid bl_chromt122p13qyn);
  set lb;
  length bl_chromt122p13qyn $200;
  where LBSPID = "baseline2" and lbtestcd = "T122P13Q";
  bl_chromt122p13qyn = strip(lborres);
  label bl_chromt122p13qyn="Baseline t(1;22)(p13;q13)";
run;
data tmp1i_chromt69(keep=usubjid bl_chromt69yn);
  set lb;
  length bl_chromt69yn $200;
  where LBSPID = "baseline2" and lbtestcd = "T69";
  bl_chromt69yn = strip(lborres);
  label bl_chromt69yn="Baseline t(6;9)/t(6;9)(p23;q34)";
run;
data tmp1i_chromtv11q233(keep=usubjid bl_chromtv11q233yn);
  set lb;
  length bl_chromtv11q233yn $200;
  where LBSPID = "baseline2" and lbtestcd = "TV11Q233";
  bl_chromtv11q233yn = strip(lborres);
  label bl_chromtv11q233yn="Baseline t(v;11q23.3)/t(v;11)(v;q23)";
run;
data tmp1i_chromt922(keep=usubjid bl_chromt922yn);
  set lb;
  length bl_chromt922yn $200;
  where LBSPID = "baseline2" and lbtestcd = "T922";
  bl_chromt922yn = strip(lborres);
  label bl_chromt922yn="Baseline t(9;22)";
run;
data tmp1i_chrominv3(keep=usubjid bl_chrominv3yn);
  set lb;
  length bl_chrominv3yn $200;
  where LBSPID = "baseline2" and lbtestcd = "INV3";
  bl_chrominv3yn = strip(lborres);
  label bl_chrominv3yn="Baseline inv(3)/inv(3)(p21;q26.2) or t(3;3)(p21;q26.2)";
run;
data tmp1i_chrommns5(keep=usubjid bl_chrommns5yn);
  set lb;
  length bl_chrommns5yn $200;
  where LBSPID = "baseline2" and lbtestcd = "MNS5";
  bl_chrommns5yn = strip(lborres);
  label bl_chrommns5yn="Baseline -5";
run;
data tmp1i_chromdel5q(keep=usubjid bl_chromdel5qyn);
  set lb;
  length bl_chromdel5qyn $200;
  where LBSPID = "baseline2" and lbtestcd = "DEL5Q";
  bl_chromdel5qyn = strip(lborres);
  label bl_chromdel5qyn="Baseline del(5q)";
run;
data tmp1i_chrommns7(keep=usubjid bl_chrommns7yn);
  set lb;
  length bl_chrommns7yn $200;
  where LBSPID = "baseline2" and lbtestcd = "MNS7";
  bl_chrommns7yn = strip(lborres);
  label bl_chrommns7yn="Baseline -7";
run;
data tmp1i_chrommns17abn(keep=usubjid bl_chrommns17abnyn);
  set lb;
  length bl_chrommns17abnyn $200;
  where LBSPID = "baseline2" and lbtestcd = "MNS17ABN";
  bl_chrommns17abnyn = strip(lborres);
  label bl_chrommns17abnyn="Baseline -17/abn(17p)/17p abnormality";
run;
data tmp1i_chromcta3km(keep=usubjid bl_chromcta3kmyn);
  set lb;
  length bl_chromcta3kmyn $200;
  where LBSPID = "baseline2" and lbtestcd = "CTA_3KM_";
  bl_chromcta3kmyn = strip(lborres);
  label bl_chromcta3kmyn="Baseline Complex type abnormality (3 or more)";
run;


proc sort data=tmp1i_chrom; by usubjid; run;
proc sort data=tmp1i_chromt821; by usubjid; run;
proc sort data=tmp1i_chrominv16; by usubjid; run;
proc sort data=tmp1i_chromt1616; by usubjid; run;
proc sort data=tmp1i_chromt911; by usubjid; run;
proc sort data=tmp1i_chromt122p13q; by usubjid; run;
proc sort data=tmp1i_chromt69; by usubjid; run;
proc sort data=tmp1i_chromtv11q233; by usubjid; run;
proc sort data=tmp1i_chromt922; by usubjid; run;
proc sort data=tmp1i_chrominv3; by usubjid; run;
proc sort data=tmp1i_chrommns5; by usubjid; run;
proc sort data=tmp1i_chromdel5q; by usubjid; run;
proc sort data=tmp1i_chrommns7; by usubjid; run;
proc sort data=tmp1i_chrommns17abn; by usubjid; run;
proc sort data=tmp1i_chromcta3km; by usubjid; run;

*★★;
data tmp1i_chromtotal; 
merge tmp1i_chrom tmp1i_chromt821 tmp1i_chrominv16 tmp1i_chromt1616 tmp1i_chromt911
         tmp1i_chromt122p13q tmp1i_chromt69 tmp1i_chromtv11q233 tmp1i_chromt922 tmp1i_chrominv3
         tmp1i_chrommns5 tmp1i_chromdel5q tmp1i_chrommns7 tmp1i_chrommns17abn tmp1i_chromcta3km;
by usubjid;
run;

*遺伝子変異
　FLT3-ITD（無　有　未施行）
　NPM1（無　有　未施行）
　CEBPA両アリル変異（無　有　未施行）
　KIT（無　有　未施行）
　RUNX1（無　有　未施行）
　SF3B1（無　有　未施行）;

data tmp1i_geneflt3(keep=usubjid bl_geneflt3yn lbstat_bl_geneflt3);
  set lb;
  length bl_geneflt3yn lbstat_bl_geneflt3 $200;
  where LBSPID = "baseline2" and lbtestcd = "FLT3-ITD";
  bl_geneflt3yn = strip(lborres);
  lbstat_bl_geneflt3=lbstat;
  label bl_geneflt3yn="Baseline FLT3-ITD";
  label lbstat_bl_geneflt3="Baseline FLT3-ITD検査施行有無";
run;
data tmp1i_genenpm1(keep=usubjid bl_genenpm1yn lbstat_bl_genenpm1);
  set lb;
  length bl_genenpm1yn lbstat_bl_genenpm1 $200;
  where LBSPID = "baseline2" and lbtestcd = "NPM1";
  bl_genenpm1yn = strip(lborres);
  lbstat_bl_genenpm1=lbstat;
  label bl_genenpm1yn="Baseline NPM1";
  label lbstat_bl_genenpm1="Baseline NPM1検査施行有無";
run;
data tmp1i_geneCEBPA(keep=usubjid bl_geneCEBPAyn lbstat_bl_geneCEBPA);
  set lb;
  length bl_geneCEBPAyn lbstat_bl_geneCEBPA $200;
  where LBSPID = "baseline2" and lbtestcd = "CEBPA";
  bl_geneCEBPAyn = strip(lborres);
  lbstat_bl_geneCEBPA=lbstat;
  label bl_geneCEBPAyn="Baseline CEBPA両アリル変異";
  label lbstat_bl_geneCEBPA="Baseline CEBPA両アリル変異検査施行有無";
run;
data tmp1i_genekit(keep=usubjid bl_geneKITyn lbstat_bl_geneKIT);
  set lb;
  length bl_geneKITyn lbstat_bl_geneKIT $200;
  where LBSPID = "baseline2" and lbtestcd = "KIT";
  bl_geneKITyn = strip(lborres);
  lbstat_bl_geneKIT=lbstat;
  label bl_geneKITyn="Baseline KIT";
  label lbstat_bl_geneKIT="Baseline KIT検査施行有無";
run;
data tmp1i_generunx1(keep=usubjid bl_generunx1yn lbstat_bl_generunx1);
  set lb;
  length bl_generunx1yn lbstat_bl_generunx1 $200;
  where LBSPID = "baseline2" and lbtestcd = "RUNX1";
  bl_generunx1yn = strip(lborres);
  lbstat_bl_generunx1=lbstat;
  label bl_generunx1yn="Baseline RUNX1";
  label lbstat_bl_generunx1="Baseline RUNX1検査施行有無";
run;
data tmp1i_geneSF3B1(keep=usubjid bl_geneSF3B1yn lbstat_bl_geneSF3B1);
  set lb;
  length bl_geneSF3B1yn lbstat_bl_geneSF3B1 $200;
  where LBSPID = "baseline2" and lbtestcd = "SF3B1";
  bl_geneSF3B1yn = strip(lborres);
  lbstat_bl_geneSF3B1=lbstat;
  label bl_geneSF3B1yn="Baseline SF3B1";
  label lbstat_bl_geneSF3B1="Baseline SF3B1検査施行有無";
run;

proc sort data=tmp1i_geneflt3;  by usubjid; run;
proc sort data=tmp1i_genenpm1;  by usubjid; run;
proc sort data=tmp1i_geneCEBPA;  by usubjid; run;
proc sort data=tmp1i_genekit;  by usubjid; run;
proc sort data=tmp1i_generunx1;  by usubjid; run;
proc sort data=tmp1i_geneSF3B1;  by usubjid; run;

data tmp1i_gene;
 merge tmp1i_geneflt3 tmp1i_genenpm1 tmp1i_geneCEBPA tmp1i_genekit tmp1i_generunx1 tmp1i_geneSF3B1;
 by usubjid;
run;

proc sort data=tmp1i_gene; by usubjid; run;
*★★;
data tmp1i_genec;
  set tmp1i_gene;
  by usubjid;  

  retain genec genecn; 
  
  length genecn $200;
  length genec 8;

  if first.usubjid then do;
    call missing(genec, genecn);
    
    /* * 症例ごとの分類ロジック
     * 優先順位: 1. FLT3-ITD -> 2. NPM1 -> 3. Other
     */
    
    /* 1. FLT3-ITD陽性 */
    if bl_geneflt3yn = 'POSITIVE' then do;
      genec = 1;
      genecn = 'FLT3-ITD';
    end;
    /* 2. NPM1陽性（FLT3-ITDが'POSITIVE'でなかった場合のみ実行） */
    else if bl_genenpm1yn = 'POSITIVE' then do;
      genec = 2;
      genecn = 'NPM1';
    end;
    /* 3. 両方とも'POSITIVE'でなかった場合（その他） */
    else do;
      genec = 3;
      genecn = 'Other';
    end;
  end;
  
  if last.usubjid then do;
    label genec="遺伝子変異3群（1.FLT3-ITD, 2.NPM1, 3.Other）";
    label genecn="遺伝子変異3群（FLT3-ITD, NPM1, Other）";
    output;
  end;
run;

proc sort data=tmp1f;  by usubjid; run;
proc sort data=tmp1h_ps;  by usubjid; run;
proc sort data=tmp1h_cga;  by usubjid; run;
proc sort data=tmp1i_wbc;  by usubjid; run;
proc sort data=tmp1i_plt; by usubjid; run;
proc sort data=tmp1i_ptinr;  by usubjid; run;
proc sort data=tmp1i_pblst;  by usubjid; run;
proc sort data=tmp1i_bblst;  by usubjid; run;
proc sort data=tmp1i_cd;  by usubjid; run;
proc sort data=tmp1i_chromtotal;  by usubjid; run;
proc sort data=tmp1i_genec;  by usubjid; run;

*★★★;
data tmp2;
 merge tmp1f tmp1h_ps tmp1h_cga tmp1i_wbc tmp1i_plt tmp1i_ptinr tmp1i_pblst tmp1i_bblst tmp1i_cd tmp1i_chromtotal tmp1i_genec;
 by usubjid;
run;


/*** EVENT DATAを抽出 ***/

/* RSドメインより効果判定（Overall Response）のデータを取得 & ソート */
proc sort data=RS; by usubjid; run;

data tmp3_or(keep=usubjid Ind1_oryn Ind1_or_rsdt Ind2_oryn Ind2_or_rsdt Cons1_oryn Cons1_or_rsdt  Cons2_oryn Cons2_or_rsdt  Cons3_oryn Cons3_or_rsdt );
length Ind1_oryn Ind2_oryn Cons1_oryn Cons2_oryn Cons3_oryn  $20.;
set rs;
    by usubjid;

    retain Ind1_oryn Ind1_or_rsdt Ind2_oryn Ind2_or_rsdt Cons1_oryn Cons1_or_rsdt  Cons2_oryn Cons2_or_rsdt  Cons3_oryn Cons3_or_rsdt;

    if first.usubjid then call missing(of Ind1_oryn Ind1_or_rsdt Ind2_oryn Ind2_or_rsdt Cons1_oryn Cons1_or_rsdt  Cons2_oryn Cons2_or_rsdt  Cons3_oryn Cons3_or_rsdt);

    if RSSPID = "evaluation1" and RSLNKGRP="INDUC1E" then do;
        Ind1_oryn=rsorres;
        Ind1_or_rsdt=input(rsdtc,yymmdd10.);
    end;
    else if RSSPID = "evaluation2" and RSLNKGRP="INDUC2E" then do;
        Ind2_oryn=rsorres;
        Ind2_or_rsdt=input(rsdtc,yymmdd10.);
    end;
    else if RSSPID = "evaluation3" and RSLNKGRP="CONS1E" then do;
        Cons1_oryn=rsorres;
        Cons1_or_rsdt=input(rsdtc,yymmdd10.);
    end;
    else if RSSPID = "evaluation4" and RSLNKGRP="CONS2E" then do;
        Cons2_oryn=rsorres;
        Cons2_or_rsdt=input(rsdtc,yymmdd10.);
    end;
    else if RSSPID = "evaluation5" and RSLNKGRP="CONS3E" then do;
        Cons3_oryn=rsorres;
        Cons3_or_rsdt=input(rsdtc,yymmdd10.);
    end;
    if last.usubjid;

    format Ind1_or_rsdt Ind2_or_rsdt Cons1_or_rsdt Cons2_or_rsdt Cons3_or_rsdt yymmdd10.;

	label Ind1_oryn="寛解導入1後総合効果判定";
	label Ind1_or_rsdt="寛解導入1後総合効果判定日";
	label Ind2_oryn="寛解導入2後総合効果判定";
	label Ind2_or_rsdt="寛解導入2後総合効果判定日";
	label Cons1_oryn="地固め1後総合効果判定";
	label Cons1_or_rsdt="地固め1後総合効果判定日";
	label Cons2_oryn="地固め2後総合効果判定";
	label Cons2_or_rsdt="地固め2後総合効果判定日";
	label Cons3_oryn="地固め3後総合効果判定";
	label Cons3_or_rsdt="地固め3後総合効果判定日";
run;


/* 寛解導入1+2療法後の効果判定（CR導入有無）データ抽出 */
data rs_or (keep= USUBJID num_visitnum RSORRES RSDTC priority);
    set rs;

    /* VISITNUMを文字型から数値型へ変換 */
    num_visitnum = input(VISITNUM, best.);

    /* 抽出対象のレコードをフィルタリング */
    IF RSTEST = "Overall Response" AND num_visitnum in (210, 310);

    /* 抽出条件に基づいて優先度(priority)を設定 */
    /* 1: CR (最優先) */
    /* 2: Non-CR/Non-PD (次に優先) */
    IF RSORRES = "CR" THEN priority = 1;
    ELSE IF RSORRES = "NON-CR/NON-PD" THEN priority = 2;
    ELSE priority = 99; /* その他の結果は対象外とする */
run;

proc sort data=rs_or;
    by USUBJID  priority;
run;

data tmp3_or2 (keep=USUBJID cr1yn cr1yndt);
    set rs_or (rename=(RSORRES=cr1yn));
    by USUBJID;

    cr1yndt = input(RSDTC, yymmdd10.);
    
    format cr1yndt yymmdd10.;
    label cr1yn   = "寛解導入療法1,2総合効果判定"
          cr1yndt = "寛解導入療法1,2総合効果判定日";

    if first.USUBJID and priority in (1, 2) then do;
        output;
    end;
run;

/*再発データ抽出*/
data tmp3_RL (keep=USUBJID RLyn RLdt);
    set ce;
    length RLyn  $20.;
	retain RLyn RLdt; 

    where CETERM = 'RELAPSE' and CEOCCUR = 'Y';

    RLyn= CEOCCUR;
    RLdt = input(CEDTC, yymmdd10.);

    format RLdt yymmdd10.;

    label RLyn = "第1再発有無"
           RLdt = "第1再発確認日";
run;


proc sort data=tmp2; by usubjid; run;
proc sort data=tmp3_or; by usubjid; run;
proc sort data=tmp3_or2; by usubjid; run;
proc sort data=tmp3_RL; by usubjid; run;

*★★★★;
data tmp4;
    merge tmp2 tmp3_or tmp3_or2 tmp3_RL;
	by usubjid;
run;



*試験治療、試験の中止完了;
data tmp5a(keep=usubjid dsterm dsstdt);
  set DS;
  length dsstdt 8.;
  where dsspid="discontinuation";
  dsstdt=input(dsstdtc,yymmdd10.);
  format dsstdt yymmdd10.;
  label dsterm="試験薬投与の完了/中止理由" 
        dsstdt="試験薬投与の完了/中止日";
run;

data tmp5b(keep=usubjid dsterm2 dsstdt2);
  set DS;
  length dsterm2 $40. dsstdt2 8.;
  where dsspid="withdrawal";
  dsterm2=dsterm;
  dsstdt2=input(dsstdtc,yymmdd10.);
  format dsstdt2 yymmdd10.;
  label dsterm2="試験の完了/中止理由" 
        dsstdt2="最終生存確認/死亡日";
run;

proc sort data=tmp4; by usubjid;run;
proc sort data=tmp5a; by usubjid;run;
proc sort data=tmp5b; by usubjid;run;

data tmp6;
 merge tmp4 tmp5a tmp5b; by usubjid; run;

data tmp6_outcome;
    set tmp6;

    /* 初期値の設定（OS_cは死亡日がない限り0/打ち切り日を初期設定） */
    OS_c = 0;
    OSdt = dsstdt2; 
    EFS_c = 0;
    EFSdt = dsstdt2; 
    
    format OSdt EFSdt yymmdd10.;
    label EFS_c = "EFSイベントフラグ (1:イベント, 0:打ち切り)";
    label EFSdt = "EFSイベント日または打ち切り日";
	label OS_c = "OSイベントフラグ (1:イベント, 0:打ち切り)";
    label OSdt = "OSイベント日または打ち切り日";

    /* ================================================= */
    /* 1. EFSイベントの定義 (if/else if の連鎖で優先度を確保) */
    /* ================================================= */
    /* 1.1 寛解導入不能 (Non-CR/Non-PD) の場合 (最優先EFSイベント) */
    if cr1yn = 'NON-CR/NON-PD' then do;
        EFS_c = 1;
        EFSdt = cr1yndt;
    end;
    
    /* 1.2 寛解導入後の再発 (CRかつRLyn='Y') の場合 */
    else if cr1yn = 'CR' and RLyn = 'Y' then do;
        EFS_c = 1;
        EFSdt = RLdt;
    end;
    
    /* 1.3 上記以外で、死亡がEFSイベントに含まれる場合 */
    else if dsterm2 = 'DEATH' then do;
        EFS_c = 1;
        EFSdt = dsstdt2; 
    end;
    
    /* ================================================= */
    /* 2. OSイベントの定義 (EFSのロジックとは独立) */
    /* ================================================= */
    if dsterm2 = 'DEATH' then do;
        OS_c = 1;
        OSdt = dsstdt2;
    end;

run;

data tmp7;
 set tmp6_outcome;
   retain efs_d efs_m efs_y os_d os_m os_y;
  efs_d = efsdt - rfstdt + 1;
  efs_m = efs_d/(365.25/12);
  efs_y = efs_d / 365.25;
  os_d = osdt - rfstdt + 1;
  os_m = os_d / (365.25/12);
  os_y = os_d / 365.25;

  label  efs_d   = "無イベント生存期間(日)"
      efs_m   = "無イベント生存期間(月)"
      efs_y   = "無イベント生存期間(年)"
      os_d    = "全生存期間(日)"
      os_m    = "全生存期間(月)"
      os_y    = "全生存期間(年)";
  run;

data outcome;
 set tmp7;
 keep usubjid ind1_oryn ind1_or_rsdt  ind2_oryn ind2_or_rsdt cr1yn cr1yndt  cons1_oryn cons1_or_rsdt cons2_oryn cons2_or_rsdt cons3_oryn cons3_or_rsdt rlyn rldt EFSdt EFS_c OSdt OS_c;run;


/*試験治療情報*/
data tmp8a;
    set ec;

    length ecstdt ecendt 8.;
    ecstdt = input(ecstdtc, yymmdd10.);
    ecendt = input(ecendtc, yymmdd10.);

    /* 投与日数(days)の計算 */
    /* 終了日(ecendt)が欠損値(.)を考慮する */
    if ecendt = . then days = 1;          /* 開始日が存在するため、欠損の場合は1日とする */
    else days = ecendt - ecstdt + 1; /* 欠損でなければ期間を計算 */

    format ecstdt ecendt yymmdd10.;
run;

*Induction tx.1;

data tmp8b_araC(keep=usubjid i1_trstdt i1_AraCdays i1_AraCdose ECDOSU);
  set tmp8a;
  length i1_trstdt i1_AraCdays i1_AraCdose 8.;
  where ecspid="induction1" and ectrt="CYTARABINE";
   i1_trstdt=ecstdt;
   i1_AraCdays=days;
   i1_AraCdose=input(ecdose, best.);

  format i1_trstdt yymmdd10.;

  label i1_trstdt="寛解導入1療法開始日"
         i1_AraCdays="寛解導入1療法AraC投与日数"
		 i1_AraCdose="寛解導入1療法AraC投与量";
run;

data tmp8b_dnr(keep=usubjid i1_DNRdays i1_DNRdose ECDOSU);
  set tmp8a;
  length i1_DNRdays i1_DNRdose 8.;
  where ecspid="induction1" and ectrt="DAUNORUBICIN HYDROCHLORIDE";
   i1_DNRdays=days;
   i1_DNRdose=input(ecdose, best.);

  label i1_DNRdays="寛解導入1療法DNR投与日数"
		 i1_DNRdose="寛解導入1療法DNR投与量";
run;

*Induction tx.2;

data tmp8c_araC(keep=usubjid i2_trstdt i2_AraCdays i2_AraCdose ECDOSU);
  set tmp8a;
  length i2_trstdt i2_AraCdays i2_AraCdose 8.;
  where ecspid="induction2" and ectrt="CYTARABINE";
   i2_trstdt=ecstdt;
   i2_AraCdays=days;
   i2_AraCdose=input(ecdose, best.);

  format i2_trstdt yymmdd10.;

  label i2_trstdt="寛解導入2療法開始日"
         i2_AraCdays="寛解導入2療法AraC投与日数"
		 i2_AraCdose="寛解導入2療法AraC投与量";
run;

data tmp8c_dnr(keep=usubjid i2_DNRdays i2_DNRdose ECDOSU);
  set tmp8a;
  length i2_DNRdays i2_DNRdose 8.;
  where ecspid="induction2" and ectrt="DAUNORUBICIN HYDROCHLORIDE";
   i2_DNRdays=days;
   i2_DNRdose=input(ecdose, best.);

  label i2_DNRdays="寛解導入2療法DNR投与日数"
		 i2_DNRdose="寛解導入2療法DNR投与量";
run;

*Consolidation tx.1;

data tmp8d_araC(keep=usubjid c1_trstdt c1_AraCdays c1_AraCdose ECDOSU);
  set tmp8a;
  length c1_trstdt c1_AraCdays c1_AraCdose 8.;
  where ecspid="consolidation1" and ectrt="CYTARABINE";
   c1_trstdt=ecstdt;
   c1_AraCdays=days;
   c1_AraCdose=input(ecdose, best.);

  format c1_trstdt yymmdd10.;

  label c1_trstdt="地固め1療法開始日"
         c1_AraCdays="地固め1療法AraC投与日数"
		 c1_AraCdose="地固め1療法AraC投与量";
run;

data tmp8d_MIT(keep=usubjid c1_MITdays c1_MITdose ECDOSU);
  set tmp8a;
  length c1_MITdays c1_MITdose 8.;
  where ecspid="consolidation1" and ectrt="MITOXANTRONE HYDROCHLORIDE";
   c1_MITdays=days;
   c1_MITdose=input(ecdose, best.);

  label c1_MITdays="地固め1療法MIT投与日数"
		 c1_MITdose="地固め1療法MIT投与量";
run;

*Consolidation tx.2;
data tmp8e_araC(keep=usubjid c2_trstdt c2_AraCdays c2_AraCdose ECDOSU);
  set tmp8a;
  length c2_trstdt c2_AraCdays c2_AraCdose 8.;
  where ecspid="consolidation2" and ectrt="CYTARABINE";
   c2_trstdt=ecstdt;
   c2_AraCdays=days;
   c2_AraCdose=input(ecdose, best.);

  format c2_trstdt yymmdd10.;

  label c2_trstdt="地固め2療法開始日"
         c2_AraCdays="地固め2療法AraC投与日数"
		 c2_AraCdose="地固め2療法AraC投与量";
run;

data tmp8e_DNR(keep=usubjid c2_DNRdays c2_DNRdose ECDOSU);
  set tmp8a;
  length c2_DNRdays c2_DNRdose 8.;
  where ecspid="consolidation2" and ectrt="DAUNORUBICIN HYDROCHLORIDE";
   c2_DNRdays=days;
   c2_DNRdose=input(ecdose, best.);

  label c2_DNRdays="地固め2療法DNR投与日数"
		 c2_DNRdose="地固め2療法DNR投与量";
run;

*Consolidation tx.3;
data tmp8f_araC(keep=usubjid c3_trstdt c3_AraCdays c3_AraCdose ECDOSU);
  set tmp8a;
  length c3_trstdt c3_AraCdays c3_AraCdose 8.;
  where ecspid="consolidation3" and ectrt="CYTARABINE";
   c3_trstdt=ecstdt;
   c3_AraCdays=days;
   c3_AraCdose=input(ecdose, best.);

  format c3_trstdt yymmdd10.;

  label c3_trstdt="地固め3療法開始日"
         c3_AraCdays="地固め3療法AraC投与日数"
		 c3_AraCdose="地固め3療法AraC投与量";
run;

data tmp8f_ACR(keep=usubjid c3_ACRdays c3_ACRdose ECDOSU);
  set tmp8a;
  length c3_ACRdays c3_ACRdose 8.;
  where ecspid="consolidation3" and ectrt="ACLARUBICIN HYDROCHLORIDE";
   c3_ACRdays=days;
   c3_ACRdose=input(ecdose, best.);

  label c3_ACRdays="地固め3療法ACR投与日数"
		 c3_ACRdose="地固め3療法ACR投与量";
run;

*髄注;

data tmp8g_it(keep=usubjid ITyn ITdays);
  set tmp8a;
  where ecspid="consolidation3" and ectrt="INTRATHECAL";

  ITyn=ECDOSE;
  ITdays=days;

  label ityn="髄注実施"
         itdays= "髄注実施日数";
run;

proc sort data=tmp8b_arac;  by usubjid; run;
proc sort data=tmp8b_dnr;  by usubjid; run;
proc sort data=tmp8c_arac; by usubjid; run;
proc sort data=tmp8c_dnr;  by usubjid; run;
proc sort data=tmp8d_arac;  by usubjid; run;
proc sort data=tmp8d_MIT;  by usubjid; run;
proc sort data=tmp8e_arac;  by usubjid; run;
proc sort data=tmp8e_dnr;  by usubjid; run;
proc sort data=tmp8f_arac;  by usubjid; run;
proc sort data=tmp8f_acr;  by usubjid; run;
proc sort data=tmp8g_it;  by usubjid; run;

data tmp8;
  merge tmp8b_arac tmp8b_dnr tmp8c_arac tmp8c_dnr tmp8d_arac tmp8d_MIT tmp8e_arac tmp8e_dnr tmp8f_arac tmp8f_acr tmp8g_it;
  by usubjid;
  label ECDOSU= "投与量単位";
run;


*SAE集計;
/*proc freq data=ae; tables aeterm;run;*/

data tmp9(keep=usubjid anysae sae1 sae2 sae3 sae4 sae5 sae6 sae7 sae8 sae9 sae10 sae11 sae12 sae13 sae14 sae15 sae16 sae17 sae18 sae19);
  set ae;
  length anysae sae1 sae2 sae3 sae4 sae5 sae6 sae7 sae8 sae9 sae10 sae11 sae12 sae13 sae14 sae15 sae16 sae17 sae18 sae19 $3.;
  if aeterm ne "" then anysae="Y";
  if aeterm="Febrile neutropenia" then sae1="Y";
  else if aeterm="Sepsis" then sae2="Y";
  else if aeterm="AST increased" then sae3="Y";
  else if aeterm="Abscess bacterial" then sae4="Y";
  else if aeterm="Acute subdural haematoma" then sae5="Y";
  else if aeterm="Anorexia" then sae6="Y";
  else if aeterm="Bacterial pneumonia, unspecified" then sae7="Y";
  else if aeterm="Cardiac disorder" then sae8="Y";
  else if aeterm="Corynebacterium sepsis" then sae9="Y";
  else if aeterm="Decreased plasma fibrinogen" then sae10="Y";
  else if aeterm="Diverticular perforation" then sae11="Y";
  else if aeterm="Infectious colitis" then sae12="Y";
  else if aeterm="Lung infection" then sae13="Y";
  else if aeterm="Perianal abscess" then sae14="Y";
  else if aeterm="Pneumonia" then sae15="Y";
  else if aeterm="Pneumonitis" then sae16="Y";
  else if aeterm="Pulmonary alveolar haemorrhage" then sae17="Y";
  else if aeterm="Septicemia gram-negative" then sae18="Y";
  else if aeterm="Tumour lysis syndrome" then sae19="Y";

label anysae="Any SAE"
        sae1="Febrile neutropenia"
        sae2="Sepsis"
        sae3="AST increased"
        sae4="Abscess bacterial"
        sae5="Acute subdural haematoma"
        sae6="Anorexia"
        sae7="Bacterial pneumonia, unspecified"
        sae8="Cardiac disorder"
        sae9="Corynebacterium sepsis"
        sae10="Decreased plasma fibrinogen"
        sae11="Diverticular perforation"
        sae12="Infectious colitis"
        sae13="Lung infection"
        sae14="Perianal abscess"
        sae15="Pneumonia"
        sae16="Pneumonitis"
        sae17="Pulmonary alveolar haemorrhage"
        sae18="Septicemia gram-negative"
        sae19="Tumour lysis syndrome";
run;

/*proc freq data=fa;*/
/*where fatest="Grade";*/
/*tables faobj;run;*/
/**/
data tmp10a;
  set fa;
  length grade 8. var1 $2. var2 $4.;
  where fatest="Grade";
  grade=faorres;

  if visitnum="200" then var1="i1";
  else if visitnum="300" then var1="i2";
  else if visitnum="500" then var1="c1";
  else if visitnum="600" then var1="c2";
  else if visitnum="700" then var1="c3";

 if faobj="Catheter related infection" then var2="ae1";
 else if faobj="Urinary tract infection" then var2="ae2";
 else if faobj="Urticaria" then var2="ae3";
 else if faobj="Rash maculo-papular" then var2="ae4";
 else if faobj="Blood bilirubin increased" then var2="ae5";
 else if faobj="Allergic reaction" then var2="ae6";
 else if faobj="Febrile neutropenia" then var2="ae7";
 else if faobj="Anorectal infection" then var2="ae8";
 else if faobj="Disseminated intravascular coagulation" then var2="ae9";
 else if faobj="Cardiac disorders - Other" then var2="ae10";
 else if faobj="Hepatic failure" then var2="ae11";
 else if faobj="Diarrhea" then var2="ae12";
 else if faobj="Hyperglycemia" then var2="ae13";
 else if faobj="Lower gastrointestinal hemorrhage" then var2="ae14";
 else if faobj="Mucositis oral" then var2="ae15";
 else if faobj="Nausea" then var2="ae16";
 else if faobj="Ileus" then var2="ae17";
 else if faobj="Pancreatitis" then var2="ae18";
 else if faobj="Upper gastrointestinal hemorrhage" then var2="ae19";
 else if faobj="Vomiting" then var2="ae20";
 else if faobj="Peripheral motor neuropathy" then var2="ae21";
 else if faobj="Peripheral sensory neuropathy" then var2="ae22";
 else if faobj="Serum amylase increased" then var2="ae23";
 else if faobj="Lung infection" then var2="ae24";
 else if faobj="Sepsis" then var2="ae25";
 else if faobj="Alanine aminotransferase increased" then var2="ae26";
 else if faobj="Aspartate aminotransferase increased" then var2="ae27";
 else if faobj="Thromboembolic event" then var2="ae28";
 else if faobj="Creatinine increased" then var2="ae29";
 else if faobj="Tumor lysis syndrome" then var2="ae30";
 else if faobj="Uterine hemorrhage" then var2="ae31";
 else if faobj="Bronchopulmonary hemorrhage" then var2="ae32";
 else if faobj="Intracranial hemorrhage" then var2="ae33";
run;


proc sort data=tmp10a;
  by usubjid var2 var1;
run;

proc transpose data=tmp10a out=tmp10b;
  by usubjid;
  id var2 var1;
  var grade;
run;

data tmp10;
  set tmp10b;
  drop _name_;
  label

   /* ae1: Catheter related infection */
    ae1i1= "Catheter related infection (induction1) Gr"
    ae1i2= "Catheter related infection (induction2) Gr"
    ae1c1 = "Catheter related infection (consolidation1) Gr"
    ae1c2 = "Catheter related infection (consolidation2) Gr"
    ae1c3 = "Catheter related infection (consolidation3) Gr"

    /* ae2: Urinary tract infection */
    ae2i1 = "Urinary tract infection (induction1) Gr"
    ae2i2 = "Urinary tract infection (induction2) Gr"
    ae2c1 = "Urinary tract infection (consolidation1) Gr"
    ae2c2 = "Urinary tract infection (consolidation2) Gr"
    ae2c3 = "Urinary tract infection (consolidation3) Gr"

    /* ae3: Urticaria */
    ae3i1= "Urticaria (induction1) Gr"
    ae3i2= "Urticaria (induction2) Gr"
    ae3c1 = "Urticaria (consolidation1) Gr"
    ae3c2 = "Urticaria (consolidation2) Gr"
    ae3c3 = "Urticaria (consolidation3) Gr"

    /* ae4: Rash maculo-papular */
    ae4i1 = "Rash maculo-papular (induction1) Gr"
    ae4i2 = "Rash maculo-papular (induction2) Gr"
    ae4c1 = "Rash maculo-papular (consolidation1) Gr"
    ae4c2 = "Rash maculo-papular (consolidation2) Gr"
    ae4c3 = "Rash maculo-papular (consolidation3) Gr"

	/* ae5: Blood bilirubin increased */
    ae5i1 = "Blood bilirubin increased (induction1) Gr"
    ae5i2 = "Blood bilirubin increased (induction2) Gr"
    ae5c1 = "Blood bilirubin increased (consolidation1) Gr"
    ae5c2 = "Blood bilirubin increased (consolidation2) Gr"
    ae5c3 = "Blood bilirubin increased (consolidation3) Gr"

    /* ae6: Allergic reaction */
    ae6i1 = "Allergic reaction (induction1) Gr"
    ae6i2 = "Allergic reaction (induction2) Gr"
    ae6c1 = "Allergic reaction (consolidation1) Gr"
    ae6c2 = "Allergic reaction (consolidation2) Gr"
    ae6c3 = "Allergic reaction (consolidation3) Gr"

    /* ae7: Febrile neutropenia */
    ae7i1 = "Febrile neutropenia (induction1) Gr"
    ae7i2 = "Febrile neutropenia (induction2) Gr"
    ae7c1 = "Febrile neutropenia (consolidation1) Gr"
    ae7c2 = "Febrile neutropenia (consolidation2) Gr"
    ae7c3 = "Febrile neutropenia (consolidation3) Gr"

    /* ae8: Anorectal infection */
    ae8i1 = "Anorectal infection (induction1) Gr"
    ae8i2 = "Anorectal infection (induction2) Gr"
    ae8c1 = "Anorectal infection (consolidation1) Gr"
    ae8c2 = "Anorectal infection (consolidation2) Gr"
    ae8c3 = "Anorectal infection (consolidation3) Gr"

	/* ae9: Disseminated intravascular coagulation */
    ae9i1 = "Disseminated intravascular coagulation (induction1) Gr"
    ae9i2 = "Disseminated intravascular coagulation (induction2) Gr"
    ae9c1 = "Disseminated intravascular coagulation (consolidation1) Gr"
    ae9c2 = "Disseminated intravascular coagulation (consolidation2) Gr"
    ae9c3 = "Disseminated intravascular coagulation (consolidation3) Gr"

    /* ae10: Cardiac disorders - Other */
    ae10i1 = "Cardiac disorders - Other (induction1) Gr"
    ae10i2 = "Cardiac disorders - Other (induction2) Gr"
    ae10c1 = "Cardiac disorders - Other (consolidation1) Gr"
    ae10c2 = "Cardiac disorders - Other (consolidation2) Gr"
    ae10c3 = "Cardiac disorders - Other (consolidation3) Gr"

    /* ae11: Hepatic failure */
    ae11i1 = "Hepatic failure (induction1) Gr"
    ae11i2 = "Hepatic failure (induction2) Gr"
    ae11c1 = "Hepatic failure (consolidation1) Gr"
    ae11c2 = "Hepatic failure (consolidation2) Gr"
    ae11c3 = "Hepatic failure (consolidation3) Gr"

    /* ae12: Diarrhea */
    ae12i1 = "Diarrhea (induction1) Gr"
    ae12i2 = "Diarrhea (induction2) Gr"
    ae12c1 = "Diarrhea (consolidation1) Gr"
    ae12c2 = "Diarrhea (consolidation2) Gr"
    ae12c3 = "Diarrhea (consolidation3) Gr"

    /* ae13: Hyperglycemia */
    ae13i1 = "Hyperglycemia (induction1) Gr"
    ae13i2 = "Hyperglycemia (induction2) Gr"
    ae13c1 = "Hyperglycemia (consolidation1) Gr"
    ae13c2 = "Hyperglycemia (consolidation2) Gr"
    ae13c3 = "Hyperglycemia (consolidation3) Gr"

    /* ae14: Lower gastrointestinal hemorrhage */
    ae14i1 = "Lower gastrointestinal hemorrhage (induction1) Gr"
    ae14i2 = "Lower gastrointestinal hemorrhage (induction2) Gr"
    ae14c1 = "Lower gastrointestinal hemorrhage (consolidation1) Gr"
    ae14c2 = "Lower gastrointestinal hemorrhage (consolidation2) Gr"
    ae14c3 = "Lower gastrointestinal hemorrhage (consolidation3) Gr"

    /* ae15: Mucositis oral */
    ae15i1 = "Mucositis oral (induction1) Gr"
    ae15i2 = "Mucositis oral (induction2) Gr"
    ae15c1 = "Mucositis oral (consolidation1) Gr"
    ae15c2 = "Mucositis oral (consolidation2) Gr"
    ae15c3 = "Mucositis oral (consolidation3) Gr"

	/* ae16: Nausea */
    ae16i1 = "Nausea (induction1) Gr"
    ae16i2 = "Nausea (induction2) Gr"
    ae16c1 = "Nausea (consolidation1) Gr"
    ae16c2 = "Nausea (consolidation2) Gr"
    ae16c3 = "Nausea (consolidation3) Gr"

    /* ae17: Ileus */
    ae17i1 = "Ileus (induction1) Gr"
    ae17i2 = "Ileus (induction2) Gr"
    ae17c1 = "Ileus (consolidation1) Gr"
    ae17c2 = "Ileus (consolidation2) Gr"
    ae17c3 = "Ileus (consolidation3) Gr"

    /* ae18: Pancreatitis */
    ae18i1 = "Pancreatitis (induction1) Gr"
    ae18i2 = "Pancreatitis (induction1) Gr"
    ae18c1 = "Pancreatitis (consolidation1) Gr"
    ae18c2 = "Pancreatitis (consolidation2) Gr"
    ae18c3 = "Pancreatitis (consolidation3) Gr"

    /* ae19: Upper gastrointestinal hemorrhage */
    ae19i1 = "Upper gastrointestinal hemorrhage (induction1) Gr"
    ae19i2 = "Upper gastrointestinal hemorrhage (induction2) Gr"
    ae19c1 = "Upper gastrointestinal hemorrhage (consolidation1) Gr"
    ae19c2 = "Upper gastrointestinal hemorrhage (consolidation2) Gr"
    ae19c3 = "Upper gastrointestinal hemorrhage (consolidation3) Gr"

    /* ae20: Vomiting */
    ae20i1 = "Vomiting (induction1) Gr"
    ae20i2 = "Vomiting (induction2) Gr"
    ae20c1 = "Vomiting (consolidation1) Gr"
    ae20c2 = "Vomiting (consolidation2) Gr"
    ae20c3 = "Vomiting (consolidation3) Gr"

    /* ae21: Peripheral motor neuropathy */
    ae21i1 = "Peripheral motor neuropathy (induction1) Gr"
    ae21i2 = "Peripheral motor neuropathy (induction2) Gr"
    ae21c1 = "Peripheral motor neuropathy (consolidation1) Gr"
    ae21c2 = "Peripheral motor neuropathy (consolidation2) Gr"
    ae21c3 = "Peripheral motor neuropathy (consolidation3) Gr"

    /* ae22: Peripheral sensory neuropathy */
    ae22i1 = "Peripheral sensory neuropathy (induction1) Gr"
    ae22i2 = "Peripheral sensory neuropathy (induction2) Gr"
    ae22c1 = "Peripheral sensory neuropathy (consolidation1) Gr"
    ae22c2 = "Peripheral sensory neuropathy (consolidation2) Gr"
    ae22c3 = "Peripheral sensory neuropathy (consolidation3) Gr"

    /* ae23: Serum amylase increased */
    ae23i1 = "Serum amylase increased (induction1) Gr"
    ae23i2 = "Serum amylase increased (induction2) Gr"
    ae23c1 = "Serum amylase increased (consolidation1) Gr"
    ae23c2 = "Serum amylase increased (consolidation2) Gr"
    ae23c3 = "Serum amylase increased (consolidation3) Gr"

    /* ae24: Lung infection */
    ae24i1 = "Lung infection (induction1) Gr"
    ae24i2 = "Lung infection (induction2) Gr"
    ae24c1 = "Lung infection (consolidation1) Gr"
    ae24c2 = "Lung infection (consolidation2) Gr"
    ae24c3 = "Lung infection (consolidation3) Gr"

    /* ae25: Sepsis */
    ae25i1 = "Sepsis (induction1) Gr"
    ae25i2 = "Sepsis (induction2) Gr"
    ae25c1 = "Sepsis (consolidation1) Gr"
    ae25c2 = "Sepsis (consolidation2) Gr"
    ae25c3 = "Sepsis (consolidation3) Gr"

    /* ae26: Alanine aminotransferase increased */
    ae26i1 = "Alanine aminotransferase increased (induction1) Gr"
    ae26i2 = "Alanine aminotransferase increased (induction2) Gr"
    ae26c1 = "Alanine aminotransferase increased (consolidation1) Gr"
    ae26c2 = "Alanine aminotransferase increased (consolidation2) Gr"
    ae26c3 = "Alanine aminotransferase increased (consolidation3) Gr"

    /* ae27: Aspartate aminotransferase increased */
    ae27i1 = "Aspartate aminotransferase increased (induction1) Gr"
    ae27i2 = "Aspartate aminotransferase increased (induction2) Gr"
    ae27c1 = "Aspartate aminotransferase increased (consolidation1) Gr"
    ae27c2 = "Aspartate aminotransferase increased (consolidation2) Gr"
    ae27c3 = "Aspartate aminotransferase increased (consolidation3) Gr"

    /* ae28: Thromboembolic event */
    ae28i1 = "Thromboembolic event (induction1) Gr"
    ae28i2 = "Thromboembolic event (induction2) Gr"
    ae28c1 = "Thromboembolic event (consolidation1) Gr"
    ae28c2 = "Thromboembolic event (consolidation2) Gr"
    ae28c3 = "Thromboembolic event (consolidation3) Gr"

    /* ae29: Creatinine increased */
    ae29i1 = "Creatinine increased (induction1) Gr"
    ae29i2 = "Creatinine increased (induction2) Gr"
    ae29c1 = "Creatinine increased (consolidation1) Gr"
    ae29c2 = "Creatinine increased (consolidation2) Gr"
    ae29c3 = "Creatinine increased (consolidation3) Gr"

	/* ae30: Tumor lysis syndrome */
    ae30i1 = "Tumor lysis syndrome (induction1) Gr"
    ae30i2 = "Tumor lysis syndrome (induction2) Gr"
    ae30c1 = "Tumor lysis syndrome (consolidation1) Gr"
    ae30c2 = "Tumor lysis syndrome (consolidation2) Gr"
    ae30c3 = "Tumor lysis syndrome (consolidation3) Gr"

    /* ae31: Uterine hemorrhage */
    ae31i1 = "Uterine hemorrhage (induction1) Gr"
    ae31i2 = "Uterine hemorrhage (induction2) Gr"
    ae31c1 = "Uterine hemorrhage (consolidation1) Gr"
    ae31c2 = "Uterine hemorrhage (consolidation2) Gr"
    ae31c3 = "Uterine hemorrhage (consolidation3) Gr"

    /* ae32: Bronchopulmonary hemorrhage */
    ae32i1 = "Bronchopulmonary hemorrhage (induction1) Gr"
    ae32i2 = "Bronchopulmonary hemorrhage (induction2) Gr"
    ae32c1 = "Bronchopulmonary hemorrhage (consolidation1) Gr"
    ae32c2 = "Bronchopulmonary hemorrhage (consolidation2) Gr"
    ae32c3 = "Bronchopulmonary hemorrhage (consolidation3) Gr"

    /* ae33: Intracranial hemorrhage */
    ae33i1 = "Intracranial hemorrhage (induction1) Gr"
    ae33i2 = "Intracranial hemorrhage (induction2) Gr"
    ae33c1 = "Intracranial hemorrhage (consolidation1) Gr"
    ae33c2 = "Intracranial hemorrhage (consolidation2) Gr"
    ae33c3 = "Intracranial hemorrhage (consolidation3) Gr";

run;

proc sort data=tmp7; by usubjid; run;
proc sort data=tmp8; by usubjid; run;
proc sort data=tmp10; by usubjid; run;

data tmp11;
 merge tmp7 tmp8 tmp10; by usubjid; run;
 
/**/
/*data tmp12_pret_atra (keep=usubjid pret_atra);*/
/* set CM;*/
/* where CMTRT="ATRA";*/
/* pret_atra=CMOCCUR;*/
/* */
/* label pret_atra = "前治療ATRA";*/
/* run;*/
/**/
/*data tmp12_pret_am80 (keep=usubjid pret_am80);*/
/* set CM;*/
/* where CMTRT="Am80";*/
/* pret_am80=CMOCCUR;*/
/* */
/* label pret_am80 = "前治療Am80";*/
/* run;*/
/**/
/*data tmp12_pret_ato (keep=usubjid pret_ato);*/
/* set CM;*/
/* where CMTRT="ATO";*/
/* pret_ato=CMOCCUR;*/
/* */
/* label pret_ato = "前治療ATO";*/
/* run;*/
/**/
/*data tmp12_pret_go (keep=usubjid pret_go);*/
/* set CM;*/
/* where CMTRT="GO";*/
/* pret_go=CMOCCUR;*/
/* */
/* label pret_go = "前治療GO";*/
/* run;*/
/*proc sort data=tmp12_pret_atra; by usubjid; run;*/
/*proc sort data=tmp12_pret_am80; by usubjid; run;*/
/*proc sort data=tmp12_pret_ato; by usubjid; run;*/
/*proc sort data=tmp12_pret_go; by usubjid; run;*/
/**/
/*data tmp12;*/
/*  merge tmp12_pret_atra tmp12_pret_am80 tmp12_pret_ato tmp12_pret_go; */
/*  by usubjid;*/
/*run;*/
/**/
/*proc sort data=tmp11; by usubjid; run;*/
/*proc sort data=tmp12; by usubjid; run;*/
/**/
/*data tmp13;*/
/*  merge tmp11 tmp12;*/
/*  by usubjid;*/
/*run;*/

/*data tmp12 (keep=usubjid RIstum c1stum c2stum c3stum dxtoreg dur_fcr dur_fcrc os_d os_m os_y os_c efs_d efs_m efs_y efs_c frlage frlagec bl_wbcc bl_platc);*/
/*  set tmp13;*/
/*  length RIstum c1stum c2stum c3stum $2.  */
/*   dxtoreg dur_fcr os_d os_m os_y os_c efs_d efs_m efs_y efs_c frlage 8.*/
/*   frlagec bl_wbcc bl_platc dur_fcrc $120.;*/
/**/
/*  if RI_trstdt ne . then ristum="Y"; else ristum="N";*/
/*  if c1_trstdt ne . then c1stum="Y"; else c1stum="N";*/
/*  if c2_trstdt ne . then c2stum="Y"; else c2stum="N";*/
/*  if c3_trstdt ne . then c3stum="Y"; else c3stum="N";*/
/**/
/*  frlage = int(yrdif(brthdt, frldt, 'AGE'));*/
/*  if frlage=. then frlagec="";*/
/*  else if frlage<60 then frlagec="60歳未満";*/
/*  else frlagec="60歳以上";*/
/**/
/*  if bl_wbc=. then bl_wbcc="";*/
/*  else if bl_wbc<3000 then bl_wbcc="3,000/μL未満";*/
/*  else bl_wbcc="3,000/μL以上";*/
/**/
/*  if bl_plat=. then bl_platc="";*/
/*  else if bl_plat<5 then bl_platc="50,000/μL未満";*/
/*  else bl_platc="50,000/μL以上";*/
/**/
/*  dxtoreg =  (rfstdt - dxdt + 1)/365.25;*/
/*  dur_fcr = (frldt-rsdtc_bl1cr+1)/365.25;*/
/**/
/*  efs_d = efsdt - rfstdt + 1;*/
/*  efs_m = efs_d/(365.25/12);*/
/*  efs_y = efs_d / 365.25;*/
/*  os_d = osdt - rfstdt + 1;*/
/*  os_m = os_d / (365.25/12);*/
/*  os_y = os_d / 365.25;*/
/**/
/*  if dur_fcr=. then dur_fcrc="";*/
/*  else if dur_fcr<5 then dur_fcrc="5年未満";*/
/*  else dur_fcrc="5年以上";*/
/**/
/*label frlage  = "初回再発時年齢"*/
/*      frlagec = "初回再発時年齢カテゴリ"*/
/*      dxtoreg = "初発診断日から症例登録日までの期間（年）"*/
/*      dur_fcr = "初回寛解期間（年）"*/
/*	  dur_fcrc = "初回寛解期間（年）カテゴリ"*/
/*      efs_d   = "無イベント生存期間(日)"*/
/*      efs_m   = "無イベント生存期間(月)"*/
/*      efs_y   = "無イベント生存期間(年)"*/
/*      os_d    = "全生存期間(日)"*/
/*      os_m    = "全生存期間(月)"*/
/*      os_y    = "全生存期間(年)"*/
/*      os_c   = "OSイベント: 1=event, 0=打切り"*/
/*	  bl_wbcc = "Baseline 白血球数カテゴリ"*/
/*	  bl_platc = "Baseline 血小板数カテゴリ"*/
/*      RIstum = "再寛解導入療法開始有無"*/
/*      c1stum = "地固めサイクル1開始有無"*/
/*      c2stum = "地固めサイクル2開始有無"*/
/*      c3stum = "地固めサイクル3開始有無";*/
/*run;*/
/**/
/*proc sort data=tmp13; by usubjid; run;*/
/*proc sort data=tmp14; by usubjid; run;*/
/**/
/*data tmp15; */
/*  merge tmp13 tmp14; */
/*  by usubjid;*/
/*run;*/

data tmp11_dfs (keep = usubjid dfs_d dfs_m dfs_y dfs_c);
    set tmp11;

    /* 血液学的寛解(cr2hemyn='CR')の症例のみを対象とする */
    where cr1yn = 'CR';

    /* --- イベント（再発）の定義 --- */
    /* 血液学的第2再発(RL2type_hem='Y') 、分子学的第2再発(RL2type_mol='Y')または CNS第2再発(RL2type_cns='Y') があった場合 */
    if RLyn= 'Y' then do;
        DFS_d = RLdt - cr1yndt + 1;
        DFS_c = 1;
        end;
    else do;
        dfs_d = osdt - cr1yndt + 1;
        dfs_c = 0;
    end;

    if dfs_d ne . then do;
       dfs_m = dfs_d / (365.25 / 12);
       dfs_y = dfs_d / 365.25;
    end;

    /* 期間が負の値になった場合などは、関連する変数をすべて欠損値にする */
    if dfs_d <= 0 then call missing(dfs_d, dfs_m, dfs_y, dfs_c);

    label dfs_d = "無病生存期間(日)"
           dfs_m = "無病生存期間(月)"
           dfs_y = "無病生存期間(年)"
           dfs_c = "DFSイベントフラグ(1:イベント, 0:打切り)";
run;

proc sort data=tmp11_dfs; by usubjid; run;
proc sort data=tmp11; by usubjid; run;

data tmp12;
 merge tmp11 tmp11_dfs; by usubjid; run;

proc freq data=gml219;
tables i2_trstdt;run;


data gml219;
 set tmp12;
  length i1stum i2stum c1stum c2stum c3stum $2. ; 
  length daysto1cr daysf1crto1rl 8.;

  if i1_trstdt ne . then i1stum="Y"; else i1stum="N";
  if i2_trstdt ne . then i2stum="Y"; else i2stum="N";
  if c1_trstdt ne . then c1stum="Y"; else c1stum="N";
  if c2_trstdt ne . then c2stum="Y"; else c2stum="N";
  if c3_trstdt ne . then c3stum="Y"; else c3stum="N";

	if cr1yn ne 'CR' then do;
        daysto1cr=.;
		daysf1crto1rl=.;
	end;
    else do;
        daysto1cr=cr1yndt-i1_trstdt+1;
		if RLyn='Y' then daysf1crto1rl=RLdt-cr1yndt+1;
	end;

    label i1stum = "寛解導入療法1開始有無";
    label i2stum = "寛解導入療法2開始有無";
    label c1stum = "地固め療法1開始有無";
    label c2stum = "地固め療法2開始有無";
    label c3stum = "地固め療法3開始有無";
    label daysto1cr = "寛解導入療法1開始から寛解導入までの日数";
    label daysf1crto1rl = "寛解導入から再発までの日数";
run;

proc contents data=gml219; run;


proc sort data=tmp9; by usubjid; run;
proc sort data=tmp1d; by usubjid; run;

data gml219_sae;
  merge tmp9(in=a) tmp1d;
  by usubjid;
  if a;
run;


/*ADS output*/
*Excel file;
proc export
	data=work.gml219
	outfile= "&cwd.\input\ads\gml219.xlsx"
	dbms=xlsx
	replace;
run;

proc export
	data=work.gml219_sae
	outfile= "&cwd.\input\ads\gml219_sae.xlsx"
	dbms=xlsx
	replace;
run;

proc export
	data=work.outcome
	outfile= "&cwd.\input\ads\outcome.xlsx"
	dbms=xlsx
	replace;
run;


*CSVファイルでエクスポート;
proc export
	data=work.gml219
	outfile= "&cwd.\input\ads\gml219.csv"
	dbms=csv
	replace;
run;
proc export
	data=work.gml219_sae
	outfile= "&cwd.\input\ads\gml219_sae.csv"
	dbms=csv
	replace;
run;


*SASファイルでエクスポート;
libname adslib "&cwd.\input\ads";

proc copy in=work out=adslib;
    select gml219; 
run;

proc copy in=work out=adslib;
    select gml219_sae; 
run;


libname adslib clear;


/*不要なら最後削除*/
/**4つの日付データ(hmhstdt, mmhstdt, bl_cns_fadt, bl_ocns_fadt)から、最も早い日を frldt(第一再発日) を設定;*/
/*data tmp1g;*/
/*  set tmp1f; /* 元になるデータセットの読み込み */*/
/**/
/*  /* 4つの日付変数のうち、最も早い日付をfrldtに設定。*/
/*    min(of ...) 構文にて、リスト内の欠損値を無視して存在する日付の中から最小値を返す*/*/
/*  frldt = min(of hmhstdt, mmhstdt, bl_cns_fadt, bl_ocns_fadt);*/
/**/
/*  /* frldtの由来に応じて再発種別を決定 */*/
/*  length relapse_type $30;*/
/*  if frldt = hmhstdt   then relapse_type = "血液学的再発";*/
/*  else if frldt = mmhstdt  then relapse_type = "分子学的再発";*/
/*  else if frldt = bl_cns_fadt  then relapse_type = "CNS再発";*/
/*  else if frldt = bl_ocns_fadt then relapse_type = "その他の髄外再発";*/
/*  else relapse_type = "";*/
/**/
/*  format frldt yymmdd10.;*/
/*  label */
/*    frldt = "第一再発日"*/
/*    relapse_type = "第一再発種別";*/
/*run;*/;
