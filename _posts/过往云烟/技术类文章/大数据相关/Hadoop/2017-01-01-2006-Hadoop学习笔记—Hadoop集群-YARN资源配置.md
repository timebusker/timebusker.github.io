---
layout:     post
title:      Hadoop集群-YARN资源配置
date:       2018-12-15
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Hadoop
---

> 继上篇[《Hadoop集群-HA-服务搭建》](http://www.timebusker.top/2018/05/19/2005-Hadoop%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0-Hadoop%E9%9B%86%E7%BE%A4-HA-%E6%9C%8D%E5%8A%A1%E6%90%AD%E5%BB%BA/)
文章，我们实现了HDFS、ResourceManager的高可用，本章继HA之后，实现YARN计算资源的调度隔离。

### YARN资源调度
在Yarn中，负责给应用分配资源的就是Scheduler。这是一个可插装的调度器，它的用途就是对多用户实现共享大集群并对每个用户资源占用做控制。
Capacity Scheduler是YARN中默认的资源调度器，相比也是性能上更为实用调度器。

##### 配置yarn-site.xml

```
<property>
	<name>yarn.resourcemanager.scheduler.class</name>
	<value>org.apache.hadoop.yarn.server.resourcemanager.scheduler.capacity.CapacityScheduler</value>
	<description>The class to use as the resource scheduler.(指定资源调度器，默认)</description>
</property>
```

##### 配置mapper-site.xml

```
<?xml version="1.0" encoding="utf-8"?>

<configuration> 
  <property> 
    <name>mapreduce.framework.name</name>  
    <value>yarn</value> 
  </property>  
  <!-- 关闭推测执行 网上反馈有问题，待验证-->  
  <property> 
    <name>mapreduce.map.speculative</name>  
    <value>false</value> 
  </property>  
  <property> 
    <name>mapreduce.reduce.speculative</name>  
    <value>false</value> 
  </property>  
  <property> 
    <name>mapreduce.cluster.temp.dir</name>  
    <value>/BDS1/hadoop/mapred/temp</value> 
  </property>  
  <!-- YarnChild 启动JVM参数设置-->  
  <property> 
    <name>mapred.child.java.opts</name>  
    <value>-Xms1024M -Xmx2048M -Xloggc:/tmp/@taskid@.gc</value> 
  </property>  
  <!-- application应用提交时上传文件的副本数，可以加快map启动-->  
  <property> 
    <name>mapreduce.client.submit.file.replication</name>  
    <value>5</value> 
  </property>  
  <!-- 最多能申请的counter数量 -->  
  <property> 
    <name>mapreduce.job.counters.max</name>  
    <value>10</value> 
  </property>  
  <!-- 当只有一个reduce任务的计算时，启用uber模式，直接在AppMaster进行运算 -->  
  <property> 
    <name>mapreduce.job.ubertask.enable</name>  
    <value>false</value> 
  </property>  
  <property> 
    <name>mapreduce.job.ubertask.maxreduces</name>  
    <value>1</value> 
  </property>  
  <property> 
    <name>mapreduce.job.ubertask.maxbytes</name>  
    <value/> 
  </property>  
  <property> 
    <name>mapreduce.job.ubertask.maxmaps</name>  
    <value>9</value> 
  </property>  
  <property> 
    <!-- 当启用了强制本地执行策略，该配置将告知是否遵循严格的数据本地化。如果启用，重用容器只能被分配至本节点上的任务。 -->  
    <name>mapreduce.container.reuse.enforce.strict-locality</name>  
    <value>false</value> 
  </property>  
  <property> 
    <name>mapreduce.job.maxtaskfailures.per.tracker</name>  
    <value>3</value> 
  </property>  
  <!-- reduce进行shuffle的时候，用于启动合并输出和磁盘溢写的过程的阀值，默认为0.66。如果允许，适当增大其比例能够减少磁盘溢写次数，提高系统性能。同mapreduce.reduce.shuffle.input.buffer.percent一起使用。 -->  
  <property> 
    <name>mapreduce.reduce.shuffle.merge.percent</name>  
    <value>0.8</value> 
  </property>  
  <property> 
    <name>yarn.app.mapreduce.am.staging-dir</name>  
    <value>/BDS1/hadoop/yarn/staging</value> 
  </property>  
  <property> 
    <name>mapreduce.admin.map.child.java.opts</name>  
    <value>-Dzookeeper.request.timeout=120000 -server -XX:NewRatio=8 -Djava.net.preferIPv4Stack=true</value> 
  </property>  
  <property> 
    <name>mapreduce.reduce.java.opts</name>  
    <value>-Xmx1024M -Djava.net.preferIPv4Stack=true</value> 
  </property>  
  <property> 
    <name>mapreduce.jobhistory.intermediate-done-dir</name>  
    <value>/BDS1/hadoop/mr-history/tmp</value> 
  </property>  
  <property> 
    <name>mapreduce.map.memory.mb</name>  
    <value>1024</value> 
  </property>  
  <property> 
    <name>mapreduce.admin.reduce.child.java.opts</name>  
    <value>-Dzookeeper.request.timeout=120000 -server -XX:NewRatio=8 -Djava.net.preferIPv4Stack=true</value> 
  </property>  
  <property> 
    <name>mapreduce.reduce.memory.mb</name>  
    <value>1024</value> 
  </property>  
  <property> 
    <name>mapreduce.jobhistory.done-dir</name>  
    <value>/BDS1/hadoop/mr-history/done</value> 
  </property>  
  <property> 
    <name>yarn.app.mapreduce.am.command-opts</name>  
    <value>-Xmx1024m -XX:CMSFullGCsBeforeCompaction=1 -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:+UseCMSCompactAtFullCollection -verbose:gc</value> 
  </property>  
  <property> 
    <name>mapreduce.map.java.opts</name>  
    <value>-Xmx1024M -Djava.net.preferIPv4Stack=true</value> 
  </property>  
  <property> 
    <name>yarn.app.mapreduce.am.resource.mb</name>  
    <value>1024</value> 
  </property> 
</configuration>
```

##### 配置capacity-scheduler.xml
在Capacity Scheduler专属配置文件capacity-scheduler.xml，在`HADOOP_HOME/etc/hadoop`目录下:

```
<configuration>
  <property>
    <name>yarn.scheduler.capacity.maximum-applications</name>
    <value>1000</value>
    <description>
      Maximum number of applications that can be pending and running.
    </description>
  </property>

  <property>
    <name>yarn.scheduler.capacity.maximum-am-resource-percent</name>
    <value>0.1</value>
    <description>
      Maximum percent of resources in the cluster which can be used to run 
      application masters i.e. controls number of concurrent running
      applications.
	  所有AppMaster最多可用资源数量在整个集群的百分比：
    </description>
  </property>

  <property>
    <name>yarn.scheduler.capacity.resource-calculator</name>
    <value>org.apache.hadoop.yarn.util.resource.DominantResourceCalculator</value>
    <description>
      The ResourceCalculator implementation to be used to compare 
      Resources in the scheduler.
      The default i.e. DefaultResourceCalculator only uses Memory while
      DominantResourceCalculator uses dominant-resource to compare 
      multi-dimensional resources such as Memory, CPU etc.
	  DefaultResourceCalculator：只考虑内存资源
	  DominantResourceCalculator：综合考虑内存和虚拟内核CPU
    </description>
  </property>

  <property>
    <name>yarn.scheduler.capacity.root.queues</name>
    <value>Queue_A,Queue_B,Queue_C,Queue_D</value>
    <description>
      The queues at the this level (root is the root queue).
    </description>
  </property>

  <property>
    <name>yarn.scheduler.capacity.root.Queue_A.capacity</name>
    <value>30</value>
    <description>Default queue target capacity.队列的资源容量（百分比）</description>
  </property>

  <property>
    <name>yarn.scheduler.capacity.root.Queue_A.user-limit-factor</name>
    <value>0.8</value>
    <description>
      Default queue user limit a percentage from 0.0 to 1.0. 单个用户最多可以使用的资源因子
    </description>
  </property>

  <property>
    <name>yarn.scheduler.capacity.root.Queue_A.maximum-capacity</name>
    <value>80</value>
    <description>
      The maximum capacity of the default queue. 队列的资源使用上限（百分比）
    </description>
  </property>
  
  <property>
    <name>yarn.scheduler.capacity.root.Queue_A.state</name>
    <value>RUNNING</value>
    <description>
      The state of the default queue. State can be one of RUNNING or STOPPED.
	  队列状态可以为STOPPED或者RUNNING，如果一个队列处于STOPPED状态，用户不可以将应用程序提交到该队列或者它的子队列中，类似的，如果ROOT队列处于STOPPED状态，
	  用户不可以向集群中提交应用程序，但正在运行的应用程序仍可以正常运行结束，以便队列可以优雅地退出。
  </description>

  <property>
    <name>yarn.scheduler.capacity.root.Queue_A.acl_submit_applications</name>
    <value>*</value>
    <description>
      The ACL of who can submit jobs to the default queue.设置用户提交application权限
    </description>
  </property>

  <property>
    <name>yarn.scheduler.capacity.root.Queue_A.acl_administer_queue</name>
    <value>*</value>
    <description>
      The ACL of who can administer jobs on the default queue.设置队列管理员，可以管理队列中application
  </description>

  <property>
    <name>yarn.scheduler.capacity.node-locality-delay</name>
    <value>40</value>
    <description>
      Number of missed scheduling opportunities after which the CapacityScheduler 
      attempts to schedule rack-local containers. 
      Typically this should be set to number of nodes in the cluster, By default is setting 
      approximately number of nodes in one rack which is 40.
	  配置延迟调度。设置为正整数，表示调度器在放松节点限制、改为匹配同一机架上的其他节点前，准备错过的调度机会的数量。
    </description>
  </property>

  <property>
    <name>yarn.scheduler.capacity.queue-mappings</name>
    <value></value>
    <description>
      A list of mappings that will be used to assign jobs to queues
      The syntax for this list is [u|g]:[name]:[queue_name][,next mapping]*
      Typically this list will be used to map users to queues,
      for example, u:%user:%user maps all users to queues with the same name
      as the user.
	  配置项指定用户/组到特定队列的映射
    </description>
  </property>

  <property>
    <name>yarn.scheduler.capacity.queue-mappings-override.enable</name>
    <value>false</value>
    <description>
      If a queue mapping is present, will it override the value specified
      by the user? This can be used by administrators to place jobs in queues
      that are different than the one specified by the user.
      The default is false.
    </description>
  </property>

  <property>
    <name>yarn.scheduler.capacity.per-node-heartbeat.maximum-offswitch-assignments</name>
    <value>1</value>
    <description>
      Controls the number of OFF_SWITCH assignments allowed
      during a node's heartbeat. Increasing this value can improve
      scheduling rate for OFF_SWITCH containers. Lower values reduce
      "clumping" of applications on particular nodes. The default is 1.
      Legal values are 1-MAX_INT. This config is refreshable.
	  控制节点心跳期间允许的OFF_SWITCH分配的数量.
	  增加此值可以提高OFF_SWITCH容器的调度速率. 较低的值可减少特定节点上应用程序的“聚集”. 默认值是1.
	  合法值是1-MAX_INT. 这个配置是可刷新的.
    </description>
  </property>
</configuration>
```

#### 使用队列   

```
# mapreduce:在Job的代码中，设置Job属于的队列,例如hive：
conf.setQueueName("hive");
# hive:在执行hive任务时，设置hive属于的队列,例如dailyTask:
set mapred.job.queue.name=dailyTask;
```

#### 队列刷新
无需重启集群刷新队列：
- 在主节点上根据具体需求，修改好`mapred-site.xml`和`capacity-scheduler.xml`
- 把配置同步到所有节点上`yarn rmadmin -refreshQueues`