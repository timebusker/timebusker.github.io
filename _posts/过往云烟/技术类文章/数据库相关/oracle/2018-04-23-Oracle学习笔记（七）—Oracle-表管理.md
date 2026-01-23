---
layout:     post
title:      Oracle学习笔记（七）—Oracle-表管理
date:       2018-04-23
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Oracle
---

> **cascade ：级联删除**
> **truncate ：与delete不同，是DDL命令，删除的数据不能恢复**

#### 表名和列名的命名规则  
- 必须以字母开头  
- 长度不能超过30个字符   
- 不能使用oracle的保留字  
- 只能使用如下字符 a-z，a-z，0-9，$,#等  

#### 数据类型

##### 字符类
- char:长度固定，最多容纳2000个字符。
- char(10):指定字符长度，空位补空格符。
- varchar2(20)：长度可变，最多容纳4000个字符。  
- clob(character large object):字符型大对象，最多容纳4G。  

[【注：】char 查询的速度极快浪费空间，适合查询比较频繁的数据字段。varchar 节省空间](#)

##### 数字型 
- number范围-10的38次方到10的38次方，可以表示整数，也可以表示小数
- number(5,2)表示一位小数有5位有效数，2位小数；范围：-999.99 到999.99
- number(5)表示一个5位整数；范围99999到-99999

##### 日期类型
- date 包含年月日和时分秒 oracle默认格式23-04月-2018 
- timestamp 时间戳，这是oracle9i对date数据类型的扩展，可以精确到毫秒。  

##### 图片 
blob 二进制数据，可以存放图片/声音4g；一般来讲，在真实项目中是不会把图片和声音真的往数据库里存放，一般存放图片、视频的路径，如果安全需要比较高的话，则放入数据库。

##### 创建表
```
--学生表
create table student (
   xh number(4), --学号
   xm varchar2(20), --姓名
   sex char(2), --性别
   birthday date, --出生日期
   sal number(7,2) --奖学金
);
```

##### 修改表  
- 添加字段      
  `alter table student add (classid number(2),....);`

- 修改字段长度     
  `alter table student modify (xm varchar2(30));`

- 修改字段数据类型（**不能有数据**）     
  `alter table student modify (xm char(30));`

- 删除字段(**不建议做，删了之后，字段顺序就变了。加就没问题，是加在后面**)     
  `alter table student drop column sal;`

- 修改表名     
  `alter table student rename to sudt`     
  `rename student to sudt`   

##### 创建保存点  
```
delete from student; --删除所有记录，表结构还在，写日志，可以恢复的，速度慢。
--delete的数据可以恢复。
savepoint a; --创建保存点
delete from student;
rollback to a; --恢复到保存点
一个有经验的dba，在确保完成无误的情况下要定期创建还原点。

drop table student; --删除表的结构和数据；
delete from student where xh = 'a001'; --删除一条记录；
truncate table student; --删除表中的所有记录，表结构还在，不写日志，无法找回删除的记录，速度快。
```



