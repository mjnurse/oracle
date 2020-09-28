/**
*** NAME
***    dict - Query the data dictionary.
***
*** USAGE
***    @dict [options] [<search-string>]
***
*** OPTIONS
***    -h|--help
***       Show help text.
*** 
*** DESCRIPTION
***    Query the data dictionary.
***
*** AUTHOR
***    mjnurse.uk - 2019
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

SELECT   NVL('&1', '') AS "1"
      ,  NVL('&2', '') AS "2"
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
WHERE    '&1' IN ('-h', '--help')
/

SET HEAD OFF FEED OFF VER OFF
SET TERM &v_usage_help_on_off

PROMPT 
!&v_usage_help_cmd &script_name | grep -e '^\*\*\*.*$' | sed 's/\*\*\* \{0,1\}//;'

SET TERM &v_results_on_off HEAD ON

-- Main script
COL table_name FOR a30
COL comments_truncated_120_char FOR a120
SELECT   SUBSTR(table_name, 1, 30) AS table_name
      ,  SUBSTR(comments, 1, 120) AS comments_truncated_120_char
FROM     dict
WHERE    '&v_run_cmd_yn' = 'Y'
AND      table_name LIKE UPPER('&1')
ORDER BY 1;

-- Clean up and attempt to put everything back as it was.
PROMPT
SET TERM OFF
UNDEF 1 2 v_usage_help_cmd v_usage_help_on_off v_results_on_off
@sqlplus_settings.sql
GET buf.tmp
SET TERM ON
