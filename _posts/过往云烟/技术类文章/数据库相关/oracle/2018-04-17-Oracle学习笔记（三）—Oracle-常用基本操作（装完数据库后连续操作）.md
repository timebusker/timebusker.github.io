---
layout:     post
title:      Oracle学习笔记（三）— Oracle-常用基本操作（装完数据库后连续操作）
date:       2018-04-17
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Oracle
---

> **Oracle数据库使用监听器来接收客户端的连接请求，要使客户端能连接Oracle数据库，必须配置监听程序。在安装Oracle数据库时，如果选择的是“创建和配置数据库”，则安装过程中会自动配置监听程序， 无需再按照此文配置。如果选择的是”仅安装数据库软件”，则需按此文手工配置监听程序，数据库才能被客户端访问。**

#### 数据库 
- 创建数据库 
  + 在数据库服务器以`oracle`用户执行`dbca`命令启动建库图形窗口。

#### 配置监听器
- 在数据库服务器以`oracle`用户执行`netca`命令启动动配置程序图形窗口（windows:也可通过“开始菜单\Oracle - OraDb11g_home1\Net Configuration Assistant”）。

- 一般配置完成后监听服务会自动重启，如果没能重启的化，可手工重启。  

```
# 关闭监听配置
lsnrctl stop  

# 启动监听配置
lsnrctl start  

# 查看监听状态
lsnrctl status
```

#### 启动/关闭数据库服务
- **sqlplus / as sysdba** 登录执行：  
  重启Oracle服务器时，需要手动启动Oracle数据库服务。  
  
```
# 启动数据库服务
startup

# 关闭数据库服务
shutdown immediate  

# 也可以直接运行
#启动数据库的脚本
dbstart

#停止数据库的脚本
dbshut

```  

#### 连接Oracle服务
- **sqlplus / as sysdba** 
  **在Oracle服务器上以oracle用户下登录。**     
  操作系统认证，不需要数据库服务器启动listener，也不需要数据库服务器处于可用状态。比如我们想要启动数据库就可以用这种方式进入。sqlplus，然后通过startup命令来启动。

- **sqlplus username/password**    
  **在Oracle服务器上以oracle用户下登录。**  
  连接本机数据库，不需要数据库服务器的listener进程，但是由于需要用户名密码的认证，因此需要数据库服务器处于可用状态才行。
  
- **sqlplus usernaem/password@orcl**   
  **PL/SQL Oracle客户端远程连接**   
  通过网络连接，这是需要数据库服务器的listener处于监听状态。此时建立一个连接的大致步骤如下：    
  + 查询sqlnet.ora，看看名称的解析方式，默认是TNSNAME
  + 查询tnsnames.ora文件，从里边找orcl的记录，并且找到数据库服务器的主机名或者IP，端口和service_name
  + 如果服务器listener进程没有问题的话，建立与listener进程的连接
  + 根据不同的服务器模式如专用服务器模式或者共享服务器模式，listener采取接下去的动作。默认是专用服务器模式，没有问题的话客户端就连接上了数据库的server process
  + 此时连接已经建立，可以操作数据库了

- **sqlplus username/password@//host:port/sid**    
  **用sqlplus远程连接oracle命令**     
  `sqlplus softt/softt@//192.168.130.99:1521/orcl`  

- **sqlplus /nolog** 
进入sqlplus环境，nolog参数表示不登录。

```
sqlplus /nolog
conn sys/sys@localhost:1521/orcl as sysdba
``` 
