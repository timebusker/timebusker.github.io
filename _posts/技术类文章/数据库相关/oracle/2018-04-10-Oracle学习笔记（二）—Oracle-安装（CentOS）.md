---
layout:     post
title:      Oracle学习笔记（二）— Oracle-安装（CentOS）
date:       2018-04-17
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Oracle
---

> 要修改OS系统标识（Oracle默认不支持CentOS系统安装，但是CentOS其实就是 Red Hat）

### [Oracle官方安装文档](https://docs.oracle.com/cd/E11882_01/install.112/e47689/pre_install.htm#LADBI1085)    

### 安装的硬件要求
- **内存** 
  **内存最小1G，推荐2G或者更高**  
  查看命令：`grep MemTotal /proc/meminfo`    
- **Swap**查看内存信息的相关指令：`grep SwapTotal /proc/meminfo` 、` free`。

  |RAM      |   Swap      |
  |   :-:   |      :-:    |
  |1G至2G   |   1.5倍 RAM |
  |2G至16G  |   同RAW相等 |
  |16G以上  |   16G       |

### 环境准备
- CentOS-6.5 64bit虚拟机
- Oracle安装包 
  + [linux.x64_11gR2_database_1of2.zip](#)
  + [linux.x64_11gR2_database_2of2.zip](#)

### 预安装准备
- **创建运行oracle数据库的系统用户和用户组**  
需要切换到`root`用户进行操作  

```  
#创建用户组oinstall、dba
groupadd oinstall
groupadd dba

#创建oracle用户，并加入到oinstall和dba用户组
useradd -g oinstall -g dba -m oracle
#设置用户oracle的登陆密码，不设置密码，在CentOS的图形登陆界面没法登陆(需要输入两次)
passwd oracle

# 查看新建的oracle用户
id oracle  
```    
- **创建oracle数据库安装目录**   

```
#进入根目录
cd / 
#oracle数据库安装目录
mkdir -p /data/oracle
#oracle数据库配置文件目录
mkdir -p /data/oraInventory
#oracle数据库软件包解压目录
mkdir -p /data/database

#设置目录所有者为oinstall用户组的oracle用户 
chown -R oracle:oinstall /data/oracle 
chown -R oracle:oinstall /data/oraInventory
chown -R oracle:oinstall /data/database 
```   
- **修改OS系统标识**  
Oracle默认不支持CentOS系统安装，但是CentOS其实就是 Red Hat。需要编辑 `redhat-release` 文件，将OS标识 由`CentOS release 6.5 (Final)`替换为`redhat-6`。  

```
# 查看系统内核版本
cat /proc/version

# 查看系统OS标识
cat /etc/redhat-release
```  
- **安装oracle数据库所需要的软件包**   
CentOS需要的安装包，可以在Oracle上查看：[查看所需安装包](https://docs.oracle.com/cd/E11882_01/install.112/e47689/pre_install.htm#LADBI1085)。
文档没有要求安装`elfutils`和`unixODBC`包，但是等安装Oracle检查安装前准备时，会提示说缺少这两个包，所以一并安装.  

```
yum -y install binutils* compat-libcap1* compat-libstdc++* gcc* gcc-c++* glibc* glibc-devel* ksh* libaio* libaio-devel* libgcc* libstdc++* libstdc++-devel* libXi* libXtst* make* sysstat* elfutils* unixODBC*
```    
**注意：**有时候使用yum安装的时候，会提示`another app is currently holding the yum lock` 。     
这个时候打开另外一个terminal，在root用户下输入 `rm -f /var/run/yum.pid`,强制关掉yum进程。  

- **关闭防火墙和不需要的服务**  
  + 关闭防火墙  
    在桌面终端运行`setup`，在`firewall configuration`中将`security level`设为`disabled`，[`selinux`](https://baike.baidu.com/item/SELinux/8865268?fr=aladdin)设为`disabled`.  
    关闭selinux（需重启生效）:`vi /etc/selinux/config` 

```
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
# enforcing - SELinux security policy is enforced.
# permissive - SELinux prints warnings instead of enforcing.
# disabled - No SELinux policy is loaded.

SELINUX=disabled #此处修改为disabled

# SELINUXTYPE= can take one of three two values:
# targeted - Targeted processes are protected,
# minimum - Modification of targeted policy. Only selected processes are protected.
# mls - Multi Level Security protection.
SELINUXTYPE=targeted
```   
  + 关闭不需要的服务   

```
for service in atd auditd avahi-daemon bluetooth cpuspeed cups ip6tables iptables isdn pcscd rawdevices rhnsd sendmail yum-updatesd 
do
chkconfig --del $service
service $service stop
done
```    
  执行时候，已经停止的服务再停止时可能会报错，忽略即可.  
   
- **修改内核参数:`vi /etc/sysctl.conf`**  

```
# sysctl settings are defined through files in
# /usr/lib/sysctl.d/, /run/sysctl.d/, and /etc/sysctl.d/.
#
# Vendors settings live in /usr/lib/sysctl.d/.
# To override a whole file, create a new file with the same in
# /etc/sysctl.d/ and put new settings there. To override
# only specific settings, add a file with a lexically later
# name in /etc/sysctl.d/ and put new settings there.
#
# For more information, see sysctl.conf(5) and sysctl.d(5).

# #################################################
# 新增部分（需要根据实际服务器参数设置）
# #################################################

net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.rp_filter = 1
# 设置最大打开文件数
fs.file-max = 6815744 
fs.aio-max-nr = 1048576
# 共享内存的总量，4G内存设置：1048576*4k/1024/1024
kernel.shmall = 1048576 
# 最大共享内存的段大小
kernel.shmmax = 2147483648 
# 整个系统共享内存端的最大数
kernel.shmmni = 4096 
kernel.sem = 250 32000 100 128
# 可使用的IPv4端口范围
net.ipv4.ip_local_port_range = 9000 65500 
net.core.rmem_default = 262144
net.core.rmem_max= 4194304
net.core.wmem_default= 262144
net.core.wmem_max= 1048576
```   
[**【使配置修改内核的参数生效指令：】**](#) `sysctl -p`    
   
- **对Oracle用户设置限制，提高软件运行性能**   

```   
# 编辑指令  
# vi /etc/security/limits.conf  

# #################################################
# 新增部分
# #################################################
oracle soft nproc 2047
oracle hard nproc 16384
oracle soft nofile 1024
oracle hard nofile 65536
```   

- **配置用户的环境变量**   

```
# 编辑指令
# vi /home/oracle/.bash_profile

# #################################################
# 新增部分
# #################################################
#oracle数据库安装目录
export ORACLE_BASE=/data/oracle
#oracle数据库路径
export ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_1
#oracle启动数据库实例名
export ORACLE_SID=orcl
export ORACLE_UNQNAME=orcl
#xterm窗口模式安装
export ORACLE_TERM=xterm
#添加系统环境变量
export PATH=$ORACLE_HOME/bin:/usr/sbin:$PATH
#添加系统环境变量
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
#防止安装过程出现乱码
export LANG=C
#设置Oracle客户端字符集，必须与Oracle安装时设置的字符集保持一致
export NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
```    
[**【使用户的环境变量配置立即生效指令：】**](#) `source /home/oracle/.bash_profile` 
   
[**异常报错：ERROR：export '=' not a valid identifier**](#)
`export ORACLE_UNQNAME=orcl （in 11.2 dbconsole, the $ORACLE_UNQNAME needs to be set rather than $ORACLE_SID`  
```
# 不能给/etc/profile文件里加空格
# 如果你给添加语句写成这样(等号两边带空格)：export LANG = C就会报错
```   

### 重启系统，确保所有设置生效   

### 安装数据库  
- **上传安装文件并解压**
  ```
  unzip linux.x64_11gR2_database_1of2.zip -d /data/database/ 
  unzip linux.x64_11gR2_database_2of2.zip -d /data/database/ 
  ```  
  
- **进入管理员权限，设置目录所有者为oinstall用户组的oracle用户，执行安装脚本**
  ```
  # 授权文件目录权限
  chown -R oracle:oinstall /data/database/database/
  
  cd /data/database/database/
  
  # 切换到oracle用户执行安装脚本
  su - oracle 
  
  ./runInstaller
  ```

#### 图形化界面安装过程   
 - **Configure Security Updates**  
 **去掉** I wish to receive security updates via My Oracle Support。  
点击 "Next >"    
-  **Installation Option**     
选择第一项 Create and configure a database（安装时建库）
点击 "Next >"  
- **System class**   
选择Server class
点击 "Next >"
- **Grid Options**   
选择单例模式 Single instance database installation
点击 "Next >"
- **Install Type**   
选择"Advanced Install"
点击 "Next >"
- **Product Languages**  
选择英语 English（根据系统默认选择好了）
点击 "Next >"
- **Database Edition(安装服务器类型，根据个人选择)**  
选择第一个标准版
- **Installation Location**   
确定数据软件的安装路径，自动读取前面Oracle环境变量中配置的值  
点击 "Next >"，  
之后也是选择默认，不做修改，直接点击"Next >"  
- **Configuration Options**   
"Character Sets"选择第二项或者第三项中的"Unicode standard UTF-8..."   
"Sample Schemas"勾选"Create database with ..."   
点击 "Next >"   
之后也是选择默认，不做修改，直接点击"Next >"   
- **Schema Passwords**   
选择第二项，并设置密码  
点击 "Next >"  
之后也是选择默认，不做修改，直接点击"Next >"   
- **Prepequisite Checks**   
OS Kernel Parameter 下的semmni的缺失是Oracle没有检测到，其实有，选中缺失的依赖包，如果下方详情栏里Expected value中有括号中标注(i386)或(i686)，是在提示缺少32位的依赖包，但是实际上已经安装了64位的依赖包，忽略它们，pdksh包已经安装，就是之前安装的ksh依赖包。   
如果还有提示的其他缺少的依赖包没有安装就去安装，按提示解决缺少的依赖包，之后点击 “Check Again”，再检查一遍，没有问题了，勾选ignore all,点击“Next”
- **Summary**   
点击 "Finsh"  
- **Install Product**   
在此过程中，安装界面会变成黑色，有一长条出现（其实是一个提示框），调整高度与宽度查看。
安装快结束时，会提示执行脚本，此时需要切换到ROOT用户下执行。
- **FINISHED........**   

### 问题记录  
- **问题一：执行./runInstaller安装异常**
```
>>> Ignoring required pre-requisite failures. Continuing...
Preparing to launch Oracle Universal Installer from /tmp/OraInstall2018-04-12_09-16-30PM. Please wait ...[oracle@orc database]$ No protocol specified
Exception in thread "main" java.lang.NoClassDefFoundError
        at java.lang.Class.forName0(Native Method)
        at java.lang.Class.forName(Class.java:164)
        at java.awt.Toolkit$2.run(Toolkit.java:821)
        at java.security.AccessController.doPrivileged(Native Method)
        at java.awt.Toolkit.getDefaultToolkit(Toolkit.java:804)
        at com.jgoodies.looks.LookUtils.isLowResolution(Unknown Source)
        at com.jgoodies.looks.LookUtils.<clinit>(Unknown Source)
        at com.jgoodies.looks.plastic.PlasticLookAndFeel.<clinit>(PlasticLookAndFeel.java:122)
        at java.lang.Class.forName0(Native Method)
        at java.lang.Class.forName(Class.java:242)
        at javax.swing.SwingUtilities.loadSystemClass(SwingUtilities.java:1783)
        at javax.swing.UIManager.setLookAndFeel(UIManager.java:480)
        at oracle.install.commons.util.Application.startup(Application.java:758)
        at oracle.install.commons.flow.FlowApplication.startup(FlowApplication.java:164)
        at oracle.install.commons.flow.FlowApplication.startup(FlowApplication.java:181)
        at oracle.install.commons.base.driver.common.Installer.startup(Installer.java:265)
        at oracle.install.ivw.db.driver.DBInstaller.startup(DBInstaller.java:114)
        at oracle.install.ivw.db.driver.DBInstaller.main(DBInstaller.java:132)
``` 
[**解决办法：**](#)
    + 产生问题原因分析：让命令终端有调用界面程序的权限，需要用root用户执行` xhost + `。 一般要调用界面需习惯性xhost+  
  ```
      # 切换用户
	  su  root
	  # 执行授权
	  xhost + 
	  # 执行结果：access control disabled, clients can connect from any host  
  ```
- **问题二：vim中文乱码** 
设置~下或者oracle用户下的.vimrc文件，加上fileencodings、enc、fencs，代码如下：
```
vim ~/.vimrc    #或者vim /home/oracle(用户名)/.vimrc
#添加如下代码
set fileencodings=utf-8,gb2312,gb18030,gbk,ucs-bom,cp936,latin1
set enc=utf8
set fencs=utf8,gbk,gb2312,gb18030
```
	  
#### [【参考资料】](#) 
- [Centos7下安装Oracle11g R2](https://www.cnblogs.com/muhehe/p/7816808.html)
- [centos 安装oracle 11g r2（一）-----软件安装](http://www.cnblogs.com/anzerong2012/p/7528311.html)  
- [在 Linux 上安装 Oracle 数据库 11g](http://www.oracle.com/ocom/groups/public/@otn/documents/webcontent/229016_zhs.htm)