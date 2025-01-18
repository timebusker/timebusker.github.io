---
layout:     post
title:      关于Spring Boot微服务加载JAR内静态资源文件
date:       2018-01-24
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Spring相关
---

> 关于Spring Boot 微服务加载JAR内静态资源文件。

#### 问题来源
在开发微服务单个模块过程中，模块通过JAR应用部署，其间可能会出现我们希望在应用运行中读取需要某个包内文件进行处理。
   
而根据 `classpath:conf/core-site.xml` 这种方式获取资源文件，但是因为在JAR包中，所有 **classpath:** 会被替换成
`jar : file : /cn/timebusker/ResourceLoaderUtils!`。最终生成的资源路径为 ：`jar : file : /cn/timebusker/ResourceLoaderUtils!/conf/core-site.xml`。
也是因为是JAR包中的文件资源，所以会在 **file：** 前加上 **jar** 。

#### 解决办法 
服务直接通过JAR启动，而JAR文件在磁盘上并没有解压，所有通过系统的文件系统获取不到这样的文件，
也就没法使用 `new File(path)` 这种方式获取文件资源。但服务是运行在java虚拟机上，所以可以通过**JAVA API**获取JAR中的文件流。
最终通过流，将文件写到本地磁盘达到目的。

#### 代码实现
  
```   
package cn.timebusker.hadoop.utils;

import org.apache.commons.io.FileUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.core.io.support.ResourcePatternResolver;

import java.io.*;
import java.util.ArrayList;
import java.util.List;

/**
 * @DESC:微服务加载jar包内静态资源工具类
 * @author: timebusker
 * @date:2018/1/24
 */
public class ResourceLoaderUtils {
    private static final Logger LOG = LoggerFactory.getLogger(ResourceLoaderUtils.class);
    /**
     * 获取容器资源解析器
     */
    private static final ResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();
    /**
     * 标志文件创建的版本号，解决文件被重复创建的问题，避免不别要的IO
     */
    private static final String FILE_VERSION = File.separator + System.currentTimeMillis();
    /**
     * 项目路径
     */
    private static final String PROJECT_PATH = System.getProperty("user.dir") + File.separator + "tmp" + FILE_VERSION;


    public static List<String> getResources(String path) {
        List<String> list = new ArrayList<String>();
        Resource[] resources = null;
        try {
            // 获取所有匹配的文件,可以采用正则表达式
            resources = resolver.getResources(path);
            for (Resource resource : resources) {
                InputStream in = resource.getInputStream();
                LOG.info(resource.getFilename() + "的文件内容是：" + in.toString());
                String localPath = PROJECT_PATH + File.separator + resource.getFilename();
                LOG.info("新文件的存储位置是：" + localPath);
                File tar = new File(localPath);
                if (tar.exists()) {
                    list.add(localPath);
                    continue;
                }
                FileUtils.copyInputStreamToFile(in, tar);
                list.add(localPath);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return list;
    }
}

```
