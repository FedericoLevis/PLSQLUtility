/*  ============================================================================
     TABLE DWH.UTL_MAIL_CFG initialization/configuration
 ============================================================================ */

 
delete from DWH.UTL_MAIL_CFG ;

INSERT INTO DWH.UTL_MAIL_CFG (PAR,VAL_NUM,VAL_DATE,VAL_STR, DESCR) VALUES ('SMTP SERVER NAME',NULL,NULL,'smtp-mi.risorse.enel','SMTP SERVER NAME');  
INSERT INTO DWH.UTL_MAIL_CFG (PAR,VAL_NUM,VAL_DATE,VAL_STR, DESCR) VALUES ('SMTP SERVER PORT',25,NULL,NULL,'SMTP SERVER PORT');  
INSERT INTO DWH.UTL_MAIL_CFG (PAR,VAL_NUM,VAL_DATE,VAL_STR, DESCR) VALUES ('DIRECTORY CSS',NULL,NULL,'HB_MAIL_CSS','DEFAULT DIRECTORY with css style file for mail');  
INSERT INTO DWH.UTL_MAIL_CFG (PAR,VAL_NUM,VAL_DATE,VAL_STR, DESCR) VALUES ('FILE CSS',NULL,NULL,'mail.css','DEFAULT CSS FILE with <style>');  


COMMIT;

