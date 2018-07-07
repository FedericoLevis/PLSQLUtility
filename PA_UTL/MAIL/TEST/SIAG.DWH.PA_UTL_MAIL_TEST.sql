CREATE OR REPLACE PACKAGE DWH.PA_UTL_MAIL_TEST IS


/**
<b>File:</b>            DWH.PA_UTL_MAIL_TEST.sql  </BR>
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
<b>First Version:</b>  ver 1.0 - May 2018   </BR>
<b>Current Version:</b>ver 1.0 - May 2018  </BR>
----------------------------------------------------------------------------------- </BR>
<b>DISCLAIMER</b> </BR>
Copyright by Federico Levis - <a href="https://github.com/FedericoLevis/PLSQLUtility" target="_blank">PL SQL Utilty</a>  </BR>
This file may be freely distributed under the MIT license.
*/



/**
Send a standard mail with ERROR, sent to the dest configured in DWH.UTL_MAIL_DEST for  p_app_sp
Description see Package Specification
_param p_feat in varchar2 feat that must be enabled in UTL_LOG_CFG to enable log
_param p_logId in number for pa_utl.og
_param p_app_sp in varchar2   e.g 'kpib_monitor_au'  SP that must be configured in DWH.UTL_MAIL_DEST to enbale mail send
_param p_dbmsOut BOOLEAN  := FALSE  true to enable dbms_out (for debug)
*/
PROCEDURE  MAIL_STANDARD_ERR(p_feat in varchar2, p_app_sp in varchar2, p_logId in number, p_dbmsOut BOOLEAN  := FALSE) ;


/**
Send a standard mail with Information, sent to the dest configured in DWH.UTL_MAIL_DEST for  p_app_sp
Description see Package Specification
_param p_feat in varchar2 feat that must be enabled in UTL_LOG_CFG to enable log
_param p_app_sp in varchar2   e.g 'kpib_monitor_au'  SP that must be configured in DWH.UTL_MAIL_DEST to enbale mail send
_param p_logId in number for pa_utl.og
_param p_dbmsOut BOOLEAN  := FALSE  true to enable dbms_out (for debug)
*/
PROCEDURE  MAIL_STANDARD_INFO(p_feat in varchar2, p_app_sp in varchar2
     ,p_logId in number:= null, p_dbmsOut BOOLEAN  := FALSE);

/**
Send a standard mail with 2 Attachment (1 File and 1 content_v2 that will generate a file), sent to the dest configured in DWH.UTL_MAIL_DEST for  p_app_sp
Description see Package Specification
_param p_feat in varchar2 feat that must be enabled in UTL_LOG_CFG to enable log
_param p_app_sp in varchar2   e.g 'kpib_monitor_au'  SP that must be configured in DWH.UTL_MAIL_DEST to enbale mail send
_param p_dir in varchar2 := null  set it to attach p_file that is in p_dir
_param p_file in varchar2 :null  set it to attach p_file that is in p_dir
_param p_file_desc in varchar2 :null
_param p_logId in number for pa_utl.og
_param p_dbmsOut BOOLEAN  := FALSE  true to enable dbms_out (for debug)
*/
PROCEDURE  MAIL_STANDARD_ATTACH(p_feat in varchar2, p_app_sp in varchar2
     ,p_dir in varchar2 := null, p_file in varchar2:= null,p_file_desc in varchar2:=null, p_file_mime_type in varchar2:=null
     ,p_logId in number:= null, p_dbmsOut BOOLEAN  := FALSE);


END PA_UTL_MAIL_TEST;
/
CREATE OR REPLACE PACKAGE BODY DWH.PA_UTL_MAIL_TEST IS

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





/*----------------------------------------------------------------------
             GLOBAL API
------------------------------------------------------------------------*/

/**
Send a standard mail with ERROR to the dest configured in DWH.UTL_MAIL_DEST for  p_app_sp
Description see Package Specification
*/
PROCEDURE  MAIL_STANDARD_ERR(p_feat in varchar2, p_app_sp in varchar2, p_logId in number, p_dbmsOut BOOLEAN  := FALSE)
IS
  K_SP VARCHAR2(100) := 'MAIL_STANDARD_ERR'; -- Name of this SP
  n_logId NUMBER := p_logId; -- Get the logId
  d_start date := sysdate;
  r_mail dwh.pa_utl_mail.rec_mail_standard;
  v_desc varchar2(1000):= 'Example of description with an error and newline: <BR/>' ||
'This is the second line
This is the line3
This is the line4 very long to see what happend....if it automatically go to the new line or if it create any layout problem';
  ar_tblTr dwh.pa_utl_mail.array_tr := dwh.pa_utl_mail.array_tr(
    dwh.pa_utl_mail.rec_tr_init('RESULT:', '<b>ERROR</b>', dwh.pa_utl_mail.K_CLASS_MAIL_ERR) ,
    dwh.pa_utl_mail.rec_tr_init('Description:', v_desc, dwh.pa_utl_mail.K_CLASS_MAIL_ERR),
    dwh.pa_utl_mail.rec_tr_init('Periodo', '[10:12:56 .. 10:58:12] <b>34 sec</b>', dwh.pa_utl_mail.K_CLASS_MAIL)
    );
BEGIN
  DWH.pa_utl.log(LOG_LEV_INFO,p_feat, K_SP, 'START',  n_logId, p_dbmsOut);

  r_mail.v_app_sp := p_app_sp;
  r_mail.n_status := dwh.pa_utl_mail.K_STATUS_KO;
  -- insert some rows
  r_mail.v_subject := 'TEST Errore';
  r_mail.ar_tblTr := ar_tblTr;
  DWH.pa_utl_mail.mail_standard (r_mail, n_logId, p_dbmsOut);
  -- Log elapsed sec
  DWH.pa_utl.log_elapsed_sec(LOG_LEV_INFO,p_feat, K_SP, d_start,' - END',  n_logId,p_dbmsOut);
  -- Log elapsed msec
END MAIL_STANDARD_ERR;


/**
Send a standard mail with Information, sent to the dest configured in DWH.UTL_MAIL_DEST for  p_app_sp
Description: see Package Specification
*/
PROCEDURE  MAIL_STANDARD_INFO(p_feat in varchar2, p_app_sp in varchar2
     ,p_logId in number:= null, p_dbmsOut BOOLEAN  := FALSE)
IS
  K_SP VARCHAR2(100) := 'MAIL_STANDARD_INFO'; -- Name of this SP
  n_logId NUMBER := p_logId; -- Get the logId
  d_start date := sysdate;
  r_mail dwh.pa_utl_mail.rec_mail_standard;
  v_desc varchar2(1000):= 'Example of description with newline: <BR/>' ||
'This is the second line
This is the line3
This is the line4 very long to see what happend....if it automatically go to the new line or if it create any layout problem';
  ar_tblTr dwh.pa_utl_mail.array_tr := dwh.pa_utl_mail.array_tr(
    dwh.pa_utl_mail.rec_tr_init('Description:', v_desc ),
    dwh.pa_utl_mail.rec_tr_init('Periodo', '[10:12:56 .. 10:58:12] <b>34 sec</b>'),
    dwh.pa_utl_mail.rec_tr_init('NOTES:', 'some POD were Missing',dwh.pa_utl_mail.K_CLASS_MAIL_NOTE )
    );
 v_info varchar2(32767) :='
This is an example of <b>Mail Information:</b>
<ul>
  <li>First Line of Information</li>
  <li>Line 2 of Information</li>
  <li>Line 3 of Information</li>
</ul>
';

BEGIN
  DWH.pa_utl.log(LOG_LEV_INFO,p_feat, K_SP, 'START',  n_logId, p_dbmsOut);

  r_mail.v_app_sp := p_app_sp;
  r_mail.n_status := dwh.pa_utl_mail.K_STATUS_OK;
  r_mail.n_lan := dwh.pa_utl_mail.K_LAN_ITA;
  -- insert some rows
  r_mail.v_subject := 'EXAMPLE of TEST OK';
  r_mail.ar_tblTr := ar_tblTr;
  r_mail.v_info := v_info;


  DWH.pa_utl_mail.mail_standard (r_mail, n_logId, p_dbmsOut);
  -- Log elapsed sec
  DWH.pa_utl.log_elapsed_sec(LOG_LEV_INFO,p_feat, K_SP, d_start,' - END',  n_logId,p_dbmsOut);
  -- Log elapsed msec

END MAIL_STANDARD_INFO;





/**
Send a standard mail with 2 Attachment, to the dest configured in DWH.UTL_MAIL_DEST for  p_app_sp
Description: see Package Specification
*/
PROCEDURE  MAIL_STANDARD_ATTACH(p_feat in varchar2, p_app_sp in varchar2
     ,p_dir in varchar2 := null, p_file in varchar2:= null,p_file_desc in varchar2:=null, p_file_mime_type in varchar2:=null
     ,p_logId in number:= null, p_dbmsOut BOOLEAN  := FALSE)
IS
  K_SP VARCHAR2(100) := 'MAIL_STANDARD_ATTACH'; -- Name of this SP
  n_logId NUMBER := p_logId; -- Get the logId
  d_start date := sysdate;
  r_mail dwh.pa_utl_mail.rec_mail_standard;
  ar_tblTr dwh.pa_utl_mail.array_tr := dwh.pa_utl_mail.array_tr(
    dwh.pa_utl_mail.rec_tr_init('Description:', 'This a Test with 2 attachments' ),
    dwh.pa_utl_mail.rec_tr_init('Period', '[10:12:56 .. 10:58:12] <b>34 sec</b>')
    );
 -- ===================== For ATTACHMENT
 r_content_file dwh.pa_utl_mail.rec_content_file := dwh.pa_utl_mail.rec_content_file_init (p_dir, p_file);
 v_attach_v2 varchar2(32767) :='
 <div>
 <input type="button" value="test" onclick="alert(''ciao'')" /> <BR/>
This is an example of <b><i>DEBUG</i>Information:</b>
				<table class="mailInfo" BORDER="1" cellspacing="0" cellpadding="2" width="100%">
				   <tr class="mailInfoTitle " >
					  <td width="50%">SP</td>
					  <td width="15%">Start</td>
					  <td width="15%">End</td>
					  <td width="20%">Result</td>
				   </tr>
				   <tr class="mailInfoAlt">
					  <td>kpib_monitor_au 1</td>
					  <td style="text-align:center">10:54:01</td>
					  <td style="text-align:center">10:55:55</td>
					  <td class="mailOk">OK</td>
				   </tr>
				   <tr class="mailInfoAlt">
					  <td>kpib_monitor_au 2</td>
					  <td style="text-align:center">10:56:01</td>
					  <td style="text-align:center">10:57:55</td>
					  <td class="mailErr">ERROR</td>
				   </tr>
				</table>
   </div>
';
  r_content_v2 dwh.pa_utl_mail.rec_content_v2 := dwh.pa_utl_mail.rec_content_v2_init ('DebugInfo.html',v_attach_v2);

  /*
    function rec_attach_init (v_desc IN varchar2,
     v_mime_type in varchar2:= K_MIME_TXT_PLAIN,
     v_content_type varchar2 := K_CONTENT_TYPE_FILE,
     r_content_file in rec_content_file := null,
     r_content_v2 in rec_content_v2 := null
     ) return rec_attach
*/
  r_attach_file dwh.pa_utl_mail.rec_attach := dwh.pa_utl_mail.rec_attach_init(
                p_desc => p_file_desc,
                p_content_type => dwh.pa_utl_mail.K_CONTENT_TYPE_FILE,
                p_content_file => r_content_file
     );
  r_attach_v2 dwh.pa_utl_mail.rec_attach := dwh.pa_utl_mail.rec_attach_init(
                p_desc => 'Debug Information',
                p_content_type => dwh.pa_utl_mail.K_CONTENT_TYPE_V2,
                p_content_v2 => r_content_v2
     );

  -- ar_attach dwh.pa_utl_mail.array_attach := dwh.pa_utl_mail.array_attach(r_attach_file, r_attach_v2);
  ar_attach dwh.pa_utl_mail.array_attach := dwh.pa_utl_mail.array_attach(r_attach_v2,r_attach_file);

BEGIN
  DWH.pa_utl.log(LOG_LEV_INFO,p_feat, K_SP, 'START',  n_logId, p_dbmsOut);

  r_mail.v_app_sp := p_app_sp;
  r_mail.n_status := dwh.pa_utl_mail.K_STATUS_OK;
  r_mail.n_lan := dwh.pa_utl_mail.K_LAN_ITA;
  -- insert some rows
  r_mail.v_subject := 'EXAMPLE of TEST OK';
  r_mail.ar_tblTr := ar_tblTr;
  r_mail.ar_attach := ar_attach;


  DWH.pa_utl_mail.mail_standard (r_mail, n_logId, p_dbmsOut);
  -- Log elapsed sec
  DWH.pa_utl.log_elapsed_sec(LOG_LEV_INFO,p_feat, K_SP, d_start,' - END',  n_logId,p_dbmsOut);
  -- Log elapsed msec



END MAIL_STANDARD_ATTACH;





END PA_UTL_MAIL_TEST;
/
