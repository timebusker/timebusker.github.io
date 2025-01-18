---
layout:     post
title:      Linux学习笔记(一)-CentOS系统安装
date:       2017-01-01
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Linux
---

> Linux学习笔记(一)-CentOS系统安装

#### 下载镜像地址
```
http://mirrors.163.com/centos/7/isos/x86_64/

http://mirrors.aliyun.com/centos/7/isos/x86_64/
```

#### 服务器版安装教程(超级详细图解)
- [安装教程(超级详细图解)](http://blog.csdn.net/junzixing1985/article/details/78700382) 
- [安装教程(推荐)](http://www.jb51.net/os/85895.html) 

#### 关机命令
- [关机命令详解](https://www.cnblogs.com/wanggd/archive/2013/07/08/3177398.html)
- `shutdown -r now `立刻重启(root用户使用) 
- `shutdown -r 10 `过10分钟自动重启(root用户使用)
- `shutdown -h now `立刻关机(root用户使用)
- `shutdown -h 10 `10分钟后自动关机 
- 如果是通过shutdown命令设置关机/重启，可以用shutdown -c命令取消重启
