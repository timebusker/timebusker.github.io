#!/bin/bash
# -------------------------------------------------------------
# 静态IP设置
# -------------------------------------------------------------
subip=$1
if [ ! -n "$subip" ] ; then 
   echo -n "请输入IP尾号："
   read subip
   if [ ! -n "$subip" ] ; then 
      echo "IP尾号为空，IP配置失败！"
	  exit 1
   fi
fi
# hosts、公钥中转服务器
comm_ip=12.12.12.9
netmask=255.255.255.0
gateway=12.12.12.1
newip=$(echo $gateway | cut -d '.' -f -3).$subip
netcard=$(ifconfig -a | grep 'Link encap:Ethernet' | awk '{print $1}')
netfile=/etc/sysconfig/network-scripts/ifcfg-$netcard
nowip=$(ifconfig $netcard | grep 'inet addr:'| awk '{print $2}' | cut -c 6-)

echo "netcard:$netcard、gateway：$gateway、netmask：$netmask、newip：$newip、nowip：$nowip"   

# 删除多余配置文件，避免冲突
rm -f /etc/sysconfig/network-scripts/ifcfg-eth*

cat > $netfile << EOF
DEVICE=$netcard
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=yes
BOOTPROTO=static
IPADDR=$newip
NETMASK=$netmask
GATEWAY=$gateway
EOF

# -------------------------------------------------------------
# 主机名设置
# -------------------------------------------------------------
hname=hdp
if [ ! -n "$hname" ] ; then 
   echo -n "请输入服务类型：（eg:mysql、hive.）"
   read hname
   if [ ! -n "$hname" ] ; then 
      echo "服务类型为空，配置失败！"
	  exit 1
   fi
fi
readonly prefix=test-
if [ ! -n $subip ]; then 
   IP=$(ifconfig -a | grep 'inet addr'| grep -v '127.0.0' | awk '{print $2}'|tr -d 'addr:')
   IPSTR=$(echo $IP |awk -F'.' '{print $4}')
else 
   IPSTR=$subip
   IP=$newip
fi

# change hosts
cat > /etc/hosts << EOF
127.0.0.1          localhost localhost.localdomain localhost4 localhost4.localdomain4
::1                localhost localhost.localdomain localhost6 localhost6.localdomain6


12.12.12.9          www.timebusker.com
12.12.12.9          dbserver.timebusker.com
$IP          $prefix$hname-$IPSTR
EOF

# change /etc/sysconfig/network
sed -i "s/HOSTNAME.*/HOSTNAME=$prefix$hname-$IPSTR/" /etc/sysconfig/network 

# -------------------------------------------------------------
# 设置SSH
# -------------------------------------------------------------
ssh_file="/etc/ssh/sshd_config"
sed -i "s/^#RSAAuthentication\ yes/RSAAuthentication\ yes/g" $ssh_file
sed -i "s/^#PubkeyAuthentication\ yes/PubkeyAuthentication yes/g" $ssh_file
sed -i "s/^#AuthorizedKeysFile* /AuthorizedKeysFile\ .ssh/authorized_keys/g" $ssh_file
sed -i "s/^#PermitRootLogin\ yes/PermitRootLogin\ yes/g" $ssh_file
sed -i "s/^#PasswordAuthentication\ yes/PasswordAuthentication\ yes/g" $ssh_file

rm -rf /root/.ssh/

ssh-keygen -t rsa -P '' -f /root/.ssh/id_rsa
cat /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys

sudo chmod 700 /root
sudo chmod 700 /root/.ssh
sudo chmod 600 /root/.ssh/authorized_keys

# 其他常用操作服务
# 关闭防火墙
service iptables stop    
chkconfig iptables off  

sed -i "s/^SELINUX=* /SELINUX=disabled/g" /etc/sysconfig/selinux

# Linux操作系统核对系统资源状态并汇总，默认发送到root用户的/var/spool/mail/root目录
# echo 'unset MAILCHECK' >> /etc/profile
source /etc/profile

# reboot network
# service network restart
# reboot sshd
# service sshd restart
reboot