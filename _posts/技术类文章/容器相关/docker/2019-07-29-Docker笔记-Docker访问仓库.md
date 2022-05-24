---
layout:     post
title:      Docker访问仓库
date:       2019-07-29
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Docker
---  

仓库（Repository）是集中存放镜像的地方。

一个容易混淆的概念是注册服务器（Registry）。实际上注册服务器是管理仓库的具体服务器，每个服务器上可以有多个仓库，而每个仓库下面有多个镜像。
从这方面来说，仓库可以被认为是一个具体的项目或目录。例如对于仓库地址 dl.dockerpool.com/ubuntu 来说，dl.dockerpool.com 是注册服务器地址，ubuntu 是仓库名。

### Docker Hub

目前 Docker 官方维护了一个公共仓库 Docker Hub，其中已经包括了数量超过 15,000 的镜像。大部分需求都可以通过在 Docker Hub 中直接下载镜像来实现。

##### 注册

你可以在 [官网hub.docker.com](https://hub.docker.com) 免费注册一个 Docker 账号。

##### 登录

可以通过执行`docker login`命令交互式的输入用户名及密码来完成在命令行界面登录 Docker Hub。

你可以通过`docker logout`退出登录。

##### 拉取镜像

你可以通过`docker search`命令来查找官方仓库中的镜像，并利用`docker pull`命令来将它下载到本地。

例如以 centos 为关键词进行搜索：

```
[root@localhost ~]# docker search centos

NAME                               DESCRIPTION                                     STARS               OFFICIAL            AUTOMATED
centos                             The official build of CentOS.                   5495                [OK]                
ansible/centos7-ansible            Ansible on Centos7                              122                                     [OK]
jdeathe/centos-ssh                 CentOS-6 6.10 x86_64 / CentOS-7 7.6.1810 x86…   111                                     [OK]
consol/centos-xfce-vnc             Centos container with "headless" VNC session…   96                                      [OK]
centos/mysql-57-centos7            MySQL 5.7 SQL database server                   60                                      
imagine10255/centos6-lnmp-php56    centos6-lnmp-php56                              57                                      [OK]
tutum/centos                       Simple CentOS docker image with SSH access      44                                      
centos/postgresql-96-centos7       PostgreSQL is an advanced Object-Relational …   39                                      
kinogmt/centos-ssh                 CentOS with SSH                                 28                                      [OK]
centos/php-56-centos7              Platform for building and running PHP 5.6 ap…   21                                      
pivotaldata/centos-gpdb-dev        CentOS image for GPDB development. Tag names…   10                                      
guyton/centos6                     From official centos6 container with full up…   9                                       [OK]
drecom/centos-ruby                 centos ruby                                     6                                       [OK]
mamohr/centos-java                 Oracle Java 8 Docker image based on Centos 7    3                                       [OK]
darksheer/centos                   Base Centos Image -- Updated hourly             3                                       [OK]
pivotaldata/centos                 Base centos, freshened up a little with a Do…   3                                       
pivotaldata/centos-mingw           Using the mingw toolchain to cross-compile t…   2                                       
miko2u/centos6                     CentOS6 日本語環境                                   2                                       [OK]
pivotaldata/centos-gcc-toolchain   CentOS with a toolchain, but unaffiliated wi…   2                                       
mcnaughton/centos-base             centos base image                               1                                       [OK]
indigo/centos-maven                Vanilla CentOS 7 with Oracle Java Developmen…   1                                       [OK]
blacklabelops/centos               CentOS Base Image! Built and Updates Daily!     1                                       [OK]
pivotaldata/centos7-dev            CentosOS 7 image for GPDB development           0                                       
smartentry/centos                  centos with smartentry                          0                                       [OK]
pivotaldata/centos6.8-dev          CentosOS 6.8 image for GPDB development         0              
```

可以看到返回了很多包含关键字的镜像，其中包括镜像名字、描述、收藏数（表示该镜像的受关注程度）、是否官方创建（OFFICIAL）、是否自动构建 （AUTOMATED）。

根据是否是官方提供，可将镜像分为两类。

一种是类似 centos 这样的镜像，被称为基础镜像或根镜像。这些基础镜像由 Docker 公司创建、验证、支持、提供。这样的镜像往往使用单个单词作为名字。

还有一种类型，比如 tianon/centos 镜像，它是由 Docker Hub 的注册用户创建并维护的，往往带有用户名称前缀。可以通过前缀 username/ 来指定使用某个用户提供的镜像，比如 tianon 用户。

另外，在查找的时候通过`--filter=stars=N`参数可以指定仅显示收藏数量为`N 以上`的镜像。

下载官方 centos 镜像到本地。

```

```

##### 推送镜像

用户也可以在登录后通过`docker push`命令来将自己的镜像推送到`Docker Hub`。

以下命令中的`username`请替换为你的`Docker 账号用户名`。

```
# 打标签
docker tag ubuntu:18.04 timebusker/ubuntu:18.04

# 推送到公共仓库
docker push username/ubuntu:18.04

# 在公共仓库中搜索
docker search username

```

##### 自动构建

自动构建（Automated Builds）功能对于需要经常升级镜像内程序来说，十分方便。

有时候，用户构建了镜像，安装了某个软件，当软件发布新版本则需要手动更新镜像。

而自动构建允许用户通过 Docker Hub 指定跟踪一个目标网站（支持 GitHub 或 BitBucket）上的项目，一旦项目发生新的提交 （commit）或者创建了新的标签（tag），Docker Hub 会自动构建镜像并推送到 Docker Hub 中。

要配置自动构建，包括如下的步骤：

- 登录 Docker Hub；
- 在 Docker Hub 点击右上角头像，在账号设置（Account Settings）中关联（Linked Accounts）目标网站；
- 在 Docker Hub 中新建或选择已有的仓库，在 Builds 选项卡中选择 Configure Automated Builds；
- 选取一个目标网站中的项目（需要含 Dockerfile）和分支；
- 指定 Dockerfile 的位置，并保存。
- 之后，可以在 Docker Hub 的仓库页面的 Timeline 选项卡中查看每次构建的状态。

### [私有仓库](https://yeasy.gitbooks.io/docker_practice/content/repository/registry.html)

有时候使用 Docker Hub 这样的公共仓库可能不方便，用户可以创建一个本地仓库供私人使用。

[docker-registry](https://docs.docker.com/registry/)是官方提供的工具，可以用于构建私有的镜像仓库。本文内容基于`docker-registry v2.x `版本。

##### 安装运行 docker-registry

- 容器运行

你可以通过获取官方`registry`镜像来运行。


### [私有仓库高级配置](https://yeasy.gitbooks.io/docker_practice/content/repository/registry_auth.html)



### [Nexus3.x 的私有仓库](https://yeasy.gitbooks.io/docker_practice/content/repository/nexus3_registry.html)









































