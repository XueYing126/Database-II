--Index Organized Tables, Partitions, Clusters
--------------------------------------------
SELECT * FROM dba_tables;
SELECT distinct iot_type FROM dba_tables;
--3.Give the index organized tables of user NIKOVITS.
SELECT owner, table_name, iot_name, iot_type FROM dba_tables WHERE owner='NIKOVITS' AND iot_type = 'IOT';

--Find the table_name, index_name and overflow name (if exists) of the above tables.
SELECT table_name, index_name, index_type FROM dba_indexes 
WHERE table_owner='NIKOVITS' AND index_type LIKE '%IOT%TOP%';

SELECT owner, table_name, iot_name, iot_type FROM dba_tables 
WHERE owner='NIKOVITS' AND iot_type = 'IOT_OVERFLOW';


--Which objects of the previous three has not null data_object_id in DBA_OBJECTS?
select *
from dba_objects
where owner = 'NIKOVITS' and object_type = 'TABLE' and data_object_id is not null;
-------------------------------------------

--4.Give the names and sizes (in bytes) of the partitions of table NIKOVITS.ELADASOK
select * from NIKOVITS.ELADASOK;
SELECT * FROM dba_part_tables WHERE owner='NIKOVITS' AND table_name='ELADASOK';
SELECT * FROM dba_tab_partitions WHERE table_owner='NIKOVITS' AND table_name='ELADASOK';
SELECT segment_name, partition_name, segment_type, bytes FROM dba_segments 
WHERE owner='NIKOVITS' AND segment_name LIKE 'ELADASOK' AND segment_type LIKE 'TABLE%';
-------------------------------------------

--5.Which is the biggest partitioned table (in bytes) in the database?
--It can have subpartitions as well.

select owner, segment_name,sum(bytes) 
from dba_segments
where segment_type like 'TABLE%PARTITION'
group by owner, segment_name
order by sum(bytes) DESC
fetch first 1 row only;
------------------------------------------

--6.Give a cluster whose cluster key consists of 3 columns.
--A cluster can have more than two tables on it!!!
select owner,cluster_name
from dba_clu_columns
group by owner,cluster_name
having count(distinct clu_column_name) = 3;

------------------------------------------

--7.How many clusters do we have in the database which uses NOT THE DEFAULT hash function?
--(So the creator defined a hash expression.)
SELECT * FROM dba_cluster_hash_expressions;
------------------------------------------

--8.Write a PL/SQL procedure which prints out the storage type (heap organized, partitioned, index organized or clustered) 
--for the parameter table.
SELECT owner, table_name, cluster_name, partitioned, iot_type 
FROM dba_tables WHERE owner='NIKOVITS' 
AND table_name IN ('ELADASOK5', 'CIKK_IOT', 'EMP_CLT');

CREATE OR REPLACE PROCEDURE print_type(p_owner VARCHAR2, p_table VARCHAR2) IS
CURSOR curs1 IS
    select owner, table_name, cluster_name, partitioned, iot_type
    from dba_tables where owner like upper(p_owner) and table_name like upper(p_table);
    rec curs1%ROWTYPE;
BEGIN
  OPEN curs1;
  LOOP
    FETCH curs1 INTO rec;
    EXIT WHEN curs1%NOTFOUND;
    if rec.cluster_name is not null then
        dbms_output.put_line(rec.owner||' - '||rec.table_name||' - clustered: '||rec.cluster_name);
    end if;
    if rec.partitioned like 'YES' then
        dbms_output.put_line(rec.owner||' - '||rec.table_name||' - partitioned ');
    end if;
    if rec.iot_type is not null then
        dbms_output.put_line(rec.owner||' - '||rec.table_name||' - index organized: '||rec.iot_type);
    end if;

  END LOOP;
  CLOSE curs1;
END;
/
-----
set serveroutput on
execute print_type('nikovits', 'eladasok5');
execute print_type('nikovits', 'cikk_iot');
execute print_type('nikovits', 'emp_clt');