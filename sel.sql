/**
*** NAME
***    sel - Select Statement Generation Script.
***
*** USAGE
***    @sel [options] <table_name>
***
*** OPTIONS
***    -h|--help
***       Show help text.
*** 
*** DESCRIPTION
***    A script to generate a SELECT statement for all columns in the specified table.  If a table owner
***    is not specified, the script checks for the table in the users current schema first, followed by
***    SYS. If the table does not exist in either schema, the table owned by the user with the
***    alphabetically greatest name is used.
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

!&v_usage_help_cmd &script_name | grep -e '^\*\*\*.*$' | sed 's/\*\*\* \{0,1\}//;'

-- Main script
-- If no parameter 1 has been passed then display a usage message.
SET TERM ON HEAD OFF
SELECT      'Usage: @sel <table_name>'
FROM        dual
WHERE       '&1' IS NULL
UNION ALL
SELECT      'Try @sel -h for more information'
FROM        dual
WHERE       '&1' IS NULL
/
SET TERM OFF

-- Determine the schema / owner to use in the table column selection
COLUMN owner NEW_VALUE owner
COLUMN table_name NEW_VALUE table_name
SELECT   table_name
      ,  SUBSTR(MAX(LPAD(DECODE(
            owner
         ,  user, 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ'
         ,  'SYS', 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZY'
         ,  owner), 30)||owner), 31) owner
FROM     dba_tab_columns
WHERE    table_name = UPPER(SUBSTR('&1', INSTR('&1', '.') + 1))
AND      owner = NVL(UPPER(SUBSTR('&1', 1, INSTR('&1', '.') - 1)), owner)
GROUP BY table_name
UNION
SELECT   table_name
      ,  SUBSTR(MAX(LPAD(DECODE(
            table_owner
         ,  user, 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ'
         ,  'SYS', 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZY'
         ,  table_owner), 30)||table_owner), 31) owner
FROM     user_synonyms
WHERE    synonym_name = UPPER(SUBSTR('&1', INSTR('&1', '.') + 1))
GROUP BY table_name
/

-- If the table does not exist then inform the user.
SET TERM ON
SELECT   'no such table: &1'
FROM     dual
WHERE    '&table_name' IS NULL
AND      '&v_run_cmd_yn' = 'Y'
AND      '&1' != 'NULL'
/
SET TERM OFF

-- Generate the SELECT statement if possible.
UNDEFINE stmt
COLUMN stmt NEW_VALUE stmt
SPOOL buf.tmp
SELECT   DECODE(
            rownum
         ,  1, 'SELECT '
         ,  '     , ')
            ||LOWER(column_name)  AS stmt
FROM     dba_tab_columns
WHERE    table_name = '&table_name'
AND      owner = '&owner'
UNION ALL
SELECT   'FROM   '||LOWER('&owner..&table_name')
FROM     dba_tab_columns
WHERE    table_name = '&table_name'
AND      owner = '&owner'
AND      rownum < 2
/

SPOOL OFF

-- Determine if a SELECT statement has been generated.  If so load this 
-- into the buffer and display it, else reload the previous buffer but
-- do not display it.
COLUMN buf_to_get NEW_VALUE buf_to_get
COLUMN term_on_off NEW_VALUE term_on_off
SELECT   DECODE(
            '&stmt'
         ,  NULL, 'buf.sql'
         ,  'buf.tmp') AS buf_to_get
      ,  DECODE(
            '&stmt'
         ,  NULL, 'OFF'
         ,  'ON') AS term_on_off
FROM     dual
/

UNDEF owner table_name

-- Clean up and attempt to put everything back as it was.
PROMPT
@sqlplus_settings.sql
SET TERM &term_on_off
UNDEF 1 2 v_usage_help_cmd v_usage_help_on_off v_results_on_off
get &buf_to_get
SET TERM ON

