---
layout:     post
title:      Oracle学习笔记（一）—Oracle-概述
subtitle:   Oracle概述
date:       2018-04-04
author:     timebusker
header-img: img/home-bg.jpg
header-img: img/taylorswift/post-bg-swift.jpg
catalog: true
tags:
    - Oracle
---

> Oracle学习笔记（一）— Oracle概述  

Oracle数据库是Oracle公司开发和销售的一种对象关系数据库管理系统。 Oracle数据库通常被称为Oracle RDBMS或简称为Oracle。

#### 数据库和实例
Oracle数据库服务器由一个数据库和至少一个数据库实例组成。 数据库是一组存储数据的文件，而数据库实例是一组管理数据库文件的内存结构。 另外，数据库由后台进程组成。  
一个数据库和一个实例是紧密相连的，因此术语 - Oracle数据库 通常用来指代实例和数据库。  
下图说明了Oracle数据库服务器体系结构：
![image](https://raw.githubusercontent.com/timebusker/timebusker.github.io/master/img/oracle/20180404/1.png?raw=true)   
**在这种体系结构中，Oracle数据库服务器包括两个主要部分：文件(Oracle数据库)和内存(Oracle实例)。**  

##### Oracle数据库  
Oracle数据库的一个基本任务是存储数据。以下部分简要地介绍Oracle数据库的物理和逻辑存储结构。
- 物理存储结构
物理存储结构是存储数据的纯文件。当执行一个CREATE DATABASE语句来创建一个新的数据库时，将创建下列文件：  
  + **数据文件：**数据文件包含真实数据，例如销售订单和客户。逻辑数据库结构(如表和索引)的数据被物理存储在数据文件中。
  + **控制文件：**每个Oracle数据库都有一个包含元数据的控制文件。元数据描述数据库的物理结构，包括数据库名称和数据文件的位置。
  + **联机重做日志文件：**每个Oracle数据库都有一个联机重做日志，其中包含两个或多个联机重做日志文件。联机重做日志由重做条目组成，记录对数据所做的所有更改。  
  + 除这些文件外，Oracle数据库还包括其他重要文件，如参数文件，网络文件，备份文件以及用于备份和恢复的归档重做日志文件。
  
- 逻辑存储结构  
Oracle数据库使用逻辑存储结构对磁盘空间使用情况进行精细控制。以下是Oracle数据库中的逻辑存储结构：  
  + **数据块(Data blocks)：**数据块对应于磁盘上的字节数。Oracle将数据存储在数据块中。数据块也被称为逻辑块，Oracle块或页。
  + **范围(Extents)：**范围是用于存储特定类型信息的逻辑连续数据块的具体数量。
  + **段(Segments)：**段是分配用于存储用户对象(例如表或索引)的一组范围。
  + **表空间(Tablespaces)：**数据库被分成称为表空间的逻辑存储单元。 表空间是段的逻辑容器。 每个表空间至少包含一个数据文件。

###### 下图说明了表空间中的段，范围和数据块：   
![image](https://raw.githubusercontent.com/timebusker/timebusker.github.io/master/img/oracle/20180404/2.png?raw=true)  
###### 下图显示了逻辑和物理存储结构之间的关系：
![image](https://raw.githubusercontent.com/timebusker/timebusker.github.io/master/img/oracle/20180404/3.png?raw=true) 

##### Oracle实例 
Oracle实例是客户端应用程序(用户)和数据库之间的接口。Oracle实例由三个主要部分组成：系统全局区(SGA)，程序全局区(PGA)和后台进程。如下图所示: 
![image](https://raw.githubusercontent.com/timebusker/timebusker.github.io/master/img/oracle/20180404/4.png?raw=true)   
SGA是实例启动时分配的共享内存结构，关闭时释放。 SGA是一组包含一个数据库实例的数据和控制信息的共享内存结构。  
不同于所有进程都可用的SGA，PGA是会话开始时为每个会话分配的私有内存区，当会话结束时释放。  

- 主要的Oracle数据库的后台进程
  + **PMON：**是调节所有其他进程的进程监视器。PMON清理异常连接的数据库连接，并自动向侦听器进程注册数据库实例。PMON是Oracle数据库中最活跃的一个进程。  
  + **SMON：**是执行系统级清理操作的系统监视进程。它有两个主要职责，包括在发生故障的情况下自动恢复实例，例如断电和清理临时文件。
  + **DBWN：**是数据库编写器。Oracle在内存中执行每个操作而不是磁盘。因为在内存中的处理速度比在磁盘上快。DBWn进程从磁盘读取数据并将其写回到磁盘。 一个Oracle实例有许多数据库编写器，如:`DBW0，DBW1，DBW2`等等。
  + **CKPT：**是检查点过程。 在Oracle中，磁盘上的数据称为块，内存中的数据称为缓冲区。 当该块写入缓冲区并更改时，缓冲区变脏，需要将其写入磁盘。CKPT进程使用检查点信息更新控制和数据文件头，并向脏盘写入脏缓冲区的信号。 
  请注意，Oracle 12c允许全面和增量检查点。 
  ![image](https://raw.githubusercontent.com/timebusker/timebusker.github.io/master/img/oracle/20180404/5.png?raw=true)   
  + **LGWR：**是日志写入过程，是可恢复架构的关键。 在数据库中发生的每一个变化都被写出到一个名为redo日志文件中用于恢复目的。 而这些变化是由LGWR进程编写和记录的。 LGWR进程首先将更改写入内存，然后将磁盘写入重做日志，然后将其用于恢复。  
  + **ARCn：**是归档进程，它将重做日志的内容复制到归档重做日志文件。存档程序进程可以有多个进程，如：ARC0，ARC1和ARC3，允许存档程序写入多个目标，如D：驱动器，E：驱动器或其他存储。
  + **MMON：**是收集性能指标的可管理性监控流程。
  + **MMAN：**是自动管理Oracle数据库内存的内存管理器。
  + **LREG：**是监听器注册过程，它使用Oracle Net Listener 在数据库实例和调度程序进程上注册信息。