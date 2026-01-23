#!/bin/bash
/etc/init.d/ipmi start
IP=$(ipmitool -I open lan print 1 | grep 'IP Address' | grep 193 | awk -F"." '{print $2"."$3"."$4}')
#eth0
#IP2=$(($(ipmitool -I open lan print 1 | grep 'IP Address' | grep 177 | awk -F"." '{print $3}') + 2))
#eth2
#IP3=$(($(ipmitool -I open lan print 1 | grep 'IP Address' | grep 177 | awk -F"." '{print $3}') + 4))
#change eth0
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE=eth0
BOOTPROTO=static
ONBOOT=yes
MASTER=bond0
SLAVE=yes
USERCTL=no
NM_CONTROLLED=no
EOF

#change eth0
cat > /etc/sysconfig/network-scripts/ifcfg-eth1 << EOF
DEVICE=eth1
BOOTPROTO=static
ONBOOT=yes
MASTER=bond0
SLAVE=yes
USERCTL=no
NM_CONTROLLED=no
EOF

#bonding
cat > /etc/sysconfig/network-scripts/ifcfg-bond0 << EOF
DEVICE=bond0
ONBOOT=yes
BOOTPROTO=static
IPADDR=192.$IP
NETMASK=255.255.255.0
USERCTL=no
NM_CONTROLLED=no
BONDING_OPTS="mode=0 miimon=100"
EOF

#cat > /etc/modprobe.d/bonding.conf << EOF
#alias bond0 bonding
#options bonding mode=4 miimon=100
#EOF

#change eth2
cat > /etc/sysconfig/network-scripts/ifcfg-eth2 << EOF
DEVICE=eth2
BOOTPROTO=static
ONBOOT=yes
MASTER=bond1
SLAVE=yes
USERCTL=no
NM_CONTROLLED=no
EOF

#change eth3
cat > /etc/sysconfig/network-scripts/ifcfg-eth3 << EOF
DEVICE=eth3
BOOTPROTO=static
ONBOOT=yes
MASTER=bond1
SLAVE=yes
USERCTL=no
NM_CONTROLLED=no
EOF

#bonding
cat > /etc/sysconfig/network-scripts/ifcfg-bond1 << EOF
DEVICE=bond1
ONBOOT=yes
BOOTPROTO=static
IPADDR=12.$IP
NETMASK=255.255.248.0
USERCTL=no
NM_CONTROLLED=no
BONDING_OPTS="mode=0 miimon=100"
GATEWAY=12.32.124.254
EOF


#stop NetworkManager
#/etc/init.d/NetworkManager stop
#chkconfig NetworkManager off

#reboot network
service network restart
sleep 5

#change hostname
#echo "$(ifconfig eth0 | grep 'inet addr' | awk -F":" '{print $2}' | awk '{print $1}') GZBD-HBASE$IP" >> /etc/hosts
#change /etc/sysconfig/network
#sed -i "s/HOSTNAME.*/HOSTNAME=GZBD-HBASE$IP/" /etc/sysconfig/network 


#rc.local
#sed -i '/test.sh/d' /etc/rc.d/rc.local
#rm -f /root/test.sh


reboot
#shutdown -h now
