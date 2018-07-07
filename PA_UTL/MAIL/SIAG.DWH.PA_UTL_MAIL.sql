CREATE OR REPLACE PACKAGE DWH.PA_UTL_MAIL
   AUTHID DEFINER
IS
/**
* =================================================================================================== </BR>
* Package with MAIL utilty </BR>
* Author:  Federico Levis </BR>
* Last Date Modify: 11/05/2018  </BR>
* DB Interface : UTL_MAIL_CFG  </BR>
* Used Packages : PA_UTL  </BR>
* Example: PA_UTL_MAIL_TEST  </BR>
* =================================================================================================== </BR>
*
*/



  /** ==================================================================================
                      DEFAULT (Used IF UTL_MAIL_CFG is not properly set)
  ================================================================================== */
  K_SMTP_SERVER CONSTANT varchar2(120) :=  'smtp-mi.risorse.enel';
  K_SMTP_SERVER_PORT CONSTANT number :=  25;
  K_DIR_MAIL_CSS         constant varchar2(128) := 'HB_MAIL_CSS';
  K_F_MAIL_CSS  constant varchar2(128) := 'mail.css';

  -- mail configuration
  type rec_mail_cfg is record(
    v_smtp_server varchar2(128) := K_SMTP_SERVER   -- SMTP server name
    ,n_smtp_port number := K_SMTP_SERVER_PORT -- SMTP server port
    ,v_dir_css varchar2(128) := K_DIR_MAIL_CSS  --   DIRECTORY with css style file for mail
    ,v_f_css varchar2(128) := K_F_MAIL_CSS   --  CSS FILE with style: mail.css
  );



  /** ==================================================================================
                       mail_standard Interface
  ================================================================================== */

  /** ==================================================================================
  STATUS used in rec_mail_standard.n_status
  ================================================================================== */
  K_STATUS_KO       constant number := 0;
  K_STATUS_OK        constant number := 1;
  K_STATUS_WARN      constant number := 2;  --

  /** ==================================================================================
  LANGUAGE Supported (messages displayed) in mail_standard
  ================================================================================== */
  K_LAN_ENG       constant number := 1;
  K_LAN_ITA       constant number := 2;

  K_LAN_DEF       constant number := K_LAN_ITA;  -- Default (when not set)



  /**
  class style defined in mail.css
  */
  K_CLASS_MAIL constant varchar(64) := 'mail';
  K_CLASS_MAIL_ERR constant varchar(64) := 'mailErr';
  K_CLASS_MAIL_OK constant varchar(64) := 'mailOk';
  K_CLASS_MAIL_INFO constant varchar(64) := 'mailInfo';
  K_CLASS_MAIL_NOTE constant varchar(64) := 'mailNote';
  K_CLASS_MAIL_WARN constant varchar(64) := 'mailWarn';
  K_CLASS_MAIL_INFO_TITLE constant varchar(64) := 'mailInfoTitle';

  K_CLASS_MAIL_LEFT constant varchar(64) := 'mailLeft';
  K_CLASS_MAIL_RIGHT constant varchar(64) := 'mailRight';
  K_CLASS_MAIL_CENTER constant varchar(64) := 'mailCenter';

  K_CLASS_MAIL_ATTACH constant varchar(64) := 'mailAttach';  -- HTML attachment


  -- 1 row (tr>) of the  Tabella (<table>).
  type rec_tr is record(
    v_td_hea varchar2 (200) := ''     -- First Col: Header (also HTML)
    ,v_td_txt varchar2 (32767) := ''   -- Second Col  (also HTML)
    ,v_txt_class varchar2 (100) := K_CLASS_MAIL   -- style
  );
  -- K_MAX_TR constant number := 50;  --
  type array_tr is varray(50) of rec_tr;  -- generic tr array (max 50 elements)


  /**  attachment type
  */
  K_CONTENT_TYPE_FILE constant varchar(32) := 'FILE';
  K_CONTENT_TYPE_V2 constant varchar(32) := 'V2';


  type rec_content_file is record (
    v_file varchar2 (128) := null -- fileName (it is in v_dir)
    ,v_dir  varchar2 (128) := null  -- logical DIRECTORY
  );

  type rec_content_v2 is record (
    v_file varchar2 (128) := '' -- name of the file atttachment to generate
    ,v_content varchar2 (32767) := null --
  );

  /**
    ATTACHMENTS rec
   */
  type rec_attach is record (
    v_desc  varchar2(1024) := ''
    ,v_content_type varchar2 (32) := K_CONTENT_TYPE_FILE  --  K_CONTENT_TYPE_FILE or K_CONTENT_TYPE_V2
    ,r_content_file rec_content_file := null   -- For v_content_tytpe=K_CONTENT_TYPE_FILE
    ,r_content_v2 rec_content_v2 := null   -- For v_content_tytpe=K_CONTENT_TYPE_V2
  );

  /**
    generic rec_attach array(max 50 elements)
  */
  -- K_MAX_ATTACH constant number := 50;  --
  type array_attach is varray(50) of rec_attach;  --


  /**
     par for  mail_standard
  */
  type rec_mail_standard is record(
    n_lan number := K_LAN_ENG,   -- language to be used for default text displayed
    v_app_sp  varchar2(128), --   Calling SP  (the Sp is searched into utl_mail_dest_cfg)    E.G.   'kpib_monitor_au'
    n_status number, --  {K_STATUS_KO 0, K_STATUS_OK 1, K_STATUS_WARN 2}
    v_subject varchar2 (1024)    -- Subject and <table> title
    -- ------------------------- TBL
    ,n_tblWidthPerc number := 80  -- TBL width Percentage (of the page)
    ,ar_tblTr array_tr  -- array with the TBL tr. NOTE First tr with RESULT based on n_status is automatically added
    ,n_td1WidthPerc number := 20  -- Percentage of First td of the Tbl (Header)
    -- ------------------------- OPTIONAL Information
    ,v_info varchar2(32767) := null  -- Optional information (also HTML) displayed in a div after the TABLE clicking on 'Show Debug Information'
    ,ar_attach array_attach := array_attach()  -- Optional array with File attachment, init to empty (no attachment)
  );




   TYPE ty_cursorehistory IS REF CURSOR;

  /* ==================================================================================
                      CUSTOM EXCEPTION
  ================================================================================== */
  K_EX_UTL_MAIL constant NUMBER := -20002;
  EX_UTL_MAIL EXCEPTION;
  PRAGMA EXCEPTION_INIT(EX_UTL_MAIL, -20002 );


   FUNCTION get_cvs_revision RETURN VARCHAR2;

   PROCEDURE install;

   FUNCTION get_history RETURN ty_cursorehistory;
   ----------------------------------------------


   /** **********************************************************************************
   Send Mail with attachments (optional)
  _param p_mail_cfg         in rec_mail_cfg
  _param p_from            in varchar2
  _param p_dest_to         in varchar2
  _param [p_dest_cc]         in varchar2 default null
  _param p_subject         in varchar2
  _param p_msg             in varchar2     HTML message
  _param p_ar_attach  in array_attach      array with attchments (can be empty).
  _param [p_logId]   IN  NUMBER              log_id used dwh.utl_log
  _param [p_dbmsOut]  IN  boolean:=false   udes with utl_log
  ********************************************************************************** */
  procedure mail_send  (
              p_mail_cfg         in rec_mail_cfg
              ,p_from            in varchar2
              ,p_dest_to         in varchar2
              ,p_dest_cc         in varchar2 default null
              ,p_subject         in varchar2
              ,p_msg             in varchar2
              ,p_ar_attach       in array_attach
              ,p_logId           in number:=null
              ,p_dbmsOut         in boolean:=false
              );



  /** **********************************************************************************
  send email with standard layout
  _param p_mail in  rec_mail_standard    mail desc
                                         NOTE:  The attachments (ar_attach if present) will be inserted only if the DB rec invoilved (UTL_MAIL_DEST_CFG) has FLAG_ATTACH=1

  _param [p_logId]   IN  NUMBER              log_id used dwh.utl_log
  _param [p_dbmsOut]  IN  boolean:=false   udes with utl_log
  ********************************************************************************** */
  procedure mail_standard(p_mail in  rec_mail_standard, p_logId in number, p_dbmsOut in boolean:=false );



  /** **********************************************************************************
  Initialize and return  a rec_content_file
  _param v_dir IN varchar2
  _param v_file IN varchar2
  _return rec_content_file  initialized with the parameter passed
  ********************************************************************************** */
  function rec_content_file_init (p_dir IN varchar2, p_file IN varchar2) return rec_content_file ;

  /** **********************************************************************************
  Initialize and return  a rec_content_v2
  _param v_file IN varchar2
  _param v_content in varchar2
  _return rec_content_v2  initialized with the parameter passed
  ********************************************************************************** */
  function rec_content_v2_init (p_file IN varchar2, p_content in varchar2) return rec_content_v2 ;

  /** **********************************************************************************
  Initialize and return  a rec_attach
  ********************************************************************************** */
  function rec_attach_init (p_desc IN varchar2,
     p_content_type varchar2 := K_CONTENT_TYPE_FILE,
     p_content_file in rec_content_file := null,
     p_content_v2 in rec_content_v2 := null
     ) return rec_attach;



  /** **********************************************************************************
  Initialize and return  a rec_tr
  _param p_td_hea in varchar2
  _param p_td_txt in varchar2
  _param p_txt_class in varchar2 := K_CLASS_MAIL
  _return rec_tr initialized with the parameter passed
  ********************************************************************************** */
  function rec_tr_init (p_td_hea in varchar2, p_td_txt in varchar2, p_txt_class in varchar2 := K_CLASS_MAIL) return rec_tr;





END PA_UTL_MAIL;
/
CREATE OR REPLACE PACKAGE BODY DWH.PA_UTL_MAIL IS


  k_linep_package CONSTANT VARCHAR2(15) := 'DWH';
  k_nome_package  CONSTANT VARCHAR2(50) := 'PA_UTL_MAIL';

  K_boundary           constant varchar2(30) := 'DMW.Boundary.605592468';


  K_CRLF CONSTANT  varchar2(2)   := chr(13) || chr(10);



  /* ===========================================================================================================================
                                                      LAN
     ========================================================================================================================= */
  -- index used internally to read the LAN TEXT

  /* ===========================================================================================================================
                                                      MAIL_STANDARD LAN Text
     ========================================================================================================================= */
  type array_lan is varray(2) of varchar2(128);
  -- ENG, ITA

  K_LAN_RESULT array_lan := array_lan('Result:', 'Risultato:');
  K_LAN_ERROR array_lan := array_lan('ERROR', 'ERRORE');
  K_LAN_WARNING array_lan := array_lan('WARNING', 'WARNING');
  K_LAN_OK array_lan := array_lan('OK', 'OK');

  K_LAN_ATTACH array_lan := array_lan('Attachments', 'Allegati');
  -- K_LAN_ATTACH_DESC array_lan := array_lan('Description of <b>FILE</b> Attachments:', 'Descrizione <b>FILE</b> Allegati:');


  /* ===========================================================================================================================
                                                      LOG
     ========================================================================================================================= */
  --
  K_NL CONSTANT VARCHAR2(4) := chr(10);
  -- Usate nei Log di inizio e fine Procedure/Function
  K_FEAT CONSTANT VARCHAR2(12) := 'MAIL';  -- FEATURE che identifica in pa_utl.log le chiamate di questo package
  --
  K_LOG_SP_START CONSTANT VARCHAR2(64) :=   'START ';
  K_LOG_SP_END CONSTANT VARCHAR2(64) :=     'END';
  K_LOG_SP_END_OK CONSTANT VARCHAR2(64) :=  'OK';
  -- Costanti di comodo
  LOG_LEV_ERR CONSTANT NUMBER := DWH.pa_utl.LOG_LEV_ERR;
  LOG_LEV_WARN CONSTANT NUMBER := DWH.pa_utl.LOG_LEV_WARN;
  -- LOG_LEV_INFO CONSTANT NUMBER := DWH.pa_utl.LOG_LEV_INFO;
  LOG_LEV_DEBUG CONSTANT NUMBER := DWH.pa_utl.LOG_LEV_DEBUG;
  LOG_LEV_TRACE CONSTANT NUMBER := DWH.pa_utl.LOG_LEV_TRACE;
  -- LOG_LEV_NOLOG CONSTANT NUMBER := DWH.pa_utl.LOG_LEV_NOLOG;

  /* ===========================================================================================================================
                                                      MISC
     ========================================================================================================================= */



  /* ===========================================================================================================================
                                                      type
     ========================================================================================================================= */
   type array_v2 is varray(20) of varchar2(5000);  -- generic array




  --  SP Descriptor
  type rec_sp is record(
    -- Valorizzati all'inizio con cmn_sp_start
    v_sp    varchar2 (128):= NULL  -- SP
    ,n_logId number:= null  -- logId
    ,b_dbmsOut boolean:= false
    ,t_Start timestamp:= CURRENT_TIMESTAMP -- time inizio elaborazione di v_sp
    -- ------
    ,v_stat  varchar2(32677):=''  -- statistiche locali della SP (esempio tempo per i vari STEP)
    ,n_warn number := 0   -- Numero Warning SP
    ,v_warn varchar2(32677):= ''  -- Messaggi di Warning della SP
    -- STEP
    ,v_step varchar2 (128):= ''  -- STEP corrente
    ,b_step_newLineSep boolean := false -- se true  aggiungo NewLine prima di v_step quando lo concateno nella v_stat della sp
    ,t_stepStart timestamp:=  NULL  -- NULL se non c'e` nessuno STEP corrente (non e` partito o l'ultimo e` stato chiuso)
    ,v_stepDetail  varchar2(32677):= NULL  -- Detail con informazione dello step corrente (Es: Qry eseguita,..). se c'e` viene usato in cmn_exception
  );



  /* ===========================================================================================================================
                                                      PROCEDURE LOCALI
     ========================================================================================================================= */


  /**
  Da chiamare al termine OK di uno STEP di cui si desiderano le statistiche di STEP (Vedi STANDARD STATISTICHE ad inizio File)
  All'inizio dello step e` stata chiamato cmn_step_start.
  Questa procedura puo` anche non essere chiamata esplicitamente perche` viene automaticamente richiamata (se non ancora fatto)
    - da un nuovo  cmn_step_start
    - da cmn_sp_end

  Fine dello step corrente:
    -- logga
    -- aggiorna spStat aggiungendo il tempo impiegato per lo Step
  _param p_rec_sp in out rec_sp    descrittore delle statistiche della SP
  _param [p_detail]  in   varchar2 := ''   e.g 'Inseriti 1000 Rec'
  */
  PROCEDURE cmn_step_end(p_rec_sp in out rec_sp, p_detail IN varchar2 := '')
  IS
    v_msg varchar2 (10000);
    b_dbmsOut       boolean := p_rec_sp.b_dbmsOut;
    n_logId         number  := p_rec_sp.n_logId;
    v_stepTimeElapsed varchar2(64) := DWH.pa_utl.time_elapsed (p_rec_sp.t_stepStart);
    v_stepSep varchar2(10) := '  ';
  BEGIN
    if (p_rec_sp.t_stepStart IS NOT NULL) THEN
      v_msg :=  dwh.pa_utl.v2_append(K_LOG_SP_END || v_stepTimeElapsed,p_detail, ' ');
      -- E` finito lo Step precedente: loggo quanto tempo ci ha messo
      DWH.pa_utl.log(LOG_LEV_DEBUG, K_FEAT, p_rec_sp.v_sp, p_rec_sp.v_step || ' '  || v_msg, n_logId, b_dbmsOut);
      -- aggiorna spStat, aggiungendo il tempo impiegato per lo Step
      -- ES p_rec_sp.v_stat:  '{REFRESH MW DWH.MW_TB_LPE_RICEVUTE_KPI96} in 00:01:12  {TABLE STATS DWH.MW_TB_LPE_RICEVUTE_KPI96} in 00:01:43'
      v_msg := dwh.pa_utl.v2_append (p_rec_sp.v_step || v_stepTimeElapsed,p_detail, '  ',10000);
      if p_rec_sp.b_step_newLineSep THEN
        v_stepSep := K_NL;
      END IF;
      p_rec_sp.v_stat := dwh.pa_utl.v2_append (p_rec_sp.v_stat,v_msg,v_stepSep);
      -- resetto lo stato: al momento non ce` nessuno step in corso
      p_rec_sp.v_step := NULL;
      p_rec_sp.t_stepStart := NULL;
    END IF;

  END cmn_step_end;



  /**
  Da chiamare all'inizio di uno STEP di cui si desiderano le statistiche standard di STEP
  Al termine dello step verra` chiamata cmn_step_end, che puo` anche non essere chiamata esplicitamente perche` viene automaticamente richiamata (se non ancora fatto)
    - da un nuovo  cmn_step_start
    - da cmn_sp_end

  Start di uno Step intermedi di SP:
    - se c'e` uno step in corso lo logga come finito
    - salva in p_kpib le relative variabili, usate pe ridentificare lo step corrente (e quando e` partito)
    - logga lo step solo se p_detail e` presente
  _param p_rec_sp in out rec_sp    descrittore delle statistiche della SP
  _param p_step  in   varchar2   step
  _param [p_detail] IN varchar2 := ''    Dettaglio dello Step (es query eseguita,..). Se c'e` vine eusato in caso di execption per dare Info aggiuntiva
  _param [b_spepNewLineSep] IN boolean :=false  true se voglio separare con NewLine la descrizione di questo Step in v_stat
  */
  PROCEDURE cmn_step_start(p_rec_sp IN OUT rec_sp,  p_step IN varchar2, p_detail IN varchar2 := '', b_spepNewLineSep IN boolean :=false)
  IS
    b_dbmsOut       boolean := p_rec_sp.b_dbmsOut;
    n_logId         number  := p_rec_sp.n_logId;
  BEGIN
    -- se c'e` uno step in corso lo logga come finito
    if (p_rec_sp.t_stepStart IS NOT NULL) THEN
      cmn_step_end (p_rec_sp);
    END IF;

    p_rec_sp.t_stepStart := CURRENT_TIMESTAMP;
    p_rec_sp.v_step := '{' || p_step || '}';
    p_rec_sp.v_stepDetail := p_detail;
    -- logga lo step solo se p_detail e` presente
    if (length (p_detail) > 0) THEN
      DWH.pa_utl.log(LOG_LEV_DEBUG, K_FEAT, p_rec_sp.v_sp, p_rec_sp.v_step || ' ' || p_detail, n_logId, b_dbmsOut);
    end IF;
    p_rec_sp.b_step_newLineSep:= b_spepNewLineSep;

  END cmn_step_start;



  /**
  Procedura chiamata all'inizio di una SP (es mail_monitor_au) di cui si desiderano le utility standard per log e statistiche di SP
  Al termine chiamare cmn_sp_end

  _param p_rec_sp in out rec_sp    descrittore delle statistiche della SP
  _param p_sp  in   varchar2   sp chiamante  e.g  'mail_monitor_au'
  _param p_logId in number :=null  per pa_utl.log
  _param p_dbmsOut in boolean :=false  passare true per avere direttamente a video quanto tracciato in UTL_LOG
  _param [p_detail] IN varchar2 := ''   Eventuale msg aggiuntivo per Log
  */
  PROCEDURE cmn_sp_start(p_rec_sp in out rec_sp, p_sp IN varchar2,p_logId in number:=null, p_dbmsOut IN boolean:=false , p_detail IN varchar2 := '')
  IS
    -- b_dbmsOut       boolean := p_rec_sp.b_dbmsOut;
    -- n_logId         number  := p_rec_sp.n_logId;
  BEGIN
    DWH.pa_utl.log(LOG_LEV_DEBUG,K_FEAT, p_sp,'<' || p_sp || '> ' || K_LOG_SP_START || p_detail, p_logId, p_dbmsOut);
    p_rec_sp.v_sp := p_sp;
    p_rec_sp.n_logId := p_logId;
    p_rec_sp.b_dbmsOut := p_dbmsOut;
    -- Non servirebbe (data la definiz di rec_sp), ma per ora lo faccio comunque
    p_rec_sp.t_Start := CURRENT_TIMESTAMP;
    p_rec_sp.v_step := '';
    p_rec_sp.t_stepStart := NULL;
  END cmn_sp_start;


  /** **********************************************************************************
  Procedura chiamata al termine OK di una SP di cui si desiderano le utility standard (log,..)
  All'inizio e` stata chiamata cmn_sp_start

  _param p_rec_sp in out rec_sp    descrittore delle statistiche della SP
  _param [p_detail] in varchar2:= ''   msg opzionale aggiuntivo subito dopo il messaggio principale.
                                       ES ' [INS 123 Rec]' e ottengo:      <detail_gen KPI30> OK in 1.23 [INS 123 Rec]
  ********************************************************************************** */
  procedure cmn_sp_end ( p_rec_sp in out rec_sp, p_detail IN varchar2 := '') is
    b_dbmsOut       boolean := p_rec_sp.b_dbmsOut;
    n_logId         number  := p_rec_sp.n_logId;
    K_SP constant varchar2(128) := p_rec_sp.v_sp;
    v_stat  varchar2(32767):= '<' || K_SP || '> ';   -- stat di SP
    v_timeElapsed varchar2(32) := DWH.pa_utl.time_elapsed (p_rec_sp.t_start);  -- 'es:   ' IN 00:01:12'
    n_logLev number := LOG_LEV_DEBUG;
  begin
    if (p_rec_sp.t_stepStart IS NOT NULL) THEN
      -- E` finito lo Step precedente: loggo quanto tempo ci ha messo
      cmn_step_end (p_rec_sp);
    END IF;
    if (p_rec_sp.n_warn = 0) then
      -- Procedura finita senza WARNING: OK
      v_stat:= v_stat || K_LOG_SP_END_OK || v_timeElapsed;
    else
      -- Procedura finita CON WARNING. Es:   <csc_load 1> [5 WARNING] in 1:12.128'
      v_stat:= v_stat || ' [' || p_rec_sp.n_warn || ' WARNING]' || v_timeElapsed;
      n_logLev := LOG_LEV_WARN;
    end if;
    v_stat := dwh.pa_utl.v2_append (v_stat, p_detail, ' ');  -- se presente appendo p_detail
    -- se ci sono statistiche di SP le concateno alle Statistiche complessive
    if (length(p_rec_sp.v_stat) > 0) then
      -- Es:  <csv_load TBLPEAttRicevute96>  OK in 13.871 (<REFRESH MW DWH.MW_TB_LPE_RICEVUTE_KPI96> in 10.726  <TABLE STATS DWH.MW_TB_LPE_RICEVUTE_KPI96> in 3.137)
      v_stat:= v_stat || ' (' || p_rec_sp.v_stat || ')';
    end if;
    -- Loggo le statistiche della SP, con anche eventuale msg di WARNING
    DWH.pa_utl.log(n_logLev, K_FEAT, K_SP, dwh.pa_utl.v2_append (v_stat,p_rec_sp.v_warn) , n_logId, b_dbmsOut);
  end cmn_sp_end;




  /** **********************************************************************************
  Add an html tr
  _parm p_rec_sp rec_sp
  _param p_mail_msg in out varchar2
  _param p_td_hea in varchar2
  _param p_td_hea_w_perc in number   width percentage of First td (E.G 25 )
  _param  p_txt_class in varchar2    class E.G 'mailErr'
  ********************************************************************************** */
  procedure html_tr_add (p_rec_sp rec_sp, p_mail_msg in out varchar2, p_td_hea in varchar2, p_td_hea_w_perc in number, p_td_txt in varchar2, p_txt_class in varchar2) is
    -- v_td_txt varchar (32767) := replace (replace (p_td_txt, K_NL, '<BR/>'),K_CRLF,'<BR/>');
  begin
    DWH.pa_utl.log(LOG_LEV_DEBUG, K_FEAT, p_rec_sp.v_sp,'html_tr_add: td_hea=' || p_td_hea  , p_rec_sp.n_logId, p_rec_sp.b_dbmsOut);
    p_mail_msg := p_mail_msg || '
           <tr>
             <td class="mailHea" width="' || p_td_hea_w_perc  || '%">'|| p_td_hea ||  '</td>
               <td>
                 <label class="'||p_txt_class||'" >'|| p_td_txt || '</label>
               </td>
            </tr>';
 end html_tr_add;


  /** **********************************************************************************
  _parm p_File          in      varchar2
  _param [p_logId] in number :=null  for pa_utl.log
  _param [p_dbmsOut] in boolean :=false   true to us ealso fbms_output.put_line (for debug)

  _return mime_type
  ********************************************************************************** */
  Function get_mime_type
   (
      p_File          in      varchar2
      ,p_logId in number
      ,p_dbmsOut in boolean:=false
   ) return varchar2
   is
     K_SP varchar2(64) := 'get_mime_type';
      type mime_type_arr        is table of varchar2(250) index by varchar2(20);
      ar_mime                mime_type_arr;
      v_mime_type                 varchar2(250);
      v_mime_cur  varchar2(250);
      v_ext  varchar2(32);

   begin
      --
      -- Populate the ar_mime array
      --
      ar_mime('323')         := 'text/h323';
      ar_mime('acx')         := 'application/internet-property-stream';
      ar_mime('ai')          := 'application/postscript';
      ar_mime('aif')         := 'audio/x-aiff';
      ar_mime('aifc')        := 'audio/x-aiff';
      ar_mime('aiff')        := 'audio/x-aiff';
      ar_mime('asf')         := 'video/x-ms-asf';
      ar_mime('asr')         := 'video/x-ms-asf';
      ar_mime('asx')         := 'video/x-ms-asf';
      ar_mime('au')          := 'audio/basic';
      ar_mime('avi')         := 'video/x-msvideo';
      ar_mime('axs')         := 'application/olescript';
      ar_mime('bas')         := 'text/plain';
      ar_mime('bcpio')       := 'application/x-bcpio';
      ar_mime('bin')         := 'application/octet-stream';
      ar_mime('bmp')         := 'image/bmp';
      ar_mime('c')           := 'text/plain';
      ar_mime('cat')         := 'application/vnd.ms-pkiseccat';
      ar_mime('cdf')         := 'application/x-cdf';
      ar_mime('cer')         := 'application/x-x509-ca-cert';
      ar_mime('class')       := 'application/octet-stream';
      ar_mime('clp')         := 'application/x-msclip';
      ar_mime('cmx')         := 'image/x-cmx';
      ar_mime('cod')         := 'image/cis-cod';
      ar_mime('cpio')        := 'application/x-cpio';
      ar_mime('crd')         := 'application/x-mscardfile';
      ar_mime('crl')         := 'application/pkix-crl';
      ar_mime('crt')         := 'application/x-x509-ca-cert';
      ar_mime('csh')         := 'application/x-csh';
      ar_mime('css')         := 'text/css';
      ar_mime('dcr')         := 'application/x-director';
      ar_mime('der')         := 'application/x-x509-ca-cert';
      ar_mime('dir')         := 'application/x-director';
      ar_mime('dll')         := 'application/x-msdownload';
      ar_mime('dms')         := 'application/octet-stream';
      ar_mime('doc')         := 'application/msword';
      ar_mime('dot')         := 'application/msword';
      ar_mime('dvi')         := 'application/x-dvi';
      ar_mime('dxr')         := 'application/x-director';
      ar_mime('eps')         := 'application/postscript';
      ar_mime('etx')         := 'text/x-setext';
      ar_mime('evy')         := 'application/envoy';
      ar_mime('exe')         := 'application/octet-stream';
      ar_mime('fif')         := 'application/fractals';
      ar_mime('flr')         := 'x-world/x-vrml';
      ar_mime('gif')         := 'image/gif';
      ar_mime('gtar')        := 'application/x-gtar';
      ar_mime('gz')          := 'application/x-gzip';
      ar_mime('h')           := 'text/plain';
      ar_mime('hdf')         := 'application/x-hdf';
      ar_mime('hlp')         := 'application/winhlp';
      ar_mime('hqx')         := 'application/mac-binhex40';
      ar_mime('hta')         := 'application/hta';
      ar_mime('htc')         := 'text/x-component';
      ar_mime('htm')         := 'text/html';
      ar_mime('html')        := 'text/html';
      ar_mime('htt')         := 'text/webviewhtml';
      ar_mime('ico')         := 'image/x-icon';
      ar_mime('ief')         := 'image/ief';
      ar_mime('iii')         := 'application/x-iphone';
      ar_mime('ins')         := 'application/x-internet-signup';
      ar_mime('isp')         := 'application/x-internet-signup';
      ar_mime('jfif')        := 'image/pipeg';
      ar_mime('jpe')         := 'image/jpeg';
      ar_mime('jpeg')        := 'image/jpeg';
      ar_mime('jpg')         := 'image/jpeg';
      ar_mime('js')          := 'application/x-javascript';
      ar_mime('latex')       := 'application/x-latex';
      ar_mime('lha')         := 'application/octet-stream';
      ar_mime('lsf')         := 'video/x-la-asf';
      ar_mime('lsx')         := 'video/x-la-asf';
      ar_mime('lzh')         := 'application/octet-stream';
      ar_mime('m13')         := 'application/x-msmediaview';
      ar_mime('m14')         := 'application/x-msmediaview';
      ar_mime('m3u')         := 'audio/x-mpegurl';
      ar_mime('man')         := 'application/x-troff-man';
      ar_mime('mdb')         := 'application/x-msaccess';
      ar_mime('me')          := 'application/x-troff-me';
      ar_mime('mht')         := 'message/rfc822';
      ar_mime('mhtml')       := 'message/rfc822';
      ar_mime('mid')         := 'audio/mid';
      ar_mime('mny')         := 'application/x-msmoney';
      ar_mime('mov')         := 'video/quicktime';
      ar_mime('movie')       := 'video/x-sgi-movie';
      ar_mime('mp2')         := 'video/mpeg';
      ar_mime('mp3')         := 'audio/mpeg';
      ar_mime('mpa')         := 'video/mpeg';
      ar_mime('mpe')         := 'video/mpeg';
      ar_mime('mpeg')        := 'video/mpeg';
      ar_mime('mpg')         := 'video/mpeg';
      ar_mime('mpp')         := 'application/vnd.ms-project';
      ar_mime('mpv2')        := 'video/mpeg';
      ar_mime('ms')          := 'application/x-troff-ms';
      ar_mime('mvb')         := 'application/x-msmediaview';
      ar_mime('nws')         := 'message/rfc822';
      ar_mime('oda')         := 'application/oda';
      ar_mime('p10')         := 'application/pkcs10';
      ar_mime('p12')         := 'application/x-pkcs12';
      ar_mime('p7b')         := 'application/x-pkcs7-certificates';
      ar_mime('p7c')         := 'application/x-pkcs7-mime';
      ar_mime('p7m')         := 'application/x-pkcs7-mime';
      ar_mime('p7r')         := 'application/x-pkcs7-certreqresp';
      ar_mime('p7s')         := 'application/x-pkcs7-signature';
      ar_mime('pbm')         := 'image/x-portable-bitmap';
      ar_mime('pdf')         := 'application/pdf';
      ar_mime('pfx')         := 'application/x-pkcs12';
      ar_mime('pgm')         := 'image/x-portable-graymap';
      ar_mime('pko')         := 'application/ynd.ms-pkipko';
      ar_mime('pma')         := 'application/x-perfmon';
      ar_mime('pmc')         := 'application/x-perfmon';
      ar_mime('pml')         := 'application/x-perfmon';
      ar_mime('pmr')         := 'application/x-perfmon';
      ar_mime('pmw')         := 'application/x-perfmon';
      ar_mime('pnm')         := 'image/x-portable-anymap';
      ar_mime('pot,')        := 'application/vnd.ms-powerpoint';
      ar_mime('ppm')         := 'image/x-portable-pixmap';
      ar_mime('pps')         := 'application/vnd.ms-powerpoint';
      ar_mime('ppt')         := 'application/vnd.ms-powerpoint';
      ar_mime('prf')         := 'application/pics-rules';
      ar_mime('ps')          := 'application/postscript';
      ar_mime('pub')         := 'application/x-mspublisher';
      ar_mime('qt')          := 'video/quicktime';
      ar_mime('ra')          := 'audio/x-pn-realaudio';
      ar_mime('ram')         := 'audio/x-pn-realaudio';
      ar_mime('ras')         := 'image/x-cmu-raster';
      ar_mime('rgb')         := 'image/x-rgb';
      ar_mime('rmi')         := 'audio/mid';
      ar_mime('roff')        := 'application/x-troff';
      ar_mime('rtf')         := 'application/rtf';
      ar_mime('rtx')         := 'text/richtext';
      ar_mime('scd')         := 'application/x-msschedule';
      ar_mime('sct')         := 'text/scriptlet';
      ar_mime('setpay')      := 'application/set-payment-initiation';
      ar_mime('setreg')      := 'application/set-registration-initiation';
      ar_mime('sh')          := 'application/x-sh';
      ar_mime('shar')        := 'application/x-shar';
      ar_mime('sit')         := 'application/x-stuffit';
      ar_mime('snd')         := 'audio/basic';
      ar_mime('spc')         := 'application/x-pkcs7-certificates';
      ar_mime('spl')         := 'application/futuresplash';
      ar_mime('src')         := 'application/x-wais-source';
      ar_mime('sst')         := 'application/vnd.ms-pkicertstore';
      ar_mime('stl')         := 'application/vnd.ms-pkistl';
      ar_mime('stm')         := 'text/html';
      ar_mime('svg')         := 'image/svg+xml';
      ar_mime('sv4cpio')     := 'application/x-sv4cpio';
      ar_mime('sv4crc')      := 'application/x-sv4crc';
      ar_mime('swf')         := 'application/x-shockwave-flash';
      ar_mime('t')           := 'application/x-troff';
      ar_mime('tar')         := 'application/x-tar';
      ar_mime('tcl')         := 'application/x-tcl';
      ar_mime('tex')         := 'application/x-tex';
      ar_mime('texi')        := 'application/x-texinfo';
      ar_mime('texinfo')     := 'application/x-texinfo';
      ar_mime('tgz')         := 'application/x-compressed';
      ar_mime('tif')         := 'image/tiff';
      ar_mime('tiff')        := 'image/tiff';
      ar_mime('tr')          := 'application/x-troff';
      ar_mime('trm')         := 'application/x-msterminal';
      ar_mime('tsv')         := 'text/tab-separated-values';
      ar_mime('txt')         := 'text/plain';
      ar_mime('uls')         := 'text/iuls';
      ar_mime('ustar')       := 'application/x-ustar';
      ar_mime('vcf')         := 'text/x-vcard';
      ar_mime('vrml')        := 'x-world/x-vrml';
      ar_mime('wav')         := 'audio/x-wav';
      ar_mime('wcm')         := 'application/vnd.ms-works';
      ar_mime('wdb')         := 'application/vnd.ms-works';
      ar_mime('wks')         := 'application/vnd.ms-works';
      ar_mime('wmf')         := 'application/x-msmetafile';
      ar_mime('wps')         := 'application/vnd.ms-works';
      ar_mime('wri')         := 'application/x-mswrite';
      ar_mime('wrl')         := 'x-world/x-vrml';
      ar_mime('wrz')         := 'x-world/x-vrml';
      ar_mime('xaf')         := 'x-world/x-vrml';
      ar_mime('xbm')         := 'image/x-xbitmap';
      ar_mime('xla')         := 'application/vnd.ms-excel';
      ar_mime('xlc')         := 'application/vnd.ms-excel';
      ar_mime('xlm')         := 'application/vnd.ms-excel';
      ar_mime('xls')         := 'application/vnd.ms-excel';
      ar_mime('xlt')         := 'application/vnd.ms-excel';
      ar_mime('xlw')         := 'application/vnd.ms-excel';
      ar_mime('xof')         := 'x-world/x-vrml';
      ar_mime('xpm')         := 'image/x-xpixmap';
      ar_mime('xwd')         := 'image/x-xwindowdump';
      ar_mime('z')           := 'application/x-compress';
      ar_mime('zip')         := 'application/zip';
      --
      -- Determine the file extension
      --
      v_mime_type := 'text/plain';  -- default

      v_ext := ar_mime.FIRST;  -- Get first element of array
      WHILE v_ext IS NOT NULL LOOP
         v_mime_cur :=ar_mime (v_ext);
         if (instr (p_file,'.' || v_ext) > 1) then
           v_mime_type := v_mime_cur;
           v_ext := null ; -- to exitr from while
         else
           v_ext := ar_mime.NEXT(v_ext);  -- Get next element of array
         end if ;
      END LOOP;
      DWH.pa_utl.log(LOG_LEV_DEBUG, K_FEAT, K_SP, 'IN File=' || p_File || ' - RETURN mime_type=' || v_mime_type, p_logId, p_dbmsOut);
      return v_mime_type;

   end get_mime_type;









 /** ====================================================================================================================
  _param p_conn  in out utl_smtp.connection
  _param [p_last] in boolean :=true true for the last attachment
  _param [p_logId]  in number:=null
  _param [p_dbmsOut]  in boolean:=false
   ==================================================================================================================== */
  PROCEDURE write_boundary(p_conn in out nocopy utl_smtp.connection
                            ,p_last in            boolean default false
                            ,p_logId in number := null
                            ,p_dbmsOut in boolean:=false
                            )
  AS
     v_msg varchar2(128);
     K_SP varchar2(64):='write_boundary';
  BEGIN
      if (p_last) then
        v_msg := '--'||K_boundary||'--'||K_CRLF;
      else
        v_msg := '--'||K_boundary||K_CRLF;
      end if;
      utl_smtp.write_data(p_conn, v_msg);
      DWH.pa_utl.log(LOG_LEV_DEBUG, K_FEAT, K_SP, 'p_last=' || dwh.pa_utl.bool_to_varchar2(p_last) || '  write_data: ' || v_msg, p_logId, p_dbmsOut);

  END write_boundary;



 /** ====================================================================================================================
  end attachment
  _param p_conn  in out utl_smtp.connection
  _param [p_last] in boolean :=true true for the last attachment
  _param [p_logId]  in number:=null
  _param [p_dbmsOut]  in boolean:=false
   ==================================================================================================================== */
  PROCEDURE end_attachment(p_conn in out nocopy utl_smtp.connection
                            ,p_last in     boolean default true
                            ,p_logId in number := null
                            ,p_dbmsOut in boolean:=false
                            )
  AS
  BEGIN
      utl_smtp.write_data(p_conn, utl_tcp.crlf);
      if (p_last) then
        write_boundary(p_conn, p_last, p_logId,p_dbmsOut);
      end if;
  END end_attachment;



  PROCEDURE write_raw_data(p_conn         in out nocopy utl_smtp.connection
                       ,p_msg in varchar2
                       ,p_sp in varchar2
                       ,p_logId in number:=null
                       ,p_dbmsOut IN boolean:=false
                              ) is
  begin
     DWH.pa_utl.log(LOG_LEV_TRACE,K_FEAT, p_sp,p_msg , p_logId, p_dbmsOut);
     utl_smtp.write_raw_data(p_conn ,utl_raw.cast_to_raw(p_msg));

  end write_raw_data;



  /** ====================================================================================================================
  begin attachment
  _param p_conn  in out utl_smtp.connection
  _param p_file in varchar2
  _param p_mime_type in varchar2     e.g.  'text/html; '
  _param p_logId  in number:=null
  _param p_dbmsOut  in boolean:=false
   ==================================================================================================================== */
  PROCEDURE begin_attachment(p_conn         in out nocopy utl_smtp.connection
                              ,p_file in varchar2
                              ,p_mime_type in varchar2 := null
                              ,p_inline       in            boolean  default false
                              ,p_transfer_enc in            varchar2 default null
                              ,p_logId in number:=null
                              ,p_dbmsOut IN boolean:=false
                              ) is
    k_sp varchar2(64) := 'begin_attachment';
    r_sp rec_sp;
    v_mime_type varchar2(32) := p_mime_type;
  BEGIN
      cmn_sp_start (r_sp, k_sp, p_logId, p_dbmsOut,'file=' || p_file || ' inline=' || dwh.pa_utl.bool_to_varchar2(p_inline));
      if (v_mime_type is null) then
        v_mime_type := get_mime_type (p_file, p_logId, p_dbmsOut);
      end if;

      write_boundary(p_conn, false, p_logId, p_dbmsOut);
      if (p_transfer_enc is not null) then
        write_raw_data (p_conn,'Content-Transfer-Encoding: '||p_transfer_enc||utl_tcp.crlf, K_SP, p_logId, p_dbmsOut);
      end if;
      write_raw_data (p_conn,'Content-Type: '||v_mime_type|| ';name="'|| p_file ||'"' ||  utl_tcp.crlf, K_SP, p_logId, p_dbmsOut);
      if (p_file is not null) then
        if (p_inline) then
          write_raw_data (p_conn,'Content-Disposition: inline; filename="'||p_file||'"'||utl_tcp.crlf, K_SP, p_logId, p_dbmsOut);
        else
          write_raw_data (p_conn,'Content-Disposition: attachment; filename="'||p_file||'"'||utl_tcp.crlf, K_SP, p_logId, p_dbmsOut);
        end if;
      end if;
      utl_smtp.write_data(p_conn, utl_tcp.crlf);
      cmn_sp_end (r_sp);
    END begin_attachment;



  /** ====================================================================================================================
  add into p_conn a binary attachment reading it form dir=p_dir file=p_file
  _param p_conn  in out utl_smtp.connection
  _param p_file in varchar2   nmae of the file to indicate in attachment
  _param p_content in varchar2
  _param [p_last] in boolean :=true true for the last attachment
  _param [p_logId]  in number:=null
  _param [p_dbmsOut]  in boolean:=false
   ==================================================================================================================== */
  PROCEDURE add_attach_v2(p_conn      in out utl_smtp.connection
                               ,p_file in     varchar2
                               ,p_content in     varchar2
                               ,p_last in boolean := false
                               ,p_logId  in number:=null
                               ,p_dbmsOut  in boolean:=false
                               )
  is
    K_SP varchar2(64) := 'add_attach_v2';
    r_sp rec_sp;
    v_mime_type varchar2(32);

      k_max_line_width constant pls_integer default 54;
      n_amt            binary_integer := 672 * 3; /* ensures proper format; 2016 */
      n_len       pls_integer := length(p_content);
      v_buf            raw(2100);
      n_modulo         pls_integer := MOD(n_len, n_amt);
      n_pieces         pls_integer := TRUNC(n_len / n_amt);
      n_pos       pls_integer := 1;
      v_data           raw(2100);
      v_chunks         pls_integer;

  BEGIN
    cmn_sp_start (r_sp, k_sp, p_logId, p_dbmsOut, 'IN file=' || p_file );
    v_mime_type := get_mime_type (p_file, p_logId, p_dbmsOut);
    begin_attachment(p_conn         => p_conn
                      ,p_file => p_file
                      ,p_mime_type    => v_mime_type
                      ,p_inline       => FALSE  -- PROVA
                      ,p_transfer_enc => 'base64'
                      ,p_logId => p_logId
                      ,p_dbmsOut => p_dbmsOut
                      );
    BEGIN
        if (n_modulo <> 0) then
          n_pieces := n_pieces + 1;
        end if;
        -- DWH.pa_utl.log(LOG_LEV_TRACE,K_FEAT, K_SP,'n_modulo=' || n_modulo || ' n_pieces=' || n_pieces , p_logId, p_dbmsOut);
        v_data := null;
        cmn_step_start (r_sp, 'loop n_pieces=' || n_pieces,'',true);
        v_buf := utl_raw.cast_to_raw(substr (p_content,1,n_amt));
        for i in 1 .. n_pieces loop
          n_pos := i * n_amt + 1;
          n_len := n_len - n_amt;
          -- DWH.pa_utl.log(LOG_LEV_TRACE,K_FEAT, K_SP,'n_pos' || n_pos || ' n_len=' || n_len , p_logId, p_dbmsOut);
          v_data := utl_raw.concat(v_data, v_buf);
          v_chunks := TRUNC(utl_raw.length(v_data) / k_max_line_width);
          if (i <> n_pieces) then
            v_chunks := v_chunks - 1;
          end if;

          utl_smtp.write_raw_data(p_conn
                                 ,utl_encode.base64_encode(v_data)
                                 );

          v_data := null;
          if (n_len < n_amt AND n_len > 0) then
            n_amt := n_len;
          end if;
          v_buf := utl_raw.cast_to_raw(substr (p_content,n_pos,n_amt));

        end loop;
      END;
      end_attachment(p_conn, p_last, p_logId, p_dbmsOut);
      cmn_sp_end (r_sp);
    EXCEPTION
      when no_data_found then
         end_attachment(p_conn, p_last, p_logId, p_dbmsOut);
    END add_attach_v2;





  /** ====================================================================================================================
  add into p_conn a binary attachment reading it form dir=p_dir file=p_file
  _param p_conn  in out utl_smtp.connection
  _param p_dir in varchar2
  _param p_file in varchar2
  _param [p_last] in boolean :=true true for the last attachment
  _param [p_logId]  in number:=null
  _param [p_dbmsOut]  in boolean:=false
   ==================================================================================================================== */
  PROCEDURE add_attach_file(p_conn      in out utl_smtp.connection
                               ,p_dir  in varchar2
                               ,p_file in     varchar2
                               ,p_last in boolean :=false
                               ,p_logId  in number:=null
                               ,p_dbmsOut  in boolean:=false
                               )
  is
    K_SP varchar2(64) := 'add_attach_file';
    r_sp rec_sp;
    v_mime_type varchar2(32);
      k_max_line_width constant pls_integer default 54;
      n_amt            binary_integer := 672 * 3; /* ensures proper format; 2016 */
      v_bfile          bfile;
      n_len       pls_integer;
      v_buf            raw(2100);
      n_modulo         pls_integer;
      n_pieces         pls_integer;
      n_pos       pls_integer := 1;
      v_data           raw(2100);
      v_chunks         pls_integer;

  BEGIN
    cmn_sp_start (r_sp, k_sp, p_logId, p_dbmsOut, 'IN dir=' || p_dir || ' file=' || p_file );
    v_mime_type := get_mime_type (p_file, p_logId, p_dbmsOut);
    begin_attachment(p_conn         => p_conn
                      ,p_file  => p_file
                      ,p_mime_type    => v_mime_type
                      ,p_inline       => FALSE  -- PROVA
                      ,p_transfer_enc => 'base64'
                      );
    BEGIN
        cmn_sp_start (r_sp, k_sp, p_logId, p_dbmsOut);
        v_bfile    := bfilename(p_dir, p_file);
        n_len := dbms_lob.getlength(v_bfile);
        n_modulo   := MOD(n_len, n_amt);
        n_pieces   := TRUNC(n_len / n_amt);
        if (n_modulo <> 0) then
          n_pieces := n_pieces + 1;
        end if;
        -- DWH.pa_utl.log(LOG_LEV_TRACE,K_FEAT, K_SP,'n_modulo=' || n_modulo || ' n_pieces=' || n_pieces , p_logId, p_dbmsOut);

        dbms_lob.fileopen(v_bfile ,dbms_lob.file_readonly  );
        dbms_lob.read(v_bfile ,n_amt ,n_pos ,v_buf );
        v_data := null;

        cmn_step_start (r_sp, 'loop n_pieces=' || n_pieces,'',true);
        for i in 1 .. n_pieces loop
          n_pos := i * n_amt + 1;
          n_len := n_len - n_amt;
          -- DWH.pa_utl.log(LOG_LEV_TRACE,K_FEAT, K_SP,'n_pos' || n_pos || ' n_len=' || n_len , p_logId, p_dbmsOut);
          v_data := utl_raw.concat(v_data, v_buf);
          v_chunks := TRUNC(utl_raw.length(v_data) / k_max_line_width);
          if (i <> n_pieces) then
            v_chunks := v_chunks - 1;
          end if;

          utl_smtp.write_raw_data(p_conn
                                 ,utl_encode.base64_encode(v_data)
                                 );

          v_data := null;
          if (n_len < n_amt AND n_len > 0) then
            n_amt := n_len;
          end if;

          dbms_lob.READ(v_bfile,n_amt,n_pos,v_buf );
        end loop;
      END;
      dbms_lob.fileclose(v_bfile);
      end_attachment(p_conn, p_last, p_logId, p_dbmsOut);
      cmn_sp_end (r_sp);
    EXCEPTION
      when no_data_found then
        dbms_lob.fileclose(v_bfile);
    END add_attach_file;







  /* ***************************************************************************
                                 PROCEDURE PUBBLICHE STANDARD per CVS
 *************************************************************************** */

  FUNCTION get_cvs_revision RETURN VARCHAR2 IS
  BEGIN
    RETURN tg.tg_pa_amm_bl_elem_comuni.formatta_cvs_keywords('$Revision: 1.10 $');
  END get_cvs_revision;

  -------------------------------------------------------------------------------------------------------------------------------

  FUNCTION get_checkout_tag RETURN VARCHAR2 IS
  BEGIN
    RETURN tg.tg_pa_amm_bl_elem_comuni.formatta_cvs_keywords('$Name:  $');
  END;

  -------------------------------------------------------------------------------------------------------------------------------

  PROCEDURE install IS
  BEGIN
    tg.tg_pa_amm_bl_elem_comuni.install(k_linep_package,
                                        k_nome_package,
                                        get_cvs_revision(),
                                        get_checkout_tag());
  END install;

  -------------------------------------------------------------------------------------------------------------------------------

  FUNCTION get_history RETURN ty_cursorehistory IS
  BEGIN
    RETURN tg.tg_pa_amm_bl_elem_comuni.get_history(k_linep_package, k_nome_package);
  END;



  /* ***************************************************************************
                                 PUBBLIC
 *************************************************************************** */





  /** **********************************************************************************
  Initialize and return  a rec_tr
  Description: see Package Specification
  ********************************************************************************** */
  function rec_tr_init (p_td_hea in varchar2, p_td_txt in varchar2, p_txt_class in varchar2 := K_CLASS_MAIL) return rec_tr
  is
    r_tr rec_tr;
  begin
    r_tr.v_td_hea :=  p_td_hea;
    r_tr.v_td_txt :=  p_td_txt;
    r_tr.v_txt_class :=  p_txt_class;
    return r_tr;
  end rec_tr_init;



  /** **********************************************************************************
  Initialize and return  a rec_content_file
  Description: see Package Specification
  ********************************************************************************** */
  function rec_content_file_init (p_dir IN varchar2, p_file IN varchar2) return rec_content_file
  IS
    r_content_file rec_content_file;
  begin
    r_content_file.v_dir := p_dir;
    r_content_file.v_file := p_file;
    return r_content_file;
  end rec_content_file_init ;

  /** **********************************************************************************
  Initialize and return  a rec_content_v2
  Description: see Package Specification
  ********************************************************************************** */
  function rec_content_v2_init (p_file IN varchar2, p_content in varchar2) return rec_content_v2
  IS
    r_content_v2 rec_content_v2;
  begin
    r_content_v2.v_file := p_file;
    r_content_v2.v_content := p_content;
    return r_content_v2;
  end rec_content_v2_init ;


  /** **********************************************************************************
  Initialize and return  a rec_attach
  Description: see Package Specification
  ********************************************************************************** */
  function rec_attach_init (p_desc IN varchar2,
     p_content_type varchar2 := K_CONTENT_TYPE_FILE,
     p_content_file in rec_content_file := null,
     p_content_v2 in rec_content_v2 := null
     ) return rec_attach
  IS
    r_attach rec_attach;
  begin
    r_attach.v_desc:= p_desc;
    r_attach.v_content_type:= p_content_type;
    r_attach.r_content_file:= p_content_file;
    r_attach.r_content_v2:= p_content_v2;
    return r_attach;
  end rec_attach_init ;


   /** **********************************************************************************
   Send Email
   Description: see Package Specification
  ********************************************************************************** */
  procedure mail_send  (
              p_mail_cfg         in rec_mail_cfg
              ,p_from            in varchar2
              ,p_dest_to         in varchar2
              ,p_dest_cc         in varchar2 default null
              ,p_subject         in varchar2
              ,p_msg             in varchar2
              ,p_ar_attach       in array_attach
              ,p_logId           in number:=null
              ,p_dbmsOut         in boolean:=false
              )
  is
    K_SP varchar2(64) := 'mail_send';
    r_sp rec_sp;
    v_smtp_server varchar(128) := p_mail_cfg.v_smtp_server;
    n_smtp_port number := p_mail_cfg.n_smtp_port;
    ar_dest_type array_v2 := array_v2 ('To','Cc');   -- NB: do not change (used in write_date)
    ar_dest array_v2 := array_v2 (ltrim(rtrim(p_dest_to)),ltrim(rtrim(p_dest_cc)));
    r_attach rec_attach;
    r_content_file rec_content_file;
    r_content_v2 rec_content_v2;
    v_dest varchar2(5000);
    v_msg            varchar2(32767);
    v_mailMsg                 varchar2(32767);
    conn                 utl_smtp.connection;
    invalid_path         exception;
    n_len number := 1;
    v_addr varchar2(100);
    b_last boolean := false;
  BEGIN
    cmn_sp_start (r_sp, K_SP,p_logId,p_dbmsOut, 'PAR from=' || p_from || ' to=' || p_dest_to || ' cc=' || p_dest_cc || ' subject=' || p_subject);
    cmn_step_start ( r_sp, 'open_connection', 'smtp_server=' || v_smtp_server  || ' smtp_port=' || n_smtp_port || ' from='||p_from ,true);

    conn:= utl_smtp.open_connection (v_smtp_server, n_smtp_port);
    utl_smtp.helo( conn, v_smtp_server );
    utl_smtp.mail( conn, p_from );
    --  --------------------------------------  dest 'TO' and 'CC'
    for i in 1..2 loop
      v_dest := ar_dest(i);
      if v_dest is not null and length(v_dest) > 0
      then
        cmn_step_start ( r_sp, 'set dest ' || ar_dest_type(i), 'v_dest=' || v_dest,true);
        if(instr(v_dest,',') = 0) then
          utl_smtp.rcpt(conn, v_dest);
          DWH.pa_utl.log(LOG_LEV_DEBUG, K_FEAT, K_SP, 'SINGLE RCPT DEST='||v_dest, p_logId, p_dbmsOut);
        else
          if substr(v_dest, length(v_dest)-1 ,1) <> ','
          then
             v_dest := v_dest||',';
          end if;
          n_len := 1;
          while(instr(v_dest,',',n_len) > 0)
          loop
            v_addr := substr(v_dest, n_len, instr(substr(v_dest,n_len),',')-1);
            n_len := n_len+instr(substr(v_dest, n_len),',');
            utl_smtp.rcpt(conn, v_addr);
            DWH.pa_utl.log(LOG_LEV_DEBUG, K_FEAT, K_SP, 'MULTIPLE RCPT CC: '||v_addr, p_logId, p_dbmsOut);
          end loop;
        end if;
      end if;
    end loop;
    -- =================
    cmn_step_start ( r_sp, 'utl_smtp.write_data','',true);
    utl_smtp.open_data ( conn );
    for i in 1..2 loop
      v_dest := ar_dest(i);
      if v_dest is not null and length(v_dest) > 0
      then
        -- e.g. 'To: ...'   or 'Cc: ...'
        v_msg := ar_dest_type(i) ||': '||v_dest ||K_CRLF;
        DWH.pa_utl.log(LOG_LEV_DEBUG, K_FEAT, K_SP, 'utl_smtp.write_data '||v_msg, p_logId, p_dbmsOut);
        utl_smtp.write_data(conn, v_msg);
      end if;
    end loop;
    v_msg := 'Subject: '||p_subject||K_CRLF;
    DWH.pa_utl.log(LOG_LEV_DEBUG, K_FEAT, K_SP, 'utl_smtp.write_data '||v_msg, p_logId, p_dbmsOut);
    utl_smtp.write_data(conn, v_msg);
    -- ========================================================================
    cmn_step_start ( r_sp, 'write_row_data mailMsg','',true);
    v_msg := p_msg;
    v_mailMsg :=  'Content-Transfer-Encoding: 7bit'
           || K_CRLF ||'Content-Type: multipart/mixed;boundary="'||K_boundary||'"'
           || K_CRLF ||'Mime-Version: 1.0'
           || K_CRLF ||'--'||K_boundary
           || K_CRLF ||'Content-Transfer-Encoding: binary'
           || K_CRLF ||'Content-Type: text/html'
           || K_CRLF || K_CRLF || v_msg
           || K_CRLF ;

    DWH.pa_utl.log(LOG_LEV_TRACE, K_FEAT, K_SP, 'MAIL MESSAGE:' || K_NL || v_mailMsg, p_logId, p_dbmsOut);
    utl_smtp.write_raw_data ( conn, utl_raw.cast_to_raw(v_mailMsg) );

    for i in 1..p_ar_attach.count loop
      r_attach := p_ar_attach(i);
      if i= p_ar_attach.count then
        b_last := true;
      end if;
      if r_attach.v_content_type is not null and r_attach.v_desc is not null then
        DWH.pa_utl.log(LOG_LEV_DEBUG, K_FEAT, K_SP, 'ADD Attachment [' || i || ']', p_logId, p_dbmsOut);
        case r_attach.v_content_type
          -- =============================================== FILE Attachment (read form v_dir v_file)
          when K_CONTENT_TYPE_FILE then
            r_content_file := r_attach.r_content_file;

            add_attach_file(p_conn      => conn
                         ,p_dir => r_content_file.v_dir
                         ,p_file => r_content_file.v_file
                         ,p_last => b_last
                         ,p_logId => p_logId
                         ,p_dbmsOut => p_dbmsOut
                         );
          -- =============================================== V2 Attachment
          when K_CONTENT_TYPE_V2 then
            r_content_v2 := r_attach.r_content_v2;
            add_attach_v2(p_conn      => conn
                         ,p_file => r_content_v2.v_file
                         ,p_content => r_content_v2.v_content
                         ,p_last => b_last
                         ,p_logId => p_logId
                         ,p_dbmsOut => p_dbmsOut
                         );
          else
            raise_application_error( K_EX_UTL_MAIL, 'SW ERROR IN ' || K_SP || ' - VALUE NOT ALLOWED for p_ar_attach[' || i || ']r_attach.v_content_type=' || r_attach.v_content_type);
        end case;
      end if;
    end loop;
    utl_smtp.close_data( conn );
    utl_smtp.quit( conn );
    cmn_sp_end (r_sp);  -- END SP OK
  EXCEPTION
   WHEN OTHERS THEN
      v_msg := 'EXCEPTION in ' || K_SP   || ' step=' || r_sp.v_step;
      pa_utl.log_exception (LOG_LEV_ERR, K_FEAT, K_SP,v_msg, p_logId, p_dbmsOut);
      -- Custom EXCEPTION
      v_msg  := v_msg || K_NL || DBMS_UTILITY.format_error_backtrace || 'SQLERRM=' || sqlerrm;
      raise_application_error( K_EX_UTL_MAIL, v_msg );

  END mail_send;




 /** **********************************************************************************
 Send Mail with standard Layout
  Description: see Package Specification
********************************************************************************** */
  procedure mail_standard(p_mail in  rec_mail_standard, p_logId in number, p_dbmsOut in boolean:=false )  is
    K_SP varchar2(100) := 'mail_standard';
    r_sp rec_sp;
    n_status number := p_mail.n_status;
    r_mail_cfg rec_mail_cfg ;
    r_tr rec_tr;
    v_from varchar2(100):='Unknown';
    v_subject  varchar2(2000) :=  p_mail.v_subject;
    err_no_dest exception;
    v_msg varchar2(32767);
    v_stmt varchar2(5000);
    ar_dest_type array_v2 := array_v2 ('TO','CC');
    ar_dest array_v2 := array_v2 ('','');
    --
    v_css varchar2(32767) := '';  -- mail.css with style
    -- Map of status_code to get the class
    n_iStatus number := n_status + 1; -- {KO 1, OK 2, WARN 3}
    n_iLan number := p_mail.n_lan;
    ar_class array_v2 := array_v2('mailErr','mailOk', 'mailWarn');
    ar_resultTxt array_v2 := array_v2(K_LAN_ERROR(n_iLan),K_LAN_OK(n_iLan), K_LAN_WARNING(n_iLan)) ;
    v_class varchar2(128) := ' class="' || ar_class(n_iStatus) || '" ' ;  -- e.g.: class="mailErr"
    --
    v_mailMsg        varchar2(32767);
    v_txt varchar2(32767) := '';  -- generic txt
    v_file varchar2(128);
    ar_attach array_attach := p_mail.ar_attach;
    r_attach rec_attach;
    n_sum_flag_attach number:=0;

  begin
    cmn_sp_start (r_sp, k_sp, p_logId, p_dbmsOut);
    begin
      select global_name  into v_from  from global_name;
      DWH.pa_utl.log(LOG_LEV_TRACE,K_FEAT, K_SP,'from=' || v_from , p_logId, p_dbmsOut);
      exception when no_data_found then null;
    end;
    --  -------------------------------------- Get dest 'TO' and 'CC' From DB
    for i in 1..2 loop
      begin
        /* E.G:
           select LISTAGG(m.dest_email, ',')  WITHIN GROUP (ORDER BY m.dest_email)
              from DWH.UTL_MAIL_DEST_CFG m
              where m.sp= 'kpib_processGlobal' and m.dest_type='TO'
              and 1=1;
        */
        v_stmt :=   'select LISTAGG(m.dest_email, '','')  WITHIN GROUP (ORDER BY m.dest_email)
           from DWH.UTL_MAIL_DEST_CFG m
           where m.sp= ''' || p_mail.v_app_sp  || '''  and m.dest_type=''' || ar_dest_type(i) || '''
           and (case  '  || n_status || '
             when 0  -- only to dest with FLAG_SEND_OK=1
               then m.FLAG_SEND_OK
             else 1
            end
            ) = 1 ';
        cmn_step_start ( r_sp, 'Get dest ' || ar_dest_type(i) || ' FROM DWH.UTL_MAIL_DEST_CFG',v_stmt,true);
        EXECUTE IMMEDIATE v_stmt INTO ar_dest(i);
        /* E.G:
          federico.levis@enel.com,manuel.galiotto@enel.com
        */
        cmn_step_end (r_sp,'dest ' || ar_dest_type(i) || '=' || ar_dest(i));
        exception  when no_data_found then  null;
      end;
    end loop;
    if trim(ar_dest(1)) is null and trim(ar_dest(2)) is null then
      -- NOTHING TO SEND
        DWH.pa_utl.log(LOG_LEV_DEBUG, K_FEAT, K_SP, 'NO MAIL TO SEND', p_logId, p_dbmsOut);
    else
      -- =============================================================================== send the mail to the dest
      cmn_step_start (r_sp, 'read css','dir_css=' || r_mail_cfg.v_dir_css || ' f_css=' || r_mail_cfg.v_f_css,true);
      -- read css with the <style>...the </style>
      v_css := dwh.pa_utl.file_read (r_mail_cfg.v_dir_css, r_mail_cfg.v_f_css, LOG_LEV_TRACE, K_FEAT, p_logId, p_dbmsOut);

      --  ---------------------------- TABLE
      v_mailMsg :='
<html><head><meta http-equiv=Content-Type content=text/html; charset=windows-1252></head>
  <style>' || K_NL ||  v_css ||'
  </style>
  <body>
    <div class="mailContainer">
      <div class="mailTblContainer" style="width:' || p_mail.n_tblWidthPerc || '%">
        <table'||v_class||'BORDER="2" cellspacing="0" cellpadding="2" width="100%">
           <tr><td '||v_class||'  style="text-align:center" colspan="2">' || v_subject || '</td></tr>';

      -- ---------------------------- tr
      -- First <tr> with result is automatically added.
      html_tr_add (r_sp, v_mailMsg, K_LAN_RESULT(n_iLan), p_mail.n_td1WidthPerc, '<b>' || ar_resultTxt(n_iStatus) || '</b>', ar_class(n_iStatus));
      -- Other <tr>
      for i in 1..p_mail.ar_tblTr.count loop
        r_tr := p_mail.ar_tblTr(i);
        html_tr_add (r_sp, v_mailMsg, r_tr.v_td_hea, p_mail.n_td1WidthPerc, r_tr.v_td_txt, r_tr.v_txt_class);
      end loop;

      -- ========================================================== add attach (at least one FLAG_ATTACH=1 is enough)
      /* e.g
       select sum(FLAG_ATTACH) from DWH.UTL_MAIL_DEST_CFG  where SP='kpib_processGlobal';
      */
      v_stmt :=   'select sum(FLAG_ATTACH) from DWH.UTL_MAIL_DEST_CFG where SP=''' || p_mail.v_app_sp  || ''' ';
      cmn_step_start ( r_sp, 'Get FLAG_ATTACH',v_stmt,true);
      BEGIN
        EXECUTE IMMEDIATE v_stmt INTO n_sum_flag_attach;
        /* E.G:   0, 1,2.. */
        cmn_step_end (r_sp,'sum_flag_attach ' || n_sum_flag_attach);
        exception  when no_data_found then  null;
      END;
      if (n_sum_flag_attach = 0) then
        ar_attach:= array_attach();
      end if;
      -- Attachment if present
      if ar_attach.count > 0 then
        cmn_step_start (r_sp, 'set attach','ar_attach.count=' || ar_attach.count,true);
        -- prepare v_txt with list of attachment
        /*
        v_txt := K_LAN_ATTACH_DESC(n_iLan) || '
           <ul>
           ';
        */
        v_txt := '
        <ul style="margin-top:0px; margin-bottom:0px;">
        ';
        for i in 1..  ar_attach.count loop
          r_attach := ar_attach(i);
          if r_attach.v_content_type is not null and r_attach.v_desc is not null then
            if r_attach.v_content_type = K_CONTENT_TYPE_FILE then
              v_file := r_attach.r_content_file.v_file;
            else
              v_file := r_attach.r_content_v2.v_file;
            end if;
            DWH.pa_utl.log(LOG_LEV_trace, K_FEAT, K_SP, 'r_attach[' || i || ']: content_type=' || r_attach.v_content_type ||
              ' v_file=' || v_file || ' v_desc=' || r_attach.v_desc , p_logId, p_dbmsOut);
            dwh.pa_utl.v2_append(v_txt,'
               <li><b>' || v_file || ':</b> ' || r_attach.v_desc || '</li>') ;
          end if;
        end loop;
        dwh.pa_utl.v2_append(v_txt,'</ul>') ;
        html_tr_add (r_sp, v_mailMsg,  K_LAN_ATTACH(n_iLan) || ' (' ||  ar_attach.count || ')', p_mail.n_td1WidthPerc , v_txt, K_CLASS_MAIL_LEFT);
      end if;
      v_mailMsg := v_mailMsg || '
        </table>
      </div>  <!-- end mailTblContainer -->
      ';
     --  ----------------------------   INFO, if present
      if (p_mail.v_info is not null) then
        v_mailMsg := v_mailMsg || K_NL ||  p_mail.v_info;
      end if;
      v_mailMsg := v_mailMsg || '
    </div> <!-- end "mailContainer">  -->
  </body>
</html>';

      mail_send (p_mail_cfg => r_mail_cfg
                  ,p_from => v_from
                  ,p_dest_to => ar_dest(1)
                  ,p_dest_cc => ar_dest(2)
                  ,p_subject => v_subject
                  ,p_msg => v_mailMsg
                  ,p_ar_attach => ar_attach
                  ,p_logId => p_logId
                  ,p_dbmsOut => p_dbmsOut
                  );

    end if;
    cmn_sp_end (r_sp);

  EXCEPTION
   WHEN OTHERS THEN
      v_msg := 'EXCEPTION in ' || K_SP   || ' step=' || r_sp.v_step;
      pa_utl.log_exception (LOG_LEV_ERR, K_FEAT, K_SP,v_msg, p_logId, p_dbmsOut);
      -- Custom EXCEPTION
      v_msg  := v_msg || K_NL || DBMS_UTILITY.format_error_backtrace || 'SQLERRM=' || sqlerrm;
      raise_application_error( K_EX_UTL_MAIL, v_msg );


  end mail_standard;







END PA_UTL_MAIL;
/
