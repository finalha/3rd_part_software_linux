#!/bin/bash

#set -e
#¿ªÆôµ÷ÊÔ
set -x

function getParameter()
{
	local PARAMETER=''
	while test -z "$PARAMETER"
	do
	  read -p "$1 : " PARAMETER
	done
	echo $PARAMETER;
}

#if [ ! -f "/etc/yum.repos.d/mongodb-enterprise.repo" ];then sudo echo -e "[mongodb-enterprise]\nname=MongoDB Enterprise Repository\nbaseurl=https://repo.mongodb.com/yum/redhat/\$releasever/mongodb-enterprise/3.2/\$basearch/\ngpgcheck=1\nenabled=1\ngpgkey=https://www.mongodb.org/static/pgp/server-3.2.asc\n" > "/etc/yum.repos.d/mongodb-enterprise.repo";fi;
INSTALL_MONGODB_ENTERPRISE_SCRIPT='
if [ ! -f "/etc/yum.repos.d/mongodb-enterprise.repo" ];then
sudo cat>/etc/yum.repos.d/mongodb-enterprise.repo<<EOF
[mongodb-enterprise]
name=MongoDB Enterprise Repository
baseurl=https://repo.mongodb.com/yum/redhat/\$releasever/mongodb-enterprise/3.2/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.2.asc
EOF
fi;
sudo yum install -y mongodb-enterprise;
sudo sed -i "s@^SELINUX=.*@SELINUX=disabled@g" /etc/selinux/config;
if [ ! -f "/etc/init.d/disable-transparent-hugepages" ];then
sudo cat>/etc/init.d/disable-transparent-hugepages<<EOF
#!/bin/bash
### BEGIN INIT INFO
# Provides: disable-transparent-hugepages
# Required-Start: \$local_fs
# Required-Stop:
# X-Start-Before: mongod mongodb-mms-automation-agent
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Disable Linux transparent huge pages
# Description: Disable Linux transparent huge pages, to improve
# database performance.
### END INIT INFO

case \$1 in
  start)
    if [ -d /sys/kernel/mm/transparent_hugepage ]; then
      thp_path=/sys/kernel/mm/transparent_hugepage
    elif [ -d /sys/kernel/mm/redhat_transparent_hugepage ]; then
      thp_path=/sys/kernel/mm/redhat_transparent_hugepage
    else
      return 0
    fi

    echo never > \${thp_path}/enabled
    echo never > \${thp_path}/defrag

    re=^[0-1]+\$
    if [[ \$(cat \${thp_path}/khugepaged/defrag) =~ \$re ]]
    then
      # RHEL 7
      echo 0  > \${thp_path}/khugepaged/defrag
    else
      # RHEL 6
      echo no > \${thp_path}/khugepaged/defrag
    fi

    unset re
    unset thp_path
    ;;
esac
EOF
fi;
sudo chmod 755 /etc/init.d/disable-transparent-hugepages;
sudo chkconfig --add disable-transparent-hugepages;
sudo chkconfig disable-transparent-hugepages on;
sudo mkdir -p /etc/tuned/no-thp;
if [ ! -f "/etc/tuned/no-thp/tuned.conf" ];then
sudo cat>/etc/tuned/no-thp/tuned.conf<<EOF
[main]
include=virtual-guest
[vm]
transparent_hugepages=never
EOF
fi;
sudo tuned-adm profile no-thp;
sudo cat /sys/kernel/mm/transparent_hugepage/enabled;
sudo cat /sys/kernel/mm/transparent_hugepage/defrag;
sudo sed -i "/*          hard    nproc/d" /etc/security/limits.conf;
sudo sed -i "/*          soft    nproc/d" /etc/security/limits.conf;
sudo echo "*          hard    nproc    64000">>/etc/security/limits.conf;
sudo echo "*          soft    nproc    64000">>/etc/security/limits.conf;
sudo echo "*          hard    nofile   64000">>/etc/security/limits.conf;
sudo echo "*          soft    nofile   64000">>/etc/security/limits.conf;
sudo ulimit -n 64000;
sudo ulimit -u 64000;
sudo sed -i "/*          hard    nproc/d" /etc/security/limits.d/20-nproc.conf;
sudo sed -i "/*          soft    nproc/d" /etc/security/limits.d/20-nproc.conf;
sudo echo "*          hard    nproc    64000">>/etc/security/limits.d/20-nproc.conf;
sudo echo "*          soft    nproc    64000">>/etc/security/limits.d/20-nproc.conf;
sudo echo "Please restart the operating system to make kernel settings of mongodb take effect";
';

## Step 1 : Install MongoDB Enterprise remote

echo "Install MongoDB";

echo "=====================";

INSTALLLOG=/tmp/installmongodbenterprise.out

HOSTNAME=$(getParameter "Please enter the target server's hostname [hostname or user@hostname] or ip [ip or user@ip]");

echo "[$HOSTNAME] Install MongoDB Enterprise remote";

ssh -t $HOSTNAME "bash -c '$INSTALL_MONGODB_ENTERPRISE_SCRIPT'" | tee $INSTALLLOG;

if [ $? == 0 ];then
echo "[$HOSTNAME] Install MongoDB Enterprise succesfully";
else
echo "[$HOSTNAME] Install MongoDB Enterprise failed, the installation script will abort";
exit
fi

echo "Done";