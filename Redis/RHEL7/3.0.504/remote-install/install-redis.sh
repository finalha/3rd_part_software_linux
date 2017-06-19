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

#install Redis 3.0.5 single node
echo "Begin to install Redis 3.0.5 single node";

echo "=====================";

LOG1=/tmp/installredis3.0.5standalone.out

HOSTNAME=$(getParameter "Please enter the target server's hostname [hostname or user@hostname] or ip [ip or user@ip]")

ssh -t $HOSTNAME "bash -s" < "./1.standalone.sh" | tee $LOG1

if [ $? == 0 ];then
echo "[$HOSTNAME] install Redis 3.0.5 standalone succesfully";
else
echo "[$HOSTNAME] install Redis 3.0.5 standalone failed, the installation script will abort";
exit
fi

#convert standalone to master

REDISMASTER=$(getParameter "Please determine whether the current machine is Redis master node,'y' or 'n'");
if [ "$REDISMASTER" == "y" ];then
echo "Begin to convert the Redis node to master";

echo "=====================";

LOG2=/tmp/convertredistomaster.out

ssh -t $HOSTNAME "bash -s" < "./2.convert_to_master.sh" | tee $LOG2

if [ $? == 0 ];then
echo "[$HOSTNAME] convert the Redis node to master succesfully";
exit
else
echo "[$HOSTNAME] convert the Redis node to master failed, the installation script will abort";
exit
fi
fi

#convert standalone to slave

REDISSLAVE=$(getParameter "Please determine whether the current machine is Redis slave node,'y' or 'n'");
if [ "$REDISSLAVE" == "y" ];then
echo "Begin to convert the Redis node to slave";

echo "=====================";

LOG3=/tmp/convertredistoslave.out

ssh -t $HOSTNAME "bash -s" < "./3.convert_to_slave.sh" | tee $LOG3

if [ $? == 0 ];then
echo "[$HOSTNAME] convert the Redis node to slave succesfully";
else
echo "[$HOSTNAME] convert the Redis node to slave failed, the installation script will abort";
exit
fi
fi

#convert standalone to sentinel

REDISSENTINEL=$(getParameter "Please determine whether the current machine is Redis sentinel node,'y' or 'n'");
if [ "$REDISSENTINEL" == "y" ];then
echo "Begin to convert the Redis node to sentinel";

echo "=====================";

LOG4=/tmp/convertredistosentinel.out

ssh -t $HOSTNAME "bash -s" < "./4.convert_to_sentinel.sh" | tee $LOG4

if [ $? == 0 ];then
echo "[$HOSTNAME] convert the Redis node to sentinel succesfully";
else
echo "[$HOSTNAME] convert the Redis node to sentinel failed, the installation script will abort";
exit
fi
fi

Done;