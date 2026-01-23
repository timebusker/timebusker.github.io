---
layout:     post
title:      Spring Boot 使用Maven资源过滤功能导致Excel模板被损坏
date:       2019-11-14
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Spring相关
---

##### 问题来源

项目是spring boot 的项目使用Mavne管理依赖，开发一个Excel表模板下载功能，模板读取和模板下载都是么有问题的，但打开Excel表示提示，文件已损坏。现象如下：

![使用Maven资源过滤功能导致Excel模板被损坏](img/older/spring/9.png)

##### 问题分析

maven的filter，主要作用就是替换变量，所以会把资源文件作为文本文件转码处理，并替换字符串。单对于像excel等这些二进制文件，则会出现问题。

问题根因是在maven编译时Excel模板表就已经被损坏了，下载一个已经被损坏的Excel表肯定是无法打开的。

##### resources配置

在开发maven项目时，一般都会把配置文件放到src/main/resources目录下，针对这个目录，maven的resources对其进行单独的配置。、

```xml
<resources>
    <resource>
        <directory>src/main/resources</directory>
        <filtering>true</filtering>
        <includes>
            <include>context.xml</include>
        </includes>
    </resource>

    <resource>
        <directory>src/main/resources</directory>
        <filtering>false</filtering>
        <excludes>
            <exclude>context.xml</exclude>
        </excludes>
    </resource>
</resources>
```

配置中一共有两个resource，第一个resource配置是过滤src/main/resources目录下文件context.xml，若文件中有类似${key}这样的配置，
就会根据maven的配置进行覆盖，让其使用真实值来填写，至于真实值如何来，后面会具体讲。

第二个resource配置是不过滤src/main/resources目录下除了context.xml的其他文件，也就不会用真实值来填写${key}这样的配置。

若是<include>和<exclude>都存在的话，那就发生冲突了，这时会以<exclude>为准。

也许有人会有疑问，若只需要过滤context.xml的话，那就只需要配置第一个resource就可以了吧。其实不然，若是只配置第一个resource，
第二个不配置，那么当你运行maven打包操作后，你就会发现，在工程的classpath下只有context.xml文件了，其他配置文件都没有打过来。
所以第二个resource是必不可少的，指明其他配置文件是不需要过滤的，但是同样需要打包到classpath下。

其实filtering为true的时候，这时只会把过滤的文件打到classpath下，filtering为false的时候，会把不需要过滤的文件打到classpath下。

还有一点需要说明，若<filtering>、<include>和<exclude>都不配置，就是把directory下的所有配置文件都放到classpath下，若这时如下配置:

```xml
<resources>
    <resource>
        <directory>src/main/resources-dev</directory>
    </resource>
    <resource>
        <directory>src/main/resources</directory>
    </resource>
</resources>
```

会以resources-dev下的相同文件为准，不一样的文件取并集。其实这样配合下面讲的profiles也可以实现各种不同环境的自动切换。

前面讲到被过滤的文件会被真实值填写文件中的${key}位置，那这些真实值来自哪里呢？这些真实值其实都来自于profiles的配置里面，如下

```xml
<profiles>
    <profile>
        <id>dev</id>
        <activation>
            <activeByDefault>true</activeByDefault>
        </activation>
        <properties>
            <config>pathConfig</config>
        </properties>
    </profile>
</profiles>
```

这段配置结合文章开头的配置，就会把context.xml文件中的${config}在打包过程中替换成pathConfig，而其他配置文件不受任何影响，
利用这种特性也可以实现各种不同环境的自动切换，主要是在打包时指定使用哪个profile即可，命令如下：

```
# 利用id=dev的profile配置打包
man clean package -Pdev
```

利用以上配置时，若是配置信息比较多，可能导致<properties>需要配置很多项，看起来不够简洁，这时可以利用profile的另外一个节点属性filter，
可以指定文件，并使用指定文件中的配置信息来填写过滤文件的内容。配置如下：

```xml
<profile>
    <id>dev</id>
    <activation>
        <activeByDefault>true</activeByDefault>
    </activation>
    <build>
        <filters>
            <filter>config-dev.properties</filter>
        </filters>
    </build>
</profile>
```


##### 问题解决

![使用Maven资源过滤功能导致Excel模板被损坏](img/older/spring/10.png)