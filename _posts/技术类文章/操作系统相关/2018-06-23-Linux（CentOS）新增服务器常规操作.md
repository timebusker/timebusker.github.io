---
layout:     post
title:      Linux（CentOS）新增服务器常规操作
date:       2018-09-23
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Linux
---

> Linux（CentOS）新增服务器常规操作

### 设置Linux启动模式
```
# 7种启动模式
# vim /etc/inittab
0:关机
1:单用户
2:多用户状态没有网络服务
3:多用户状态有网络服务
4:系统未使用保留给用户
5:图形界面
6:系统重启

id:5:initdefault  ==》  id:3:initdefault
``` 

### 终端vim中文乱码
设置/root/或者当前用户目录下的`.vimrc`文件，增加`fileencodings、enc、fencs`三项配置
```
vim ~/.vimrc    #或者vim /home/oracle(用户名)/.vimrc
#添加如下代码
set fileencodings=utf-8,gb2312,gb18030,gbk,ucs-bom,cp936,latin1
set enc=utf8
set fencs=utf8,gbk,gb2312,gb18030
```

### 添加开机启动任务计划   

```
# 添加系统启动服务，设置卡机启动    
chkconfig --add /etc/init.d/mysqld
chkconfig mysqld on 


```  

### 修改yum源     

```
# 1备份
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
# 2下载新的CentOS-Base.repo 到/etc/yum.repos.d/
# CentOS 5
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-5.repo
# 或者
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-5.repo
# CentOS 6
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
# 或者
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
# CentOS 7
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
# 或者
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
```  

### 卸载预装软件

```
# 卸载MySQL
yum list installed | grep mysql 
yum list installed | grep firefox 
yum list installed | grep java 


#卸载JDK
yum remove mysql-libs.x86_64
yum remove mysql-libs.x86_64
yum remove mysql-libs.x86_64
-----
```

### 关闭不必要配置   

```
# 关闭防火墙
service iptables stop    
chkconfig iptables off  

# 

```

### 常用软件安装   

```
yum install -y expect
yum install -y lrzsz
yum install -y vim
yum -y install ntp ntpdate
yum install openssh-clients
```

### JDK环境  

```
# vim /root/.bashrc  设置成当前用户
JAVA_HOME=/usr/java/jdk1.8.0_181/
PATH=$PATH:$JAVA_HOME/bin/
export JAVA_HOME PATH 
```   

### 关闭邮件提醒——`You have new mail in /var/spool/mail/root`

```
echo "unset MAILCHECK">> /etc/profile
``` 

### 关闭SElinux
SElinux是强制访问控制(MAC)安全系统，是linux历史上最杰出的新安全系统。对于linux安全模块来说，SElinux的功能是最全面的，测试也是最充分的，这是一种基于内核的安全系统。   

```
# 永久
vim /etc/sysconfig/selinux  
SELINUX=enforcing 改为 SELINUX=disabled
# 永久
vim /etc/selinux/config
将SELINUX=enforcing改为SELINUX=disabled

# 临时关闭
getenforce 
setenforce 0

# 查看状态
/usr/sbin/sestatus
```    
- getenforce 命令是单词get（获取）和enforce(执行)连写，可查看selinux状态，与setenforce命令相反。
- setenforce 命令则是单词set（设置）和enforce(执行)连写，用于设置selinux防火墙状态，如： setenforce 0用于关闭selinux防火墙，但重启后失效

### SSH配置

```
# 清除原有SSH
rm -rf /root/.ssh/

# 生成秘钥
ssh-keygen -t rsa -P '' -f /root/.ssh/id_rsa
cat /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys

# 修改权限
sudo chmod 700 /root
sudo chmod 700 /root/.ssh
sudo chmod 600 /root/.ssh/authorized_keys

# SSH服务配置
sed -i "s/^#RSAAuthentication\ yes/RSAAuthentication\ yes/g" /etc/ssh/sshd_config
sed -i "s/^#PubkeyAuthentication\ yes/PubkeyAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/^#AuthorizedKeysFile* /AuthorizedKeysFile\ .ssh/authorized_keys/g" /etc/ssh/sshd_config
sed -i "s/^#PermitRootLogin\ yes/PermitRootLogin\ yes/g" /etc/ssh/sshd_config
sed -i "s/^#PasswordAuthentication\ yes/PasswordAuthentication\ yes/g" /etc/ssh/sshd_config
```   

### SSH客户端、服务配置
解决SSH连接缓慢甚至导致`Connection closed by 12.12.12.23`情况.   
——使用`ssh -v 12.12.12.23`查看连接详细信息进行排查.

```
# 关闭DNS反向解析
# 在linux中，默认就是开启了SSH的反向DNS解析,这个会消耗大量时间，因此需要关闭。
# 在配置文件中，虽然UseDNS yes是被注释的，但默认开关就是yes
# vim /etc/ssh/sshd_config
UseDNS=no

# 关闭SERVER上的GSS认证
# 在authentication gssapi-with-mic有很大的可能出现问题，因此关闭GSS认证可以提高ssh连接速度。
# vim /etc/ssh/sshd_config
GSSAPIAuthentication no

# 修改server上nsswitch.conf文件
# 含义是对于访问的主机进行域名解析的顺序，是先访问file，也就是/etc/hosts文件，如果hosts中没有记录域名，则访问dns，进行域名解析，
# 如果dns也无法访问，就会等待访问超时后返回，因此等待时间比较长。
# vim /etc/nsswitch.conf
# hosts： files dns  改为 hosts：files   

# GSSAPI(Generic Security Services Application Programming Interface)是一套类似Kerberos 5的通用网络安全系统接口。
# vim /etc/ssh/sshd_config
# GSSAPIAuthentication yes  改为  GSSAPIAuthentication no 
```   

### Linux磁盘重新分区操作   
```
# 查看各分区磁盘情况
df -h

# 先卸载需要操作的分区 
umount /home
# 如果提示无法卸载，则是有进程占用/home，使用如下命令来终止占用进程：  
fuser -m /home

# 调整分区大小，指定分区大小
#（指定分区能使用逻辑卷的大小，但是之前占用的空间并未释放出来，下一步是需要释放出空间）
# resize2fs 为重新设定磁盘大小，只是重新指定一下大小，并不对结果有影响，需要下面lvreduce的配合
resize2fs -p /dev/mapper/VolGroup-lv_home 20G
# 如果提示运行“e2fsck -f /dev/mapper/VolGroup-lv_home”，则执行相关命令后再重复执行上述命令
e2fsck -f /dev/mapper/VolGroup-lv_home
resize2fs -p /dev/mapper/VolGroup-lv_home 20G

# 挂载上/home，查看磁盘使用情况
mount /home
df -h

# 设置空闲空间
# 使用lvreduce指令用于减少LVM逻辑卷占用的空间大小。可能会删除逻辑卷上已有的数据，所以在操作前必须进行确认。记得输入 “y”
# lvreduce -L 20G的意思为设置当前文件系统为20G，如果lvreduce -L -20G是指从当前文件系统上减少20G
# 使用lvreduce减小逻辑卷的大小。注意：减小后的大小不能小于文件的大小，否则会丢失数据。
lvreduce -L 20G /dev/mapper/VolGroup-lv_home

# 使用vgdisplay命令等查看一下可以操作的大小，vgdisplay为显示LVM卷组的元数据信息
vgdisplay

# 把闲置空间挂在到特定分区上
# lvextend -L +221G为在文件系统上增加221G
lvextend -L +221G /dev/mapper/VolGroup-lv_root
# 重置指定分区大小
resize2fs -p /dev/mapper/VolGroup-lv_root

# 最后检查调整结果
df -h
```   




