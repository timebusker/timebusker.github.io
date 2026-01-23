---
layout:     post
title:      Spark Streaming整合Kafka两种连接方式
date:       2019-03-13
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Spark-Streaming
---

#### Receiver模式

Receiver模式又称kafka高级api模式

[整合Kafka两种连接方式](img/older/spark-sreaming/1.png)

[整合Kafka两种连接方式](img/older/spark-sreaming/2.png)

如图，SparkStreaming中的Receivers直接订阅kafka中的消息，并把接收到的数据存储在Executor，这会存在一些问题：

- worker突然宕机，会导致存储在`Executor`的数据一起丢失

- worker消费能力不够，会导致未消费的数据持续丢失。假定5秒消费一次数据处理，但spark实际处理时间超过5秒，一次会导致数据持续丢失

缓解该问题的改进版本是 `AWL(write ahead logs) Receiver模式`：

在程序里对`streamingContext`初始化后，得到她的对象进行`checkpoint("hdfs://xxxx/xx")`即可，这样程序会默认把日志偏移量存到`hdfs备份`，防止数据丢失，但是这样会影响性能。


####  Direct模式

Direct模式又称kafka低级API模式，采用kafka直连的方式消费数据。

[整合Kafka两种连接方式](img/older/spark-sreaming/3.png)

直连方式就是使用executor直接连接kakfa节点。

- 直连方式从Kafka集群中读取数据，并且在Spark Streaming系统里面维护偏移量相关的信息，实现零数据丢失，保证不重复消费，比createStream更高效；

- 创建的DStream的rdd的partition做到了和Kafka中topic的partition一一对应

直接通过低阶API从kafka的topic消费消息，并且不再向zookeeper中更新consumer offsets，使得基于zookeeper的consumer offsets的监控工具都会失效。所以更新zookeeper中的consumer offsets还需要自己去实现，
并且官方提供的两个createDirectStream重载并不能很好的满足我的需求，需要进一步封装。

在采用直连的方式消费kafka中的数据的时候，大体思路是首先获取保存在zookeeper中的偏移量信息，根据偏移量信息去创建stream，消费数据后再把当前的偏移量写入zk中。


#### 两种方式对比

- 降低资源。Direct模式不需要Receivers，其申请的Executors全部参与到计算任务中；而Receiver模式则需要专门的Receivers来读取Kafka数据且不参与计算。因此相同的资源申请，Direct模式能够支持更大的业务。

- 降低内存。Receiver模式的Receiver与其他Exectuor是异步的，并持续不断接收数据，对于小业务量的场景还好，如果遇到大业务量时，需要提高Receiver的内存，但是参与计算的Executor并无需那么多的内存。而Direct模式因为没有Receivers，而是在计算时读取数据，然后直接计算，所以对内存的要求很低。实际应用中我们可以把原先的10G降至现在的2-4G左右。

- 鲁棒性更好。Receiver模式方法需要Receivers来异步持续不断的读取数据，因此遇到网络、存储负载等因素，导致实时任务出现堆积，但Receivers却还在持续读取数据，此种情况很容易导致计算崩溃。Direct模式则没有这种顾虑，其Driver在触发batch计算任务时，才会读取数据并计算。队列出现堆积并不会引起程序的失败。

- 提高成本。Direct需要用户采用checkpoint或者第三方存储来维护offsets，而不像Receiver-based那样，通过ZooKeeper来维护Offsets，此提高了用户的开发成本。

- 监控可视化。Receiver-based方式指定topic指定consumer的消费情况均能通过ZooKeeper来监控，而Direct则没有这种便利，如果做到监控并可视化，则需要投入人力开发。


