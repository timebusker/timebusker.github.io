---
layout:     post
title:      Linux（CentOS）服务开机启动
date:       2018-07-23
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Linux
---

> Linux（CentOS）服务开机启动

#### chkconfig 配置开机启动

在`/etc/init.d`创建执行服务的可执行脚本，赋予脚本可执行权限。如果是通过`yum`或者`rpm`安装的，并且已经在该目录下存在对应的启动脚本，就不用自己创建了。

需要开机通过`chkconfig`设置开机启动的服务，必须在`/etc/init.d`目录创建一个可执行脚本，服务名称就是脚本名称。
每个被chkconfig管理的服务需要在对应的`/etc/init.d`下的脚本加上两行或者更多行的注释。

```
# chkconfig: chkconfig缺省启动的运行级以及启动和停止的优先级
# description: 对服务进行描述，可以用 \ 跨行注释
```

`/etc/init.d/mYservice`只是模拟一下，服务执行只是输出数字`123`.

```shell
#！/bin/bash
# chkconfig: 2345 20 80 
# description: Saves and restores system entropy pool for \
# higher quality random number generation.
echo 123;
```

`chkconfig: 2345 20 80`表示这个服务在运行级别`2345`下运行`20`表示开机启动优先权重`80`表示关闭优先权重。
实际上`chkconfig --add`命令是将`/etc/init.d`中的启动脚本软连接到
`/etc/rc.d/rc3.d （rc0.d ... rc6.d) 0-6`个运行级别对应相应的目录。都是/etc/init.d 中启动脚本的软连接。

给脚本`mYservice`设置可执行权限,并通过`chkconfig`添加开机启动服务。

```shell
chmod +x /etc/init.d/my-service
chkconfig --add mYervice
```

`/etc/init.d/`中的脚本，可以通过命令：`service service-name [start/stop] `启动或者关闭。


#### /etc/rc.local 文件中添加开机启动命令

开机的时候，执行完`/etc/rcx.d`(x表示0到6中的一个数字，对应7个运行级别的启动目录），最后会执行`/etc/rc.local`脚本，我们将要启动的服务脚本写到这个文件即可。
如果不生效，检查文件是否有可执行权限。

`vim /etc/rc.local`

```

#!/bin/bash
# This script will be executed *after* all the other init scripts.
# You can put your own initialization stuff in here if you don't
# want to do the full Sys V style init stuff.
touch /var/lock/subsys/local

# 需要执行的脚本写绝对路径
/usr/local/rabbitmq_server-3.6.3/sbin/rabbitmq-server detached &
```
