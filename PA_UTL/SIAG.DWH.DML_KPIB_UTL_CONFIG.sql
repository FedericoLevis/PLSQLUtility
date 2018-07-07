/*  ============================================================================
     TABLE DWH.UTL_CFG initialization/configuration per KPI BEAT
 ============================================================================ */

-- Configurazione Livello LOG desiderato per KPIB: abilitato fino al livello 4 (LOG_TRACE), ossia al massimo
DELETE FROM DWH.UTL_LOG_CFG WHERE FEATURE = 'KPIB';
INSERT INTO DWH.UTL_LOG_CFG VALUES ('KPIB',4);

-- Configurazione Livello LOG desiderato per MAIL: abilitato fino al livello 4 (LOG_TRACE), ossia al massimo
DELETE FROM DWH.UTL_LOG_CFG WHERE FEATURE = 'MAIL';
INSERT INTO DWH.UTL_LOG_CFG VALUES ('MAIL',4);


COMMIT;


