/* ==============================================================================
Generic script to create PA_UTL_MAIL DB Objects 
SCHEMA: DWH    (Replace it if you want to use a different schema), TS: TS_DWH_KPIB_DATI
author: F.Levis (May 2018)
============================================================================== */





  
/*  ============================================================================
     TABLE DWH.UTL_MAIL_CFG for UTL_MAIL configuration 
 ============================================================================ */

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE DWH.UTL_MAIL_CFG CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE DWH.UTL_MAIL_CFG
(
  PAR       VARCHAR2(32 BYTE)  NOT NULL, 
  VAL_NUM   NUMBER   DEFAULT 0, 
  VAL_DATE  DATE   DEFAULT NULL, 
  VAL_STR   VARCHAR2 (64 BYTE) DEFAULT NULL,
  DESCR     VARCHAR2 (1024 BYTE) DEFAULT NULL
);

comment on table DWH.UTL_MAIL_CFG is 'UTL_MAIL Configuration (SMTP_SERVER,...)';
comment on column DWH.UTL_MAIL_CFG.PAR is 'Parameter - E.g.: SMTP SERVER NAME';
comment on column DWH.UTL_MAIL_CFG.VAL_NUM is 'Used if the Parameter has Numeric Value';
comment on column DWH.UTL_MAIL_CFG.VAL_DATE is 'Used if the Parameter has Date Value';
comment on column DWH.UTL_MAIL_CFG.VAL_STR is 'Used if the Parameter has String Value. E.g: smtp-mi.risorse.enel';
comment on column DWH.UTL_MAIL_CFG.DESCR is 'Parameter Description ';


/*  ============================================================================
     TABLE DWH.UTL_MAIL_DEST_CFG:  Configuration of email dest  for each SP 
 ============================================================================ */

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE DWH.UTL_MAIL_DEST_CFG CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/

 
create table DWH.UTL_MAIL_DEST_CFG
(
  sp                      varchar2(128),
  dest_email              VARCHAR2(200),
  dest_type               varchar2(8) DEFAULT 'TO',
  flag_send_ok            NUMBER DEFAULT (1),
  flag_attach             NUMBER DEFAULT (1)
);

comment on table DWH.UTL_MAIL_DEST_CFG is 'UTL_MAIL Configuration (SMTP_SERVER,...)';
comment on column DWH.UTL_MAIL_DEST_CFG.SP is 'Store Procedure calling the EMAIL. E.G: kpib_monitor_au';
comment on column DWH.UTL_MAIL_DEST_CFG.DEST_EMAIL is 'email dest';
comment on column DWH.UTL_MAIL_DEST_CFG.DEST_TYPE is ' ''TO'' or ''CC'' ';
comment on column DWH.UTL_MAIL_DEST_CFG.FLAG_SEND_OK is '1= Send if status_code=OK.  0=DO NOT SEND when status_code=OK';
comment on column DWH.UTL_MAIL_DEST_CFG.FLAG_ATTACH is '1= Add Attcahment if present.  0=NEVER add attachment';




