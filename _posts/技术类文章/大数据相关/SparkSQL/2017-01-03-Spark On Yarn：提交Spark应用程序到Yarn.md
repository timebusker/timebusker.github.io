---
layout:     post
title:      Spark On Yarn：提交Spark应用程序到Yarn
date:       2018-07-19
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Spark
    - SparkSQL
---

> [SparkSQL常用内置配置项](https://www.cnblogs.com/pekkle/p/10525757.html)

Spark On Yarn模式配置非常简单，只需要下载编译好的Spark安装包，在一台带有Hadoop Yarn客户端的机器上解压，简单配置之后即可使用。

要把Spark应用程序提交到Yarn运行，首先需要配置HADOOP_CONF_DIR或者YARN_CONF_DIR，让Spark知道Yarn的配置信息，比如：ResourceManager的地址。
可以配置在spark-env.sh中，也可以在提交Spark应用之前export：

```
export HADOOP_HOME=/root/hadoop-2.8.1
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop/conf
```

- yarn-cluster模式提交Spark应用程序

```
./spark-submit \
--class org.apache.spark.examples.SparkPi \
--master yarn-cluster \
--executor-memory 4G \
--num-executors 10 \
examples/jars/spark-examples_2.11-2.4.0.jar \
1000
```

- yarn-client模式提交Spark应用程序

```
./spark-submit \
--class org.apache.spark.examples.SparkPi \
--master yarn-client \
--executor-memory 4G \
--num-executors 10 \
examples/jars/spark-examples_2.11-2.4.0.jar \
1000
```

在提交Spark应用程序到Yarn时候，可以使用`—files`指定应用程序所需要的文件；使用`—jars`和`–archives`添加应用程序所依赖的第三方jar包等。

- Yarn Cluster模式和Yarn Client模式的主要区别

yarn-cluster模式中，应用程序(包括SparkContext)都是作为Yarn框架所需要的ApplicationMaster,在Yarn ResourceManager为其分配的一个随机节点上运行；
而在yarn-client模式中，SparkContext运行在本地，该模式适用于应用程序本身需要在本地进行交互的场合。

- Spark On Yarn相关的配置参数

|:---------:|:-----------:|:-------------:|
|:**配置项**:|:**默认值**:|:描述:|
|**spark.yarn.am.memory**|`512M`|在yarn-client模式下，申请Yarn App Master所用的内存|
|**spark.driver.memory**|`512M`|在yarn-cluster模式下，申请Yarn App Master（包括Driver）所用的内存|
|**spark.yarn.am.cores**|`1`|在yarn-client模式下，申请Yarn App Master所用的CPU核数|
|**spark.yarn.am.waitTime**|`100s`|在yarn-cluster模式下，Yarn App Master等待SparkContext初始化完成的时间；<br>在yarn-client模式下，Yarn App Master等待SparkContext链接它的时间；|
|**spark.yarn.submit.file.replication**|`HDFS副本数:(3)`|Spark应用程序的依赖文件上传到HDFS时，在HDFS中的副本数，这些文件包括Spark的Jar包、应用程序的Jar包、其他作为DistributeCache使用的文件等。通常，如果你的集群节点数越多，相应地就需要设置越多的拷贝数以加快这些文件的分发。|
|**spark.yarn.preserve.staging.files**|`false`|在应用程序结束后是否保留上述上传的文件|
|**spark.yarn.scheduler.heartbeat.interval-ms**|`5000`|Spark Application Master向Yarn ResourceManager发送心跳的时间间隔，单位毫秒。|
|**spark.yarn.max.executor.failures**|`numExecutors * 2 (最小为3)`|最多允许失败的Executor数量。重复运行多少次后仍然失败便挂起|
|**spark.yarn.historyServer.address**|`none`|Spark运行历史Server的地址，主机:host，如：12.12.12.14:18080，注意不能包含`http://`<br>默认不配置，必须开启Spark的historyServer之后才能配置。该地址用于Yarn ResourceManager在Spark应用程序结束时候，将该application的运行URL从ResourceManager的UI指向Spark historyServer UI。|
|**spark.executor.instances**|`2`|Executor实例的数量，不能与spark.dynamicAllocation.enabled同时使用|
|**spark.yarn.queue**|`default`|指定提交到Yarn的资源池|
|**spark.yarn.jar**|`--`|Spark应用程序使用的Jar包位置，比如：hdfs://root/apps/|

- Spark Standalone模式下提交Spark应用程序

```
./spark-submit \
--class org.apache.spark.examples.SparkPi \
--master spark://12.12.12.3:7077,12.12.12.4:7077 \
--executor-memory 4G \
--num-executors 10 \
examples/jars/spark-examples_2.11-2.4.0.jar \
1000
```

