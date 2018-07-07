CREATE OR REPLACE PACKAGE DWH.PA_UTL
    AUTHID DEFINER
IS

/**
<b>File:</b>              PA_UTL.pck  </BR>
<b>Author:</b>          <a href="https://www.linkedin.com/in/federicolevis" target="_blank">Federico Levis</a>  </BR>
<b>Description:</b>   PLSQL Utility Package :
                       - LOG: log, log_elapsed_sec, log_elapsed_msec are used to log with various level (LOG_LEV_ERR,..,LOG_LEV_TRACE) into Table UTL_LOG  </BR>
                       - OTHER Utility Function: time_diff_sec, bool_to_varchar2,...  </BR>
<b>REQUIRED:</b>       UTL_LOG, UTL_CFG, UTL_LOG_CFG,  SEQ_LOG_ID  </BR>
<b>Documentation:</b>  <a href="https://rawgit.com/FedericoLevis/PLSQLUtility/master/PA_UTL/README.md.html" target="_blank">PA_UTL Documentation</a>   </BR>
<b>First Version:</b>  ver 1.0 - Jan 2015   </BR>
<b>Current Version:</b>ver 3.2 - 08 May 2018  (NB: Changed Interface) </BR>
----------------------------------------------------------------------------------- </BR>
<b>DISCLAIMER</b> </BR>
Copyright by Federico Levis - <a href="https://github.com/FedericoLevis/PLSQLUtility" target="_blank">PL SQL Utilty</a>  </BR>
This file may be freely distributed under the MIT license.
*/





  /* ==================================================================================
                      CONSTANT
  ================================================================================== */
  /**  LogLev for ERRORS  */
  LOG_LEV_ERR CONSTANT NUMBER :=0;
  /**  LogLev for WARNING  */
  LOG_LEV_WARN CONSTANT NUMBER :=1;
  /**  LogLev for INFO: important information  */
  LOG_LEV_INFO CONSTANT NUMBER :=2;
  /**  LogLev for DEBUG  */
  LOG_LEV_DEBUG CONSTANT NUMBER :=3;
  /**  LogLev for TRACE: Detailed Log used by developers */
  LOG_LEV_TRACE CONSTANT NUMBER :=4;
  /**  NO LOG */
  LOG_LEV_NOLOG CONSTANT NUMBER :=999;


  /**  Standard for utl_log_status.status */
  LOG_STATUS_OK  constant varchar2 (16) := 'OK';
  LOG_STATUS_RUNNING  constant varchar2 (16) := 'RUNNING';
  LOG_STATUS_ERR  constant varchar2 (16) := 'ERROR';
  LOG_STATUS_WARN  constant varchar2 (16) := 'WARNING';




  /** LOG_ID NOT MeaningFul   */
  LOG_ID_NOT_USED CONSTANT NUMBER := 0;
  /** GROUP_ID NOT MeaningFul   */
  GROUP_ID_NOT_USED CONSTANT NUMBER := 0;

  K_NL CONSTANT VARCHAR2(4) := chr(10);



/**
OK used as RETURN value for FUNCTION
*/
OK CONSTANT NUMBER := 0;

/**
ERROR used as RETURN value for FUNCTION
*/
ERR CONSTANT NUMBER := 1;


  /* ==================================================================================
                      PA_UTL TYPE
  ================================================================================== */
  TYPE ARRAY_V2_V2 IS TABLE OF varchar2(10000) INDEX BY VARCHAR2(128);   -- Associative array type


  /* ==================================================================================
                      PA_UTL CUSTOM EXCEPTION
  ================================================================================== */
  K_EX_UTL constant NUMBER := -20001;
  EX_UTL EXCEPTION;
  PRAGMA EXCEPTION_INIT(EX_UTL, -20001 );




 /** **********************************************************************************
 Get varchar2 with p_len adding if required blank to get it aligned to the Right (Right)
  _param p_str in varchar2
  _param p_len in number
  _return string
  -------------------- E.G.:
  p_str          p_len    return
  ------------------------------------
  '123'          5           '  123'
  '1234567'      5           '12345'
  '1234567'      10          '   1234567'
  ********************************************************************************** */
  function v2_alignR(p_str In varchar2, p_len in number) return varchar2;


 /** **********************************************************************************
 Append to p_str adding p_sep_append only when p_str is not empty
  _param p_str in varchar2
  _param p_str_append in varchar2
  _param [p_sep_append] in varchar2 := K_NL
  _param [n_max_len] in number:= 32767
  _return New string
  ********************************************************************************** */
  function v2_append (p_str in varchar2, p_str_append in varchar2, p_sep_append in varchar2 := K_NL, n_max_len in number:= 32767) return varchar2;


 /** **********************************************************************************
 Like funzion v2_append but this is aprocedure that modify p_str
 Append to p_str adding p_sep_append only when p_str is not empty. Modify p_str
  _param p_str in out varchar2
  _param p_str_append in varchar2
  _param [p_sep_append] in varchar2 := K_NL
  _param [n_max_len] in number:= 32767
  ********************************************************************************** */
  procedure v2_append (p_str in out varchar2, p_str_append in varchar2, p_sep_append in varchar2 := K_NL, n_max_len in number:= 32767);



 /** **********************************************************************************
 Troncate p_str when required by n_max_len, adding "..." to the end only when we really have truncated
  _param p_str in varchar2  stringa da troncare
  _param n_max_len in number
  _return New string
  ********************************************************************************** */
  function v2_trunc (p_str in varchar2, n_max_len in number) return varchar2;





/**
 _return  next Log_id  that can be used to group together in UTL_LOG the log messages of the same funzionality
 * */
FUNCTION log_id_get_next RETURN NUMBER;



/**
 * LOG a Message into UTL_LOG
 * NOTES:
 *  - log is done only if p_loglev is enabled in UTL_CFG for p_feature
 *  - The Aging of UTL_CFG is automatically performed by this routine, calling locale procedure LOG_AGING that uses UTL_LOG_CFG configuration
  _param p_loglev    IN  NUMBER     LOG_LEV_xx: 0=LOG_LEV_ERR  1= LOG_LEV_WARN , .....
  _param p_feature   IN  VARCHAR2   Calling Feature. It will be logged onbly if enabled in UTL_CFG
  _param p_sp        IN  VARCHAR2   Calling SP (SP of the Feature p_feature)
  _param p_logmsg       IN  VARCHAR2   Message to Log
  _param [p_logId]   IN  NUMBER     Optional ID used to group together the log messages of the same CALL.
  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo alos with DMBS_OUTPUT.PUT_LINE
 *
 */
PROCEDURE log (p_loglev  IN  NUMBER, p_feature IN VARCHAR2, p_sp IN VARCHAR2, p_logmsg IN VARCHAR2,
                 p_logId IN NUMBER :=NULL, p_dbmsOut IN BOOLEAN :=NULL);


/**
 * Change Default Log Options
  _param [p_dbmsOutDate] IN BOOLEAN  [NULL]=use default option -  TRUE to log also Date in dbms_out
  _param [p_dbmsOutFeat] IN BOOLEAN  [NULL]=use default option -  TRUE to log also Feature in dbms_out
 *
 */
PROCEDURE log_set_opt (p_dbmsOutDate IN BOOLEAN :=NULL, p_dbmsOutFeat IN BOOLEAN :=NULL);



/**
 * LOG ElapsedTime with Msec precision
  _param p_loglev    IN  NUMBER     LOG_LEV_xx: 0=LOG_LEV_ERR  1= LOG_LEV_WARN , .....
  _param p_feature   IN  VARCHAR2   Calling Feature. It will be logged only if enabled in UTL_CFG
  _param p_sp        IN  VARCHAR2   Calling SP (SP of the Feature p_feature)
  _param p_startTime  IN  TIMESTAMP   Start TIMESTAMP used to calculate ElapsedTime= SYSDATE - p_startTime
  _param p_logmsg     IN  VARCHAR2   Message to Log
  _param [p_logId]   IN  NUMBER     Optional ID used to group together the log messages of the same CALL.
  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo alos with DMBS_OUTPUT.PUT_LINE
 *
 */
PROCEDURE log_elapsed_msec (p_loglev  IN  NUMBER, p_feature IN VARCHAR2, p_sp IN VARCHAR2, p_startTime IN TIMESTAMP, p_logmsg IN VARCHAR2,
              p_logId IN NUMBER :=NULL, p_dbmsOut IN BOOLEAN :=NULL);

/**
 * LOG ElapsedTime with sec precision
  _param p_loglev    IN  NUMBER     LOG_LEV_xx: 0=LOG_LEV_ERR  1= LOG_LEV_WARN , .....
  _param p_feature   IN  VARCHAR2   Calling Feature. It will be logged only if enabled in UTL_CFG
  _param p_sp        IN  VARCHAR2   Calling SP (SP of the Feature p_feature)
  _param p_startDate  IN  DATE      Start DATE used to calculate ElapsedTime= SYSDATE - p_startDate
  _param p_logmsg     IN  VARCHAR2   Message to Log
  _param [p_logId]   IN  NUMBER     Optional ID used to group together the log messages of the same CALL.
  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo alos with DMBS_OUTPUT.PUT_LINE
 *
 */
PROCEDURE log_elapsed_sec (p_loglev  IN  NUMBER, p_feature IN VARCHAR2, p_sp IN VARCHAR2, p_startDate IN DATE, p_logmsg IN VARCHAR2,
                 p_logId IN NUMBER :=NULL, p_dbmsOut IN BOOLEAN :=NULL);




/**
LOG an EXCEPTION
  _param p_logLev IN NUMBER := LOG_LEV_ERR
  _param p_feature   IN  VARCHAR2   Calling Feature. It will be logged only if enabled in UTL_CFG
  _param p_sp        IN  VARCHAR2   Calling SP (SP of the Feature p_feature)
  _param p_logmsg    IN  VARCHAR2   A Message to Log
  _param [p_logId]   IN  NUMBER     Optional ID used to group together the log messages of the same CALL.
  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo alos with DMBS_OUTPUT.PUT_LINE
 */
PROCEDURE log_exception (p_logLev IN NUMBER := LOG_LEV_ERR, p_feature IN VARCHAR2, p_sp IN VARCHAR2, p_logmsg IN varchar2,
   p_logId IN NUMBER DEFAULT NULL,  p_dbmsOut IN BOOLEAN DEFAULT NULL);




/**
 * Call DBMS_OUTPUT.PUT_LINE (p_msg) adding before DateTime
  _param p_msg IN VARCHAR2   Message
 * */
PROCEDURE dbms_out ( p_msg IN VARCHAR2);


/**
Get Time differences in second between 2 TIMESTAMP
 * */
FUNCTION time_diff_sec (time1 IN TIMESTAMP, time2 In TIMESTAMP) RETURN NUMBER;


/**
Get Time differences in second between 2 TIMESTAMP, formatted as varchar2 (e.g 2.345   623.001  1423.023)
 * */
FUNCTION time_vdiff_sec (time1 IN TIMESTAMP, time2 In TIMESTAMP, prefix IN varchar2 default ' in ' ) RETURN VARCHAR2;


/**
Get Time differences between Now and timeStart, formatted as varchar2 with also hour:min:ss if present
 _param timeStart IN TIMESTAMP
 _param [bMsec] in boolean := false
 _param [prefix] IN varchar2 default ' in '    Put in Front of the returned label
 _return varchar2
 ------------------ EXAMPLES
   bMsec              return
   false              in 01:12:45
   true               in 00:00:05.123

 * */
FUNCTION time_elapsed (timeStart IN TIMESTAMP, bMsec boolean := false, prefix IN varchar2 default ' in ') RETURN VARCHAR2;

/**
Get Time differences between 2 TIMESTAMP, formatted as varchar2 with also hour:min:ss if present
 _param time1 IN TIMESTAMP
 _param time2 IN TIMESTAMP
 _param [bMsec] in boolean := false
 _param prefix IN varchar2 default ' in '    Put in Front of the returned label
 _return varchar2
 ------------------ EXAMPLES
   bMsec              return
   false              in 01:12:45
   true               in 00:00:05.123
 * */
FUNCTION time_vdiff (time1 IN TIMESTAMP, time2 In TIMESTAMP, bMsec boolean := false, prefix IN varchar2 default ' in ') RETURN VARCHAR2;



/**
Convert BOOLEAN to VARCHAR2
 * */
FUNCTION bool_to_varchar2 (p_bool IN BOOLEAN) RETURN VARCHAR2;


/**
Prepare a DYNAMIC SQL Statement for TO_DATE condition, starting from a date contained in a varchar2
param p_v_date IN varchar2  e.g  '2016-07-27 10:50:53'
param p_fmt IN varchar2   Fmt used in p_d_date. e.g  'YYYY-MM-DD HH24:MI:SS'
return e.g   'TO_DATE ('''2016-07-27 10:50:53''','''YYYY-MM-DD HH24:MI:SS''')'
 * */
FUNCTION sql_v2_to_date (p_v_date IN varchar2, p_fmt IN varchar2) RETURN VARCHAR2;

/**
Prepare a DYNAMIC SQL Statement for TO_DATE condition, starting from a date
param p_date IN date  e.g  2016-07-27 10:50:53
param [p_fmt] IN varchar2   Fmt to use. Default  'YYYY-MM-DD HH24:MI:SS'
return e.g   'TO_DATE ('''2016-07-27 10:50:53''','''YYYY-MM-DD HH24:MI:SS''')'
 * */
FUNCTION sql_to_date (p_date IN date, p_fmt IN varchar2:= 'YYYY-MM-DD HH24:MI:SS') RETURN VARCHAR2;


/**
Prepare a DYNAMIC SQL Statement for BETWEEN condition, starting from 2 dates
param p_date_from IN date  e.g  2016-07-27 10:50:53
param p_date_to IN date  e.g  2016-12-31 12:51:01
param [p_fmt] IN varchar2   Fmt to use. Default  'YYYY-MM-DD HH24:MI:SS'
return e.g   ' BETWEEN ('''2016-07-27 10:50:53''','''YYYY-MM-DD HH24:MI:SS''')  AND  ('''2016-12-31 12:51:01''','''YYYY-MM-DD HH24:MI:SS''')  '
 * */
FUNCTION sql_between_date (p_date_from IN date, p_date_to IN date, p_fmt IN varchar2:= 'YYYY-MM-DD HH24:MI:SS') RETURN VARCHAR2;


/**
  - EXECUTE IMMEDIATE DROP TABLE ...
  - NO ERROR if alread it does not exist
  - In case of EXCEPTION log it (with details) and then RAISE a custom EXPTION EX_FILE_READ (with sqlerrm describing it)
  _param p_stmt IN varchar2  e.g  'DROP TABLE DTCT_OWN.TB_DTCT_DOCUMENTI'
  _param p_loglev    IN  NUMBER     LOG_LEV_xx: 0=LOG_LEV_ERR  1= LOG_LEV_WARN , .....
  _param p_feature   IN  VARCHAR2   Calling Feature. It will be logged only if enabled in UTL_CFG
  _param p_sp        IN  VARCHAR2   Calling SP (SP of the Feature p_feature)
  _param [p_logId]   IN  NUMBER     Optional ID used to group together the log messages of the same CALL.
  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo alos with DMBS_OUTPUT.PUT_LINE
 */
PROCEDURE execute_stmt_drop (p_stmt IN VARCHAR2, p_loglev  IN  NUMBER, p_feature IN VARCHAR2, p_sp IN VARCHAR2,
    p_logId IN NUMBER :=NULL, p_dbmsOut IN BOOLEAN :=NULL) ;

/**
  - EXECUTE IMMEDIATE  a generic SQL Statement
  - LOG
  - In case of EXCEPTION log it (with details) and then RAISE a custom EXPTION EX_FILE_READ (with sqlerrm describing it)
  _param p_stmt IN varchar2  e.g  'CREATE TABLE ....'
  _param p_loglev    IN  NUMBER     LOG_LEV_xx: 0=LOG_LEV_ERR  1= LOG_LEV_WARN , .....
  _param p_feature   IN  VARCHAR2   Calling Feature. It will be logged only if enabled in UTL_CFG
  _param p_sp        IN  VARCHAR2   Calling SP (SP of the Feature p_feature)
  _param [p_logId]   IN  NUMBER     Optional ID used to group together the log messages of the same CALL.
  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo also with DMBS_OUTPUT.PUT_LINE

 */
PROCEDURE execute_stmt (p_stmt IN VARCHAR2, p_loglev  IN  NUMBER, p_feature IN VARCHAR2, p_sp IN VARCHAR2,
        p_logId IN NUMBER :=NULL, p_dbmsOut IN BOOLEAN :=NULL);

/**
Like execute_stmt, but also return n_rec that is meaningful only for some stmt: for this stmt you can use this function instead of execute_stmt
  - EXECUTE IMMEDIATE  a generic SQL Statement
  - LOG
  - In case of EXCEPTION log it (with details) and then RAISE a custom EXPTION EX_FILE_READ (with sqlerrm describing it)
  _param p_stmt IN varchar2  e.g  'CREATE TABLE ....'
  _param p_loglev    IN  NUMBER     LOG_LEV_xx: 0=LOG_LEV_ERR  1= LOG_LEV_WARN , .....
  _param p_feature   IN  VARCHAR2   Calling Feature. It will be logged only if enabled in UTL_CFG
  _param p_sp        IN  VARCHAR2   Calling SP (SP of the Feature p_feature)
  _param [p_logId]   IN  NUMBER     Optional ID used to group together the log messages of the same CALL.
  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo also with DMBS_OUTPUT.PUT_LINE

  _return    sql%rowcount
 */
FUNCTION execute_stmt_fun (p_stmt IN VARCHAR2, p_loglev  IN  NUMBER, p_feature IN VARCHAR2, p_sp IN VARCHAR2,
        p_logId IN NUMBER :=NULL, p_dbmsOut IN BOOLEAN :=NULL) RETURN NUMBER;


/**
  Get Number of lines of a file.
  _param p_dir IN VARCHAR2
  _param p_file IN VARCHAR2
  _return n_lines   -1 if files is not present
                    0 if is present but is empty
                    N present with N Lines
*/
FUNCTION file_get_nlines (p_dir IN VARCHAR2, p_file IN VARCHAR2)  RETURN number;


/**
  Get size (in bytes) of a file.
  _param p_dir IN VARCHAR2
  _param p_file IN VARCHAR2
  _return n_lines   -1 if files is not present
                    0 if is present but is empty
                    N: num byte
*/
FUNCTION file_get_size (p_dir IN VARCHAR2, p_file IN VARCHAR2)  RETURN number;


/**
  - Read a File of MAX SIZE 32767 and return the v_buf_read
  - LOG the size of v_read_buf at Level p_logLev
  - Only if explicitily required by p_log_read_buf (default=FALSE) we log also v_buf_read
  - In case of EXCEPTION log it (with details) and then RAISE a custom EXPTION EX_FILE_READ (with sqlerrm describing it)

  _param p_dir IN VARCHAR2
  _param p_file IN VARCHAR2
  _param p_loglev    IN  NUMBER     LOG_LEV_xx: 0=LOG_LEV_ERR  1= LOG_LEV_WARN , ..... LOG_LEV_NOLOG if you do not want any LOG
  _param p_feature   IN  VARCHAR2   Calling Feature. It will be logged only if enabled in UTL_CFG
  _param [p_logId]   IN  NUMBER     Optional ID used to group together the log messages of the same CALL.
  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo alos with DMBS_OUTPUT.PUT_LINE
  _param [p_log_read_buf] IN BOOLEAN := FALSE     If TRUE we log also p_buf_read

  _return v_read_buf   The File contents
*/
FUNCTION file_read (p_dir IN VARCHAR2, p_file IN VARCHAR2, p_loglev  IN  NUMBER := LOG_LEV_TRACE, p_feature IN VARCHAR2,
      p_logId IN NUMBER :=NULL, p_dbmsOut IN BOOLEAN :=NULL, p_log_read_buf IN BOOLEAN := FALSE)  RETURN varchar2;


/**
  - Read v_buf from a File SQL of MAX SIZE 32767
  - REPLACING the PlaceHolder and return v_sql
  - LOG v_sql at Level p_logLev
  - In case of EXCEPTION log it (with details) and then RAISE a custom EXPTION EX_FILE_READ (with sqlerrm describing it)

  _param p_dir IN VARCHAR2
  _param p_file IN VARCHAR2
  _param p_replace IN ARRAY_V2_V2   Array of PlaceHolder to be replaced and relative Values
  _param p_loglev    IN  NUMBER     LOG_LEV_xx: 0=LOG_LEV_ERR  1= LOG_LEV_WARN , ..... LOG_LEV_NOLOG if you do not want any LOG
  _param p_feature   IN  VARCHAR2   Calling Feature. It will be logged only if enabled in UTL_CFG
  _param [p_logId]   IN  NUMBER     Optional ID used to group together the log messages of the same CALL.
  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo alos with DMBS_OUTPUT.PUT_LINE
  _param [p_log_sql_buf] IN BOOLEAN := FALSE     If TRUE we log also p_buf_read
  _return v_read_buf   The File contents
*/
FUNCTION file_sql_read (p_dir IN VARCHAR2, p_file IN VARCHAR2, p_replace IN ARRAY_V2_V2,
      p_loglev  IN  NUMBER := LOG_LEV_TRACE, p_feature IN VARCHAR2,
      p_logId IN NUMBER :=NULL, p_dbmsOut IN BOOLEAN :=NULL, p_log_sql_buf IN BOOLEAN := FALSE)  RETURN varchar2;




/**
 _return  next Log_id  that can be used to group together in UTL_LOG the log messages of the same funzionality
 * */
FUNCTION log_status_group_id_get_next RETURN NUMBER;

/**
 _return  Current Log_id  used to group together in UTL_LOG the log messages of the same funzionality
 * */
FUNCTION log_status_group_id_get_cur RETURN NUMBER;

/**
 _param p_group_id in number  set in UTL_CFG current value of  groupId that can be retrieved using log_status_group_id_get_cur
 * */
PROCEDURE  log_status_group_id_set_cur (p_group_id in number);


/**
 Start a new REcord with PK <LOG_ID, GROUP_ID, SP> into utl_log_status:
 - If PK <LOG_ID, GROUP_ID, SP> already exist into UTL_LOG_STATUS, we delete it
 - INSERT a New Record with PK <LOG_ID, GROUP_ID, SP> into UTL_LOG_STATUS, setting startDate

  _param p_logId IN NUMBER   <LOG_ID, GROUP_ID, SP> identify the SP Status
  _param p_groupId IN NUMBER   can be used to group together different SP running in parallel
  _param p_feature IN VARCHAR2
  _param p_sp IN VARCHAR2
  _param p_status IN VARCHAR2 := LOG_STATUS_RUNNING
  _param p_detail IN VARCHAR2 := ''      Can also be > 4000 bytes
  _param [p_dbmsOut] IN BOOLEAN     default FALSE
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo also with DMBS_OUTPUT.PUT_LINE
*/
PROCEDURE log_status_start (p_logId IN NUMBER, p_groupId IN NUMBER, p_feature IN varchar2, p_sp IN VARCHAR2, p_status IN VARCHAR2 := LOG_STATUS_RUNNING, p_detail IN VARCHAR2 := '', p_dbmsOut in boolean:=false);


/**
 Update in utl_log_status the Status of <LOG_ID, SP>:
 - If PK <LOG_ID, GROUP_ID, SP> NOT still exist in UTL_LOG_STATUS, we INSERT a New Record with PK <LOG_ID, GROUP_ID, SP> into UTL_LOG_STATUS, setting startDate
 - Update the Record with PK <LOG_ID, GROUP_ID, SP> in UTL_LOG_STATUS, setting LastDate and ElapsedSec

  _param p_logId IN NUMBER   <LOG_ID, GROUP_ID, SP> identify the SP Status
  _param p_groupId IN NUMBER   can be used to group together different SP running in parallel
  _param p_feature IN VARCHAR2
  _param p_sp IN VARCHAR2
  _param p_status IN VARCHAR2
  _param p_detail IN VARCHAR2 := ''      Can also be > 4000 bytes
  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo also with DMBS_OUTPUT.PUT_LINE
*/
PROCEDURE log_status_update (p_logId IN NUMBER, p_groupId IN NUMBER, p_feature IN VARCHAR2, p_sp IN VARCHAR2, p_status IN VARCHAR2, p_detail IN VARCHAR2 := '', p_dbmsOut in boolean:=false);




/**
 delete a log_status identified by <LOG_ID, GROUP_ID, SP>:
  _param p_logId IN NUMBER   <LOG_ID, GROUP_ID, SP> identify the SP Status
  _param p_groupId IN NUMBER   can be used to group together different SP running in parallel
  _param p_feature IN VARCHAR2
  _param p_sp IN VARCHAR2
  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo also with DMBS_OUTPUT.PUT_LINE
*/
PROCEDURE log_status_delete (p_logId IN NUMBER, p_groupId IN NUMBER, p_feature IN VARCHAR2, p_sp IN VARCHAR2, p_dbmsOut in boolean:=false);


/**
  It is automatically called and managed by UTL_LOG itsself.  GLOBAL SP only to check it behaviour
  AGING of UTL_LOG and UTL_LOG_STATUS:
     - Check only each UTL_CFG.LOG_AGING_FREQ_DAYS (configured into UTL_CFG.LOG_AGING_LAST_DATE )
     - When we make the check: drop partition  older than  UTL_CFG.LOG_AGING_DUR_DAYS and Update UTL_CFG.LOG_AGING_LAST_DATE

  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo also with DMBS_OUTPUT.PUT_LINE
 * */
PROCEDURE log_aging (p_dbmsOut IN BOOLEAN DEFAULT NULL);


END;
/
CREATE OR REPLACE PACKAGE BODY DWH.PA_UTL IS

/**
<b>File:</b>          PA_UTL.pck  </BR>
<b>Author:</b>        Federico Levis  </BR>
<b>Description:</b>   PLSQL Utility Package :
                       - LOG: log, log_elapsed_sec, log_elapsed_msec are used to log with various level (LOG_LEV_ERR,..,LOG_LEV_TRACE) into Table UTL_LOG  </BR>
                       - OTHER Utility Function: time_diff_sec, bool_to_varchar2,...  </BR>
<b>REQUIRED:</b>       UTL_LOG, UTL_CFG, UTL_LOG_CFG,  SEQ_LOG_ID  </BR>
<b>Documentation:</b>  <a href="https://rawgit.com/FedericoLevis/PLSqlUtility/master/PA_UTL/README.html" target="_blank">PA_UTL README.html</a>   </BR>
<b>Public Procedure Description</b>See Package Specification</b></BR>
<b>First Version:</b>  ver 1.0 - Jan 2015   </BR>
<b>Current Version:</b>ver 3.1 - Apr 2018  (NB: Changed Interface) </BR>
----------------------------------------------------------------------------------- </BR>
<b>DISCLAIMER</b> </BR>
Copyright by Federico Levis - <a href="https://github.com/JSUtility/PLSQLUtility" target="_blank">PL SQL Utilty</a>  </BR>
This file may be freely distributed under the MIT license.
*/

  /* *******************************************
             CONSTANT
  ********************************************/
  --K_APICE CONSTANT VARCHAR2(1) := '''';
  K_SEE_MSG_CLOB        CONSTANT VARCHAR2(64) := 'LOG in MSG_CLOB ...  ';
  K_SEE_DETAIL_CLOB        CONSTANT VARCHAR2(64) := 'SEE DETAIL_CLOB ...  ';
  MAX_LEN_LOG_MSG CONSTANT NUMBER := 4000;  -- Uguale a spazio colonna LOG.LOG_MSG allocato in DB
  --  Default usati (robustezza) se per dimenticanza non sono stati definiti i relativi _parametri in LOG_CFG
  --  AGING (num giorni) Tabella LOG
  K_DEF_LOG_AGING_FREQ_DAYS CONSTANT  NUMBER := 7;
  K_DEF_LOG_AGING_DUR_DAYS CONSTANT  NUMBER := 30;
  k_csv_fmt_decimal constant varchar2(30) := 'FM999999999990.999'; -- Decimal Format

  K_FMT_DATETIME constant varchar2(32) := 'yyyy-mm-dd hh24:mi:ss.FF3';
  K_FMT_TIME constant varchar2(32) := 'hh24:mi:ss.FF3';

  /* *******************************************
                 VAR
  ******************************************* **/
  -- Last aging check of this session. Used to optimize check num
  d_log_check_aging DATE := SYSDATE -100;  -- Very old, so first time we check

  -- Option for DBMS_OUT that could be called (if enabled) for each log
  opt_dbmsOutDate BOOLEAN := FALSE;
  opt_dbmsOutFeat BOOLEAN := FALSE;


/*************************************************
*****            PRIVATE             *****
**************************************************/


/**
  It is automatically called and managed by UTL_LOG itsself.
  AGING of UTL_LOG and UTL_LOG_STATUS:
     - Check only each UTL_CFG.LOG_AGING_FREQ_DAYS (configured into UTL_CFG.LOG_AGING_LAST_DATE )
     - When we make the check: drop partition  older than  UTL_CFG.LOG_AGING_DUR_DAYS and Update UTL_CFG.LOG_AGING_LAST_DATE

  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo also with DMBS_OUTPUT.PUT_LINE
 * */
PROCEDURE log_aging (p_dbmsOut IN BOOLEAN DEFAULT NULL)
IS

  n_delta_date NUMBER;
  n_delta_check NUMBER :=  trunc(SYSDATE - d_log_check_aging) ; -- num days elapsed from last check of this session
  n_aging_freq_days NUMBER := K_DEF_LOG_AGING_FREQ_DAYS;  -- default
  n_aging_dur_days NUMBER := K_DEF_LOG_AGING_DUR_DAYS;  -- default
  d_aging_last_date DATE := SYSDATE -100;  -- default set to old date
  K_SP varchar2(100) := 'log_aging';
  t_startTime TIMESTAMP := CURRENT_TIMESTAMP;
  v_stmt varchar2(1000);
  n_part_drop number := 0;
BEGIN
  -- IF(p_dbmsOut) THEN
  --  dbms_out (K_SP || ' n_delta_check=' || n_delta_check);
  -- end if;
  IF (n_delta_check <= 0) THEN
    return; -- Nothing to do : the check has been already done in the last 24 hours in this session
  END IF;
  -- We Have to make the Check
  IF(p_dbmsOut) THEN
    dbms_out (K_SP || ' n_delta_check=' || n_delta_check || ' - We have to Make the Check Aging reading UTL_CFG par');
  END IF;
  d_log_check_aging := SYSDATE; -- SET Last date of check of this session
  BEGIN
      -- Get UTL_CFG par
      SELECT VAL_NUM INTO n_aging_freq_days  FROM DWH.UTL_CFG WHERE PAR = 'AGING_LOG_FREQ_DAYS';
      SELECT VAL_NUM INTO n_aging_dur_days  FROM DWH.UTL_CFG WHERE PAR = 'AGING_LOG_DUR_DAYS';
      SELECT VAL_DATE INTO d_aging_last_date  FROM DWH.UTL_CFG WHERE PAR = 'AGING_LOG_LAST_DATE';
      EXCEPTION WHEN OTHERS THEN
          -- In case of error we GO ON with default
       NULL;
  END;
  -- How many days have elapsed from last AGING?
  n_delta_date :=  TRUNC(sysdate-d_aging_last_date);
  IF (n_delta_date < n_aging_freq_days) THEN
    RETURN;
  END IF;
  -- we have to mahe the aging
  IF (p_dbmsOut) THEN
     dbms_out ('START LOG_AGING: DELETE  PARTITION Older than ' || n_aging_dur_days  || ' days');
  END IF;

   /* GET 'part_rule' and 'part_date'
       ES:
        part_rule = TO_DATE(' 2018-01-15 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')
        part_date = 2018-01-15

       FILTER Only Part to drop:
         - part_date < (sysdate - n_aging_dur_days)
         - DO NOT DROP BASE PART that have INTERVAL='NO'
   */

   FOR rec IN
       (select * from (
         with xml as (
         select dbms_xmlgen.getxmltype('select table_owner, table_name, partition_name, interval, high_value from DBA_TAB_PARTITIONS where table_owner=''DWH'' AND table_name IN (''UTL_LOG'',''UTL_LOG_STATUS'') ') as x
           from   dual
         )
         select
           extractValue(rws.object_value, '/ROW/TABLE_OWNER') table_owner,
           extractValue(rws.object_value, '/ROW/TABLE_NAME') table_name,
           extractValue(rws.object_value, '/ROW/PARTITION_NAME') part_name,
           extractValue(rws.object_value, '/ROW/INTERVAL') interval,
           extractValue(rws.object_value, '/ROW/HIGH_VALUE') part_rule,
           to_date(substr(extractValue(rws.object_value, '/ROW/HIGH_VALUE'),
                    instr(extractValue(rws.object_value, '/ROW/HIGH_VALUE'), '''')+2, 19),
                    'yyyy-mm-dd hh24:mi:ss') part_date
         from   xml x , table(xmlsequence(extract(x.x, '/ROWSET/ROW'))) rws )
         WHERE INTERVAL != 'NO' AND part_date < sysdate - n_aging_dur_days
        )
    LOOP
      v_stmt := 'ALTER TABLE ' || rec.table_owner || '.' || rec.table_name || ' DROP PARTITION ' || rec.PART_NAME;
      IF (p_dbmsOut) THEN
        dbms_out ('EXECUTE STMT: ' || v_stmt);
      END IF;
      execute immediate v_stmt;
      n_part_drop := n_part_drop + 1;
    END LOOP;
    UPDATE DWH.UTL_CFG SET VAL_DATE = SYSDATE WHERE PAR = 'log_aging_LAST_DATE';
    COMMIT;
    IF (p_dbmsOut) THEN
      dbms_out ('DROPPED ' || n_part_drop || '  PARTITION in ' || time_elapsed (t_startTime));
    END IF;
END log_aging;




PROCEDURE RAISE_FILE_EX (v_sp in varchar2, p_dir varchar2, p_file varchar2) IS
  v_msg varchar2(10000);
BEGIN
  v_msg := 'EXCEPTION in ' || v_SP || ' DIR=' || p_dir || ' FILE='|| p_file;
  -- RAISE Custom EXCEPTION
  v_msg  := v_msg || K_NL || DBMS_UTILITY.format_error_backtrace || 'SQLERRM=' || sqlerrm;
  dbms_out (v_msg);
  raise_application_error( K_EX_UTL, v_msg );
END RAISE_FILE_EX;



/*************************************************
*****            PUBLIC             *****
**************************************************/


 /** **********************************************************************************
  Description: see Package Specification
  ********************************************************************************** */
  function v2_alignR(p_str In varchar2, p_len in number) return varchar2
  IS
    n_lenCur number := LENGTH(p_str);
  BEGIN
    IF (n_lenCur <= p_len) then
      return substr('                                      ' || p_str,- p_len);
    ELSE
      return substr(p_str,1, p_len);
    END IF;
  END v2_alignR;





 /** **********************************************************************************
 Append to p_str adding p_sep_append only when p_str is not empty
 Detail Description: see Package Specification
  ********************************************************************************** */
  function v2_append (p_str in varchar2, p_str_append in varchar2, p_sep_append in varchar2 := K_NL, n_max_len in number:= 32767) return varchar2 IS
  BEGIN
    IF (LENGTH (p_str) > 0) THEN
      IF (LENGTH (p_str_append) > 0) THEN
        return SUBSTR (p_str || p_sep_append || p_str_append, 1 , n_max_len);
      ELSE
        return p_str;
      END IF;
    ELSE
      return p_str_append;
    END IF;
  END v2_append;



 /** **********************************************************************************
 Append to p_str adding p_sep_append only when p_str is not empty. Modify p_str
 Detail Description: see Package Specification
  ********************************************************************************** */
  procedure v2_append (p_str in out varchar2, p_str_append in varchar2, p_sep_append in varchar2 := K_NL, n_max_len in number:= 32767)  IS
  BEGIN
    IF (LENGTH (p_str) > 0) THEN
      IF (LENGTH (p_str_append) > 0) THEN
        p_str := SUBSTR( p_str || p_sep_append || p_str_append, 1 , n_max_len);
      END IF;
    ELSE
      p_str := p_str_append;
    END IF;
  END v2_append;




 /** **********************************************************************************
 Troncate p_str when required by n_max_len, adding "..." to the end only when we really have truncated
 Detail Description: see Package Specification
  ********************************************************************************** */
  function v2_trunc (p_str in varchar2, n_max_len in number) return varchar2 IS
    n_len number;
  BEGIN
    IF (p_str IS NULL) THEN
      return p_str;
    END IF;
    n_len := length (p_str);
    IF (n_len >= (n_max_len -3)) THEN
      return substr (p_str,1,n_max_len -3) || '...';
    ELSE
      return p_str;
    END IF;
  END v2_trunc;


/**
 Call DBMS_OUTPUT.PUT_LINE (p_msg) adding before DateTime
 Detail Description: see Package Specification
 *  */
PROCEDURE dbms_out (p_msg IN VARCHAR2)
IS
  v_time_fmt varchar2(32) := K_FMT_TIME;
BEGIN
  IF (opt_dbmsOutDate) THEN
    v_time_fmt := K_FMT_DATETIME;
  END IF;
  DBMS_OUTPUT.PUT_LINE(TO_CHAR(CURRENT_TIMESTAMP,v_time_fmt) || ' ' ||   p_msg);
END dbms_out;


/**
 _return  next Log_id  that can be used to group together in UTL_LOG the log messages of the same functionality
 * */
FUNCTION log_id_get_next RETURN NUMBER
IS
  n_log_id NUMBER := DWH.SEQ_LOG_ID.NEXTVAL;
BEGIN
  -- Update UTL_CFG
  -- UPDATE DWH.UTL_CFG SET VAL_NUM=n_log_id WHERE PAR='LOG_ID';
  return n_log_id;
END log_id_get_next;



/**
 * Change Default Log Options
  _param [p_dbmsOutDate] IN BOOLEAN  [NULL]=use default option -  TRUE to log also Date in dbms_out
  _param [p_dbmsOutFeat] IN BOOLEAN  [NULL]=use default option -  TRUE to log also Feature in dbms_out
 *
 */
PROCEDURE log_set_opt (p_dbmsOutDate IN BOOLEAN :=NULL, p_dbmsOutFeat IN BOOLEAN :=NULL)
IS
BEGIN
  IF (p_dbmsOutDate IS NOT NULL) THEN
    opt_dbmsOutDate := p_dbmsOutDate;
  END IF;
  IF (p_dbmsOutFeat  IS NOT NULL) THEN
    opt_dbmsOutFeat := p_dbmsOutFeat;
  END IF;
END;



/**
 * LOG a Message into UTL_LOG
 * NOTES:
 *  - log is done only if p_loglev is enabled in UTL_CFG for p_feature
 *  - The Aging of UTL_CFG is automatically performed by this routine, calling locale procedure LOG_AGING that uses UTL_LOG_CFG configuration
  _param p_loglev    IN  NUMBER     LOG_LEV_xx: 0=LOG_LEV_ERR  1= LOG_LEV_WARN , .....
  _param p_feature   IN  VARCHAR2   Calling Feature. It will be logged onbly if enabled in UTL_CFG
  _param p_sp        IN  VARCHAR2   Calling SP (SP of the Feature p_feature)
  _param p_logmsg       IN  VARCHAR2   Message to Log
  _param [p_logId]   IN  NUMBER     Optional ID used to group together the log messages of the same CALL.
  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo also with DMBS_OUTPUT.PUT_LINE
 *
 */
PROCEDURE log (p_loglev  IN  NUMBER, p_feature IN VARCHAR2, p_sp IN VARCHAR2, p_logmsg IN VARCHAR2,
                 p_logId IN NUMBER :=NULL, p_dbmsOut IN BOOLEAN :=NULL)
IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  b_log     INTEGER := 1;  -- DEfault: Enabled
  v_logFeat VARCHAR2 (128) := '';
  v_seeCLOB varchar2(1000);
BEGIN
  IF (p_loglev > LOG_LEV_ERR) THEN
    -- Check if l_logLev is Enable for this p_feature
    SELECT COUNT(*) INTO b_log FROM DWH.UTL_LOG_CFG WHERE FEATURE = p_feature AND LOG_LEV >= p_loglev;
  END IF;

  IF (b_log > 0)THEN
    log_aging (p_dbmsOut) ;  -- Only if required make the AGING
    IF (p_dbmsOut) THEN
      -- Enable dbms Output
      IF (opt_dbmsOutFeat) THEN
        v_logFeat := p_feature || ' ';
      END IF;
      DBMS_OUT(p_loglev || ' ' || v_logFeat || '[' || p_sp || '] ' || p_logmsg);
    END IF;
    -- Check LEN: if LEN > MAX_LEN_LOG_MSG we will use CLOB
    IF (LENGTH (p_logmsg) > MAX_LEN_LOG_MSG) THEN
      v_seeCLOB := K_SEE_MSG_CLOB || v2_trunc(p_logmsg,30);
      INSERT INTO DWH.UTL_LOG (FEATURE, SP,LOG_LEV,LOG_TIME,LOG_ID,MSG,MSG_CLOB)
          VALUES (p_feature, p_sp, p_loglev, CURRENT_TIMESTAMP, p_logId,v_seeCLOB,p_logmsg);
    ELSE
      INSERT INTO DWH.UTL_LOG (FEATURE, SP,LOG_LEV,LOG_TIME,LOG_ID,MSG)
          VALUES (p_feature, p_sp,p_loglev,CURRENT_TIMESTAMP, p_logId, p_logmsg);
    END IF;
    COMMIT;
  END IF;

  EXCEPTION WHEN OTHERS THEN
    DBMS_OUT ('UTL_LOG ERROR: ' || TO_CHAR(SQLCODE) || ' - ' || SQLERRM);
    COMMIT;

END log;



/**
 * LOG ElapsedTime with Msec precision
  _param p_loglev    IN  NUMBER     LOG_LEV_xx: 0=LOG_LEV_ERR  1= LOG_LEV_WARN , .....
  _param p_feature   IN  VARCHAR2   Calling Feature. It will be logged only if enabled in UTL_CFG
  _param p_sp        IN  VARCHAR2   Calling SP (SP of the Feature p_feature)
  _param p_startTime  IN  TIMESTAMP   Start TIMESTAMP used to calculate ElapsedTime= SYSDATE - p_startTime
  _param p_logmsg     IN  VARCHAR2   Message to Log
  _param [p_logId]   IN  NUMBER     Optional ID used to group together the log messages of the same CALL.
  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo also with DMBS_OUTPUT.PUT_LINE
 *
 */
PROCEDURE log_elapsed_msec (p_loglev  IN  NUMBER, p_feature IN VARCHAR2, p_sp IN VARCHAR2, p_startTime IN TIMESTAMP, p_logmsg IN VARCHAR2,
              p_logId IN NUMBER :=NULL, p_dbmsOut IN BOOLEAN :=NULL)
IS
BEGIN
  log (p_loglev, p_feature, p_sp, time_vdiff_sec (CURRENT_TIMESTAMP,p_startTime) || p_logmsg ,
              p_logId, p_dbmsOut);
END log_elapsed_msec;

/**
 * LOG ElapsedTime with sec precision
  _param p_loglev    IN  NUMBER     LOG_LEV_xx: 0=LOG_LEV_ERR  1= LOG_LEV_WARN , .....
  _param p_feature   IN  VARCHAR2   Calling Feature. It will be logged only if enabled in UTL_CFG
  _param p_sp        IN  VARCHAR2   Calling SP (SP of the Feature p_feature)
  _param p_startDate  IN  DATE      Start DATE used to calculate ElapsedTime= SYSDATE - p_startDate
  _param p_logmsg     IN  VARCHAR2   Message to Log
  _param [p_logId]   IN  NUMBER     Optional ID used to group together the log messages of the same CALL.
  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo also with DMBS_OUTPUT.PUT_LINE
 *
 */
PROCEDURE log_elapsed_sec (p_loglev  IN  NUMBER, p_feature IN VARCHAR2, p_sp IN VARCHAR2, p_startDate IN DATE, p_logmsg IN VARCHAR2,
                 p_logId IN NUMBER :=NULL, p_dbmsOut IN BOOLEAN :=NULL)
IS
  n_sec NUMBER;
BEGIN

  n_sec := TRUNC((SYSDATE-p_startDate)*24*60*60);
  log (p_loglev,p_feature, p_sp, 'Elapsed=' || n_sec || ' sec  ' || p_logmsg,  p_logId, p_dbmsOut);
END log_elapsed_sec;


/**
Get Time differences (time1 - time2) in second between 2 TIMESTAMP
 * */
FUNCTION time_diff_sec (time1 IN TIMESTAMP, time2 In TIMESTAMP) RETURN NUMBER
IS
  n_sec NUMBER;
BEGIN
  n_sec := extract(day from (time1-time2))*24*60*60
     + extract(hour from (time1-time2))*60*60
     + extract(minute from (time1-time2))*60
     + extract(second from (time1-time2));
  return n_sec;
END time_diff_sec;


/**
Get Time differences in second between 2 TIMESTAMP, formatted as varchar2 without msec
 _param timeStart IN TIMESTAMP
 _param prefix IN varchar2 default ' in '    Put in Front of the returned label
 _return varchar2(32) e.g ' in 23 sec'   ' in 10:23.001 sec'  ' in 12,456 sec'

 **/
FUNCTION time_vdiff_sec (time1 IN TIMESTAMP, time2 In TIMESTAMP, prefix IN varchar2 default ' in ') RETURN VARCHAR2
IS
BEGIN
  return prefix || to_char(time_diff_sec (time1,time2), k_csv_fmt_decimal) || ' sec';
END time_vdiff_sec;



/**
Get Time differences between Now and timeStart, formatted as varchar2 with also hour:min:ss if present
 _param timeStart IN TIMESTAMP
 _param [bMsec] in boolean := false
 _param [prefix] IN varchar2 default ' in '    Put in Front of the returned label
 _return varchar2
 ------------------ EXAMPLES
   bMsec              return
   ------------------------------
   false              in 01:12:45
   true               in 00:00:05.123

 * */
FUNCTION time_elapsed (timeStart IN TIMESTAMP, bMsec boolean := false, prefix IN varchar2 default ' in ') RETURN VARCHAR2
IS
BEGIN
  return time_vdiff (CURRENT_TIMESTAMP, timeStart, bMsec, prefix);
END time_elapsed;



/**
Get Time differences between 2 TIMESTAMP, formatted as varchar2 with also hour:min:ss if present
 _param time1 IN TIMESTAMP
 _param time2 IN TIMESTAMP
 _param [bMsec] in boolean := false
 _param prefix IN varchar2 default ' in '    Put in Front of the returned label
 _return varchar2
 ------------------ EXAMPLES
   bMsec              return
   ------------------------------
   false              in 01:12:45
   true               in 00:00:05.123
 * */
FUNCTION time_vdiff (time1 IN TIMESTAMP, time2 In TIMESTAMP, bMsec boolean := false, prefix IN varchar2 default ' in ') RETURN VARCHAR2
IS
  n_sec_tot NUMBER := DWH.pa_utl.time_diff_sec (time1,time2);
  n_hour NUMBER := trunc(n_sec_tot / 3600);
  n_min NUMBER := trunc(mod (n_sec_tot,3600)/60);
  n_sec NUMBER := trunc(MOD(n_sec_tot,60));  -- e.g 54
  n_msec NUMBER := trunc (MOD(n_sec_tot*1000,1000));  -- e.g 123
  v_time varchar2(32);
BEGIN
  v_time := to_char(n_hour,'FM00') || ':' || to_char(n_min,'FM00') || ':' || to_char(n_sec,'FM00');
  IF (bMsec) THEN
    v_time :=  v_time ||  '.' || to_char(n_msec,'FM000');
  END IF;
  return prefix || v_time;
END time_vdiff;







/**
Convert BOOLEAN to VARCHAR2
 * */
FUNCTION bool_to_varchar2 (p_bool IN BOOLEAN) RETURN VARCHAR2 IS
BEGIN
  RETURN
    case
      when p_bool = true  then  'TRUE'
      else 'FALSE'
    end;
END bool_to_varchar2;


/**
Prepare a DYNAMIC SQL Statement for TO_DATE condition, starting from a date contained in a varchar2
param p_v_date IN varchar2  e.g  '2016-07-27 10:50:53'
param p_fmt IN varchar2   Fmt used in p_d_date. e.g  'YYYY-MM-DD HH24:MI:SS'
return e.g   'TO_DATE ('''2016-07-27 10:50:53''','''YYYY-MM-DD HH24:MI:SS''')'
 * */
FUNCTION sql_v2_to_date (p_v_date IN varchar2, p_fmt IN varchar2) RETURN VARCHAR2 IS
BEGIN
  RETURN   ' TO_DATE(''' || p_v_date  ||  ''',''' || p_fmt  ||  ''')';
END sql_v2_to_date;


/**
Prepare a DYNAMIC SQL Statement for TO_DATE condition, starting from a date
param p_date IN date  e.g  2016-07-27 10:50:53
param [p_fmt] IN varchar2   Fmt to use. Default  'YYYY-MM-DD HH24:MI:SS'
return e.g   'TO_DATE ('''2016-07-27 10:50:53''','''YYYY-MM-DD HH24:MI:SS''')'
 * */
FUNCTION sql_to_date (p_date IN date, p_fmt IN varchar2:= 'YYYY-MM-DD HH24:MI:SS') RETURN VARCHAR2 IS
  v_date varchar2(32) := TO_CHAR (p_date, p_fmt);
BEGIN

  RETURN  sql_v2_to_date (v_date,p_fmt);
END sql_to_date;

/**
Prepare a DYNAMIC SQL Statement for BETWEEN condition, starting from 2 dates
param p_date_from IN date  e.g  2016-07-27 10:50:53
param p_date_to IN date  e.g  2016-12-31 12:51:01
param [p_fmt] IN varchar2   Fmt to use. Default  'YYYY-MM-DD HH24:MI:SS'
return e.g   ' BETWEEN ('''2016-07-27 10:50:53''','''YYYY-MM-DD HH24:MI:SS''')  AND  ('''2016-12-31 12:51:01''','''YYYY-MM-DD HH24:MI:SS''')  '
 * */
FUNCTION sql_between_date (p_date_from IN date, p_date_to IN date, p_fmt IN varchar2:= 'YYYY-MM-DD HH24:MI:SS') RETURN VARCHAR2 IS
  v_date_from varchar2(32) := TO_CHAR (p_date_from, p_fmt);
  v_date_to varchar2(32) := TO_CHAR (p_date_to, p_fmt);
BEGIN

  RETURN  ' BETWEEN ' || sql_v2_to_date (v_date_from,p_fmt) || ' AND ' || sql_v2_to_date (v_date_to,p_fmt);
END sql_between_date;



/**
LOG an EXCEPTION
  _param p_log_lev   IN  NUMBER:=LOG_LEV_ERR
  _param p_feature   IN  VARCHAR2   Calling Feature. It will be logged only if enabled in UTL_CFG
  _param p_sp        IN  VARCHAR2   Calling SP (SP of the Feature p_feature)
  _param p_logmsg    IN  VARCHAR2   A Message to Log
  _param [p_logId]   IN  NUMBER     Optional ID used to group together the log messages of the same CALL.
  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo also with DMBS_OUTPUT.PUT_LINE
 */
PROCEDURE log_exception (p_logLev IN NUMBER := LOG_LEV_ERR, p_feature IN VARCHAR2, p_sp IN VARCHAR2, p_logmsg IN varchar2,
    p_logId IN NUMBER DEFAULT NULL,  p_dbmsOut IN BOOLEAN DEFAULT NULL)
IS
  v_msg  varchar2 (30000) := p_logmsg || K_NL || DBMS_UTILITY.format_error_backtrace ;
BEGIN
  -- IF SQLERRM is present
  IF (SQLERRM IS NOT NULL) THEN
    v_msg := v_msg || 'SQLERRM=' || SQLERRM;
  END IF;
  pa_utl.log (p_logLev, p_feature, p_sp, v_msg, p_logId, p_dbmsOut);
END log_exception;



/**
  - EXECUTE IMMEDIATE DROP TABLE ...
  - NO ERROR if alread it does not exist
  - In case of EXCEPTION log it (with details) and then RAISE a custom EXPTION EX_FILE_READ (with sqlerrm describing it)
  _param p_stmt IN varchar2  e.g  'DROP TABLE DTCT_OWN.TB_DTCT_DOCUMENTI'
  _param p_loglev    IN  NUMBER     LOG_LEV_xx: 0=LOG_LEV_ERR  1= LOG_LEV_WARN , .....
  _param p_feature   IN  VARCHAR2   Calling Feature. It will be logged only if enabled in UTL_CFG
  _param p_sp        IN  VARCHAR2   Calling SP (SP of the Feature p_feature)
  _param [p_logId]   IN  NUMBER     Optional ID used to group together the log messages of the same CALL.
  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo also with DMBS_OUTPUT.PUT_LINE
 */
PROCEDURE execute_stmt_drop (p_stmt IN VARCHAR2, p_loglev  IN  NUMBER, p_feature IN VARCHAR2, p_sp IN VARCHAR2,
    p_logId IN NUMBER :=NULL, p_dbmsOut IN BOOLEAN :=NULL)

IS
  v_msg varchar2(30000);
BEGIN
  pa_utl.log(p_loglev, p_feature, p_sp, p_stmt, p_logId,p_dbmsOut);
  BEGIN
    EXECUTE IMMEDIATE '' || p_stmt;
    EXCEPTION
      WHEN OTHERS THEN
        IF SQLCODE = -942 THEN
          RETURN;  -- OK it was already absent
        ELSE
          v_msg := 'EXCEPTION executing SQL: ' || K_NL || p_stmt;
          pa_utl.log_exception (LOG_LEV_ERR, p_feature, p_sp,v_msg, p_logId, p_dbmsOut);
          -- Custom EXCEPTION
          v_msg  := v_msg || K_NL || DBMS_UTILITY.format_error_backtrace || 'SQLERRM=' || sqlerrm;
          raise_application_error( K_EX_UTL, v_msg );
        END IF;
  END;
END execute_stmt_drop ;


/**
  - EXECUTE IMMEDIATE  a generic SQL Statement
  - LOG
  - In case of EXCEPTION log it (with details) and then RAISE a custom EXPTION EX_FILE_READ (with sqlerrm describing it)
  _param p_stmt IN varchar2  e.g  'CREATE TABLE ....'
  _param p_loglev    IN  NUMBER     LOG_LEV_xx: 0=LOG_LEV_ERR  1= LOG_LEV_WARN , .....
  _param p_feature   IN  VARCHAR2   Calling Feature. It will be logged only if enabled in UTL_CFG
  _param p_sp        IN  VARCHAR2   Calling SP (SP of the Feature p_feature)
  _param [p_logId]   IN  NUMBER     Optional ID used to group together the log messages of the same CALL.
  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo also with DMBS_OUTPUT.PUT_LINE

 */
PROCEDURE execute_stmt (p_stmt IN VARCHAR2, p_loglev  IN  NUMBER, p_feature IN VARCHAR2, p_sp IN VARCHAR2,
        p_logId IN NUMBER :=NULL, p_dbmsOut IN BOOLEAN :=NULL)
IS
  t_start TIMESTAMP := CURRENT_TIMESTAMP;
  v_msg varchar2(30000);
  n_rec NUMBER :=0;
BEGIN
  BEGIN
    EXECUTE IMMEDIATE '' || p_stmt;
    EXCEPTION
      WHEN OTHERS THEN
        v_msg := 'EXCEPTION executing SQL: ' || K_NL || p_stmt;
        pa_utl.log_exception (LOG_LEV_ERR,  p_feature, p_sp,v_msg, p_logId, p_dbmsOut);
        -- Custom EXCEPTION
        v_msg  := v_msg || K_NL || DBMS_UTILITY.format_error_backtrace || 'SQLERRM=' || sqlerrm;
        raise_application_error( K_EX_UTL, v_msg );
  END;
  n_rec := sql%rowcount;
  pa_utl.log(p_loglev, p_feature, p_sp, 'SQL=' || p_stmt || K_NL || ' REC=' || n_rec || time_elapsed (t_start), p_logId,p_dbmsOut);
END execute_stmt;



/**
Like execute_stmt, but also return n_rec that is meaningful only for some stmt: for this stmt you can use this function instead of execute_stmt
  - EXECUTE IMMEDIATE  a generic SQL Statement
  - LOG
  - In case of EXCEPTION log it (with details) and then RAISE a custom EXPTION EX_FILE_READ (with sqlerrm describing it)
  _param p_stmt IN varchar2  e.g  'CREATE TABLE ....'
  _param p_loglev    IN  NUMBER     LOG_LEV_xx: 0=LOG_LEV_ERR  1= LOG_LEV_WARN , .....
  _param p_feature   IN  VARCHAR2   Calling Feature. It will be logged only if enabled in UTL_CFG
  _param p_sp        IN  VARCHAR2   Calling SP (SP of the Feature p_feature)
  _param [p_logId]   IN  NUMBER     Optional ID used to group together the log messages of the same CALL.
  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo also with DMBS_OUTPUT.PUT_LINE

  _return    sql%rowcount
 */
FUNCTION execute_stmt_fun (p_stmt IN VARCHAR2, p_loglev  IN  NUMBER, p_feature IN VARCHAR2, p_sp IN VARCHAR2,
        p_logId IN NUMBER :=NULL, p_dbmsOut IN BOOLEAN :=NULL) RETURN NUMBER
IS
  t_start TIMESTAMP := CURRENT_TIMESTAMP;
  v_msg varchar2(30000);
  n_rec NUMBER :=0;
BEGIN
  BEGIN
    EXECUTE IMMEDIATE '' || p_stmt;
    EXCEPTION
      WHEN OTHERS THEN
        v_msg := 'EXCEPTION executing SQL: ' || K_NL || p_stmt;
        pa_utl.log_exception (LOG_LEV_ERR,  p_feature, p_sp,v_msg, p_logId, p_dbmsOut);
        -- Custom EXCEPTION
        v_msg  := v_msg || K_NL || DBMS_UTILITY.format_error_backtrace || 'SQLERRM=' || sqlerrm;
        raise_application_error( K_EX_UTL, v_msg );
        return n_rec;
  END;
  n_rec := sql%rowcount;
  pa_utl.log(p_loglev, p_feature, p_sp, 'SQL=' || p_stmt || K_NL || ' REC=' || n_rec || time_elapsed (t_start), p_logId,p_dbmsOut);
  return n_rec;
END execute_stmt_fun;





/**
  Get Number of lines of a file.
  _param p_dir IN VARCHAR2
  _param p_file IN VARCHAR2
  _return n_lines   -1 if files is not present
                    0 if is present but is empty
                    N present with N Lines
*/
FUNCTION file_get_nlines (p_dir IN VARCHAR2, p_file IN VARCHAR2)  RETURN number
IS
  f_type utl_file.file_type := NULL;
  v_line varchar2(10000);
  K_SP constant varchar2(128) := 'PA_UTL.file_get_nlines';
  b_exists BOOLEAN;
  n_length NUMBER;
  n_blocksize NUMBER;
  n_line number := 0;
begin
  UTL_FILE.fgetattr (p_dir, p_file, b_exists, n_length, n_blocksize);
  if (NOT b_exists) then
    return -1;
  end if;
  if (b_exists and n_length > 0) then
    f_type  := utl_file.fopen(p_dir, p_file, 'r');
    LOOP
      BEGIN
        UTL_FILE.GET_LINE(f_type,v_line);
        EXCEPTION WHEN No_Data_Found THEN
          EXIT;
      END;
      n_line := n_line + 1;
    end loop;
    utl_file.fclose (f_type);
  end if;
  return n_line;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE_FILE_EX (K_SP, p_dir, p_file);
      return -2;
end file_get_nlines;



/**
  Get size (in bytes) of a file.
  _param p_dir IN VARCHAR2
  _param p_file IN VARCHAR2
  _return n_lines   -1 if files is not present
                    0 if is present but is empty
                    N: num byte
*/
FUNCTION file_get_size (p_dir IN VARCHAR2, p_file IN VARCHAR2)  RETURN number
IS
  K_SP constant varchar2(128) := 'PA_UTL.file_get_size';
  b_exists BOOLEAN;
  n_length NUMBER;
  n_blocksize NUMBER;
BEGIN
  UTL_FILE.fgetattr (p_dir, p_file, b_exists, n_length, n_blocksize);
  if (NOT b_exists) then
    return -1;
  end if;
  return n_length;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE_FILE_EX (K_SP, p_dir, p_file);
      return -2;
end file_get_size;



/**
  - Read a File of MAX SIZE 32767 and return the v_buf_read
  - LOG the size of v_read_buf at Level p_logLev
  - Only if explicitily required by p_log_read_buf (default=FALSE) we log also v_buf_read
  - In case of EXCEPTION log it (with details) and then RAISE a custom EXPTION EX_FILE_READ (with sqlerrm describing it)

  _param p_dir IN VARCHAR2
  _param p_file IN VARCHAR2
  _param p_loglev    IN  NUMBER     LOG_LEV_xx: 0=LOG_LEV_ERR  1= LOG_LEV_WARN , ..... LOG_LEV_NOLOG if you do not want any LOG
  _param p_feature   IN  VARCHAR2   Calling Feature. It will be logged only if enabled in UTL_CFG
  _param [p_logId]   IN  NUMBER     Optional ID used to group together the log messages of the same CALL.
  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo also with DMBS_OUTPUT.PUT_LINE
  _param [p_log_read_buf] IN BOOLEAN := FALSE     If TRUE we log also p_buf_read

  _return v_read_buf   The File contents
*/
FUNCTION file_read (p_dir IN VARCHAR2, p_file IN VARCHAR2, p_loglev  IN  NUMBER := LOG_LEV_TRACE, p_feature IN VARCHAR2,
      p_logId IN NUMBER :=NULL, p_dbmsOut IN BOOLEAN :=NULL, p_log_read_buf IN BOOLEAN := FALSE)  RETURN varchar2
IS
  f_type utl_file.file_type := NULL;
  v_line varchar2(10000);
  b_first boolean  := true;
  K_SP constant varchar2(128) := 'PA_UTL.file_read';
  v_read_buf  varchar2(32767) := '';
  v_msg varchar2(10000);
BEGIN
    f_type  := utl_file.fopen(p_dir, p_file, 'R');
    LOOP
      BEGIN
        UTL_FILE.GET_LINE(f_type,v_line);
        if (b_first) THEN
          b_first := false;
          v_read_buf := v_line;
        else
          v_read_buf := v_read_buf || K_NL || v_line;
        END IF;
        EXCEPTION
          WHEN No_Data_Found THEN
          EXIT;
      END;
    end loop;
    utl_file.fclose (f_type);
    v_msg := 'DIR=' || p_dir || ' FILE='|| p_file || '  ReadSize=' || LENGTH (v_read_buf);
    if (p_log_read_buf) THEN
      pa_utl.log(p_loglev, p_feature, K_SP, v_msg || K_NL || 'ReadBuf=' || K_NL|| v_read_buf,  p_logId,p_dbmsOut);
    ELSE
      pa_utl.log(p_loglev, p_feature, K_SP, v_msg, p_logId,p_dbmsOut);
    END IF;
    return v_read_buf;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE_FILE_EX (K_SP, p_dir, p_file);
        return '';
end file_read;


/**
  - Read v_buf from a File SQL of MAX SIZE 32767
  - REPLACING the PlaceHolder and return v_sql
  - LOG v_sql at Level p_logLev
  - In case of EXCEPTION log it (with details) and then RAISE a custom EXPTION EX_FILE_READ (with sqlerrm describing it)

  _param p_dir IN VARCHAR2
  _param p_file IN VARCHAR2
  _param p_replace IN ARRAY_V2_V2   Array of PlaceHolder to be replaced and relative Values
  _param p_loglev    IN  NUMBER     LOG_LEV_xx: 0=LOG_LEV_ERR  1= LOG_LEV_WARN , ..... LOG_LEV_NOLOG if you do not want any LOG
  _param p_feature   IN  VARCHAR2   Calling Feature. It will be logged only if enabled in UTL_CFG
  _param [p_logId]   IN  NUMBER     Optional ID used to group together the log messages of the same CALL.
  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo also with DMBS_OUTPUT.PUT_LINE
  _param [p_log_sql_buf] IN BOOLEAN := FALSE     If TRUE we log also p_buf_read
  _return v_read_buf   The File contents
*/
FUNCTION file_sql_read (p_dir IN VARCHAR2, p_file IN VARCHAR2, p_replace IN ARRAY_V2_V2,
      p_loglev  IN  NUMBER := LOG_LEV_TRACE, p_feature IN VARCHAR2,
      p_logId IN NUMBER :=NULL, p_dbmsOut IN BOOLEAN :=NULL, p_log_sql_buf IN BOOLEAN := FALSE)  RETURN varchar2

IS
  K_SP varchar2(128) := 'PA_UTL.file_sql_read';
  v_sql  varchar2(32767) := '';
  v_el varchar2(128);
  v_repl_msg varchar2(10000) := 'REPLACE'; -- The msg describing the v_ar
  v_msg varchar2(10000);
  n_pos number;
BEGIN
  v_sql := file_read (p_dir, p_file, LOG_LEV_NOLOG, p_feature, p_logId, p_dbmsOut);
  v_el := p_replace.FIRST;  -- Get first element of array
  -- Replace and prepare v_ar_msg
  WHILE v_el IS NOT NULL LOOP
    v_repl_msg := v_repl_msg || K_NL || '   ' || v_el || ' = ' || p_replace(v_el);   -- prepare replace msg (for log)
    v_sql := REPLACE (v_sql, v_el, p_replace(v_el));  -- Make the REPLACE
    v_el := p_replace.NEXT(v_el);  -- Get next element of array
  END LOOP;
  n_pos := INSTR(v_sql, ';', -1);  -- Pos of last ;
  if (n_pos > 0) THEN
    v_sql := substr (v_sql, 1, n_pos -1);
  end if;

  v_msg := 'DIR=' || p_dir || ' FILE='|| p_file || K_NL || v_repl_msg;
  if (p_log_sql_buf) then
    pa_utl.log(p_loglev, p_feature, k_sp, v_msg || K_NL || 'RETURN SQL:' || K_NL || v_sql, p_logId,p_dbmsOut);
  else
    pa_utl.log(p_loglev, p_feature, k_sp, v_msg,  p_logId,p_dbmsOut);
  end if;
  return v_sql;
end file_sql_read;





/* ======================================================================================================================================
=========================================================================================================================================
                                      LOG STATUS
=========================================================================================================================================
====================================================================================================================================== */
/**
 _return  next Log_id  that can be used to group together in UTL_LOG the log messages of the same functionality
 * */
FUNCTION  log_status_group_id_get_next RETURN NUMBER
IS
  n_group_id NUMBER := DWH.SEQ_LOG_STATUS_GROUP_ID.NEXTVAL;
BEGIN
  -- Update UTL_CFG
  log_status_group_id_set_cur (n_group_id);
  return n_group_id;
END log_status_group_id_get_next;

/**
 _param p_group_id in number  set in UTL_CFG current value of  groupId that can be retrieved using log_status_group_id_get_cur
 * */
PROCEDURE  log_status_group_id_set_cur (p_group_id in number)
IS
BEGIN
  -- Update UTL_CFG
  UPDATE DWH.UTL_CFG SET VAL_NUM=p_group_id WHERE PAR='LOG_STATUS_GROUP_ID';
  COMMIT;
END log_status_group_id_set_cur;

/**
 _return  Current Log_id  used to group together in UTL_LOG the log messages of the same functionality
 * */
FUNCTION log_status_group_id_get_cur RETURN NUMBER
IS
  n_log_id NUMBER;
BEGIN
  SELECT VAL_NUM into n_log_id FROM DWH.UTL_CFG WHERE PAR='LOG_STATUS_GROUP_ID';
  return n_log_id;
END log_status_group_id_get_cur;



/**
 Start a new REcord with PK <LOG_ID, GROUP_ID, SP> into utl_log_status:
 - If PK <LOG_ID, GROUP_ID, SP> already exist into UTL_LOG_STATUS, we delete it
 - INSERT a New Record with PK <LOG_ID, GROUP_ID, SP> into UTL_LOG_STATUS, setting startDate

  _param p_logId IN NUMBER   <LOG_ID, GROUP_ID, SP> identify the SP Status
  _param p_groupId IN NUMBER   can be used to group together different SP running in parallel
  _param p_feature IN VARCHAR2
  _param p_sp IN VARCHAR2
  _param p_status IN VARCHAR2 :=  LOG_STATUS_RUNNING
  _param p_detail IN VARCHAR2 := ''      Can also be > 4000 bytes
  _param [p_dbmsOut] IN BOOLEAN     default FALSE
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo also with DMBS_OUTPUT.PUT_LINE
*/
PROCEDURE log_status_start (p_logId IN NUMBER, p_groupId IN NUMBER, p_feature IN varchar2, p_sp IN VARCHAR2, p_status IN VARCHAR2 := LOG_STATUS_RUNNING,
   p_detail IN VARCHAR2 := '', p_dbmsOut in boolean:=false)
IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  b_dbmsOut boolean := p_dbmsOut;
  v_logDesc varchar2(5000);
  v_seeCLOB varchar2(1000);
BEGIN
  v_logDesc:='[log_status_start] p_logId=' || p_logId  || ' p_groupId=' || p_groupId || ' p_sp=' || p_sp || ' p_status=' || p_status;
  IF (b_dbmsOut) THEN
     DBMS_OUT(v_logDesc);
  END IF;
  -- If PK <LOG_ID, GROUP_ID, SP> already exist into UTL_LOG_STATUS, we delete it
  log_status_delete (p_logId, p_groupId ,p_feature ,p_sp, p_dbmsOut);
  IF (b_dbmsOut) THEN
     DBMS_OUT('INSERT into UTL_LOG_STATUS New Rec with PK <LOG_ID, GROUP_ID, SP>');
  END IF;
  -- Check LEN: if LEN > MAX_LEN_LOG_MSG we will use CLOB
  IF (LENGTH (p_detail) > MAX_LEN_LOG_MSG) THEN
    v_seeCLOB := K_SEE_MSG_CLOB || v2_trunc(p_detail,30);
    INSERT INTO DWH.UTL_LOG_STATUS (LOG_ID, GROUP_ID, FEATURE, SP, START_DATE, STATUS, DETAIL, DETAIL_CLOB)
          VALUES (p_logId, p_groupId, p_feature, p_sp, SYSDATE, p_Status, v_seeCLOB, p_detail);
  ELSE
    INSERT INTO DWH.UTL_LOG_STATUS (LOG_ID, GROUP_ID, FEATURE, SP, START_DATE, STATUS, DETAIL)
         VALUES (p_logId, p_groupId, p_feature, p_sp, SYSDATE, p_Status, p_detail);
  END IF;
  COMMIT;

  EXCEPTION WHEN OTHERS THEN
    DBMS_OUT ('ERROR: ' || TO_CHAR(SQLCODE) || ' - ' || SQLERRM || K_NL || v_logDesc);
    COMMIT;

END log_status_start;

/**
 Update in utl_log_status the Status of <LOG_ID, SP>:
 - If PK <LOG_ID, GROUP_ID, SP> NOT still exist in UTL_LOG_STATUS, we INSERT a New Record with PK <LOG_ID, GROUP_ID, SP> into UTL_LOG_STATUS, setting startDate
 - Update the Record with PK <LOG_ID, GROUP_ID, SP> in UTL_LOG_STATUS, setting LastDate and ElapsedSec

  _param p_logId IN NUMBER   <LOG_ID, GROUP_ID, SP> identify the SP Status
  _param p_groupId IN NUMBER   can be used to group together different SP running in parallel
  _param p_feature IN VARCHAR2
  _param p_sp IN VARCHAR2
  _param p_status IN VARCHAR2
  _param p_detail IN VARCHAR2 := ''      Can also be > 4000 bytes
  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo also with DMBS_OUTPUT.PUT_LINE
*/
PROCEDURE log_status_update (p_logId IN NUMBER, p_groupId IN NUMBER,p_feature IN VARCHAR2, p_sp IN VARCHAR2, p_status IN VARCHAR2, p_detail IN VARCHAR2 := '', p_dbmsOut in boolean:=false)
IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  d_start DATE;
  d_last  DATE := SYSDATE;
  n_elapsedSec NUMBER;
  b_dbmsOut boolean := p_dbmsOut;
  v_logDesc varchar2(5000);
  v_seeCLOB varchar2(1000);
  n_rec number := 0;
BEGIN
  log_aging;  -- Only if required make the AGING
  v_logDesc:='[log_status_update] p_logId=' || p_logId  || ' p_groupId=' || p_groupId || ' p_sp=' || p_sp || ' p_status=' || p_status || ' n_elapsedSec=' || n_elapsedSec;
  IF (b_dbmsOut) THEN
    DBMS_OUT(v_logDesc);
    DBMS_OUT('Check if already exist REC with PK <LOG_ID, GROUP_ID, SP>');
  END IF;
  -- If PK <LOG_ID, GROUP_ID, SP> NOT still exist in UTL_LOG_STATUS, we INSERT a New Record with PK <LOG_ID, GROUP_ID, SP> into UTL_LOG_STATUS, setting startDate
  SELECT COUNT(*) INTO n_rec FROM DWH.UTL_LOG_STATUS WHERE LOG_ID = p_logId AND SP = p_sp AND GROUP_ID = p_groupId;
  IF n_rec = 0 THEN
    DBMS_OUT('REC with PK <LOG_ID, GROUP_ID, SP> WAS NOT Present. We insert it');
    log_status_start (p_logId, p_groupId, p_feature, p_sp);
  END IF;

  SELECT START_DATE INTO d_start  FROM DWH.UTL_LOG_STATUS WHERE LOG_ID = p_logId AND SP = p_sp AND GROUP_ID = p_groupId;
  n_elapsedSec := time_diff_sec (d_last, d_start);
  -- FOR DEBUG
  -- log(LOG_LEV_TRACE, p_feature, p_sp, v_logDesc, p_logId, b_dbmsOut);
  IF (b_dbmsOut) THEN
     DBMS_OUT(v_logDesc);
  END IF;
  IF (LENGTH (p_detail) > MAX_LEN_LOG_MSG) THEN
    v_seeCLOB := K_SEE_MSG_CLOB || v2_trunc(p_detail,30);
    UPDATE DWH.UTL_LOG_STATUS
        SET LAST_DATE = d_last,
        ELAPSED_SEC = n_elapsedSec,
        STATUS = p_status,
        DETAIL = K_SEE_DETAIL_CLOB,
        DETAIL_CLOB = p_detail
    WHERE LOG_ID = p_logId AND SP = p_sp AND GROUP_ID = p_groupId;
  ELSE
    UPDATE DWH.UTL_LOG_STATUS
        SET LAST_DATE = d_last,
        ELAPSED_SEC = n_elapsedSec,
        STATUS = p_status,
        DETAIL = p_detail,
        DETAIL_CLOB = NULL
    WHERE LOG_ID = p_logId AND SP = p_sp AND GROUP_ID = p_groupId;
  END IF;
  COMMIT;

  EXCEPTION WHEN OTHERS THEN
    DBMS_OUT ('ERROR: ' || TO_CHAR(SQLCODE) || ' - ' || SQLERRM || K_NL || v_logDesc);
    COMMIT;

END log_status_update;

/**
 delete a log_status identified by <LOG_ID, GROUP_ID, SP>, if exist
  _param p_logId IN NUMBER   <LOG_ID, GROUP_ID, SP> identify the SP Status
  _param p_groupId IN NUMBER   can be used to group together different SP running in parallel
  _param p_feature IN VARCHAR2
  _param p_sp IN VARCHAR2
  _param [p_dbmsOut] IN BOOLEAN     default NULL (use default option=FALSE if not changed with log_set_opt)
                                                - TRUE to call also DMBS_OUTPUT.PUT_LINE - if set to TRUE you can set DBMS_OUTPUT.ENABLE (buffer_size => NULL)
                                                - FALSE do not echo also with DMBS_OUTPUT.PUT_LINE
*/
PROCEDURE log_status_delete (p_logId IN NUMBER, p_groupId IN NUMBER, p_feature IN VARCHAR2, p_sp IN VARCHAR2, p_dbmsOut in boolean:=false) IS
  v_logDesc varchar2(5000);
  n_rec number := 0;
BEGIN
  v_logDesc:='[log_status_delete] p_logId=' || p_logId  || ' p_groupId=' || p_groupId || ' p_sp=' || p_sp;
  -- log(LOG_LEV_TRACE, p_feature, p_sp, v_logDesc, p_logId, p_dbmsOut);
  SELECT COUNT(*) INTO n_rec FROM DWH.UTL_LOG_STATUS WHERE LOG_ID = p_logId AND SP = p_sp AND GROUP_ID = p_groupId;
  IF n_rec > 0 THEN
    IF (p_dbmsOut) THEN
      DBMS_OUT(v_logDesc);
    END IF;
    DELETE FROM DWH.UTL_LOG_STATUS  WHERE LOG_ID = p_logId AND SP = p_sp AND GROUP_ID = p_groupId;
    COMMIT;
  END IF;

  EXCEPTION WHEN OTHERS THEN
    DBMS_OUT ('ERROR: ' || TO_CHAR(SQLCODE) || ' - ' || SQLERRM || K_NL || v_logDesc);
    COMMIT;
END log_status_delete;


END;
/
