CREATE OR REPLACE PACKAGE DWH.PA_UTL_TEST IS


/**
<b>File:</b>            DWH.PA_UTL_TEST.sql  </BR>
<b>Author:</b>          <a href="https://www.linkedin.com/in/federicolevis" target="_blank">Federico Levis</a>  </BR>
<b>Description:</b>      Example of SP that uses PLSQL Utility Package PA_UTL to log into UTL_LOG
                       - Configure LOG of TEST_FEAT into UTL_LOG_CFGlog with various LOG_LEV to show that only LOG_LEV enabled will be logged </BR>
                       - log with various LOG_LEV </BR>
                       - log a very LONG message (len>4000) that will be automatically logged into UTL_LOG.MSG_CLOB column </BR>
                       - log_elapsed_sec and log_elapsed_msec </BR>
<b>NOTES:</b> We suppose that this Test and PA_UTL are in SGM schema (replace it if you are using a different SCHEMA) </BR>
If PA_UTL is in a different schema, you have simply to add PA_UTL schema owner in front of PA_UTL (e.g PA_UTL if PA_UTL is in DEM SCHEMA) </BR>
<b>REQUIRED:</b>       PA_UTL and its TABLES  </BR>
<b>Documentation:</b>  <a href="https://rawgit.com/FedericoLevis/PLSQLUtility/master/PA_UTL/README.md.html" target="_blank">PA_UTL Documentation</a>   </BR>
<b>First Version:</b>  ver 1.0 - Jan 2015   </BR>
<b>Current Version:</b>ver 2.1 - Jan 2017  </BR>
----------------------------------------------------------------------------------- </BR>
<b>DISCLAIMER</b> </BR>
Copyright by Federico Levis - <a href="https://github.com/FedericoLevis/PLSQLUtility" target="_blank">PL SQL Utilty</a>  </BR>
This file may be freely distributed under the MIT license.
*/



/**
 * TEST main LOG API: <ul>
 *  <li> log with various LOG_LEV </li>
 *  <li> log a very LONG message (len>4000) that will be automatically logged into UTL_LOG.MSG_CLOB column </li>
 *  <li> log_elapsed_sec and log_elapsed_msec </li>
 * </ul>
 * _param p_feature  varchar2                       identify log_feature in LOG Tables                      
 * _param p_log_rec_num NUMBER DEFAULT 10            Num REC to log in this test, at LOG_DEBUG
 * _param  p_generateSqlException DEFAULT FALSE      TRUE to generate an Exception that will be logged
 * _param  p_dbmsOut BOOLEAN DEFAULT FALSE           TRUE if you want to see in OUTPUT the LOG
 */
PROCEDURE TEST_LOG_API (
  p_feature  varchar2,
  p_log_rec_num NUMBER :=10, 
  p_generateSqlException BOOLEAN := FALSE, 
  p_dbmsOut BOOLEAN  := FALSE 
  ) ;






/**
 * TEST LOG of 2 instance of the same FUNCTION executed in parallel
 *
 * _param p_feature  varchar2                       identify log_feature in LOG Tables                      
 * _param [p_process_id]          IN NUMBER   := 1,..     Idendify Process
 * _param [n_rec_num] NUMBER := 10    Number of record to insert each 1 second into Table UTL_LOG_TEST
 */
PROCEDURE TEST_LOG_PARALLEL (
  p_feature  varchar2,
  p_process_id NUMBER :=1, 
  n_rec_num NUMBER := 10
  );
  

END PA_UTL_TEST;
/
CREATE OR REPLACE PACKAGE BODY DWH.PA_UTL_TEST IS

/**
<b>File:</b>          DWH.pa_utl.pck  </BR>
<b>Author:</b>        Federico Levis  </BR>
<b>Description:</b>   PLSQL Utility Package :
                       - LOG: log, log_elapsed_sec, log_elapsed_msec are used to log with various level (LOG_LEV_ERR,..,LOG_LEV_TRACE) into Table UTL_LOG  </BR>
                       - OTHER Utility Function: time_get_diff_sec, bool_to_varchar2,...  </BR>
<b>REQUIRED:</b>       UTL_LOG, UTL_CFG, UTL_LOG_CFG,  SEQ_LOG_ID  </BR>
<b>Documentation:</b>  <a href="https://rawgit.com/FedericoLevis/PLSqlUtility/master/PA_UTL/README.html" target="_blank">PA_UTL README.html</a>   </BR>
<b>First Version:</b>  ver 1.0 - Jan 2015   </BR>
<b>Current Version:</b>ver 2.0 - Jul 2016  </BR>
----------------------------------------------------------------------------------- </BR>
<b>DISCLAIMER</b> </BR>
Copyright by Federico Levis - <a href="https://github.com/JSUtility/PLSQLUtility" target="_blank">PL SQL Utilty</a>  </BR>
This file may be freely distributed under the MIT license.
*/


/* ------------------------------------------------------------------------------------------------
          CONSTANT
-------------------------------------------------------------------------------------------------*/

p_feature CONSTANT VARCHAR2(64) := 'LOG_TEST'; -- The Feature that identify this LOGS
K_NL CONSTANT VARCHAR2(4) := chr(10);

-- Constant not strictly required, but used only to have shorter constant in the CODE
LOG_LEV_ERR CONSTANT NUMBER := DWH.pa_utl.LOG_LEV_ERR;
LOG_LEV_WARN CONSTANT NUMBER := DWH.pa_utl.LOG_LEV_WARN;
LOG_LEV_INFO CONSTANT NUMBER := DWH.pa_utl.LOG_LEV_INFO;
LOG_LEV_DEBUG CONSTANT NUMBER := DWH.pa_utl.LOG_LEV_DEBUG;
LOG_LEV_TRACE CONSTANT NUMBER := DWH.pa_utl.LOG_LEV_TRACE;





/**
 * INSERT n_rec_num Record into UTL_LOG_TEST each 1 second, identified by p_process_id
 *
 * param  v_feat IN VARCHAR2      Log Feature 
 * param  n_logid IN NUMBER      Log Id
 * _param p_process_id  IN NUMBER  1,2 ..  Idendify Process
 * _param n_rec_num IN NUMBER      Number of record to insert and then extract in Table UTL_LOG_TEST
 * _return NUMBER DWH.pa_utl.ERR or DWH.pa_utl.OK
 */
PROCEDURE INSERT_TEST_REC (
  p_feature  IN VARCHAR2,
  n_logId IN NUMBER, 
  p_process_id IN NUMBER, 
  n_rec_num IN NUMBER
  ) 
IS
  K_SP VARCHAR2(100) := 'Id=' || p_process_id || ' INSERT_TEST_REC' ; -- Name of this SP
  t_startTime TIMESTAMP := CURRENT_TIMESTAMP; -- startTime with msec Precision
  v_stmt varchar2(1000);
--   b_FirstQry BOOLEAN  :=TRUE;
BEGIN

  DWH.pa_utl.log(LOG_LEV_INFO,p_feature, K_SP, 'START p_process_id=' || p_process_id,  n_logId);
  DWH.pa_utl.log(LOG_LEV_DEBUG,p_feature, K_SP, 'INSERT ' || n_rec_num || ' REC with a LONG LOOP',  n_logId);
  -- INSERT RECORD with a LONG LOOP
  BEGIN
    FOR i IN 1..n_rec_num LOOP
      v_stmt :=  'INSERT INTO DWH.UTL_LOG_TEST (PROCESS_ID,INSERT_DATE,REC_ID) VALUES (' || p_process_id || ',' ||
         DWH.pa_utl.sql_to_date (SYSDATE) || ',' || i || ')' ;
      DWH.pa_utl.log(LOG_LEV_DEBUG,p_feature, K_SP, 'QUERY= ' || K_NL || v_stmt,  n_logId);
      EXECUTE IMMEDIATE v_stmt;
	  -- NOTE: Commented because there is no privilege in some envirnoment
      -- dbms_lock.sleep( 1 ); 
      
    END LOOP;
    COMMIT;
    EXCEPTION WHEN OTHERS THEN
      
    DWH.pa_utl.log_exception (LOG_LEV_ERR, p_feature, K_SP, 'EXCEPTION - QRY =' || v_stmt ,  n_logId);
  END;  
  -- Log elapsed msec
  DWH.pa_utl.log_elapsed_msec(LOG_LEV_INFO,p_feature, K_SP, t_startTime,' END',  n_logId,TRUE);

END INSERT_TEST_REC;


/*----------------------------------------------------------------------
             GLOBAL API
------------------------------------------------------------------------*/             




/**
 * TEST main LOG API: <ul>
 *  <li> log with various LOG_LEV </li>
 *  <li> log a very LONG message (len>4000) that will be automatically logged into UTL_LOG.MSG_CLOB column </li>
 *  <li> log_elapsed_sec and log_elapsed_msec </li>
 *  <li> log query </li>
 *  <li> if p_generateSqlException=TRUE test  DWH.pa_utl.log_sql_exception </li>
 * </ul>
 *
 * _param p_feature  varchar2                       identify log_feature in LOG Tables                      
 * _param p_log_rec_num NUMBER DEFAULT 10            Num REC to log in this test, at LOG_DEBUG
 * _param  p_generateSqlException DEFAULT FALSE      TRUE to generate an Exception that will be logged with DWH.pa_utl.log_sql_exception
 * _param  p_dbmsOut BOOLEAN DEFAULT FALSE           TRUE if you want to see in OUTPUT the LOG
 */
PROCEDURE TEST_LOG_API (
  p_feature  varchar2,
  p_log_rec_num NUMBER :=10, 
  p_generateSqlException BOOLEAN := FALSE, 
  p_dbmsOut BOOLEAN  := FALSE 
  ) 
IS
  K_SP VARCHAR2(100) := 'TEST_LOG_API'; -- Name of this SP
  n_logId NUMBER := DWH.pa_utl.LOG_ID_GET_NEXT(); -- Get the logId
  d_startDate DATE:= SYSDATE; -- startDate with only Date 
  d_1week_ago DATE := SYSDATE -7;  -- 1 Week Ago (use in Test qry)
  n_val NUMBER := 1234567; -- to log a number for test
  v_long_msg varchar2(32000) :='';
  n_rec  NUMBER;
  v_stmt varchar2(1000);
  t_startTimeQry TIMESTAMP; -- startTime of QRY
BEGIN
  DWH.pa_utl.log(LOG_LEV_INFO,p_feature, K_SP,  
      'START IN p_feature=' || p_feature || ' p_log_rec_num='  || p_log_rec_num  || ' p_generateSqlException=' || DWH.pa_utl.bool_to_varchar2(p_generateSqlException) || ' p_dbmsOut=' || DWH.pa_utl.bool_to_varchar2(p_dbmsOut) , 
       n_logId, p_dbmsOut);
  DWH.pa_utl.log(LOG_LEV_DEBUG,p_feature, K_SP, 'TEST Log DEBUG with a ''Word Between dot'', with a value=' || n_val || n_val , n_logId,p_dbmsOut);
  DWH.pa_utl.log(LOG_LEV_ERR,p_feature, K_SP, 'Example of ERROR: it will be always logged if This Feature ' || p_feature || ' is configured in UTL_LOG_CFG (NO MATTER the realtive LOG_LEVEL Enabled) ', n_logId,p_dbmsOut);
  DWH.pa_utl.log(LOG_LEV_WARN,p_feature, K_SP, 'Example of WARNING',  n_logId,p_dbmsOut);
  
  FOR i IN 1..p_log_rec_num LOOP
    DWH.pa_utl.log(DWH.pa_utl.LOG_LEV_TRACE,p_feature, K_SP, 'Log at LOG_LEV_TRACE - Rec ' || i,  n_logId,p_dbmsOut);
  END LOOP;
  -- Prepare a long msg that will be logged in MSG_CLOB
  FOR i IN 1..300 LOOP
    v_long_msg := v_long_msg ||   'This is a Test of a very long message that will be logged into MSG_CLOB. This is the line' || i || K_NL;
  END LOOP;
  DWH.pa_utl.log(LOG_LEV_TRACE,p_feature, K_SP, v_long_msg,  n_logId,p_dbmsOut);
  -- QRY Example using DWH.pa_utl.sql_to_date : Get the number of LOGGED Record of the Last week
  BEGIN
     v_stmt :=  'SELECT COUNT(*) FROM DWH.UTL_LOG ' || K_NL || 
       ' WHERE LOG_TIME >= ' || DWH.pa_utl.sql_to_date(d_1week_ago);  
    IF (p_generateSqlException) THEN
      DWH.pa_utl.log(LOG_LEV_INFO,p_feature, K_SP, 'As required, now we will generate an Exception in Query, to show how we will log it',  n_logId, p_dbmsOut);
      v_stmt := v_stmt || ' AND COL_NOT_PRESENT = 0'; -- Generate an Exception to test DWH.pa_utl.log_sql_exception 
    END IF;  
    t_startTimeQry  := CURRENT_TIMESTAMP; -- startTime with msec Precision. Used to misure QryTime execution
    EXECUTE IMMEDIATE v_stmt INTO n_rec;
  EXCEPTION WHEN OTHERS THEN
    DWH.pa_utl.log_exception (LOG_LEV_ERR,  p_feature, K_SP, 'EXCEPTION in QUERY=' || K_NL || v_stmt,  n_logId,p_dbmsOut);
  END;
  -- log elapsed msec and QRY Information
  DWH.pa_utl.log_elapsed_msec(LOG_LEV_DEBUG,p_feature, K_SP, t_startTimeQry,
     ' GET ' || n_rec || ' REC with QUERY:'  || K_NL  || v_stmt,  n_logId,p_dbmsOut);
  -- Log elapsed sec
  DWH.pa_utl.log_elapsed_sec(LOG_LEV_INFO,p_feature, K_SP, d_startDate,' - END TEST',  n_logId,p_dbmsOut);
  -- Log elapsed msec
END TEST_LOG_API;





/**
 * Used to TEST LOG of Many instance of the same FUNCTION executed in parallel: call this function in parallel foirm different SQL Window.
 *  Example
 *  1) SQL Window 1    n_ret := DWH.PA_UTL_TEST.TEST_LOG_PARALLEL (1);
 *  2) SQL Window 2    n_ret := DWH.PA_UTL_TEST.TEST_LOG_PARALLEL (2);
 *  ...............................
 *
 * _param p_feature  varchar2                       identify log_feature in LOG Tables                      
 * _param [p_process_id]          IN NUMBER   := 1,..     Idendify Process
 * _param [n_rec_num] NUMBER := 10    Number of record to insert each 1 second into Table UTL_LOG_TEST
 */
PROCEDURE TEST_LOG_PARALLEL (
  p_feature varchar2,
  p_process_id NUMBER :=1, 
  n_rec_num NUMBER := 10
  ) 
IS
  K_SP VARCHAR2(100) := 'Id=' || p_process_id || ' TEST_LOG_PARALLEL'; -- Name of this SP
  n_logId NUMBER := DWH.pa_utl.LOG_ID_GET_NEXT(); -- Get the logId
  t_startTime TIMESTAMP := CURRENT_TIMESTAMP; -- startTime with msec Precision
BEGIN

  DWH.pa_utl.log(LOG_LEV_INFO, p_feature, K_SP, 'START IN p_feature=' || p_feature || ' p_process_id=' || p_process_id || ' n_rec_num=' || n_rec_num,  n_logId);
  INSERT_TEST_REC (p_feature, n_logId,p_process_id,n_rec_num);
  -- Log elapsed msec
  DWH.pa_utl.log_elapsed_msec(LOG_LEV_INFO, p_feature, K_SP, t_startTime,' END ' ,  n_logId,TRUE);
END;




END PA_UTL_TEST;
/
