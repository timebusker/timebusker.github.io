---
layout:     post
title:      使用Docker
date:       2019-07-27
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Docker
---  

> Docker 运行容器前需要本地存在对应的镜像，如果本地不存在该镜像，Docker 会从镜像仓库下载该镜像。

### 获取镜像

之前提到过，Docker Hub 上有大量的高质量的镜像可以用，这里我们就说一下怎么获取这些镜像。

从 Docker 镜像仓库获取镜像的命令是`docker pull`。其命令格式为：    

`docker pull [选项] [Docker Registry 地址[:端口号]/]仓库名[:标签]`

具体的选项可以通过 docker pull --help 命令看到，这里我们说一下镜像名称的格式。

- Docker 镜像仓库地址：地址的格式一般是`<域名/IP>[:端口号]`。默认地址是`Docker Hub`。

- 仓库名：如之前所说，这里的仓库名是两段式名称，即`<用户名>/<软件名>`。对于 Docker Hub，如果不给出用户名，则默认为 library，也就是官方镜像。

```
18.04: Pulling from library/ubuntu
7413c47ba209: Pull complete 
0fe7e7cbb2e8: Pull complete 
1d425c982345: Pull complete 
344da5c95cec: Pull complete 
Digest: sha256:c303f19cfe9ee92badbbbd7567bc1ca47789f79303ddcef56f77687d4744cd7a
Status: Downloaded newer image for ubuntu:18.04
docker.io/library/ubuntu:18.04
```

上面的命令中没有给出 Docker 镜像仓库地址，因此将会从`Docker Hub`获取镜像。而镜像名称是`ubuntu:18.04`，
因此将会获取官方镜像`library/ubuntu`仓库中标签为 18.04 的镜像。

从下载过程中可以看到我们之前提及的`分层存储的概念`，镜像是由`多层存储所构成`。下载也是一层层的去下载，并非单一文件。
下载过程中给出了每一层的 ID 的前 12 位。并且下载结束后，给出该镜像完整的`sha256`的摘要，以确保下载一致性。

在使用上面命令的时候，你可能会发现，你所看到的层 ID 以及 sha256 的摘要和这里的不一样。这是因为官方镜像是一直在维护的，
有任何新的 bug，或者版本更新，都会进行修复再以原来的标签发布，这样可以确保任何使用这个标签的用户可以获得更安全、更稳定的镜像。

##### 运行

有了镜像后，我们就能够以这个镜像为基础启动并运行一个容器。以上面的 ubuntu:18.04 为例，
如果我们打算启动里面的 bash 并且进行交互式操作的话，可以执行下面的命令。

```
docker run -it --rm \
>     ubuntu:18.04 \
>     bash


root@f60dae56edd7:/# cat /etc/os-release
NAME="Ubuntu"
VERSION="18.04.2 LTS (Bionic Beaver)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 18.04.2 LTS"
VERSION_ID="18.04"
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=bionic
UBUNTU_CODENAME=bionic
root@f60dae56edd7:/# 

```

`root@f60dae56edd7:/# ` 表示已经进入容器内部。

docker run 就是运行容器的命令，具体格式我们会在 容器 一节进行详细讲解，我们这里简要的说明一下上面用到的参数。

- `-it`：这是两个参数，一个是 -i：交互式操作，一个是 -t 终端。我们这里打算进入 bash 执行一些命令并查看返回结果，因此我们需要交互式终端。

- `--rm`：这个参数是说容器退出后随之将其删除。默认情况下，为了排障需求，退出的容器并不会立即删除，除非手动 docker rm。我们这里只是随便执行个命令，看看结果，不需要排障和保留结果，因此使用 --rm 可以避免浪费空间。

- `ubuntu:18.04`：这是指用 ubuntu:18.04 镜像为基础来启动容器。

- `bash`：放在镜像名后的是 命令，这里我们希望有个交互式 Shell，因此用的是 bash。

进入容器后，我们可以在 Shell 下操作，执行任何所需的命令。这里，我们执行了`cat /etc/os-release`，
这是 Linux 常用的查看当前系统版本的命令，从返回的结果可以看到容器内是 Ubuntu 18.04.1 LTS 系统。

最后我们通过`exit`退出了这个容器。

### 列出镜像

要想列出已经下载下来的镜像，可以使用`docker image ls`命令。

```
[root@localhost ~]# docker image ls

REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
ubuntu              18.04               3556258649b2        2 weeks ago         64.2MB
hello-world         latest              fce289e99eb9        7 months ago        1.84kB

```

列表包含了`仓库名`、`标签`、`镜像 ID`、`创建时间`以及`所占用的空间`。

`镜像 ID`则是镜像的唯一标识，一个镜像可以对应多个`标签`。因此，在上面的例子中，我们可以看到 ubuntu:18.04 和 ubuntu:latest 拥有相同的 ID，
因为它们对应的是同一个镜像。

##### 镜像体积

Docker Hub 中显示的体积是压缩后的体积。在镜像下载和上传过程中镜像是保持着压缩状态的，因此 Docker Hub 所显示的大小是网络传输中更关心的流量大小。
而 docker image ls 显示的是镜像下载到本地后，展开的大小，准确说，是展开后的各层所占空间的总和，因为镜像到本地后，查看空间的时候，
更关心的是本地磁盘空间占用的大小。

另外一个需要注意的问题是，docker image ls 列表中的镜像体积总和并非是所有镜像实际硬盘消耗。由于 Docker 镜像是多层存储结构，
并且可以继承、复用，因此不同镜像可能会因为使用相同的基础镜像，从而拥有共同的层。由于 Docker 使用 Union FS，相同的层只需要保存一份即可，
因此实际镜像硬盘占用空间很可能要比这个列表镜像大小的总和要小的多。

你可以通过以下命令来便捷的查看镜像、容器、数据卷所占用的空间。

```
[root@localhost ~]# docker system df

TYPE                TOTAL               ACTIVE              SIZE                RECLAIMABLE
Images              2                   1                   64.19MB             64.19MB (99%)
Containers          1                   0                   0B                  0B
Local Volumes       0                   0                   0B                  0B
Build Cache         0                   0                   0B                  0B

```

##### 虚悬镜像

上面的镜像列表中，还可以看到一个特殊的镜像，这个镜像既没有仓库名，也没有标签，均为` <none>。`：

```
<none>               <none>              00285df0df87        5 days ago          342 MB
```

这个镜像原本是有镜像名和标签的，原来为 mongo:3.2，随着官方镜像维护，发布了新版本后，重新 docker pull mongo:3.2 时，
mongo:3.2 这个镜像名被转移到了新下载的镜像身上，而旧的镜像上的这个名称则被取消，从而成为了 <none>。除了 docker pull 可能导致这种情况，
docker build 也同样可以导致这种现象。由于新旧镜像同名，旧镜像名称被取消，从而出现仓库名、标签均为 <none> 的镜像。这类无标签镜像也被称为 
**虚悬镜像(dangling image) **，可以用下面的命令专门显示这类镜像：

```
[root@localhost ~]# docker image ls -f dangling=true

REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
<none>              <none>              00285df0df87        5 days ago          342 MB
```

一般来说，虚悬镜像已经失去了存在的价值，是可以随意删除的，可以用下面的命令删除。

```
[root@localhost ~]# docker image prune

WARNING! This will remove all dangling images.
Are you sure you want to continue? [y/N] y
Total reclaimed space: 0B

```

##### 中间层镜像

为了加速镜像构建、重复利用资源，Docker 会利用 中间层镜像。所以在使用一段时间后，可能会看到一些依赖的中间层镜像。
默认的 docker image ls 列表中只会显示顶层镜像，如果希望显示包括中间层镜像在内的所有镜像的话，需要加`-a`参数。

```
[root@localhost ~]# docker image ls -a

REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
ubuntu              18.04               3556258649b2        2 weeks ago         64.2MB
hello-world         latest              fce289e99eb9        7 months ago        1.84kB

```

这样会看到很多无标签的镜像，与之前的虚悬镜像不同，这些无标签的镜像很多都是中间层镜像，是其它镜像所依赖的镜像。这些无标签镜像不应该删除，
否则会导致上层镜像因为依赖丢失而出错。实际上，这些镜像也没必要删除，因为之前说过，相同的层只会存一遍，而这些镜像是别的镜像的依赖，
因此并不会因为它们被列出来而多存了一份，无论如何你也会需要它们。只要删除那些依赖它们的镜像后，这些依赖的中间层镜像也会被连带删除。

##### 列出部分镜像

不加任何参数的情况下，docker image ls 会列出所有顶层镜像，但是有时候我们只希望列出部分镜像。docker image ls 有好几个参数可以帮助做到这个事情。

```
[root@localhost ~]# docker image ls ubuntu

REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
ubuntu              18.04               3556258649b2        2 weeks ago         64.2MB

```

列出特定的某个镜像，也就是说指定仓库名和标签

```
[root@localhost ~]# docker image ls ubuntu:18.04

REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
ubuntu              18.04               3556258649b2        2 weeks ago         64.2MB

```

除此以外，docker image ls 还支持强大的过滤器参数 --filter，或者简写 -f。之前我们已经看到了使用过滤器来列出虚悬镜像的用法，
它还有更多的用法。比如，我们希望看到在 mongo:3.2 之后建立的镜像，可以用下面的命令：

```
docker image ls -f since=mongo:3.2
```

想查看某个位置之前的镜像也可以，只需要把 since 换成 before 即可。此外，如果镜像构建时，定义了 LABEL，还可以通过 LABEL 来过滤。

```
docker image ls -f label=com.example.version=0.1
```

##### 以特定格式显示

默认情况下，`docker image ls`会输出一个完整的表格，
但是我们并非所有时候都会需要这些内容。比如，刚才删除虚悬镜像的时候，
我们需要利用 docker image ls 把所有的虚悬镜像的 ID 列出来，然后才可以交给 docker image rm 命令作为参数来删除指定的这些镜像，
这个时候就用到了 -q 参数。

```
[root@localhost ~]# docker image ls -q

3556258649b2
fce289e99eb9

```

--filter 配合 -q 产生出指定范围的 ID 列表，然后送给另一个 docker 命令作为参数，从而针对这组实体成批的进行某种操作的做法在 Docker 命令行使用过程中非常常见，
不仅仅是镜像，将来我们会在各个命令中看到这类搭配以完成很强大的功能。因此每次在文档看到过滤器后，可以多注意一下它们的用法。

另外一些时候，我们可能只是对表格的结构不满意，希望自己组织列；或者不希望有标题，这样方便其它程序解析结果等，这就用到了 Go 的模板语法。

```
[root@localhost ~]# docker image ls --format "{{.ID}}: {{.Repository}}"

3556258649b2: ubuntu
fce289e99eb9: hello-world

```

或者打算以表格等距显示，并且有标题行，和默认一样，不过自己定义列：

```
[root@localhost ~]# docker image ls --format "table {{.ID}}\t{{.Repository}}\t{{.Tag}}"

IMAGE ID            REPOSITORY          TAG
3556258649b2        ubuntu              18.04
fce289e99eb9        hello-world         latest

```

### 删除本地镜像

如果要删除本地的镜像，可以使用 docker image rm 命令，其格式为：

```
docker image rm [选项] <镜像1> [<镜像2> ...]
```

其中，`<镜像>` 可以是`镜像短 ID`、`镜像长 ID`、`镜像名(<仓库名>:<标签>)`或者`镜像摘要`。

##### Untagged 和 Deleted

如果观察上面这几个命令的运行输出信息的话，你会注意到删除行为分为两类，一类是 Untagged，另一类是 Deleted。我们之前介绍过，
镜像的唯一标识是其 ID 和摘要，而一个镜像可以有多个标签。

因此当我们使用上面命令删除镜像的时候，实际上是在要求删除某个标签的镜像。所以首先需要做的是将满足我们要求的所有镜像标签都取消，
这就是我们看到的 Untagged 的信息。因为一个镜像可以对应多个标签，因此当我们删除了所指定的标签后，可能还有别的标签指向了这个镜像，
如果是这种情况，那么 Delete 行为就不会发生。所以并非所有的 docker image rm 都会产生删除镜像的行为，有可能仅仅是取消了某个标签而已。

当该镜像所有的标签都被取消了，该镜像很可能会失去了存在的意义，因此会触发删除行为。镜像是多层存储结构，
因此在删除的时候也是从上层向基础层方向依次进行判断删除。镜像的多层结构让镜像复用变得非常容易，因此很有可能某个其它镜像正依赖于当前镜像的某一层。
这种情况，依旧不会触发删除该层的行为。直到没有任何层依赖当前层时，才会真实的删除当前层。这就是为什么，有时候会奇怪，为什么明明没有别的标签指向这个镜像，
但是它还是存在的原因，也是为什么有时候会发现所删除的层数和自己 docker pull 看到的层数不一样的原因。

除了镜像依赖以外，还需要注意的是容器对镜像的依赖。如果有用这个镜像启动的容器存在（即使容器没有运行），
那么同样不可以删除这个镜像。之前讲过，容器是以镜像为基础，再加一层容器存储层，组成这样的多层存储结构去运行的。
因此该镜像如果被这个容器所依赖的，那么删除必然会导致故障。如果这些容器是不需要的，应该先将它们删除，然后再来删除镜像。

##### 用 docker image ls 命令来配合

像其它可以承接多个实体的命令一样，可以使用 docker image ls -q 来配合使用 docker image rm，这样可以成批的删除希望删除的镜像。我们在“镜像列表”章节介绍过很多过滤镜像列表的方式都可以拿过来使用。

```
# 删除所有仓库名为 redis 的镜像
docker image rm $(docker image ls -q redis)
 
# 删除所有在 mongo:3.2 之前的镜像
docker image rm $(docker image ls -q -f before=mongo:3.2)
```

##### CentOS/RHEL 的用户需要注意的事项

在 Ubuntu/Debian 上有 UnionFS 可以使用，如 aufs 或者 overlay2，而 CentOS 和 RHEL 的内核中没有相关驱动。因此对于这类系统，
一般使用 devicemapper 驱动利用 LVM 的一些机制来模拟分层存储。这样的做法除了性能比较差外，稳定性一般也不好，而且配置相对复杂。
Docker 安装在 CentOS/RHEL 上后，会默认选择 devicemapper，但是为了简化配置，其 devicemapper 是跑在一个稀疏文件模拟的块设备上，
也被称为 loop-lvm。这样的选择是因为不需要额外配置就可以运行 Docker，这是自动配置唯一能做到的事情。但是 loop-lvm 的做法非常不好，
其稳定性、性能更差，无论是日志还是 docker info 中都会看到警告信息。官方文档有明确的文章讲解了如何配置块设备给 devicemapper 
驱动做存储层的做法，这类做法也被称为配置 direct-lvm。

除了前面说到的问题外，devicemapper + loop-lvm 还有一个缺陷，因为它是稀疏文件，所以它会不断增长。用户在使用过程中会注意到 
/var/lib/docker/devicemapper/devicemapper/data 不断增长，而且无法控制。很多人会希望删除镜像或者可以解决这个问题，结果发现效果并不明显。
原因就是这个稀疏文件的空间释放后基本不进行垃圾回收的问题。因此往往会出现即使删除了文件内容，空间却无法回收，随着使用这个稀疏文件一直在不断增长。

所以对于 CentOS/RHEL 的用户来说，在没有办法使用 UnionFS 的情况下，一定要配置 direct-lvm 给 devicemapper，无论是为了性能、稳定性还是空间利用率。

或许有人注意到了 CentOS 7 中存在被 backports 回来的 overlay 驱动，不过 CentOS 里的这个驱动达不到生产环境使用的稳定程度，所以不推荐使用。
