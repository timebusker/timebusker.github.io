#!/bin/bash

local_ip=$1   #本地ip
remote_ip=$2  #远程ip
local_password="thinker"    #本地root密码
remote_password="thinker"   #远程root密码

local_path=$3               #本地GDS路径(用于scp源目录)：本地gds路径+表名+区域+批次号 eg:/nas44/ztfx/mppexp/tw_wysrf_stat_0755_2017111600
remote_local_path=$4       #远程GDS路径(用于scp目的目录)：本地gds路径+表名+区域+批次号 eg:/mnt/data/mppexp/tw_wysrf_stat_0755_2017111600
remote_hdfs_path=$5        #远程hdfs路径(用于hdfs put)：hive文件目录 eg:/user/hive/warehouse/tw_wysrf_stat_0755/ad=2018011800


result_file="result"`date +%s`".txt"  #hdfs put结果status文件名，用于判断是否hdfs put是否异常


#-----------------------------------expect开始-----------------------------
/usr/bin/expect <<-EOF
set timeout 60

#远程登录
spawn ssh root@$remote_ip
expect {
    "yes/no" {send "yes\r"; exp_continue}
    "*assword:" {send "$remote_password\r"}
}
expect "Last login:"

#执行命令-问题1：scp命令拷贝目录如果目录存在就会将目录copy到该目录下（多层目录）。问题2：scp命令拷贝目录父目录需要存在
#先删除该目录，再创建该目录，最后再删除该目录（删除数据，创建父目录）
send "rm -rf $remote_local_path\r"
send "mkdir -p $remote_local_path\r"
send "rm -rf $remote_local_path\r"

#返回结果
send "echo \$? >/tmp/$result_file\r"
send "scp /tmp/$result_file root@$local_ip:/tmp/$result_file\r"
expect {
    "yes/no" {send "yes\r"; exp_continue}
    "*assword:" {send "$local_password\r"}
}
expect "$result_file"

#清除数据
send "rm -rf /tmp/$result_file\r"

send "exit\r"
send "exit\r"

expect eof
EOF
#-----------------------------------expect结束-----------------------------

#判断是否成功，失败退出
code10=`echo $?`
if [ "${code10}" != "0" ] ; then
    echo "删除目录rm -rf $remote_local_path失败status:${code10}"
    exit ${code10}
fi

#判断是否成功，失败退出
code11=`cat /tmp/${result_file}`
if [ "${code11}" != "0" ] ; then
    echo "删除目录rm -rf $remote_local_path失败status:${code11}"
    exit ${code11}
fi

rm -rf /tmp/$result_file

#-----------------------------------expect开始-----------------------------
/usr/bin/expect <<-EOF
set timeout 30

#本地scp到省厅
spawn scp -r $local_path root@$remote_ip:$remote_local_path
expect {
    "yes/no" {send "yes\r"; exp_continue}
    "*assword:" {send "$remote_password\r"}
}

set timeout 3600
expect {
    "100%" { exp_continue }
    timeout { expect eof; exit 101 }
    eof
}

EOF
#-----------------------------------expect结束-----------------------------

#判断是否成功，失败退出
code21=`echo $?`
if [ "${code21}" != "0" ] ; then
    echo "scp -r ${local_path} root@${remote_ip}:${remote_local_path}失败status:${code21}"
    exit ${code21}
fi

#-----------------------------------expect开始-----------------------------
/usr/bin/expect <<-EOF
set timeout 30

#远程登录
spawn ssh root@$remote_ip
expect {
    "yes/no" {send "yes\r"; exp_continue}
    "*assword:" {send "$remote_password\r"}
}
expect "Last login:"

set timeout 1800
#执行命令
send "/usr/bin/hdfs2 '$remote_local_path/*' '$remote_hdfs_path'\r"

#返回结果
send "echo \$? >/tmp/$result_file\r"
send "scp /tmp/$result_file root@$local_ip:/tmp/$result_file\r"
expect {
    "yes/no" {send "yes\r"; exp_continue}
    "*assword:" {send "$local_password\r"}
}
expect "$result_file"

#清除数据
send "rm -rf /tmp/$result_file\r"
send "rm -rf $remote_local_path\r"

send "exit\r"
send "exit\r"

expect eof
EOF
#-----------------------------------expect结束-----------------------------

#判断是否成功，失败退出
code31=`echo $?`
if [ "${code31}" != "0" ] ; then
    echo "/usr/bin/hdfs2 ${remote_local_path}/* ${remote_hdfs_path}失败status:${code31}"
    exit ${code31}
fi

#判断是否成功，失败退出
code32=`cat /tmp/${result_file}`
if [ "${code32}" != "0" ] ; then
    echo "/usr/bin/hdfs2 ${remote_local_path}/* ${remote_hdfs_path}失败status:${code32}"
    exit ${code32}
fi

rm -rf /tmp/$result_file
