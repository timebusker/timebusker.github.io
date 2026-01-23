<<<<<<< HEAD
---
layout:     post
title:      Hadoop学习笔记 — MapReduce计算模型 
date:       2018-06-03
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Hadoop  
---

> Hadoop学习笔记—MapReduce计算模型 

#### MapReduce并行计算模型
- 在Hadoop的MapReduce框架中主要涉及到两个组件：**JobTracker**和**TaskTracker**（HDFS中的组件是NameNode和DataNode）。   

- MapReduce的本质是**并行运算**，可以将大规模的数据分析任务分发到任何一个拥有足够多机器的数据中心，进行大规模的数据集处理。  

- Hadoop MR(Mapper Reduce) 是一个软件架构的实现，用户处理大批量的的离线数据作业，运行于大型集群中，硬件可靠和容错。
  MR核心思想将作业的输入转化为多个并行的Map程序，然后进行Reduce输出运算结果。作业的输入和输出都存储于文件，由MR框架负责作业的调度，监控和失败重试。

##### TaskTracker
- TaskTracker一个hadoop计算进程，运行在hadoop集群的datanode节点上。taskTracker的主要任务是**运行JobTracker分配给它的实际计算任务**，如运行Map、Reduce函数，
  当然也包括Shuffle过程。TaskTracker任务具体运行在一组slots上，slots的数量可以配置，一般slots的数量会配置成和这台机器的CPU核心数量一致。
  当TaskTracker收到JobTracker分配的一个task时，JobTracker会为这个task单独启动一个jvm进程，也就是说，每个map、reduce任务都会单独运行在一个jvm进程中
  (jvm也可以重用，这里不多做介绍)。TaskTracker被分配的task数量决定于当前还有多少个空闲的slots。TaskTracker在运行task的过程中会向JobTracker发送心跳信息，
  发送心跳出了要告诉JobTracker自己是否存活外，心跳信息中还包含当前空闲的slots数量等信息。  
##### JobTracker  
- JobTracker进程的作用是运行和监控MapReduce的Job，当一个客户端向JobTracker提交任务时，过程如下图：  
![image](img/older/hadoop/14.png)    
   1. JobTracker接收Job请求（**接受JOB请求**）
   2. JobTracker根据Job的输入参数向NameNode请求包含这些文件数据块的DataNode节点列表（**根据计算分配资源**）
   3. JobTracker确定Job的执行计划：确定执行此job的Map、Reduce的task数量，并且分配这些task到离数据块最近的节点上（**指定执行计划并分配计算**）
   4. JobTracker提交所有task到每个TaskTracker节点。TaskTracker会定时的向JobTracker发送心跳，若一定时间内没有收到心跳，JobTracker就认为这个TaskTracker节点失败，然后JobTracker就会把此节点上的task重新分配到其它节点上
   5. 一旦所有的task执行完成，JobTracker会更新job状态为完成，若一定数量的task总数执行失败，这个job就会被标记为失败
   6. JobTracker发送job运行状态信息给Client端


#### MR设计目标
- 为只需要几分钟或者几小时的就可以完成的任务作业提供服务。
- 运行在同一个内部有高速网络连接的数据中心内。
- 数据中心内的计算机都是可靠的、专门的硬件。

#### MR程序设计
```
// MRV1.0 API org.apache.hadoop.mapred
// MRV2.0 API org.apache.hadoop.mapreduce

// map方法是提供给map task进程来调用的，map task进程是每读取一行文本来调用一次我们自定义的map方法
// map task在调用map方法时，传递的参数：
//   1、一行的起始偏移量LongWritable作为key（行号）
//   2、一行的文本内容Text作为value（文本内容）

// Combiner 
// map task可以利用Combiner来对自己负责的切片中的数据进行聚合，聚合后再发给reduce task，这中间可以减少传输的数据量。
// 而map task调用Combiner的机制跟reduce task调用Reducer类的机制是一样的，所以Combiner组件在开发时也是继承Reducer类

// reduce task会将shuffle阶段分发过来的大量kv数据对进行聚合排序，聚合排序的机制是相同key的kv对聚合为一组
// 然后reduce task对每一组聚合kv调用一次我们自定义的reduce方法
// 调用时传递的参数：
//   1、key：一组kv中的key
//   2、values：一组kv中所有value的迭代器

// 每次reduce执行完成后，还会执行cleanup()方法——在复杂变模型中，可以重写该方法做一些计算出来

// 在复杂的运算中，通过定义Java Bean（需要实现Hadoop Writeable序列化接口）进行数据封装，并可以将Java bean作为Key或者Value
// 定义多次提交任务将负责任务简单化

// Java 序列化：对象的类、类签名、类的所有非暂态和非静态成员的值,以及它所有的父类都要被写入——冗余信息很多
// Hadoop序列化：同一个类的对象的序列化结果只输出一份元数据，并通过某种形式的引用,来共享元数据。
//     1、紧凑：由于带宽是 Hadoop集群中最稀缺的资源,一个紧凑的序列化机制可以充分利用数据中心的带宽。
//     2、快速：在进程间通信(包括 MapReduce过程中涉及的数据交互)时会大量使用序列化机制,因此,必须尽量减少序列化和反序列化的开销，在hadoop的反序列化中，能重复的利用一个对象的readField方法来重新产生不同的对象。 
//     3、可扩展：简化的序列化机制能够容易支持系统、协议的升级。
//     4、互操作：可以支持不同开发语言间的通信,如C++和Java间的通信（精心设计文件的格式或者IPC机制实现）。

/**
 * 用于提交mapreduce job的客户端程序
 * 功能：
 *   1、封装本次job运行时所需要的必要参数
 *   2、跟yarn进行交互，将mapreduce程序成功的启动、运行
 */
public class JobSubmitter {
	
	public static void main(String[] args) throws Exception {
		
		// 在代码中设置JVM系统参数，用于给job对象来获取访问HDFS的用户身份
		System.setProperty("HADOOP_USER_NAME", "root");
		
		// 能够默认加载classpath路径下的core-site.xml等配置文件信息
		// 并写入到Context中在整个计算过程中使用
		Configuration conf = new Configuration();
		// 1、设置job运行时要访问的默认文件系统
		conf.set("fs.defaultFS", "hdfs://hdp-01:9000");
		// 2、设置job提交到哪去运行
		conf.set("mapreduce.framework.name", "yarn");
		conf.set("yarn.resourcemanager.hostname", "hdp-01");
		// 3、如果要从windows系统上运行这个job提交客户端程序，则需要加这个跨平台提交的参数
		conf.set("mapreduce.app-submission.cross-platform","true");
		
		Job job = Job.getInstance(conf);
		
		// 1、封装参数：jar包所在的位置
		job.setJar("d:/wc.jar");
		//job.setJarByClass(JobSubmitter.class);
		
		// 2、封装参数： 本次job所要调用的Mapper实现类、Reducer实现类
		job.setMapperClass(WordcountMapper.class);
		job.setReducerClass(WordcountReducer.class);
		
		// 3、封装参数：本次job的Mapper实现类、Reducer实现类产生的结果数据的key、value类型
		job.setMapOutputKeyClass(Text.class);
		job.setMapOutputValueClass(IntWritable.class);
		
		job.setOutputKeyClass(Text.class);
		job.setOutputValueClass(IntWritable.class);
		
		Path output = new Path("/wordcount/output");
		FileSystem fs = FileSystem.get(new URI("hdfs://hdp-01:9000"),conf,"root");
		if(fs.exists(output)){
			fs.delete(output, true);
		}
		
		// 4、封装参数：本次job要处理的输入数据集所在路径、最终结果的输出路径
		FileInputFormat.setInputPaths(job, new Path("/wordcount/input"));
		FileOutputFormat.setOutputPath(job, output);  // 注意：输出路径必须不存在
		
		// 5、封装参数：想要启动的reduce task的数量
		job.setNumReduceTasks(2);
		
		// 6、提交job给yarn
		boolean res = job.waitForCompletion(true);
		System.exit(res?0:-1);
	}
}
```

#### MR运作流程
##### 数据流  
- MR作业（JOB）是客户端需要执行的工作单元，它包含输入数据、MR程序和配置信息。Hadoop将作业分为若干个任务（task）来执行，
其中包含两类任务：map任务和reduce任务。这些任务运行在集群的节点上，并通过YARN进行资源调度，如果一个任务失败，它将
在另一个节点上自动重新调度运行。     
   
- Hadoop将MR的输入数据切割为等长大小的数据块，简称为[**分片**](#)。Hadoop为每一个数据分片构建一个map任务，并由它来运行用户
自定义的map函数，从而处理分片中的数据。      

- 拥有许多分片，意味着处理每个分片所需的时间少于处理整个输入数据所花的时间。因此，并行处理每个数据分片，且每个数据分片比较小，那么整个处理
过程将获得更好的负载均衡。——随着切片分得越细，负载均衡的效果就越好。    

- 另一方面，分片太小，以为构建的map任务数多，因此，管理分片的总时间和构建map任务的总时间成为决定作业的整个执行时间。
——合理的分片大小是：趋向于HDFS块大小，默认128M。是因为它确保可以存储在单个节点上的最大输入块的大小。如果分片跨越两个数据块，
那么对于任何一个HDFS节点（基本上不可能同时存储着着两个数据块），都需要网络传输数据。     

![image](img/older/hadoop/hadoop-mr-1.jpg)    
![image](img/older/hadoop/hadoop-mr-2.jpg)    
![image](img/older/hadoop/hadoop-mr-3.jpg)    

##### 任务执行流程
1、执行计算任务有两个角色一个是JobTracker，一个是TaskTracker，前者用于管理和调度工作，后者用于执行工作。  
2、一般来说一个Hadoop集群由一个JobTracker和N个TaskTracker构成。
3、可以理解为shuffle描述着Map task到Reduce task的整个过程。

- 每次的计算任务都分为两个阶段，一个Map阶段一个Reduce阶段。（shuffle阶段位于Map和Reduce的中间）

- Map阶段接收一组键值对形式的值<key,Value>，然后对这个输入进行处理并输出一组键值对形式的值    （map接收的数据是由InputFormat处理过的先spilt然后再生成键值对）

- Reduce接收Map输出的结果进行计算并输出（map过程产生的数据默认写入内存缓冲区，因为在内存里可以提高combine和sort的速度，默认的缓冲区的大小为100MB可以进行配置，但是当缓冲区的内存使用大于一定的值得时候会发生溢写，默认是使用率80%，一个后台的线程就会启动把缓冲区的数据写入到磁盘中，往内存中写入的线程会继续的执行）

- 当（Spill）写入线程启动后，会对这80MB空间内的key/value对进行sort。排序是MapReduce模型的默认行为，首先进行key排序，对于key相同的按照value进行排序。

- Combine（规约）发生在Spill的阶段本质上Combine就是Reduce，通过Combine可以减少输入reduce的数据量，优化MR的中间数据量

- 每次的Spill都会在本地声称一个Spill文件，如果map的数据量很大进行了多次的spill磁盘上对应的会有多个的spill文件存在、当map task 真正的完成的时候，内存缓冲区中的数据也会spill到本地磁盘上形成一个spill文件，所以磁盘上最少会有一个spill文件的存在，因为最终的文件只能有一个，所以需要把这些spill文件归并到一起，这个归并的过程叫做Merge

- Merger是把多个不同的spill文件合并到一个文件，所以可能会发生有相同的key的事情，如果这时候设置过Combiner就会直接用Combiner来合并相同的key

- reduce分为四个子阶段 ①从各个map task上读取相应的数据 ②sort ③执行reduce函数 ④把结果写到HDFS中

首先是客户端要编写好mapreduce程序，配置好mapreduce的作业也就是job，接下来就是提交job了，提交job是提交到JobTracker上的，这个时候JobTracker就会构建这个job，
具体就是分配一个新的job任务的ID值，接下来它会做检查操作，这个检查就是确定输出目录是否存在，如果存在那么job就不能正常运行下去，JobTracker会抛出错误给客户端，
接下来还要检查输入目录是否存在，如果不存在同样抛出错误，如果存在JobTracker会根据输入计算输入分片（Input Split），如果分片计算不出来也会抛出错误，至于输入分片我后面会做讲解的，
这些都做好了JobTracker就会配置Job需要的资源了。分配好资源后，JobTracker就会初始化作业，初始化主要做的是将Job放入一个内部的队列，让配置好的作业调度器能调度到这个作业，
作业调度器会初始化这个job，初始化就是创建一个正在运行的job对象（封装任务和记录信息），以便JobTracker跟踪job的状态和进程。初始化完毕后，作业调度器会获取输入分片信息（input split），
每个分片创建一个map任务。接下来就是任务分配了，这个时候tasktracker会运行一个简单的循环机制定期发送心跳给jobtracker，心跳间隔是5秒，程序员可以配置这个时间，
心跳就是jobtracker和tasktracker沟通的桥梁，通过心跳，jobtracker可以监控tasktracker是否存活，也可以获取tasktracker处理的状态和问题，同时tasktracker也可以通过心跳里的返回值获取jobtracker给它的操作指令。
任务分配好后就是执行任务了。在任务执行时候jobtracker可以通过心跳机制监控tasktracker的状态和进度，同时也能计算出整个job的状态和进度，
而tasktracker也可以本地监控自己的状态和进度。当jobtracker获得了最后一个完成指定任务的tasktracker操作成功的通知时候，jobtracker会把整个job状态置为成功，然后当客户端查询job运行状态时候（注意：这个是异步操作），
客户端会查到job完成的通知的。如果job中途失败，mapreduce也会有相应机制处理，一般而言如果不是程序员程序本身有bug，mapreduce错误处理机制都能保证提交的job能正常完成。   

##### 输入分片（input split）：
在进行map计算之前，mapreduce会根据输入文件计算输入分片（input split），每个输入分片（input split）针对一个map任务，输入分片（input split）存储的并非数据本身，
而是一个分片长度和一个记录数据的位置的数组，输入分片（input split）往往和hdfs的block（块）关系很密切，假如我们设定hdfs的块的大小是64mb，如果我们输入有三个文件，大小分别是3mb、65mb和127mb，
那么mapreduce会把3mb文件分为一个输入分片（input split），65mb则是两个输入分片（input split）而127mb也是两个输入分片（input split），
换句话说我们如果在map计算前做输入分片调整，例如合并小文件，那么就会有5个map任务将执行，而且每个map执行的数据大小不均，这个也是mapreduce优化计算的一个关键点。

##### map阶段：
就是程序员编写好的map函数了，因此map函数效率相对好控制，而且一般map操作都是本地化操作也就是在数据存储节点上进行；

##### combiner阶段：
combiner阶段是程序员可以选择的，combiner其实也是一种reduce操作，因此我们看见WordCount类里是用reduce进行加载的。
Combiner是一个本地化的reduce操作，它是map运算的后续操作，主要是在map计算出中间文件前做一个简单的合并重复key值的操作，
例如我们对文件里的单词频率做统计，map计算时候如果碰到一个hadoop的单词就会记录为1，但是这篇文章里hadoop可能会出现n多次，
那么map输出文件冗余就会很多，因此在reduce计算前对相同的key做一个合并操作，那么文件会变小，这样就提高了宽带的传输效率，
毕竟hadoop计算力宽带资源往往是计算的瓶颈也是最为宝贵的资源，但是combiner操作是有风险的，使用它的原则是combiner的输入不会影响到reduce计算的最终输入，
例如：如果计算只是求总数，最大值，最小值可以使用combiner，但是做平均值计算使用combiner的话，最终的reduce计算结果就会出错。

##### shuffle阶段：
将map的输出作为reduce的输入的过程就是shuffle了，这个是mapreduce优化的重点地方。这里我不讲怎么优化shuffle阶段，讲讲shuffle阶段的原理，因为大部分的书籍里都没讲清楚shuffle阶段。
Shuffle一开始就是map阶段做输出操作，一般mapreduce计算的都是海量数据，map输出时候不可能把所有文件都放到内存操作，因此map写入磁盘的过程十分的复杂，更何况map输出时候要对结果进行排序，
内存开销是很大的，map在做输出时候会在内存里开启一个环形内存缓冲区，这个缓冲区专门用来输出的，默认大小是100mb，并且在配置文件里为这个缓冲区设定了一个阀值，
默认是0.80（这个大小和阀值都是可以在配置文件里进行配置的），同时map还会为输出操作启动一个守护线程，如果缓冲区的内存达到了阀值的80%时候，这个守护线程就会把内容写到磁盘上，
这个过程叫spill，另外的20%内存可以继续写入要写进磁盘的数据，写入磁盘和写入内存操作是互不干扰的，如果缓存区被撑满了，那么map就会阻塞写入内存的操作，
让写入磁盘操作完成后再继续执行写入内存操作，前面我讲到写入磁盘前会有个排序操作，这个是在写入磁盘操作时候进行，不是在写入内存时候进行的，如果我们定义了combiner函数，
那么排序前还会执行combiner操作。每次spill操作也就是写入磁盘操作时候就会写一个溢出文件，也就是说在做map输出有几次spill就会产生多少个溢出文件，等map输出全部做完后，
map会合并这些输出文件。这个过程里还会有一个Partitioner操作，对于这个操作很多人都很迷糊，其实Partitioner操作和map阶段的输入分片（Input split）很像，一个Partitioner对应一个reduce作业，
如果我们mapreduce操作只有一个reduce操作，那么Partitioner就只有一个，如果我们有多个reduce操作，那么Partitioner对应的就会有多个，Partitioner因此就是reduce的输入分片，
这个程序员可以编程控制，主要是根据实际key和value的值，根据实际业务类型或者为了更好的reduce负载均衡要求进行，这是提高reduce效率的一个关键所在。
到了reduce阶段就是合并map输出文件了，Partitioner会找到对应的map输出文件，然后进行复制操作，复制操作时reduce会开启几个复制线程，这些线程默认个数是5个，
程序员也可以在配置文件更改复制线程的个数，这个复制过程和map写入磁盘过程类似，也有阀值和内存大小，阀值一样可以在配置文件里配置，而内存大小是直接使用reduce的tasktracker的内存大小，
复制时候reduce还会进行排序操作和合并文件操作，这些操作完了就会进行reduce计算了。

##### reduce阶段：和map函数一样也是程序员编写的，最终结果是存储在hdfs上的**（有多少个reduce进程任务就会产生多少个结果文件）**。

##### Mapreduce的相关问题
- **jobtracker的单点故障**：jobtracker和hdfs的namenode一样也存在单点故障，单点故障一直是hadoop被人诟病的大问题，为什么hadoop的做的文件系统和mapreduce计算框架都是高容错的，但是最重要的管理节点的故障机制却如此不好，
我认为主要是namenode和jobtracker在实际运行中都是在内存操作，而做到内存的容错就比较复杂了，只有当内存数据被持久化后容错才好做，namenode和jobtracker都可以备份自己持久化的文件，
但是这个持久化都会有延迟，因此真的出故障，任然不能整体恢复，另外hadoop框架里包含zookeeper框架，zookeeper可以结合jobtracker，用几台机器同时部署jobtracker，
保证一台出故障，有一台马上能补充上，不过这种方式也没法恢复正在跑的mapreduce任务。   

- **输出目录**：做mapreduce计算时候，输出一般是一个文件夹，而且该文件夹是不能存在，我在出面试题时候提到了这个问题，而且这个检查做的很早，当我们提交job时候就会进行，
mapreduce之所以这么设计是保证数据可靠性，如果输出目录存在reduce就搞不清楚你到底是要追加还是覆盖，不管是追加和覆盖操作都会有可能导致最终结果出问题，
mapreduce是做海量数据计算，一个生产计算的成本很高，例如一个job完全执行完可能要几个小时，因此一切影响错误的情况mapreduce是零容忍的

- **格式化输入/输出**：Mapreduce还有一个InputFormat和OutputFormat，我们在编写map函数时候发现map方法的参数是之间操作行数据，没有牵涉到InputFormat，这些事情在我们new Path时候mapreduce计算框架帮我们做好了，
而OutputFormat也是reduce帮我们做好了，我们使用什么样的输入文件，就要调用什么样的InputFormat，InputFormat是和我们输入的文件类型相关的，mapreduce里常用的InputFormat有FileInputFormat普通文本文件，
SequenceFileInputFormat是指hadoop的序列化文件，另外还有KeyValueTextInputFormat。OutputFormat就是我们想最终存储到hdfs系统上的文件格式了，这个根据你需要定义了，hadoop有支持很多文件格式。

##### 优化方案
- 数据本地化策略：Hadoop在存储有输入数据的（HDFS的数据）的节点上运行map任务，可以获得最佳的性能，因为它无需使用宝贵的集群带宽资源。     

- combiner函数：Combiner函数，在Map运算结束后类似于先在Map计算节点进行一次Reduce计算，减少数据传输量。在MapReduce中，当map生成的数据过大时，带宽就成了瓶颈，
当在发送给 Reduce 时对数据进行一次本地合并，减少数据传输量以提高网络IO性能。   

[**【Hadoop 中的 Combiner 过程】**](https://blog.csdn.net/u011007180/article/details/52495191) 
![image](img/older/hadoop/42.png)  
![image](img/older/hadoop/43.png)  
![image](img/older/hadoop/44.png)  
![image](img/older/hadoop/45.png)  
![image](img/older/hadoop/46.png)  
![image](img/older/hadoop/47.png)  
![image](img/older/hadoop/48.png)  
=======
---
layout:     post
title:      Hadoop学习笔记 — MapReduce计算模型 
date:       2018-06-03
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Hadoop  
---

> [Hadoop学习笔记—MapReduce计算模型](https://github.com/timebusker/timebusker.github.io/blob/master/img/hadoop/map-reduce.png) 

> [详细阅读shuffle阶段](http://www.timebusker.top/2018/06/03/1003-Hadoop%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0-MapReduce%E8%AE%A1%E7%AE%97%E6%A8%A1%E5%9E%8B/#shuffle%E9%98%B6%E6%AE%B5)

> ***input->split->recordReader->map函数->partition->spill(->sort->combiner)->map合并溢写小文件（默认80MB）->reduce复制文件->排序->合并-reduce函数->输出结果***

#### MapReduce并行计算模型
- 在Hadoop的MapReduce框架中主要涉及到两个组件：**JobTracker**和**TaskTracker**（HDFS中的组件是NameNode和DataNode）。   

- MapReduce的本质是**并行运算**，可以将大规模的数据分析任务分发到任何一个拥有足够多机器的数据中心，进行大规模的数据集处理。  

- Hadoop MR(Mapper Reduce) 是一个软件架构的实现，用户处理大批量的的离线数据作业，运行于大型集群中，硬件可靠和容错。
  MR核心思想将作业的输入转化为多个并行的Map程序，然后进行Reduce输出运算结果。作业的输入和输出都存储于文件，由MR框架负责作业的调度，监控和失败重试。

##### TaskTracker
- TaskTracker一个hadoop计算进程，运行在hadoop集群的datanode节点上。taskTracker的主要任务是**运行JobTracker分配给它的实际计算任务**，如运行Map、Reduce函数，
  当然也包括Shuffle过程。TaskTracker任务具体运行在一组slots上，slots的数量可以配置，一般slots的数量会配置成和这台机器的CPU核心数量一致。
  当TaskTracker收到JobTracker分配的一个task时，JobTracker会为这个task单独启动一个jvm进程，也就是说，每个map、reduce任务都会单独运行在一个jvm进程中
  (jvm也可以重用，这里不多做介绍)。TaskTracker被分配的task数量决定于当前还有多少个空闲的slots。TaskTracker在运行task的过程中会向JobTracker发送心跳信息，
  发送心跳出了要告诉JobTracker自己是否存活外，心跳信息中还包含当前空闲的slots数量等信息。  
##### JobTracker  
- JobTracker进程的作用是运行和监控MapReduce的Job，当一个客户端向JobTracker提交任务时，过程如下图：  
![image](img/older/hadoop/14.png)    
   1. JobTracker接收Job请求（**接受JOB请求**）
   2. JobTracker根据Job的输入参数向NameNode请求包含这些文件数据块的DataNode节点列表（**根据计算分配资源**）
   3. JobTracker确定Job的执行计划：确定执行此job的Map、Reduce的task数量，并且分配这些task到离数据块最近的节点上（**指定执行计划并分配计算**）
   4. JobTracker提交所有task到每个TaskTracker节点。TaskTracker会定时的向JobTracker发送心跳，若一定时间内没有收到心跳，JobTracker就认为这个TaskTracker节点失败，然后JobTracker就会把此节点上的task重新分配到其它节点上
   5. 一旦所有的task执行完成，JobTracker会更新job状态为完成，若一定数量的task总数执行失败，这个job就会被标记为失败
   6. JobTracker发送job运行状态信息给Client端


#### MR设计目标
- 为只需要几分钟或者几小时的就可以完成的任务作业提供服务。
- 运行在同一个内部有高速网络连接的数据中心内。
- 数据中心内的计算机都是可靠的、专门的硬件。

#### MR程序设计
```
// MRV1.0 API org.apache.hadoop.mapred
// MRV2.0 API org.apache.hadoop.mapreduce

// map方法是提供给map task进程来调用的，map task进程是每读取一行文本来调用一次我们自定义的map方法
// map task在调用map方法时，传递的参数：
//   1、一行的起始偏移量LongWritable作为key（行号）
//   2、一行的文本内容Text作为value（文本内容）

// Combiner 
// map task可以利用Combiner来对自己负责的切片中的数据进行聚合，聚合后再发给reduce task，这中间可以减少传输的数据量。
// 而map task调用Combiner的机制跟reduce task调用Reducer类的机制是一样的，所以Combiner组件在开发时也是继承Reducer类

// reduce task会将shuffle阶段分发过来的大量kv数据对进行聚合排序，聚合排序的机制是相同key的kv对聚合为一组
// 然后reduce task对每一组聚合kv调用一次我们自定义的reduce方法
// 调用时传递的参数：
//   1、key：一组kv中的key
//   2、values：一组kv中所有value的迭代器

// 每次reduce执行完成后，还会执行cleanup()方法——在复杂变模型中，可以重写该方法做一些计算出来

// 在复杂的运算中，通过定义Java Bean（需要实现Hadoop Writeable序列化接口）进行数据封装，并可以将Java bean作为Key或者Value
// 定义多次提交任务将负责任务简单化

// Java 序列化：对象的类、类签名、类的所有非暂态和非静态成员的值,以及它所有的父类都要被写入——冗余信息很多
// Hadoop序列化：同一个类的对象的序列化结果只输出一份元数据，并通过某种形式的引用,来共享元数据。
//     1、紧凑：由于带宽是 Hadoop集群中最稀缺的资源,一个紧凑的序列化机制可以充分利用数据中心的带宽。
//     2、快速：在进程间通信(包括 MapReduce过程中涉及的数据交互)时会大量使用序列化机制,因此,必须尽量减少序列化和反序列化的开销，在hadoop的反序列化中，能重复的利用一个对象的readField方法来重新产生不同的对象。 
//     3、可扩展：简化的序列化机制能够容易支持系统、协议的升级。
//     4、互操作：可以支持不同开发语言间的通信,如C++和Java间的通信（精心设计文件的格式或者IPC机制实现）。

/**
 * 用于提交mapreduce job的客户端程序
 * 功能：
 *   1、封装本次job运行时所需要的必要参数
 *   2、跟yarn进行交互，将mapreduce程序成功的启动、运行
 */
public class JobSubmitter {
	
	public static void main(String[] args) throws Exception {
		
		// 在代码中设置JVM系统参数，用于给job对象来获取访问HDFS的用户身份
		System.setProperty("HADOOP_USER_NAME", "root");
		
		// 能够默认加载classpath路径下的core-site.xml等配置文件信息
		// 并写入到Context中在整个计算过程中使用
		Configuration conf = new Configuration();
		// 1、设置job运行时要访问的默认文件系统
		conf.set("fs.defaultFS", "hdfs://hdp-01:9000");
		// 2、设置job提交到哪去运行
		conf.set("mapreduce.framework.name", "yarn");
		conf.set("yarn.resourcemanager.hostname", "hdp-01");
		// 3、如果要从windows系统上运行这个job提交客户端程序，则需要加这个跨平台提交的参数
		conf.set("mapreduce.app-submission.cross-platform","true");
		
		Job job = Job.getInstance(conf);
		
		// 1、封装参数：jar包所在的位置
		job.setJar("d:/wc.jar");
		//job.setJarByClass(JobSubmitter.class);
		
		// 2、封装参数： 本次job所要调用的Mapper实现类、Reducer实现类
		job.setMapperClass(WordcountMapper.class);
		job.setReducerClass(WordcountReducer.class);
		
		// 3、封装参数：本次job的Mapper实现类、Reducer实现类产生的结果数据的key、value类型
		job.setMapOutputKeyClass(Text.class);
		job.setMapOutputValueClass(IntWritable.class);
		
		job.setOutputKeyClass(Text.class);
		job.setOutputValueClass(IntWritable.class);
		
		Path output = new Path("/wordcount/output");
		FileSystem fs = FileSystem.get(new URI("hdfs://hdp-01:9000"),conf,"root");
		if(fs.exists(output)){
			fs.delete(output, true);
		}
		
		// 4、封装参数：本次job要处理的输入数据集所在路径、最终结果的输出路径
		FileInputFormat.setInputPaths(job, new Path("/wordcount/input"));
		FileOutputFormat.setOutputPath(job, output);  // 注意：输出路径必须不存在
		
		// 5、封装参数：想要启动的reduce task的数量
		job.setNumReduceTasks(2);
		
		// 6、提交job给yarn
		boolean res = job.waitForCompletion(true);
		System.exit(res?0:-1);
	}
}
```

#### MR运作流程
##### 数据流  
- MR作业（JOB）是客户端需要执行的工作单元，它包含输入数据、MR程序和配置信息。Hadoop将作业分为若干个任务（task）来执行，
其中包含两类任务：map任务和reduce任务。这些任务运行在集群的节点上，并通过YARN进行资源调度，如果一个任务失败，它将
在另一个节点上自动重新调度运行。     
   
- Hadoop将MR的输入数据切割为等长大小的数据块，简称为[**分片**](#)。Hadoop为每一个数据分片构建一个map任务，并由它来运行用户
自定义的map函数，从而处理分片中的数据。      

- 拥有许多分片，意味着处理每个分片所需的时间少于处理整个输入数据所花的时间。因此，并行处理每个数据分片，且每个数据分片比较小，那么整个处理
过程将获得更好的负载均衡。——随着切片分得越细，负载均衡的效果就越好。    

- 另一方面，分片太小，以为构建的map任务数多，因此，管理分片的总时间和构建map任务的总时间成为决定作业的整个执行时间。
——合理的分片大小是：趋向于HDFS块大小，默认128M。是因为它确保可以存储在单个节点上的最大输入块的大小。如果分片跨越两个数据块，
那么对于任何一个HDFS节点（基本上不可能同时存储着着两个数据块），都需要网络传输数据。     

![image](img/older/hadoop/hadoop-mr-1.jpg)    
![image](img/older/hadoop/hadoop-mr-2.jpg)    
![image](img/older/hadoop/hadoop-mr-3.jpg)    

##### 任务执行流程
1、执行计算任务有两个角色一个是JobTracker，一个是TaskTracker，前者用于管理和调度工作，后者用于执行工作。  
2、一般来说一个Hadoop集群由一个JobTracker和N个TaskTracker构成。
3、可以理解为shuffle描述着Map task到Reduce task的整个过程。

- 每次的计算任务都分为两个阶段，一个Map阶段一个Reduce阶段。（shuffle阶段位于Map和Reduce的中间）

- Map阶段接收一组键值对形式的值<key,Value>，然后对这个输入进行处理并输出一组键值对形式的值    （map接收的数据是由InputFormat处理过的先spilt然后再生成键值对）

- Reduce接收Map输出的结果进行计算并输出（map过程产生的数据默认写入内存缓冲区，因为在内存里可以提高combine和sort的速度，默认的缓冲区的大小为100MB可以进行配置，但是当缓冲区的内存使用大于一定的值得时候会发生溢写，默认是使用率80%，一个后台的线程就会启动把缓冲区的数据写入到磁盘中，往内存中写入的线程会继续的执行）

- 当（Spill）写入线程启动后，会对这80MB空间内的key/value对进行sort。排序是MapReduce模型的默认行为，首先进行key排序，对于key相同的按照value进行排序。

- Combine（规约）发生在Spill的阶段本质上Combine就是Reduce，通过Combine可以减少输入reduce的数据量，优化MR的中间数据量

- 每次的Spill都会在本地声称一个Spill文件，如果map的数据量很大进行了多次的spill磁盘上对应的会有多个的spill文件存在、当map task 真正的完成的时候，内存缓冲区中的数据也会spill到本地磁盘上形成一个spill文件，所以磁盘上最少会有一个spill文件的存在，因为最终的文件只能有一个，所以需要把这些spill文件归并到一起，这个归并的过程叫做Merge

- Merger是把多个不同的spill文件合并到一个文件，所以可能会发生有相同的key的事情，如果这时候设置过Combiner就会直接用Combiner来合并相同的key

- reduce分为四个子阶段 ①从各个map task上读取相应的数据 ②sort ③执行reduce函数 ④把结果写到HDFS中

首先是客户端要编写好mapreduce程序，配置好mapreduce的作业也就是job，接下来就是提交job了，提交job是提交到JobTracker上的，这个时候JobTracker就会构建这个job，
具体就是分配一个新的job任务的ID值，接下来它会做检查操作，这个检查就是确定输出目录是否存在，如果存在那么job就不能正常运行下去，JobTracker会抛出错误给客户端，
接下来还要检查输入目录是否存在，如果不存在同样抛出错误，如果存在JobTracker会根据输入计算输入分片（Input Split），如果分片计算不出来也会抛出错误，至于输入分片我后面会做讲解的，
这些都做好了JobTracker就会配置Job需要的资源了。分配好资源后，JobTracker就会初始化作业，初始化主要做的是将Job放入一个内部的队列，让配置好的作业调度器能调度到这个作业，
作业调度器会初始化这个job，初始化就是创建一个正在运行的job对象（封装任务和记录信息），以便JobTracker跟踪job的状态和进程。初始化完毕后，作业调度器会获取输入分片信息（input split），
每个分片创建一个map任务。接下来就是任务分配了，这个时候tasktracker会运行一个简单的循环机制定期发送心跳给jobtracker，心跳间隔是5秒，程序员可以配置这个时间，
心跳就是jobtracker和tasktracker沟通的桥梁，通过心跳，jobtracker可以监控tasktracker是否存活，也可以获取tasktracker处理的状态和问题，同时tasktracker也可以通过心跳里的返回值获取jobtracker给它的操作指令。
任务分配好后就是执行任务了。在任务执行时候jobtracker可以通过心跳机制监控tasktracker的状态和进度，同时也能计算出整个job的状态和进度，
而tasktracker也可以本地监控自己的状态和进度。当jobtracker获得了最后一个完成指定任务的tasktracker操作成功的通知时候，jobtracker会把整个job状态置为成功，然后当客户端查询job运行状态时候（注意：这个是异步操作），
客户端会查到job完成的通知的。如果job中途失败，mapreduce也会有相应机制处理，一般而言如果不是程序员程序本身有bug，mapreduce错误处理机制都能保证提交的job能正常完成。   

##### 输入分片（input split）：
在进行map计算之前，mapreduce会根据输入文件计算输入分片（input split），每个输入分片（input split）针对一个map任务，输入分片（input split）存储的并非数据本身，
而是一个分片长度和一个记录数据的位置的数组，输入分片（input split）往往和hdfs的block（块）关系很密切，假如我们设定hdfs的块的大小是64mb，如果我们输入有三个文件，大小分别是3mb、65mb和127mb，
那么mapreduce会把3mb文件分为一个输入分片（input split），65mb则是两个输入分片（input split）而127mb也是两个输入分片（input split），
换句话说我们如果在map计算前做输入分片调整，例如合并小文件，那么就会有5个map任务将执行，而且每个map执行的数据大小不均，这个也是mapreduce优化计算的一个关键点。

##### map阶段：
就是程序员编写好的map函数了，因此map函数效率相对好控制，而且一般map操作都是本地化操作也就是在数据存储节点上进行；

##### combiner阶段：
combiner阶段是程序员可以选择的，combiner其实也是一种reduce操作，因此我们看见WordCount类里是用reduce进行加载的。
Combiner是一个本地化的reduce操作，它是map运算的后续操作，主要是在map计算出中间文件前做一个简单的合并重复key值的操作，
例如我们对文件里的单词频率做统计，map计算时候如果碰到一个hadoop的单词就会记录为1，但是这篇文章里hadoop可能会出现n多次，
那么map输出文件冗余就会很多，因此在reduce计算前对相同的key做一个合并操作，那么文件会变小，这样就提高了宽带的传输效率，
毕竟hadoop计算力宽带资源往往是计算的瓶颈也是最为宝贵的资源，但是combiner操作是有风险的，使用它的原则是combiner的输入不会影响到reduce计算的最终输入，
例如：如果计算只是求总数，最大值，最小值可以使用combiner，但是做平均值计算使用combiner的话，最终的reduce计算结果就会出错。

##### shuffle阶段：
将map的输出作为reduce的输入的过程就是shuffle了，这个是mapreduce优化的重点地方。这里我不讲怎么优化shuffle阶段，讲讲shuffle阶段的原理，因为大部分的书籍里都没讲清楚shuffle阶段。

Shuffle一开始就是map阶段做输出操作，一般mapreduce计算的都是海量数据，map输出时候不可能把所有文件都放到内存操作，因此map写入磁盘的过程十分的复杂，更何况map输出时候要对结果进行排序，
内存开销是很大的，map在做输出时候会在内存里开启一个`环形内存缓冲区`，这个缓冲区专门用来输出的，默认大小是`100MB`，并且在配置文件里为这个缓冲区设定了一个阀值，
默认是`0.80`（这个大小和阀值都是可以在配置文件里进行配置的），同时map还会为输出操作启动一个守护线程，如果缓冲区的内存达到了阀值的80%时候，这个守护线程就会把内容写到磁盘上，
这个过程叫`spill(溢写)`，另外的20%内存可以继续写入要写进磁盘的数据，写入磁盘和写入内存操作是互不干扰的，如果缓存区被撑满了，那么map就会阻塞写入内存的操作，
让写入磁盘操作完成后再继续执行写入内存操作。

前面我讲到写入磁盘前会有个排序操作，这个是在`写入磁盘操作前`进行，不是在写入内存时候进行的，如果我们定义了combiner函数，
那么排序前还会执行combiner操作。每次spill操作也就是写入磁盘操作时候就会写一个溢出文件，也就是说在做map输出有几次spill就会产生多少个溢出文件，等map输出全部做完后，
map会合并这些输出文件。这个过程里还会有一个Partitioner操作，对于这个操作很多人都很迷糊，其实Partitioner操作和map阶段的输入分片（Input split）很像，一个Partitioner对应一个reduce作业，
如果我们mapreduce操作只有一个reduce操作，那么Partitioner就只有一个，如果我们有多个reduce操作，那么Partitioner对应的就会有多个，Partitioner因此就是reduce的输入分片，
这个程序员可以编程控制，主要是根据实际key和value的值，根据实际业务类型或者为了更好的reduce负载均衡要求进行，这是提高reduce效率的一个关键所在。
到了reduce阶段就是合并map输出文件了，Partitioner会找到对应的map输出文件，然后进行复制操作，复制操作时reduce会开启几个复制线程，这些线程默认个数是5个，
程序员也可以在配置文件更改复制线程的个数，这个复制过程和map写入磁盘过程类似，也有阀值和内存大小，阀值一样可以在配置文件里配置，而内存大小是直接使用reduce的tasktracker的内存大小，
复制时候reduce还会进行排序操作和合并文件操作，这些操作完了就会进行reduce计算了。

- `input->split->recordReader->map函数->partition->spill(->sort->combiner)->map合并溢写小文件（默认80MB）->reduce复制文件->排序->合并-reduce函数->输出结果`

##### reduce阶段：和map函数一样也是程序员编写的，最终结果是存储在hdfs上的**（有多少个reduce进程任务就会产生多少个结果文件）**。

##### Mapreduce的相关问题
- **jobtracker的单点故障**：jobtracker和hdfs的namenode一样也存在单点故障，单点故障一直是hadoop被人诟病的大问题，为什么hadoop的做的文件系统和mapreduce计算框架都是高容错的，但是最重要的管理节点的故障机制却如此不好，
我认为主要是namenode和jobtracker在实际运行中都是在内存操作，而做到内存的容错就比较复杂了，只有当内存数据被持久化后容错才好做，namenode和jobtracker都可以备份自己持久化的文件，
但是这个持久化都会有延迟，因此真的出故障，任然不能整体恢复，另外hadoop框架里包含zookeeper框架，zookeeper可以结合jobtracker，用几台机器同时部署jobtracker，
保证一台出故障，有一台马上能补充上，不过这种方式也没法恢复正在跑的mapreduce任务。   

- **输出目录**：做mapreduce计算时候，输出一般是一个文件夹，而且该文件夹是不能存在，我在出面试题时候提到了这个问题，而且这个检查做的很早，当我们提交job时候就会进行，
mapreduce之所以这么设计是保证数据可靠性，如果输出目录存在reduce就搞不清楚你到底是要追加还是覆盖，不管是追加和覆盖操作都会有可能导致最终结果出问题，
mapreduce是做海量数据计算，一个生产计算的成本很高，例如一个job完全执行完可能要几个小时，因此一切影响错误的情况mapreduce是零容忍的

- **格式化输入/输出**：Mapreduce还有一个InputFormat和OutputFormat，我们在编写map函数时候发现map方法的参数是之间操作行数据，没有牵涉到InputFormat，这些事情在我们new Path时候mapreduce计算框架帮我们做好了，
而OutputFormat也是reduce帮我们做好了，我们使用什么样的输入文件，就要调用什么样的InputFormat，InputFormat是和我们输入的文件类型相关的，mapreduce里常用的InputFormat有FileInputFormat普通文本文件，
SequenceFileInputFormat是指hadoop的序列化文件，另外还有KeyValueTextInputFormat。OutputFormat就是我们想最终存储到hdfs系统上的文件格式了，这个根据你需要定义了，hadoop有支持很多文件格式。

##### 优化方案
- 数据本地化策略：Hadoop在存储有输入数据的（HDFS的数据）的节点上运行map任务，可以获得最佳的性能，因为它无需使用宝贵的集群带宽资源。     

- combiner函数：Combiner函数，在Map运算结束后类似于先在Map计算节点进行一次Reduce计算，减少数据传输量。在MapReduce中，当map生成的数据过大时，带宽就成了瓶颈，
当在发送给 Reduce 时对数据进行一次本地合并，减少数据传输量以提高网络IO性能。   

[**【Hadoop 中的 Combiner 过程】**](https://blog.csdn.net/u011007180/article/details/52495191) 
![image](img/older/hadoop/42.png)  
![image](img/older/hadoop/43.png)  
![image](img/older/hadoop/44.png)  
![image](img/older/hadoop/45.png)  
![image](img/older/hadoop/46.png)  
![image](img/older/hadoop/47.png)  
![image](img/older/hadoop/48.png)  
>>>>>>> 9e9ce05fb213fbbcbd3ec27310e657cec97881c5
![image](img/older/hadoop/49.png)  