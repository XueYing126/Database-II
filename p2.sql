--(DBA_SYNONYMS, DBA_VIEWS, DBA_SEQUENCES, DBA_DB_LINKS)
--Give the following query (in ARAMIS database):
  SELECT * FROM sz1;
--Is there a table named 'sz1' ? (Answer -> no)
--Then which is the table (owner, table_name) whose records are displayed?
--You should find a table, a view is not enough.

SELECT * from dba_objects where lower(object_name) like 'sz1%';
SELECT * FROM DBA_SYNONYMS WHERE owner='PUBLIC' AND synonym_name like'SZ1%';
SELECT * from dba_objects where lower(object_name) like 'v1%' and owner='NIKOVITS';
SELECT view_name, text FROM DBA_VIEWS WHERE owner='NIKOVITS' AND view_name='V1';
SELECT * from dba_objects where lower(object_name) like 'employ%' and owner='NIKOVITS';

--Oracle storage concepts
-----------------------
--(DBA_TABLES, DBA_DATA_FILES, DBA_TEMP_FILES, DBA_TABLESPACES, DBA_SEGMENTS, DBA_EXTENTS, DBA_FREE_SPACE)
--1.Give the names and sizes of database files. (file_name, size_in_bytes)
select * from dba_data_files;
select file_name, bytes from dba_data_files;

--2.Give the names of tablespaces. (tablespace_name)
select * from dba_tablespaces;
select tablespace_name from dba_tablespaces;

--3.Which datafile belongs to which tablespace? (filename, tablespace_name)
select file_name, tablespace_name from dba_data_files;

--4.Is there a tablespace that doesn't have datafiles? -> see temp_files
select tablespace_name from dba_tablespaces
where tablespace_name not in( 
select tablespace_name from dba_data_files);

select file_name, tablespace_name
from dba_temp_files;

--5.What is the block size in USERS tablespace? (block_size)
select block_size from dba_tablespaces where tablespace_name = 'USERS';

--6.Find some segments whose owner is NIKOVITS. What segment types do they have? List the types. (segment_type)
select distinct segment_type 
from dba_segments
where owner = 'NIKOVITS';

--7.How many extents there are in file 'users02.dbf' ? (num_extents)
select count(*)
from dba_extents 
where file_id = (
select file_id
from dba_data_files
where file_name like '%users02.dbf'
);

SELECT count(*) FROM dba_data_files f, dba_extents e
WHERE file_name like '%/users02%' AND f.file_id=e.file_id;

--How many bytes do they occupy? (sum_bytes)
select sum(bytes)
from dba_extents 
where file_id = (
select file_id
from dba_data_files
where file_name like '%users02.dbf'
);

SELECT sum(e.bytes) FROM dba_data_files f, dba_extents e
WHERE file_name LIKE '%/users02%' AND f.file_id=e.file_id;

--8.How many free extents there are in file 'users02.dbf', and what is the summarized size of them ? (num, sum_bytes)
select count(*), sum(bytes)
from dba_free_space 
where file_id = (
select file_id
from dba_data_files
where file_name like '%users02.dbf'
);

select count(*), sum(s.bytes), f.bytes
from dba_data_files f, dba_free_space s
where f.file_id = s.file_id and f.file_name like '%users02.dbf'
group by f.bytes;

--How many percentage of file 'users02.dbf' is full (allocated to some object)?
select (1-sum(s.bytes)/f.bytes)
from dba_data_files f, dba_free_space s
where f.file_id = s.file_id and f.file_name like '%users02.dbf'
group by f.bytes;

SELECT sum(e.bytes)/f.bytes 
FROM dba_data_files f, dba_extents e
WHERE file_name LIKE '%/users02%' AND f.file_id=e.file_id
group by f.bytes;

--9.Who is the owner whose objects occupy the most space in the database? (owner, sum_bytes)
select owner, sum(bytes)
from dba_extents
group by owner
order by sum(bytes) desc
FETCH FIRST 1 ROWS ONLY;

-- If we want only the first row (e.g. INDEXES):
SELECT owner, sum(bytes) 
from dba_segments 
WHERE segment_type = 'INDEX'
GROUP BY owner 
order by 2 desc 
FETCH FIRST 1 ROWS ONLY;

--10.Is there a table of owner NIKOVITS that has extents in more than one datafile? (table_name)
select segment_name, count(distinct file_id)
from dba_extents
where owner = 'NIKOVITS' and segment_type = 'TABLE'
group by segment_name
having count(distinct file_id)>1;

--Select one from the above tables (e.g. tabla_123) and give the occupied space by files. (filename, bytes)
select file_name, sum(bytes)
from dba_extents natural join (select file_name, file_id from dba_data_files)
where owner = 'NIKOVITS' and segment_type = 'TABLE' and segment_name = 'TABLA_123'
group by file_name;


--11.On which tablespace is the table ORAUSER.dolgozo?
--On which tablespace is the table NIKOVITS.eladasok? Why NULL? 
-- (-> partitioned table, stored on more than 1 tablespace)
select tablespace_name
from dba_segments
where owner = 'ORAUSER' 
and segment_name = 'DOLGOZO'
and segment_type = 'TABLE';

select tablespace_name
from dba_segments
where owner = 'NIKOVITS' 
and segment_name = 'ELADASOK'
and segment_type = 'TABLE';

select *
from dba_segments
where owner = 'NIKOVITS' 
and segment_name = 'ELADASOK';

select owner,table_name,PARTITIONED      
from dba_tables
where owner = 'NIKOVITS' 
and table_name = 'ELADASOK';

-------------------------------------------------------
--Write a PL/SQL procedure, which prints out for the parameter user his/her oldest table (which was created earliest)
--the size of the table in bytes (the size of the table's segment) and the creation date. (table_name, bytes, created)


CREATE OR REPLACE PROCEDURE oldest_table(p_user VARCHAR2) IS
CURSOR curs1 IS 
    select o.object_name as table_name, s.bytes as bytes , o.created as created
    from dba_objects o, dba_segments s
    where o.owner like upper(p_user)||'%' and o.object_type = 'TABLE'
    and o.object_name = s.segment_name and o.owner = s.owner
    order by CREATED desc
    FETCH FIRST 1 ROWS ONLY;
    rec curs1%ROWTYPE;
begin
    OPEN curs1;
    LOOP
        FETCH curs1 INTO rec;
        EXIT WHEN curs1%NOTFOUND;
        dbms_output.put_line(rec.table_name||' - '||rec.bytes||' - '||rec.created);
    END LOOP;
    CLOSE curs1;
end;
/

SET SERVEROUTPUT ON
execute oldest_table('NIKOVITS');
