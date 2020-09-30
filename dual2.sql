/*
** NAME
**    dual2 - Creates an extended version of dual.
**
** USAGE
**    @dual2
**
** OPTIONS
**    -h|--help
**       Show help text.
** 
** DESCRIPTION
**    Returning:
**    -  Number (Num - Range 1..4000), 
**    -  Character (chr - A..Z repeats),
**    -  Word (word - consecutive words from the lorem ipsum phrase - repeats),
**    -  String (string - increasing length string - using characters from the lorem ipsum -
**       no spaces),
**    -  Sentence (sentence - using full words from lorem ipsum.  Sentence shorter than length -
**       Num).
**
** AUTHOR
**    mjnurse.dev - 2019
*/

-- help_line: Create an extended version of dual: @dual
-- desc_line: Create an extended version of dual

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

CREATE OR REPLACE VIEW dual2 AS
WITH step1 AS
  ( SELECT -- 69 words
            'Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor '
          ||'incididunt ut labore et dolore magna aliqua Ut enim ad minim veniam quis nostrud '
          ||'exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat Duis aute irure '
          ||'dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla '
          ||'pariatur Excepteur sint occaecat cupidatat non proident sunt in culpa qui officia '
          ||'deserunt mollit anim id est laborum ' AS str
           , ROWNUM AS num
           , MOD(ROWNUM-1, 69)+1 AS offset
    FROM     dual CONNECT BY LEVEL <= 4000 ) -->
  , step2 AS
  ( SELECT   num
           , RPAD(str, 3999, ' '||str)||' ' AS str
           , RPAD(REPLACE(str, ' ', ''), 4000, REPLACE(str, ' ', '')) AS str_no_space
           , INSTR(' '||str, ' ', 1, offset) AS sta
           , INSTR(' '||str, ' ', 1, offset+1) AS fin
           , CHR(65+MOD(num-1, 26)) AS chr
    FROM     step1 )
SELECT   CAST(num AS NUMBER) AS num
       , CAST(chr AS VARCHAR2(1)) AS chr
       , CAST(SUBSTR(str, sta, fin-sta-1) AS VARCHAR2(20)) AS word
       , CAST(SUBSTR(str_no_space, 1, num) AS VARCHAR2(4000)) AS string
       , CAST(SUBSTR(str, 1, INSTR(SUBSTR(str, 1, num), ' ', -1)-1)||'.' AS VARCHAR2(4000)) AS sentence
FROM     step2;

PROMPT
PROMPT ---------------------------------------------

PROMPT View: dual2 - created
PROMPT
PROMPT EXAMPLE: SELECT * FROM dual2 WHERE num = 300;
PROMPT ---------------------------------------------

COL STRING FOR a50
COL SENTENCE FOR a50 
SELECT * FROM dual2 WHERE num = 300;

-- Clean up and attempt to put everything back as it was.
PROMPT
SET TERM OFF
UNDEF 1 2 v_usage_help_cmd v_usage_help_on_off v_results_on_off
@sqlplus_settings.sql
GET buf.tmp
SET TERM ON
