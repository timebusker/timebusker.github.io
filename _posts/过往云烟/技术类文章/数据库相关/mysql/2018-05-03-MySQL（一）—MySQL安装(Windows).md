---
layout: post
title: MySQL学习笔记（一）—MySQL-5.7安装(Windows)
author: timebusker
catalog: true
tags:
  - MySQL
---

#### 下载解压安装包


#### 修改基础配置文件

```
# 在MySQL_HOME环境新增配置文件：default.ini
[mysql]
# 设置mysql客户端默认字符集
default-character-set=utf8 

# 设置3306端口
port = 3306 

# 设置mysql的安装目录
basedir=C:\Program Files\mysql-5.7.23-winx64\

# 设置mysql数据库的数据的存放目录
datadir=C:\Program Files\mysql-5.7.23-winx64\data

# 允许最大连接数
max_connections=200

# 服务端使用的字符集默认为8比特编码的latin1字符集
character-set-server=utf8

# 创建新表时将使用的默认存储引擎
default-storage-engine=INNODB
```


#### 服务启动配置

```
# 进入到mysql的bin目录
# 安装服务
mysqld install
# 初始化系统服务(跳过会出现：请键入 NET HELPMSG 3534 以获得更多的帮助。异常)
# 输出自动生成的密码
mysqld --initialize --user=mysql --console  
# 2019-01-16T14:53:52.020512Z 1 [Note] A temporary password is generated for root@localhost: <%u#PNEX2sG!

# 启动服务
net start mysql

# 设置密码服务
set password = password('timebusker');
```

#### 更新mysql服务密码的方式

```
# 5.7版本
# 用SET PASSWORD命令 
set password = password('timebusker');
set password for root@localhost = password('timebusker'); 

# 用UPDATE直接编辑user表 
use mysql; 
update user set password=password('timebusker') where user='root' and host='localhost'; 
flush privileges; 


# 8.0版本通用
alter user 'root'@'localhost' identified with mysql_native_password by 'timebusker';  
```



#### 问题处理
##### 找不到msvcp140.dll
