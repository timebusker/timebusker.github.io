#!/bin/bash 
 
Date=`date +%Y%m%d` 
LogFile="/var/log/rsync_yum/$Date.log" 
CentOSTrunkVer="6" 
CentOSCurrentVer="6.5" 
CentOSCurrentv="6.5" 
ReceiveMail="nathanzhou@mysite.com" 
Cpanpath="/data0/yum/mirrors.sohu.com/CPAN/" 
RsyncBin="/usr/bin/rsync" 
RsyncPerm="-avrt --delete --exclude=debug/  --exclude=isos/" 
CentOS_Trunk_Ver_Path="/data0/yum/mirrors.sohu.com/centos/$CentOSTrunkVer" 
CentOS_Current_Ver_Path="/data0/yum/mirrors.sohu.com/centos/$CentOSCurrentVer" 
CentOS_Current_v_Path="/data0/yum/mirrors.sohu.com/centos/$CentOSCurrentv" 
YumSiteList="rsync://mirrors.sohu.com/centos" 
Cpansitelist="cpan.wenzk.com::CPAN" 
#============ epel ============== 
epelSite="rsync://mirrors.sohu.com/fedora-epel/" 
epelLocalPath="/data0/yum/mirrors.sohu.com/epel" 
 
# rpmforge 
rpmforgeSite="rsync://mirrors.sohu.com/dag/redhat/" 
rpmforgeLocalPath="/data0/yum/mirrors.dzwww.com/rpmforce" 
# CPAN mirrors 
cpansite="rsync://mirrors.sohu.com/nginx/" 
cpanlocalpath="/data0/yum/mirrors.sohu.com/CPAN/" 
 
echo "---- $Date `date +%T` Begin ----" >>$LogFile 
#CPAN 
$RsyncBin $RsyncPerm $Cpansitelist $cpanlocalpath >> $LogFile 
# centos 5 
$RsyncBin $RsyncPerm $YumSiteList/$CentOSTrunkVer/ \ 
$CentOS_Trunk_Ver_Path >> $LogFile 
 
# centos 5.5 
$RsyncBin $RsyncPerm $YumSiteList/$CentOSCurrentVer/ \ 
$CentOS_Current_Ver_Path  >> $LogFile 
# centos 4.8 
$RsyncBin $RsyncPerm $YumSiteList/$CentOSCurrentv/ \ 
$CentOS_Current_v_Path  >> $LogFile 
# epel 
$RsyncBin $RsyncPerm  --exclude=4/ --exclude=4AS/ --exclude=4AS/ \ 
--exclude=4WS/  --exclude=beta/ --exclude=testing/ $epelSite $epelLocalPath >> $LogFile 
 
# rpmforge 
$RsyncBin $RsyncPerm $rpmforgeSite $rpmforgeLocalPath >> $LogFile 
 
# CPAN 
#$RsyncBin $RsyncPerm $cpansite $cpanlocalpath >> $LogFile 
 
echo  "---- $Date `date +%T` End ----" >> $LogFile 