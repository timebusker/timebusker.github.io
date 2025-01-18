---
layout:     post
title:      Linux（CentOS）YUM下载RPM包及依赖包的两种方式
date:       2019-07-23
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Linux
---

> Linux（CentOS）YUM下载RPM包及依赖包的两种方式

当生产环境由于安全原因处于断网状态的时候。通过本地源的方式，使用yum能够自动安装软件，并且自动处理好依赖关系。
然而该方法最最关键的一个问题是——怎么获取该软件及其依赖包，供本地源使用？当安装软件的依赖包较少的话，通过手动的方式，
一个个查找并下载，也许是一个可以考虑的方案，而当一个软件有上百个依赖、并且依赖上又有依赖，这时候你再试试？如果真的觉得很无力，
那么`downloadonly`跟`yumdownloade`绝对是两个值得尝试的神器。本文简单介绍`downloadonly`跟`yumdownloade`的使用方法。

### downloadonly

`downloadonly`作为`yum`的一个插件使用，下载软件包时，必须是本地没有安装时才能正常下载。

- 安装downloadonly

```

sudo yum install yum-plugin-downloadonly
```

- downloadonly使用 

```
# yum install –downloadonly+软件名称

sudo yum install --downloadonly nano
# 默认情况下软件下载的路径在/var/cache/yum/x86_64/7/base/packages/下

# 我们还可以指定软件包的下载路径。需要加入参数–downloaddir参数。
sudo yum install --downloadonly --downloaddir=/root/package/nano nano
```

此时，下载的nano包存放在/root/package/nano目录下。

### yumdownloade

- 安装yumdownloade

```
sudo yum install yum-utils -y
```

- yumdownloade使用 

```
# 格式：sudo yumdownloader 软件名
sudo yumdownloader nano 

sudo yumdownloader httpd --resolve --destdir=/root/package/httpd 
```

默认情况下，下载的包会被保存在当前目录中，我们需要使用root权限，因为yumdownloader会在下载过程中更新包索引文件。
与yum命令不同的是，任何依赖包不会被下载。我们可以通过加参数，使得下载包的过程中同时下载依赖以及自定义下载位置，
格式为：yumdownloader 软件名 –resolve –destdir=保存目录 
