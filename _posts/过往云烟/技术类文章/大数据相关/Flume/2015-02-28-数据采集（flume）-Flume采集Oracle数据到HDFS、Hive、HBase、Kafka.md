---
layout:     post
title:      数据采集（flume）-Flume采集Oracle数据到HDFS、Hive、HBase、Kafka
date:       2018-04-02
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Flume
---  

> [本部分内容网上博客说法不一，实际操作多关注源码](https://github.com/apache/flume)

> [官网文档地址](http://flume.apache.org/releases/content/1.9.0/FlumeUserGuide.html#)

> [Flume HDFS Sink常用配置深度解读](https://www.jianshu.com/p/4f43780c82e9)

### Flume读取Oracle数据

> 使用Flume不适用Sqoop的主要原因是，Flume可以统一增量读取数据后写入Kafka，分发到各数据平台。借助开源插件[flume-ng-sql-source](https://github.com/timebusker/flume-ng-sql-source)

> `flume-ng-sql-source`插件采用`openCVS`写数据到channel，导致数据都有双引号，需要配置额外的拦截器`DataFormatInterceptor(自定义)`，也可以使用Flume自带的过滤器[SearchandReplaceInterceptor](http://flume.apache.org/releases/content/1.9.0/FlumeUserGuide.html#regex-filtering-interceptor)过滤。

- `flume-ng-sql-source`插件需要指定数据范围进行增量提取，否则提取的数据全部重复
- 数据`自增值`可根据源码自行调整

```
# 配置Source读取数据
# For each one of the sources, the type is defined
agent.sources.source1.type = org.keedio.flume.source.SQLSource
# channel selector 选择器
# replicating：可同时输出相同数据到两个channel
# Multiplexing：可根据head头信息把消息输出到指定channel
# 除此之外还可以自定义
agent.sources.source1.selector.type=replicating
# Hibernate Database connection properties
agent.sources.source1.hibernate.connection.url = jdbc:oracle:thin:@12.12.12.11:1521:orc
agent.sources.source1.hibernate.connection.user = mine
agent.sources.source1.hibernate.connection.password = mine
agent.sources.source1.hibernate.connection.autocommit = true
agent.sources.source1.hibernate.dialect = org.hibernate.dialect.Oracle10gDialect
agent.sources.source1.hibernate.connection.driver_class = oracle.jdbc.driver.OracleDriver
# Columns to import to kafka (default * import entire row)
#agent.sources.sqlSource.columns.to.select = *
# Query delay, each configured milisecond the query will be sent
# 本处已经修改数据范围设置，基于时间范围做控制(默认是基于ID主键自增控制  id + rownum)
# 60000ms =1 min
agent.sources.source1.run.query.delay = 60000
# Status file is used to save last readed row
agent.sources.source1.status.file.path = /var/log/flume
agent.sources.source1.status.file.name = sqlSource.status
# Custom query
agent.sources.source1.start.from = 20190703220000
agent.sources.source1.custom.query = select t.* from tb_test_stat t where datetime>= to_date($@$,'yyyy-MM-DD HH24:MI:SS') and datetime <= (to_date($@$,'yyyy-MM-DD HH24:MI:SS')+1/24/60) order by datetime asc 
# 每次写入channel的 event数量
agent.sources.source1.batch.size = 1000
# 每次执行查询的最大行数
agent.sources.source1.max.rows = 1000
agent.sources.source1.hibernate.connection.provider_class = org.hibernate.connection.C3P0ConnectionProvider
agent.sources.source1.hibernate.c3p0.min_size=1
agent.sources.source1.hibernate.c3p0.max_size=10


# 为source配置拦截器
# 配置拦截器，flume自带拦截器
agent.sources.source1.interceptors= interceptor1
agent.sources.source1.interceptors.interceptor1.type=org.keedio.flume.interceptor.DataFormatInterceptor$Builder
```

### 写入HDSF

> agent主机上需要配置好`hadoop客户端`

```
#配置Sink(HDFS)
agent.sinks.sink1.type = hdfs
agent.sinks.sink1.hdfs.path = hdfs://HdpCluster/timebusker/%Y%m%d%H
agent.sinks.sink1.hdfs.filePrefix = 1
agent.sinks.sink1.hdfs.fileSuffix = data
agent.sinks.sink1.hdfs.minBlockReplicas= 1
agent.sinks.sink1.hdfs.batchSize= 1000
agent.sinks.sink1.hdfs.fileType = DataStream
agent.sinks.sink1.hdfs.writeFormat =Text
## roll：滚动切换：控制写文件的切换规则
agent.sinks.sink1.hdfs.rollSize = 128000000
agent.sinks.sink1.hdfs.rollCount = 50000000
agent.sinks.sink1.hdfs.rollInterval = 3600
## 控制生成目录的规则
agent.sinks.sink1.hdfs.round = true
agent.sinks.sink1.hdfs.roundValue = 10
agent.sinks.sink1.hdfs.roundUnit = minute
agent.sinks.sink1.hdfs.useLocalTimeStamp = true
```

### 写入Hive表

> `flume-ng-sql-source`插件采用`openCVS`写数据到channel，导致数据都有双引号，需要配置额外的拦截器`DataFormatInterceptor(自定义)`，也可以使用Flume自带的过滤器[SearchandReplaceInterceptor](http://flume.apache.org/releases/content/1.9.0/FlumeUserGuide.html#regex-filtering-interceptor)过滤。

> SparkSQL不支持`分桶表`查询操作

> [参考博客](https://blog.csdn.net/woloqun/article/details/77651006)

> Flume入数据到Hive需要注意一下几点:

- 只支持`ORCFile`文件格式
- 建表时必须将表设置为事务性表,事务默认关闭，需要自己开启
- 表必须分桶
- 需要修改hive-site.xml
- 需要拷贝hive的jar到flume
- 需要启动hive元数据服务

```
# 建表示例：
create table tb_user(
	id string,
	name string,
	age string
)clustered by (id) into 5 buckets stored as orc tblproperties ('transactional'='true');

# hive-site.xml修改以下内容:

<property>
	<name>hive.support.concurrency</name>
	<value>true</value>
</property>
<property>
	<name>hive.exec.dynamic.partition.mode</name>
	<value>nonstrict</value>
</property>
<property>
	<name>hive.txn.manager</name>
	<value>org.apache.hadoop.hive.ql.lockmgr.DbTxnManager</value>
</property>
<property>
	<name>hive.compactor.initiator.on</name>
	<value>true</value>
</property>
<property>
	<name>hive.compactor.worker.threads</name>
	<value>1</value>
</property>

# 拷贝Hive相关jar包到Flume
cp apache-hive-2.3.0-bin/hcatalog/share/hcatalog/* $FLUME_HOME/lib
cp apache-hive-2.3.0-bin/lib/hive-* $FLUME_HOME/lib
cp apache-hive-2.3.0-bin/lib/antlr* $FLUME_HOME/lib

# 启动hive元数据服务
nohup ./apache-hive-2.3.0-bin/bin/hive --service metastore 2>&1 1>/dev/null &

# 启动服务配置，若失败，尝试重启集群服务
```

```
# 配置Sink(HIVE)
agent.sinks.sink2.type=hive
agent.sinks.sink2.hive.metastore=thrift://12.12.12.11:9083
agent.sinks.sink2.hive.database=default
agent.sinks.sink2.hive.table=tb_test_stat
#agent.sinks.sink2.hive.autoCreatePartitions=true
#agent.sinks.sink2.hive.partition=%Y%m%d%H
agent.sinks.sink2.batchSize=1000
agent.sinks.sink2.serializer=DELIMITED
agent.sinks.sink2.serializer.delimiter=","
agent.sinks.sink2.serializer.serdeSeparator=','
agent.sinks.sink2.serializer.fieldnames=city_code,city_name,area_name,datetime
## 控制生成分区时间的规则
#agent.sinks.sink2.round = true
#agent.sinks.sink2.roundValue = 10
#agent.sinks.sink2.roundUnit = minute
#agent.sinks.sink2.useLocalTimeStamp = true
```

### 写入HBase表

> HBaseSink根据HBase分为两个版本：hbase、hbase2

> 拷贝HBase依赖包到Flume的lib目录下

```
cp metrics-core-* $FLUME_HOME/lib
cp protobuf-java-* $FLUME_HOME/lib
cp htrace-core-* $FLUME_HOME/lib
cp hbase-* $FLUME_HOME/lib
```

- [Flume-Hbase-Sink针对不同版本flume与HBase的适配研究与经验总结](https://cloud.tencent.com/developer/article/1025430)

```
#配置Sink(HBase v2.1)
agent.sinks.sink3.type = hbase2
agent.sinks.sink3.zookeeperQuorum = hdp-cluster-11:2181,hdp-cluster-12:2181,hdp-cluster-13:2181
agent.sinks.sink3.znodeParent = /hbase
agent.sinks.sink3.table = tb_b_c_ci_dsj
agent.sinks.sink3.columnFamily  = hzcgi_info
agent.sinks.sink3.batchSize=1000
agent.sinks.sink3.rowPrefix=hzcgi_
agent.sinks.sink3.suffix=nano

# 将所有数据写到一个列祖的一列中
# agent.sinks.sink3.serializer = org.apache.flume.sink.hbase2.SimpleHBase2EventSerializer
# agent.sinks.sink3.serializer.payloadColumn='hzcgi'

# 使用正则匹配切割event，然后存入HBase表的多个列(基于java正则捕获组实现)
agent.sinks.sink3.serializer = org.apache.flume.sink.hbase2.RegexHBase2EventSerializer
# 正则表达式对event的body做分割，然后按列存储HBase:
agent.sinks.sink3.serializer.regex = (.*),(.*),(.*),(.*),(.*),(.*),(.*),(.*),(.*),(.*),(.*),(.*),(.*),(.*),(.*),(.*)
agent.sinks.sink3.serializer.colNames = city_code,city_name,area_name,datetime
```

### 写入Kafka

> flume写入kafka，未指定分区时，将是随机分布。flume写kafka分区是根据flume的event的header信息确定

```
#配置Sink(Kafka)
# 未设置指定分区，将是随机分布
# flume写kafka分区是根据flume的event的header信息确定
agent.sinks.sink4.type=org.apache.flume.sink.kafka.KafkaSink
agent.sinks.sink4.kafka.topic=timebusker
agent.sinks.sink4.kafka.bootstrap.servers=web-server-50:9092,web-server-51:9092,web-server-52:9092
agent.sinks.sink4.kafka.flumeBatchSize=1000
agent.sinks.sink4.kafka.partitionIdHeader=partitionIds
agent.sinks.sink4.kafka.producer.acks=1
agent.sinks.sink4.kafka.producer.linger.ms=1
agent.sinks.sink4.kafka.producer.comperssion.type=snappy
```

### 关于Flume拦截器开发及Kafka分区设置

```
package org.keedio.flume.interceptor;

import org.apache.commons.codec.Charsets;
import org.apache.flume.Context;
import org.apache.flume.Event;
import org.apache.flume.interceptor.Interceptor;
import java.util.List;
import java.util.Map;

public class DataFormatInterceptor implements Interceptor {

    @Override
    public void initialize() {
    }

    @Override
    public Event intercept(Event event) {
        // 设置event信息体信息
        String body = new String(event.getBody(), Charsets.UTF_8);
        body = body.replace("\"", "");
        event.setBody(body.getBytes());
        // 设置event头信息
        Map<String, String> headers = event.getHeaders();
        int partitionIds = System.currentTimeMillis() % 2 == 0 ? 0 : 1;
        headers.put("partitionIds", partitionIds + "");
        event.setHeaders(headers);
        return event;
    }

    @Override
    public List<Event> intercept(List<Event> list) {
        for (Event e : list) {
            intercept(e);
        }
        return list;
    }

    @Override
    public void close() {
    }

    public static class Builder implements Interceptor.Builder {
        @Override
        public Interceptor build() {
            return new DataFormatInterceptor();
        }
        @Override
        public void configure(Context context) {
            // 通过调用context对象的getString方法来获取flume配置自定义拦截器的参数，方法参数要和自定义拦截器配置中的参数保持一致
        }
    }
}
```