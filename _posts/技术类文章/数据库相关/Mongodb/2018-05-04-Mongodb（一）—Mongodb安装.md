---
layout:     post
title:      Mongodb学习笔记（一）—Mongodb安装
subtitle:   
date:       2018-08-04
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - MongoDB
---

> Mongodb学习笔记（一）—Mongodb安装

#### 下载社区版本
(下载链接https://www.mongodb.com/download-center?jmp=nav#community)[https://www.mongodb.com/download-center?jmp=nav#community]  

#### 安装MongoDB   

```
# 指定安装目录并解压
tar  –zxvf mongodb-linux-x86_64-2.4.9.tgz

# 指定日志目录数据存储目录
mkdir datas
mkdir logs

# /root/mongodb/datas
# /root/mongodb/logs
```

#### 设置配置文件   

```
# mongod进程存储数据目录，此配置仅对mongod进程有效。默认值为：/data/db  
dbpath=/root/mongodb/datas
# 日志目录
logpath=/root/mongodb/logs/mongodb.log
# mongod侦听端口，默认值为27017
port=27017
# 后台方式运行mongodb
fork=true 
# 关闭http接口
nohttpinterface=true
#允许所有的连接
bind_ip=0.0.0.0    
```  

#### Shell启动服务

```
# 启动服务脚本
/root/mongodb/mongodb-linux-x86_64/bin/mongod –f /root/mongodb/mongodb-linux-x86_64/bin/mongodb.conf

# 关闭服务
/root/mongodb/mongodb-linux-x86_64/bin/mongod -f /root/mongodb/mongodb-linux-x86_64/bin/mongodb.conf --shutdown

# 设置开机启动服务
# vim /etc/rc.d/rc.local
/root/mongodb/mongodb-linux-x86_64/bin/mongod -f /root/mongodb/mongodb-linux-x86_64/bin/mongodb.conf

# 测试连接   
/root/mongodb/mongodb-linux-x86_64/bin/mongo 

# 配置环境变量
# vim /root/.bashrc
/root/mongodb/mongodb-linux-x86_64/bin/

#查看数据列表
show dbs
#查看当前db版本
db.version()
```
