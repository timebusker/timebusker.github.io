---
layout:     post
title:      Hive-Hive使用Spark on Yarn作为执行引擎
date:       2017-12-17
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Hive
---

Hive从1.1之后，支持使用Spark作为执行引擎，配置使用Spark On Yarn作为Hive的执行引擎，首先需要注意以下两个问题：

- Hive的版本和Spark的版本要匹配
具体来说，你使用的Hive版本编译时候用的哪个版本的Spark，那么就需要使用相同版本的Spark，可以在Hive的pom.xml中查看spark.version来确定；
`Hive root pom.xml’s <spark.version> defines what version of Spark it was built/tested with.`

- Spark使用的jar包，必须是没有集成Hive的；
也就是说，编译时候没有指定`-Phive`.一般官方提供的编译好的Spark下载，都是集成了Hive的，因此这个需要另外编译。
`Note that you must have a version of Spark which does not include the Hive jars. Meaning one which was not built with the Hive profile.`

#### 配置
首先设置`SPARK_HOME`环境变量，再编辑配置`hive-site.xml`

```
<property>
    <name>spark.home</name>
    <value>/usr/local/spark/spark-1.5.0-bin-hadoop2.3</value>
</property>
<property>
    <name>spark.master</name>
	<!-- 此处使用YARN，也可直接配置spark master statalone模式 -->
    <value>yarn-cluster</value>
</property>
<property>
    <name>hive.execution.engine</name>
    <value>spark</value>
</property>
<property>
    <name>spark.eventLog.enabled</name>
    <value>true</value>
</property>
<property>
    <name>spark.eventLog.dir</name>
    <value>hdfs://root/tmp/spark/eventlog</value>
</property>
<property>
    <name>spark.executor.memory</name>
    <value>5G</value>
</property>
<property>
    <name>spark.executor.instances</name>
    <value>50</value>
</property>
<property>
    <name>spark.driver.memory</name>
    <value>10G</value>
</property>
<property>
    <name>spark.serializer</name>
    <value>org.apache.spark.serializer.KryoSerializer</value>
</property>
```

配置完毕，启动hive服务

- 总结
在进入hive-cli命令行，第一次执行查询之后，Hive向Yarn申请Container资源，即参数`spark.executor.instances`指定的数量，
另外加一个Driver使用的Container。该Application便会一直运行，直到退出hive-cli，该Application便会成功结束，期间占用的集群资源不会自动释放和回收。
如果在hive-cli中修改和executor相关的参数，再次执行查询时候，Hive会结束上一次在Yarn上运行的Application，重新申请资源提交运行。
