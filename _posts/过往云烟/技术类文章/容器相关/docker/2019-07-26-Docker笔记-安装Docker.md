---
layout:     post
title:      安装Docker
date:       2019-07-26
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Docker
---  

> 切勿在没有配置 Docker YUM 源的情况下直接使用 yum 命令安装 Docker.

Docker 分为 CE 和 EE 两大版本。CE 即社区版（免费，支持周期 7 个月），EE 即企业版，强调安全，付费使用，支持周期 24 个月。

Docker CE 分为 stable, test, 和 nightly 三个更新频道。每六个月发布一个 stable 版本 (18.09, 19.03, 19.09...)。

### CentOS 安装 Docker CE

- 系统要求

Docker CE 支持 64 位版本`CentOS 7`，并且要求内核版本不低于 3.10。 CentOS 7 满足最低内核的要求，但由于内核版本比较低，部分功能（如 overlay2 存储层驱动）无法使用，并且部分功能可能不太稳定。

```
[root@localhost ~]# cat /proc/version 

Linux version 3.10.0-957.el7.x86_64 (mockbuild@kbuilder.bsys.centos.org) (gcc version 4.8.5 20150623 (Red Hat 4.8.5-36) (GCC) ) #1 SMP Thu Nov 8 23:39:32 UTC 2018

```

- 卸载旧版本

旧版本的`Docker`称为`docker`或者`docker-engine`，使用以下命令卸载旧版本：

```
yum remove docker \
           docker-client \
           docker-client-latest \
           docker-common \
           docker-latest \
           docker-latest-logrotate \
           docker-logrotate \
           docker-selinux \
           docker-engine-selinux \
           docker-engine
```

- 安装依赖包

```
yum install -y \
        yum-utils \
        device-mapper-persistent-data \
        lvm2
```

#### 使用官方yum源安装（不建议）

鉴于国内网络问题，强烈建议使用国内源，官方源请在注释中查看。执行下面的命令添加 yum 软件源：

```	
# 官方源
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
```

源文件默认关闭了`测试版`、`每日构建版`，如需使用需要手动开启。

> 如果需要测试版本的 Docker CE 请使用以下命令：`yum-config-manager --enable docker-ce-test`

> 如果需要每日构建版本的 Docker CE 请使用以下命令：`yum-config-manager --enable docker-ce-nightly`

- 安装 Docker CE

更新 yum 软件源缓存，并安装 docker-ce。

```
yum makecache fast
yum install docker-ce -y
```

#### 使用脚本自动安装（不建议）

在测试或开发环境中 Docker 官方为了简化安装流程，提供了一套便捷的安装脚本，CentOS 系统上可以使用这套脚本安装：

```
# 下载脚本
curl -fsSL get.docker.com -o get-docker.sh
# 执行脚本
sh get-docker.sh --mirror Aliyun
```

执行这个命令后，脚本就会自动的将一切准备工作做好，并且把 Docker CE 的 Edge 版本安装在系统中。

#### 使用国内镜像加速安装（推荐）

如果在使用过程中发现拉取 Docker 镜像十分缓慢，可以配置 Docker 国内镜像加速。

> 以使用[阿里云](https://cr.console.aliyun.com)为例（`阿里云需要账号登录获取加速地址`）

> **登录阿里云**-->**控制台**-->**产品与服务**-->**弹性计算**-->**容器镜像服务**-->**镜像中心**-->**镜像加速器**

[镜像加速](img/older/docker/image-jiasu.png)

**分别完成服务加速器的两步操作即可**

#### 测试Docker 

```
[root@localhost yum.repos.d]# docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
1b930d010525: Pull complete 
Digest: sha256:6540fc08ee6e6b7b63468dc3317e3303aae178cb8a45ed3123180328bcc1d20f
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/


```

若能正常输出以上信息，则说明安装成功。

#### 添加内核参数

如果在 CentOS 使用 Docker CE 看到下面的这些警告信息：

```
WARNING: bridge-nf-call-iptables is disabled
WARNING: bridge-nf-call-ip6tables is disabled
```

请添加内核配置参数以启用这些功能。

```
tee -a /etc/sysctl.conf <<-EOF
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
EOF
```

然后重新加载`sysctl.conf`即可

```
sysctl -p
```

### Windows 10 PC 安装 Docker CE

Docker for Windows 支持 64 位版本的 Windows 10 Pro，且必须开启 Hyper-V。