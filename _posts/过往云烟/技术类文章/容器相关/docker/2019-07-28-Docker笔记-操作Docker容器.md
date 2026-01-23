---
layout:     post
title:      操作Docker容器
date:       2019-07-28
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Docker
---  

### 启动容器

启动容器有两种方式，一种是基于镜像新建一个容器并启动，另外一个是将在终止状态（stopped）的容器重新启动。

因为 Docker 的容器实在太轻量级了，很多时候用户都是随时删除和新创建容器。

##### 新建并启动

所需要的命令主要为 docker run。

例如，下面的命令输出一个 “Hello World”，之后终止容器。

```
docker run ubuntu:18.04 /bin/echo 'Hello world'

Hello world
```

这跟在本地直接执行 /bin/echo 'hello world' 几乎感觉不出任何区别。

下面的命令则启动一个 bash 终端，允许用户进行交互。

```
docker run -it ubuntu:18.04 /bin/bash
```

其中-t 选项让Docker分配一个伪终端（pseudo-tty）并绑定到容器的标准输入上， -i 则让容器的标准输入保持打开。

在交互模式下，用户可以通过所创建的终端来输入命令，例如：

```
root@31c277947eac:/# ls

bin  boot  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var

```

当利用 docker run 来创建容器时，Docker 在后台运行的标准操作包括：

- 检查本地是否存在指定的镜像，不存在就从公有仓库下载
- 利用镜像创建并启动一个容器
- 分配一个文件系统，并在只读的镜像层外面挂载一层可读写层
- 从宿主主机配置的网桥接口中桥接一个虚拟接口到容器中去
- 从地址池配置一个`ip`地址给容器
- 执行用户指定的应用程序
- 执行`完毕后容器被终止`

##### 启动已终止容器

可以利用`docker container start`命令，直接将一个已经终止的容器启动运行。

容器的核心为所执行的应用程序，所需要的资源都是应用程序运行所必需的。除此之外，并没有其它的资源。可以在伪终端中利用 ps 或 top 来查看进程信息。

```
root@31c277947eac:/# ps

  PID TTY          TIME CMD
    1 pts/0    00:00:00 bash
   12 pts/0    00:00:00 ps

```

可见，容器中仅运行了指定的 bash 应用。这种特点使得 Docker 对资源的利用率极高，是货真价实的轻量级虚拟化。


### 后台运行

更多的时候，需要让 Docker 在后台运行而不是直接把执行命令的结果输出在当前宿主机下。此时，可以通过添加`-d`参数来实现。

下面举两个例子来说明一下。

如果不使用 -d 参数运行容器。

```
[root@localhost ~]# docker run ubuntu:18.04 /bin/sh -c "while true; do echo hello world; sleep 1; done"

hello world
hello world
hello world
hello world

```

如果使用了`-d`参数运行容器。

```
[root@localhost ~]# docker run -d ubuntu:18.04 /bin/sh -c "while true; do echo hello world; sleep 1; done"

6f488ee51e2f3d94adbcf7237db20b6ae3e5951d7779bcfe7c6e9512a5553d35

```

此时容器会在后台运行并不会把输出的结果 (STDOUT) 打印到宿主机上面(输出结果可以用 docker logs 查看)。

注： 容器是否会长久运行，是和`docker run`指定的命令有关，和`-d`参数无关。

使用 -d 参数启动后会返回一个唯一的`id`，也可以通过`docker container ls`命令来查看容器信息。

```
[root@localhost ~]# docker container ls

CONTAINER ID        IMAGE               COMMAND                  CREATED              STATUS              PORTS               NAMES
6f488ee51e2f        ubuntu:18.04        "/bin/sh -c 'while t…"   About a minute ago   Up About a minute                       cranky_einstein
31c277947eac        ubuntu:18.04        "/bin/bash"              2 hours ago          Up 2 hours                              jolly_carson

```

要获取容器的输出信息，可以通过`docker container logs`命令。

```
[root@localhost ~]# docker container logs 6f488ee51e2f

hello world
hello world
hello world
hello world
hello world
hello world
hello world
hello world
hello world
hello world
hello world
hello world
hello world

```

### 终止容器

可以使用`docker container stop <容器ID>`来终止一个运行中的容器。此外，当 Docker 容器中指定的应用终结时，容器也自动终止。

终止状态的容器可以用`docker container ls -a`命令看到。例如

```
[root@localhost ~]# docker container ls -a

CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                          PORTS               NAMES
6f488ee51e2f        ubuntu:18.04        "/bin/sh -c 'while t…"   5 minutes ago       Exited (137) 59 seconds ago                         cranky_einstein
e2773d782759        ubuntu:18.04        "/bin/sh -c 'while t…"   6 minutes ago       Exited (0) 6 minutes ago                            exciting_bouman
31c277947eac        ubuntu:18.04        "/bin/bash"              2 hours ago         Exited (0) About a minute ago                       jolly_carson
255d0f7cd05e        ubuntu:18.04        "/bin/echo 'Hello wo…"   2 hours ago         Exited (0) 2 hours ago                              festive_turing
aea53faf79d8        hello-world         "/hello"                 4 hours ago         Exited (0) 4 hours ago                              focused_antonelli

```

处于终止状态的容器，可以通过`docker container start  <容器ID>`命令来重新启动。

此外，`docker container restart <容器ID>`命令会将一个运行态的容器终止，然后再重新启动它。

### 进入容器

在使用`-d`参数时，容器启动后会进入后台。

某些时候需要进入容器进行操作，包括使用`docker attach`命令或`docker exec`命令，推荐大家使用`docker exec`命令，原因会在下面说明。

##### attach 命令

```
# 启动容器
[root@localhost ~]# docker run -dit ubuntu 

Unable to find image 'ubuntu:latest' locally
latest: Pulling from library/ubuntu
Digest: sha256:c303f19cfe9ee92badbbbd7567bc1ca47789f79303ddcef56f77687d4744cd7a
Status: Downloaded newer image for ubuntu:latest
afaeb358833e0c71806f2fe8bf9bf004116a0d499b0163b03dfb7252339961df


# 查看容器
[root@localhost ~]# docker container ls

CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
afaeb358833e        ubuntu              "/bin/bash"         47 seconds ago      Up 46 seconds                           bold_mestorf

```

**注意： 如果从这个 stdin 中 exit，会导致容器的停止。**

##### exec 命令

> -i -t 参数

docker exec 后边可以跟多个参数，这里主要说明 -i -t 参数。

只用`-i`参数时，由于没有分配伪终端，界面没有我们熟悉的 Linux 命令提示符，但命令执行结果仍然可以返回。

当`-i -t`参数一起使用时，则可以看到我们熟悉的 Linux 命令提示符。

```
docker exec -i afaeb358833e bash

docker exec -it afaeb358833e bash
```

**如果从这个 stdin 中 exit，不会导致容器的停止。这就是为什么推荐大家使用 docker exec 的原因。**

### 导出和导入容器

##### 导出容器

如果要导出本地某个容器，可以使用`docker export`命令。

```
[root@localhost ~]# docker container ls -a

CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                        PORTS               NAMES
afaeb358833e        ubuntu              "/bin/bash"              8 minutes ago       Up 8 minutes                                      bold_mestorf
6f488ee51e2f        ubuntu:18.04        "/bin/sh -c 'while t…"   17 minutes ago      Exited (137) 12 minutes ago                       cranky_einstein
e2773d782759        ubuntu:18.04        "/bin/sh -c 'while t…"   18 minutes ago      Exited (0) 17 minutes ago                         exciting_bouman
31c277947eac        ubuntu:18.04        "/bin/bash"              2 hours ago         Exited (0) 12 minutes ago                         jolly_carson
255d0f7cd05e        ubuntu:18.04        "/bin/echo 'Hello wo…"   2 hours ago         Exited (0) 2 hours ago                            festive_turing
aea53faf79d8        hello-world         "/hello"                 4 hours ago         Exited (0) 4 hours ago                            focused_antonelli

```

指令导出容器：

```
[root@localhost ~]# docker export afaeb358833e > ubuntu.tar

```

##### 导入容器快照

可以使用`docker import`从容器快照文件中再导入为镜像，例如

```
[root@localhost ~]# cat ubuntu.tar | docker import - timebusker/ubuntu:v1.0

sha256:81b26734eb7d4140811df606f23a62bb3fc9fc9ddd080a8775dbeee6944963ef


[root@localhost ~]# docker image ls 
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
timebusker/ubuntu   v1.0                81b26734eb7d        13 seconds ago      64.2MB
ubuntu              18.04               3556258649b2        2 weeks ago         64.2MB
ubuntu              latest              3556258649b2        2 weeks ago         64.2MB
hello-world         latest              fce289e99eb9        7 months ago        1.84kB

```

此外，也可以通过指定 URL 或者某个目录来导入，例如

```
 docker import http://example.com/exampleimage.tgz example/imagerepo
```

***用户既可以使用 docker load 来导入镜像存储文件到本地镜像库，也可以使用 docker import 来导入一个容器快照到本地镜像库。这两者的区别在于容器快照文件将丢弃所有的历史记录和元数据信息（即仅保存容器当时的快照状态），而镜像存储文件将保存完整记录，体积也要大。此外，从容器快照文件导入时可以重新指定标签等元数据信息。***

### 删除容器

可以使用`docker container rm`来删除一个处于终止状态的容器。例如

```
[root@localhost ~]# docker container ls -a

CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                        PORTS               NAMES
afaeb358833e        ubuntu              "/bin/bash"              15 minutes ago      Exited (0) 6 seconds ago                          bold_mestorf
6f488ee51e2f        ubuntu:18.04        "/bin/sh -c 'while t…"   25 minutes ago      Exited (137) 20 minutes ago                       cranky_einstein
e2773d782759        ubuntu:18.04        "/bin/sh -c 'while t…"   25 minutes ago      Exited (0) 25 minutes ago                         exciting_bouman
31c277947eac        ubuntu:18.04        "/bin/bash"              2 hours ago         Exited (0) 20 minutes ago                         jolly_carson
255d0f7cd05e        ubuntu:18.04        "/bin/echo 'Hello wo…"   2 hours ago         Exited (0) 2 hours ago                            festive_turing
aea53faf79d8        hello-world         "/hello"                 4 hours ago         Exited (0) 4 hours ago                            focused_antonelli


[root@localhost ~]# docker container rm afaeb358833e 6f488ee51e2f e2773d782759 31c277947eac 255d0f7cd05e aea53faf79d8 
afaeb358833e
6f488ee51e2f
e2773d782759
31c277947eac
255d0f7cd05e
aea53faf79d8

[root@localhost ~]# docker container ls -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES

```

如果要删除一个运行中的容器，可以添加 -f 参数。Docker 会发送 SIGKILL 信号给容器。

##### 清理所有处于终止状态的容器

用`docker container ls -a`命令可以查看所有已经创建的包括终止状态的容器，如果数量太多要一个个删除可能会很麻烦，用下面的命令可以清理掉所有处于终止状态的容器。

```

docker container prune

```
