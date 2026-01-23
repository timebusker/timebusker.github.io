---
layout:     post
title:      Linux学习笔记(十二)-YUM和RPM指令详解
date:       2017-01-13
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Linux
---

> Linux学习笔记(十二)-YUM和RPM指令详解

#### RPM     
rpm命令是RPM软件包的管理工具。rpm原本是Red Hat Linux发行版专门用来管理Linux各项套件的程序，由于它遵循GPL规则且功能强大方便，因而广受欢迎。
逐渐受到其他发行版的采用。RPM套件管理方式的出现，让Linux易于安装，升级，间接提升了Linux的适用度。   
- 选项   
```
-a  ：查询所有套件；
-b  <完成阶段><套件档>+或-t <完成阶段><套件档>+：设置包装套件的完成阶段，并指定套件档的文件名称；
-c  ：只列出组态配置文件，本参数需配合"-l"参数使用；
-d  ：只列出文本文件，本参数需配合"-l"参数使用；
-e  <套件档>或--erase<套件档>：删除指定的套件；
-f  <文件>+：查询拥有指定文件的套件；
-h  或--hash：套件安装时列出标记；
-i  ：显示套件的相关信息；
-i  <套件档>或--install<套件档>：安装指定的套件档；
-l  ：显示套件的文件列表；
-p  <套件档>+：查询指定的RPM套件档；
-q  ：使用询问模式，当遇到任何问题时，rpm指令会先询问用户；
-R  ：显示套件的关联性信息；
-s  ：显示文件状态，本参数需配合"-l"参数使用；
-U  <套件档>或--upgrade<套件档>：升级指定的套件档；
-v  ：显示指令执行过程；
-vv ：详细显示指令执行过程，便于排错。
```   
##### 常用指令    

```
# 安装  
rpm -ivh package.rpm

# 卸载
rpm -e package.rpm  

# 安装查找
rpm -qa | grep sql
```    

- yum命令是在Fedora和RedHat以及SUSE中基于rpm的软件包管理器，它可以使系统管理人员交互和自动化地更细与管理RPM软件包，
  能够从指定的服务器自动下载RPM包并且安装，可以自动处理依赖性关系，并且一次安装所有依赖的软体包，无须繁琐地一次次下载、安装。

- 选项     

```
-h：显示帮助信息；
-y：对所有的提问都回答“yes”；
-c：指定配置文件；
-q：安静模式；
-v：详细模式；
-d：设置调试等级（0-10）；
-e：设置错误等级（0-10）；
-R：设置yum处理一个命令的最大等待时间；
-C：完全从缓存中运行，而不去下载或者更新任何头文件。
```

- 参数     

```
install：安装rpm软件包；
update：更新rpm软件包；
check-update：检查是否有可用的更新rpm软件包；
remove：删除指定的rpm软件包；
list：显示软件包的信息；
search：检查软件包的信息；
info：显示指定的rpm软件包的描述信息和概要信息；
clean：清理yum过期的缓存；
shell：进入yum的shell提示符；
resolvedep：显示rpm软件包的依赖关系；
localinstall：安装本地的rpm软件包；
localupdate：显示本地rpm软件包进行更新；
deplist：显示rpm软件包的所有依赖关系。
``` 
#### 安装    
```
yum install              #全部安装
yum install package1     #安装指定的安装包package1
yum groupinsall group1   #安装程序组group1
``` 
#### 更新和升级     
    
```
yum update               #全部更新
yum update package1      #更新指定程序包package1
yum check-update         #检查可更新的程序
yum upgrade package1     #升级指定程序包package1
yum groupupdate group1   #升级程序组group1
``` 
#### 查找和显示    

```
yum info package1      #显示安装包信息package1
yum list               #显示所有已经安装和可以安装的程序包
yum list package1      #显示指定程序包安装情况package1
yum groupinfo group1   #显示程序组group1信息yum search string 根据关键字string查找安装包
``` 
#### 删除程序     

```
yum remove package1   #删除程序包package1
yum groupremove group1             #删除程序组group1
yum deplist package1               #查看程序package1依赖情况
``` 
#### 清除缓存     

```
yum clean packages       #清除缓存目录下的软件包
yum clean headers        #清除缓存目录下的 headers
yum clean oldheaders     #清除缓存目录下旧的 headers
``` 

