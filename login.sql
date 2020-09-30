/*
** NAME
**    login - SQLPLUS Login Script
**
** USAGE
**    Called by default when SQLPlus logs in, or @login.sql
**
** OPTIONS
**    None.
** 
** DESCRIPTION
**    Description: Configures the SQLPLUS session.
**
** AUTHOR
**    mjnurse.dev - 2005
*/

-- help_line: SQLPLUS Login Script
-- desc_line: SQLPLUS Login Script

SET TERM OFF
SAVE buf_login.tmp REPLACE

-- Use a decent editor.
DEFINE _editor='/home/martin/bin/gv'

-- Set a sensible name for the default edit file.
SET EDITFILE "buf.sql"

-- Construct the command prompt: username@DATABASE(SID) - it it fails default to NONE.
DEFINE prompt=NONE
COLUMN new_prompt NEW_VALUE prompt

SELECT LOWER(USER)
    || '@'
    || DECODE( INSTR(global_name,'.')
             , 0, global_name
             , SUBSTR(global_name,1,INSTR(global_name,'.')-1) ) AS new_prompt
FROM   global_name
/

SELECT LOWER(USER)
    || '@'
    || DECODE( INSTR(global_name,'.')
             , 0, global_name
             , SUBSTR(global_name,1,INSTR(global_name,'.')-1) )
    || '('||SYS_CONTEXT( 'USERENV', 'SID' )||') ' AS new_prompt
FROM   global_name
/

-- Set (DOS) command window title.
--$title &prompt ( %CD% )

-- Set the prompt.
SET sqlprompt '&prompt.> '

-- Misc
ALTER SESSION SET nls_date_format='DD/MM/YYYY HH24:MI:SS';
--ALTER SESSION SET plsql_warnings='ENABLE:SEVERE','ENABLE:PERFORMANCE','DISABLE:INFORMATIONAL';

-- Get the old buffer back and cleanup.
GET buf_login.tmp NOLIST
.
.

SET PAGES 1000 LINES 160
SET SERVEROUT ON SIZE 1000000 FORMAT WRAPPED
SET LONG 10000
SET ARRAYSIZE 5000

COL GB FOR 9,999.00
COL MB FOR 9,999.00

BREAK ON REPORT
COMPUTE SUM OF GB ON REPORT
COMPUTE SUM OF total_me ON REPORT

--$del /f buf_login.tmp
!rm -f buf_login.tmp
UNDEF 1

SET TERM ON
SET TRIMSPOOL ON

COL break_skip_1 NOPRINT
BREAK ON break_skip_1 SKIP 1
