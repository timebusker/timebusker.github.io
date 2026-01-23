---
layout:     post
title:      Linux（CentOS）搭建时间同步服务器
date:       2018-05-30
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Linux
---

> Linux（CentOS）搭建时间同步服务器
> [设置时区，搭建时间同步服务器——date -s "20180809 06:00:00" && hwclock --systohc](https://www.cnblogs.com/boshen-hzb/p/6269378.html) 
> [有道笔记-RHEL6.5中部署NTP（ntp server + client）](http://note.youdao.com/noteshare?id=9cdf4d6be8e8a0d28611b3f64579a718)

https://blog.csdn.net/cocojiji5/article/details/1601590  

https://blog.csdn.net/eagle1830/article/details/62042917/

### 安装NTP服务   
```
# 安装 ntp、ntpdate
yum  install  -y  ntp  ntpdate
```

### 配置NTP服务
```  
# tinker panic 0 这可以保证ntpd在时间差较大时依然工作
tinker panic 0

# YNC_HWCLOCK=yes 允许BIOS与系统时间同步
SYNC_HWCLOCK=yes

# For more information about this file, see the man pages
# ntp.conf(5), ntp_acc(5), ntp_auth(5), ntp_clock(5), ntp_misc(5), ntp_mon(5).

driftfile /var/lib/ntp/drift

# Permit time synchronization with our time source, but do not
# permit the source to query or modify the service on this system.
restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery

# Permit all access over the loopback interface.  This could
# be tightened as well, but to do so would effect some of
# the administrative functions.
restrict 127.0.0.1
restrict -6 ::1

# Hosts on local network are less restricted.
# 允许内网其他机器同步时间
restrict 192.168.0.0 mask 255.255.255.0 nomodify notrap

# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
# 中国这边最活跃的时间服务器 : http://www.pool.ntp.org/zone/cn
server 210.72.145.44 perfer   # 中国国家受时中心
server 202.112.10.36          # 1.cn.pool.ntp.org
server 59.124.196.83          # 0.asia.pool.ntp.org

#broadcast 192.168.1.255 autokey        # broadcast server
#broadcastclient                        # broadcast client
#broadcast 224.0.1.1 autokey            # multicast server
#multicastclient 224.0.1.1              # multicast client
#manycastserver 239.255.254.254         # manycast server
#manycastclient 239.255.254.254 autokey # manycast client

# allow update time by the upper server
# 允许上层时间服务器主动修改本机时间
restrict 210.72.145.44 nomodify notrap noquery
restrict 202.112.10.36 nomodify notrap noquery
restrict 59.124.196.83 nomodify notrap noquery

# Undisciplined Local Clock. This is a fake driver intended for backup
# and when no outside source of synchronized time is available. 

# 外部时间服务器不可用时，以本地时间作为时间服务
server  127.127.1.0     # local clock
fudge   127.127.1.0 stratum 10

# Enable public key cryptography.
#crypto

includefile /etc/ntp/crypto/pw

# Key file containing the keys and key identifiers used when operating
# with symmetric key cryptography. 
keys /etc/ntp/keys

# Specify the key identifiers which are trusted.
#trustedkey 4 8 42

# Specify the key identifier to use with the ntpdc utility.
#requestkey 8

# Specify the key identifier to use with the ntpq utility.
#controlkey 8

# Enable writing of statistics records.
#statistics clockstats cryptostats loopstats peerstats
```

### 服务启动  
```
# 重启服务
service ntpd retart
# 加入开启启动服务
chkconfig ntpd on
# 检查日志
tail /var/log/messages 
# 查看启动端口(默认123)
netstat -tlunp | grep ntp 
``` 

#### [BLOG](http://blog.sina.com.cn/s/blog_bf9b14b20102x19k.html)

#### 问题一：ntpd dead but pid file exists(NTP自动退出问题排查)  
![image](img/older/liunx/practice/1.png)   
默认情况下如果ntp本地时间与上级ntp时间差超过1000s，那么ntp进程就会退出并在系统日志文件中记录。    
```
# 解决办法：使用tinker命令调整该阈值,在配置文件/etc/ntp.conf增加以下内容
# tinker panic 0 这可以保证ntpd在时间差较大时依然工作
tinker panic 0

# YNC_HWCLOCK=yes 允许BIOS与系统时间同步
SYNC_HWCLOCK=yes
```   