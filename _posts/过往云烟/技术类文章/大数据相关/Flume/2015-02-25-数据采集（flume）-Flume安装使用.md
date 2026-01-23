---
layout:     post
title:      数据采集（flume）-Flume安装使用
date:       2018-03-01
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Flume
---  

> [官网文档地址](http://flume.apache.org/releases/content/1.9.0/FlumeUserGuide.html#)

#### flume安装
> [Flume官网下载](http://flume.apache.org/download.html)软件，解压关注**bin**和**conf**两个目录。

- 配置环境变量***FLUME_HOME***
- 修改配置文件：
    + 重命名flume-env.ps1.template为flume-env.ps1
    + 重命名flume-env.sh.template为flume-env.sh，可以JDK、JVM

```
# 限定Flume的JVM堆大小为1G
export JAVA_OPTS="-Dcom.sun.management.jmxremote -verbose:gc -server -Xms256m -Xmx1g -XX:NewRatio=3 -XX:SurvivorRatio=8 -XX:MaxMetaspaceSize=128M -XX:+UseConcMarkSweepGC -XX:CompressedClassSpaceSize=128M -XX:MaxTenuringThreshold=5 -XX:CMSInitiatingOccupancyFraction=70 -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:/opt/flume/logs/server-gc.log.$(date +%F) -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=1 -XX:GCLogFileSize=64M"
```



### 配置文件
一般来说,在Flume中会存在着多个Agent,所以我们需要给它们分别取一个名字来区分它们,注意名字不要相同,名字保持唯一。
在Flume配置文件中,我们需要做一下操作：
- 需要命名当前使用的`Agent的名称`.
- 命名Agent下的`source的名字`.
- 命名Agent下的`channal的名字`.
- 命名Agent下的`sink的名字`.
- 将source和sink通过channal`绑定`起来.

![数据采集（flume）](img/older/flume/8.png)

```
# 设置名称
#Agent取名为 agent_name
agent_name.source = source_name（逗号隔开，可以同时配置多个）
agent_name.channels = channel_name（逗号隔开，可以同时配置多个）
agent_name.sinks = sink_name（逗号隔开，可以同时配置多个）
```

##### NetCat方式

- 创建agent配置文件

```
vim .conf/netcat.conf
# 设置名称,agent名称：agentNetCat
agentNetCat.sources = sourceNetCat
agentNetCat.sinks = slinkNetCat
agentNetCat.channels = channelNetCat

# 配置Source，监听端口，接受任意IP发送数据
agentNetCat.sources.sourceNetCat.type = netcat
agentNetCat.sources.sourceNetCat.channels = channelNetCat
agentNetCat.sources.sourceNetCat.bind = 0.0.0.0
agentNetCat.sources.sourceNetCat.port = 4141
  
#配置Sink(直接使用日志形式输出)
agentNetCat.sinks.slinkNetCat.type = logger
  
#配置Channel
agentNetCat.channels.channelNetCat.type = memory
agentNetCat.channels.channelNetCat.capacity = 1000
agentNetCat.channels.channelNetCat.transactionCapacity = 100
  
#将source和sink通过channal绑定起来
agentNetCat.sources.sourceNetCat.channels = channelNetCat
agentNetCat.sinks.slinkNetCat.channel = channelNetCat
``` 

- 启动agent

```
./bin/flume-ng agent --conf conf --conf-file ./conf/netcat.conf -name agentNetCat -Dflume.root.logger=INFO,console
```

- 验证 

```
telnet localhost 4141 输入任意字符验证flume日志输出
```

##### Exec方式

- 创建agent配置文件

```
vim .conf/exec.conf
# 设置名称,agent名称：agentExec
agentExec.sources = sourceExec
agentExec.sinks = slinkExec
agentExec.channels = channelExec

# 配置Source，执行shell命令返回的结果
agentExec.sources.sourceExec.type = exec
agentExec.sources.sourceExec.command = tail -f /root/logs/generation.log
  
#配置Sink(直接使用日志形式输出)
agentExec.sinks.slinkExec.type = logger
  
#配置Channel
agentExec.channels.channelExec.type = memory
agentExec.channels.channelExec.capacity = 1000
agentExec.channels.channelExec.transactionCapacity = 100
  
#将source和sink通过channal绑定起来
agentExec.sources.sourceExec.channels = channelExec
agentExec.sinks.slinkExec.channel = channelExec
``` 

- 启动agent

```
./bin/flume-ng agent --conf ./conf --conf-file ./conf/exec.conf -name agentExec -Dflume.root.logger=INFO,console
```

- 验证 

```
echo '11111111111' >> /root/logs/generation.log 观察flume日志输出
```

##### HDFS

- 创建agent配置文件

```
vim .conf/hdfs.conf
# 设置名称,agent名称：agentHdfs
agentHdfs.sources = sourceHdfs
agentHdfs.sinks = slinkHdfs
agentHdfs.channels = channelHdfs

# 配置Source，执行shell命令返回的结果
agentHdfs.sources.sourceHdfs.type = avro
agentHdfs.sources.sourceHdfs.channels = channelHdfs
agentHdfs.sources.sourceHdfs.bind = 0.0.0.0
agentHdfs.sources.sourceHdfs.port = 4141

#配置Sink(直接使用日志形式输出)
agentHdfs.sinks.slinkHdfs.type = hdfs
agentHdfs.sinks.slinkHdfs.channel = channelHdfs
agentHdfs.sinks.slinkHdfs.hdfs.path = hdfs://localhost/timebusker/logs
agentHdfs.sinks.slinkHdfs.hdfs.filePrefix = generation
agentHdfs.sinks.slinkSpool.hdfs.fileSuffix = .log
agentSpool.sinks.slinkSpool.hdfs.minBlockReplicas= 1
agentHdfs.sinks.slinkSpool.hdfs.batchSize= 100
agentHdfs.sinks.slinkSpool.hdfs.fileType = DataStream
agentHdfs.sinks.slinkSpool.hdfs.writeFormat =Text
## roll：滚动切换：控制写文件的切换规则
agentHdfs.sinks.slinkSpool.hdfs.rollSize = 512000    ## 按文件体积（字节）来切   
agentHdfs.sinks.slinkSpool.hdfs.rollCount = 1000000  ## 按event条数切
agentHdfs.sinks.slinkSpool.hdfs.rollInterval = 60    ## 按时间间隔切换文件
## 控制生成目录的规则
# 默认值：false，是否启用时间上的”舍弃”，类似于”四舍五入”，如果启用，则会影响除了%t的其他所有时间表达式；
agentHdfs.sinks.slinkSpool.hdfs.round = true
# 默认值：1，时间上进行“舍弃”的值；
agentHdfs.sinks.slinkSpool.hdfs.roundValue = 10
# 默认值：seconds，时间上进行”舍弃”的单位，包含：second,minute,hour
agentHdfs.sinks.slinkSpool.hdfs.roundUnit = minute
  
#配置Channel
agentHdfs.channels.channelHdfs.type = memory
agentHdfs.channels.channelHdfs.capacity = 1000
agentHdfs.channels.channelHdfs.transactionCapacity = 100
  
#将source和sink通过channal绑定起来
agentHdfs.sources.sourceHdfs.channels = channelHdfs
agentHdfs.sinks.slinkHdfs.channel = channelHdfs
``` 

- 启动agent

```
./bin/flume-ng agent --conf ./conf --conf-file ./conf/hdfs.conf -name agentHdfs -Dflume.root.logger=INFO,console
```

- 验证 

```
# -Dflume.root.logger=INFO,console 设置日志输出控制台，不写到文件
./bin/flume-ng avro-client --conf conf -H localhost -p 4141 -F /root/logs/generation.log -Dflume.root.logger=INFO,console
```

##### 模拟使用Flume监听日志变化,并且把增量的日志文件写入到hdfs中

- 创建agent配置文件

Spool监测配置的目录下新增的文件，并将文件中的数据读取出来。需要注意两点：
- 拷贝到spool目录下的文件不可以再打开编辑
- spool目录下不可包含相应的子目录

```
vim .conf/spool.conf
agentSpool.sources = sourceSpool
agentSpool.sinks = slinkSpool
agentSpool.channels = channelSpool

# 配置Source，执行shell命令返回的结果
agentSpool.sources.sourceSpool.type = spooldir
agentSpool.sources.sourceSpool.spoolDir = /root/logs
agentSpool.sources.sourceSpool.fileHeader  = true
agentSpool.sources.sourceSpool.includePattern  = ^generation-[0-9]{4}.*$
agentSpool.sources.sourceSpool.deletePolicy = never
agentSpool.sources.sourceSpool.deserializer.maxLineLength = 5210
agentSpool.sources.sourceSpool.deserializer.outputCharset = UTF-8
  
#配置Sink(直接使用日志形式输出)
agentSpool.sinks.slinkSpool.type = hdfs
agentSpool.sinks.slinkSpool.hdfs.path = hdfs://localhost/timebusker/logs/%y-%m-%d-%H-%M
agentSpool.sinks.slinkSpool.hdfs.filePrefix = generation
agentSpool.sinks.slinkSpool.hdfs.fileSuffix = .data
agentSpool.sinks.slinkSpool.hdfs.minBlockReplicas= 1
agentSpool.sinks.slinkSpool.hdfs.batchSize= 100
agentSpool.sinks.slinkSpool.hdfs.fileType = DataStream
agentSpool.sinks.slinkSpool.hdfs.writeFormat =Text
## roll：滚动切换：控制写文件的切换规则
agentSpool.sinks.slinkSpool.hdfs.rollSize = 512000    ## 按文件体积（字节）来切   
agentSpool.sinks.slinkSpool.hdfs.rollCount = 1000000  ## 按event条数切
agentSpool.sinks.slinkSpool.hdfs.rollInterval = 60    ## 按时间间隔切换文件
## 控制生成目录的规则
agentSpool.sinks.slinkSpool.hdfs.round = true
agentSpool.sinks.slinkSpool.hdfs.roundValue = 10
agentSpool.sinks.slinkSpool.hdfs.roundUnit = minute
agentSpool.sinks.slinkSpool.hdfs.useLocalTimeStamp = true
  
#配置Channel
agentSpool.channels.channelSpool.type = memory
agentSpool.channels.channelSpool.capacity = 10000
agentSpool.channels.channelSpool.transactionCapacity = 500
  
#将source和sink通过channal绑定起来
agentSpool.sources.sourceSpool.channels = channelSpool
agentSpool.sinks.slinkSpool.channel = channelSpool
``` 

- 启动agent

```
./bin/flume-ng agent --conf ./conf --conf-file ./conf/spool.conf -name agentSpool -Dflume.root.logger=INFO,console
```









