---
layout:     post
title:      MySQL学习笔记（一）—MySQL-5.7安装(Linux)
subtitle:   MySQL-5.7安装
date:       2018-05-04
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - MySQL
---

#### 卸载系统自带MySQL安装  

```
# 检查是否安装
yum list installed | grep mysql 
rpm -qa|grep -i mysql
rpm -qa | grep mariadb  

# 卸载安装 
yum remove mysql-libs.x86_64
```

#### 查看MySQL官方安装文档
学习过程需要养成看官方文档的习惯，尝试阅读。[**官方安装文档**](https://dev.mysql.com/doc/mysql-yum-repo-quick-guide/en/#repo-qg-yum-install-components)。    
可参照官方文档实现快速在线安装：在本地新增mysql-repo快速安装（A Quick Guide to Using the MySQL Yum Repository）。   
[https://dev.mysql.com/doc/mysql-yum-repo-quick-guide/en/](https://dev.mysql.com/doc/mysql-yum-repo-quick-guide/en/)

#### 离线安装  
- 下载离线安装包   
额外需要使用的依赖包还有：`libaio.x86_64`、`openssl.x86_64`,需要检查是否已经安装。    
![image](/img/older/mysql/1/1.png)   
![image](/img/older/mysql/1/2.png)  

```
# 顺序安装一下依赖包    
rpm -ivh mysql-community-common-5.7.22-1.el6.x86_64.rpm   
rpm -ivh mysql-community-libs-5.7.22-1.el6.x86_64.rpm   
rpm -ivh mysql-community-client-5.7.22-1.el6.x86_64.rpm   
rpm -ivh mysql-community-server-5.7.22-1.el6.x86_64.rpm

# 初始化mysql    
mysqld --initialize 
chown mysql:mysql /var/lib/mysql -R
service mysqld restart
service mysqld start
service mysqld stop

# 添加系统启动服务，设置卡机启动    
chkconfig --add /etc/init.d/mysqld
chkconfig mysqld on 

# 查看mysql初始化密码  
grep 'temporary password' /var/log/mysqld.log   
grep 'temporary password' /var/log/mysql/mysqld.log  

# 设置默认密码  
# 本地登录
mysql -uroot -p
use mysql  
ALTER USER 'root'@'localhost' IDENTIFIED BY 'timebusker';

------------------------------------------------------------------------
/usr/bin/mysqladmin -u root password 'timebusker'
------------------------------------------------------------------------

# [远程连接授权](https://blog.csdn.net/attilax/article/details/8595696)    
update user set host='%' where user='root'  

######################################################################
# 以上操作完成后需要刷新配置（登录状态）
flush privileges;
######################################################################
```  
#### RMP离线安装默认目录

```
# 数据库目录
/var/lib/mysql/

# 配置文件(mysql.server命令及配置文件)
find / -iname '*.cnf' -print
/etc/my.cnf
/usr/share/mysql/

# 相关命令(mysqladmin mysqldump等命令)
/usr/bin/

# 启动脚本(启动脚本文件mysql的目录)
/etc/rc.d/init.d/
``` 


#### 异常处理   
- 问题一: **error: 'Can't connect to local MySQL server through socket '/var/lib/mysql/mysql.sock' (2)'**    
  + 先查看 /etc/rc.d/init.d/mysqld status 看看mysql服务是否已经启动.
  + 确定你的mysql.sock是否是`var/lib/mysql/mysql.sock`  
  + 确认执行权限，修改文件权限：`chown -R mysql:mysql /var/lib/mysql`    

- [问题二：](https://blog.csdn.net/fghsfeyhdf/article/details/78799270) **ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: NO)**        
  + 关闭mysql服务:`service mysqld stop ` 
  + `sudo mysqld_safe --user=mysql --skip-grant-tables --skip-networking &`  
  + 登录MySQL客户端`sudo mysql -uroot -pmysql `
  + 进入mysql数据库设置密码不过期：`use mysql`、`update user set password_expired = "N" where user="root"; `  
  + 设置新密码：`update user set authentication_string=password('timebusker') where user='root';` 
  + 刷新配置，退出登录：`flush privileges;`、`\q or quit `      

- 问题三:初始化数据时异常, ** --initialize specified but the data directory has files in it. Aborting.**   
  + 保证`--datadir`目录为空，默认目录是：`/var/lib/mysql/`将其清空。

- [问题四:安装时操作失误导启动失败，致执行`service mysqld status`异常：**mysqld dead but subsys locked**](https://blog.csdn.net/mochong/article/details/67636467)    

- 问题五:最小化系统安装Mysql提示缺包。异常如下：   

```  
error: Failed dependencies:
	libaio.so.1()(64bit) is needed by mysql-community-server-5.7.22-1.el6.x86_64
	libaio.so.1(LIBAIO_0.1)(64bit) is needed by mysql-community-server-5.7.22-1.el6.x86_64
	libaio.so.1(LIBAIO_0.4)(64bit) is needed by mysql-community-server-5.7.22-1.el6.x86_64
	libnuma.so.1()(64bit) is needed by mysql-community-server-5.7.22-1.el6.x86_64
	libnuma.so.1(libnuma_1.1)(64bit) is needed by mysql-community-server-5.7.22-1.el6.x86_64
	libnuma.so.1(libnuma_1.2)(64bit) is needed by mysql-community-server-5.7.22-1.el6.x86_64
```   

需要补全安装的依赖包如下：     
  
```
yum install numactl -y   
yum install libaio -y  
```    

- [问题六:客户端执行SQL会抛异常](https://blog.csdn.net/fansili/article/details/78664267)     

```
[Err] 1055 - Expression #1 of ORDER BY clause is not in GROUP BY clause and 
contains nonaggregated column 'information_schema.PROFILING.SEQ' 
which is not functionally dependent on columns in GROUP BY clause; 
this is incompatible with sql_mode=only_full_group_by   
```  

原因:MySQL 5.7.5和up实现了对功能依赖的检测。如果启用了only_full_group_by SQL模式(在默认情况下是这样)，   
那么MySQL就会拒绝选择列表、条件或顺序列表引用的查询，这些查询将引用组中未命名的非聚合列，而不是在功能上依赖于它们。   
(在5.7.5之前，MySQL没有检测到功能依赖项，only_full_group_by在默认情况下是不启用的。关于前5.7.5行为的描述，请参阅MySQL 5.6参考手册。)         
   
```     

# find / -name my.cnf
# For advice on how to change settings please see
# http://dev.mysql.com/doc/refman/5.7/en/server-configuration-defaults.html

[client]
default-character-set=utf8mb4

[mysqld]
sql_mode='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION'
character-set-server=utf8
collation-server=utf8_general_ci
#
# Remove leading # and set to the amount of RAM for the most important data
# cache in MySQL. Start at 70% of total RAM for dedicated server, else 10%.
# innodb_buffer_pool_size = 128M
#
# Remove leading # to turn on a very important data integrity option: logging
# changes to the binary log between backups.
# log_bin
#
# Remove leading # to set options mainly useful for reporting servers.
# The server defaults are faster for transactions and fast SELECTs.
# Adjust sizes as needed, experiment to find the optimal values.
# join_buffer_size = 128M
# sort_buffer_size = 2M
# read_rnd_buffer_size = 2M
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock

# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0

log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid

[database]
character_set_database=utf8   

```    

#### 参考资料
- [MySQL在线安装](https://www.cnblogs.com/silentdoer/articles/7258232.html)
- [MySQL修改密码以及忘记密码解决](https://blog.csdn.net/Oscer2016/article/details/76450711)
- [解决mysql远程连接配置与错误修复](https://www.jianshu.com/p/192688974302)
- [MySQL设置允许用户远程登录](https://blog.csdn.net/gebitan505/article/details/51726667)