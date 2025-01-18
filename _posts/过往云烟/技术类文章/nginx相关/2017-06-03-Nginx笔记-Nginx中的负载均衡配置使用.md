---
layout:     post
title:      Nginx中的负载均衡配置使用
date:       2017-06-02
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Nginx
---

> [tengine](http://tengine.taobao.org/)新增[健康检查模块](http://tengine.taobao.org/document_cn/http_upstream_check_cn.html)可实现故障自动转移

#### 负载均衡配置&&宕机自动切换

严格来说，nginx自带是没有针对负载均衡后端节点的健康检查的，但是可以通过默认自带的`ngx_http_proxy_module`模块和`ngx_http_upstream_module`模块中的相关指令来完成当后端节点出现故障时，
自动切换到健康节点来提供访问。下面列出这两个模块中相关的指令：

通过配置超时触发请求转移到其他服务器上

```
语法: proxy_connect_timeout time;
默认值: proxy_connect_timeout 60s;
设置与后端服务器建立连接的超时时间。应该注意这个超时一般不可能大于75秒。

语法: proxy_read_timeout time;
默认值: proxy_read_timeout 60s;
定义从后端服务器读取响应的超时。此超时是指相邻两次读操作之间的最长时间间隔，而不是整个响应传输完成的最长时间。
如果后端服务器在超时时间段内没有传输任何数据，连接将被关闭。
```

`也可以设置备份服务器，但只有当访问的服务器异常时才会访问它`。

```

upstream netitcast.com {   
    server  127.0.0.1:6666 weight=1;
    server  127.0.0.1:8080 weight=1;
    server  127.0.0.1:8081 backup;
}
```

#### 常用配置

```
#设定http服务器，利用它的反向代理功能提供负载均衡支持
http {

    #设定mime类型,类型由mime.type文件定义
    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    #设定日志格式
    access_log        /var/log/nginx/access.log;

    #设定负载均衡的服务器列表
    upstream mysvr {
        #weigth参数表示权值，权值越高被分配到的几率越大
        server 192.168.8.1x:3128 weight=5;
        #本机上的Squid开启3128端口,不是必须要squid
        server 192.168.8.2x:80    weight=1;
        server 192.168.8.3x:80    weight=6;
    }
    

    #第一个虚拟服务器
    server {
        #侦听192.168.8.x的80端口
        listen             80;
        server_name    192.168.8.x;

        #对aspx后缀的进行负载均衡请求
        location ~ .*.aspx$ {
            #定义服务器的默认网站根目录位置
            root     /root; 
            #定义首页索引文件的名称
            index index.php index.html index.htm;
            
            #请求转向mysvr 定义的服务器列表
            proxy_pass    http://mysvr ;

            #以下是一些反向代理的配置可删除.

            proxy_redirect off;

            #后端的Web服务器可以通过X-Forwarded-For获取用户真实IP
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

            #允许客户端请求的最大单文件字节数
            client_max_body_size 10m; 

            #缓冲区代理缓冲用户端请求的最大字节数，
            client_body_buffer_size 128k;

            #nginx跟后端服务器连接超时时间(代理连接超时)
            proxy_connect_timeout 90;

            #连接成功后，后端服务器响应时间(代理接收超时)
            proxy_read_timeout 90;

            #设置代理服务器（nginx）保存用户头信息的缓冲区大小
            proxy_buffer_size 4k;

            #proxy_buffers缓冲区，网页平均在32k以下的话，这样设置
            proxy_buffers 4 32k;

            #高负荷下缓冲大小（proxy_buffers*2）
            proxy_busy_buffers_size 64k; 

            #设定缓存文件夹大小，大于这个值，将从upstream服务器传
            proxy_temp_file_write_size 64k;    

        }
    }
}
```