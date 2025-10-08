# PostgreSQL can have a bloat table (fragmentation) in a insert only table. See below how a rollback can cause this (attention to n_dead_tup column).
```
db1=# create database db2;
CREATE DATABASE
db1=# \c db2;
You are now connected to database "db2" as user "rdsadmin".
db2=# create table table1(id int unique);
CREATE TABLE
db2=# ALTER TABLE table1 SET (                                                                                                                                                                                                                              autovacuum_enabled = false,                                                                                                                                                                                                                             toast.autovacuum_enabled = false
);
ALTER TABLE
db2=# select relname, n_tup_ins, n_tup_upd, n_tup_del, n_live_tup, n_dead_tup, n_mod_since_analyze, n_ins_since_vacuum, last_vacuum, last_autovacuum, last_analyze, last_autoanalyze, vacuum_count, autovacuum_count, analyze_count, autoanalyze_count from pg_stat_all_tables where relname = 'table1';
 relname | n_tup_ins | n_tup_upd | n_tup_del | n_live_tup | n_dead_tup | n_mod_since_analyze | n_ins_since_vacuum | last_vacuum | last_autovacuum | last_analyze | last_autoanalyze | vacuum_count | autovacuum_count | analyze_count | autoanalyze_coun
t
---------+-----------+-----------+-----------+------------+------------+---------------------+--------------------+-------------+-----------------+--------------+------------------+--------------+------------------+---------------+-----------------
--
 table1  |         0 |         0 |         0 |          0 |          0 |                   0 |                  0 |             |                 |              |                  |            0 |                0 |             0 |
0
(1 row)

db2=# insert into table1 (id) values (1);
INSERT 0 1
db2=# select relname, n_tup_ins, n_tup_upd, n_tup_del, n_live_tup, n_dead_tup, n_mod_since_analyze, n_ins_since_vacuum, last_vacuum, last_autovacuum, last_analyze, last_autoanalyze, vacuum_count, autovacuum_count, analyze_count, autoanalyze_count from pg_stat_all_tables where relname = 'table1';
 relname | n_tup_ins | n_tup_upd | n_tup_del | n_live_tup | n_dead_tup | n_mod_since_analyze | n_ins_since_vacuum | last_vacuum | last_autovacuum | last_analyze | last_autoanalyze | vacuum_count | autovacuum_count | analyze_count | autoanalyze_coun
t
---------+-----------+-----------+-----------+------------+------------+---------------------+--------------------+-------------+-----------------+--------------+------------------+--------------+------------------+---------------+-----------------
--
 table1  |         1 |         0 |         0 |          1 |          0 |                   1 |                  1 |             |                 |              |                  |            0 |                0 |             0 |
0
(1 row)

db2=# insert into table1 (id) values (1);
ERROR:  duplicate key value violates unique constraint "table1_id_key"
DETAIL:  Key (id)=(1) already exists.
db2=# select relname, n_tup_ins, n_tup_upd, n_tup_del, n_live_tup, n_dead_tup, n_mod_since_analyze, n_ins_since_vacuum, last_vacuum, last_autovacuum, last_analyze, last_autoanalyze, vacuum_count, autovacuum_count, analyze_count, autoanalyze_count from pg_stat_all_tables where relname = 'table1';
 relname | n_tup_ins | n_tup_upd | n_tup_del | n_live_tup | n_dead_tup | n_mod_since_analyze | n_ins_since_vacuum | last_vacuum | last_autovacuum | last_analyze | last_autoanalyze | vacuum_count | autovacuum_count | analyze_count | autoanalyze_coun
t
---------+-----------+-----------+-----------+------------+------------+---------------------+--------------------+-------------+-----------------+--------------+------------------+--------------+------------------+---------------+-----------------
--
 table1  |         2 |         0 |         0 |          1 |          1 |                   1 |                  2 |             |                 |              |                  |            0 |                0 |             0 |
0
(1 row)



```
