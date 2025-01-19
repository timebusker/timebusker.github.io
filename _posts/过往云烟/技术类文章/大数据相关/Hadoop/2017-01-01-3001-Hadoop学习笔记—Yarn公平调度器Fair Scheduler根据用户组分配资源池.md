---
layout:     post
title:      Hadoop学习笔记 — Yarn公平调度器Fair Scheduler根据用户组分配资源池
date:       2018-06-05
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Hadoop  
---

在一个公司内部的Hadoop Yarn集群，肯定会被多个业务、多个用户同时使用，共享Yarn的资源，如果不做资源的管理与规划，那么整个Yarn的资源很容易被某一个用户提交的Application占满，
其它任务只能等待，这种当然很不合理，我们希望每个业务都有属于自己的特定资源来运行MapReduce任务，Hadoop中提供的公平调度器–Fair Scheduler，就可以满足这种需求。

Fair Scheduler将整个Yarn的可用资源划分成多个资源池，每个资源池中可以配置最小和最大的可用资源（内存和CPU）、最大可同时运行Application数量、权重、以及可以提交和管理Application的用户等。

> 根据用户名分配资源池

![Yarn公平调度器Fair Scheduler](img/older/hadoop/yarn/1.jpg)

如图所示，假设整个Yarn集群的可用资源为100vCPU，100GB内存，现在为3个业务各自规划一个资源池，另外，规划一个default资源池，用于运行其他用户和业务提交的任务。
如果没有在任务中指定资源池（通过参数mapreduce.job.queuename），那么可以配置使用用户名作为资源池名称来提交任务，即用户businessA提交的任务被分配到资源池businessA中，
用户businessC提交的任务被分配到资源池businessC中。除了配置的固定用户，其他用户提交的任务将会被分配到资源池default中。

另外，每个资源池可以配置允许提交任务的用户名，比如，在资源池businessA中配置了允许用户businessA和用户hadoop提交任务，如果使用用户hadoop提交任务，
并且在任务中指定了资源池为businessA，那么也可以正常提交到资源池businessA中。

> 根据权重获得额外的空闲资源

在每个资源池的配置项中，有个weight属性（默认为1），标记了资源池的权重，当资源池中有任务等待，并且集群中有空闲资源时候，每个资源池可以根据权重获得不同比例的集群空闲资源。

资源池businessA和businessB的权重分别为2和1，这两个资源池中的资源都已经跑满了，并且还有任务在排队，此时集群中有30个Container的空闲资源，那么，businessA将会额外获得20个Container的资源，businessB会额外获得10个Container的资源。

> 最小资源保证

在每个资源池中，允许配置该资源池的最小资源，这是为了防止把空闲资源共享出去还未回收的时候，该资源池有任务需要运行时候的资源保证。

比如，资源池businessA中配置了最小资源为（5vCPU，5GB），那么即使没有任务运行，Yarn也会为资源池businessA预留出最小资源，一旦有任务需要运行，而集群中已经没有其他空闲资源的时候，
这个最小资源也可以保证资源池businessA中的任务可以先运行起来，随后再从集群中获取资源。

> 动态更新资源配额

Fair Scheduler除了需要在`yarn-site.xml`文件中启用和配置之外，还需要一个`XML文件来配置资源池以及配额`，而该XML中每个资源池的配额可以动态更新，
之后使用命令：`yarn rmadmin –refreshQueues`来使得其生效即可，`不用重启Yarn集群`。

`需要注意的是：动态更新只支持修改资源池配额，如果是新增或减少资源池，则需要重启Yarn集群。`

#### Fair Scheduler配置示例

> yarn-site.xml

```
<!– scheduler start –>
<property>
    <!-- 配置Yarn使用的调度器插件类名 -->
    <name>yarn.resourcemanager.scheduler.class</name>
    <value>org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.FairScheduler</value>
</property>
<property>
    <!-- 配置资源池以及其属性配额的XML文件路径 -->
    <name>yarn.scheduler.fair.allocation.file</name>
    <value>/etc/hadoop/conf/fair-scheduler.xml</value>
</property>
<property>
    <!-- 开启资源抢占 -->
    <name>yarn.scheduler.fair.preemption</name>
    <value>true</value>
</property>
<property>
    <!-- 设置成true，当任务中未指定资源池的时候，将以用户名作为资源池名。这个配置就实现了根据用户名自动分配资源池。 -->
    <name>yarn.scheduler.fair.user-as-default-queue</name>
    <value>true</value>
    <description>default is True</description>
</property>
<property>
    <!-- 是否允许创建未定义的资源池。 -->
    <!-- 如果设置成true，yarn将会自动创建任务中指定的未定义过的资源池。设置成false之后，任务中指定的未定义的资源池将无效，该任务会被分配到default资源池中。-->
    <name>yarn.scheduler.fair.allow-undeclared-pools</name>
    <value>false</value>
    <description>default is True</description>
</property>
<!– scheduler end –>
```

- fair-scheduler.xml

假设在生产环境Yarn中，总共有四类用户需要使用集群，开发用户、测试用户、业务1用户、业务2用户。为了使其提交的任务不受影响，
我们在Yarn上规划配置了五个资源池，分别为 dev_group（开发用户组资源池）、test_group（测试用户组资源池）、business1_group（业务1用户组资源池）、
business2_group（业务2用户组资源池）、default（只分配了极少资源）。并根据实际业务情况，为每个资源池分配了相应的资源及优先级等。

```
<?xml version="1.0"?>
<allocations>  
  <!-- users max running apps -->
  <userMaxAppsDefault>30</userMaxAppsDefault>
<queue name="root">
  <aclSubmitApps> </aclSubmitApps>
  <aclAdministerApps> </aclAdministerApps>
  
  <queue name="default">
          <minResources>2000mb,1vcores</minResources>
          <maxResources>10000mb,1vcores</maxResources>
          <maxRunningApps>1</maxRunningApps>
          <schedulingMode>fair</schedulingMode>
          <weight>0.5</weight>
          <aclSubmitApps>*</aclSubmitApps>
  </queue>
       
  <queue name="dev_group">
          <minResources>200000mb,33vcores</minResources>
          <maxResources>300000mb,90vcores</maxResources>
          <maxRunningApps>150</maxRunningApps>
          <schedulingMode>fair</schedulingMode>
          <weight>2.5</weight>
          <aclSubmitApps> dev_group</aclSubmitApps>
          <aclAdministerApps> hadoop,dev_group</aclAdministerApps>
  </queue>
                                                                                                                                                  
  <queue name="test_group">
          <minResources>70000mb,20vcores</minResources>
          <maxResources>95000mb,25vcores</maxResources>
          <maxRunningApps>60</maxRunningApps>
          <schedulingMode>fair</schedulingMode>
          <weight>1</weight>
          <aclSubmitApps> test_group</aclSubmitApps>
          <aclAdministerApps> hadoop,test_group</aclAdministerApps>
  </queue>
                                                                          
  <queue name="business1_group">
          <minResources>75000mb,15vcores</minResources>
          <maxResources>100000mb,20vcores</maxResources>
          <maxRunningApps>80</maxRunningApps>
          <schedulingMode>fair</schedulingMode>
          <weight>1</weight>
          <aclSubmitApps> business1_group</aclSubmitApps>
          <aclAdministerApps> hadoop,business1_group</aclAdministerApps>
  </queue>
                                                             
                                                                          
  <queue name="business2_group">
      <minResources>75000mb,15vcores</minResources>
      <maxResources>102400mb,20vcores</maxResources>
      <maxRunningApps>80</maxRunningApps>
      <schedulingMode>fair</schedulingMode>
      <weight>1</weight>
      <aclSubmitApps> business2_group</aclSubmitApps>
      <aclAdministerApps> hadoop,business2_group</aclAdministerApps>
  </queue>
 
</queue>
  <queuePlacementPolicy>
      <rule name="primaryGroup" create="false" />
      <rule name="secondaryGroupExistingQueue" create="false" />
      <rule name="default" />
  </queuePlacementPolicy>
 
</allocations>
```

需要注意的是，所有客户端提交任务的用户和用户组的对应关系，需要维护在ResourceManager上，ResourceManager在分配资源池时候，
是从ResourceManager上读取用户和用户组的对应关系的，否则就会被分配到default资源池。
在日志中出现`UserGroupInformation: No groups available for user`类似的警告。而客户端机器上的用户对应的用户组无关紧要。

- 刷新操作
每次在ResourceManager上新增用户或者调整资源池配额后，需要执行下面的命令刷新使其生效：

```
yarn rmadmin -refreshQueues
yarn rmadmin -refreshUserToGroupsMappings
```
