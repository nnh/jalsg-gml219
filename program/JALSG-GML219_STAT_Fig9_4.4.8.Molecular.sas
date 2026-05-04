**********************************************************************;
* Project      : JALSG-GML219
* Program name : JALSG-GML219_STAT_Fig9_4.4.8.Molecular.sas
* Author       : AKIKO SAITO
* Date created : 20260504
* Description  : 分子病型別（FLT3-ITD/NPM1/Other）RFS・OS・EFS (SAP 4.4.8)
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

proc printto log="&log.\JALSG-GML219_STAT_Fig9_&DATE..log" new; run;

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

ods rtf file="&output.\JALSG-GML219 Fig9_&DATE..rtf" style=listing;
ods escapechar='^';
footnote2 "^S={just=r} 出力日 &DATE";

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

/*--- 分子病型別 RFS (CR到達例) ---*/
title2 '分子病型別 Relapse-free Survival（2年・5年）';
title3 '解析対象集団: FAS CR到達例  分類: FLT3-ITD / NPM1 / Other';

ods graphics on / width=18cm height=14cm imagename="Fig9_RFS_byMolGrp";
proc lifetest data=FAS_cr plots=survival(atrisk cl) notable;
  time RFS_y*rfs_c(0);
  strata molgrp;
run;
ods graphics off;

title2 'RFS 時点別推定値（分子病型別）';
title3 ' ';
ods select none;
proc lifetest data=FAS_cr alpha=0.05 outsurv=_surv_mol;
  time RFS_y*rfs_c(0);
  strata molgrp;
run;
ods select all;
%km_strata(_surv_mol, RFS_y, molgrp, 2);
%km_strata(_surv_mol, RFS_y, molgrp, 5);
data mol_rfs_est; set _e2y _e5y; run;
proc sort data=mol_rfs_est; by molgrp year; run;
proc print data=mol_rfs_est label noobs;
  label year='経過年数' survival='生存率' SDF_LCL='95%CI下限' SDF_UCL='95%CI上限';
  var molgrp year survival SDF_LCL SDF_UCL;
  format survival SDF_LCL SDF_UCL 8.4;
run;

/*--- 分子病型別 OS ---*/
title2 '分子病型別 Overall Survival（2年・5年）';
title3 '解析対象集団: FAS  分類: FLT3-ITD / NPM1 / Other';

ods graphics on / width=18cm height=14cm imagename="Fig9_OS_byMolGrp";
proc lifetest data=FAS plots=survival(atrisk cl) notable;
  time OS_y*os_c(0);
  strata molgrp;
run;
ods graphics off;

title2 'OS 時点別推定値（分子病型別）';
title3 ' ';
ods select none;
proc lifetest data=FAS alpha=0.05 outsurv=_surv_mol;
  time OS_y*os_c(0);
  strata molgrp;
run;
ods select all;
%km_strata(_surv_mol, OS_y, molgrp, 2);
%km_strata(_surv_mol, OS_y, molgrp, 5);
data mol_os_est; set _e2y _e5y; run;
proc sort data=mol_os_est; by molgrp year; run;
proc print data=mol_os_est label noobs;
  label year='経過年数' survival='生存率' SDF_LCL='95%CI下限' SDF_UCL='95%CI上限';
  var molgrp year survival SDF_LCL SDF_UCL;
  format survival SDF_LCL SDF_UCL 8.4;
run;

/*--- 分子病型別 EFS ---*/
title2 '分子病型別 Event-free Survival（2年・5年）';
title3 '解析対象集団: FAS  分類: FLT3-ITD / NPM1 / Other';

ods graphics on / width=18cm height=14cm imagename="Fig9_EFS_byMolGrp";
proc lifetest data=FAS plots=survival(atrisk cl) notable;
  time EFS_y*efs_c(0);
  strata molgrp;
run;
ods graphics off;

title2 'EFS 時点別推定値（分子病型別）';
title3 ' ';
ods select none;
proc lifetest data=FAS alpha=0.05 outsurv=_surv_mol;
  time EFS_y*efs_c(0);
  strata molgrp;
run;
ods select all;
%km_strata(_surv_mol, EFS_y, molgrp, 2);
%km_strata(_surv_mol, EFS_y, molgrp, 5);
data mol_efs_est; set _e2y _e5y; run;
proc sort data=mol_efs_est; by molgrp year; run;
proc print data=mol_efs_est label noobs;
  label year='経過年数' survival='生存率' SDF_LCL='95%CI下限' SDF_UCL='95%CI上限';
  var molgrp year survival SDF_LCL SDF_UCL;
  format survival SDF_LCL SDF_UCL 8.4;
run;

ods rtf close;
proc printto; run;