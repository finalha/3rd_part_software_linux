#!/bin/bash

set -e
#¿ªÆôµ÷ÊÔ
#set -x

function getParameter()
{
	local PARAMETER=''
	while test -z "$PARAMETER"
	do
	  read -p "$1 : " PARAMETER
	done
	echo $PARAMETER;
}

echo "Begin to install stunnel";
echo "=====================";
LOG1=/tmp/installstunnel.out
LOG2=/tmp/installlsof.out
yum -y localinstall stunnel-4.56-6.el7.x86_64.rpm | tee $LOG1
if [ $? == 0 ];then
echo "install stunnel succesfully";
else
echo "install stunnel failed, the installation script will abort";
exit
fi
#yum -y install lsof | tee $LOG2

REDISCERTPATH=$(getParameter "Please enter the path of cert for Redis Server, e.g., /etc/ssl/rediscert.pem");
if [ ! -f "$REDISCERTPATH" ]; then
echo "The cert file of Redis can not be found, the installation script will abort";
exit
fi

REDISKEYPATH=$(getParameter "Please enter the path of key for Redis Server, e.g., /etc/ssl/rediskey.pem");
if [ ! -f "$REDISKEYPATH" ]; then
echo "The key file of Redis can not be found, the installation script will abort";
exit
fi

cat "$REDISKEYPATH" "$REDISCERTPATH" > "/etc/stunnel/rediscert.pem"

if [ -f "/etc/stunnel/stunnel.conf" ];then 
mv "/etc/stunnel/stunnel.conf" "/etc/stunnel/stunnel.conf$(date -u +"%Y|%b|%d|%T")"
fi

REDISMASTER=$(getParameter "Please determine whether the current machine is Redis master node,'y' or 'n'");
if [ "$REDISMASTER" == "y" ];then
echo "Begin to generate the config file of stunnel";
echo "=====================";

STUNNELREDISMASTERPORT=$(getParameter "Please enter the port for stunnel, e.g., 7000")
##check port occupied,use lsof -i:portnumber
#checkport=$(lsof -i:$STUNNELREDISMASTERPORT)
#while test -n "$checkport"
#do
#   echo "The port number is being used"
#   STUNNELREDISMASTERPORT=$(getParameter "Please enter the port for stunnel, e.g., 7000")
#   checkport=$(lsof -i:$STUNNELREDISMASTERPORT)
#done

cat > /etc/stunnel/stunnel.conf << EOF 
cert = /etc/stunnel/rediscert.pem
pid = /var/run/stunnel.pid

[redis-master]
accept = $STUNNELREDISMASTERPORT
connect = 0.0.0.0:6379
EOF

stunnel /etc/stunnel/stunnel.conf
sleep 5
stunnelstatus=$(ps -ef|grep stunnel|grep -v grep)
if [ ! -z "$stunnelstatus" ]; then
echo "The stunnel has been installed and configed succesfully"
exit 
else
echo "The stunnel has not been installed and configed succesfully, the installation script will abort"
exit
fi
fi

REDISSLVAE=$(getParameter "Please determine whether the current machine is Redis slave node,'y' or 'n'");
if [ "$REDISSLVAE" == "y" ];then
echo "Begin to generate the config file of stunnel";
echo "=====================";

STUNNELREDISSLAVEPORT=$(getParameter "Please enter the port for stunnel, e.g., 7000");
##check port occupied,use lsof -i:portnumber
#checkport=$(lsof -i:$STUNNELREDISSLAVEPORT)
##check $checkport is not null
#while test -n "$checkport"
#do
#   echo "The port number is being used"
#   STUNNELREDISSLAVEPORT=$(getParameter "Please enter the port for stunnel, e.g., 7000");
#   checkport=$(lsof -i:$STUNNELREDISSLAVEPORT)
#done

cat > /etc/stunnel/stunnel.conf << EOF 
cert = /etc/stunnel/rediscert.pem
pid = /var/run/stunnel.pid

[redis-slave]
accept = $STUNNELREDISSLAVEPORT
connect = 0.0.0.0:6379
EOF
fi

REDISSENTINEL=$(getParameter "Please determine whether the current machine is Redis sentinel node,'y' or 'n'");
if [ "$REDISSENTINEL" == "y" -a "$REDISSLVAE" == "y" ];then
echo "Begin to generate the config file of stunnel";
echo "=====================";

STUNNELREDISSENTINELPORT=$(getParameter "Please enter the port for stunnel, e.g., 7000");
##check port occupied,use lsof -i:portnumber
#checkport=$(lsof -i:$STUNNELREDISSENTINELPORT)
##check $checkport is not null
#while test -n "$checkport"
#do
#   echo "The port number is being used"
#   STUNNELREDISSENTINELPORT=$(getParameter "Please enter the port for stunnel, e.g., 7000");
#   checkport=$(lsof -i:$STUNNELREDISSENTINELPORT)
#done

cat > /etc/stunnel/stunnel.conf << EOF 
cert = /etc/stunnel/rediscert.pem
pid = /var/run/stunnel.pid

[redis-slave]
accept = $STUNNELREDISSLAVEPORT
connect = 0.0.0.0:6379

[redis-sentinel]
accept = $STUNNELREDISSENTINELPORT
connect = 0.0.0.0:6380
EOF
fi

if [ "$REDISSENTINEL" == "y" -a "$REDISSLVAE" == "n" ];then
echo "Begin to generate the config file of stunnel";
echo "=====================";

STUNNELREDISSENTINELPORT=$(getParameter "Please enter the port for stunnel, e.g., 7000");
##check port occupied,use lsof -i:portnumber
#checkport=$(lsof -i:$STUNNELREDISSENTINELPORT)
##check $checkport is not null
#while test -n "$checkport"
#do
#   echo "The port number is being used"
#   STUNNELREDISSENTINELPORT=$(getParameter "Please enter the port for stunnel, e.g., 7000");
#   checkport=$(lsof -i:$STUNNELREDISSENTINELPORT)
#done

cat > /etc/stunnel/stunnel.conf << EOF 
cert = /etc/stunnel/rediscert.pem
pid = /var/run/stunnel.pid

[redis-sentinel]
accept = $STUNNELREDISSENTINELPORT
connect = 0.0.0.0:6380
EOF
fi

stunnel /etc/stunnel/stunnel.conf
sleep 5
stunnelstatus=$(ps -ef|grep stunnel|grep -v grep)
if [ ! -z "$stunnelstatus" ]; then
echo "The stunnel has been installed and configed succesfully"
else
echo "The stunnel has not been installed and configed succesfully, the installation script will abort"
fi
