delete from plan_table;
commit;

--/db2_practice7.txt
-----------------------------------------------------------------------------------------
--Exercise 2.
--Give the name of the departments which have an employee with salary category 1
create table dept as select * from  NIKOVITS.dept;
create table emp as select * from  NIKOVITS.emp;
create table sal_cat as select * from  NIKOVITS.sal_cat;
select * from plan_table;

select * from emp;
select * from dept;
select * from sal_cat;

EXPLAIN PLAN SET statement_id='st2'  -- 'st1' -> unique name of the statement
   FOR
select distinct dname
from dept, emp, sal_cat
where category = 1 and sal between lowest_sal and highest_sal
and emp.deptno = dept.deptno;


SELECT LPAD(' ', 2*(level-1))||operation||' + '||options||' + '
  ||object_owner||nvl2(object_owner,'.','')||object_name xplan
FROM plan_table
START WITH id = 0 AND statement_id = 'st2'                 -- 'st1' -> unique name of the statement
CONNECT BY PRIOR id = parent_id AND statement_id = 'st2'   -- 'st1' -> again
ORDER SIBLINGS BY position;

--create index to see diff in plan
drop index sal1;
create index sal1 on sal_cat(category);
create index hhh1 on emp(deptno);

--use hint force it not to use index
select /*+ full(sal_cat) */ distinct dname
from dept, emp, sal_cat
where category = 1 and sal between lowest_sal and highest_sal
and emp.deptno = dept.deptno;

select /*+  */ distinct dname
from dept, emp, sal_cat
where category = 1 and sal between lowest_sal and highest_sal
and emp.deptno = dept.deptno;


--https://people.inf.elte.hu/nikovits/DB2/07_expl.txt
--https://people.inf.elte.hu/nikovits/DB2/07_hints.txt


-----------------------------------------------------------------------------------------
--Exercise 3.
-------------
--Compare the two similar queries in runtime_example.txt, compare the execution plans
--and tell what the difference is. Why one of them is much faster? See COST and CARDINALITY
--for the nodes.
ALTER SESSION SET nls_date_language = american;  -- 'monday'

EXPLAIN PLAN SET statement_id='fast'  -- 'st1' -> unique name of the statement
   FOR
SELECT sum(no_calls) FROM nikovits.calls_v ca, nikovits.tel_center_v ce, nikovits.primer_v p
WHERE ca.calling_id = ce.c_id AND ce.district = p. district AND p.city = 'Szentendre'
AND ca.call_date = next_day(to_date('2012.01.31', 'yyyy.mm.dd'), 'monday') - 1;

EXPLAIN PLAN SET statement_id='slow'  -- 'st1' -> unique name of the statement
   FOR
SELECT sum(no_calls) FROM nikovits.calls_v ca, nikovits.tel_center_v ce, nikovits.primer_v p
WHERE ca.calling_id = ce.c_id AND ce.district = p. district AND p.city = 'Szentendre'
AND ca.call_date + 1 = next_day(to_date('2012.01.31', 'yyyy.mm.dd'), 'monday');


SELECT SUBSTR(LPAD(' ', 2*(LEVEL-1))||operation||' + '||options||' + '||object_name, 1, 50) terv,
  cost, cardinality, bytes, io_cost, cpu_cost
FROM plan_table
START WITH ID = 0 AND STATEMENT_ID = 'fast'                 -- 'st1' -> unique name of the statement
CONNECT BY PRIOR id = parent_id AND statement_id = 'fast'   -- 'st1'
ORDER SIBLINGS BY position;

--SELECT STATEMENT +  +                9713     1
--  SORT + AGGREGATE +                          1
--    HASH JOIN +  +                    9713    2641
--      TABLE ACCESS + FULL + KOZPONT     3     1249
--      MERGE JOIN + CARTESIAN +        9710    163735
--        TABLE ACCESS + FULL + PRIMER     3    1
--        BUFFER + SORT +                9707   163735
--          PARTITION RANGE + SINGLE +    9707  163735
--            TABLE ACCESS + FULL + HIVAS 9707  163735

SELECT SUBSTR(LPAD(' ', 2*(LEVEL-1))||operation||' + '||options||' + '||object_name, 1, 50) terv,
  cost, cardinality, bytes, io_cost, cpu_cost
FROM plan_table
START WITH ID = 0 AND STATEMENT_ID = 'slow'                 -- 'st1' -> unique name of the statement
CONNECT BY PRIOR id = parent_id AND statement_id = 'slow'   -- 'st1'
ORDER SIBLINGS BY position;

--SELECT STATEMENT +  +                58136        1
--  SORT + AGGREGATE +                              1
--    HASH JOIN +  +                    58136       7273
--      TABLE ACCESS + FULL + KOZPONT        3      1249
--      MERGE JOIN + CARTESIAN +        58132       450930
--        TABLE ACCESS + FULL + PRIMER        3     1
--        BUFFER + SORT +                58129      450930
--          PARTITION RANGE + ALL +    58129        450930
--            TABLE ACCESS + FULL + HIVAS 58129     450930


-----------------------------------------------------------------------------------------
--Exercise 4.
-----------
--PRODUCT(prod_id, name, color, weight)
--SUPPLIER(supl_id, name, status, address)
--PROJECT(proj_id, name, address)
--SUPPLY(supl_id, prod_id, proj_id, amount, date)

--Give the sum amount of products where color = 'piros'
--Give hints in order to use the following execution plans (see hints.txt)

SELECT SUM(amount)
FROM nikovits.product p, nikovits.supply s
WHERE p.prod_id=s.prod_id and color='piros';

--a) no index at all
SELECT /*+ full(p) full(s) */ SUM(amount)
FROM nikovits.product p, nikovits.supply s
WHERE p.prod_id=s.prod_id and color='piros';

--b) one index
select * from dba_indexes where table_owner = 'NIKOVITS'
and table_name in ('PRODUCT','SUPPLY');  --find all indexes on this two table

SELECT /*+ index(p,PROD_COLOR_IDX) full(s) */ SUM(amount)
FROM nikovits.product p, nikovits.supply s
WHERE p.prod_id=s.prod_id and color='piros';

--c) index for both tables
SELECT /*+ index(p) index(s) */ SUM(amount) FROM nikovits.product p, nikovits.supply s
WHERE p.prod_id=s.prod_id and color='piros';

--d) SORT-MERGE join
SELECT /*+ use_merge(p s) */ SUM(amount) FROM nikovits.product p, nikovits.supply s
WHERE p.prod_id=s.prod_id and color='piros';

--e) NESTED-LOOPS join
SELECT /*+ use_nl(p s) */ SUM(amount) FROM nikovits.product p, nikovits.supply s
WHERE p.prod_id=s.prod_id and color='piros';

SELECT /*+ use_nl(p s) index(p) full(s)*/ SUM(amount) FROM nikovits.product p, nikovits.supply s
WHERE p.prod_id=s.prod_id and color='piros';

--f) NESTED-LOOPS join and no index
SELECT /*+ use_nl(p s) no_index(s) */ SUM(amount) FROM nikovits.product p, nikovits.supply s
WHERE p.prod_id=s.prod_id and color='piros';

-----------------------------------------------------------------------------------------
----https://people.inf.elte.hu/nikovits/DB2/db2_practice8.txt

-----------------------------------------------------------------------------------------
--PRODUCT(prod_id, name, color, weight)
--SUPPLIER(supl_id, name, status, address)
--PROJECT(proj_id, name, address)
--SUPPLY(supl_id, prod_id, proj_id, amount, sDate)


--Exercise 1.
--Query:
--Give the sum amount of products where prod_id=2 and supl_id=2.
--
--Give hints in order to use the following execution plans:

--a) No index
select /*+ NO_INDEX(s)*/sum(amount)
from nikovits.supply s
where prod_id=2 and supl_id=2;

--b) Two indexes and the intersection of ROWID-s (AND-EQUAL in plan).
select /*+ AND_EQUAL(s supply_prod_idx supply_supplier_idx)*/sum(amount)
from nikovits.supply s
where prod_id=2 and supl_id=2;

-----------------------------------------------------------------------------------------
--Exercise 2.
--Query:
--Give the sum amount of products where the color of product is 'piros' and address of supplier is 'Pecs'.
--Give hints in order to use the following execution plans:

--a) Join order should be: first supply and product tables then supplier table.
select /*+ ordered */ sum(amount) 
from nikovits.supply sy, nikovits.product p, nikovits.supplier sr
where sy.supl_id=sr.supl_id and p.prod_id=sy.prod_id
and p.color='piros' and sr.address='Pecs';

--b) Join order should be: first supply and supplier tables then product table.
select /*+ ordered */ sum(amount) 
from nikovits.supply sy, nikovits.supplier sr, nikovits.product p
where sy.supl_id=sr.supl_id and p.prod_id=sy.prod_id
and p.color='piros' and sr.address='Pecs';

SELECT/*+USE_HASH(s sl) NO_USE_HASH(p sl)*/ *
FROM nikovits.product p, nikovits.supplier sl, nikovits.supply s
WHERE p.prod_id=s.prod_id and color='piros' and sl.address = 'Pecs' and sl.supl_id = s.supl_id;

-----------------------------------------------------------------------------------------

--Exercise 3.
--Give a SELECT statement which has the following execution plan.

--PLAN (OPERATION + OPTIONS + OBJECT_NAME)                                               
------------------------------------------ 
--SELECT STATEMENT +  + 
--  SORT + AGGREGATE + 
--    TABLE ACCESS + FULL + PRODUCT

SELECT sum(weight) FROM PRODUCT;

select /*+ full(p) */ sum(weight)
from nikovits.product p where color='piros';

--SELECT STATEMENT +  +
--  SORT + AGGREGATE +
--    TABLE ACCESS + BY INDEX ROWID + PRODUCT
--      INDEX + UNIQUE SCAN + PROD_ID_IDX

SELECT sum(weight) FROM nikovits.PRODUCT where prod_id = 10;

select /*+ index(p) */ sum(weight)
from nikovits.product p where prod_id=1;

--SELECT STATEMENT +  + 
--  SORT + AGGREGATE + 
--    HASH JOIN +  + 
--      TABLE ACCESS + FULL + PROJECT
--      TABLE ACCESS + FULL + SUPPLY

select /*+ full(p) */ sum(amount)
from nikovits.supply s natural join nikovits.project p 
where address='Szeged';

--SELECT STATEMENT +  + 
--  HASH + GROUP BY + 
--    HASH JOIN +  + 
--      TABLE ACCESS + FULL + PROJECT
--      TABLE ACCESS + FULL + SUPPLY
select /*+ full(p) */ sum(amount)
from nikovits.supply s natural join nikovits.project p  
group by prod_id;
      
--SELECT STATEMENT +  + 
--  SORT + AGGREGATE + 
--    MERGE JOIN +  + 
--      SORT + JOIN + 
--        TABLE ACCESS + BY INDEX ROWID BATCHED + PRODUCT
--          INDEX + RANGE SCAN + PROD_COLOR_IDX
--      SORT + JOIN + 
--        TABLE ACCESS + FULL + SUPPLY  

select /*+ use_merge(s p) index(p) */ sum(amount)
from nikovits.supply s natural join nikovits.product p 
where color='piros';

--SELECT STATEMENT +  + 
--  FILTER +  + 
--    HASH + GROUP BY + 
--      HASH JOIN +  + 
--        TABLE ACCESS + FULL + PROJECT
--        HASH JOIN +  + 
--          TABLE ACCESS + FULL + SUPPLIER
--          TABLE ACCESS + FULL + SUPPLY

select /*+ no_index(s) no_index(sr) no_index( p)leading(sr) */ sum(amount)
from nikovits.supply s, nikovits.supplier sr, nikovits.project p 
where s.supl_id=sr.supl_id and s.proj_id=p.proj_id 
group by prod_id having prod_id > 100;

select /*+ no_index(s) leading(sr) */ sum(amount)
from nikovits.supply s, nikovits.supplier sr, nikovits.project p 
where s.supl_id=sr.supl_id and s.proj_id=p.proj_id 
and sr.address='Pecs' and p.address='Szeged'
group by prod_id having prod_id > 100;


------------------------------------------------------------

------------------------------------------------------------

--https://people.inf.elte.hu/nikovits/DB2/07_execution_plans4.txt

--ANTI: NOT EXIST, NOT IN
--SEMI: IN, EXIST

--https://people.inf.elte.hu/nikovits/DB2/07_execution_plans1.txt
--https://people.inf.elte.hu/nikovits/DB2/db2_practice9.txt
--paper exercises