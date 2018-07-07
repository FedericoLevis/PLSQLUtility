PL/SQL Developer Test script 3.0
18
declare
  t_time1 TIMESTAMP := CURRENT_TIMESTAMP;
  t_time2 TIMESTAMP := CURRENT_TIMESTAMP - 0.000123;
  v_result varchar2(120);
begin
  -- Call the function
  /*
  v_result := sgm.pa_utl.time_get_vdiff(time1 => t_time1,
                                       time2 => t_time2);
  DBMS_OUTPUT.PUT_LINE (v_result);
  */
  v_result := sgm.pa_utl.time_get_vdiff(time1 => t_time1,
                                       time2 => t_time2);
  DBMS_OUTPUT.PUT_LINE (v_result);
  
end;


3
result
0
-5
time1
1
﻿CURRENT_TIMESTAMP
-12
time2
1
﻿CURRENT_TIMESTAMP
-12
0
