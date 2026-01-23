---
layout:     post
title:      Spark笔记(十七)-SparkCore的源码解读之启动与SparkSubmit
date:       2018-06-25
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Spark
---

#### 启动过程

![SparkCore的源码解读之启动流程](img/older/spark/17/1.png)

- 通过Shell脚本启动Master，Master类继承Actor类，通过ActorySystem创建并启动。
- 通过Shell脚本启动Worker，Worker类继承Actor类，通过ActorySystem创建并启动。
- Worker通过Akka或者Netty发送消息向Master注册并汇报自己的资源信息(内存以及CPU核数等)，以后就是定时汇报，保持心跳。
- Master接受消息后保存(源码中通过持久化引擎持久化)并发送消息表示Worker注册成功，并且定时调度，移除超时的Worker。
- 通过Spark-Submit提交作业或者通过Spark Shell脚本连接集群，都会启动一个Spark进程Driver。
- Master拿到作业后根据资源筛选Worker并与Worker通信，发送信息，主要包含Driver的地址等。
- Worker进行收到消息后，启动Executor，Executor与Driver通信。
- Driver端计算作业资源，transformation在Driver 端完成，划分各个Stage后提交Task给Executor。
- Exectuor针对于每一个Task读取HDFS文件，然后计算结果，最后将计算的最终结果聚合到Driver端或者写入到持久化组件中。

#### Shell脚本
独立部署模式下，主要由`master`和`slaves`组成，`master`可以利用`zk`实现高可用性，其`driver`，`work`，`app`等信息可以持久化到`zk`上；`slaves`由一台至多台主机构成。`Driver`通过向`Master`申请资源获取运行环境。

启动`master`和`slaves`主要是执行`$SPARK_HOME/sbin`目录下的`start-master.sh`和`start-slaves.sh`，或者执行`start-all.sh`，其中`star-all.sh`本质上就是调用`spark-config.sh`、`start-master.sh`和`start-slaves.sh`。
其中`start-master.sh`和`start-slave.sh`分别调用的是`org.apache.spark.deploy.master.Master`和`org.apache.spark.deploy.worker.Worker`。

- spark-config.sh

```
#判断SPARK_HOME是否有值，没有将其设置为当前文件所在目录的上级目录
if [ -z "${SPARK_HOME}" ]; then
  export SPARK_HOME="$(cd "`dirname "$0"`"/..; pwd)"
fi
#SPARK_CONF_DIR存在就用此目录，不存在用${SPARK_HOME}/conf
export SPARK_CONF_DIR="${SPARK_CONF_DIR:-"${SPARK_HOME}/conf"}"
# Add the PySpark classes to the PYTHONPATH:
if [ -z "${PYSPARK_PYTHONPATH_SET}" ]; then
  export PYTHONPATH="${SPARK_HOME}/python:${PYTHONPATH}"
  export PYTHONPATH="${SPARK_HOME}/python/lib/py4j-0.10.6-src.zip:${PYTHONPATH}"
  export PYSPARK_PYTHONPATH_SET=1
fi
```

- start-master.sh

```
#1.判断SPARK_HOME是否有值，没有将其设置为当前文件所在目录的上级目录
if [ -z "${SPARK_HOME}" ]; then
  export SPARK_HOME="$(cd "`dirname "$0"`"/..; pwd)"
fi

# NOTE: This exact class name is matched downstream by SparkSubmit.
# Any changes need to be reflected there.
#2.设置CLASS="org.apache.spark.deploy.master.Master"
CLASS="org.apache.spark.deploy.master.Master"

#3.如果参数结尾包含--help或者-h则打印帮助信息，并退出
if [[ "$@" = *--help ]] || [[ "$@" = *-h ]]; then
  echo "Usage: ./sbin/start-master.sh [options]"
  pattern="Usage:"
  pattern+="\|Using Spark's default log4j profile:"
  pattern+="\|Registered signal handlers for"

  "${SPARK_HOME}"/bin/spark-class $CLASS --help 2>&1 | grep -v "$pattern" 1>&2
  exit 1
fi

#4.设置ORIGINAL_ARGS为所有参数
ORIGINAL_ARGS="$@"
#5.执行${SPARK_HOME}/sbin/spark-config.sh
. "${SPARK_HOME}/sbin/spark-config.sh"
#6.执行${SPARK_HOME}/bin/load-spark-env.sh
. "${SPARK_HOME}/bin/load-spark-env.sh"
#7.SPARK_MASTER_PORT为空则赋值7077
if [ "$SPARK_MASTER_PORT" = "" ]; then
  SPARK_MASTER_PORT=7077
fi
#8.SPARK_MASTER_HOST为空则赋值本主机名(hostname)
if [ "$SPARK_MASTER_HOST" = "" ]; then
  case `uname` in
      (SunOS)
      SPARK_MASTER_HOST="`/usr/sbin/check-hostname | awk '{print $NF}'`"
      ;;
      (*)
      SPARK_MASTER_HOST="`hostname -f`"
      ;;
  esac
fi
#9.SPARK_MASTER_WEBUI_PORT为空则赋值8080
if [ "$SPARK_MASTER_WEBUI_PORT" = "" ]; then
  SPARK_MASTER_WEBUI_PORT=8080
fi
#10.执行脚本
"${SPARK_HOME}/sbin"/spark-daemon.sh start $CLASS 1 \
  --host $SPARK_MASTER_HOST --port $SPARK_MASTER_PORT --webui-port $SPARK_MASTER_WEBUI_PORT \
  $ORIGINAL_ARGS

# sbin/spark-daemon.sh start org.apache.spark.deploy.master.Master 1 --host hostname --port 7077 --webui-port 8080
```

#### start-slaves.sh/start-slave.sh

```
#1.判断SPARK_HOME是否有值，没有将其设置为当前文件所在目录的上级目录
if [ -z "${SPARK_HOME}" ]; then
  export SPARK_HOME="$(cd "`dirname "$0"`"/..; pwd)"
fi

#2.执行${SPARK_HOME}/sbin/spark-config.sh，见上述分析
. "${SPARK_HOME}/sbin/spark-config.sh"

#3.执行${SPARK_HOME}/bin/load-spark-env.sh，见上述分析
. "${SPARK_HOME}/bin/load-spark-env.sh"

# Find the port number for the master
#4.SPARK_MASTER_PORT为空则设置为7077
if [ "$SPARK_MASTER_PORT" = "" ]; then
  SPARK_MASTER_PORT=7077
fi

#5.SPARK_MASTER_HOST为空则设置为`hostname`
if [ "$SPARK_MASTER_HOST" = "" ]; then
  case `uname` in
      (SunOS)
      SPARK_MASTER_HOST="`/usr/sbin/check-hostname | awk '{print $NF}'`"
      ;;
      (*)
      SPARK_MASTER_HOST="`hostname -f`"
      ;;
  esac
fi

# Launch the slaves
#6.启动slaves，
#   "${SPARK_HOME}/sbin/slaves.sh" cd "${SPARK_HOME}" \; "${SPARK_HOME}/sbin/start-slave.sh" "spark://$SPARK_MASTER_HOST:$SPARK_MASTER_PORT"
#   遍历conf/slaves中主机，其中有设置SPARK_SSH_OPTS，ssh每一台机器执行"${SPARK_HOME}/sbin/start-slave.sh" "spark://$SPARK_MASTER_HOST:$SPARK_MASTER_PORT"
"${SPARK_HOME}/sbin/slaves.sh" cd "${SPARK_HOME}" \; "${SPARK_HOME}/sbin/start-slave.sh" "spark://$SPARK_MASTER_HOST:$SPARK_MASTER_PORT"
```

#### Spark Submit
作业提交的主要脚本是`spark-submit.sh`脚本，主要执行的代码是：`exec "${SPARK_HOME}"/bin/spark-class org.apache.spark.deploy.SparkSubmit "$@"`。

#### SparkSubmit类

![SparkCore的源码解读之启动流程](img/older/spark/17/3.png)

```
./bin/spark-submit 
 --master spark://12.12.12.11:7077 \
 --class org.apache.spark.examples.SparkPi \
 --executor-memory 20G \
 --total-executor-cores 100\
 lib/spark-examples-1.0.0-hadoop2.2.0.jar \
 1000
```

![SparkCore的源码解读之启动流程](img/older/spark/17/2.png)