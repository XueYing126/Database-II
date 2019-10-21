--Oracle indexes
--------------
--1.Give the tables (table_name) which has a column indexed in descending order.
--See the name of the column. Why is it so strange? -> DBA_IND_EXPRESSIONS
select * from dba_ind_columns;
select distinct table_name,column_name from dba_ind_columns where descend = 'DESC';

--(In the solutions only objects of Nikovits are concerned.)
SELECT * FROM dba_ind_columns WHERE descend='DESC' AND index_owner='NIKOVITS';

--See the name of the column. Why is it so strange? -> DBA_IND_EXPRESSIONS.COLUMN_NAME
SELECT * FROM dba_ind_columns WHERE index_name='EMP2' AND index_owner='NIKOVITS';
SELECT * FROM dba_ind_expressions WHERE index_name='EMP2' AND index_owner='NIKOVITS';

--2.Give the indexes (index name) which are composite and have at least 9 columns (expressions).
select index_owner,index_name 
from dba_ind_columns
group by index_owner,index_name
having count(*)>=9;
-- confirm one of them
SELECT * FROM dba_ind_columns WHERE index_owner='SYS' AND index_name='I_OBJ2';

--3.Give the name of bitmap indexes on table NIKOVITS.CUSTOMERS.
select *
from dba_indexes
where table_owner = 'NIKOVITS' and table_name= 'CUSTOMERS' and index_type = 'BITMAP';

--4.Give the indexes which has at least 2 columns and are function-based.
select index_owner as owner, index_name
from dba_ind_columns
group by index_owner,index_name
having count(*)>=2
intersect
select owner,index_name 
from dba_indexes 
where index_type like 'FUNCTION-BASED%';


--5.Give for one of the above indexes the expression for which the index was created.

select * from dba_indexes;
select * from dba_ind_columns;
SELECT * FROM dba_ind_expressions;
SELECT * FROM dba_ind_expressions WHERE index_owner='NIKOVITS';

---------------------------------------------------------------------------------------
select * 
from dba_segments 
where segment_type = 'INDEX';

select s.owner,s.segment_name,s.segment_type, s.bytes
from dba_segments s, dba_ind_expressions e
where s.segment_type = 'INDEX' and s.owner = e.index_owner and s.segment_name = e.index_name;

--6.Write a PL/SQL procedure which prints out the names and sizes (in bytes) of indexes created
--on the parameter table.
CREATE OR REPLACE PROCEDURE list_indexes(p_owner VARCHAR2, p_table VARCHAR2) IS
CURSOR curs1 IS
    select s.segment_name as name, s.bytes
    from dba_segments s, dba_ind_expressions e
    where s.segment_type = 'INDEX' and s.owner = e.index_owner and s.segment_name = e.index_name
        and e.table_owner like upper(p_owner) and e.table_name like upper(p_table);
    rec curs1%ROWTYPE;
BEGIN
  OPEN curs1;
  LOOP
    FETCH curs1 INTO rec;
    EXIT WHEN curs1%NOTFOUND;
    dbms_output.put_line(rec.name||' - '||rec.bytes);
  END LOOP;
  CLOSE curs1;
END;
/
set serveroutput on
execute list_indexes('nikovits', 'emp');
---------------------------------------------------------------------------------------

--7.Write a PL/SQL procedure which gets a file_id and block_id as a parameter and prints out the database
--object to which this datablock is allocated. (owner, object_name, object_type).
--If the specified datablock is not allocated to any objects, the procedure should print out 'Free block'.

select * from dba_extents;

CREATE OR REPLACE PROCEDURE block_usage(p_fileid NUMBER, p_blockid NUMBER) IS
CURSOR curs1 IS
    select owner, segment_name as object_name, segment_type as object_type 
    from dba_extents
    where file_id = p_fileid AND block_id = p_blockid;
    rec curs1%ROWTYPE;
BEGIN
  OPEN curs1;
  LOOP
    FETCH curs1 INTO rec;
    if rec.owner is null then
         dbms_output.put_line('FREE BLOCK!!!');
    end if;   
    EXIT WHEN curs1%NOTFOUND;
    dbms_output.put_line(rec.owner||' - '||rec.object_name||' - '||rec.object_type);
  END LOOP;
  CLOSE curs1;
END;
/

set serveroutput on
execute block_usage(2, 615);
execute block_usage(1, 232);