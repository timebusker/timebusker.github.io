#!/bin/bash

readonly comm_ip="192.168.0.11"
readonly username=root
readonly password=timebusker


# 检测中转配置文件，存在删除
tmp_hosts=/tmp/tmp_hosts
tmp_authorized_keys=/tmp/tmp_authorized_keys

usr/bin/expect <<-EOF
set timeout 10
spawn ssh $username@$comm_ip
expect {
    "*yes/no" { send "yes\r"; exp_continue }
    "*password:" { send "$password\r"; exp_continue }
}
expect "*Last login:"
send "rm -f $tmp_hosts\r"
send "rm -f $tmp_authorized_keys\r"
send "cat /etc/hosts | grep $comm_ip >> $tmp_hosts\r"
send "cat /root/.ssh/id_rsa.pub >> $tmp_authorized_keys\r"
send "exit\r"
expect eof
EOF

# 公共服务器IP(当前服务器IP)
# now_server_ip=$(head -1 hostips)
netcard=$(ls /sys/class/net | awk '{print $1}' | grep eth)
nowip=$(ifconfig $netcard | grep 'inet addr:' | awk '{print $2}' | cut -d ':' -f 2)
nowhosts=$(cat /etc/hosts | grep $nowip)
echo 'now_server_ip:$now_server_ip'