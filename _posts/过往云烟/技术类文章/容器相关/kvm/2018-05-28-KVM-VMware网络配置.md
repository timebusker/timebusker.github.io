---
layout:     post
title:      KVM-VMware网络配置
date:       2018-03-21
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - KVM
---

> Linux安装Nginx服务配置

#### VMware端口转发配置

```
vim /etc/vmware/vmnet8（对应网卡）/nat/nat.conf  
   vim /etc/vmware/vmnet0/nat/nat.conf  
   在[incomingtcp]模块下配置端口映射：
        64005=12.12.12.5:22
        64006=12.12.12.6:22
        64007=12.12.12.7:22
        64008=12.12.12.8:22
        64009=12.12.12.9:22
        
   重启网卡：
   /usr/bin/vmware-networks --stop
   /usr/bin/vmware-networks --start
   
   12.12.12.6 repo.timebusker.com
```

