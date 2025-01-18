---
layout:     post
title:      PostgreSQL安装-服务-配置
subtitle:   安装以及服务配置
date:       2018-03-20
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - PostgreSQL
---

> PostgreSQL安装-服务-配置

### [PostgreSQL安装-服务-配置](https://www.cnblogs.com/qiyebao/p/4562557.html)

[官网地址](https://www.postgresql.org/download/linux/redhat/)

```
# Linux-软件包管理-rpm命令管理-查询
rpm -qa | grep postgres    检查PostgreSQL 是否已经安装
rpm -qal | grep postgres   检查PostgreSQL 安装位置

rpm -e postgresql-XXXXXXX...  卸载

# 使用yum库设置安装postgresql94版本，最好先创建用户组和用户 --> 

# 默认关闭服务开启启动
chkconfig --list | grep postgres
chkconfig postgresql-10 off/on

# 编辑 /etc/profile设置登录提示

echo "#####################################################################"
echo "#                                                                   #"
echo "# 本服务器所有服务需要手工启动，已安装的服务及启动指令如下：             #"
echo "#                                                                   #"
echo "# PostgreSQL数据库服务：    service postgresql-10 start              #"
echo "#                                                                   #"
echo "#                                                                   #"
echo "#                                                                   #"
echo "#                                                                   #"
echo "#                                                                   #"
echo "#                                                                   #"
echo "#####################################################################"
```

#### 修改密码

```
#	su - postgres

bash-4.1$	psql

postgres=#	alter user postgres with password 'new password'
```

#### POSTGRESQL 开放外网IP访问

```
# 编辑pg_hba.conf ->设置访问权限
# 允许所有IP访问
host  all  all  0.0.0.0/0   md5

# 编辑postgresql.conf ->监听所有IP
listen_addresses = '*'	# what IP address(es) to listen on;
```