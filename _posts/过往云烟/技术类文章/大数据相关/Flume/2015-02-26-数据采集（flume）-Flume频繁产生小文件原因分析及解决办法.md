---
layout:     post
title:      数据采集（flume）-Flume频繁产生小文件原因分析及解决办法
date:       2018-03-01
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Flume
---  

> [官网文档地址](http://flume.apache.org/releases/content/1.9.0/FlumeUserGuide.html#)

> [Flume HDFS Sink常用配置深度解读](https://www.jianshu.com/p/4f43780c82e9)

#### flume滚动配置为何不起作用？
在测试hdfs的sink，发现sink端的文件滚动配置项起不到任何作用，配置如下：

```
# 核心配置
agentSpool.sinks.slinkSpool.hdfs.rollSize = 512000    ## 按文件体积（字节）来切   
agentSpool.sinks.slinkSpool.hdfs.rollCount = 1000000  ## 按event条数切
agentSpool.sinks.slinkSpool.hdfs.rollInterval = 60    ## 按时间间隔切换文件
```

当我启动flume的时候，运行十几秒，不断写入数据，发现hdfs端频繁的产生文件，每隔几秒就有新文件产生而且在flume的日志输出可以频繁看到这句

```
[WARN - org.apache.flume.sink.hdfs.BucketWriter.append(BucketWriter.java:589)] Block Under-replication detected. Rotating file.
```

只要有这句，就会产生一个新的文件。其原意是`检测到复制块正在滚动文件(现有的文件块少于指定的文件块数量)`，结合源码看下：

- 判断文件滚动源码

```
private boolean shouldRotate() {  
    boolean doRotate = false;  
    // 判断是否当前的HDFSWriter正在复制块
    if (writer.isUnderReplicated()) {  
      this.isUnderReplicated = true;  
      doRotate = true;  
    } else {  
      this.isUnderReplicated = false;  
    }  
   
    if ((rollCount > 0) && (rollCount <= eventCounter)) {  
      LOG.debug("rolling: rollCount: {}, events: {}", rollCount, eventCounter);  
      doRotate = true;  
    }  
   
    if ((rollSize > 0) && (rollSize <= processSize)) {  
      LOG.debug("rolling: rollSize: {}, bytes: {}", rollSize, processSize);  
      doRotate = true;  
    }  
    return doRotate;  
  }
```

- 获取文件块是否正在被复制
通过读取的配置复制块数量和当前正在复制的块比较，判断是否正在被复制。

```
public boolean isUnderReplicated() {  
    try {  
      int numBlocks = getNumCurrentReplicas();  
      if (numBlocks == -1) {  
        return false;  
      }  
      int desiredBlocks;  
      if (configuredMinReplicas != null) {  
        desiredBlocks = configuredMinReplicas;  
      } else {  
        desiredBlocks = getFsDesiredReplication();  
      }  
      return numBlocks < desiredBlocks;  
    } catch (IllegalAccessException e) {  
      logger.error("Unexpected error while checking replication factor", e);  
    } catch (InvocationTargetException e) {  
      logger.error("Unexpected error while checking replication factor", e);  
    } catch (IllegalArgumentException e) {  
      logger.error("Unexpected error while checking replication factor", e);  
    }  
    return false;  
  }
```

- 程序入口

```
if (shouldRotate()) {  
   boolean doRotate = true;  
   if (isUnderReplicated) {  
     if (maxConsecUnderReplRotations > 0 && consecutiveUnderReplRotateCount >= maxConsecUnderReplRotations) {  
       doRotate = false;  
       if (consecutiveUnderReplRotateCount == maxConsecUnderReplRotations) {  
         LOG.error("Hit max consecutive under-replication rotations ({}); " +  
             "will not continue rolling files under this path due to " +  
             "under-replication", maxConsecUnderReplRotations);  
       }  
     } else {  
       LOG.warn("Block Under-replication detected. Rotating file.");  
     }  
     consecutiveUnderReplRotateCount++;  
   } else {
     consecutiveUnderReplRotateCount = 0;  
   }
}
```

`固定变量maxConsecUnderReplRotations=30`

> 判断逻辑：

如果文件现有的数据块少于额定的数据块数量，确认当前文件正在进行复制操作。
正在复制的块，最多之能滚动出30个文件，如果超过了30次，该数据块如果还在复制中，那么数据也不会滚动了，doRotate=false，不会滚动了，所以有的人发现自己一旦运行一段时间，会出现30个文件。

如果你配置了10秒滚动一次，写了2秒，恰好这时候该文件内容所在的块在复制中，那么虽然没到10秒，依然会给你滚动文件的，和文件大小，事件数量的配置原理相同。

为了解决上述问题，我们只要让程序感知不到写的文件所在块正在复制就行了，怎么做呢？

`只要让isUnderReplicated()方法始终返回false就行了`

该方法是通过当前正在被复制的块和配置中读取的复制块数量比较的，我们能改的就只有配置项中复制块的数量，而官方给出的flume配置项中有该项。

`hdfs.minBlockReplicas`

默认读的是hadoop中的dfs.replication属性，该属性默认值是3。这里我们也不去该hadoop中的配置，在flume中添加上述属性为1即可

`agentSpool.sinks.slinkSpool.hdfs.minBlockReplicas= 1`