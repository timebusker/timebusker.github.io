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

> [streaming-offset-to-zk](https://github.com/qindongliang/streaming-offset-to-zk)

#### 全人工操作

我们都知道SparkStreaming程序是一个长服务，一旦运转起来不会轻易停掉，那么如果我们想要停掉正在运行的程序应该怎么做呢？

暴力停掉sparkstreaming是有可能出现问题的，比如你的数据源是kafka，已经加载了一批数据到sparkstreaming中正在处理，如果中途停掉，这个批次的数据很有可能没有处理完，就被强制stop了，下次启动时候会重复消费或者部分数据丢失。

- 1.4之前的版本，需要一个钩子函数：

```scala
sys.ShutdownHookThread{  
    log.info("Gracefully stopping Spark Streaming Application")  
    ssc.stop(true, true)  
    log.info("Application stopped")  
}  
```

- .4之后的版本，比较简单:

```scala
// 
sparkConf.set("spark.streaming.stopGracefullyOnShutdown","true")  
```

然后，如果需要停掉sparkstreaming程序时：登录spark ui页面在executors页面找到driver程序所在的机器;使用ssh命令登录这台机器上，执行下面的命令通过端口号找到主进程然后kill掉。

```shell
ss -tanlp |  grep 55197|awk '{print $6}'|awk  -F, '{print $2}'|xargs kill -15  
```

注意上面的操作执行后，sparkstreaming程序，并不会立即停止，而是会把当前的批处理里面的数据处理完毕后才会停掉，此间sparkstreaming不会再消费kafka的数据，这样以来就能保证结果不丢和重复。

此外还有一个问题是，spark on yarn模式下，默认的情况driver程序的挂了，会自动再重启一次，作为高可用，也就是上面的操作你可能要执行两次，才能真能的停掉程序，
当然我们也可以设置驱动程序一次挂掉之后，就真的挂掉了，这样就没有容灾机制了，需要慎重考虑：

```java
# 指定yarn最大重试次数
--conf spark.yarn.maxAppAttempts=1  
```

`麻烦、有风险、不够简单`

#### 消息通知

在驱动程序中，加一段代码，这段代码的作用每隔一段时间可以是10秒也可以是3秒，扫描通知消息，如果收到停机消息就调用StreamContext对象stop方法。

消息中间件可以是redis，zk，hbase，db等


#### 端口接受停机请求

内部暴露一个socket或者http端口用来接收请求，等待触发关闭流程序。

需要在driver启动一个socket线程，或者http服务，这里推荐使用http服务，因为socket有点偏底层处理起来稍微复杂点，如果使用http服务，
我们可以直接用内嵌的jetty，对外暴露一个http接口，spark ui页面用的也是内嵌的jetty提供服务，所以我不需要在pom里面引入额外的依赖，
在关闭的时候，找到驱动所在ip，就可以直接通过curl或者浏览器就直接关闭流程序。


