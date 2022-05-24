---
layout:     post
title:      Oracle学习笔记（八）—Oracle-逻辑备份与恢复
subtitle:   逻辑备份与恢复
date:       2018-04-24
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Oracle
---

> Oracle 数据库(表)的逻辑备份与恢复  

> **exp和imp指令可在Oracle客户端的bin目录下执行。PL/SQL也是调用这两个命令实现操作。**

> **scheme:方案**

#### 介绍  
- **逻辑备份：**是指使用工具export将数据对象的结构和数据导出到文件的过程。
- **逻辑恢复：**是指当数据库对象被误操作而损坏后使用工具import利用备份的文件把数据对象导入到数据库的过程。
- **物理备份：**即可在数据库open的状态下进行也可在关闭数据库后进行，但是逻辑备份和恢复只能在open的状态下进行。

#### 备份(导出)
导出分为导出表、导出方案、导出数据库三种方式。导出使用[**EXP(sqlplus)**](#)命令来完成的，该命令常用的选项有:
- **userid：**用于指定执行导出操作的用户名，口令，连接字符串
- **tables：**用于指定执行导出操作的表
- **owner：**用于指定执行导出操作的方案
- **full=y：**用于指定执行导出操作的数据库
- **inctype：**用于指定执行导出操作的增量类型
- **rows：**用于指定执行导出操作是否要导出表中的数据
- **file：**用于指定导出文件名

##### 用例
- 导出指定用户表   
`exp userid=scott/oracle@orcl tables=(emp) file=d:\emp.dmp --导出单个表`   
`exp userid=scott/oracle@orcl tables=(emp,dept) file=d:\emp.dmp --导出多个表`   

