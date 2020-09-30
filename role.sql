/*
** NAME
**    role - Query role and role privileges. 
**
** USAGE
**    @role [options] [<role name - wildcards allowed>]
**
** OPTIONS
**    -h|--help
**       Show help text.
**    -p
**       Show privilege details.
** 
** DESCRIPTION
**    Query role and role privileges. 
**
** AUTHOR
**    mjnurse.dev - 2019
*/

-- help_line: Query Role and Role Privileges: @role [options] [<role name - wildcards allowed>]
-- desc_line: Query Role and Role Privileges

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
WHERE    '&1' IN ('-h', '--help')
/

SET HEAD OFF FEED OFF VER OFF
SET TERM &v_usage_help_on_off

PROMPT 
!&v_usage_help_cmd &script_name | grep -e '^\*\*\*.*$' | sed 's/\*\*\* \{0,1\}//;'

DEFINE o_privs_yn=N
COLUMN o_privs_yn NEW_VALUE o_privs_yn
SELECT   '&2' AS "1", 'Y' AS o_privs_yn
FROM     dual
WHERE    '&1' = '-p';

SELECT NVL('&1','%') AS "1" FROM dual;

SET TERM &v_results_on_off HEAD ON

COL role FOR a30
-- Main script
SELECT   DISTINCT
         role
FROM     role_sys_privs 
WHERE    '&v_run_cmd_yn' = 'Y'
AND      '&o_privs_yn' = 'N'
AND      role LIKE UPPER('&1')
ORDER BY 1;

SELECT   role
      ,  privilege
FROM     role_sys_privs 
WHERE    '&v_run_cmd_yn' = 'Y'
AND      '&o_privs_yn' = 'Y'
AND      role LIKE UPPER('&1')
ORDER BY 1, 2;

-- Clean up and attempt to put everything back as it was.
PROMPT
SET TERM OFF
UNDEF 1 2 v_usage_help_cmd v_usage_help_on_off v_results_on_off
@sqlplus_settings.sql
GET buf.tmp
SET TERM ON
