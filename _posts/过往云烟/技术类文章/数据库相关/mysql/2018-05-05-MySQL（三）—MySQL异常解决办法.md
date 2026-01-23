---
layout:     post
title:      MySQL学习笔记（三）— MySQL异常解决办法
subtitle:   MySQL常用配置
date:       2018-06-25
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - MySQL
---

> MySQL学习笔记（二）—MySQL常用配置

#### MySQL-JDBC-URL异常

```
# URL:jdbc:mysql://hdp-cluster-6:3306/hive_a?createDatabaseIfNotExist=true&useUnicode=true&characterEncoding=UTF-8&useSSL=true
# 异常信息：The reference to entity "useUnicode" must end with the ';' delimiter.

# 原因：数据源配置时加上编码转换格式后出了问题
# 解决办法：字符转义 &--> &amp;
URL:jdbc:mysql://hdp-cluster-6:3306/hive_a?createDatabaseIfNotExist=true&amp;useUnicode=true&amp;characterEncoding=UTF-8&amp;useSSL=true
```

