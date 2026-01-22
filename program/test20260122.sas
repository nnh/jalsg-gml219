proc import
    datafile='C:\Users\c0002691\Documents\GitHub\jalsg-gml219\input\rawdata\AE.csv'
    out=raw_ae dbms=csv replace;
    getnames=yes;
    guessingrows=max;
run;

proc import
    datafile='C:\Users\c0002691\Documents\GitHub\jalsg-gml219\input\rawdata\dm.csv'
    out=raw_dm dbms=csv replace;
    getnames=yes;
    guessingrows=max;
run;

/* raw_dmとraw_aeをUSUBJIDで左結合 */
proc sql;
    create table dm_ae_merged as
    select dm.*
        , ae.STUDYID as AE_STUDYID
        , ae.DOMAIN as AE_DOMAIN
        , ae.USUBJID as AE_USUBJID
        , ae.AETERM
        , ae.AELLTCD
        , ae.AETOXGR
    from raw_dm as dm
    left join raw_ae as ae
    on dm.USUBJID = ae.USUBJID;
quit;

proc print data=work.dm_ae_merged(obs=20);
run;



/* AEデータセットのAETERMのユニーク一覧を取得 */
proc sql;
    create table unique_aeterm as select distinct AETERM, AELLTCD from raw_ae;
quit;



/* AELLTCD, AETOXGR毎の件数を集計 */
proc sql;
    create table count_aelltcd_aetoxgr as select AELLTCD, AETOXGR, AETERM,
        count(*) as CNT from raw_ae group by AELLTCD, AETOXGR, AETERM;
quit;

proc print data=work.dm_ae_merged;
    where USUBJID in ("GML219-0060", "GML219-0090");
run;



/* USUBJIDが重複しているオブザベーションを抽出 */
proc sql;
    create table duplicated_usubjid as
    select * from dm_ae_merged
    where USUBJID in (
        select USUBJID from dm_ae_merged
        group by USUBJID
        having count(*) > 1
    );
quit;



proc print data=work.duplicated_usubjid(obs=20);
run;

/* dm_ae_mergedからAETERM、AELLTCD、AETOXGR毎にUSUBJIDベースで集計し、件数とパーセントを算出 */
proc sql;
    /* 分母となるUSUBJIDのユニーク数を取得 */
    select count(distinct USUBJID) into :total_usubjid from dm_ae_merged;
quit;

proc sql;
    create table summary_aeterm as
    select AETERM, AELLTCD, AETOXGR,
           count(distinct USUBJID) as CNT,
           calculated CNT / &total_usubjid * 100 as PCT format=6.2
    from dm_ae_merged
    group by AETERM, AELLTCD, AETOXGR;
quit;

proc print data=summary_aeterm;
run;
