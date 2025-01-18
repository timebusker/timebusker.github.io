---
layout:     post
title:      管理Spark Streaming消费Kafka的偏移量
date:       2019-03-12
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Spark-Streaming
---

spark streaming里面管理偏移量的策略，默认的spark streaming它自带管理的offset的方式是通过checkpoint来记录每个批次的状态持久化到HDFS中，
如果机器发生故障，或者程序故障停止，下次启动时候，仍然可以从checkpoint的目录中读取故障时候rdd的状态，便能接着上次处理的数据继续处理，
但checkpoint方式最大的弊端是如果代码升级，新版本的jar不能复用旧版本的序列化状态，导致两个版本不能平滑过渡，结果就是要么丢数据，要么数据重复。

通用的解决办法就是自己写代码管理spark streaming集成kafka时的offset，自己写代码管理offset，其实就是把每批次offset存储到一个外部的存储系统。

`但人需要注意的问题：分区调整，手动维护的偏移量也需要跟进调整`

#### Maven依赖

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>demo</groupId>
    <artifactId>direct-stream-offset-to-zk</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <properties>
        <scala.version>2.11.8</scala.version>
        <spark.version>2.1.0</spark.version>
        <jedis.version>2.9.0</jedis.version>
        <spark.streaming.version>2.1.0</spark.streaming.version>
        <spark.kafka.version>2.0.2</spark.kafka.version>
        <kafka.version>0.9.0.0</kafka.version>
        <hbase.version>1.3.0</hbase.version>
        <config.version>1.2.1</config.version>
        <guava.version>18.0</guava.version>
        <joad-time.version>2.9.4</joad-time.version>
        <fast.json>1.2.31</fast.json>
        <scala.logging.version>3.1.0</scala.logging.version>
        <logback.version>1.1.7</logback.version>
        <json-simple.version>1.1.1</json-simple.version>
        <elasticsearch.version>2.3.4</elasticsearch.version>
        <zk.client>0.3</zk.client>
    </properties>
    <dependencies>
        <dependency>
            <groupId>org.elasticsearch</groupId>
            <artifactId>elasticsearch</artifactId>
            <version>${elasticsearch.version}</version>
        </dependency>
        <dependency>
            <groupId>com.101tec</groupId>
            <artifactId>zkclient</artifactId>
            <version>${zk.client}</version>
        </dependency>
        <dependency>
            <groupId>log4j</groupId>
            <artifactId>log4j</artifactId>
            <version>1.2.17</version>
        </dependency>
        <dependency>
            <groupId>com.typesafe</groupId>
            <artifactId>config</artifactId>
            <version>${config.version}</version>
        </dependency>
        <dependency>
            <groupId>joda-time</groupId>
            <artifactId>joda-time</artifactId>
            <version>${joad-time.version}</version>
        </dependency>
        <!--json解析框架-->
        <dependency>
            <groupId>com.alibaba</groupId>
            <artifactId>fastjson</artifactId>
            <version>${fast.json}</version>
        </dependency>
        <dependency>
            <groupId>com.google.guava</groupId>
            <artifactId>guava</artifactId>
            <version>${guava.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.spark</groupId>
            <artifactId>spark-streaming-kafka-0-8_2.11</artifactId>
            <version>${spark.kafka.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.kafka</groupId>
            <artifactId>kafka-clients</artifactId>
            <version>${kafka.version}</version>
        </dependency>
        <dependency>
            <groupId>org.scala-lang</groupId>
            <artifactId>scala-library</artifactId>
            <version>${scala.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.spark</groupId>
            <artifactId>spark-core_2.11</artifactId>
            <version>${spark.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.spark</groupId>
            <artifactId>spark-streaming_2.11</artifactId>
            <version>${spark.streaming.version}</version>
        </dependency>
    </dependencies>
    <build>
        <pluginManagement>
            <plugins>
                <plugin>
                    <groupId>net.alchim31.maven</groupId>
                    <artifactId>scala-maven-plugin</artifactId>
                    <version>3.2.1</version>
                </plugin>
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-compiler-plugin</artifactId>
                    <version>2.0.2</version>
                </plugin>
            </plugins>
        </pluginManagement>
        <plugins>
            <plugin>
                <groupId>net.alchim31.maven</groupId>
                <artifactId>scala-maven-plugin</artifactId>
                <executions>
                    <execution>
                        <id>scala-compile-first</id>
                        <phase>process-resources</phase>
                        <goals>
                            <goal>add-source</goal>
                            <goal>compile</goal>
                        </goals>
                    </execution>
                    <execution>
                        <id>scala-test-compile</id>
                        <phase>process-test-resources</phase>
                        <goals>
                            <goal>testCompile</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <executions>
                    <execution>
                        <phase>compile</phase>
                        <goals>
                            <goal>compile</goal>
                        </goals>
                    </execution>
                </executions>
                <configuration>
                    <source>1.7</source>
                    <target>1.7</target>
                    <encoding>UTF-8</encoding>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

#### Offset管理工具类

```scala
import kafka.common.TopicAndPartition
import kafka.utils.ZkUtils
import org.I0Itec.zkclient.ZkClient
import org.apache.spark.rdd.RDD
import org.apache.spark.streaming.kafka.HasOffsetRanges

/**
  *
  * 负责kafka偏移量的读取和保存
  *
  * Created by QinDongLiang on 2017/11/28.
  */
object KafkaOffsetManager {


  lazy val log = org.apache.log4j.LogManager.getLogger("KafkaOffsetManage")

  /***读取zk里面的偏移量，如果有就返回对应的分区和偏移量
    * 如果没有就返回None
    * @param zkClient  zk连接的client
    * @param zkOffsetPath   偏移量路径
    * @param topic    topic名字
    * @return  偏移量Map or None
    */
   def readOffsets(zkClient: ZkClient, zkOffsetPath: String, topic: String): Option[Map[TopicAndPartition, Long]] = {
    //（偏移量字符串,zk元数据)
    val (offsetsRangesStrOpt, _) = ZkUtils.readDataMaybeNull(zkClient, zkOffsetPath)//从zk上读取偏移量
    offsetsRangesStrOpt match {
      case Some(offsetsRangesStr) =>
        //这个topic在zk里面最新的分区数量
        val  lastest_partitions= ZkUtils.getPartitionsForTopics(zkClient,Seq(topic)).get(topic).get
        var offsets = offsetsRangesStr.split(",")//按逗号split成数组
          .map(s => s.split(":"))//按冒号拆分每个分区和偏移量
          .map { case Array(partitionStr, offsetStr) => (TopicAndPartition(topic, partitionStr.toInt) -> offsetStr.toLong) }//加工成最终的格式
          .toMap //返回一个Map

        //说明有分区扩展了
        if(offsets.size<lastest_partitions.size){
          //得到旧的所有分区序号
          val old_partitions=offsets.keys.map(p=>p.partition).toArray
          //通过做差集得出来多的分区数量数组
          val add_partitions=lastest_partitions.diff(old_partitions)
          if(add_partitions.size>0){
            log.warn("发现kafka新增分区："+add_partitions.mkString(","))
            add_partitions.foreach(partitionId=>{
              offsets += (TopicAndPartition(topic,partitionId)->0)
              log.warn("新增分区id："+partitionId+"添加完毕....")
            })
          }
        }else{
          log.warn("没有发现新增的kafka分区："+lastest_partitions.mkString(","))
        }
        Some(offsets)//将Map返回
      case None =>
        None//如果是null，就返回None
    }
  }

  /****
    * 保存每个批次的rdd的offset到zk中
    * @param zkClient zk连接的client
    * @param zkOffsetPath   偏移量路径
    * @param rdd     每个批次的rdd
    */
  def saveOffsets(zkClient: ZkClient, zkOffsetPath: String, rdd: RDD[_]): Unit = {
    //转换rdd为Array[OffsetRange]
    val offsetsRanges = rdd.asInstanceOf[HasOffsetRanges].offsetRanges
    //转换每个OffsetRange为存储到zk时的字符串格式 :  分区序号1:偏移量1,分区序号2:偏移量2,......
    val offsetsRangesStr = offsetsRanges.map(offsetRange => s"${offsetRange.partition}:${offsetRange.untilOffset}").mkString(",")
    log.debug(" 保存的偏移量：  "+offsetsRangesStr)
    //将最终的字符串结果保存到zk里面
    ZkUtils.updatePersistentPath(zkClient, zkOffsetPath, offsetsRangesStr)
  }

  class Stopwatch {
    private val start = System.currentTimeMillis()
    def get():Long = (System.currentTimeMillis() - start)
  }
}
```

#### 测试

```scala
import javax.servlet.http.{HttpServletRequest, HttpServletResponse}

import kafka.api.OffsetRequest
import kafka.message.MessageAndMetadata
import kafka.serializer.StringDecoder
import kafka.utils.ZKStringSerializer
import org.I0Itec.zkclient.ZkClient
import org.apache.hadoop.conf.Configuration
import org.apache.hadoop.fs.Path
import org.apache.spark.SparkConf
import org.apache.spark.streaming.dstream.InputDStream
import org.apache.spark.streaming.kafka.KafkaUtils
import org.apache.spark.streaming.{Seconds, StreamingContext}
import org.spark_project.jetty.server.{Request, Server}
import org.spark_project.jetty.server.handler.{AbstractHandler, ContextHandler}

/**
  * Created by QinDongLiang on 2017/11/28.
  */
object SparkDirectStreaming {


  val log = org.apache.log4j.LogManager.getLogger("SparkDirectStreaming")

  /***
    * 创建StreamingContext
    * @return
    */
  def createStreamingContext():StreamingContext={

    val isLocal=true//是否使用local模式
    val firstReadLastest=true//第一次启动是否从最新的开始消费

    val sparkConf=new SparkConf().setAppName("Direct Kafka Offset to Zookeeper")
    if (isLocal)  sparkConf.setMaster("local[1]") //local模式
    sparkConf.set("spark.streaming.stopGracefullyOnShutdown","true")//优雅的关闭
    sparkConf.set("spark.streaming.backpressure.enabled","true")//激活削峰功能
    sparkConf.set("spark.streaming.backpressure.initialRate","5000")//第一次读取的最大数据值
    sparkConf.set("spark.streaming.kafka.maxRatePerPartition","2000")//每个进程每秒最多从kafka读取的数据条数

    var kafkaParams=Map[String,String]("bootstrap.servers"-> "192.168.10.6:9092,192.168.10.7:9092,192.168.10.8:9092")//创建一个kafkaParams
    if (firstReadLastest)   kafkaParams += ("auto.offset.reset"-> OffsetRequest.LargestTimeString)//从最新的开始消费
    //创建zkClient注意最后一个参数最好是ZKStringSerializer类型的，不然写进去zk里面的偏移量是乱码
    val  zkClient= new ZkClient("192.168.10.6:2181,192.168.10.7:2181,192.168.10.8:2181", 30000, 30000,ZKStringSerializer)
    val zkOffsetPath="/sparkstreaming/20171128"//zk的路径
    val topicsSet="dc_test".split(",").toSet//topic名字

    val ssc=new StreamingContext(sparkConf,Seconds(10))//创建StreamingContext,每隔多少秒一个批次

    val rdds:InputDStream[(String,String)]=createKafkaStream(ssc,kafkaParams,zkClient,zkOffsetPath,topicsSet)

    //开始处理数据
    rdds.foreachRDD( rdd=>{

      if(!rdd.isEmpty()){//只处理有数据的rdd，没有数据的直接跳过

        //迭代分区，里面的代码是运行在executor上面
        rdd.foreachPartition(partitions=>{

          //如果没有使用广播变量，连接资源就在这个地方初始化
          //比如数据库连接，hbase，elasticsearch，solr，等等

          //遍历每一个分区里面的消息
          partitions.foreach(msg=>{
             log.info("读取的数据："+msg)
            // process(msg)  //处理每条数据
          })
        })
        //更新每个批次的偏移量到zk中，注意这段代码是在driver上执行的
        KafkaOffsetManager.saveOffsets(zkClient,zkOffsetPath,rdd)
      }
    })
    // 返回StreamContext
    ssc
  }


  /****
    * 负责启动守护的jetty服务
    * @param port 对外暴露的端口号
    * @param ssc Stream上下文
    */
  def daemonHttpServer(port:Int,ssc: StreamingContext)={
    val server=new Server(port)
    val context = new ContextHandler();
    context.setContextPath( "/close" );
    context.setHandler( new CloseStreamHandler(ssc) )
    server.setHandler(context)
    server.start()
  }

  /*** 负责接受http请求来优雅的关闭流
    * @param ssc  Stream上下文
    */
  class CloseStreamHandler(ssc:StreamingContext) extends AbstractHandler {
    override def handle(s: String, baseRequest: Request, req: HttpServletRequest, response: HttpServletResponse): Unit ={
      log.warn("开始关闭......")
      ssc.stop(true,true)//优雅的关闭
      response.setContentType("text/html; charset=utf-8");
      response.setStatus(HttpServletResponse.SC_OK);
      val out = response.getWriter();
      out.println("close success");
      baseRequest.setHandled(true);
      log.warn("关闭成功.....")
    }
  }


  /***
    * 通过一个消息文件来定时触发是否需要关闭流程序
    * @param ssc StreamingContext
    */
  def stopByMarkFile(ssc:StreamingContext):Unit= {
    val intervalMills = 10 * 1000 // 每隔10秒扫描一次消息是否存在
    var isStop = false
    val hdfs_file_path = "/spark/streaming/stop" //判断消息文件是否存在，如果存在就
    while (!isStop) {
      isStop = ssc.awaitTerminationOrTimeout(intervalMills)
      if (!isStop && isExistsMarkFile(hdfs_file_path)) {
        log.warn("2秒后开始关闭sparstreaming程序.....")
        Thread.sleep(2000)
        ssc.stop(true, true)
      }

    }
  }

    /***
      * 判断是否存在mark file
      * @param hdfs_file_path  mark文件的路径
      * @return
      */
    def isExistsMarkFile(hdfs_file_path:String):Boolean={
      val conf = new Configuration()
      val path=new Path(hdfs_file_path)
      val fs =path.getFileSystem(conf);
      fs.exists(path)
    }





  def main(args: Array[String]): Unit = {
    // 创建StreamingContext
    val ssc=createStreamingContext()
    // 开始执行
    ssc.start()
    // 启动接受停止请求的守护进程
	// 方式一通过Http方式优雅的关闭策略
    daemonHttpServer(5555,ssc)
    // 方式二通过扫描HDFS文件来优雅的关闭
    // stopByMarkFile(ssc)
    // 等待任务终止
    ssc.awaitTermination()


  }

  /****
    *
    * @param ssc  StreamingContext
    * @param kafkaParams  配置kafka的参数
    * @param zkClient  zk连接的client
    * @param zkOffsetPath zk里面偏移量的路径
    * @param topics     需要处理的topic
    * @return   InputDStream[(String, String)] 返回输入流
    */
  def createKafkaStream(ssc: StreamingContext,
                        kafkaParams: Map[String, String],
                        zkClient: ZkClient,
                        zkOffsetPath: String,
                        topics: Set[String]): InputDStream[(String, String)]={
    //目前仅支持一个topic的偏移量处理，读取zk里面偏移量字符串
    val zkOffsetData=KafkaOffsetManager.readOffsets(zkClient,zkOffsetPath,topics.last)
	
    val kafkaStream = zkOffsetData match {
      case None =>  //如果从zk里面没有读到偏移量，就说明是系统第一次启动
        log.info("系统第一次启动，没有读取到偏移量，默认就最新的offset开始消费")
        //使用最新的偏移量创建DirectStream
        KafkaUtils.createDirectStream[String, String, StringDecoder, StringDecoder](ssc, kafkaParams, topics)
      case Some(lastStopOffset) =>
        log.info("从zk中读取到偏移量，从上次的偏移量开始消费数据......")
        val messageHandler = (mmd: MessageAndMetadata[String, String]) => (mmd.key, mmd.message)
        //使用上次停止时候的偏移量创建DirectStream
        KafkaUtils.createDirectStream[String, String, StringDecoder, StringDecoder, (String, String)](ssc, kafkaParams, lastStopOffset, messageHandler)
    }
    kafkaStream//返回创建的kafkaStream
  }
}
```