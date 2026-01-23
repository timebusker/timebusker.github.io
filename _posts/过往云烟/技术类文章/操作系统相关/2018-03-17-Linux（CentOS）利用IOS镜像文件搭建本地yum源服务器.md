---
layout:     post
title:      Linux利用IOS镜像文件搭建本地yum源服务器
date:       2018-03-17
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Linux
    - 实践记录
---

> Linux利用IOS镜像文件搭建本地yum源服务器  

> [**切记：Linux文件不能拷贝到Windows系统上，否则导致文件后缀名缺失**](#)  

#### 问题来源
  - 随着内网Linux服务器越来越多，在每台服务器上安装软件，都要先把安装盘上传上去，在配置本地yum服务，即麻烦又费时。可以在内网的一台Linux服务器上安装yum服务，然后其他服务器直接修改repo文件使用yum服务就可以了。
   
### 核心点
  - 屏蔽（删除）原有的yum源镜像配置
  - 将IOS镜像文件中包含的`Packages`上传至内网（本地）服务器，其中可在DVD1与DVD2中找到,其中CD1内安装包更为齐全
  - 将yum源指向内网（本地）服务即可，其中可以通过httpd、Nginx、tomcat、ftp、file:///等方式访问到`Packages`路径

### 操作步骤
#### （一）[镜像挂载操作](https://blog.csdn.net/buxiaoxindasuile/article/details/49612867)  
   - 上传IOS镜像文件到服务器，并将镜像文件挂载到指定目录上，并将镜像内`packages`和`repodata`拷贝出到指定位置，做挂载yum源，避免服务器重启需要反复挂载。  
  
   - 挂载镜像文件指令：  
```mount -t iso9660 -o loop /root/backups/CentOS-6.4-x86_64-bin-DVD1.iso /mnt/centos-packages```         
```mount -o loop /root/backups/CentOS-6.4-x86_64-bin-DVD2.iso /mnt/centos-packages``` 
    
   - 递归拷贝文件指令：**-r**    
```cp -r Packages/ ../```  

#### （二）Nginx服务配置
  - 配置Nginx访问本地文件系统   
  
```
user  root;
worker_processes  2;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;
    sendfile        on;
    #tcp_nopush     on;
    keepalive_timeout  65;
    #gzip  on;

    server {
        listen   80;# 确定80端口没有被占用哦，也可以自定义其他端口号
        server_name  localhost;
        charset utf-8,gbk;
        autoindex on;                        #开启目录浏览功能；
        autoindex_exact_size off;            #关闭详细文件大小统计，让文件大小显示MB，GB单位，默认为b；
        autoindex_localtime on;              #开启以服务器本地时区显示文件修改日期！
        # access_log  /var/log/nginx/access.log;
        
        location /centos-repo {
	       # 指定实际目录绝对路径；
           root /media/; 
        }
	    location /hadoop-utils {
	       # 指定实际目录绝对路径；
           root /media/; 
        }
	    location /hadoop {
	       # 指定实际目录绝对路径；
           root /media/; 
        }
	    location /ambari-server {
	       # 指定实际目录绝对路径；
           root /media/; 
        }
	    location / {
	       # 指定实际目录绝对路径；
           root /media/; 
        }
    }
}
```  
	
#### （三）
  - 更新本地服务器yum源配置信息  
  - 删除/备份`/etc/yum.repos.d/`目录下的repo类文件，编辑新的loacl.repo文件  
  
```
[base]
name=CentOS-$releasever - Base
mirrorlist=http://centos-repo.timebusker.cn/
#baseurl=http://mirror.centos.org/centos/$releasever/os/$basearch/
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6

#released updates 
[updates]
name=CentOS-$releasever - Updates
mirrorlist=http://centos-repo.timebusker.cn/
#baseurl=http://mirror.centos.org/centos/$releasever/updates/$basearch/
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
```  
	
#### （四） 
   - 清除缓存  
     `yum clean all`

   - 更新yum源  
     `yum update`
             
   - 测试安装  
     `yum install openssh-clients`