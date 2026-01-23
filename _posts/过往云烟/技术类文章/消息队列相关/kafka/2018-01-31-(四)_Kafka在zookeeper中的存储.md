---
layout:     post
title:      Kafka在zookeeper中的存储
date:       2019-06-14
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Kafka
---  

### Kafka在zookeeper中存储结构图

![image](img/older/MQ-middle/kafka17.png)   

![image](img/older/MQ-middle/kafka23.png)   

##### admin

该目录下znode只有在有相关操作时才会存在，操作结束时会将其删除

/admin/reassign_partitions用于将一些Partition分配到不同的broker集合上。对于每个待重新分配的Partition，Kafka会在该znode上存储其所有的Replica和相应的Broker id。该znode由管理进程创建并且一旦重新分配成功它将会被自动移除。

##### broker
即/brokers/ids/[brokerId]）存储“活着”的broker信息。

topic注册信息（/brokers/topics/[topic]），存储该topic的所有partition的所有replication所在的broker id，第一个replica即为preferred replication，
对一个给定的partition，它在同一个broker上最多只有一个replication,因此broker id可作为replication id。

##### controller

/controller -> int (broker id of the controller)存储当前controller的信息

/controller_epoch -> int (epoch)直接以整数形式存储controller epoch，而非像其它znode一样以JSON字符串形式存储。

### 分析

##### topic注册信息

`/brokers/topics/[topic]` : 存储某个topic的partitions所有分配信息

![image](img/older/MQ-middle/kafka18.png)   

```
# topic节点数据内容
{
    "version": "版本编号目前固定为数字1",
    "partitions": {
        "partitionId编号": [
            同步副本组brokerId列表
        ],
        "partitionId编号": [
            同步副本组brokerId列表
        ],
        .......
    }
}
```

##### partition状态信息

/brokers/topics/[topic]/partitions/[0...N]  其中[0..N]表示partition索引号

/brokers/topics/[topic]/partitions/[partitionId]/state

![image](img/older/MQ-middle/kafka19.png)   

```
{
    "controller_epoch": 表示kafka集群中的中央控制器选举次数,
    "leader": 表示该partition选举leader的brokerId,
    "version": 版本编号默认为1,
    "leader_epoch": 该partition leader选举次数,
    "isr": [同步副本组brokerId列表]
}
```

##### Broker注册信息

/brokers/ids/[0...N]                 

![image](img/older/MQ-middle/kafka20.png)  

```
{
    "jmx_port": jmx端口号,
    "timestamp": kafka broker初始启动时的时间戳,
    "host": 主机名或ip地址,
    "version": 版本编号默认为1,
    "port": kafka broker的服务端端口号,由server.properties中参数port确定
}
```

##### Controller epoch

/controller_epoch -->  int (epoch)   

此值为一个数字,kafka集群中第一个broker第一次启动时为1，以后只要集群中center controller中央控制器所在broker变更或挂掉，就会重新选举新的center controller，每次center controller变更controller_epoch值就会 + 1; 

![image](img/older/MQ-middle/kafka21.png) 

##### Controller注册信息

/controller -> int (broker id of the controller)  存储center controller中央控制器所在kafka broker的信息

![image](img/older/MQ-middle/kafka22.png) 

```
{
    "version": 版本编号默认为1,
    "brokerid": kafka集群中broker唯一编号,
    "timestamp": kafka broker中央控制器变更时的时间戳
}
```

### 消费者与消费者组

- 每个consumer客户端被创建时,会向zookeeper注册自己的信息

- 此作用主要是为了"负载均衡"

- 同一个Consumer Group中的Consumers，Kafka将相应Topic中的每个消息只会被其中一个Consumer消费

- Consumer Group中的每个Consumer读取Topic的一个或多个Partitions，并且是唯一的Consumer

- 一个Consumer group的多个consumer的所有线程依次有序地消费一个topic的所有partitions,如果Consumer group中所有consumer总线程大于partitions数量，则会出现空闲情况

##### Consumer均衡算法

当一个group中,有consumer加入或者离开时,会触发partitions均衡.均衡的最终目的,是提升topic的并发消费能力。

- 假如topic1,具有如下partitions: P0,P1,P2,P3

- 加入group中,有如下consumer: C0,C1

- 首先根据partition索引号对partitions排序: P0,P1,P2,P3

- 根据(consumer.id + '-'+ thread序号)排序: C0,C1

- 计算倍数: M = [P0,P1,P2,P3].size / [C0,C1].size,本例值M=2(向上取整)

- 然后依次分配partitions: C0 = [P0,P1],C1=[P2,P3],即Ci = [P(i * M),P((i + 1) * M -1)]

##### Consumer注册信息

每个consumer都有一个唯一的ID(consumerId可以通过配置文件指定,也可以由系统生成),此id用来标记消费者信息.

/consumers/[groupId]/ids/[consumerIdString]，是一个临时的znode,此节点的值为请看consumerIdString产生规则,即表示此consumer目前所消费的topic + partitions列表.

consumerId产生规则：

```
StringconsumerUuid = null;
if(config.consumerId!=null && config.consumerId)
  consumerUuid = consumerId;
else {
  String uuid = UUID.randomUUID()
  consumerUuid = "%s-%d-%s".format(
    InetAddress.getLocalHost.getHostName, System.currentTimeMillis,
    uuid.getMostSignificantBits().toHexString.substring(0,8));

}
String consumerIdString = config.groupId + "_" + consumerUuid;
```

##### Consumer owner

/consumers/[groupId]/owners/[topic]/[partitionId] -> consumerIdString + threadId索引编号

a) 首先进行"Consumer Id注册";

b) 然后在"Consumer id 注册"节点下注册一个watch用来监听当前group中其他consumer的"退出"和"加入";只要此znode path下节点列表变更,都会触发此group下consumer的负载均衡.(比如一个consumer失效,那么其他consumer接管partitions).

c) 在"Broker id 注册"节点下,注册一个watch用来监听broker的存活情况;如果broker列表变更,将会触发所有的groups下的consumer重新balance.


##### Consumer offset

/consumers/[groupId]/offsets/[topic]/[partitionId] -> long (offset)

用来跟踪每个consumer目前所消费的partition中最大的offset

此znode为持久节点,可以看出offset跟group_id有关,以表明当消费者组(consumer group)中一个消费者失效,

重新触发balance,其他consumer可以继续消费.



















