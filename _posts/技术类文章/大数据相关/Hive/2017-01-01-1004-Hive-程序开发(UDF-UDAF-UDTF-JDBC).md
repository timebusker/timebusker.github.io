---
layout:     post
title:      Hive-程序开发（UDF/UDAF/UDTF/JDBC）
date:       2017-12-14
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Hive
---
#### UDF函数开发

- Maven依赖

```xml
<dependency>
    <groupId>org.apache.hive</groupId>
    <artifactId>hive-exec</artifactId>
    <version>${hive.version}</version>
    <scope>provided</scope>
</dependency>
```

- JAVA编码

```java
package com.timebusker.hive.udf;

import org.apache.hadoop.hive.ql.exec.Description;
import org.apache.hadoop.hive.ql.exec.UDF;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * @Description:JsonStringParseUDF:JSON解析器
 * @Author:Administrator
 * @Date2019/10/20 10:04
 **/

/**
 * 便捷UDF函数详细信息
 * 使用 DESCRIBE FUNCTION EXTENDED udf_json_parse 可查看;
 */
@Description(name = "udf_json_parse",
        value = "_FUNC_(jsonString,key) - valid the jsonString, if like return 1 else return 0",
        extended = "Example:\n > SELECT _FUNC_('jsonString', 'key') FROM src LIMIT 1; \n  'value'")
public class JsonStringParseUDF extends UDF {

    public static String evaluate(String jsonStr, String key) {
        try {
            JSONObject json = new JSONObject(jsonStr);
            return json.getString(key);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return "";
    }

    public static void main(String[] args) {
        evaluate("{\"movie\":\"1721\",\"rate\":\"4\",\"timeStamp\":\"978300055\",\"uid\":\"1\"}", "movie");
    }
}
```

- maven打包

> 只需打包必须引入依赖和开发代码部分即可，hive依赖生产环境可以提供

- 添加jar

> 加入hive的classpath环境变量中：可拷贝到HIVE_HOME下的lib中（需要重启服务）或者链接到beeline中执行`add jar xxx.jar`（只对当前链接有效）。然后执行创建函数：

```
create function udf_json_parse as 'com.timebusker.hive.udf.JsonStringParseUDF';
```

> 把jar包上传到hdfs中，加载使用(**推荐使用**)

```
create function udf_json_parse as 'com.timebusker.hive.udf.JsonStringParseUDF' using jar 'hdfs://hdpcentos:9000/jars/hive/spark-all-hive-function-1.0.0.jar';
```

sparkSQL与hive整合后，sparkSQL可支持本地jar模式加载：

```sql
create function udf_json_parse as 'com.timebusker.hive.udf.JsonStringParseUDF' using jar 'file:///root/spark-all-hive-function-1.0.0.jar';

-- 查看新建函数：

show functions;

-- 新建函数将以数据库名.函数名展示
-- | default.udf_json_parse  |
```
