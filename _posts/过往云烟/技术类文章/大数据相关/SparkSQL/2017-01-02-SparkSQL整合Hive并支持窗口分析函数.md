---
layout:     post
title:      SparkSQL整合Hive并支持窗口分析函数
date:       2018-07-18
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - SparkSQL
---

> [SparkSQL常用内置配置项](https://www.cnblogs.com/pekkle/p/10525757.html)

#### 关于SparkSQL的元数据
SparkSQL 的元数据的状态有两种：
- in_memory(存放在内存中)，用完了元数据也就丢了，此类主要针对`接口编程`，保存结果信息时没有保存元数据信息。
  
- 借助hive存储元数据，也就是说，`SparkSQL的数据仓库在建立在Hive之上实现的`。我们要用SparkSQL去构建数据仓库的时候，必须依赖于Hive。



Spark1.4发布，除了重量级的SparkR，其中的SparkSQL支持了我期待已久的窗口分析函数(window functions)。

> 前提：已经安装配置好Hadoop和Hive，可用

#### SparkSQL与Hive的整合
- 拷贝`$HIVE_HOME/conf/hive-site.xml`和`hive-log4j.properties`到`$SPARK_HOME/conf/`

- 在`$SPARK_HOME/conf/`目录中，修改`spark-env.sh`，添加:

```
export HIVE_HOME=/usr/local/apache-hive-0.13.1-bin 
# 有问题，会跑mysql驱动包找不到，最好直接拷贝到$SPARK_HOME/jars目录下
export SPARK_CLASSPATH=$HIVE_HOME/lib/mysql-connector-java-5.1.15-bin.jar:$SPARK_CLASSPATH
```

- 设置一下Spark的log4j配置文件，使得屏幕中不打印额外的INFO信息:

```
log4j.rootCategory=WARN, console
```

- 配置完后，重启Spark集群

- 验证

```
cd $SPARK_HOME/bin

./spark-sql –-master yarn-client --queue QueueA --name SparkSQL

# 执行SQL
show databases;
```

#### Spark Thrift Server
ThriftServer是一个JDBC/ODBC接口，用户可以通过JDBC/ODBC连接ThriftServer来访问SparkSQL的数据。
ThriftServer在启动的时候，会启动了一个sparkSQL的应用程序，而通过JDBC/ODBC连接进来的客户端共同分享这个sparkSQL应用程序的资源，
也就是说不同的用户之间可以共享数据；ThriftServer启动时还开启一个侦听器，等待JDBC客户端的连接和提交查询。
所以，在配置ThriftServer的时候，至少要配置ThriftServer的主机名和端口，如果要使用hive数据的话，还要提供hive metastore的uris。

- Spark Application运行过程
大体分为三部分：（1）SparkConf创建；（2）SparkContext创建；（3）任务执行。

构建Spark Application的运行环境。创建SparkContext后，SparkContext向资源管理器注册并申请资源。
这里说的资源管理器有Standalone、Messos、YARN等。事实上，Spark和资源管理器关系不大，主要是能够获取Executor进程，
并能保持相互通信。在SparkContext初始化过程中，Spark分别创建作业调度模块DAGScheduler和任务调度模块TaskScheduler
(此例为Standalone模式下，在YARN-Client模式下任务调度模块为YarnClientClusterScheduler,在YARN-Cluster模式下
为YarnClusterScheduler)。

- 区别
ThriftServer是一个不同的用户之间可以共享数据，`常服务`

Spark Application是每次启动都要申请资源，`是例行的`

- 启用Spark Thrift Server

```
cd $SPARK_HOME/sbin/
./start-thriftserver.sh \
--master yarn-client \
--conf spark.driver.memory=3G 
```

> 测试使用

```
cd $SPARK_HOME/bin
./beeline -u jdbc:hive2://12.12.12.11:10000
```

