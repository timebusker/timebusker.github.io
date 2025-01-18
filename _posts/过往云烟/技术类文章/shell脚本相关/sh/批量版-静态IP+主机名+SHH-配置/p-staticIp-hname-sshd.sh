#!/bin/bash
# Linux集群同步SSH秘钥

# 等号左右不能有空格
# 单引号属于强引用，它会忽略所有被引起来的字符的特殊处理，被引用起来的字符会被原封不动的使用
# 双引号属于弱引用，它会对一些被引起来的字符进行特殊处理

# 配置HostIP配置文件地址
readonly hostips=hosts
readonly username=root
readonly password=timebusker
readonly hprefix=test-
readonly hsuffix=

# 检测输入配置文件
if [ ! -e $hostips ];then
    echo "当前目录下$hostip配置文件不存在！"
        exit 1
else
    echo "$hostips"
fi

# 检测中转配置文件，存在删除
rm -f /tmp/tmp_hosts
rm -f /tmp/tmp_authorized_keys

# 公共服务器IP(当前服务器IP)
# now_server_ip=$(head -1 hostips)
netcard=$(ls /sys/class/net | awk '{print $1}' | grep eth)
nowip=$(ifconfig $netcard | grep 'inet addr:' | awk '{print $2}' | cut -d ':' -f 2)
echo 'now_server_ip:$now_server_ip' 

cat /tmp/tmp_hosts <<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

comm_server_hosts
EOF


# 设置集群主机名，生成秘钥和hosts IP映射主机名配置
for ip in $(cat $hostips)
do
  ip_last=$(echo $ip |awk -F'.' '{print $4}')
  hostname="$hprefix$ip_last$hsuffix"
  ehosts="$ip $hostname"
  # echo $ehosts >> /etc/hosts
  /usr/bin/expect <<-EOF
  set timeout 10
  spawn ssh $username@${ip}
  expect {
      "*yes/no" { send "yes\r"; exp_continue }
      "*password:" { send "$password\r" }
  }
  expect "*Last login:"
  send "echo $ehosts >> /etc/hosts\r"
  send "sed -i s/HOSTNAME.*/HOSTNAME=$hostname/ /etc/sysconfig/network\r"
  expect "~]#"
  
  send "exit\r"
  expect eof
EOF
done