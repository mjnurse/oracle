/*
** NAME
**    drop - A script to generate a list of drop object statements.
**
** USAGE
**    @drop [options] [<filter_1>]
**
** OPTIONS
**    -h|--help
**       Show help text.
** 
** DESCRIPTION
**    This script generates a list of DROP object statements for the current user.  A filter can be
**    passed.
**
** AUTHOR
**    mjnurse.dev - 2019
*/

-- help_line: Generate a list of object drop statements: @drop [options] [<filter_1>]
-- desc_line: Generate a list of object drop statements

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
SELECT   'DROP '||object_type||' '||object_name||';' AS stmt
FROM     user_objects
WHERE    '&v_run_cmd_yn' = 'Y'
AND      (object_name LIKE UPPER('&1') OR object_type LIKE UPPER('&1') OR '&1' IS NULL);

-- Clean up and attempt to put everything back as it was.
PROMPT
SET TERM OFF
UNDEF 1 2 v_usage_help_cmd v_usage_help_on_off v_results_on_off
@sqlplus_settings.sql
GET buf.tmp
SET TERM ON



