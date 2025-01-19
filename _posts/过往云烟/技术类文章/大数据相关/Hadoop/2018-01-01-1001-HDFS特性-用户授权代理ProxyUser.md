---
layout:     post
title:      HDFS特性-用户授权代理ProxyUser
date:       2018-12-15
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Hadoop
---

#### [Hadoop权限认证管理用户指南](http://hadoop.apache.org/docs/r1.0.4/cn/hdfs_permissions_guide.html#%E6%A6%82%E8%BF%B0)

#### 介绍
Hadoop2.0版本开始支持`ProxyUser`的机制。含义是使用`User A`的用户认证信息，以`User B`的名义去访问`hadoop集群`——用户授权代理认证服务，可以简单抽象到角色赋值过程。

对于服务端来说就认为此时是`User B`在访问集群，相应对访问请求的鉴权（包括**`HDFS`文件系统的权限，`YARN`提交任务队列的权限**）都以用户`User B`来进行。

`User A`被认为是`superuser`（这里super user并不等同于hdfs中的超级用户，只是拥有代理某些用户的权限，对于hdfs来说本身也是普通用户），`User B`被认为是`proxyuser`。

#### 应用场景
在`Hadoop`的用户认证机制中，如果使用的是`Simple`认证机制，实际上`ProxyUser`的使用意义并不大，因为客户端本身就可以使用任意用 户对服务端进行访问，
服务端并不会做认证。而在使用了安全认证机制（例如`Kerberos`）的情况下，`ProxyUser`认证机制就很有作用：
- 用户的管理会比较繁琐，每增加一个新的用户，都需要维护相应的认证信息（`kerberosKeyTab`），使用`ProxyUser`的话，只需要维护少量`superuser`的认证信息，
而新增用户只需要添加`proxyuser`即可，`proxyuser`本身不需要认证信息。

- 通常的安全认证方式，适合场景是不同用户在不同的客户端上提交对集群的访问；
而实际应用中，通常有第三方用户平台或系统会统一用户对集群的访问，并且执行一系列任务调度逻辑，
例如`Oozie`、华为的BDI系统等。此时访问集群提交任务的实际只有一个客户端。使用`ProxyUser`机制，则可以在这一 个客户端上，实现多个用户对集群的访问。
![image](img/older/hadoop/hdfs/1.png)   
使用ProxyUser访问hadoop集群，访问请求的UGI对象中实际包含了以下信息：
- proxyUser用户名
- superUser用户名
- superUser的认证信息

在非ProxyUser方式访问，UGI中只包含了普通用户及其认证信息。 通过ProxyUser方式访问hadoop集群，认证鉴权流程如下：
![image](img/older/hadoop/hdfs/2.png) 
- 对SuperUser进行认证，在Simple认证模式下直接通过认证，在Kerberos认证模式下，会验证ticket的合法性。
- 代理权限认证，即认证`SuperUser`是否有权限代理`proxyUser`。权限认证的逻辑的实现可以通过`hadoop.security.impersonation.provider.class`参数指定。在默认实现中通过一系列参数可以指定每个`SuperUser`允许代理用户的范围。
- 访问请求鉴权，即验证`proxyUser`是否有权限对集群（`hdfs`文件系统访问或者`yarn`提交任务到资源队列）的访问。这里的鉴权只是针对`proxyUser`用户而已经与`SuperUser`用户无关，及时`superUser`用户有权限访问某个目录，而`proxyUser`无权限访问，此时鉴权 也会返回失败。

#### 配置使用
服务端需要在`NameNode`和`ResourceManager`的`core-site.xml`中进行代理权限相关配置。
<table> 
 <thead> 
  <tr> 
   <th>配置</th> 
   <th>说明</th> 
  </tr> 
 </thead> 
 <tbody> 
  <tr> 
   <td>hadoop.proxyuser.$superuser.hosts</td> 
   <td>配置该superUser允许通过代理访问的主机节点</td> 
  </tr> 
  <tr> 
   <td>hadoop.proxyuser.$superuser.groups</td> 
   <td>配置该superUser允许代理的用户所属组</td> 
  </tr> 
  <tr> 
   <td>hadoop.proxyuser.$superuser.users</td> 
   <td>配置该superUser允许代理的用户</td> 
  </tr> 
 </tbody> 
</table>

> 对于每个superUser用户，hosts必须进行配置，而groups和users至少需要配置一个, `* 符号代表所有，多个配置项逗号隔开`

