---
layout:     post
title:      Spark笔记(五)-Spark之RDD-算子API使用（二）
date:       2018-06-25
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Spark
---

### 算法实例

- workCount
- TopN
- 多主键排序

```
package com.timebusker

import org.apache.spark.{Partitioner, SparkConf, SparkContext}

import scala.collection.mutable

/*
  * @DESC:PopularTeacher:求取最受欢迎的老师
  * @author:timebusker
  * @date:2019 /5/15
  */
object PopularTeacher {

  def main(args: Array[String]): Unit = {
    val inputFile = "D:\\WorkSpaces\\timebusker.github.io\\_posts\\大数据\\spark&scala\\data\\teacher.log"

    // 统计最受欢迎的老师
    // popularTeacher(inputFile)

    // 统计每个学科最受欢迎的老师
    // subjectPopularTeacher(inputFile)

    // 统计每个学科最受欢迎的老师的-TopN
    subjectPopularTeacherTopN(inputFile)
  }

  /**
    * 计算老师被搜索的喜好统计，降序排序
    *
    * @param arg
    */
  def popularTeacher(arg: String): Unit = {
    val conf = new SparkConf().setAppName("popularTeacher").setMaster("local[4]")
    val sc = new SparkContext(conf)
    val lines = sc.textFile(arg)

    // http://bigdata.edu360.cn/laoduan
    val rdd = lines.map(x => {
      val teacher = x.substring(x.lastIndexOf("/") + 1)
      (teacher, 1)
    })
    // 聚合运算时，设置分区数为1
    rdd.reduceByKey(_ + _, 1).sortBy(x => x._2, false).saveAsTextFile("D:\\WorkSpaces\\timebusker.github.io\\_posts\\大数据\\spark&scala\\" + System.currentTimeMillis())
  }

  /**
    * 统计每个学科老师的喜好度，降序排序
    *
    * @param agr
    */
  def subjectPopularTeacher(agr: String): Unit = {
    val conf = new SparkConf().setAppName("subjectPopularTeacher").setMaster("local[4]")
    val sc = new SparkContext(conf)
    val lines = sc.textFile(agr)

    // 提取（学科，老师）
    val subjectTeacher = lines.map(line => {
      val arr = line.split("/")
      val subject = arr(2).split("[.]")(0)
      (subject, arr(3))
    })

    // 统计学科下的老师被搜索的次数
    val map = subjectTeacher.map((_, 1))

    // 按学科把每个老师的结果聚合在一起,设置一个分区
    val reduce = map.reduceByKey(_ + _, 1)

    // 处理排序,设置多条件排序规则
    val result = reduce.map(x => (x._1._1, x._1._2, x._2)).sortBy(x => (x._1, x._3), false)

    // 保存文件
    result.saveAsTextFile("D:\\WorkSpaces\\timebusker.github.io\\_posts\\大数据\\spark&scala\\" + System.currentTimeMillis())
  }


  /**
    * 统计每个学科老师的喜好度，提取出前两名
    *
    * @param agr
    */
  def subjectPopularTeacherTopN(agr: String): Unit = {
    val topN = 100
    val conf = new SparkConf().setAppName("subjectPopularTeacher").setMaster("local[4]")
    val sc = new SparkContext(conf)
    val lines = sc.textFile(agr)

    // 提取（学科，老师）
    val subjectTeacher = lines.map(line => {
      val arr = line.split("/")
      val subject = arr(2).split("[.]")(0)
      (subject, arr(3))
    })

    // 统计学科下的老师被搜索的次数
    val map = subjectTeacher.map((_, 1))

    // 按学科把每个老师的结果聚合在一起,此处取消分区设置。当数据量足够庞大时，分区数是不可控的
    val reduce = map.reduceByKey(_ + _)

    // 计算有多少学科
    val subjects = reduce.map(_._1._1).distinct().collect()

    // 设置分区
    val partitioner = new SubjectPartitioner(subjects)
    val partitioned = reduce.partitionBy(partitioner)

    // 针对分区内元素求出TopN
    val sorted = partitioned.mapPartitions(iterator => {
      //将迭代器转换成list，然后排序，在转换成迭代器返回
      iterator.toList.sortBy(_._2).reverse.take(topN).iterator
    })

    // 保存文件
    sorted.repartition(1).saveAsTextFile("D:\\WorkSpaces\\timebusker.github.io\\_posts\\大数据\\spark&scala\\" + System.currentTimeMillis())
  }
}

/**
  * 自定义分区器
  *
  * @param subjects
  */
class SubjectPartitioner(subjects: Array[String]) extends Partitioner {
  /**
    * 相当于主构造器（new的时候回执行一次），用于存放规则的一个map
    */
  val rules = new mutable.HashMap[String, Int]()
  var i = 0
  for (subject <- subjects) {
    rules.put(subject, i)
    i += 1
  }

  /**
    * 返回分区数
    *
    * @return
    */
  override def numPartitions: Int = rules.size

  /**
    * 根据传入的key计算分区标号
    * key是一个元组（String， String）
    *
    * @param key
    * @return
    */
  override def getPartition(key: Any): Int = {
    //获取学科名称
    val subject = key.asInstanceOf[(String, String)]._1
    //根据规则计算分区编号
    rules(subject)
  }
}
```