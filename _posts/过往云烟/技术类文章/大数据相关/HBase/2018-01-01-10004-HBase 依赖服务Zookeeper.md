---
layout:     post
title:      HBase 依赖服务Zookeeper
date:       2019-01-14
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - HBase
---

#### HBase依赖服务
HBase并不是一个独立的无依赖的项目。在正常的线上集群上，它至少依赖于ZooKeeper、HDFS两个Apache顶级项目。
对于某些特殊场景，例如Copy Snapshot和验证集群间数据一致性等，还需要借助Yarn集群的分布式计算能力才能实现。

正是借助了Apache的这些成熟稳定的顶级系统，HBase研发团队才能够集中精力来解决高性能、高可用的KV存储系统所面临的诸多问题。

本章将简要介绍ZooKeeper和HDFS，以便读者更深入地理解HBase内部原理。

#### ZooKeeper
ZooKeeper在HBase系统中扮演着非常重要的角色。事实上，无论在HBase中，还是在Hadoop其他的分布式项目中，抑或是非Hadoop生态圈的很多开源项目中，
甚至是全球大大小小的公司内，ZooKeeper都是一项非常重要的基础设施。

ZooKeeper之所以占据如此重要的地位，是因为它解决了分布式系统中一些最基础的问题：

- 提供极低延迟、超高可用的内存KV数据库服务。
- 提供中心化的服务故障发现服务。
- 提供分布式场景下的锁、Counter、Queue等协调服务。

ZooKeeper集群本身是一个服务高可用的集群，通常由奇数个（比如3个、5个等）节点组成，集群的服务不会因小于一半的节点宕机而受影响。
ZooKeeper集群中多个节点都存储同一份数据，为保证多节点之间数据的一致性，ZooKeeper使用ZAB（ZooKeeper Atomic Broadcast）协议作为数据一致性的算法。
ZAB是由Paxos算法改进而来，有兴趣的读者可以进一步阅读论文《Zab: High-performance broadcast for primary-backup systems》。

ZooKeeper节点内数据组织为树状结构，数据存储在每一个树节点（称为znode）上，用户可以根据数据路径获取对应的数据。

##### ZooKeeper核心特性
ZooKeeper在使用ZAB协议保证多节点数据一致性的基础上实现了很多其他工程特性，以下这些特性对于实现分布式集群管理的诸多功能至关重要。

![架构图](img/older/hbase/17.png)

- 多类型节点：ZooKeeper数据树节点可以设置多种节点类型，每种节点类型具有不同节点特性。
	+ 持久节点（PERSISTENT）：节点创建后就会一直存在，直到有删除操作来主动清除这个节点。
	
	+ 临时节点（EPHEMERAL）：和持久节点不同，临时节点的生命周期和客户端session绑定。也就是说，如果客户端session失效，
	  那么这个节点就会自动被清除掉。注意，这里提到的是session失效，而非连接断开，后面会讲到两者的区别；另外，在临时节点下面不能创建子节点。
	  
	+ 持久顺序节点（PERSISTENT_SEQUENTIAL）：这类节点具有持久特性和顺序特性。持久特性即一旦创建就会一直存在，直至被删除。
	  顺序特性表示父节点会为它的第一级子节点维护一份时序，记录每个子节点创建的先后顺序。实际实现中，
	  Zookeeper会为顺序节点加上一个自增的数字后缀作为新的节点名。
	  
	+ 临时顺序节点（EPHEMERAL_SEQUENTIAL）：这类节点具有临时特性和顺序特性。临时特性即客户端session一旦结束，节点就消失。
	  顺序特性表示父节点会为它的第一级子节点维护一份时序，记录每个子节点创建的先后顺序。

- Watcher机制：Watcher机制是ZooKeeper实现的一种事件异步反馈机制，就像现实生活中某读者订阅了某个主题，
  这个主题一旦有任何更新都会第一时间反馈给该读者一样。
	+ watcher设置：ZooKeeper可以为所有的读操作设置watcher，这些读操作包括getChildren()、exists()以及getData()。
	  其中通过getChildren()设置的watcher为子节点watcher，这类watcher关注的事件包括子节点创建、删除等。通过exists()和getData()设置的watcher为数据watcher，
	  这类watcher关注的事件包含节点数据发生更新、子节点发生创建删除操作等。
	  
	+ watcher触发反馈：ZooKeeper中客户端与服务器端之间的连接是长连接。watcher事件发生之后服务器端会发送一个信息给客户端，
	  客户端会调用预先准备的处理逻辑进行应对。
	  
	+ watcher特性：watcher事件是一次性的触发器，当watcher关注的对象状态发生改变时，将会触发此对象上所设置的watcher对应事件。
	  例如：如果一个客户端通过getData("/znode1", true)操作给节点/znode1加上了一个watcher，一旦"/znode1"的数据被改变或删除，客户端就会获得一个关于"znode1"的事件。但是如果/znode1再次改变，那么将不再有watcher事件反馈给客户端，除非客户端重新设置了一个watcher。

- Session机制：ZooKeeper在启动时，客户端会根据配置文件中ZooKeeper服务器列表配置项，选择其中任意一台服务器相连，如果连接失败，
它会尝试连接另一台服务器，直到与一台服务器成功建立连接或因为所有ZooKeeper服务器都不可用而失败。

一旦建立连接，ZooKeeper就会为该客户端创建一个新的session。每个session都会有一个超时时间设置，这个设置由创建session的应用和服务器端设置共同决定。
如果ZooKeeper服务器在超时时间段内没有收到任何请求，则相应的session会过期。一旦session过期，任何与该session相关联的临时znode都会被清理。
临时znode一旦被清理，注册在其上的watch事件就会被触发。

需要注意的是，ZooKeeper对于网络连接断开和session过期是两种处理机制。在客户端与服务端之间维持的是一个长连接，在session超时时间内，
服务端会不断检测该客户端是否还处于正常连接，服务端会将客户端的每次操作视为一次有效的心跳检测来反复地进行session激活。
因此，在正常情况下，客户端session是一直有效的。然而，当客户端与服务端之间的连接断开后，用户在客户端可能主要看到：
`CONNECTION_LOSS`和`SESSION_EXPIRED`两类异常。

	 + CONNECTION_LOSS：网络一旦断连，客户端就会收到CONNECTION_LOSS异常，此时它会自动从ZooKeeper服务器列表中重新选取新的地址，并尝试重新连接，直到最终成功连接上服务器。
	 + SESSION_EXPIRED：客户端与服务端断开连接后，如果重连时间耗时太长，超过了session超时时间，服务器会进行session清理。注意，此时客户端不知道session已经失效，状态还是DISCONNECTED，如果客户端重新连上了服务器，此时状态会变更为SESSION_EXPIRED。
	 
##### ZooKeeper典型使用场景
ZooKeeper在实际集群管理中利用上述工程特性可以实现非常多的分布式功能，比如HBase使用ZooKeeper实现了Master高可用管理、RegionServer宕机异常检测、分布式锁等一系列功能。以分布式锁为例，具体实现步骤如下：

- 客户端调用`create()`方法创建名为`locknode/lock-`的节点，需要注意的是，节点的创建类型需要设置为`EPHEMERAL_SEQUENTIAL`。

- 客户端调用`getChildren(“locknode”)`方法来获取所有已经创建的子节点。

- 客户端获取到所有子节点path之后，如果发现自己在`步骤1`中创建的节点序号最小，那么就认为这个客户端获得了锁。

- 如果在`步骤3`中发现自己并非所有子节点中最小的，说明集群中其他进程获取到了这把锁。此时客户端需要找到最小子节点，然后对其调用exist()方法，同时注册事件监听。

- 一旦最小子节点对应的进程释放了分布式锁，对应的临时节点就会被移除，客户端因为注册了事件监听而收到相应的通知。这个时候客户端需要再次调用`getChildren("locknode")`方法来获取所有已经创建的子节点，然后进入`步骤3`。


### HBase中ZooKeeper核心配置
一个分布式HBase集群的部署运行强烈依赖于ZooKeeper，在当前的HBase系统实现中，ZooKeeper扮演了非常重要的角色。
首先，在安装HBase集群时需要在配置文件conf/hbase-site.xml中配置与ZooKeeper相关的几个重要配置项，如下所示：

```xml
<!-- ZK集群地址 -->
<property>
	<name>hbase.zookeeper.quorum</name>
	<!-- 默认 -->
	<value>localhost</value>
<property>
<!-- ZK集群端口 -->
<property>
	<name>hbase.zookeeper.property.clientPort</name>
	<!-- 默认 -->
	<value>2181</value>
<property>
<!-- HBase在ZK集群的存储根目录 -->
<property>
	<name>zookeeper.znode.parent</name>
	<!-- 默认 -->
	<value>/hbase</value>
<property>
```

##### HBase在ZooKeeper上存储的信息
- meta-region-server：存储HBase集群hbase:meta元数据表所在的RegionServer访问地址。客户端读写数据首先会从此节点读取hbase:meta元数据的访问地址，将部分元数据加载到本地，根据元数据进行数据路由。

- master/backup-masters：通常来说生产线环境要求所有组件节点都避免单点服务，HBase使用ZooKeeper的相关特性实现了Master的高可用功能。其中Master节点是集群中对外服务的管理服务器，backup-masters下的子节点是集群中的备份节点，一旦对外服务的主Master节点发生了异常，备Master节点可以通过选举切换成主Master，继续对外服务。需要注意的是备Master节点可以是一个，也可以是多个。

- table：集群中所有表信息。

- region-in-transition：在当前HBase系统实现中，迁移Region是一个非常复杂的过程。首先对这个Region执行unassign操作，将此Region从open状态变为offline状态（中间涉及PENDING_CLOSE、CLOSING以及CLOSED等过渡状态），再在目标RegionServer上执行assign操作，将此Region从offline状态变成open状态。这个过程需要在Master上记录此Region的各个状态。目前，RegionServer将这些状态通知给Master是通过ZooKeeper实现的，RegionServer会在region-in-transition中变更Region的状态，Master监听ZooKeeper对应节点，以便在Region状态发生变更之后立马获得通知，得到通知后Master再去更新Region在hbase:meta中的状态和在内存中的状态。

- table-lock：HBase系统使用ZooKeeper相关机制实现分布式锁。HBase中一张表的数据会以Region的形式存在于多个RegionServer上，因此对一张表的DDL操作（创建、删除、更新等操作）通常都是典型的分布式操作。每次执行DDL操作之前都需要首先获取相应表的表锁，防止多个DDL操作之间出现冲突，这个表锁就是分布式锁。分布式锁可以使用ZooKeeper的相关特性来实现，在此不再赘述。

- online-snapshot：用来实现在线snapshot操作。表级别在线snapshot同样是一个分布式操作，需要对目标表的每个Region都执行snapshot，全部成功之后才能返回成功。Master作为控制节点给各个相关RegionServer下达snapshot命令，对应RegionServer对目标Region执行snapshot，成功后通知Master。Master下达snapshot命令、RegionServer反馈snapshot结果都是通过ZooKeeper完成的。

- replication：用来实现HBase复制功能。

- splitWAL/recovering-regions：用来实现HBase分布式故障恢复。为了加速集群故障恢复，HBase实现了分布式故障恢复，让集群中所有RegionServer都参与未回放日志切分。ZooKeeper是Master和RegionServer之间的协调节点。

- rs：集群中所有运行的RegionServer。

### HDFS

我们知道HBase的文件都存放在HDFS（Hadoop Distribuited File System）文件系统上。HDFS本质上是一个分布式文件系统，可以部署在大量价格低廉的服务器上，
提供可扩展的、高容错性的文件读写服务。HBase项目本身并不负责文件层面的高可用和扩展性，它通过把数据存储在HDFS上来实现大容量文件存储和文件备份。

与其他的分布式文件系统相比，HDFS擅长的场景是大文件（一般认为字节数超过数十MB的文件为大文件）的顺序读、随机读和顺序写。
从API层面，HDFS并不支持文件的随机写（Seek+Write）以及多个客户端同时写同一个文件。正是由于HDFS的这些优点和缺点，深刻地影响了HBase的设计。

##### HDFS架构

![架构图](img/older/hbase/18.png)

一般情况下，一个线上的高可用HDFS集群主要由4个重要的服务组成：NameNode、DataNode、JournalNode、ZkFailoverController。
在具体介绍4个服务之前，我们需要了解Block这个概念。存储在HDFS上面的文件实际上是由若干个数据块（Block，大小默认为128MB)组成，
每一个Block会设定一个副本数N，表示这个Block在写入的时候会写入N个数据节点，以达到数据备份的目的。
读取的时候只需要依次读取组成这个文件的Block即可完整读取整个文件，注意读取时只需选择N个副本中的任何一个副本进行读取即可。

- NameNode

线上需要部署2个NameNode：一个节点是Active状态并对外提供服务；另一个节点是StandBy状态，作为Active的备份，备份状态下不提供对外服务，也就是说HDFS客户端无法通过请求StandBy状态的NameNode来实现修改文件元数据的目的。如果ZkFailoverController服务检测到Active状态的节点发生异常，会自动把StandBy状态的NameNode服务切换成Active的NameNode。

NameNode存储并管理HDFS的文件元数据，这些元数据主要包括文件属性（文件大小、文件拥有者、组以及各个用户的文件访问权限等）
以及文件的多个数据块分布在哪些存储节点上。需要注意的是，文件元数据是在不断更新的，例如HBase对HLog文件持续写入导致文件的Block数量不断增长，
管理员修改了某些文件的访问权限，HBase把一个HFile从/hbase/data目录移到/hbase/archive目录。所有这些操作都会导致文件元数据的变更。
因此NameNode本质上是一个独立的维护所有文件元数据的高可用KV数据库系统。为了保证每一次文件元数据都不丢失，
NameNode采用写EditLog和FsImage的方式来保证元数据的高效持久化。每一次文件元数据的写入，都是先做一次EditLog的顺序写，
然后再修改NameNode的内存状态。同时NameNode会有一个内部线程，周期性地把内存状态导出到本地磁盘持久化成FsImage（假设导出FsImage的时间点为t），
那么对于小于时间点t的EditLog都认为是过期状态，是可以清理的，这个过程叫做推进checkpoint。

NameNode会把所有文件的元数据全部维护在内存中。因此，如果在HDFS中存放大量的小文件，则造成分配大量的Block，
这样可能耗尽NameNode所有内存而导致OOM。因此，HDFS并不适合存储大量的小文件。当然，后续的HDFS版本支持NameNode对元数据分片，解决了NameNode的扩展性问题。

- DataNode
组成文件的所有Block都是存放在DataNode节点上的。一个逻辑上的Block会存放在N个不同的DataNode上。而NameNode、JournalNode、ZKFailoverController服务都是用来维护文件元数据的。

- JournaNode
由于NameNode是Active-Standby方式的高可用模型，且NameNode在本地写EditLog，那么存在一个问题—在StandBy状态下的NameNode切换成Active状态后，如何才能保证新Active的NameNode和切换前Active状态的NameNode拥有完全一致的数据？如果新Active的NameNode数据和老Active的NameNode不一致，那么整个分布式文件系统的数据也将不一致，这对用户来说是一件极为困扰的事情。

为了保证两个NameNode在切换前后能读到一致的EditLog，HDFS单独实现了一个叫做JournalNode的服务。线上集群一般部署奇数个JournalNode（一般是3个，或者5个），在这些JournalNode内部，通过Paxos协议来保证数据一致性。因此可以认为，JournalNode其实就是用来维护EditLog一致性的Paxos组。

- ZKFailoverController
ZKFailoverController主要用来实现NameNode的自动切换。

##### 文件写入

```
FileSystem fs=FileSystem.get(conf);
FSDataOutputStream out ;
try(out = fs.create(path)){
	out.writeBytes("test-data");
}catch(Exception e){
	e
}finally{
	out.flush;
	out.close;
}
```

![架构图](img/older/hbase/19.png)

- DFS Client在创建FSDataOutputStream时，把文件元数据发给NameNode，得到一个文件唯一标识的fileId，并向用户返回一个OutputStream。

- 用户拿到OutputStream之后，开始写数据。注意写数据都是按照Block来写的，不同的Block可能分布在不同的DataNode上，因此如果发现当前的Block已经写满，
  DFSClient就需要再发起请求向NameNode申请一个新的Block。在一个Block内部，数据由若干个Packet（默认64KB）组成，若当前的Packet写满了，
  就放入DataQueue队列，DataStreamer线程异步地把Packet写入到对应的DataNode。３个副本中的某个DataNode收到Packet之后，会先写本地文件，
  然后发送一份到第二个DataNode，第二个执行类似步骤后，发给第三个DataNode。等所有的DataNode都写完数据之后，就发送Packet的ACK给DFS Client，
  只有收到ACK的Packet才是写入成功的。
  
- 用户执行完写入操作后，需要关闭OutputStream。关闭过程中，DFSClient会先把本地DataQueue中未发出去的Packet全部发送到DataNode。
  若忘记关闭，对那些已经成功缓存在DFS Client的DataQueue中但尚未成功写入DataNode的数据，将没有机会写入DataNode中。对用户来说，这部分数据将丢失。

> FSDataOutputStream中hflush和hsync的区别

flush成功返回，则表示DFSClient的DataQueue中所有Packet都已经成功发送到了３个DataNode上。但是对每个DataNode而言，数据仍然可能存放在操作系统的Cache上，
若存在至少一个正常运行的DataNode，则数据不会丢失。sync成功返回，则表示DFSClient DataQueue中的Packet不但成功发送到了３个DataNode，
而且每个DataNode上的数据都持久化（sync）到了磁盘上，这样就算所有的DataNode都重启，数据依然存在（flush则没法保证）。

在HBASE-19024之后，HBase 1.5.0以上的版本可以在服务端通过设置`hbase.wal.hsync`来选择`hflush`或者`hsync`。低于1.5.0的版本，可以在表中设置`DURABILITY`属性来实现。

在小米内部大部分HBase集群上，综合考虑写入性能和数据可靠性两方面因素，我们选择使用默认的`hflush`来保证WAL持久性。
因为底层的HDFS集群已经保证了数据的三副本，并且每一个副本位于不同的机架上，而三个机架同时断电的概率极小。
但是对那些依赖`云服务`的`HBase`集群来说，有可能没法保证副本落在不同机架，`hsync`是一个合理的选择。

另外，针对小米广告业务和云服务这种对数据可靠性要求很高的业务，我们采用同步复制的方式来实现多个数据中心的数据备份，
这样虽然仍选择用`hflush`，但数据已经被同步写入两个数据中心的6个DataNode上，同样可以保证数据的高可靠性。

##### 文件读取
![架构图](img/older/hbase/20.png)

- DFSClient请求NameNode，获取到对应read position的Block信息（包括该Block落在了哪些DataNode上）。

- DFSClient从Block对应的DataNode中选择一个合适的DataNode，对选中的DataNode创建一个BlockReader以进行数据读取。

HDFS读取流程很简单，但对HBase的读取性能影响重大，尤其是Locality和短路读这两个最为核心的因素。

- Locality 

某些服务可能和`DataNode`部署在同一批机器上。因为`DataNode`本身需要消耗的内存资源和CPU资源都非常少，主要消耗网络带宽和磁盘资源。
而HBase的`RegionServer`服务本身是内存和CPU消耗型服务，于是我们把`RegionServer`和`DataNode`部署在一批机器上。对某个`DFSClient`来说，
一个文件在这台机器上的`locality`可以定义为：

`locality =该文件存储在本地机器的字节数之和 / 该文件总字节数`

因此，`locality是[0, 1]之间的一个数`，locality越大，则读取的数据都在本地，无需走网络进行数据读取，性能就越好。反之，则性能越差。

- 短路读（Short Circuit Read）

短路读是指对那些Block落在和DFSClient同一台机器上的数据，可以不走TCP协议进行读取，而是直接由DFSClient向本机的DataNode请求对应Block的文件描述符
（File Descriptor），然后创建一个BlockReaderLocal，通过fd进行数据读取，这样就节省了走本地TCP协议栈的开销。

测试数据表明，locality和短路读对HBase的读性能影响重大。在locality=1.0情况下，不开短路读的p99性能要比开短路读差10%左右。如果用locality=0和locality=1相比，读操作性能则差距巨大。

##### HDFS在HBase系统中扮演的角色
HBase使用HDFS存储所有数据文件，从HDFS的视角看，HBase就是它的客户端。这样的架构有几点需要说明：

- HBase本身并不存储文件，它只规定文件格式以及文件内容，实际文件存储由HDFS实现。

- HBase不提供机制保证存储数据的高可靠，数据的高可靠性由HDFS的多副本机制保证。

- HBase-HDFS体系是典型的计算存储分离架构。这种轻耦合架构的好处是，一方面可以非常方便地使用其他存储替代HDFS作为HBase的存储方案；
  另一方面对于云上服务来说，计算资源和存储资源可以独立扩容缩容，给云上用户带来了极大的便利。

### HBase在HDFS中的文件布局

通过HDFS的客户端列出HBase集群的文件如下：

```
drwxr-xr-x - hadoop hadoop 0 2018-05-07 10:42 /hbase-nptest/.hbase-snapshot
drwxr-xr-x - hadoop hadoop 0 2018-04-27 14:04 /hbase-nptest/.tmp
drwxr-xr-x - hadoop hadoop 0 2018-07-06 21:07 /hbase-nptest/MasterProcWALs
drwxr-xr-x - hadoop hadoop 0 2018-06-25 17:14 /hbase-nptest/WALs
drwxr-xr-x - hadoop hadoop 0 2018-05-07 10:43 /hbase-nptest/archive
drwxr-xr-x - hadoop hadoop 0 2017-10-10 20:24 /hbase-nptest/corrupt
drwxr-xr-x - hadoop hadoop 0 2018-05-31 12:02 /hbase-nptest/data
-rw-r--r-- 3 hadoop hadoop 42 2017-09-29 17:30 /hbase-nptest/hbase.id
-rw-r--r-- 3 hadoop hadoop 7 2017-09-29 17:30 /hbase-nptest/hbase.version
drwxr-xr-x - hadoop hadoop 0 2018-07-06 21:22 /hbase-nptest/oldWALs
```

- .hbase-snapshot：snapshot文件存储目录。用户执行snapshot后，相关的snapshot元数据文件存储在该目录。

- .tmp：临时文件目录，主要用于HBase表的创建和删除操作。表创建的时候首先会在tmp目录下执行，执行成功后再将tmp目录下的表信息移动到实际表目录下。表删除操作会将表目录移动到tmp目录下，一定时间过后再将tmp目录下的文件真正删除。

- MasterProcWALs：存储Master Procedure过程中的WAL文件。Master Procedure功能主要用于可恢复的分布式DDL操作。在早期HBase版本中，分布式DDL操作一旦在执行到中间某个状态发生宕机等异常的情况时是没有办法回滚的，这会导致集群元数据不一致。Master Procedure功能使用WAL记录DDL执行的中间状态，在异常发生之后可以通过WAL回放明确定位到中间状态点，继续执行后续操作以保证整个DDL操作的完整性。

- WALs：存储集群中所有RegionServer的HLog日志文件。

- archive：文件归档目录。这个目录主要会在以下几个场景下使用。所有对HFile文件的删除操作都会将待删除文件临时放在该目录。

- Compaction删除HFile的时候，也会把旧的HFile移动到这里。

- corrupt：存储损坏的HLog文件或者HFile文件。

- data：存储集群中所有Region的HFile数据。

HFile文件在data目录下的完整路径如下所示：

`/hbase/data/default/usertable/fa13562579a4c0ec84858f2c947e8723/family/105baeff31ed481cb708c65728965666`

其中，default表示命名空间，usertable为表名，`fa13562579a4c0ec84858f2c947e8723`为Region名称，`family`为列簇名，`105baeff31ed481cb708c65728965666`为HFile文件名。
除了HFile文件外，data目录下还存储了一些重要的子目录和子文件。

- .tabledesc：表描述文件，记录对应表的基本schema信息。

- .tmp：表临时目录，主要用来存储Flush和Compaction过程中的中间结果。以flush为例，MemStore中的KV数据落盘形成HFile首先会生成在.tmp目录下，一旦完成再从.tmp目录移动到对应的实际文件目录。

- .regioninfo：Region描述文件。

- recovered.edits：存储故障恢复时该Region需要回放的WAL日志数据。RegionServer宕机之后，该节点上还没有来得及flush到磁盘的数据需要通过WAL回放恢复，WAL文件首先需要按照Region进行切分，每个Region拥有对应的WAL数据片段，回放时只需要回放自己的WAL数据片段即可。

- hbase.id：集群启动初始化的时候，创建的集群唯一id。

- hbase.version：HBase软件版本文件，代码静态版本。

- oldWALs：WAL归档目录。一旦一个WAL文件中记录的所有KV数据确认已经从MemStore持久化到HFile，那么该WAL文件就会被移到该目录。