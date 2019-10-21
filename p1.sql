--Give the SELECT statements and the results for the following queries.
--Parenthesis shows the columns of the required result.
--(DBA_OBJECTS)

--1.Who is the owner of the view DBA_TABLES? Who is the owner of table DUAL? (owner)
select * from dba_objects;
select owner from dba_objects where object_name = 'DBA_TABLES' and object_type = 'VIEW';
select owner from dba_objects where object_name = 'DUAL' and object_type = 'TABLE';

--2.Who is the owner of synonym DBA_TABLES? (or synonym DUAL) (owner)
select owner from dba_objects where object_name = 'DBA_TABLES' and object_type = 'SYNONYM';
select owner from dba_objects where object_name = 'DUAL' and object_type = 'SYNONYM';

--3.What kind of objects the database user ORAUSER has? (dba_objects.object_type column)
select distinct object_type from dba_objects where owner = 'ORAUSER';

--4.What are the object types existing in the database? (object_type) 
select distinct object_type from dba_objects;

--5.Which users have more than 10 different kind of objects in the database? (owner)
select owner 
from dba_objects
group by owner
having count(distinct object_type) >=10;

--6.Which users have both triggers and views in the database? (owner)
select owner
from dba_objects
where object_type = 'TRIGGER'
intersect
select owner
from dba_objects
where object_type = 'VIEW';

--7.Which users have views but don't have triggers? (owner)
select distinct owner
from dba_objects
where object_type = 'VIEW'
minus
select distinct owner
from dba_objects
where object_type = 'TRIGGER';

--8.Which users have more than 40 tables, but less than 30 indexes? (owner)
select distinct owner
from dba_objects
where object_type = 'TABLE'
group by owner
having count(*) > 40
intersect
select distinct owner
from dba_objects
where object_type = 'INDEX'
group by owner
having count(*) < 30;

--9.Let's see the difference between a table and a view (dba_objects.data_object_id).
select data_object_id 
from dba_objects
where object_type = 'TABLE';

select distinct data_object_id 
from dba_objects
where object_type = 'VIEW';


--10.Which object types have NULL (or 0) in the column data_object_id? (object_type)
select distinct object_type
from dba_objects
where data_object_id is null or data_object_id = 0;


--11.Which object types have non NULL (and non 0) in the column data_object_id? (object_type)
select distinct object_type
from dba_objects
where data_object_id is not null or data_object_id <> 0;

--12.What is the intersection of the previous 2 queries? (object_type)
select distinct object_type
from dba_objects
where data_object_id is null or data_object_id = 0
intersect
select distinct object_type
from dba_objects
where data_object_id is not null or data_object_id <> 0;



--(DBA_TAB_COLUMNS)

--13.How many columns nikovits.emp table has? (num)
select * from dba_tab_columns;
select * from dba_tab_columns where owner = 'NIKOVITS' and table_name = 'EMP';
select count(*) from dba_tab_columns where owner = 'NIKOVITS' and table_name = 'EMP';

--14.What is the data type of the 6th column of the table nikovits.emp? (data_type)
select data_type from dba_tab_columns where owner = 'NIKOVITS' and table_name = 'EMP' and column_id = 6;

--15.Give the owner and name of the tables which have column name beginning with letter 'Z'.(owner, table_name)
select distinct owner, table_name
from dba_tab_columns
where column_name like 'Z%';

--16.Give the owner and name of the tables which have at least 8 columns with data type DATE.(owner, table_name)
select owner, table_name
from dba_tab_columns
where data_type = 'DATE'
group by owner, table_name
having count(*) >=8;

--17.Give the owner and name of the tables whose 1st and 4th column's datatype is VARCHAR2.(owner, table_name)
select owner, table_name
from dba_tab_columns
where data_type = 'VARCHAR2' and column_id = 1
intersect
select owner, table_name
from dba_tab_columns
where data_type = 'VARCHAR2' and column_id = 4;

--18.Write a PL/SQL procedure, which prints out the owners and names of the tables beginning with the parameter character string. 
CREATE OR REPLACE PROCEDURE table_print(p_char VARCHAR2) IS
CURSOR curs1 IS 
    select owner, table_name
    from dba_tab_columns
    where table_name like upper(p_char)||'%'; --since it is a variable
    --where table_name like 'p_char%' ; --not good
    rec curs1%ROWTYPE;
begin
    OPEN curs1;
    LOOP
        FETCH curs1 INTO rec;
        EXIT WHEN curs1%NOTFOUND;
        dbms_output.put_line(to_char(rec.owner)||' - '||rec.table_name);
    END LOOP;
    CLOSE curs1;
end;
/


set serveroutput on
execute table_print('Z');


--==============================================================================
--Example: Run the following SQL and PL/SQL statements and examine the rows of the table.
--==============================================================================
CREATE TABLE test1(col1 INTEGER PRIMARY KEY, col2 VARCHAR2(20));
describe test1;

CREATE SEQUENCE seq1 
MINVALUE 1 MAXVALUE 100 INCREMENT BY 5 START WITH 50 CYCLE;

CREATE OR REPLACE TRIGGER test1_bir -- before insert row
BEFORE INSERT ON test1 
FOR EACH ROW 
WHEN (new.col1 is null) 
BEGIN
  :new.col1 := seq1.nextval;
END;
/
BEGIN
 FOR i IN 1..14 LOOP 
  INSERT INTO test1 VALUES(null, 'trigger'||to_char(i,'FM09'));
 END LOOP;
 INSERT INTO test1 VALUES(seq1.currval + 1, 'sequence + 1'); 
 COMMIT;
END;
/
SELECT * FROM test1 ORDER BY col2;

DROP TABLE test1;    -- trigger will be dropped too
DROP sequence seq1;  -- sequence is not bound to the table
