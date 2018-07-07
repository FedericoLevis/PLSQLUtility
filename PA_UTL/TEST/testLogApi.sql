/**
<b>File:</b>            testLog.sql  </BR>
<b>Author:</b>          <a href="https://www.linkedin.com/in/federicolevis" target="_blank">Federico Levis</a>  </BR>
<b>Description:</b>   SQL to call DWH.PA_UTL_TEST.TEST_LOG_API qeith various cases
<b>NOTES:</b> We suppose to have installed DWH.PA_UTL into SGM schema </BR>
  If DWH.PA_UTL is in a different schema, you have simply to replace  SGM with the correct schema 
<b>REQUIRED:</b>       DWH.PA_UTL and its TABLES  </BR>
<b>Documentation:</b>  <a href="https://rawgit.com/FedericoLevis/PLSQLUtility/master/DWH.PA_UTL/README.md.html" target="_blank">DWH.PA_UTL Documentation</a>   </BR>
<b>First Version:</b>  ver 1.0 - Jan 2015   </BR>
<b>Current Version:</b>ver 2.0 - Jul 2016  </BR>
----------------------------------------------------------------------------------- </BR>
<b>DISCLAIMER</b> </BR>
Copyright by Federico Levis - <a href="https://github.com/FedericoLevis/PLSQLUtility" target="_blank">PL SQL Utilty</a>  </BR>
This file may be freely distributed under the MIT license.
*/


declare
  p_test NUMBER := &1;   
  -- 
  -- 1   Test Generic
  -- 2   Test of ERRORS and SQL EXCEPTION
-- ==============================================  FIXED CONSTANT
  K_TEST_FEAT CONSTANT VARCHAR2(64) := 'LOG_TEST'; -- The Feature that identify this LOGS
-- =========================== VAR
  n_log_rec_num NUMBER :=10; -- Num REC to log in this test, at LOG_DEBUG
  -- ----------------- TRY to enable different LOG Level
  n_cfg_log_lev NUMBER := DWH.pa_utl.LOG_LEV_TRACE;
  -- n_cfg_log_lev NUMBER := pa_utl.LOG_LEV_DEBUG;
  -- -----------------
  b_dbmsOut BOOLEAN  := FALSE; -- TRUE if you want to see in OUTPUT the LOG
  b_generateSqlException BOOLEAN := FALSE; -- TRUE to generate an Exception that will be logged with pa_utl.log_sql_exception
  b_test_aging BOOLEAN := false;  -- set TRUE to TEST aging
begin
  CASE p_test
    WHEN 1 THEN -- Enable TRACE LEV. Log 10 Rec. Enable b_dbmsOut 
      n_log_rec_num := 5;
      n_cfg_log_lev := DWH.pa_utl.LOG_LEV_TRACE; 
      b_dbmsOut := TRUE;
      b_generateSqlException := FALSE;
    WHEN 2 THEN -- Enable ONLY INFO and ERROR and set b_generateSqlException 
      n_log_rec_num := 3;
      n_cfg_log_lev := DWH.pa_utl.LOG_LEV_INFO; 
      b_dbmsOut := FALSE;
      b_generateSqlException:=TRUE;
    ELSE NULL;  -- default case
  END CASE;  
    
  -- =================================================================== 
  -- TEST CONFIGURATION, to try different cases
  -- =================================================================== 
  IF (b_dbmsOut) THEN
    -- To avoid Buffer Overflow if we use 
    DBMS_OUTPUT.ENABLE (buffer_size => NULL);
  END IF;  
  -- WE CONFIGURE LOG LEVEL for TEST_FEAT
  DELETE FROM DWH.UTL_LOG_CFG WHERE FEATURE = K_TEST_FEAT;
  INSERT INTO DWH.UTL_LOG_CFG VALUES (K_TEST_FEAT,n_cfg_log_lev);
  COMMIT;
  -- to test the aging we set an old date into AGING_LOG_LAST_DATE
  if (b_test_aging) THEN
    UPDATE DWH.UTL_CFG SET VAL_DATE = SYSDATE-100 WHERE PAR = 'AGING_LOG_LAST_DATE';
    COMMIT;
  END IF;  
  -- Call the procedure
  
  DWH.pa_utl_test.TEST_LOG_API(K_TEST_FEAT,n_log_rec_num,b_generateSqlException,b_dbmsOut);
  
end;
/


-- SHOW UTL_LOG records of Last LOG_ID 
select * from DWH.utl_log log WHERE
-- only TEST_FEAT
  FEATURE = 'LOG_TEST' 
-- Last LOG_ID
  AND LOG_ID = (select max (LOG_ID) from DWH.utl_log) 
  -- Try different LOG_LEV FILTER
  AND LOG_LEV <= 4
  -- AND LOG_LEV <= 3
  -- AND LOG_LEV <= 2
  order by log_time;

