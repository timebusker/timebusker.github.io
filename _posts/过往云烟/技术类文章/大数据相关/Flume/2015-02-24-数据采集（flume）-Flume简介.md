---
layout:     post
title:      数据采集（flume）-Flume简介
date:       2018-03-01
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Flume
---  

#### 概述
Apache Flume 是一个分布式，可靠且可用的系统，用于有效地从许多不同的源收集、聚合和移动大量日志数据到一个集中式的数据存储区。

Flume 的使用不只限于日志数据。因为数据源可以定制，flume 可以被用来传输大量事件数据，这些数据不仅仅包括网络通讯数据、社交媒体产生的数据、电子邮件信息等等。

Apache Flume 是 Apache 基金会的顶级项目，在加入 Apache 之前由 cloudera 公司开发以及维护。

Apache Flume 目前有两种主版本： `0.9.x`和 `1.x`。 其中`0.9.x`是历史版本，我们称之为`Flume OG（original generation）`。2011年10月22号，cloudera完成了Flume-728，对Flume进行了里程碑式的改动：
重构核心组件、核心配置以及代码架构，重构后的版本统称为`Flume NG（next generation）`，也就是这里说的 1.x 版本。

> Flume NG的主要变化：

- `sources`和`sinks`使用`channels`进行链接
- 两个主要`channel`。`in-memory channel`:非持久性支持，速度快；`JDBC-based channel`:持久性支持
- 不再区分逻辑和物理node，所有物理节点统称为 `agents`,每个`agents`都能运行0个或多个`sources`和`sinks`
- 不再需要`master`节点和对`zookeeper`的依赖，配置文件简单化。
- 插件化，一部分面对用户，工具或系统开发人员。
- 使用`Thrift服务`，Avro Flume sources可以从flume0.9.4 发送 events  到flume 1.x

![数据采集（flume）](img/older/flume/1.png)

> 特点

- Flume可以高效率的将多个网站服务器中收集的日志信息存入HDFS/HBase中
- 使用Flume，我们可以将从多个服务器中获取的数据迅速的移交给Hadoop中
- 除了日志信息，Flume同时也可以用来接入收集规模宏大的社交网络节点事件数据，比如facebook,twitter,电商网站如亚马逊，flipkart等
- 支持各种接入资源数据的类型以及接出数据类型
- 支持多路径流量，多管道接入流量，多管道接出流量，上下文路由等
- 可以被水平扩展

### 架构

![数据采集（flume）](img/older/flume/9.png)

#### 数据流模型
`一个Flume事件`被定义为一个`数据流单元`。Flume agent其实是一个JVM进程，该进程中包含完成任务所需要的各个组件，其中最核心的三个组件是`Source`、`Chanel`以及`Slink`。

![数据采集（flume）](img/older/flume/2.png)

##### Source 
消费由外部源（如Web服务器）传递给它的事件。外部源以一定的格式发送数据给Flume，这个格式的定义`由目标Flume Source来确定`。
例如，一个 Avro Flume source 可以从 Avro（Avro是一个基于二进制数据传输的高性能中间件，是 hadoop 的一个子项目） 客户端接收 Avro 事件，
也可以从其他 Flume agents （该 Flume agents 有 Avro sink）接收 Avro 事件。 
同样，我们可以定义一个`Thrift Flume Source`接收来自`Thrift Sink`、`Flume Thrift RPC`客户端或者其他任意客户端（该客户端可以使用任何语言编写，只要满足 Flume thrift 协议）的事件。

##### channel 
  - 通道：采用被动存储的形式，即通道会缓存该事件直到该事件被sink组件处理
  - 所以Channel是一种短暂的存储容器，它将从source处接收到的event格式的数据缓存起来,直到它们被sinks消费掉,它在source和sink间起着一共桥梁的作用,channel是一个完整的事务,这一点保证了数据在收发的时候的一致性. 并且它可以和任意数量的source和sink链接
  - 可以通过参数设置event的最大个数
  - Flume通常选择FileChannel，而不使用Memory Channel
  – Memory Channel：内存存储事务，吞吐率极高，但存在丢数据风险
  – File Channel：本地磁盘的事务实现模式，保证数据不会丢失（WAL实现）

##### slink 
Sink会将事件从Channel中移除，并将事件放置到外部数据介质上
   – 例如：通过Flume HDFS Sink将数据放置到HDFS中，或者放置到下一个Flume的Source，等到下一个Flume处理。
   – 对于缓存在通道中的事件，Source和Sink采用异步处理的方式
- Sink成功取出Event后，将Event从Channel中移除
- Sink必须作用于一个确切的Channel
- 不同类型的Sink：
   – 存储Event到最终目的的终端：HDFS、Hbase
   – 自动消耗：Null Sink
   – 用于Agent之间通信：Avro

![数据采集（flume）](img/older/flume/3.png)
- 数据发生器（如：facebook,twitter）产生的数据被被单个的运行在数据发生器所在服务器上的agent所收集，之后数据收容器从各个agent上汇集数据并将采集到的数据存入到HDFS或者HBase中
##### 事件(Flume Event)
- Flume使用Event对象来作为传递数据的格式，是内部数据传输的最基本单元
- 由两部分组成：转载数据的字节数组+可选头部
![数据采集（flume）](img/older/flume/4.png)
- Header 是 key/value 形式的，可以用来制造路由决策或携带其他结构化信息(如事件的时间戳timestamp或事件来源的服务器主机名host)。你可以把它想象成和HTTP 头一样提供相同的功能——通过该方法来传输正文之外的额外信息。Flume提供的不同source会给其生成的event添加不同的header
- Body是一个字节数组，包含了实际的内容

##### 代理(Flume Agent)
- Flume内部有一个或者多个Agent
- 每一个Agent是一个独立的守护进程(JVM) container
- 从客户端哪儿接收收集，或者从其他的Agent哪儿接收，然后迅速的将获取的数据传给下一个目的节点Agent
![数据采集（flume）](img/older/flume/5.png)
- Agent主要由source、channel、sink三个组件组成。

##### 拦截器(Agent Interceptor)
- Interceptor用于Source的一组拦截器，按照预设的顺序必要地方对events进行过滤和自定义的处理逻辑实现
- 在app(应用程序日志)和 source 之间的，对app日志进行拦截处理的。也即在日志进入到source之前，对日志进行一些包装、清洗过滤等等动作
- 官方上提供的已有的拦截器有：
– Timestamp Interceptor：在event的header中添加一个key叫：timestamp,value为当前的时间戳
    + Host Interceptor：在event的header中添加一个key叫：host,value为当前机器的hostname或者ip
    + Static Interceptor：可以在event的header中添加自定义的key和value
    + Regex Filtering Interceptor：通过正则来清洗或包含匹配的events
    + Regex Extractor Interceptor：通过正则表达式来在header中添加指定的key,value则为正则匹配的部分
- flume的拦截器也是chain形式的，可以对一个source指定多个拦截器，按先后顺序依次处理

##### 选择器(Agent Selector)
- channel selectors 有两种类型:
   + Replicating Channel Selector (default)：将source过来的events发往所有channel
   + Multiplexing Channel Selector：而Multiplexing 可以选择该发往哪些channel
- 对于有选择性选择数据源，明显需要使用Multiplexing 这种分发方式
![数据采集（flume）](img/older/flume/6.png)

> 问题:
Multiplexing 需要判断header里指定key的值来决定分发到某个具体的channel，如果demo和demo2同时运行在同一个服务器上，如果在不同的服务器上运行，我们可以在 source1上加上一个 host 拦截器，
这样可以通过header中的host来判断event该分发给哪个channel，而这里是在同一个服务器上，由host是区分不出来日志的来源的，我们必须想办法在header中添加一个key来区分日志的来源:`通过设置上游不同的Source就可以解决`

#### 可靠性
事件被存储在每个`agent`的`channel`中。随后这些事件会发送到流中的下一个`agent`或者设备存储中（例如 HDFS）。只有事件已经被存储在下一个`agent`的`channel`中或设备存储中时，
当前 channel 才会清除该事件。这种机制保证了流在端到端的传输中具有可靠性。

Flume使用事务方法（transactional approach）来保证事件的可靠传输。在 source 和 slink 中，事件的存储以及恢复作为事务进行封装，
存放事件到 channel 中以及从 channel 中拉取事件均是事务性的。这保证了流中的事件在节点之间传输是可靠的。

- flume保证单次跳转可靠性的方式：传送完成后，该事件才会从通道中移除
- Flume使用事务性的方法来保证事件交互的可靠性。
- 整个处理过程中，如果因为网络中断或者其他原因，在某一步被迫结束了，这个数据会在下一次重新传输。
- Flume可靠性还体现在数据可暂存上面，当目标不可访问后，数据会暂存在Channel中，等目标可访问之后，再进行传输
- Source和Sink封装在一个事务的存储和检索中，即事件的放置或者提供由一个事务通过通道来分别提供。这保证了事件集在流中可靠地进行端到端的传递。
    – Sink开启事务
    – Sink从Channel中获取数据
    – Sink把数据传给另一个Flume Agent的Source中
    – Source开启事务
    – Source把数据传给Channel
    – Source关闭事务
    – Sink关闭事务

#### 可恢复
事件在 channel 中进行，该 channel 负责保障事件从故障中恢复。Flume 支持一个由本地文件系统支持的持久化文件（文件模式：channel.type = "file"） channel。
同样也支持内存模式（channel.type = "memmory"）,即将事件保存在内存队列中。显然，内存模式相对与文件模型性能会更好，但是当 agent 进程不幸挂掉时，内存模式下存储在 channel 中的事件将丢失，无法进行恢复。


#### 复杂的流
Flume 允许用户构建一个复杂的数据流，比如数据流经多个 agent 最终落地。
![数据采集（flume）](img/older/flume/7.png)
