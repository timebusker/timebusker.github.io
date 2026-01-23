#!/bin/bash
subip=192.168.0.
gateway=192.168.0.1
netcard=$(ifconfig -a | grep 'Link encap:Ethernet' | awk '{print $1}')
netfile=/etc/sysconfig/network-scripts/ifcfg-$netcard
nowip=$(ifconfig $netcard | grep 'inet addr:'| awk '{print $2}' | cut -c 6-)

# 创建新的网卡文件
rm -f $netfile
touch $netfile

sleep $(($RANDOM%10+1))
# 获取当前可用最小IP
for (( i=5;i<255;i++ )) 
do 
   newip=$subip$i
   # NR==8 指定读取行
   pv=$(ping -c 3 $newip | awk 'NR==7 {print $4}')
   echo $pv
   if $pv -gt 0 ; then
      # 当前IP已被暂用，继续执行
	  if $newip -eq $nowip ; then 
	     echo "可用IP即为当前IP!"
		 exit 1
	  fi
	  echo "$newip is up!"
	  continue
   else 
      echo "$newip is down!"
      break
   fi
done

cat > $netfile << EOF
DEVICE=$netcard
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=yes
BOOTPROTO=static
IPADDR=$newip
NETMASK=255.255.255.0
GATEWAY=$gateway
EOF

# reboot network
service network restart

# reboot