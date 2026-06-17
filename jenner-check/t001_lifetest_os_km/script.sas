/**********************************************************************
* Adapted from: program/JALSG-GML219_STAT_Fig5_4.4.4a.OS.sas
* Original author: AKIKO SAITO  (JALSG-GML219)
*
* Overall Survival (OS) Kaplan-Meier analysis for the FAS population.
* This is the analysis core of the upstream Fig5 program: PROC LIFETEST
* produces the survival estimates, OUTSURV= captures the survival
* function, and a small macro reads off the 1/2/3/5-year point
* estimates with their 95% confidence limits.
*
* The only changes from the original are mechanical: the Windows
* libname / %working_dir / proc printto / ods rtf plumbing that points
* at a local analyst machine has been removed, and GML219 is supplied
* by the bundle autoexec instead of read from libraw.  The survival
* logic, OUTSURV handling, the %km_pt macro and the PROC PRINT are
* exactly as written upstream.
**********************************************************************/

data FAS;
  set gml219;
  where FASFL = "Y";
run;

TITLE1 'JALSG-GML219';
title2 'Overall Survival (2yr / 5yr)';
title3 'Analysis population: FAS';

/*--- Kaplan-Meier estimates ---*/
proc lifetest data=FAS plots=survival notable;
  time OS_y*os_c(0);
run;

/*--- Point estimates by year ---*/
title2 'OS point estimates';
title3 ' ';

ods select none;
proc lifetest data=FAS alpha=0.05 outsurv=_surv0;
  time OS_y*os_c(0);
run;
ods select all;

%macro km_pt(yr);
  data _s&yr.y;
    set _surv0;
    where OS_y <= &yr.;
  run;
  proc sort data=_s&yr.y; by OS_y; run;
  data _e&yr.y(keep=year survival SDF_LCL SDF_UCL);
    set _s&yr.y end=last;
    if last;
    year = &yr.;
  run;
%mend;
%km_pt(1); %km_pt(2); %km_pt(3); %km_pt(5);

data os_est;
  set _e1y _e2y _e3y _e5y;
run;

proc print data=os_est label noobs;
  label year='Year' survival='Survival' SDF_LCL='95%CI Lower' SDF_UCL='95%CI Upper';
  var year survival SDF_LCL SDF_UCL;
  format survival SDF_LCL SDF_UCL 8.4;
run;
