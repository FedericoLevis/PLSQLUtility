-- SHOW UTL_LOG records of only Last LOG_ID of only THIS FEATURE (without other that has run  in parallel
select * from SGM.utl_log log WHERE
-- only TEST_FEAT
  FEATURE = 'LOG_TEST_PARALLEL' 
-- Last LOG_ID
  AND LOG_ID = (select max (LOG_ID) from SGM.utl_log)  
  -- Try different LOG_LEV FILTER
  AND LOG_LEV <= 4
  -- AND LOG_LEV <= 3
  -- AND LOG_LEV <= 2
  order by log_time;
