/*
** NAME
**    rb - A script to show rollback in use.
**
** USAGE
**    @rb [<sid>]
**
** OPTIONS
**    -h|--help
**       Show help text.
** 
** DESCRIPTION
**    A script to show rollback in use.  Optional filter on SID.
**
** AUTHOR
**    mjnurse.dev - 2011
*/

-- help_line: Show rollback in use: @rb [<sid>]
-- desc_line: Show rollback in use

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

--DEFINE o_demo_yn=N
--COLUMN o_demo_yn NEW_VALUE o_demo_yn
--SELECT   '&2' AS "1", 'Y' AS o_demo_yn
--FROM     dual
--WHERE    '&1' = '-a';

SET TERM &v_results_on_off HEAD ON

-- Main script
SELECT  s.sid
      , s.username
      , s.osuser
      , TO_CHAR(t.used_urec,'FM9999,999,999') AS used_undo_rec
      , TO_CHAR(t.used_ublk,'FM9999,999,999') AS used_undo_blk
      --, x.hsecs
FROM    v$transaction t
      , v$session     s
      , v$timer       x
WHERE  t.addr     = s.taddr
AND    ( TO_CHAR(s.sid) = '&1' OR '&1' IS NULL )
AND    '&v_run_cmd_yn' = 'Y';

-- Clean up and attempt to put everything back as it was.
PROMPT
SET TERM OFF
UNDEF 1 2 v_usage_help_cmd v_usage_help_on_off v_results_on_off
@sqlplus_settings.sql
GET buf.tmp
SET TERM ON

