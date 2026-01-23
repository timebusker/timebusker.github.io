---
layout:     post
title:      Shell-Expect编程使用指南
subtitle:   Expect编程使用指南
date:       2018-05-29
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Shell
---

> Shell-Expect编程使用指南

#### Expect的安装   
```
yum install expect 

# 所需要的rpm包有： 
expect-5.44.1.15-5.el6_4.x86_64     
tcl.x86_64 1:8.5.7-6.el6  
```
#### Expect工作原理   
从最简单的层次来说，Expect的工作方式象一个通用化的Chat脚本工具。Chat脚本最早用于UUCP网络内，以用来实现计算机之间需要建立连接时进行特定的登录会话的自动化。   
Chat脚本由一系列expect-send对组成：expect等待输出中输出特定的字符，通常是一个提示符，然后发送特定的响应。     

- **语法解释** 
  + `#!/usr/bin/expect`:指定脚本执行解释器,当使用 #!/usr/bin/expect -d 时，expect 脚本将运行在调试模式，届时脚本执行的全过程将被展示出来。  
  + `set timeout`:设置超时时间，计时单位是：秒，timeout -1 为永不超时。当某个 expect 判断未能成功匹配的 30 秒后，将跳过该 expect 判断，执行后续内容。  
  + `spawn`:用来传递交互指令,spawn 是进入 expect 环境后才可以执行的 expect 内部命令，如果没有装 expect 或者直接在默认的 shell 下执行是找不到 spawn 命令的。
  + `expect`:是 expect 程序包的一个内部命令，需要在 expect 环境中执行。该命令用于判断交互中上次输出的结果里**是否包含某些字符串**，如果有则立即返回。否则如果有设置超时时间，则等待超时时长后返回。
  + `send`：用于执行交互动作，与手工输入动作等效。
  + `interact`：执行完成后保持交互状态，把控制权交给控制台,如果只是登录过去执行一段命令就退出，可改为expect eof 
  + `exp_continue`：exp_continue 附加于某个 expect 判断项之后，可以使该项被匹配后，还能继续匹配该 expect 判断语句内的其他项。exp_continue 类似于控制语句中的 continue 语句。

##### 简单示例  
```
# 
#!/usr/bin/expect  
set timeout 30  
spawn ssh root@12.12.12.10
expect "(yes/no)?"
send "yes\r"
expect "password:"
send "timebusker\r"  
interact
```  
##### 嵌套expect的shell脚本    
```shell
#! /bin/bash
for ip in $(cat /root/hosts)
do
  echo ${ip}
  /usr/bin/expect <<-EOF
  set timeout 30
  spawn ssh root@${ip}
  expect {
      "*yes/no" { send "yes\r"; exp_continue }
      "*password:" { send "timebusker\r" }
  }
  expect "*Last login:"
  send "df -h > mine.txt\r"
  expect "*#"
  send "exit\r"
  expect eof
EOF
done
```
![image](img/older/shell/4.png)  

- **注意**  
  + `EOF`标记前后不能有空格等其他符号，结束标记要独立为一行：   
    `warning: here-document at line 6 delimited by end-of-file (wanted `EOF')`    

上述脚本hosts文件内容：     
```
12.12.12.10  
12.12.12.11  
12.12.12.12  
```  