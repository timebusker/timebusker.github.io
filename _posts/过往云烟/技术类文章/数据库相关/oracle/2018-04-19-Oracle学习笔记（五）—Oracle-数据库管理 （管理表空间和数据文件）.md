---
layout:     post
title:      Oracle学习笔记（五）—Oracle-数据库管理 （管理表空间和数据文件）
date:       2018-04-19
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Oracle
---

> Oracle学习笔记（五）—Oracle-数据库管理 （管理表空间和数据文件）

#### 概念 
- Oracle中逻辑结构包括表空间、段、区和块
**数据库的逻辑结构：**数据库由表空间构成，而表空间又是由段构成，而段又是由区构成，而区又是由oracle块构成的，这样可以提高数据库的效率。

- 表空间是数据库的逻辑组成部分
从物理上讲，数据库数据存放在数据文件中；   
从逻辑上讲，数据库数据则是存放在表空间中，表空间由一个或多个数据文件组成。   


#### 表空间   
表空间用于从逻辑上组织数据库的数据。数据库逻辑上是由一个或是多个表空间组成的。通过表空间可以达到以下作用：    
1、控制数据库占用的磁盘空间
2、dba可以将不同数据类型部署到不同的位置，这样有利于提高i/o性能，同时利于备份和恢复等管理操作。

- **建立表空间**     
一般情况下，建立表空间是特权用户或是dba来执行的，如果用其它用户来创建表空间，则用户必须要具有create tablespace的系统权限。同时，在建立数据库后，为便于管理表，最好建立自己的表空间。   
`create tablespace tbs_dba datafile '/data/oracle/oradata/orcl/tbs_dba.dbf' size 20m extent management local autoallocate; -- uniform size 256k`  
**注释：** 创建名为`tbs_dba`的表空间，数据文件为`/data/oracle/oradata/orcl/tbs_dba.dbf`，表空间默认大小20M，使用自动管理的方式扩展表空间，区大小设置为256K。  
`create tablespace tbs_dba datafile '/data/oracle/oradata/orcl/tbs_dba.dbf' size 20m autoextend on next 50m maxsize 500m extent management local autoallocate; -- uniform size 256k`

- **改变表空间的状态**   
当建立表空间时，表空间处于联机的(online)状态，此时该表空间是可以访问的，并且该表空间是可以读写的，即可以查询该表空间的数据，而且还可以在表空间执行各种语句。但是在进行系统维护或是数据维护时，可能需要改变表空间的状态。一般情况下，由特权用户或是dba来操作。   
  + 使表空间脱机`alter tablespace 表空间名 offline; --表空间名不能加单引号`
  + 使表空间联机`alter tablespace 表空间名 online;`
  + 只读表空间 `alter tablespace 表空间名 read only;`,如果不希望在该表空间上执行update，delete，insert操作，那么可以将表空间修改为只读。
  **注意：修改为可写是`alter tablespace 表空间名 read write;`**  

- **删除表空间**   
`drop tablespace ‘表空间’ including contents and datafiles;`    
说明：including contents表示删除表空间时，删除该空间的所有数据库对象，而datafiles表示将数据库文件也删除。   

- **扩展表空间(三种方法)**    
  + 增加数据文件      
  `alter tablespace tbs_dba add datafile '/data/oracle/oradata/orcl/tbs_dba_01.dbf' size 1m;`    
  + 修改数据文件的大小      
  `alter tablespace tbs_dba '/data/oracle/oradata/orcl/tbs_dba.dbf' resize 4m;`
  + 设置文件的自动增长   
  `alter tablespace tbs_dba '/data/oracle/oradata/orcl/tbs_dba.dbf' autoextend on next 10m maxsize 500m;`

- **移动数据文件**   
有时，如果你的数据文件所在的磁盘损坏时，该数据文件将不能再使用，为了能够重新使用，需要将这些文件的副本移动到其它的磁盘，然后恢复。     
  + 确定数据文件所在的表空间   
  `select tablespace_name from dba_data_files where file_name=upper('/data/oracle/oradata/orcl/tbs_dba.dbf');  `
  + 使表空间脱机,确保数据文件的一致性，将表空间转变为offline的状态  
  `alter tablespace tbs_dba offline;`  
  + 使用命令移动数据文件到指定的目标位置   
  `host move /data/oracle/oradata/orcl/tbs_dba.dbf /root/tbs_dba.dbf;`  
  + 执行alter tablespace 命令    
  在物理上移动了数据后，还必须执行alter tablespace命令对数据库文件进行逻辑修改：    
  `alter tablespace tbs_dba rename datafile '/data/oracle/oradata/orcl/tbs_dba.dbf' to '/root/tbs_dba.dbf';`  
  + 使得表空间联机    
  在移动了数据文件后，为了使用户可以访问该表空间，必须将其转变为online状态    
  `alter tablespace tbs_dba online;`  

- **显示表空间信息**   
  + 查询数据字典视图dba_tablespaces，显示表空间的信息：   
    `select tablespace_name from dba_tablespaces;`
  + 显示表空间所包含的数据文件   
    查询数据字典视图dba_data_files,可显示表空间所包含的数据文件，如下：   
   `select file_name, bytes from dba_data_files where tablespace_name='表空间';`


#### 参考资料
- [oracle 数据库管理--管理表空间和数据文件](http://www.cnblogs.com/linjiqin/archive/2012/02/16/2354328.html)

