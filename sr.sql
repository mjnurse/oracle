/**
*** NAME
***    sr - Shows currently running SQL.
***
*** USAGE
***    @sr [options]
***
*** OPTIONS
***    -h|--help
***       Show help text.
*** 
*** DESCRIPTION
***    This script show the currently running SQL.
***
*** AUTHOR
***    mjnurse.uk - 2010
**/

SET TERM OFF DEF ON
STORE SET sqlplus_settings.sql REPLACE
SAVE buf.tmp REPLACE

-- Get the current script name including path.
SET APPINFO ON
COLUMN script_name NEW_VALUE script_name
SELECT SUBSTR(script_name, INSTR(script_name,' ')+1) AS script_name
FROM   (SELECT SYS_CONTEXT('USERENV', 'MODULE') AS script_name FROM dual);

-- Create empty parameter values for missing parameters.
COLUMN 1 NEW_VALUE 1
COLUMN 2 NEW_VALUE 2
SELECT 1, 2 FROM dual WHERE 0 = 1;

-- Set local variables which determine is the script should run or a usage message shown.
DEFINE v_usage_help_cmd=#
DEFINE v_usage_help_on_off=OFF
DEFINE v_results_on_off=ON
DEFINE v_run_cmd_yn=Y

COLUMN v_usage_help_cmd NEW_VALUE v_usage_help_cmd
COLUMN v_usage_help_on_off NEW_VALUE v_usage_help_on_off
COLUMN v_results_on_off NEW_VALUE v_results_on_off
COLUMN v_run_cmd_yn NEW_VALUE v_run_cmd_yn

-- Determine whether to run the script or display the usage / help message.

SELECT   'cat' AS v_usage_help_cmd
      ,  'ON' as v_usage_help_on_off
      ,  'N' AS v_run_cmd_yn
      ,  'OFF' AS v_results_on_off
FROM     dual
WHERE    '&1' IN ('-h', '--help');

SET HEAD OFF FEED OFF VER OFF
SET TERM &v_usage_help_on_off

PROMPT 
!&v_usage_help_cmd &script_name | grep -e '^\*\*\*.*$' | sed 's/\*\*\* \{0,1\}//;'

SET TERM &v_results_on_off HEAD ON

-- Main script
SELECT   /* =ignore= */
         NVL(TO_CHAR(ses.sid),'none')||'/'||UPPER(NVL(ses.schemaname,'none'))
      || DECODE(ses.sid,NULL,'',LOWER(' ('||osuser||'/'||machine||'/'||program||')'))
      || ' '||sql.sql_id
       , RPAD('Done : '||NVL(rows_processed,0),20)
      || RPAD('Undo : '||NVL(trn.used_urec,0),20)
      || RPAD('Runs:  '||executions, 20)
      || TRIM(LOWER(SUBSTR(REGEXP_REPLACE(sql_text,'  *',' '),1,75)))
       , RPAD('LogIO: '||NVL(TO_CHAR(log_io),'-'), 20)
      || RPAD('PhyIO: '||NVL(TO_CHAR(phy_io),'-'), 20)
      || RPAD('Sorts: '||NVL(sorts,0),20)
      || TRIM(LOWER(SUBSTR(REGEXP_REPLACE(sql_text,'  *',' '),76,75)))
       , DECODE(lo.start_time, NULL, '', RPAD('Start: '||TO_CHAR(lo.start_time,'HH24:MI:SS'),20)
      || RPAD('Remain: '||SUBSTR(TO_CHAR(FLOOR(lo.time_remaining/3600),'FM09')
                        ||':'||TO_CHAR(FLOOR((lo.time_remaining-FLOOR(lo.time_remaining/3600)*3600)/60),'FM09')
                        ||':'||TO_CHAR(MOD(lo.time_remaining,60),'FM09'),1,8),20)
      ||RPAD('Elasped: '||SUBSTR(TO_CHAR(FLOOR(lo.elapsed_seconds/3600),'FM09')
                        ||':'||TO_CHAR(FLOOR((lo.elapsed_seconds-FLOOR(lo.elapsed_seconds/3600)*3600)/60),'FM09')
                        ||':'||TO_CHAR(MOD(lo.elapsed_seconds,60),'FM09'),1,8),20))
FROM     v$sql sql
       , v$session ses
       , v$transaction trn
       , v$session_longops lo
WHERE    '&v_run_cmd_yn' = 'Y'
AND      users_executing > 0
AND      ses.sid = DECODE( 0&1,0,ses.sid, 0&1)
AND      ses.sql_id (+)= sql.sql_id
AND      trn.addr   (+)= ses.taddr
AND      lo.sid     (+)= ses.sid
AND      lo.time_remaining (+) > 0
AND      INSTR(sql_text,'=ignore=') = 0
ORDER BY NVL(ses.sid,-1)
/

-- Clean up and attempt to put everything back as it was.
PROMPT
SET TERM OFF
UNDEF 1 2 v_usage_help_cmd v_usage_help_on_off v_results_on_off
@sqlplus_settings.sql
GET buf.tmp
SET TERM ON

