---
layout:     post
title:      Linux（CentOS）让进程在后台可靠运行的几种方法
date:       2018-06-06 
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Linux
---

> Linux（CentOS）让进程在后台可靠运行的几种方法

### blog
[Linux 技巧：让进程在后台可靠运行的几种方法](https://www.ibm.com/developerworks/cn/linux/l-cn-nohup/)  

### 常用命令组合
```
# 标准输出到文件myout.file，并把标准错误输出重定向到标准输出中，写入文件
nohup command > myout.file 2>&1 &  

# 标准输出到 空设备（/dev/null：不会实质记录任何内容），并把标准错误输出重定向到标准输出中
nohup /usr/saohei/redis-3.0.4/bin/redis-server redis.conf 1>/dev/null 2>&1 &

# 操作系统常用的三种流操作：
# 0  标准输入
# 1  标准输出流
# 2  标准错误流
# 一般，我们在使用">、>>、< "等未指明时，默认使用0和1

# 上述指令解释：将command添加到后天运行，并把标准错误流输出到标准输出中，
# 避免标准输出和标准错误同时输出到文件myout.file产生文件读写竞争。
```

### 常用任务管理命令
> jobs      //查看任务，返回任务编号n和进程号（`只能查看当前终端上操作的任务`）     
> bg  %n    //将编号为n的任务转后台运行（n"为jobs命令查看到的job编号）      
> fg  %n    //将编号为n的任务转前台运行（n"为jobs命令查看到的job编号）      
> ctrl+z    //挂起当前任务      
> ctrl+c    //结束当前任务     

### 前台进程转后台

```
# 如运行命令
# ping 127.0.0.1

# 使用ctrl + z挂起进程
# 使用jobs -l 查看任务编号n
# 使用bg %n将任务转至后台运行
```

### 后台任务转前台

```
# 使用jobs -l 查看任务编号n

# 使用bg %n将任务转至后台运行
```