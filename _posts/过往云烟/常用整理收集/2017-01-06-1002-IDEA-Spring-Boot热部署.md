---
layout:     post
title:      IDEA-Spring-Boot热部署
date:       2018-08-13
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - 开发工具
    - SpringBoot
---

#### 开启IDEA的自动编译（静态）

打开顶部工具栏 `File` -> `Settings` -> `Default Settings` -> `Build` -> `Compiler` 然后勾选 `Build project automatically`.

![image](/img/older/tools/5.png)

#### 开启IDEA的自动编译（动态）

按住`Ctrl + Shift + Alt`，选择进入`Registry`，勾选自动编译并调整延时参数：

`compile.document.save.trigger.delay`主要是针对静态文件如`JS`、`CSS`的更新，延迟时间减少。

![image](/img/older/tools/6.png)

#### 开启IDEA的热部署策略（非常重要）

顶部菜单`RUM` -> `Edit Configurations` -> `SpringBoot` -> `目标项目` -> `勾选热更新`

![image](/img/older/tools/7.png)


#### 添加SpringBoot热部署依赖

```xml
<dependency>
     <groupId>org.springframework.boot</groupId>
     <artifactId>spring-boot-devtools</artifactId>
     <scope>runtime</scope>
</dependency>
```

#### 关闭浏览器缓存

![image](/img/older/tools/8.png)