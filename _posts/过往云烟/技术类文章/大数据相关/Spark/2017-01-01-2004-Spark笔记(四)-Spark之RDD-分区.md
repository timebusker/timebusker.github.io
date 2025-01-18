---
layout:     post
title:      Spark笔记(四)-Spark之RDD-分区
date:       2018-06-25
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Spark
---

#### 基础知识
分区是RDD内部并行计算的一个计算单元，RDD的数据集在逻辑上被划分为多个分片，每一个分片称为分区，分区的格式决定了并行计算的粒度，
而每个分区的数值计算都是在一个任务中进行的，因此任务的个数，也是由RDD(准确来说是作业最后一个RDD)的分区数决定。

#### 为什么要进行分区
数据分区，在分布式集群里，网络通信的代价很大，减少网络传输可以极大提升性能。mapreduce框架的性能开支主要在io和网络传输，io因为要大量读写文件，
它是不可避免的，但是网络传输是可以避免的，把大文件压缩变小文件，从而减少网络传输，但是增加了cpu的计算负载。

Spark里面io也是不可避免的，但是网络传输spark里面进行了优化：

Spark把rdd进行分区（分片），放在集群上并行计算。同一个rdd分片100个，10个节点，平均一个节点10个分区，当进行sum型的计算的时候，先进行每个分区的sum，然后把sum值shuffle传输到主程序进行全局sum，
所以进行sum型计算对网络传输非常小。但对于进行join型的计算的时候，需要把数据本身进行shuffle，网络开销很大。spark是如何优化这个问题的呢？

Spark把key－value rdd通过key的hashcode进行分区，而且保证相同的key存储在同一个节点上，这样对改rdd进行key聚合时，就不需要shuffle过程，我们进行mapreduce计算的时候为什么要进行shuffle？
就是说mapreduce里面网络传输主要在shuffle阶段，shuffle的根本原因是相同的key存在不同的节点上，按key进行聚合的时候不得不进行shuffle。shuffle是非常影响网络的，它要把所有的数据混在一起走网络，
然后它才能把相同的key走到一起。要进行shuffle是存储决定的。

Spark从这个教训中得到启发，spark会把key进行分区，也就是key的hashcode进行分区，相同的key，hashcode肯定是一样的，所以它进行分区的时候100t的数据分成10分，每部分10个t，
它能确保相同的key肯定在一个分区里面，而且它能保证存储的时候相同的key能够存在同一个节点上。比如一个rdd分成了100份，集群有10个节点，所以每个节点存10份，每一分称为每个分区，
spark能保证相同的key存在同一个节点上，实际上相同的key存在同一个分区。

key的分布不均决定了有的分区大有的分区小。没法分区保证完全相等，但它会保证在一个接近的范围。所以mapreduce里面做的某些工作里边，spark就不需要shuffle了，spark解决网络传输这块的根本原理就是这个。

进行join的时候是两个表，不可能把两个表都分区好，通常情况下是把用的频繁的大表事先进行分区，小表进行关联它的时候小表进行shuffle过程。

需要在工作节点间进行数据混洗的转换极大地受益于分区。这样的转换是`cogroup`，`groupWith`，`join`，`leftOuterJoin`，`rightOuterJoin`，`groupByKey`，`reduceByKey`，`combineByKey`和`lookup`。



#### Spark分区原则及方法

RDD分区的一个分区原则：`尽可能是得分区的个数等于集群cpu core数目`

无论是本地模式、Standalone模式、YARN模式或Mesos模式，我们都可以通过`spark.default.parallelism`来配置其默认分区个数，若没有设置该值，则根据不同的集群环境确定该值

`partition`是`RDD`的最小数据处理单元，可以看作是一个数据块，每个`partition`有个编号`index`。一个`partition`被一个`map task`处理。

> `spark.default.parallelism`，默认的并发数（默认值`2`）

当配置文件spark-default.conf中没有显示的配置，则按照如下规则取值：

##### 本地模式
该模式下，不会启动executor，由SparkSubmit进程生成指定数量的线程数来并发。

```
spark-shell spark.default.parallelism = 1

spark-shell --master local[N] spark.default.parallelism = N （使用N个核）

spark-shell --master local spark.default.parallelism = 1
```

##### 伪集群模式
x为本机上启动的executor数，y为每个executor使用的core数，z为每个 executor使用的内存

```
spark-shell --master local-cluster[x,y,z] spark.default.parallelism = x*y
```

##### yarn/standalone模式

```
#  Others: total number of cores on all executor nodes or 2, whichever is larger
spark.default.parallelism =  max（所有executor使用的core总数， 2）
```

经过上面的规则，就能确定了spark.default.parallelism的默认值（前提是配置文件spark-default.conf中没有显示的配置，如果配置了，则spark.default.parallelism = 配置的值）

还有一个配置比较重要，spark.files.maxPartitionBytes = 128 M（默认）
The maximum number of bytes to pack into a single partition when reading files.
代表着rdd的一个分区能存放数据的最大字节数，如果一个400m的文件，只分了两个区，则在action时会发生错误。

当一个spark应用程序执行时，生成sparkContext，同时会生成两个参数，由上面得到的spark.default.parallelism推导出这两个参数的值

```
sc.defaultParallelism     = spark.default.parallelism

sc.defaultMinPartitions = min(spark.default.parallelism,2)
```

`当sc.defaultParallelism和sc.defaultMinPartitions最终确认后，就可以推算rdd的分区数了。`

> `RDD分区的数据取决于哪些因素？`
- 如果是将Driver端的Scala集合并行化创建RDD，并且没有指定RDD的分区，RDD的分区就是为该app分配的核数

- 如果是重hdfs中读取数据创建RDD，并且设置了最新分区数量是1，那么RDD的分区数据即使输入切片的数据，
  如果不设置最小分区的数量，即spark调用textFile时会默认传入2，那么RDD的分区数量会打于等于输入切片的数量
  
- Spark 2.3.X版本对分区有负载优化操作，对所有数据量求平均值，针对异常较大数据块进行二次切割（逻辑切割）计算

#### 分区器(partitioner)

MR任务的map阶段的处理结果会进行分片（也可以叫分区，这个分区不同于上面的分区），分片的数量就是reduce task的数量。

spark中默认定义了两种partitioner：
- 哈希分区器（Hash Partitioner）
hash分区器会根据key-value的键值key的hashcode进行分区，速度快，但是可能产生数据偏移，造成每个分区中数据量不均衡。

- 范围分区器（Range Partitioner）
range分区器会对现有rdd中的key-value数据进行抽样，尽量找出均衡分割点，一定程度上解决了数据偏移问题，力求分区后的每个分区内数据量均衡，但是速度相对慢。

##### partitioner分区详情
`在对父RDD执行完Map阶段任务后和在执行Reduce阶段任务前`，会对Map阶段中间结果进行分区。分区由父RDD的partitioner确定，主要包括两部分工作：
- 确定分区数量（也就是reduce task数量），也是子RDD的partition数量。
- 决定将Map阶段中间结果的每个key-value对分到哪个分区上。

假设一个父RDD要执行reduceByKey任务，我们可以显式的指定分区器：

```
val rdd_child = rdd_parent.reduceByKey(new HashPartitioner(3), _+_)
```

HashPartitioner构造参数3就是分区数量，也是启动的reduce task数量，也是reduceByKey结果返回的子RDD的partitions方法返回的数组的长度。

如果没有显式指定分区器，则会调用org.apache.spark包下伴生对象Partitioner的defaultPartitioner静态方法返回的分区器作为默认分区器。

- defaultPartitioner返回默认分区器的过程如下：

尝试利用`父RDD`的partitioner，如果父RDD没有partitioner，则会查看sparkConf中是否定义了`spark.default.parallelism`配置参数，
如果定义了就返回`new HashPartitioner(sc.defaultParallelism)`作为默认分区器，
如果没定义就返回`new HashPartitioner(rdd_parent.partitions.length)`作为默认分区器。

```
//org.apache.spark包下伴生对象object Partitioner的方法
def defaultPartitioner(rdd: RDD[_], others: RDD[_]*): Partitioner = {
  val rdds = (Seq(rdd) ++ others)
  val hasPartitioner = rdds.filter(_.partitioner.exists(_.numPartitions > 0))
  if (hasPartitioner.nonEmpty) {
    hasPartitioner.maxBy(_.partitions.length).partitioner.get
  } else {
    if (rdd.context.conf.contains("spark.default.parallelism")) {
      new HashPartitioner(rdd.context.defaultParallelism)
    } else {
      new HashPartitioner(rdds.map(_.partitions.length).max)
    }
  }
}
```

无论是以本地模式、Standalone 模式、Yarn 模式或者是 Mesos 模式来运行 Apache Spark，
分区的默认个数等于对spark.default.parallelism的指定值，若该值未设置，则 Apache Spark 会根据不同集群模式的特征，来确定这个值。

##### 自定义分区
继承`Partitioner`,需要实现`numPartitions`,`getPartition`2个方法。

```
class MyPartitoiner(val numParts:Int) extends  Partitioner{
  override def numPartitions: Int = numParts
  override def getPartition(key: Any): Int = {
    val domain = new URL(key.toString).getHost
    val code = (domain.hashCode % numParts)
    if (code < 0) {
      code + numParts
    } else {
      code
    }
  }
}

object DomainNamePartitioner {
  def main(args: Array[String]): Unit = {
    val conf = new SparkConf().setAppName("word count").setMaster("local")

    val sc = new SparkContext(conf)

    val urlRDD = sc.makeRDD(Seq(("http://baidu.com/test", 2),
      ("http://baidu.com/index", 2), ("http://ali.com", 3), ("http://baidu.com/tmmmm", 4),
      ("http://baidu.com/test", 4)))
    //Array[Array[(String, Int)]]
    // = Array(Array(),
    // Array((http://baidu.com/index,2), (http://baidu.com/tmmmm,4),
    // (http://baidu.com/test,4), (http://baidu.com/test,2), (http://ali.com,3)))
    val hashPartitionedRDD = urlRDD.partitionBy(new HashPartitioner(2))
    hashPartitionedRDD.glom().collect()

    //使用spark-shell --jar的方式将这个partitioner所在的jar包引进去，然后测试下面的代码
    // spark-shell --master spark://master:7077 --jars spark-rdd-1.0-SNAPSHOT.jar
    val partitionedRDD = urlRDD.partitionBy(new MyPartitoiner(2))
    val array = partitionedRDD.glom().collect()

  }
}
```

