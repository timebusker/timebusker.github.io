---
layout:     post
title:      Spark动态资源分配-Dynamic Resource Allocation
date:       2018-07-19
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Spark
    - SparkSQL
---

> [SparkSQL常用内置配置项](https://www.cnblogs.com/pekkle/p/10525757.html)

Spark中，所谓资源单位一般指的是executors，和Yarn中的Containers一样，在Spark On Yarn模式下，通常使用–num-executors来指定Application使用的executors数量，
而–executor-memory和–executor-cores分别用来指定每个executor所使用的内存和虚拟CPU核数。相信很多朋友至今在提交Spark应用程序时候都使用该方式来指定资源。

假设有这样的场景，如果使用Hive，多个用户同时使用hive-cli做数据开发和分析，只有当用户提交执行了Hive SQL时候，才会向YARN申请资源，执行任务，如果不提交执行，
无非就是停留在Hive-cli命令行，也就是个JVM而已，并不会浪费YARN的资源。现在想用Spark-SQL代替Hive来做数据开发和分析，也是多用户同时使用，如果按照之前的方式，
以yarn-client模式运行spark-sql命令行（[spark应用提交运行](http://www.timebusker.top/2018/07/19/Spark-On-Yarn-%E6%8F%90%E4%BA%A4Spark%E5%BA%94%E7%94%A8%E7%A8%8B%E5%BA%8F%E5%88%B0Yarn/)），
在启动时候指定`-–num-executors 10、--executor-memory 4G`，那么每个用户启动时候都使用了10个YARN的资源（Container），
这10个资源就会一直被占用着，`只有当用户退出spark-sql命令行时才会释放`。

`Spark-sql On Yarn`，能不能像Hive一样，执行SQL的时候才去申请资源，不执行的时候就释放掉资源呢？
其实从Spark1.2之后，对于On Yarn模式，已经`支持动态资源分配（Dynamic Resource Allocation）`，
可以根据Application的负载（Task情况），动态的增加和减少executors，这种策略非常适合在YARN上使用spark-sql做数据开发和分析，
以及将spark-sql作为长服务来使用的场景。

#### YARN的配置
首先需要对YARN的NodeManager进行配置，使其支持Spark的Shuffle Service。

- 修改yarn-site.xml

```
<property>
    <!-- 支持Spark的Shuffle Service -->
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle,spark_shuffle</value>
</property>

<!-- 增加spark_shuffle配置 -->
<property>
    <!-- 拷贝“${SPARK_HOME}/yarn/spark-2.4.0-yarn-shuffle.jar”到“${HADOOP_HOME}/share/hadoop/yarn/lib/”目录下 -->
    <name>yarn.nodemanager.aux-services.spark_shuffle.class</name>
    <value>org.apache.spark.network.yarn.YarnShuffleService</value>
</property>
<property>
    <name>spark.shuffle.service.port</name>
    <value>7337</value>
</property>
```

- 重启所有NodeManager

#### Spark的配置
- 修改spark-defaults.conf
配置`$SPARK_HOME/conf/spark-defaults.conf`，增加以下参数：

```
spark.shuffle.service.enabled true       //启用External shuffle Service服务
spark.shuffle.service.port 7337          //Shuffle Service服务端口，必须和yarn-site中的一致
spark.dynamicAllocation.enabled true     //开启动态资源分配
spark.dynamicAllocation.minExecutors 1   //每个Application最小分配的executor数
spark.dynamicAllocation.maxExecutors 30  //每个Application最大并发分配的executor数
spark.dynamicAllocation.schedulerBacklogTimeout 1s 
spark.dynamicAllocation.sustainedSchedulerBacklogTimeout 5s
```

- 命令行

```
spark-submit \
--master yarn \
--deploy-mode cluster \
--executor-cores 3 \
--executor-memory 10G \
--driver-memory 4G \
--conf spark.dynamicAllocation.enabled=true \
--conf spark.shuffle.service.enabled=true \
--conf spark.dynamicAllocation.initialExecutors=5 \
--conf spark.dynamicAllocation.maxExecutors=40 \
--conf spark.dynamicAllocation.minExecutors=0 \
--conf spark.dynamicAllocation.executorIdleTimeout=30s \
--conf spark.dynamicAllocation.schedulerBacklogTimeout=10s 
```

- 动态资源分配策略
开启动态分配策略后，application会在task因没有足够资源被挂起的时候去动态申请资源，
这种情况意味着该application现有的executor无法满足所有task并行运行。
`Spark一轮一轮的申请资源`，当有task挂起或等待`spark.dynamicAllocation.schedulerBacklogTimeout(默认1s)时间的时候`，会开始动态资源分配；
之后会每隔`spark.dynamicAllocation.sustainedSchedulerBacklogTimeout(默认1s)时间申请一次`，
直到申请到足够的资源。每次申请的资源量是`指数增长`的，即1,2,4,8等。

之所以采用指数增长，出于两方面考虑：其一，开始申请的少是考虑到可能application会马上得到满足；
其次要成倍增加，是为了防止application需要很多资源，而该方式可以在很少次数的申请之后得到满足。

- 资源回收策略
当application的executor空闲时间超过`spark.dynamicAllocation.executorIdleTimeout（默认60s）后`，就会被回收。

##### 使用Spark-sql On Yarn执行SQL，动态分配资源

```
./spark-sql 
--master yarn-client \
--executor-memory 1G \
--name SparkSQL
-e "select count(*) from tb_sougou_search"
```

> 需要注意：

- 如果使用`./spark-sql –master yarn-client –executor-memory 1G`进入spark-sql命令行，
  在命令行中执行任何SQL查询，都不会执行，原因是spark-sql在提交到Yarn时候，已经被当成一个Application，
  而这种，除了Driver，是不会被分配到任何executors资源的，所有，你提交的查询因为没有executor而不能被执行。
  而这个问题，我使用Spark的ThriftServer（HiveServer2）得以解决。
  
- 针对实时程序如果也要动态分配资源的话，有些默认值需要根据实际情况调整一下，比如spark.dynamicAllocation.initialExecutors设置成2，
  如果每个executor一个vcore的话，至少启动两个executor，一个core给receive用，一个core用来执行计算任务。

- 实时程序首个batch可能会有一些初始化的动作在里面，比如初始化了数据库连接池，初始化redis连接池等，可能处理时间会较长，
  如果按spark.dynamicAllocation.schedulerBacklogTimeout默认的1秒阈值的话，那么就会开始申请增加executors了，
  这样不是很合理，可以根据实际初始化时长适当将该参数调大一点，比如调成10秒。

- 当指定了`–num-executors`，即明确指定了executor的个数，即使你设置了`spark.dynamicAllocation.enable=true`,动态资源分配也将无效。
  并在`driver`stderr的warn日志中看到如下警告：`WARN spark.SparkContext: Dynamic Allocation and num executors both set, thus dynamic allocation disabled.`

##### 使用Thrift JDBC方式执行SQL，动态分配资源
首选以yarn-client模式，启动Spark的ThriftServer服务，也就是HiveServer2。

- 配置ThriftServer监听的端口号和地址

```
vim $SPARK_HOME/conf/spark-env.sh
export HIVE_SERVER2_THRIFT_PORT=10000
export HIVE_SERVER2_THRIFT_BIND_HOST=0.0.0.0
```

- 以yarn-client模式启动ThriftServer

```
cd $SPARK_HOME/sbin/
./start-thriftserver.sh \
--master yarn-client \
--queue QueueA \
--conf spark.driver.memory=3G \
--conf spark.shuffle.service.enabled=true \
--conf spark.dynamicAllocation.enabled=true \
--conf spark.dynamicAllocation.minExecutors=1 \
--conf spark.dynamicAllocation.maxExecutors=30 \
--conf spark.dynamicAllocation.sustainedSchedulerBacklogTimeout=5s
```

- 启动后，ThriftServer会在Yarn上作为一个长服务来运行：

- 使用beeline通过JDBC连接spark-sql

```
# 此处注意：hive的beeline和spark的beeline不兼容，配置环境变量可能混淆
cd $SPARK_HOME/bin
./beeline -u jdbc:hive2://12.12.12.11:10000
```

多个用户可以通过beeline，JDBC连接到Thrift Server，执行SQL查询，而资源也是动态分配的。

需要注意的是，在启动ThriftServer时候指定的`spark.dynamicAllocation.maxExecutors=30`，是整个`ThriftServer同时并发的最大资源数`，
如果多个用户同时连接，则会被多个用户共享竞争，`总共30个`。