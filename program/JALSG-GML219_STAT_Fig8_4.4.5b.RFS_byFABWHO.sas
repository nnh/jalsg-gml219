**********************************************************************;
* Project      : JALSG-GML219
* Program name : JALSG-GML219_STAT_Fig8_4.4.5b.RFS_byFABWHO.sas
* Author       : AKIKO SAITO
* Date created : 20260504
* Description  : FAB/WHO分類別 2年・5年RFS (FAS + CR到達例) (SAP 4.4.5b)
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

proc printto log="&log.\JALSG-GML219_STAT_Fig8_&DATE..log" new; run;

options validvarname=v7 fmtsearch=(libout work) nofmterr
        nomlogic nosymbolgen nomprint ls=100 missing="" pageno=1
        nodate nonumber;

data gml219;
  set libraw.gml219;
run;

data FAS_cr;
  set gml219;
  where FASFL = "Y" and crfl = "Y";
run;

TITLE1 'JALSG-GML219';

ods rtf file="&output.\JALSG-GML219 Fig8_&DATE..rtf" style=listing;
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

/*--- FAB分類別 RFS ---*/
title2 'FAB分類別 Relapse-free Survival（2年・5年）';
title3 '解析対象集団: FAS CR到達例  分類: M0/M6/M7/Unknown vs Others';

ods graphics on / width=18cm height=14cm imagename="Fig8_RFS_byFAB";
proc lifetest data=FAS_cr(where=(fabgrp ne "")) plots=survival(atrisk cl) notable;
  time RFS_y*rfs_c(0);
  strata fabgrp;
run;
ods graphics off;

title2 'RFS 時点別推定値（FAB分類別）';
title3 ' ';

ods select none;
proc lifetest data=FAS_cr(where=(fabgrp ne "")) alpha=0.05 outsurv=_surv_fab;
  time RFS_y*rfs_c(0);
  strata fabgrp;
run;
ods select all;

%km_strata(_surv_fab, RFS_y, fabgrp, 2);
%km_strata(_surv_fab, RFS_y, fabgrp, 5);
data fab_est; set _e2y _e5y; run;
proc sort data=fab_est; by fabgrp year; run;
proc print data=fab_est label noobs;
  label year='経過年数' survival='生存率' SDF_LCL='95%CI下限' SDF_UCL='95%CI上限';
  var fabgrp year survival SDF_LCL SDF_UCL;
  format survival SDF_LCL SDF_UCL 8.4;
run;

/*--- WHO分類別 RFS ---*/
title2 'WHO分類別 Relapse-free Survival（2年・5年）';
title3 '解析対象集団: FAS CR到達例  分類: t-MN / AML-MRC / Others';

ods graphics on / width=18cm height=14cm imagename="Fig8_RFS_byWHO";
proc lifetest data=FAS_cr(where=(whogrp ne "")) plots=survival(atrisk cl) notable;
  time RFS_y*rfs_c(0);
  strata whogrp;
run;
ods graphics off;

title2 'RFS 時点別推定値（WHO分類別）';
title3 ' ';

ods select none;
proc lifetest data=FAS_cr(where=(whogrp ne "")) alpha=0.05 outsurv=_surv_who;
  time RFS_y*rfs_c(0);
  strata whogrp;
run;
ods select all;

%km_strata(_surv_who, RFS_y, whogrp, 2);
%km_strata(_surv_who, RFS_y, whogrp, 5);
data who_est; set _e2y _e5y; run;
proc sort data=who_est; by whogrp year; run;
proc print data=who_est label noobs;
  label year='経過年数' survival='生存率' SDF_LCL='95%CI下限' SDF_UCL='95%CI上限';
  var whogrp year survival SDF_LCL SDF_UCL;
  format survival SDF_LCL SDF_UCL 8.4;
run;

ods rtf close;
proc printto; run;