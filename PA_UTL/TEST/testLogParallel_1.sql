/**
<b>File:</b>            testLogParallel_1.sql  </BR>
<b>Author:</b>          <a href="https://www.linkedin.com/in/federicolevis" target="_blank">Federico Levis</a>  </BR>
<b>Description:</b>   SQL to call SGM.PA_UTL_TEST.TEST_LOG_API qeith various cases
<b>NOTES:</b> We suppose to have installed SGM.PA_UTL into SGM schema </BR>
  If SGM.PA_UTL is in a different schema, you have simply to replace  SGM with the correct schema 
<b>REQUIRED:</b>       SGM.PA_UTL and its TABLES  </BR>
<b>Documentation:</b>  <a href="https://rawgit.com/FedericoLevis/PLSQLUtility/master/SGM.PA_UTL/README.md.html" target="_blank">SGM.PA_UTL Documentation</a>   </BR>
<b>First Version:</b>  ver 1.0 - Jan 2015   </BR>
<b>Current Version:</b>ver 2.1 - Gen 2018  </BR>
----------------------------------------------------------------------------------- </BR>
<b>DISCLAIMER</b> </BR>
Copyright by Federico Levis - <a href="https://github.com/FedericoLevis/PLSQLUtility" target="_blank">PL SQL Utilty</a>  </BR>
This file may be freely distributed under the MIT license.
*/


declare
  K_PROCESS_ID CONSTANT NUMBER := 1; -- Identify THIS Process
  K_REC_NUM CONSTANT NUMBER := 10;
  n_res NUMBER; 
  n_log_num NUMBER;  
-- ==============================================  FIXED CONSTANT
  K_TEST_FEAT CONSTANT VARCHAR2(64) := 'LOG_TEST_PARALLEL'; -- The Feature that identify this LOGS
  n_ret NUMBER;
  n_cfg_log_lev NUMBER := SGM.pa_utl.LOG_LEV_TRACE;
begin
    
  -- If required WE CONFIGURE LOG LEVEL for TEST_FEAT
  SELECT count(*) INTO n_log_num FROM SGM.UTL_LOG_CFG WHERE FEATURE = K_TEST_FEAT;
  IF (n_log_num = 0) THEN
    INSERT INTO SGM.UTL_LOG_CFG VALUES (K_TEST_FEAT,n_cfg_log_lev);
    COMMIT;
  END IF;  
  -- Call the procedure that insert K_REC_NUM into LOG_UTL_TEST
  n_ret := SGM.pa_utl_test.TEST_LOG_PARALLEL(K_TEST_FEAT,K_PROCESS_ID ,K_REC_NUM);
  
end;
/


-- SHOW UTL_LOG records of Last 2 LOG_ID of only THIS FEATURE (they could have run inparallel and they acould be mixed)
select * from SGM.utl_log log WHERE
-- only TEST_FEAT
  FEATURE = 'LOG_TEST_PARALLEL' 
-- Last LOG_ID
  AND LOG_ID >= (select max (LOG_ID) from SGM.utl_log) -1
  -- Try different LOG_LEV FILTER
  AND LOG_LEV <= 4
  -- AND LOG_LEV <= 3
  -- AND LOG_LEV <= 2
  order by log_time;

