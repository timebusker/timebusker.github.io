---
layout:     post
title:      Nginx中的静态资源缓存
date:       2017-06-04
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Nginx
---


> [博客](https://www.cnblogs.com/walls/p/9017821.html)

```
http{
    # 服务器连接的超时时间
    proxy_connect_timeout 10;
	# 连接成功后,等候后端服务器响应时间
    proxy_read_timeout 180;
	# 后端服务器数据回传时间
    proxy_send_timeout 5;
	# 缓冲区的大小
    proxy_buffer_size 16k;
	# 每个连接设置缓冲区的数量为number和每块缓冲区的大小为size
    proxy_buffers 4 32k;
	# 开启缓冲响应的功能以后，在没有读到全部响应的情况下，写缓冲到达一定大小时，nginx一定会向客户端发送响应，直到缓冲小于此值。
    proxy_busy_buffers_size 96k;
	# 设置nginx每次写数据到临时文件的size(大小)限制
    proxy_temp_file_write_size 96k;
	# 从后端服务器接收的临时文件的存放路径
    proxy_temp_path /tmp/temp_dir;
	# 设置缓存的路径和其他参数。被缓存的数据如果在inactive参数（当前为1天）指定的时间内未被访问，就会被从缓存中移除
    proxy_cache_path /tmp/cache levels=1:2 keys_zone=cache_one:100m inactive=1d max_size=10g;
	
    server {
        listen       80 default_server;
        server_name  localhost;
        root /mnt/blog/;
        location / {
		    
        }

        #要缓存文件的后缀，可以在以下设置。
        location ~ .*\.(gif|jpg|png|css|js)(.*) {
		        # nginx缓存里拿不到资源，向该地址转发请求，拿到新的资源，并进行缓存
                proxy_pass http://ip地址:90;
				# 设置后端服务器“Location”响应头和“Refresh”响应头的替换文本
                proxy_redirect off;
				# 允许重新定义或者添加发往后端服务器的请求头
                proxy_set_header Host $host;
				# 指定用于页面缓存的共享内存，对应http层设置的keys_zone
                proxy_cache cache_one;
				# 为不同的响应状态码设置不同的缓存时间
                proxy_cache_valid 200 302 24h;
                proxy_cache_valid 301 30d;
                proxy_cache_valid any 5m;
				# 缓存时间
                expires 90d;
                add_header wall  "hey!guys!give me a star.";
        }
    }

    # 无nginx缓存的blog端口
    server {
        listen  90;
        server_name localhost;
        root /mnt/blog/;
        location / {
		    
        }
    }
}
```