#!/usr/bin/expect -f
readonly password=timebusker
readonly subip=192.168.0.

for ((i = 1; i < 254; i++)) 
do /usr/bin/expect << EOF
  set timeout=10 
  spawn ssh root@$subip.$i 
  expect{
     '(yes/no)?'{
       send 'yes\r';
  	   exp_continue
     }
     'password:'{
       send '$password\r';
  	   exp_continue
     }
  }
  expect{
     '~]#'{
	   echo '我已经登录进来：'
	 }
  }
EOF
done