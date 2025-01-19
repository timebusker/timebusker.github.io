---
layout:     post
title:      Hive-HiveServer服务高可用
date:       2017-12-15
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Hive
---

在生产环境中使用Hive，强烈建议使用HiveServer2来提供服务，好处很多：
- 在应用端不用部署Hadoop和Hive客户端；
- 相比hive-cli方式，HiveServer2不用直接将HDFS和Metastore暴漏给用户；
- 有安全认证机制，并且支持自定义权限校验；
- 有HA机制，解决应用端的并发和负载均衡问题；
- JDBC方式，可以使用任何语言，方便与应用进行数据交互；
- 从2.0开始，HiveServer2提供了WEB UI。

Hive从0.14开始，使用Zookeeper实现了HiveServer2的HA功能（ZooKeeper Service Discovery），Client端可以通过指定一个nameSpace来连接HiveServer2，而不是指定某一个host和port。

![HiveServer服务高可用](img/older/hive/4.png)

#### Hive配置
> 假设你的Zookeeper已经安装好，并可用。

> 在两个安装了apache-hive-2.0.0-bin的机器上，分别编辑hive-site.xml，添加以下参数：

```
<property>
    <name>hive.server2.support.dynamic.service.discovery</name>
    <value>true</value>
</property>
<property>
    <name>hive.server2.zookeeper.namespace</name>
    <value>hiveserver2</value>
</property>
<property>
    <name>hive.zookeeper.quorum</name>
    <value>12.12.12.11:2181,12.12.12.12:2181,12.12.12.13:2181</value>
</property>
 
<property>
    <name>hive.zookeeper.client.port</name>
    <value>2181</value>
</property>
<property>
   <name>hive.server2.thrift.bind.host</name>
   <value>0.0.0.0</value>
</property>
<property>
   <name>hive.server2.thrift.port</name>
   <!-- 两个HiveServer2实例的端口号要一致  -->
   <value>10001</value>
</property>
```

配置完成，分别启动两个HiveServer即可。

#### 客户端连接

```
cd $HIVE_HOME/bin

./beeline
# 先连接ZK获取可用hiveserverURL
!connect jdbc:hive2://12.12.12.11:2181,12.12.12.12:2181,12.12.12.13:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2
```
