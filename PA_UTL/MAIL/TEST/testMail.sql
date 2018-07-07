/**
<b>File:</b>            testLog.sql  </BR>
<b>Author:</b>          <a href="https://www.linkedin.com/in/federicolevis" target="_blank">Federico Levis</a>  </BR>
<b>Description:</b>   SQL to Test DWH.PA_UTL_MAIL  API
<b>NOTES:</b> We suppose to have installed DWH.PA_UTL into DWH schema </BR>
  If DWH.PA_UTL is in a different schema, you have simply to replace  DWH with the correct schema 
<b>REQUIRED:</b>       DWH.PA_UTL, DWH.PA_UTL_MAIL and its TABLES  </BR>
<b>Documentation:</b>  <a href="https://rawgit.com/FedericoLevis/PLSQLUtility/master/DWH.PA_UTL/README.md.html" target="_blank">DWH.PA_UTL Documentation</a>   </BR>
<b>First Version:</b>  ver 1.0 - May 2018   </BR>
<b>Current Version:</b>ver 1.0 - May 2018  </BR>
----------------------------------------------------------------------------------- </BR>
<b>DISCLAIMER</b> </BR>
Copyright by Federico Levis - <a href="https://github.com/FedericoLevis/PLSQLUtility" target="_blank">PL SQL Utilty</a>  </BR>
This file may be freely distributed under the MIT license.
*/


declare
  b_dbmsOut BOOLEAN  := TRUE; -- TRUE if you want to see in OUTPUT the LOG
  K_TEST_FEAT varchar2(32) := 'TST_MAIL';
  K_SP_TEST varchar2(64) := 'SP_TST_MAIL';  
  K_DEST_MAIL_1 varchar2 (128) := 'federico.levis@enel.com';
  n_logId NUMBER := DWH.pa_utl.LOG_ID_GET_NEXT(); -- Get the logId 
  r_mail_cfg DWH.pa_utl_mail.rec_mail_cfg;

  
begin
  IF (b_dbmsOut) THEN
    -- To avoid Buffer Overflow if we use 
    DBMS_OUTPUT.ENABLE (buffer_size => NULL);
  END IF;  
  -- WE CONFIGURE LOG LEVEL for TEST_FEAT
  DELETE FROM DWH.UTL_LOG_CFG WHERE FEATURE = K_TEST_FEAT;
  INSERT INTO DWH.UTL_LOG_CFG VALUES (K_TEST_FEAT,DWH.PA_UTL.LOG_LEV_TRACE);
  -- WE Configure UTL_MAIL_DEST_CFG for TEST_FEAT
  DELETE FROM DWH.UTL_MAIL_DEST_CFG  WHERE SP = K_SP_TEST;
  INSERT INTO DWH.UTL_MAIL_DEST_CFG (SP, DEST_EMAIL, DEST_TYPE, FLAG_SEND_OK) VALUES (K_SP_TEST,K_DEST_MAIL_1,'TO',1);  

  COMMIT;
  --
  
  -- dwh.pa_utl_mail_test.MAIL_STANDARD_ERR (K_TEST_FEAT,K_SP_TEST, n_logId, b_dbmsOut);
  dwh.pa_utl_mail_test.MAIL_STANDARD_INFO (
  p_feat =>K_TEST_FEAT
  ,p_app_sp => K_SP_TEST 
  ,p_logId => n_logId 
  ,p_dbmsOut => b_dbmsOut);

  dwh.pa_utl_mail_test.MAIL_STANDARD_ATTACH (
  p_feat =>K_TEST_FEAT
  ,p_app_sp => K_SP_TEST 
  ,p_dir => 'HB_KPIB_MAIL_FILE'
  ,p_file => '20180208_SLOT_4.csv'
  ,p_file_desc => 'POD Non presenti' 
  ,p_logId => n_logId 
  ,p_dbmsOut => b_dbmsOut);

  
EXCEPTION 
  WHEN OTHERS THEN
     dbms_output.put_line ('=============================================================================');
     dbms_output.put_line ('**************************** EXCEPTION TORNATA ****************************');
     dbms_output.put_line ('=============================================================================');
     dbms_output.put_line ('EXCEPTION ' ||  sqlerrm);

    
  
end;
/


-- SHOW UTL_LOG records of Last LOG_ID 
select * from DWH.utl_log log WHERE   LOG_ID = (select max (LOG_ID) from DWH.utl_log)   order by log_time;

