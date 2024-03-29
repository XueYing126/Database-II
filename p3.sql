--1.
--How many data blocks are allocated in the database for the table NIKOVITS.CIKK?
--There can be empty blocks, but we count them too.
--The same question: how many data blocks does the segment of the table have?
select blocks 
from dba_segments
where owner = 'NIKOVITS' and segment_name = 'CIKK' and segment_type = 'TABLE';


--2.
--How many filled data blocks does the previous table have?
--Filled means that the block is not empty (there is at least one row in it).
--This question is not the same as the previous !!!
--How many empty data blocks does the table have?
SELECT 
DISTINCT dbms_rowid.rowid_relative_fno(ROWID) file_id, 
         dbms_rowid.rowid_object(ROWID) data_object, 
         dbms_rowid.rowid_block_number(ROWID) block_nr
FROM nikovits.cikk;
-- The number of these data blocks:
SELECT count(*) FROM
(SELECT DISTINCT dbms_rowid.rowid_relative_fno(ROWID) file_id, 
                 dbms_rowid.rowid_object(ROWID) data_object, 
                 dbms_rowid.rowid_block_number(ROWID) block_nr
 FROM nikovits.cikk);
 
 --How many empty data blocks does the table have? --?
(select blocks - (SELECT count(*) FROM
(SELECT DISTINCT dbms_rowid.rowid_relative_fno(ROWID) file_id, 
                 dbms_rowid.rowid_object(ROWID) data_object, 
                 dbms_rowid.rowid_block_number(ROWID) block_nr
 FROM nikovits.cikk)) 
 from dba_segments where owner = 'NIKOVITS' and segment_name = 'CIKK' and segment_type = 'TABLE');
 
--3.
--How many rows are there in each block of the previous table?

SELECT dbms_rowid.rowid_relative_fno(ROWID) file_no,
       dbms_rowid.rowid_block_number(ROWID) block_no, 
       count(*)
FROM nikovits.cikk
GROUP BY dbms_rowid.rowid_block_number(ROWID), 
         dbms_rowid.rowid_relative_fno(ROWID);
         
--4.
--There is a table NIKOVITS.ELADASOK which has the following row:
--szla_szam = 100 (szla_szam is a column name)
--In which datafile is the given row stored?
--Within the datafile in which block? (block number) 
--In which data object? (Give the name of the segment.)
SELECT  dbms_rowid.rowid_relative_fno(ROWID) file_id, 
        dbms_rowid.rowid_object(ROWID) data_object,
        dbms_rowid.rowid_block_number(ROWID) block_nr, 
        dbms_rowid.rowid_row_number(ROWID) row_nr 
FROM nikovits.eladasok WHERE szla_szam = 100;

SELECT * FROM dba_data_files WHERE file_id=7;             -- in ARAMIS database
SELECT * FROM dba_objects WHERE data_object_id=80868;

-- We combine the previous two together:
SELECT dbms_rowid.rowid_relative_fno(e.ROWID) file_id, f.file_name 
FROM nikovits.eladasok e, dba_data_files f
WHERE szla_szam = 100 AND dbms_rowid.rowid_relative_fno(e.ROWID)=f.file_id;

-------------------------------------------------------
--5.
--Write a PL/SQL procedure which prints out the number of rows in each data block for the 
--following table: NIKOVITS.TABLA_123. The output has 3 columns: file_id, block_id, num_of_rows.     
select file_id, block_id,
from dba_extents
where owner = 'NIKOVITS' and segment_name = 'TABLA_123';


CREATE OR REPLACE PROCEDURE num_of_rows IS 
CURSOR curs1 IS
SELECT dbms_rowid.rowid_relative_fno(ROWID) file_id,
       dbms_rowid.rowid_block_number(ROWID) block_id, 
       count(*) as num_of_rows
       FROM NIKOVITS.TABLA_123
       GROUP BY dbms_rowid.rowid_block_number(ROWID), dbms_rowid.rowid_relative_fno(ROWID);
    rec curs1%ROWTYPE;
BEGIN
  OPEN curs1;
  LOOP
    FETCH curs1 INTO rec;
    EXIT WHEN curs1%NOTFOUND;
    dbms_output.put_line(rec.file_id||' - '||rec.block_id||' - '||rec.num_of_rows);
  END LOOP;
  CLOSE curs1;
END;
/
-----
SET SERVEROUTPUT ON
execute num_of_rows();

--Hint:
--Find the extents of the table. You can find the first block of the extents and the sizes in blocks
--in DBA_EXTENTS. Check the individual blocks, how many rows they contain. (use rowid)

CREATE OR REPLACE PROCEDURE num_of_rows IS
 cnt NUMBER;
BEGIN 
 FOR rec IN (select file_id, block_id, blocks from dba_extents 
             where owner='NIKOVITS' and segment_name='TABLA_123' order by 1,2,3)
 LOOP
  FOR i in 1..rec.blocks LOOP
   SELECT count(*) into cnt FROM nikovits.tabla_123 
   WHERE dbms_rowid.rowid_relative_fno(ROWID) = rec.file_id
   AND dbms_rowid.rowid_block_number(ROWID) = rec.block_id+i-1;
   dbms_output.put_line(rec.file_id||'.'||to_char(rec.block_id+i-1)||'->'||cnt);
  END LOOP;
 END LOOP;
END;
/
-------------------------------------------------------
--6.
--Write a PL/SQL procedure which counts and prints the number of empty blocks of a table.
--CREATE OR REPLACE PROCEDURE empty_blocks(p_owner VARCHAR2, p_table VARCHAR2) IS
...
Test:
-----
set serveroutput on
execute empty_blocks('nikovits', 'employees');

--Hint: 
--Count the total number of blocks (see the segment), the filled blocks (use rowid), 
--the difference is the number of empty blocks.
--You have to use dynamic SQL statement in the PL/SQL program, see pl_dynamicSQL.txt
-------------------------------------------------------