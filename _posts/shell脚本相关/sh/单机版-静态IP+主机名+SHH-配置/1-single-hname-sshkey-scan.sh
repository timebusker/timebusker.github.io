#!/bin/bash

export comm_ip=12.12.12.9
rm -f /root/.ssh/authorized_keys
ssh-copy-id root@$comm_ip

export netcard=$(ls /sys/class/net | grep eth | awk '{print $1}')
export nowip=$(ifconfig $netcard | grep 'inet addr:' | awk '{print $2}' | cut -d ':' -f 2)
export nowhosts=$(cat /etc/hosts | grep $nowip)
cat /etc/hosts | grep $nowip | grep -v timebusker | head -1 | ssh -p 22 root@$comm_ip 'cat >> /etc/hosts'

export sleeptime=$(date +%N | cut -c 8-)

#休眠30秒
# sleep $sleeptime
sleep 30

scp -p root@$comm_ip:/root/.ssh/authorized_keys /root/.ssh/authorized_keys
scp -p root@$comm_ip:/etc/hosts /etc/hosts

# sudo chmod 700 /root
sudo chmod 700 /root/.ssh
sudo chmod 600 /root/.ssh/authorized_keys
