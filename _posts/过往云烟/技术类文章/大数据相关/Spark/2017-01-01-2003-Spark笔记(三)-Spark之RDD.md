---
layout:     post
title:      Spark笔记(三)-Spark之RDD
date:       2018-06-25
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Spark
---

#### RDD的概述

- `RDD`（Resilient Distributed Dataset）叫做`弹性分布式数据集`，是Spark中最基本的`数据抽象`，它代表一个`不可变`、`可分区`、里面的元素`可并行计算`的集合。
  
- RDD具有数据流模型的特点：`自动容错`、`位置感知性调度`和`可伸缩性`。RDD允许用户在执行多个查询时显式地将工作集缓存在内存中，后续的查询能够重用工作集，这极大地提升了查询速度。

##### RDD的属性

- `一组分片（Partition）`，即数据集的基本组成单位。对于RDD来说，每个分片都会被一个计算任务处理，并决定并行计算的粒度。
  用户可以在创建RDD时指定RDD的分片个数，如果没有指定，那么就会采用默认值。默认值就是程序所分配到的`CPU Core的数目`。

- `一个计算每个分区的函数`。Spark中RDD的计算是以`分片为单位`的，每个RDD都会实现compute函数以达到这个目的。
  compute函数会对迭代器进行复合，不需要保存每次计算的结果。

- `RDD之间的依赖关系`。RDD的每次转换都会生成一个新的RDD，所以RDD之间就会形成类似于流水线一样的前后依赖关系。
   在部分分区数据丢失时，Spark可以通过这个依赖关系重新计算丢失的分区数据，而不是对RDD的所有分区进行重新计算。

- `一个Partitioner`，即RDD的`分片函数`。当前Spark中实现了两种类型的分片函数，一个是基于哈希的HashPartitioner，
   另外一个是基于范围的RangePartitioner。只有对于key-value的RDD，才会有Partitioner，非key-value的RDD的Parititioner的值是None。
   Partitioner函数不但决定了RDD本身的分片数量，也决定了parent RDD Shuffle输出时的分片数量。

- `一个列表`，存储存取每个Partition的优先位置（preferred location）。对于一个HDFS文件来说，
  这个列表保存的就是每个Partition所在的块的位置。按照“移动数据不如移动计算”的理念，Spark在进行任务调度的时候，
  会尽可能地将计算任务分配到其所要处理数据块的存储位置。
  
#### 图解wordCount-RDD

```
sc.textFile("/spark/hello.txt").flatMap(_.split(",")).map((_,1)).reduceByKey(_+_).saveAsTextFile("/spark/out")

# sc是SparkContext对象，该对象是提交spark程序的入口
# textFile("/spark/hello.txt")是hdfs中读取数据
# flatMap(_.split(" "))先map再压平
# map((_,1))将单词和1构成元组
# reduceByKey(_+_)按照key进行reduce，并将value累加
# saveAsTextFile("/spark/out")将结果写入到hdfs中
```

![图解wordCount-RDD](img/older/spark/3/1.png)

#### RDD的创建

- 通过读取文件生成的

`Hadoop文件系统读取：sc.textFile("hdfs:///spark/data")`

`本地文件系统读取：sc.textFile("file:///spark/data")`


由外部存储系统的数据集创建，包括`本地`的文件系统，还有所有`Hadoop`支持的数据集，比如HDFS、Cassandra、HBase等

- 通过并行化的方式创建RDD

```
# 由一个已经存在的Scala集合创建。

val array = Array(1,2,3,4,5)
val rdd = sc.parallelize(array)
```

- 其他方式

> 读取数据库等等其他的操作。也可以生成RDD。

> RDD可以通过其他的RDD转换而来的。

### RDD编程API

Spark支持两个类型（算子）操作：Transformation和Action

#### Transformation
将一个已有的RDD生成另外一个RDD。Transformation具有lazy特性(延迟加载)。Transformation算子的代码不会真正被执行。
只有当我们的程序里面遇到一个action算子的时候，代码才会真正的被执行。这种设计让Spark更加有效率地运行。

> 常用的Transformation

|:------:|:-------|
|**转换**|**含义**|
|map(func)|返回一个新的RDD，该RDD由每一个输入元素经过func函数转换后组成|
|filter(func)|返回一个新的RDD，该RDD由经过func函数计算后返回值为true的输入元素组成|
|flatMap(func)|类似于map，但是每一个输入元素可以被映射为0或多个输出元素（所以func应该返回一个序列，而不是单一元素）|
|mapPartitions(func)|类似于map，但独立地在RDD的每一个分片上运行，因此在类型为T的RDD上运行时，func的函数类型必须是Iterator[T] => Iterator[U]|
|mapPartitionsWithIndex(func)|类似于mapPartitions，但func带有一个整数参数表示分片的索引值，因此在类型为T的RDD上运行时，func的函数类型必须是(Int, Interator[T]) => Iterator[U]|
|sample(withReplacement, fraction, seed)|根据fraction指定的比例对数据进行采样，可以选择是否使用随机数进行替换，seed用于指定随机数生成器种子|
|union(otherDataset)|对源RDD和参数RDD求并集后返回一个新的RDD|
|intersection(otherDataset)|对源RDD和参数RDD求交集后返回一个新的RDD|
|distinct([numTasks]))|distinct([numTasks]))|
|groupByKey([numTasks])|在一个(K,V)的RDD上调用，返回一个(K, Iterator[V])的RDD|
|reduceByKey(func, [numTasks])|在一个(K,V)的RDD上调用，返回一个(K,V)的RDD，使用指定的reduce函数，将相同key的值聚合到一起，与groupByKey类似，reduce任务的个数可以通过第二个可选的参数来设置|
|aggregateByKey(zeroValue)(seqOp, combOp, [numTasks])|先按分区聚合 再总的聚合   每次要跟初始值交流 例如：aggregateByKey(0)(_+_,_+_) 对k/y的RDD进行操作|
|sortByKey([ascending], [numTasks])|在一个(K,V)的RDD上调用，K必须实现Ordered接口，返回一个按照key进行排序的(K,V)的RDD|
|sortBy(func,[ascending], [numTasks])|与sortByKey类似，但是更灵活 第一个参数是根据什么排序  第二个是怎么排序 false倒序   第三个排序后分区数  默认与原RDD一样|
|join(otherDataset, [numTasks])|在类型为(K,V)和(K,W)的RDD上调用，返回一个相同key对应的所有元素对在一起的(K,(V,W))的RDD  相当于内连接（求交集）|
|cogroup(otherDataset, [numTasks])|在类型为(K,V)和(K,W)的RDD上调用，返回一个(K,(Iterable<V>,Iterable<W>))类型的RDD|
|cartesian(otherDataset)|两个RDD的笛卡尔积  的成很多个K/V|
|pipe(command, [envVars])|调用外部程序|
|coalesce(numPartitions)|重新分区 第一个参数是要分多少区，第二个参数是否shuffle 默认false  少分区变多分区 true   多分区变少分区 false|
|repartition(numPartitions)|重新分区 必须shuffle  参数是要分多少区  少变多|
|repartitionAndSortWithinPartitions(partitioner)|重新分区+排序  比先分区再排序效率高  对K/V的RDD进行操作|
|foldByKey(zeroValue)(seqOp)|该函数用于K/V做折叠，合并处理 ，与aggregate类似   第一个括号的参数应用于每个V值  第二括号函数是聚合例如：_+_|
|combineByKey|合并相同的key的值 rdd1.combineByKey(x => x, (a: Int, b: Int) => a + b, (m: Int, n: Int) => m + n)|
|partitionBy（partitioner）|对RDD进行分区  partitioner是分区器 例如new HashPartition(2)|
|cache、persist|RDD缓存，可以避免重复计算从而减少时间，区别：cache内部调用了persist算子，cache默认就一个缓存级别MEMORY-ONLY ，而persist则可以选择缓存级别|
|Subtract（rdd）|返回前rdd元素不在后rdd的rdd|
|leftOuterJoin|leftOuterJoin类似于SQL中的左外关联left outer join，返回结果以前面的RDD为主，关联不上的记录为空。只能用于两个RDD之间的关联，如果要多个RDD关联，多关联几次即可。|
|rightOuterJoin|rightOuterJoin类似于SQL中的有外关联right outer join，返回结果以参数中的RDD为主，关联不上的记录为空。只能用于两个RDD之间的关联，如果要多个RDD关联，多关联几次即可|
|subtractByKey|substractByKey和基本转换操作中的subtract类似只不过这里是针对K的，返回在主RDD中出现，并且不在otherRDD中出现的元素|


#### Action

触发代码的运行，我们一段spark代码里面至少需要有一个action操作。

> 常用的Action

|:------:|:-------|
|**动作**|**含义**|
|**reduce(func)**|***通过func函数聚集RDD中的所有元素，这个功能必须是课交换且可并联的***|
|**collect()**|***在驱动程序中，以数组的形式返回数据集的所有元素***|
|**count()**|***返回RDD的元素个数***|
|**first()**|***返回RDD的第一个元素（类似于take(1)）***|
|**take(n)**|***返回一个由数据集的前n个元素组成的数组***|
|**takeSample(withReplacement,num, [seed])**|***返回一个数组，该数组由从数据集中随机采样的num个元素组成，可以选择是否用随机数替换不足的部分，seed用于指定随机数生成器种子***|
|**takeOrdered(n, [ordering])**|***--***|
|**saveAsTextFile(path)**|***将数据集的元素以textfile的形式保存到HDFS文件系统或者其他支持的文件系统，对于每个元素，Spark将会调用toString方法，将它装换为文件中的文本***|
|**saveAsSequenceFile(path)**|***将数据集中的元素以Hadoop sequencefile的格式保存到指定的目录下，可以使HDFS或者其他Hadoop支持的文件系统。***|
|**saveAsObjectFile(path)**|***--***|
|**countByKey()**|***针对(K,V)类型的RDD，返回一个(K,Int)的map，表示每一个key对应的元素个数。***|
|**foreach(func)**|***在数据集的每一个元素上，运行函数func进行更新。***|
|**aggregate**|***先对分区进行操作，在总体操作***|
|**reduceByKeyLocally**|***含义***|
|**lookup**|***含义***|
|**top**|***含义***|
|**fold**|***含义***|
|**foreachPartition**|***含义***|


#### Spark WordCount代码编写


#### RDD的宽依赖和窄依赖

- RDD的宽依赖和窄依赖

由于RDD是粗粒度的操作数据集，每个Transformation操作都会生成一个新的RDD，所以RDD之间就会形成类似流水线的前后依赖关系；
RDD和它依赖的父RDD（s）的关系有两种不同的类型，即窄依赖（narrow dependency）和宽依赖（wide dependency）。如图所示显示了RDD之间的依赖关系。

![RDD的宽依赖和窄依赖](img/older/spark/3/2.png)

> 窄依赖：
是指每个父RDD的一个Partition最多被子RDD的一个Partition所使用，例如map、filter、union等操作都会产生窄依赖；（`分区-独生子女`）

> 宽依赖：
是指一个父RDD的Partition会被多个子RDD的Partition所使用，例如groupByKey、reduceByKey、sortByKey等操作都会产生宽依赖；（`分区-超生`）

- 需要特别说明的是对join操作有两种情况：
图中左半部分join：如果两个RDD在进行join操作时，一个RDD的partition仅仅和另一个RDD中已知个数的Partition进行join，
那么这种类型的join操作就是窄依赖，例如图中左半部分的join操作(join with inputs co-partitioned)；

图中右半部分join：其它情况的join操作就是宽依赖,例如图1中右半部分的join操作(join with inputs not co-partitioned)，
由于是需要父RDD的所有partition进行join的转换，这就涉及到了shuffle，因此这种类型的join操作也是宽依赖。

##### 总结
- 窄依赖不仅包含一对一的窄依赖，还包含一对固定个数的窄依赖。

- 宽依赖是shuffle级别的，数据量越大，那么子RDD所依赖的父RDD的个数就越多，从而子RDD所依赖的父RDD的partition的个数也会变得越来越多。

#### 依赖关系下的数据流视图

![RDD的宽依赖和窄依赖](img/older/spark/3/3.png)

在spark中，会根据RDD之间的依赖关系将DAG图（有向无环图）划分为不同的阶段，对于窄依赖，由于partition依赖关系的确定性，
partition的转换处理就可以在同一个线程里完成，窄依赖就被spark划分到同一个stage中，而对于宽依赖，只能等父RDD shuffle处理完成后，
下一个stage才能开始接下来的计算。

因此spark划分stage的整体思路是：从后往前推，遇到宽依赖就断开，划分为一个stage；遇到窄依赖就将这个RDD加入该stage中。
因此在图2中`RDD-C`,`RDD-D`,`RDD-E`,`RDD-F`被构建在一个stage中,`RDD-A`被构建在一个单独的Stage中,而`RDD-B`和`RDD-G`又被构建在同一个stage中。

在spark中，Task的类型分为2种：`ShuffleMapTask`和`ResultTask`；

简单来说，DAG的最后一个阶段会为每个结果的partition生成一个ResultTask，即每个Stage里面的Task的数量是由该Stage中最后一个RDD的Partition的数量所决定的！
而其余所有阶段都会生成ShuffleMapTask；之所以称之为ShuffleMapTask是因为它需要将自己的计算结果通过shuffle到下一个stage中；
也就是说上图中的stage1和stage2相当于mapreduce中的Mapper,而ResultTask所代表的stage3就相当于mapreduce中的reducer。

在之前动手操作了一个wordcount程序，因此可知，Hadoop中MapReduce操作中的Mapper和Reducer在spark中的基本等量算子是map和reduceByKey;
不过区别在于：Hadoop中的MapReduce天生就是排序的；而reduceByKey只是根据Key进行reduce，但spark除了这两个算子还有其他的算子；
因此从这个意义上来说，Spark比Hadoop的计算算子更为丰富。
