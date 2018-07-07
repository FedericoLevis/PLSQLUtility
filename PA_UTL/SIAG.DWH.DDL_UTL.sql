/* ==============================================================================
Generic script to create PA_UTL DB Objects 
SCHEMA: DWH    (Replace it if you want to use a different schema), TS: TS_DWH_KPIB_DATI
author: F.Levis (Apr 2018)
============================================================================== */


/*  ============================================================================
     SEQUENCE used by DWH.UTL_LOG  
 ============================================================================ */

BEGIN
   EXECUTE IMMEDIATE 'DROP SEQUENCE DWH.SEQ_LOG_ID';
EXCEPTION
   WHEN OTHERS THEN
     NULL;
END;
/

 
CREATE SEQUENCE DWH.SEQ_LOG_ID
  START WITH 1
  MAXVALUE 999999999
  MINVALUE 1
  CYCLE
  NOCACHE
  NOORDER;

/*  ============================================================================
     SEQUENCE used by DWH.UTL_LOG_STATUS  
 ============================================================================ */

BEGIN
   EXECUTE IMMEDIATE 'DROP SEQUENCE DWH.SEQ_LOG_STATUS_GROUP_ID';
EXCEPTION
   WHEN OTHERS THEN
     NULL;
END;
/

 
CREATE SEQUENCE DWH.SEQ_LOG_STATUS_GROUP_ID
  START WITH 1
  MAXVALUE 999999999
  MINVALUE 1
  CYCLE
  NOCACHE
  NOORDER;



  
/*  ============================================================================
     TABLE DWH.UTL_CFG for UTL configuration and to Store current values af variable parameteres
 ============================================================================ */

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE DWH.UTL_CFG CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN   RAISE;
      END IF;
END;
/

CREATE TABLE DWH.UTL_CFG
(
  PAR       VARCHAR2(32 BYTE)  NOT NULL, 
  VAL_NUM   NUMBER   DEFAULT 0, 
  VAL_DATE  DATE   DEFAULT NULL, 
  VAL_STR   VARCHAR2 (64 BYTE) DEFAULT NULL,
  DESCR     VARCHAR2 (1024 BYTE) DEFAULT NULL
);

comment on table DWH.UTL_CFG is 'LOG Configuration';
comment on column DWH.UTL_CFG.PAR is 'Parameter - E.g.: AGING_DAYS_LOG, ...';
comment on column DWH.UTL_CFG.VAL_NUM is 'Used if the Parameter has Numeric Value';
comment on column DWH.UTL_CFG.VAL_DATE is 'Used if the Parameter has Date Value';
comment on column DWH.UTL_CFG.VAL_STR is 'Used if the Parameter has String Value';
comment on column DWH.UTL_CFG.DESCR is 'Parameter Description ';


/*  ============================================================================
     TABLE DWH.UTL_LOG : Detail Log Table with Many Rows for the same LOG_ID
	 All the rows with the same LOG_ID belong to the same Call (one SP and its Sub Calls)
 ============================================================================ */

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE DWH.UTL_LOG CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN   RAISE;
      END IF;
END;
/

CREATE TABLE DWH.UTL_LOG
(
  FEATURE      VARCHAR2(32 BYTE)  NOT NULL, 
  SP           VARCHAR2(128 BYTE)  NOT NULL, 
  LOG_LEV      NUMBER    NOT NULL,
  LOG_TIME     TIMESTAMP NOT NULL,
  LOG_ID       NUMBER DEFAULT NULL,
  MSG          VARCHAR2(4000 BYTE) DEFAULT NULL, 
  MSG_CLOB     CLOB   DEFAULT NULL
)  
PARTITION BY RANGE (LOG_TIME) INTERVAL (NUMTODSINTERVAL(1,'DAY')) --- Daily Partition
 ( 
  PARTITION BASE_UTL_LOG VALUES LESS THAN (TO_DATE('2018-01-01','YYYY-MM-DD')) -- Initial Empty Partition, to be mantained
 )
TABLESPACE TS_DWH_KPIB_DATI
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          2M
            NEXT             2M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOLOGGING 
NOCOMPRESS 
NOCACHE
PARALLEL ( DEGREE DEFAULT INSTANCES DEFAULT )
MONITORING;


comment on table DWH.UTL_LOG is 'LOG Table -  see DWH.UTL_LOG_CFG to enable the LOG for a FEATURE';
comment on column DWH.UTL_LOG.FEATURE is 'Feature. E.g.: EXB.1';
comment on column DWH.UTL_LOG.SP is 'StoreProcedure Name that is  calling the LOG';
comment on column DWH.UTL_LOG.LOG_LEV is 'LOG_LEV: 0=ERRORE 1=WARNING 2=INFO 3=DEBUG 4=TRACE';
comment on column DWH.UTL_LOG.LOG_ID is 'Optionale ID - e.g useful to group all the call of the same group of call of a thread';
comment on column DWH.UTL_LOG.MSG is 'MSG logged. If > 4000 it is automatically put into MSG_CLOB';
comment on column DWH.UTL_LOG.MSG_CLOB is 'MSG > 4000';

/*  ============================================================================
     TABLE DWH.UTL_LOG_CFG - LOG Configuration: enable SP  LOG
 ============================================================================ */

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE DWH.UTL_LOG_CFG CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN   RAISE;
      END IF;
END;
/

CREATE TABLE DWH.UTL_LOG_CFG
(
  FEATURE      VARCHAR2(32 BYTE)  NOT NULL, 
  LOG_LEV      NUMBER    DEFAULT 0    NOT NULL 
);

comment on table DWH.UTL_LOG_CFG is 'LOG Configuration';
comment on column DWH.UTL_LOG_CFG.FEATURE is 'FEATURE used as first parameter in LOG';
comment on column DWH.UTL_LOG_CFG.LOG_LEV is 'LOG_LEV enable for the FEATURE: 0=ERRORS (Always enabled presente), 1= INFO, 2=DEBUG (and INFO), 3= TRACE, INFO, DEBUG';


/*  ============================================================================
     TABLE DWH.UTL_LOG_STATUS 
     1 Row Updated with the Current Status of an SP, identify by <LOG_ID , SP>	 
 ============================================================================ */

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE DWH.UTL_LOG_STATUS CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN   RAISE;
      END IF;
END;
/

CREATE TABLE DWH.UTL_LOG_STATUS
(
  LOG_ID       NUMBER DEFAULT 0,
  GROUP_ID     NUMBER DEFAULT 0,
  FEATURE      VARCHAR2(32 BYTE)  NOT NULL, 
  SP           VARCHAR2(128 BYTE)  NOT NULL, 
  START_DATE   DATE NOT NULL,
  LAST_DATE    DATE,
  ELAPSED_SEC  NUMBER,
  STATUS       VARCHAR2(128 BYTE) NOT NULL, 
  DETAIL       VARCHAR2(4000 BYTE) DEFAULT NULL, 
  DETAIL_CLOB  CLOB   DEFAULT NULL
)
PARTITION BY RANGE (START_DATE) INTERVAL (NUMTODSINTERVAL(1,'DAY')) --- Daily Partition
 ( 
  PARTITION BASE_UTL_LOG_STATUS VALUES LESS THAN (TO_DATE('2018-01-01','YYYY-MM-DD')) -- Initial Empty Partition, to be mantained
 )
TABLESPACE TS_DWH_KPIB_DATI
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          2M
            NEXT             2M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOLOGGING 
NOCOMPRESS 
NOCACHE
PARALLEL ( DEGREE DEFAULT INSTANCES DEFAULT )
MONITORING;

CREATE INDEX PK_LOG_STATUS ON DWH.UTL_LOG_STATUS (LOG_ID, GROUP_ID, SP ) LOCAL
TABLESPACE TS_DWH_KPIB_INDEX
NOLOGGING
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          1M
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );



comment on table DWH.UTL_LOG_STATUS is 'LOG Status Table: there is 1 rows for each LOG_ID, with the SP Status Updated during its evolution.';
comment on column DWH.UTL_LOG_STATUS.LOG_ID is '<LOG_ID, SP, GROUP_ID> identify the SP Status. LOG_ID=0 means LOG_ID NOT Meaningfull. LOG_ID can be correlated to UTL_LOG.LOG_ID records, if used';
comment on column DWH.UTL_LOG_STATUS.GROUP_ID is 'GROUP_ID can be opionally used to correlate together a GROUP of records, that belong to same Process spilitted into several parallel SP. GROUP_ID=0 means GROUP_ID NOT Meaningfull.';
comment on column DWH.UTL_LOG_STATUS.FEATURE is 'Feature (e.g KPI_BEAT)';
comment on column DWH.UTL_LOG_STATUS.SP is 'StoreProcedure (or Function) Name - e.g: ''KPIB_DETAIL KPIB30 1'' , ''KPIB_DETAIL KPIB30 5'', ... ';
comment on column DWH.UTL_LOG_STATUS.START_DATE is 'SP Start Date';
comment on column DWH.UTL_LOG_STATUS.LAST_DATE is 'SP Last Date, relative to Current STATUS';
comment on column DWH.UTL_LOG_STATUS.ELAPSED_SEC is 'Number of Elapsed Seconds (LAST_DATE - START_DATE)';
comment on column DWH.UTL_LOG_STATUS.STATUS is 'SP Current STATUS';
comment on column DWH.UTL_LOG_STATUS.DETAIL is 'Status Detail. If >  4000 it is automatically put into DETAIL_CLOB';
comment on column DWH.UTL_LOG_STATUS.DETAIL_CLOB is 'Status Detail, when LENGTH > 4000';



/*  ============================================================================
     TABLE DWH.UTL_LOG_TEST - Used only for TEST of PA_UTL with PA_UTL_TEST package
 ============================================================================ */

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE DWH.UTL_LOG_TEST CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN   RAISE;
      END IF;
END;
/

CREATE TABLE DWH.UTL_LOG_TEST
(
  PROCESS_ID   NUMBER,
  INSERT_DATE  DATE,  
  REC_ID  NUMBER
);








