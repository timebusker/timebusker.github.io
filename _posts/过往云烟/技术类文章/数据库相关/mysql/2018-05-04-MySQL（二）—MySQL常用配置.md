---
layout:     post
title:      MySQL学习笔记（二）—MySQL常用配置
subtitle:   MySQL常用配置
date:       2018-06-24
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - MySQL
---

> MySQL学习笔记（二）—MySQL常用配置

#### MySQL本机免密登陆   
**注：密码配置到文件以后是有安全隐患的，请根据自己的实际需求来配置。**    
```
# 编辑配置文件后保存即可实现
# vim /root/.my.cnf
[client]
host=localhost
user=root
password=timebusker
```  
![image](/img/older/mysql/1/3.png)    

#### 修改Linux下MySQL编码  
##### 查看mysql字符集 
默认登录mysql之后可以通过SHOW VARIABLES语句查看系统变量及其值。    
- 查看服务端编码`show variables like '%character%';` 
![image](/img/older/mysql/1/4.png)    
- 查看数据库编码，登陆切换到目标库，`show variables like 'character';`

- 查看表字段编码`show full columns from tb_test;`

##### 修改某一个数据库、表、字段的编码    

```
alter database test default character set utf8;   
alter table `emp` default character set utf8;   
alter table `emp` change `ename` `ename` varchar(128) character set utf8;   
```   

##### 修改mysql服务端的编码   
`find / -iname '*.cnf' -print`   

```  
# vim /etc/my.cnf


# For advice on how to change settings please see
# http://dev.mysql.com/doc/refman/5.7/en/server-configuration-defaults.html

[mysqld]
character-set-server=utf8
collation-server=utf8_general_ci

datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock

# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid

[database]
character_set_database=utf8
```  

##### 查看mysql字符集 