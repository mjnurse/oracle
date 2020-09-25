/**
*** NAME
***    ses - Returns a list of active sessions.
***
*** USAGE
***    @ses [options] [<SID|username|os-name>]
***
*** OPTIONS
***    -h|--help
***       Show help text.
*** 
*** DESCRIPTION
***    This script returns a list of active sessions which can be filters by SID, username or os-name.
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

COL sid FOR a4 TRUNCATE HEADING "SID" 
COL username FOR a20 TRUNCATE HEADING "Oracle User" 
COL os_mach_prog FOR a60 TRUNCATE HEADING "OS User - Machine Name - Program" 
COL logon_time FOR a11 TRUNCATE HEADING "Logon Time" 
COL program FOR a30 TRUNCATE HEADING "Program" 
COL state FOR a20 TRUNCATE HEADING "State" 
COL client_info FOR a10 TRUNCATE HEADING "Client Info" 
COL last_call_et FOR 0 TRUNCATE HEADING "Last Call Et" 

SELECT   SUBSTR(sid,1,4) AS sid--, serial#
       , username
       , NVL(OSUSER,'None')||' - '|| machine || ' - ' || program AS os_mach_prog
       , TO_CHAR(logon_time,'MM/DD HH24:MI') As logon_time
       , DECODE( state, 'WAITING', event, state ) AS state
       , client_info
       , last_call_et
FROM     v$session
WHERE    username IS NOT NULL
AND      (   '&1' IS NULL
          OR TO_CHAR(sid) LIKE '&1'
          OR username LIKE UPPER('&1')
          OR UPPER(osuser) LIKE UPPER('&1') )
AND      '&v_run_cmd_yn' = 'Y'
ORDER BY TO_NUMBER(sid), username, osuser
/

-- Clean up and attempt to put everything back as it was.
PROMPT
SET TERM OFF
UNDEF 1 2 v_usage_help_cmd v_usage_help_on_off v_results_on_off
@sqlplus_settings.sql
GET buf.tmp
SET TERM ON
