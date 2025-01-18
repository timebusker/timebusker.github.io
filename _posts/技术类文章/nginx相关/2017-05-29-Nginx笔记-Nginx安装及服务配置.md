---
layout:     post
title:      Nginx安装及服务配置
date:       2017-05-29
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Nginx
---

### Nginx安装 
#### 安装编译工具及库文件                
```
# gcc、gcc-c++ Nginx编译环境
# pcre 为了Nginx的rewrite重写提供支持
# zlib 为了Nginx的gzip压缩提供支持
# 
yum -y install make zlib zlib-devel gcc gcc-c++ libtool  openssl openssl-devel
```  

#### 安装 PCRE         
+ PCRE是正则表达式库，让nginx支持rewrite需要安装这个库。下载 PCRE 安装包   
  下载地址： http://downloads.sourceforge.net/project/pcre/pcre/8.35/pcre-8.35.tar.gz
  ```  
  wget http://downloads.sourceforge.net/project/pcre/pcre/8.35/pcre-8.35.tar.gz
  ``` 
+ 解压pcre-8.35.tar.gz 
  ```
  tar zxvf pcre-8.35.tar.gz
  ```	   
+ 进入解压后的目录 
  ```
  cd pcre-8.35  
  ```	   	  
+ 配置安装信息
  ```
  ./configure  
  ```	   
+ 编译&&安装
  ```
  # make是用来编译的，它从Makefile中读取指令，然后编译
  # make install是用来安装的，它也从Makefile中读取指令，安装到指定的位置
  make && make install
  ```   

#### Nginx安装                     
+ 下载Nginx安装包，下载地址：http://nginx.org/download/nginx-1.13.9.tar.gz
  ```  
  wget http://nginx.org/download/nginx-1.13.9.tar.gz
  ``` 
+ 解压nginx-1.13.9.tar.gz  

  ```
  tar zxvf nginx-1.13.9.tar.gz 
  ```
  
+ 进入解压后的目录 

  ```
  cd nginx-1.13.9  
  ```	   	  
  
+ 配置安装信息  

  configure命令是用来检测你的安装平台的目标特征的。它定义了系统的各个方面，包括nginx的被允许使用的连接处理的方法，比如它会检测你是不是有CC或GCC，并不是需要CC或GCC，它是个shell脚本，执行结束时，它会创建一个Makefile文件。
  
  ```
  # --user 设置进程用户，默认当前用户
  # --group 设置进程用户组，默认当前
  # --prefix 设置安装目录，默认/usr/local/目录下
  # --with 设置安装参数 
  ./configure --user=root --group=root --prefix=/root/software/ --with-http_stub_status_module --with-http_ssl_module --with-http_realip_module
  ./configure --user=root --group=root --with-http_stub_status_module --with-http_ssl_module --with-http_realip_module
  ```	
  
+ 编译&&安装

  ```
  make && make install
  ``` 
  
+ 检查是否安装成功

  ```
  cd /root/software/nginx-1.13.9/sbin/
  ./nginx -t 
  
  #显示结果：
  nginx: the configuration file /root/nginx-1.13.6/conf/nginx.conf syntax is ok
  nginx: configuration file /root/nginx-1.13.6/conf/nginx.conf test is successful
  ``` 

#### Nginx常用操作指令
                
```
cd /root/software/nginx-1.13.9/sbin/

./nginx                      # 启动
./nginx -s reload            # 重新载入配置文件
./nginx -s reopen            # 重启 Nginx
./nginx -s stop              # 停止 Nginx
```	

#### 安装常见问题

- 启动nginx失败`./sbin/nginx: error while loading shared libraries: libpcre.so.1: cannot open shared object file: No such file or directory`

是因为加载不到`pcre`依赖包，首先需要确认是否已经安装`pcre`。

```
# 检查pcre安装

# 系统自带pcre
ls /lib |grep pcre
# 如果自己手动安装
ls /usr/local/lib |grep pcre


# 新增软连接挂载依赖
ln -s /usr/local/lib/libpcre.so.1 /lib/
# 64位的系统下也加载（centos、redhat会从该目录下加载）
ln -s /usr/local/lib/libpcre.so.1 /lib64/
```

### 相关博客地址

[Linux(CentOS)下设置nginx开机自动启动和chkconfig管理](http://blog.csdn.net/u013870094/article/details/52463026)  
   
[Nginx安装及配置详解](https://www.cnblogs.com/zhouxinfei/p/7862285.html)	  
  	  	   	   
[Nginx 安装配置](http://www.runoob.com/linux/nginx-install-setup.html)	  
  	  
[Linux中Nginx安装与配置详解](https://www.linuxidc.com/Linux/2016-08/134110.htm)   


