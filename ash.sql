/*
** NAME
**    ash - Shows the status of active sessions in the last n minutes (default 10).
**
** USAGE
**    @ash [<number minutes history (default:10)>]
**
** OPTIONS
**    -h|--help
**       Show help text.
** 
** DESCRIPTION
**    This scripts shows the status of active sessions in the last n minutes.
**
** AUTHOR
**    mjnurse.dev - 2011
*/

-- help_line: Show status of active sessions: @ash [<number minutes history (default:10)>]
-- desc_line: Show status of active sessions in last n mins

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

SELECT NVL('&1',10) AS "1"
FROM   dual;

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
COL state FOR a30
COL sql FOR a80
BREAK ON hh_mi SKIP 1
COL hh_mi FOR a5
COL "#SES" FOR 999
COL num FOR 9999

WITH details AS
   (  SELECT      TO_CHAR(sample_time, 'HH24:MI') AS hh_mi
               ,  sql_id
               ,  SUBSTR(SUBSTR(username, 1, 15)||': '||REGEXP_REPLACE(s.sql_text, '  *', ' '), 1, 80) AS sql
               ,  COUNT(UNIQUE session_id) AS ses
               ,  COUNT(*) num
               ,  DECODE(session_state, 'WAITING', event, session_state) AS state
      FROM        v$active_session_history ash
      JOIN        v$sql s USING (sql_id)
      LEFT JOIN   dba_users u USING (user_id)
      WHERE       '&v_run_cmd_yn' = 'Y'
      AND         sample_time > SYSDATE - &1/24/60
      AND         s.sql_text NOT LIKE '%all the audit options that%'
      GROUP BY    TO_CHAR(sample_time, 'HH24:MI')
               ,  SUBSTR(SUBSTR(username, 1, 15)||': '||REGEXP_REPLACE(s.sql_text, '  *', ' '), 1, 80)
               ,  sql_id
               ,  DECODE(session_state, 'WAITING', event, session_state)
   )
SELECT      hh_mi
         ,  sql_id
         ,  sql
         ,  ses AS "#SES"
         ,  num
         ,  DECODE(
               state
            ,  'SQL*Net more data from dblink', 'SQL*Net dblink'
            ,  'db file sequential read', 'seq read'
            ,  'direct path read temp', 'dpath read tmp'
            ,  'direct path write temp', 'dpath write tmp'
            ,  state) AS state
FROM        details
ORDER BY    1, 2, 3;

-- Clean up and attempt to put everything back as it was.
PROMPT
SET TERM OFF
UNDEF 1 2 v_usage_help_cmd v_usage_help_on_off v_results_on_off
@sqlplus_settings.sql
GET buf.tmp
SET TERM ON
