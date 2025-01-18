---
layout:     post
title:      Spark笔记(五)-Spark之RDD-算子API使用（一）
date:       2018-06-25
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Spark
---

### Transformation算子
#### map(func())
**对于多层集合嵌套，需要确保`函数`能够处理当前迭代元素**

> 输入分区与输出分区一对一，即：有多少个输入分区，就有多少个输出分区。

接收一个函数，对于RDD中的每一个元素执行此函数操作，结果返回到原集合中。

```
// 单层集合
val rdd = sc.parallelize(Array(1, 2, 3, 4)) 
rdd.map(x => x*x).foreach(println) 
// 1 4 9 16

# 多层嵌套
val rdd = sc.parallelize(List(Array(1, 2, 3, 4),Array(5, 6, 7, 8),Array(9, 10, 11, 12))) 
rdd.map(_.map(x=>x*x)).foreach(_.foreach(println))
// Array[Array[Int]] = Array(Array(1, 4, 9, 16), Array(25, 36, 49, 64), Array(81, 100, 121, 144))
```

#### flatMap(func())
**对于多层集合嵌套，需要确保`函数`能够处理当前迭代元素**

接收一个函数，对于RDD中的每一个元素执行此函数操作，结果统一返回到新RDD`一维集合`中，故功能与`map(func())`类似，新增`打平`集合功能。

`仅支持打平两层集合嵌套关系`

```
val rdd = sc.parallelize(List(Array(1, 2, 3, 4),Array(5, 6, 7, 8),Array(9, 10, 11, 12))) 
rdd.map(_.map(x=>x*x)).collect
// Array[Array[Int]] = Array(Array(1, 4, 9, 16), Array(25, 36, 49, 64), Array(81, 100, 121, 144))
rdd.flatMap(_.map(y=>y+y)).collect
// Array[Int] = Array(2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24)
rdd.flatMap(_.map(y=>y+y)).mapPartitionsWithIndex((k,v)=>(v.map(x=>(k + "#" + x))))


val rdd = sc.parallelize(List(Array(Array(1, 2),Array(3, 4),Array(5, 6)),Array(Array(7, 8),Array(9 ,10),Array(11, 12)))) 
rdd.map(_.map(x=>x.map(y=>y*y))).collect
// Array[Array[Array[Int]]] = Array(Array(Array(1, 4), Array(9, 16), Array(25, 36)), Array(Array(49, 64), Array(81, 100), Array(121, 144)))

rdd.flatMap(_.map(x=>x.map(y=>y*y))).collect
// res20: Array[Array[Int]] = Array(Array(1, 4), Array(9, 16), Array(25, 36), Array(49, 64), Array(81, 100), Array(121, 144))
```

#### mapPartitions(func())
**以分区作为数据输入，针对RDD分区的、类似map(func())的计算方式**

```
# 指定并行化处理的RDD分区数为3
val rdd = sc.parallelize(1 to 10,3)

# 以RDD的每个元素作为输入
rdd.map(x=>x+10).collect

# 以RDD的每个分区作为输入
rdd.mapPartitions(_.map(x=>x+10)).collect
```

#### mapPartitionsWithIndex(func(key,value))
是`mapPartitions(func())`的扩展，以`分区序号、分区数据作为函数输入`，类似map(func())的计算方式

```
# 初始化RDD
val rdd = sc.parallelize(1 to 5,3)

# 返回分区号与分区数据的拼接字符串
rdd.mapPartitionsWithIndex((k,v)=>{v.map(x=> (k + "#" + x))}).collect
// Array[String] = Array(0#1, 1#2, 1#3, 2#4, 2#5)

# 另一种实现形式：
rdd.mapPartitionsWithIndex((x,iterator)=>{
        var result=List[String]()
        while (iterator.hasNext){
          result ::=(x+"-"+iterator.next())
        }
        result.toIterator
    }).foreach(println)
```

#### filter(func())
接收一个返回值为布尔类型的方法，以RDD元素作为输入，返回为true的数据并组成一个新的RDD

```
# 初始化RDD
val rdd = sc.parallelize(1 to 13,3)
# 对元素进行3求余，返回余数大于1的
rdd.filter(x=>x%3>1).collect
# Array[Int] = Array(2, 5, 8, 11, 14, 17, 20)
```

#### union(RRD[T])

两个RDD`并集运算`，生成一个新的RDD，新的RDD分区数为`两个RDD分区数之和`。

```
val rdd1 = sc.parallelize(1 to 5,3)
val rdd2 = sc.parallelize(3 to 7,4)
val rdd3 = rdd1.union(rdd2)
rdd3.mapPartitionsWithIndex((k,v)=>{v.map(x=> (k + "#" + x))}).collect
```

#### intersection(RRD[T])

两个RDD`交集运算`**并去重**，生成一个新的RDD，新的RDD的分区默认为max(rdd1分区，rdd2分区)，可以手动指定分区数。

```
val rdd1 = sc.parallelize(1 to 5,5)
val rdd2 = sc.parallelize(3 to 7,4)
val rdd3 = rdd1.intersection(rdd2)
rdd3.mapPartitionsWithIndex((k,v)=>{v.map(x=> (k + "#" + x))}).collect
```

#### subtract(RRD[T])

两个RDD`差集运算`，生成一个新的RDD，新的RDD默认分区数为调该方法的RDD的分区数，也可以指定。

```
val rdd1 = sc.parallelize(1 to 5,5)
val rdd2 = sc.parallelize(3 to 7,6)
val rdd3 = rdd1.subtract(rdd2)
rdd3.mapPartitionsWithIndex((k,v)=>{v.map(x=> (k + "#" + x))}).collect
```

#### zipWithUniqueId()/zipWithIndex()
返回一个键值对的RDD，`键为元素，值为下标`。zipWithIndex()的值是从0到RDD元素数-1，而zipWithUniqueId()的值不受为RDD元素数-1的约束，确保下标唯一。

```
val rdd1 = sc.parallelize(List(Array(1,2,3,4,5),Array(3,4,5,6,7)),5)
val rdd2 = rdd1.flatMap(_.map(x=>x)).collect

val rdd = sc.parallelize(Array(1, 2, 3, 4, 5, 3, 4, 5, 6, 7))

rdd2.zipWithUniqueId.collect
rdd2.zipWithIndex.collect
```

#### zip()

zip函数用于将两个RDD组合成`Key/Value`形式的RDD,默认两个RDD的`partition数量`以及`元素数量`都相同，否则会抛出异常。

```
var rdd1 = sc.makeRDD(1 to 5,2)
var rdd2 = sc.makeRDD(Seq("A","B","C","D","E"),2)
val rdd3 = rdd1.zip(rdd2)
```

#### zipPartitions()

zipPartitions函数将多个RDD按照partition组合成为新的RDD，该函数需要组合的RDD具有相同的分区数，但对于每个分区内的元素数量没有要求。

`def zipPartitions[B, V](rdd: RDD[B], preservesPartitioning: Boolean)`
- 输入参数RDD表示需要合并的RDD
- 输入参数Boolean表示是否保留父RDD的partitioner分区信息`可选、有两种实现`

```
var rdd1 = sc.makeRDD(1 to 6,2)
var rdd2 = sc.makeRDD(Seq("A","B","C","D","E"),2)

rdd1.mapPartitionsWithIndex((k,v)=>(v.map(x=>(k + "#" + x)))).collect
rdd2.mapPartitionsWithIndex((k,v)=>(v.map(x=>(k + "#" + x)))).collect

rdd1.zipPartitions(rdd2,true)((rdd1Iterator,rdd2Iterator)=>{
    var result = List[String]()
    while(rdd1Iterator.hasNext && rdd2Iterator.hasNext) {
      result::=(rdd1Iterator.next() + "_" + rdd2Iterator.next())
    }
    result.iterator
}).collect

rdd1.zipPartitions(rdd2)((rdd1Iterator,rdd2Iterator)=>{
    var result = List[String]()
    while(rdd1Iterator.hasNext && rdd2Iterator.hasNext) {
      result::=(rdd1Iterator.next() + "_" + rdd2Iterator.next())
    }
    result.iterator
}).collect
```

#### foreach(func())

遍历RDD元素，按照`func()`函数做映射操作，无返回值，一般使用在调试阶段。

```
val rdd = sc.parallelize(Array(1, 2, 3, 4, 5, 3, 4, 5, 6, 7))
rdd.foreach(println)
```

#### coalesce/repartition
该函数用于将RDD进行重分区，使用HashPartitioner。第一个参数为重分区的数目，第二个为是否进行shuffle，默认为false;如果重分区的数目大于原来的分区数，那么必须指定shuffle参数为true,否则不起作用。

窄依赖自动收缩分区数，不会发生shuffle。宽依赖需要shuffle过程收缩分区。

repartition是coalesce函数第二个参数为true的实现

```
val rdd = sc.parallelize(Array(1, 2, 3, 4, 5, 3, 4, 5, 6, 7),5)
rdd.coalesce(4,true)

rdd.repartition(4)
```

#### foldByKey

```
def foldByKey(zeroValue: V)(func: (V, V) => V): RDD[(K, V)]

def foldByKey(zeroValue: V, numPartitions: Int)(func: (V, V) => V): RDD[(K, V)]

def foldByKey(zeroValue: V, partitioner: Partitioner)(func: (V, V) => V): RDD[(K, V)]
```

该函数用于RDD[K,V]根据K将V做折叠、合并处理，其中的参数zeroValue表示先根据映射函数将zeroValue应用于V,进行初始化V,再将映射函数应用于初始化后的V.

```
var rdd1 = sc.makeRDD(Array(("A",0),("A",2),("B",1),("B",2),("C",1)))
rdd1.foldByKey(0)(_+_).collect
// Array[(String, Int)] = Array((A,2), (B,3), (C,1))
rdd1.foldByKey(0)(_+_).collect
// Array[(String, Int)] = Array((A,2), (B,3), (C,1))

// 可参考action类fold算子计算过程
//将rdd1中每个key对应的V进行累加，注意zeroValue=0,需要先初始化V,映射函数为+操
//作，比如("A",0), ("A",2)，先将zeroValue应用于每个V,得到：("A",0+0), ("A",2+0)，即：
//("A",0), ("A",2)，再将映射函数应用于初始化后的V，最后得到(A,0+2),即(A,2)
```

#### partitionBy
`def partitionBy(partitioner: Partitioner): RDD[(K, V)]`

根据partitioner函数生成新的ShuffleRDD，将原RDD重新分区。

```
var rdd1 = sc.makeRDD(Array((1,"A"),(2,"B"),(3,"C"),(4,"D")),2)
rdd1.partitions.size
rdd1.mapPartitionsWithIndex((k,v)=>{v.map(x=> (k + "#" + x))}).collect

# 重新分区
var rdd2 = rdd1.partitionBy(new org.apache.spark.HashPartitioner(1))
rdd2.partitions.size
rdd2.mapPartitionsWithIndex((k,v)=>{v.map(x=> (k + "#" + x))}).collect
```

#### mapValues
`def mapValues[U](f: (V) => U): RDD[(K, U)]`

同基本转换操作中的map，只不过mapValues是针对[K,V]中的V值进行map操作。

```
var rdd1 = sc.makeRDD(Array((1,"A"),(2,"B"),(3,"C"),(4,"D")))
rdd1.mapValues(x => x + "_").collect
```

#### flatMapValues
`def flatMapValues[U](f: (V) => TraversableOnce[U]): RDD[(K, U)]`

同基本转换操作中的flatMap，只不过flatMapValues是针对[K,V]中的V值进行flatMap操作。

```
var rdd1 = sc.makeRDD(Array((1,"A"),(2,"B"),(3,"C"),(4,"D")),2)
rdd1.flatMapValues(x => x + "_").collect
```

#### combineByKey()
该函数用于将RDD[K,V]转换成RDD[K,C],这里的V类型和C类型可以相同也可以不同。

> 参数  

- `createCombiner`：组合器函数，用于将V类型转换成C类型，输入参数为RDD[K,V]中的V,输出为C
- `mergeValue`：合并值函数，将一个C类型和一个V类型值合并成一个C类型，输入参数为(C,V)，输出为C
- `mergeCombiners`：合并组合器函数，用于将两个C类型值合并成一个C类型，输入参数为(C,C)，输出为C
- `numPartitions`：结果RDD分区数，`默认`保持原有的分区数
- `partitioner`：分区函数,`默认`为HashPartitioner
- `mapSideCombine`：是否需要在Map端进行combine操作，类似于MapReduce中的combine，`默认`为true

> 源码：

```
//参数：
//创建聚合器，如果K已经创建，则调mergeValue，没创建，则创建，将V生成一个新值
//作用于分区内的数据，将相同K对应的V聚合
//作用于各分区，将各分区K相同的V聚合
def combineByKey[C](createCombiner: V => C,
      mergeValue: (C, V) => C,
      mergeCombiners: (C, C) => C) : RDD[(K, C)] = {
    combineByKey(createCombiner, mergeValue, mergeCombiners, defaultPartitioner(self))
  }

//numSplits分区数，聚合完成后生成的RDD有几个分区
def combineByKey[C](createCombiner: V => C,
      mergeValue: (C, V) => C,
      mergeCombiners: (C, C) => C,
      numSplits: Int): RDD[(K, C)] = {
    combineByKey(createCombiner, mergeValue, mergeCombiners, new HashPartitioner(numSplits))
  }

def combineByKey[C](createCombiner: V => C,
      mergeValue: (C, V) => C,
      mergeCombiners: (C, C) => C,
      partitioner: Partitioner): RDD[(K, C)] = {
    val aggregator = new Aggregator[K, V, C](createCombiner, mergeValue, mergeCombiners)
    new ShuffledRDD(self, aggregator, partitioner)
  }
```

```
# 实例：组装不同新RDD
var rdd1 = sc.makeRDD(Array(("A",1),("A",2),("B",1),("B",2),("C",1)))
rdd1.combineByKey(
      (v : Int) => v + "_",   
      (c : String, v : Int) => c + "@" + v,  
      (c1 : String, c2 : String) => c1 + "$" + c2
    ).collect
	
rdd1.combineByKey(
      (v : Int) => List(v),
      (c : List[Int], v : Int) => v :: c,
      (c1 : List[Int], c2 : List[Int]) => c1 ::: c2
    ).collect
```

#### reduceByKey()

根据Key聚合运算，将RDD中元素两两传递给输入函数，同时产生一个新值，新值与RDD中下一个元素再被传递给输入函数，直到最后只有一个值为止。

```
# 参数numPartitions用于指定分区数；
# 参数partitioner用于指定分区函数；
def reduceByKey(func: (V, V) => V): RDD[(K, V)]
def reduceByKey(func: (V, V) => V, numPartitions: Int): RDD[(K, V)]
def reduceByKey(partitioner: Partitioner, func: (V, V) => V): RDD[(K, V)]
```

用于将RDD[K,V]中每个K对应的V值根据映射函数来运算。

```
var rdd1 = sc.makeRDD(Array(("A",0),("A",2),("B",1),("B",2),("C",1)))
rdd1.reduceByKey((x,y) => x + y).collect
```

#### reduceByKeyLocally
`def reduceByKeyLocally(func: (V, V) => V): Map[K, V]`

将RDD[K,V]中每个K对应的V值根据映射函数来运算，运算结果映射到一个Map[K,V]中，而不是RDD[K,V]。

```
var rdd1 = sc.makeRDD(Array(("A",0),("A",2),("B",1),("B",2),("C",1)))
rdd1.reduceByKeyLocally((x,y) => x + y)
```

#### groupBy()/groupByKey()

```
# 参数numPartitions用于指定分区数；
# 参数partitioner用于指定分区函数；
def groupByKey(): RDD[(K, Iterable[V])]
def groupByKey(numPartitions: Int): RDD[(K, Iterable[V])]
def groupByKey(partitioner: Partitioner): RDD[(K, Iterable[V])]
```
用于将RDD[K,V]中每个K对应的V值，合并到一个集合Iterable[V]中。

```
var rdd1 = sc.makeRDD(Array(("A",0),("A",2),("B",1),("B",2),("C",1)))
rdd1.groupByKey().collect
```


### Action算子

#### saveAsTextFile
用于将RDD以文本文件的格式存储到文件系统中。

```
def saveAsTextFile(path: String): Unit
def saveAsTextFile(path: String, codec: Class[_ <: CompressionCodec]): Unit

# codec参数可选，可指定压缩的类名
```

#### saveAsSequenceFile
用于将RDD以SequenceFile的文件格式保存到HDFS上，用法同saveAsTextFile。

#### saveAsObjectFile
用于将RDD中的元素序列化成对象，存储到文件中，对于HDFS，默认采用SequenceFile保存。

#### saveAsHadoopFile
将RDD存储在HDFS上的文件中，支持老版本Hadoop API，可以指定outputKeyClass、outputValueClass以及压缩格式。每个分区输出一个文件。

```
var rdd1 = sc.makeRDD(Array(("A",2),("A",1),("B",6),("B",3),("B",7)))
rdd1.saveAsNewAPIHadoopFile("/tmp/result/",classOf[Text],classOf[IntWritable],classOf[TextOutputFormat[Text,IntWritable]])
```

#### saveAsHadoopDataset
用于将RDD保存到除了HDFS的其他存储中，比如HBase。

在JobConf中，通常需要关注或者设置五个参数：
文件的保存路径、key值的class类型、value值的class类型、RDD的输出格式(OutputFormat)、以及压缩相关的参数。

```
var rdd1 = sc.makeRDD(Array(("A",2),("A",1),("B",6),("B",3),("B",7)))
var jobConf = new JobConf()
jobConf.setOutputFormat(classOf[TextOutputFormat[Text,IntWritable]])
jobConf.setOutputKeyClass(classOf[Text])
jobConf.setOutputValueClass(classOf[IntWritable])
jobConf.set("mapred.output.dir","/tmp/result/")
rdd1.saveAsHadoopDataset(jobConf)
```

#### saveAsNewAPIHadoopFile
于将RDD数据保存到HDFS上，使用新版本Hadoop API。用法基本同saveAsHadoopFile。

```
var rdd1 = sc.makeRDD(Array(("A",2),("A",1),("B",6),("B",3),("B",7)))
rdd1.saveAsNewAPIHadoopFile("/tmp/result/",classOf[Text],classOf[IntWritable],classOf[TextOutputFormat[Text,IntWritable]])
```

#### saveAsNewAPIHadoopDataset
作用同saveAsHadoopDataset,只不过采用新版本Hadoop API。

#### Lookup(T)

用于(K,V)类型的RDD，指定K值，返回RDD中该K对应的所有V值。

```
var rdd1 = sc.makeRDD(1 to 5,2)
var rdd2 = sc.makeRDD(Seq("A","B","C","D","E"),2)
val rdd3 = rdd1.zip(rdd2)
rdd3.lookup(1)
```

#### count()
count()用来求RDD中元素的个数，`先求出个分区元素个数，然后sum()求和`

```
val rdd = sc.parallelize(Array(1, 2, 3, 4, 5, 3, 4, 5, 6, 7))
rdd.count()
```

#### countByKey()
用于统计RDD[K,V]中每个K的数量：`def countByKey(): Map[K, Long]`

```
var rdd1 = sc.makeRDD(Array(("A",0),("A",2),("B",1),("B",2),("B",3)))
rdd1.countByKey
// Map(A -> 2, B -> 3)
```

#### sortBy
根据给定的排序k函数将RDD中的元素进行排序:

```
var rdd1 = sc.makeRDD(Seq(3,6,7,1,2,0),2)
# 默认升序
rdd1.sortBy(x => x).collect
# 降序
rdd1.sortBy(x => x,false).collect

var rdd1 = sc.makeRDD(Array(("A",2),("A",1),("B",6),("B",3),("B",7)))
rdd1.sortBy(x=>x._2,false).collect
```

#### collect()/toArray()

collect()方法将RDD中的数据转化为数组，可在控制台输出。

toArray方法，调用collect()方法，将RDD转为数组

#### reduce(func())-计算结果与分区数有关
根据映射函数f，对RDD中的元素进行二元计算，返回计算结果——`T`。

reduce将RDD中元素两两传递给输入函数，同时产生一个新值，新值与RDD中下一个元素再被传递给输入函数，直到最后只有一个值为止。

**先计算各个分区与初值的结果，存入数组，再计算结果与初值的值。**

reduce()主要分两步，第一步调用`reduceLeft()`计算各个分区数据，第二步，再调用reduceLeft()计算各分区结果，再返回。

reduceLeft()、reduceRight():是scala语言特有算子  

> reduceLeft():(((1+2)+3)+4)+5

> reduceRight():1+(2+(3+(4+5)))

```
val rdd = sc.parallelize(1 to 5,5)
rdd.reduce(_+_)
# reduce()的计算过程:(((1+2)+3)+4)+5

# scala语言实现
val w=(1 to 5).toIterator
println(w.reduceLeft(_+_)) 

var rdd1 = sc.makeRDD(Array(("A",0),("A",2),("B",1),("B",2),("C",1)))
rdd1.reduce((v1,v2)=>(v1._1 + v2._1,v1._2+v2._2))
```

#### fold(T)-计算结果与分区数有关
fold是aggregate的简化，将aggregate中的seqOp和combOp使用同一个函数op。

fold跟reduce是差不多，只不过fold有初值，`先计算各个分区与初值的结果，存入数组，再计算结果与初值的值`。

`def fold(zeroValue: T)(op: (T, T) ⇒ T): T`

`reduce()`与`fold()`的区别就是一个有初值，一个无初值。

```
val rdd = sc.parallelize(1 to 5,5)
rdd.fold(5)(_+_)
// 计算过程：((1+5)+(2+5)+(3+5)+(4+5)+(5+5))+5
// Int = 45
```

#### aggregate(T)-计算结果与分区数有关
聚合RDD:`def aggregate[U](zeroValue: U)(seqOp: (U, T) ⇒ U, combOp: (U, U) ⇒ U)(implicit arg0: ClassTag[U]): U`

先用`seqOp`方法计算各分区里的数据，将各分区结果存入数组，然后再调用`fold()`，方法为`combOp`计算结果数据。

`aggregate()`与`fold()`的区别在于：flod计算某个分区数据与最后计算各分区结果数据用的用同一个方法，而`aggregate()`
则可以用两种不同的方法，当aggregate()两个方法一样时，结果与fold()是一样的。

aggregate()需要传入两个方法，第一个方法计算各分区内数据，第二个方法计算各分区之前结果数据。

```
val rdd = sc.parallelize(1 to 5,5)
rdd.reduce(_+_)
rdd.fold(5)(_+_)
rdd.aggregate(5)(_+_,_+_)

# 对比计算过程
# reduce：(((1+2)+3)+4)+5
# fold：((1+5)+(2+5)+(3+5)+(4+5)+(5+5))+5
# aggregate：((1+5)+(2+5)+(3+5)+(4+5)+(5+5))+5
```

#### take()

`rdd.take(2)：取前两个元素`

#### takeOrdered()

`rdd.takeOrdered(2)：升序排列后，取前两元素`

#### top()

`rdd.top(2)：降序排列后，取前两元素`

#### first()

`rdd.first()：取第一个元素`

#### sample()
随机抽样元素：sample(withReplacement,fraction,seed)
- withReplacement：是否重复抽取元素
- fraction：抽样概率，即每个元素被抽到的概率
- seed：随机数生成器的种子，`一般不好把控，不方便设置`
- `返回一个RDD[T]`

```
val rdd = sc.parallelize(1 to 100)
rdd.sample(false,0.1).collect
// 根据采样概率，每次返回的元素个数不一致
// Array[Int] = Array(28, 36, 45, 52, 63, 79)
```

#### takeSample()
随机抽样元素：takeSample(withReplacement,num,seed)
- withReplacement：是否重复抽取元素
- num：返回的样本的大小
- seed：随机数生成器的种子，`一般不好把控，不方便设置`
- `返回一个Array[T]`

```
val rdd = sc.parallelize(1 to 100)
rdd.takeSample(false,10).collect
// 指定样本大小进行采集，返回数组对象
// Array[Int] = Array(86, 10, 45, 8, 70, 90, 12, 14, 85, 20)
```