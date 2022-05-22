#!/bin/sh
function startGpfdist()
{
  source /usr/local/greenplum-loaders-4.3.16.1/greenplum_loaders_path.sh
  gpfdist -d /nas44/ztfx/greenplum -p 8003 -l /nas44/ztfx/greenplum/gpfdist.8003.log &
  gpfdist -d /nas44/ztfx/greenplum -p 8004 -l /nas44/ztfx/greenplum/gpfdist.8004.log &
}
cnt=`ps -ef |grep /nas44/ztfx/greenplum/gpfdist | grep -v grep| wc -l`
echo  "cnt is ${cnt}"
if [ ${cnt} -eq 2 ] ; then
 echo `date`"gpfdist service is running normally"  >> /usr/local/log_check_gpfdist.txt
else
 echo `date`"restart gpfdist service "  >> /usr/local/log_check_gpfdist.txt
 startGpfdist
fi
