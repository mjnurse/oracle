/*
** NAME
**    xp - Transparent Explain Plan Utility for SQLPlus. 
**
** USAGE
**    @xp
**
** DESCRIPTION
**    Reports the execution plan of the current SQL buffer (i.e. the most recent SQL statement
**    to be run, edited, fetched etc (not necessarily run), and then places it back in the
**    buffer, as far as possible leaving everything the way it was. 
**
** AUTHOR
**    mjnurse.dev - 2004
*/

-- help_line: Transparent Explain Plan Utility for SQLPlus: @xp
-- desc_line: Transparent Explain Plan Utility for SQLPlus
 
-- NOTE: Uses OS-specific host commands 'TYPE' and 'DEL'. For Linux replace with 'cat' and 'rm'. 

SET TERM OFF 
STORE SET sqlplus_settings.sql REPLACE 
 
TTITLE OFF 
SET PAUSE OFF FEED OFF VERIFY OFF TIMING OFF PAGES 999 TRIMOUT ON TRIMSPOOL ON LONG 2000 
SET AUTOTRACE OFF LINES 190 FLAGGER OFF TAB OFF 
 
COL query_path FORMAT A70 HEA "Query Path" 
COL statement_id NEW_VALUE statement_id 
COL optimizer FORMAT A9 
 
BREAK ON REPORT 
COMP SUM LABEL '' OF cost ON REPORT 
 
0 EXPLAIN PLAN SET STATEMENT_ID = '&STATEMENT_ID' FOR 
 
SAVE xplan.buf REPL 
 
SAVEPOINT xplan; 
 
SELECT USER||TO_CHAR(SYSDATE,'ddmmyyhh24miss') STATEMENT_ID FROM dual; 

VAR statement_id VARCHAR2(50) 
EXEC :statement_id := '&STATEMENT_ID'; 
 
DELETE plan_table WHERE statement_id = :statement_id; 
 
GET xplan.buf NOLIST 
 
SPOOL xplan_errors 
@xplan.buf 
SPOOL OFF 
 
SET TERM ON 
 
SPOOL xplan 
 
SET HEA OFF 
SELECT * FROM TABLE(dbms_xplan.DISPLAY('PLAN_TABLE','&statement_id','ALIAS')); 
 
SET DOC OFF 
 
HOST TYPE xplan_errors.lst 
HOST DEL xplan_errors.lst 
 
SPOOL OFF 
 
SET TERM OFF FEED ON HEA ON  
ROLLBACK TO xplan; 
 
GET xplan.buf NOLIST  
l1  
DEL  
 
CLEAR BREAKS 
UNDEF statement_id  
@sqlplus_settings.sql 

HOST DEL xplan.buf
HOST DEL xplan.LST
HOST DEL sqlplus_settings.sql
 
SET TERM ON 
