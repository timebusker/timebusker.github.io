---
layout:     post
title:      Nginx中的upstream配置使用
date:       2017-06-02
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Nginx
---

##### 配置例子

定义一组服务器。 这些服务器可以监听不同的端口。 而且，监听在TCP和UNIX域套接字的服务器可以混用。

```
upstream backend {
    server backend1.example.com       weight=5;
    server backend2.example.com:8080;
    server unix:/tmp/backend3;
    server backup1.example.com:8080   backup;
    server backup2.example.com:8080   backup;
	keepalive 80;
}

server {
    location / {
        proxy_pass http://backend;
    }
}
```

定义服务器的地址address和其他参数parameters。 地址可以是域名或者IP地址，端口是可选的，或者是指定“unix:”前缀的UNIX域套接字的路径。
如果没有指定端口，就使用80端口。 如果一个域名解析到多个IP，本质上是定义了多个server。

- weight=number设定服务器的权重，默认是1

- max_fails=number设定Nginx与服务器通信的尝试失败的次数。在fail_timeout参数定义的时间段内，如果失败的次数达到此值，Nginx就认为服务器不可用。在下一个fail_timeout时间段，服务器不会再被尝试。 
失败的尝试次数默认是1。设为0就会停止统计尝试次数，认为服务器是一直可用的。 你可以通过指令`proxy_next_upstream`、 `fastcgi_next_upstream`和`memcached_next_upstream`来配置什么是失败的尝试。 
默认配置时，http_404状态不被认为是失败的尝试。

- fail_timeout=time设定，服务器被认为不可用的时间段，默认情况下，该超时时间是10秒。统计失败尝试次数的时间段。在这段时间中，服务器失败次数达到指定的尝试次数，服务器就被认为不可用。

- backup标记为备用服务器。当主服务器不可用以后，请求会被传给这些服务器。

- down标记服务器永久不可用，可以跟ip_hash指令一起使用。

- keepalive参数设置每个worker进程与后端服务器保持连接的最大数量。这些保持的连接会被放入缓存。 如果连接数大于这个值时，最久未使用的连接会被关闭。需要注意的是，keepalive指令不会限制Nginx进程与上游服务器的连接总数。
 新的连接总会按需被创建。keepalive参数应该稍微设低一点，以便上游服务器也能处理额外新进来的连接。
 
 