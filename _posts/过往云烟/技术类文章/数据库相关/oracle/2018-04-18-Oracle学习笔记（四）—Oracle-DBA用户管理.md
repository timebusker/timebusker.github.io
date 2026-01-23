---
layout:     post
title:      Oracle学习笔记（四）—Oracle DBA用户管理
date:       2018-04-18
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Oracle
---

> **Oracle创建用户时，密码必须以字母开头，如果以数字开头，它不会创建用户**  

#### 数据库管理员    
每个oracle数据库应该至少有一个数据库管理员(dba)，对于一个小的数据库，一个dba就够了，但是对于一个大的数据库可能需要多个dba分担不同的管理职责。那么一个数据库管理员的主要工作是什么呢：   
  1.安装和升级oracle 数据库   
  2.建库，表空间，表，视图，索引…   
  3.制定并实施备份和恢复计划   
  4.数据库权限管理，调优，故障排除   
  5.对于高级dba，要求能参与项目开发，会编写sql 语句、存储过程、触发器、规则、约束、包   

##### sys和system用户的区别 
sys所有oracle的数据字典的基表和视图都存放在sys用户中，这些基表和视图对于oracle的运行是至关重要的，由数据库自己维护，任何用户都不能手动更改。sys用户拥有dba，sysdba，sysoper等角色或权限，是oracle权限最高的用户。   

system用户用于存放次一级的内部数据，如oracle的一些特性或工具的管理信息。system用户拥有普通dba角色权限。   
![image](/img/older/oracle/2018041800/1.png)  
system如果正常登录，它其实就是一个普通的dba用户，但是如果以as sysdba登录，其结果实际上它是作为sys用户登录的，这一点类似Linux里面的sudo的感觉，从登录信息里面我们可以看出来。因此在as sysdba连接数据库后，创建的对象实际上都是生成在sys中的。其他用户也是一样，如果 as sysdba登录，也是作为sys用户登录的。  

##### dba和sysdba的区别
- oracle服务的创建过程
  + 创建实例
  + 启动实例
  + 创建数据库(system表空间是必须的)
- oracle服务的启动过程  
  + 实例启动
  + 装载数据库
  + 打开数据库

sysdba，是管理oracle实例的，它的存在不依赖于整个数据库完全启动，只要实例启动了，它就已经存在，以sysdba身份登陆，装载数据库、打开数据库。
dba是Oracle里的一种对象，Role 和User一样，是实实在在存在在Oracle里的物理对象，而sysdba是指的一种概念上的操作对象，在Oracle数据里并不存在。
所以说这两个概念是完全不同的。dba是一种role对应的是对Oracle实例里对象的操作权限的集合，而sysdba是概念上的role是一种登录认证时的身份标识而已。 

##### 用户管理 
- 创建用户   
`create user linkdba identified by 123456 ;`

- 赋予用户的表空间权限  
`alter user linkdba default tablespace linkdba_space;`

- 创建用户并赋予表空间权限  
`create user linkdba identified by 123456 default tablespace linkdba_space;`

- 授予用户管理权限  
`grant connect,resource,dba to linkdba ;`

- 删除用户   
`drop user user_name cascade;`    
cascade参数是级联删除该用户所有对象。  

- 修改用户密码    
在用户已经连接的情况下:    
`password linkdba`    
或者   
`alter user linkdba identified by newpassword`  

- 查看当前用户的角色   
`select * from user_role_privs;`   
`select * from session_privs;`    

- 查看当前用户的系统权限和表级权限    
`select * from user_sys_privs;`   
`select * from user_tab_privs;`    

- 查询用户表  
`select name from dba_users;`  

- 显示当前用户    
`show user;`  

- 账户锁定—（使用profile管理用户口令）  
概述：profile是口令限制，资源限制的命令集合，当建立数据库时，oracle会自动建立名称为default的profile。当建立用户没有指定profile选项时，那么oracle就会将default分配给用户。    
指定该账户(用户)登陆时最多可以输入密码的次数，也可以指定用户锁定的时间(天)一般用dba的身份去执行该命令。  
如：指定scott这个用户最多只能尝试3次登陆，锁定时间为2天，让我们看看怎么实现。      
`create profile lock_account limit failed_login_attempts 3 password_lock_time 2;`     
`alter user scott profile lock_account;`

- 给账户(用户)解锁   
`alter user scott account unlock;` 

- 终止口令—（使用profile管理用户口令） 
为了让用户定期修改密码可以使用终止口令的指令来完成，同样这个命令也需要dba的身份来操作。  
如：要求该用户每隔10天要修改自己的登陆密码，宽限期为2天。  
`create profile myprofile limit password_life_time 10 password_grace_time 2;`   
`alter user test profile myprofile;`  

- 口令历史
如果希望用户在修改密码时，不能使用以前使用过的密码，可使用口令历史，这样oracle就会将口令修改的信息存放到数据字典中，这样当用户修改密码时，oracle就会对新旧密码进行比较，当发现新旧密码一样时，就提示用户重新输入密码。  
建立profile   
`create profile password_history limit password_life_time 10 password_grace_time 2 `  
`alter user test profile password_history;`

- 删除profile 
当不需要某个profile文件时，可以删除该文件。  
`drop profile password_history 【casade】`  


##### 权限管理—权限分为系统权限和对象权限  
- 系统权限  
用户对数据库的相关权限，connect、resource、dba等系统权限，如建库、建表、建索引、建存储过程、登陆数据库、修改密码等。  
- 对象权限 
用户对其他用户的数据对象操作的权限，insert、delete、update、select、all等对象权限，数据对象有很多，比如表，索引，视图，触发器、存储过程、包等。 


#### 参考资料  
- [Oracle用户，权限，角色以及登录管理](https://www.cnblogs.com/zangdalei/p/5483695.html)
- [oracle 用户管理一](http://www.cnblogs.com/linjiqin/archive/2012/01/31/2332616.html)
- [oracle 用户管理二](http://www.cnblogs.com/linjiqin/archive/2012/01/31/2333982.html)

