**********************************************************************;
* Project      : JALSG-GML219
* Program name : JALSG-GML219_STAT_Fig1_4.4.1a.EFS2yr_FAS.sas
* Author       : AKIKO SAITO
* Date created : 20260504
* Description  : 2年Event-free survival (FAS)【主要エンドポイント】(SAP 4.4.1a)
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

proc printto log="&log.\JALSG-GML219_STAT_Fig1_&DATE..log" new; run;

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

TITLE1 'JALSG-GML219';

ods rtf file="&output.\JALSG-GML219 Fig1_&DATE..rtf" style=listing;
ods escapechar='^';
footnote2 "^S={just=r} 出力日 &DATE";

/*--- KMカーブ（リスク数付き） ---*/
title2 'Event-free Survival（2年・主要エンドポイント）';
title3 '解析対象集団: FAS';

ods graphics on / width=18cm height=14cm imagename="Fig1_EFS2yr_FAS";
proc lifetest data=FAS plots=survival(atrisk cl) notable;
  time EFS_y*efs_c(0);
run;
ods graphics off;

/*--- 時点別生存率（1・2・3・5年） ---*/
title2 'EFS 時点別推定値';
title3 ' ';

ods select none;
proc lifetest data=FAS alpha=0.05 outsurv=_surv0;
  time EFS_y*efs_c(0);
run;
ods select all;

%macro km_pt(yr);
  data _s&yr.y;
    set _surv0;
    where EFS_y <= &yr.;
  run;
  proc sort data=_s&yr.y; by EFS_y; run;
  data _e&yr.y(keep=year survival SDF_LCL SDF_UCL);
    set _s&yr.y end=last;
    if last;
    year = &yr.;
  run;
%mend;
%km_pt(1); %km_pt(2); %km_pt(3); %km_pt(5);

data efs_est;
  set _e1y _e2y _e3y _e5y;
run;

proc print data=efs_est label noobs;
  label year='経過年数' survival='生存率' SDF_LCL='95%CI下限' SDF_UCL='95%CI上限';
  var year survival SDF_LCL SDF_UCL;
  format survival SDF_LCL SDF_UCL 8.4;
run;

ods rtf close;
proc printto; run;