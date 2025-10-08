# PostgreSQL can have a bloat table (fragmentation) in a insert only table. See below how a rollback can cause this (attention to n_dead_tup column).

  
  # Create a new DB
db1=# create database db2;
CREATE DATABASE
db1=# \c db2;
You are now connected to database "db2" as user "rdsadmin".

  # Create a new table with unique id column
db2=# create table table1(id int unique);
CREATE TABLE

  # Disable AV 
db2=# ALTER TABLE table1 SET (autovacuum_enabled = false,toast.autovacuum_enabled = false);
ALTER TABLE

  # Check table stats
db2=# select relname, n_tup_ins, n_tup_upd, n_tup_del, n_live_tup, n_dead_tup, n_mod_since_analyze, n_ins_since_vacuum, last_vacuum, last_autovacuum, last_analyze, last_autoanalyze, vacuum_count, autovacuum_count, analyze_count, autoanalyze_count from pg_stat_all_tables where relname = 'table1';
 relname | n_tup_ins | n_tup_upd | n_tup_del | n_live_tup | n_dead_tup | n_mod_since_analyze | n_ins_since_vacuum | last_vacuum | last_autovacuum | last_analyze | last_autoanalyze | vacuum_count | autovacuum_count | analyze_count | autoanalyze_coun
t
---------+-----------+-----------+-----------+------------+------------+---------------------+--------------------+-------------+-----------------+--------------+------------------+--------------+------------------+---------------+-----------------
--
 table1  |         0 |         0 |         0 |          0 |          0 |                   0 |                  0 |             |                 |              |                  |            0 |                0 |             0 |
0
(1 row)
   
db2=# SELECT
db2-#     pg_size_pretty(pg_relation_size('table1')) as table_size,
db2-#     pg_size_pretty(pg_total_relation_size('table1')) as total_size,
db2-#     pg_relation_size('table1') / 8192 as table_blocks,
db2-#     pg_total_relation_size('table1') / 8192 as total_blocks;
 table_size | total_size | table_blocks | total_blocks
------------+------------+--------------+--------------
 0 bytes    | 8192 bytes |            0 |            1
(1 row)
   
  # Insert first row
db2=# insert into table1 (id) values (1);
INSERT 0 1

  # Check table stats
db2=# select relname, n_tup_ins, n_tup_upd, n_tup_del, n_live_tup, n_dead_tup, n_mod_since_analyze, n_ins_since_vacuum, last_vacuum, last_autovacuum, last_analyze, last_autoanalyze, vacuum_count, autovacuum_count, analyze_count, autoanalyze_count from pg_stat_all_tables where relname = 'table1';
 relname | n_tup_ins | n_tup_upd | n_tup_del | n_live_tup | n_dead_tup | n_mod_since_analyze | n_ins_since_vacuum | last_vacuum | last_autovacuum | last_analyze | last_autoanalyze | vacuum_count | autovacuum_count | analyze_count | autoanalyze_coun
t
---------+-----------+-----------+-----------+------------+------------+---------------------+--------------------+-------------+-----------------+--------------+------------------+--------------+------------------+---------------+-----------------
--
 table1  |         1 |         0 |         0 |          1 |          0 |                   1 |                  1 |             |                 |              |                  |            0 |                0 |             0 |
0
(1 row)

db2=# SELECT
    pg_size_pretty(pg_relation_size('table1')) as table_size,
    pg_size_pretty(pg_total_relation_size('table1')) as total_size,
    pg_relation_size('table1') / 8192 as table_blocks,
    pg_total_relation_size('table1') / 8192 as total_blocks;
 table_size | total_size | table_blocks | total_blocks
------------+------------+--------------+--------------
 8192 bytes | 24 kB      |            1 |            3
(1 row)

   
  # Insert another row which will rollback due to unique constraint
db2=# insert into table1 (id) values (1);
ERROR:  duplicate key value violates unique constraint "table1_id_key"
DETAIL:  Key (id)=(1) already exists.

  # Check table stats, see the dead tuple in n_dead_tup column from previous 0 to 1 now.
db2=# select relname, n_tup_ins, n_tup_upd, n_tup_del, n_live_tup, n_dead_tup, n_mod_since_analyze, n_ins_since_vacuum, last_vacuum, last_autovacuum, last_analyze, last_autoanalyze, vacuum_count, autovacuum_count, analyze_count, autoanalyze_count from pg_stat_all_tables where relname = 'table1';
 relname | n_tup_ins | n_tup_upd | n_tup_del | n_live_tup | n_dead_tup | n_mod_since_analyze | n_ins_since_vacuum | last_vacuum | last_autovacuum | last_analyze | last_autoanalyze | vacuum_count | autovacuum_count | analyze_count | autoanalyze_coun
t
---------+-----------+-----------+-----------+------------+------------+---------------------+--------------------+-------------+-----------------+--------------+------------------+--------------+------------------+---------------+-----------------
--
 table1  |         2 |         0 |         0 |          1 |          1 |                   1 |                  2 |             |                 |              |                  |            0 |                0 |             0 |
0
(1 row)

db2=# SELECT
    pg_size_pretty(pg_relation_size('table1')) as table_size,
    pg_size_pretty(pg_total_relation_size('table1')) as total_size,
    pg_relation_size('table1') / 8192 as table_blocks,
    pg_total_relation_size('table1') / 8192 as total_blocks;
 table_size | total_size | table_blocks | total_blocks
------------+------------+--------------+--------------
 8192 bytes | 24 kB      |            1 |            3
(1 row)

\q
   
  # now run the insert multiple times and see the bloat increasing considerable
for i in {1..10000}; do
    psql -d db2 -c "insert into table1 (id) values (1);"
done
DETAIL:  Key (id)=(1) already exists.
ERROR:  duplicate key value violates unique constraint "table1_id_key"
   .
   .
   .
DETAIL:  Key (id)=(1) already exists.
ERROR:  duplicate key value violates unique constraint "table1_id_key"

   
  # Connect and check the check table stats and number of rows in the table
psql 
db2=# select relname, n_tup_ins, n_tup_upd, n_tup_del, n_live_tup, n_dead_tup, n_mod_since_analyze, n_ins_since_vacuum, last_vacuum, last_autovacuum, last_analyze, last_autoanalyze, vacuum_count, autovacuum_count, analyze_count, autoanalyze_count from pg_stat_all_tables where relname = 'table1';
 relname | n_tup_ins | n_tup_upd | n_tup_del | n_live_tup | n_dead_tup | n_mod_since_analyze | n_ins_since_vacuum | last_vacuum | last_autovacuum | last_analyze | last_autoanalyze | vacuum_count | autovacuum_count | analyze_count | autoanalyze_coun
t
---------+-----------+-----------+-----------+------------+------------+---------------------+--------------------+-------------+-----------------+--------------+------------------+--------------+------------------+---------------+-----------------
--
 table1  |     10001 |         0 |         0 |          1 |      10000 |                   1 |              10001 |             |                 |              |                  |            0 |                0 |             0 |
0
(1 row)

db2=# SELECT                                                                                                                                                                                                                                                pg_size_pretty(pg_relation_size('table1')) as table_size,
    pg_size_pretty(pg_total_relation_size('table1')) as total_size,
    pg_relation_size('table1') / 8192 as table_blocks,
    pg_total_relation_size('table1') / 8192 as total_blocks;
 table_size | total_size | table_blocks | total_blocks
------------+------------+--------------+--------------
 360 kB     | 400 kB     |           45 |           50
(1 row)

db2=# select * from table1;
 id
----
  1
(1 row)

db2=#
