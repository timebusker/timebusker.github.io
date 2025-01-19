---
layout:     post
title:      Linux（CentOS）集群之间实现免密登录
date:       2018-03-15
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Linux
---

> Linux（CentOS）集群之间实现免密登录

#### [配置SSH](#) 
- 修改`集群中每一台机器`的`sshd_config`配置文件  
  修改指令：`sudo vim /etc/ssh/sshd_config`  
  修改内容如下：  
  ```
  RSAAuthentication yes
  PubkeyAuthentication yes
  AuthorizedKeysFile .ssh/authorized_keys
  ```

#### [生成SSH密钥](http://note.youdao.com/noteshare?id=769ed229ebda530d067d808b91e99406&sub=DF72981E9BEA4079954C7FA73E686FC3) 
- 在`集群中每一台机器`上执行下面命令，一路回车，可生成本机的rsa类型的密钥。  
  `ssh-keygen -t rsa`     
  执行完之后在~/.ssh/目录下会生成一个保存有公钥的文件：`id_rsa.pub`。

#### [把公钥写入authorized_keys文件](#) 
- 将`集群中每一台机器`的公钥拷贝到集群中的##Master机##的`/root/.ssh/`目录下  
  操作指令：`ssh-copy-id root@[IP/主机名]` 
  合并后的数据文件如下：  
  ![image](img/older/20180328-1/1.png)  

#### [把authorized_keys文件拷贝到节点](#) 
- 把authorized_keys文件拷贝到节点的`/root/.ssh/`目录下  
   操作指令：  
  `scp root@[IP/主机名]:/root/.ssh/authorized_keys /root/.ssh/`  

#### [重启SSH服务](#) 
- `sudo service sshd restart`

#### [常见免密码登录失败分析](#) 
  - 配置问题
    + 检查配置文件/etc/ssh/sshd_config是否开启了AuthorizedKeysFile选项
    + 检查AuthorizedKeysFile选项指定的文件是否存在并内容正常
  - 目录权限问题
    + ~ 权限设置为700
    + ~/.ssh权限设置为700
    + ~/.ssh/authorized_keys的权限设置为600
    ```
	sudo chmod 700 ~
	sudo chmod 700 ~/.ssh
	sudo chmod 600 ~/.ssh/authorized_keys
	```

#### 拷贝密钥的几种方式
```
# 使用cat + ssh 
cat id_rsa.pub > authorized_keys 
cat /etc/hosts | ssh -p 22 root@169.254.4.11 'cat >> /etc/hosts'

# ssh-copy-id 
ssh-copy-id root@169.254.4.11 

# scp 远程到本地
scp root@169.254.4.11:/root/.ssh/authorized_keys /root/.ssh/
# scp 本地到远程
scp /root/.ssh/ root@169.254.4.11:/root/.ssh/authorized_keys
```
	
##### 查阅博客文章
###### [RedHat中敲sh-copy-id命令报错：-bash: ssh-copy-id: command not found](http://www.bubuko.com/infodetail-1662159.html)
###### [使用ssh-copy-id批量拷贝公钥到远程主机](https://segmentfault.com/a/1190000009832597)
###### [CentOS 配置集群机器之间SSH免密码登录](https://www.cnblogs.com/keitsi/p/5653520.html)  `