/*
** NAME
**    o - List objects.
**
** USAGE
**    @o [options] [<filter>]
**
** OPTIONS
**    -h|--help
**       Show help text.
**
**    -a|--all
**       Show objects from all users/schemas
** 
** DESCRIPTION
**    This script list objects.
**
** AUTHOR
**    mjnurse.dev - 2019
*/

-- help_line: Lists schema objects: @o [options] [<filter>]
-- desc_line: Lists schema objects 

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

DEFINE o_all_yn=N
COLUMN o_all_yn NEW_VALUE o_all_yn
SELECT   '&2' AS "1", 'Y' AS o_all_yn
FROM     dual
WHERE    '&1' = '-a';

SET TERM OFF
SELECT NVL('&1','%') AS "1" FROM dual;

SET TERM &v_results_on_off HEAD ON

-- Main script
COL owner FOR a30
COL object_type FOR a15
COL object_name FOR a30
COL other FOR a50
SELECT   owner
      ,  object_type
      ,  object_name
      ,  other
FROM
(  SELECT   o.owner
         ,  o.object_type
         ,  o.object_name
         ,  DECODE(o.object_type
                  ,'INDEX', 'Tb: '||i.table_name
                  ,'') AS other
   FROM     all_objects o
   LEFT OUTER JOIN all_indexes i
   ON       (   i.owner = o.owner
            AND i.index_name = o.object_name)
   WHERE    '&v_run_cmd_yn' = 'Y'
   AND      (   o.owner = USER
            OR '&o_all_yn' = 'Y')
   AND      o.object_name LIKE '&1'
   UNION ALL
   SELECT   owner
         ,  DECODE(constraint_type,'P','PRIMARY','R','REFERENTIAL','U','UNIQUE','OTHER')
         ,  constraint_name
         ,  DECODE(constraint_type
                  ,'P','Tb: '||table_name||', Id: '||index_name
                  ,'U','Tb: '||table_name||', Id: '||index_name
                  ,'R','Tb: '||table_name||' -> '||r_constraint_name
                  ,'')
   FROM     all_constraints
   WHERE    '&v_run_cmd_yn' = 'Y'
   AND      constraint_type != 'C'
   AND      (   owner = USER
            OR '&o_all_yn' = 'Y')
   AND      (  constraint_name LIKE '&1'
            OR table_name LIKE '&1')
)
ORDER BY owner
      ,  object_type
      ,  object_name;

-- Clean up and attempt to put everything back as it was.
PROMPT
SET TERM OFF
UNDEF 1 2 v_usage_help_cmd v_usage_help_on_off v_results_on_off
@sqlplus_settings.sql
GET buf.tmp
SET TERM ON
