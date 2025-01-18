---
layout:     post
title:      MySQL（四）—MySQL常用操作
date:       2019-09-14
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - MySQL
---

> MySQL（四）—MySQL常用操作

#### 数据备份

- 使用`mysqldump`命令备份

mysqldump命令将数据库中的数据备份成一个文本文件。表的结构和表中的数据将存储在生成的文本文件中。

mysqldump命令的工作原理很简单。它先查出需要备份的表的结构，再在文本文件中生成一个CREATE语句。然后，将表中的所有记录转换成一条INSERT语句。然后通过这些语句，就能够创建表并插入数据。

> 使用语法

```
# 语法示例
mysqldump -u username -p database table1 table2 ...-> backups.sql
```

> database参数表示数据库的名称；

> table1和table2参数表示需要备份的表的名称，为空则整个数据库备份；

> backups.sql参数表设计备份文件的名称，文件名前面可以加上一个绝对路径。通常将数据库被分成一个后缀名为sql的文件；


```
# 使用root用户备份test数据库下的person表
mysqldump -u root -p test person > D:\backup.sql

# 备份多个数据库
mysqldump -u username -p --databases dbname2 dbname2 > backup.sql

# 备份所有数据库
mysqldump -u username -p -all-databases > backup.sql
```

- 直接复制整个数据库目录

MySQL有一种非常简单的备份方法，就是将MySQL中的数据库文件直接复制出来。这是最简单，速度最快的方法。

不过在此之前，要先将服务器停止，这样才可以保证在复制期间数据库的数据不会发生变化。如果在复制数据库的过程中还有数据写入，就会造成数据不一致。这种情况在开发环境可以，但是在生产环境中很难允许备份服务器。

`注意：这种方法不适用于InnoDB存储引擎的表，而对于MyISAM存储引擎的表很方便。同时，还原时MySQL的版本最好相同。`


- 使用`mysqlhotcopy`工具快速备份

mysqlhotcopy支持不停止MySQL服务器备份。而且，mysqlhotcopy的备份方式比mysqldump快。mysqlhotcopy是一个perl脚本，主要在Linux系统下使用。其使用LOCK TABLES、FLUSH TABLES和cp来进行快速备份。

mysqlhotcopy并非mysql自带，需要安装Perl的数据库接口包；下载地址为:`http://dev.mysql.com/downloads/dbi.html`目前，该工具也仅仅能够备份MyISAM类型的表。

`原理：先将需要备份的数据库加上一个读锁，然后用FLUSH TABLES将内存中的数据写回到硬盘上的数据库，最后，把需要备份的数据库文件复制到目标目录。`


#### 备份恢复

- 还原使用`mysqldump`命令备份的数据库的语法如下:

```
mysql -u root -p [dbname] < backup.sq
```

如出现字符异常，需要增加编码设置：

```
mysql -u root -h 127.0.0.1 -P 33067 --default-character-set=utf8 mujitokyo_dev<mujitokyo_dev.sql
```

- 还原直接复制目录的备份

通过这种方式还原时，必须保证两个MySQL数据库的版本号是相同的。MyISAM类型的表有效，对于InnoDB类型的表不可用，InnoDB表的表空间不能直接复制。
