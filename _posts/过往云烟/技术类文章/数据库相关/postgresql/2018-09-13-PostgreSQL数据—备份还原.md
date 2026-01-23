---
layout:     post
title:      PostgreSQL数据—备份还原
date:       2018-09-13
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - PostgreSQL
---

> https://blog.51cto.com/liyuanjie/category6.html

#### Postgresql的三种备份方式
- 文件系统级别的冷备份
这种备份方式需要关闭数据库，然后拷贝数据文件的完整目录。恢复数据库时，只需将数据目录复制到原来的位置。该方式实际工作中很少使用。

- SQL转储
常用到的工具：用到的工具是pg_dump和pg_dumpall

这种方式可以在数据库正在使用的时候进行完整一致的备份，并不阻塞其它用户对数据库的访问。它会产生一个脚本文件，里面包含备份开始时，已创建的各种数据库对象的SQL语句和每个表中的数据。
可以使用数据库提供的工具`pg_dumpall`和`pg_dump`来进行备份。`pg_dump`只备份数据库集群中的某个数据库的数据，它不会导出角色和表空间相关的信息，因为这些信息是整个数据库集群共用的，
不属于某个单独的数据库。`pg_dumpall`，对集簇中的每个数据库调用`pg_dump`来完成该工作,还会还转储对所有数据库公用的全局对象（`pg_dump`不保存这些对象）。
目前这包括适数据库用户和组、表空间以及适合所有数据库的访问权限等属性。

```
# 使用如下命令对名为dbname的数据库进行备份
pg_dump –h 127.0.0.1 -p 5432 -U postgres -c –f dbname.sql dbname

# 使用如下命令可对全部pg数据库进行备份
pg_dumpall –h 127.0.0.1 –p 5432 -U postgres –c –f db_bak.sql

# 恢复方式很简单(登录系统，指定加载文件即可)
psql –h 127.0.0.1 -p 5432 -U postgres –f db_bak.sql

```

- 连续归档
这种方式的策略是把一个文件系统级别的全量备份和WAL(预写式日志)级别的增量备份结合起来。当需要恢复时，我们先恢复文件系统级别的备份，
然后重放备份的WAL文件，把系统恢复到之前的某个状态。这种备份有显著的优点：

- 不需要一个完美的一致的文件系统备份作为开始点。备份中的任何内部不一致性将通过日志重放来修正。
- 可以结合一个无穷长的WAL文件序列用于重放，可以通过简单地归档WAL文件来达到连续备份。
- 不需要重放WAL项一直到最后。可以在任何点停止重放，并使数据库恢复到当时的一致状态。
- 可以连续地将一系列WAL文件输送给另一台已经载入了相同基础备份文件的机器，得到一个实时的热备份系统。

> 如何进行连续归档呢？

```
首先，需要修改postgresql.conf文件的几个参数修改如下：
# 
wal_level = ‘replica’
# 开启归档
archive_mode = ‘on’
# script脚本
archive_command = 'copy  /y  "%p"  "/opt/databack/%f"'
# archive_command执行时，%p会被要被归档的文件路径所替代，而%f只会被文件名所替代。如果你需要在命令中嵌入一个真正的%字符，可以使用%%。
#  “D:\\archive\\”替换为归档日志的存放路径，要确保归档的目录是存在的。

需要重启数据库使配置生效。
```

# PostgreSQL 自动备份,并删除10天前的备份文件的windows脚本.

```
@ECHO OFF
@setlocal enableextensions
@cd /d "%~dp0"
 
SET PGPATH=D:\db\postgresql\bin\
SET SVPATH=E:\DatabaseBackup\
SET PRJDB=dbname
SET DBUSR=postgres
FOR /F "TOKENS=1,2,3 DELIMS=/ " %%i IN ('DATE /T') DO SET d=%%i-%%j-%%k
 
SET DBDUMP=%PRJDB%_%d%.bak
@ECHO OFF
%PGPATH%pg_dump -h localhost -U postgres %PRJDB% > %SVPATH%%DBDUMP%

echo Backup Taken Complete %SVPATH%%DBDUMP%

forfiles /p %SVPATH% /d -5 /c "cmd /c echo deleting @file ... && del /f @path" 
```

https://www.cnblogs.com/wycc/p/6911910.html

https://blog.csdn.net/international24/article/details/82689136

https://blog.51cto.com/liyuanjie/category6.html
