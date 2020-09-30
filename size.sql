/*
** NAME
**    size - Display the size of objects visible for the current user in the data dictionary.
**
** USAGE
**    @size [options] <object_ name> (wildcards allowed in all parameters)
**
** OPTIONS
**    -t <type>
**       Object type.
**
**    -o <owner>
**       Object owner.
**
**    -n <num>
**       Show the top <num> results
**
** DESCRIPTION
**    This script list objects.
**
** AUTHOR
**    mjnurse.dev - 2010
*/

-- help_line: Display the size of objects: @size [options] <object_ name>
-- desc_line: Display the size of objects.

DEFINE script_name="size.sql"

SET TERM OFF DEF ON
STORE SET sqlplus_settings.sql REPLACE
SAVE buf.tmp REPLACE

-- Set default values for missing parameters.
COLUMN 1 NEW_VALUE 1
COLUMN 2 NEW_VALUE 2
COLUMN 3 NEW_VALUE 3
COLUMN 4 NEW_VALUE 4
COLUMN 5 NEW_VALUE 5
COLUMN 6 NEW_VALUE 6
COLUMN 7 NEW_VALUE 7
SELECT 1, 2, 3, 4, 5, 6, 7 FROM dual WHERE 0 = 1;
SELECT NVL('&1', '##nothing') AS "1"
     , NVL('&2', '##nothing') AS "2"
     , NVL('&3', '##nothing') AS "3"
     , NVL('&4', '##nothing') AS "4"
     , NVL('&5', '##nothing') AS "5"
     , NVL('&6', '##nothing') AS "6"
     , NVL('&7', '##nothing') AS "7"
FROM   dual;

COLUMN v_type NEW_VALUE v_type
COLUMN v_owner NEW_VALUE v_owner
COLUMN v_top_n NEW_VALUE v_top_n
COLUMN v_object NEW_VALUE v_object

SELECT NVL( DECODE('&1', '-t', '&2')||DECODE('&3', '-t', '&4')||DECODE('&5', '-t', '&6')
          , '##nothing' ) AS v_type
     , NVL( DECODE('&1', '-o', '&2')||DECODE('&3', '-o', '&4')||DECODE('&5', '-o', '&6')
          , '##nothing' ) AS v_owner
     , NVL( DECODE('&1', '-n', '&2')||DECODE('&3', '-n', '&4')||DECODE('&5', '-n', '&6')
          , '##nothing' ) AS v_top_n
     , CASE WHEN '&2' = '##nothing' THEN '&1'
            WHEN '&4' = '##nothing' THEN '&3'
            WHEN '&6' = '##nothing' THEN '&5'
            ELSE '&7'
       END AS v_object
FROM   dual;

-- Set local variables which determine is the script should run or a usage message shown.
DEFINE v_usage_help_cmd='rem'
DEFINE v_usage_help_on_off=OFF
DEFINE v_results_on_off=OFF

COLUMN v_usage_help_cmd NEW_VALUE v_usage_help_cmd
COLUMN v_usage_help_on_off NEW_VALUE v_usage_help_on_off
COLUMN v_results_on_off NEW_VALUE v_results_on_off

-- Determine whether to run the script or display the usage / help message.  Note: When testing for missing
-- parameters we need only check the last mandatory parameter because for it to be missing then the previous
-- parameters must also be missing.

SELECT   'type &script_name | findstr "^...Usage: "' AS v_usage_help_cmd 
      ,  'ON' as v_usage_help_on_off
FROM     dual 
WHERE    '&v_object' = '##nothing'
--OR       '&2' IN ('?', '##missing', '-h', '-help' )
/
SELECT   'type &script_name | findstr "^\*\* "' AS v_usage_help_cmd 
      ,  'ON' as v_usage_help_on_off
FROM     dual 
WHERE    '&v_object' IN ('?', '-h', '-help' )
--OR       '&2' IN ('?', '-h', '-help' )
/

SELECT   'ON' AS v_results_on_off 
FROM     dual
WHERE    '&v_usage_help_cmd' NOT LIKE '%type%';

SET HEAD OFF FEED OFF VER OFF 
SET TERM &v_usage_help_on_off

PROMPT
HOST &v_usage_help_cmd

SET TERM &v_results_on_off HEAD ON FEED ON

SET LINES 132
SET PAGES 9999
COLUMN owner FOR a20
COLUMN object_name FOR a30
COLUMN tablespace_name FOR a20
COLUMN type FOR a12
COLUMN parent_object FOR a20
COLUMN mbytes FORMAT "9,999,990.00" JUSTIFY RIGHT
COLUMN extents FOR "999,990"
COMPUTE SUM OF mbytes ON REPORT
COMPUTE SUM OF extents ON REPORT
BREAK ON REPORT

WITH src AS
( SELECT    s.owner
          , s.segment_name AS object_name
          , s.tablespace_name
          , s.segment_type AS type
          , SUBSTR(NVL(i.table_name, '-'), 1, 20) AS parent_object
          , SUM(s.bytes) / 1024 / 1024 mbytes
          , SUM(s.extents) AS extents
  FROM      dba_segments s
  LEFT JOIN all_indexes i
  ON        ( i.index_name = s.segment_name )
  WHERE     ( '&v_owner' = '##nothing' OR s.owner LIKE UPPER('&v_owner') )
  AND       ( '&v_type' = '##nothing' OR s.segment_type LIKE UPPER('&v_type') )
  AND       s.segment_name LIKE UPPER('&v_object')
  GROUP BY  s.owner
          , s.segment_name
          , s.tablespace_name
          , s.segment_type
          , NVL(i.table_name, '-')
  ORDER BY  mbytes DESC
          , segment_name
  )
SELECT *
FROM   src
WHERE  '&v_top_n' = '##nothing'
OR     rownum <= '&v_top_n';

CLEAR COMPUTE
CLEAR BREAK

SET TERM OFF
UNDEF 1 2 3 4 5 6 7 v_results_on_off v_type v_owner v_top_n v_usage_help_cmd v_usage_help_on_off v_results_on_off
@sqlplus_settings.sql
GET buf.tmp
SET TERM ON
