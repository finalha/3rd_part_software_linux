#!/bin/bash

#set -e
#开启调试
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

#function getPassword()
#{
#	local PASSWORD=''
#	while test -z "$PASSWORD"
#	do
#	  read -p "$1 : " PASSWORD
#	done
#	echo $PASSWORD;
#}

INSTALL_RABBITMQ_SCRIPT='
sudo yum -y install epel-release;
sudo yum -y install erlang;
sudo yum -y install rabbitmq-server;

';

CONFIG_RABBITMQ_SCRIPT="
sudo sed -i "s@\%\% {tcp_listeners, \[5672\]}@{tcp_listeners, \[5672\]}@g" /etc/rabbitmq/rabbitmq.config;
sudo sed -i "s@\%\% {tcp_listeners, \[5672\]}@{tcp_listeners, \[5672\]}@g" /etc/rabbitmq/rabbitmq.config;
";


SERVICE_RABBITMQ_SCRIPT='
sudo chkconfig rabbitmq-server on;
sudo service rabbitmq-server start;
sudo service rabbitmq-server status;
sudo rabbitmq-plugins enable rabbitmq_management;
sudo service rabbitmq-server restart;
';

FIREWALL_RABBITMQ_SCRIPT='
sudo firewall-cmd --permanent --zone=public --add-port=15672/tcp;
sudo firewall-cmd --permanent --zone=public --add-port=6938/tcp;
sudo firewall-cmd --reload;
sudo firewall-cmd --zone=public --list-ports;
';

## Step 1 : Install RabbitMQ remote

echo "Install RabbitMQ";

echo "=====================";

INSTALLLOG=/tmp/installrabbitmq.out

HOSTNAME=$(getParameter "Please enter the target server's hostname [hostname or user@hostname] or ip [ip or user@ip]");

echo "[$HOSTNAME] Install RabbitMQ";

ssh -t $HOSTNAME "bash -c '$INSTALL_RABBITMQ_SCRIPT'" | tee $INSTALLLOG;

if [ $? == 0 ];then
echo "[$HOSTNAME] Install RabbitMQ succesfully";
else
echo "[$HOSTNAME] Install RabbitMQ failed, the installation script will abort";
exit
fi

# Step 2 : Start RabbitMQ service remote

echo "Start RabbitMQ service";

echo "=====================";

SERVICELOG=/tmp/startrabbitmqservice.out

HOSTNAME=$(getParameter "Please enter the target server's hostname [hostname or user@hostname] or ip [ip or user@ip]");

echo "[$HOSTNAME] start RabbitMQ service";

ssh -t $HOSTNAME "bash -c '$SERVICE_RABBITMQ_SCRIPT'" | tee $SERVICELOG;

sleep 1
#example:if $HOSTNAME=lytest@10.10.3.137 or 10.10.3.137,so $SUFFIX=10.10.3.137
SUFFIX=$(echo $HOSTNAME|cut -d "@" -f2)
sudo wget rabbitmq@$SUFFIX:15672
#wget rabbitmq@$SUFFIX:15672

if [ $? == 0 ];then
echo "[$HOSTNAME] Start RabbitMQ Service succesfully";
else
echo "[$HOSTNAME] Start RabbitMQ Service failed, the installation script will abort";
exit
fi


# Step 3 : Config HOSTNAME firewall

echo "Config [$HOSTNAME] firewall";

echo "=====================";

FIREWALLLOG=/tmp/configfirewall.out

#HOSTNAME=$(getParameter "Please enter the target server's hostname [hostname or user@hostname] or ip [ip or user@ip]");

echo "[$HOSTNAME] Install RabbitMQ";

ssh -t $HOSTNAME "bash -c '$FIREWALL_RABBITMQ_SCRIPT'" | tee $FIREWALLLOG;

if [ $? == 0 ];then
echo "[$HOSTNAME] Config firewall succesfully";
else
echo "[$HOSTNAME] Config firewall failed, the installation script will abort";
exit
fi

# Step 4 : Add RabbitMQ User

echo "[$HOSTNAME] Add RabbitMQ user";

echo "=====================";

ADDRABBITMQUSERLOG=/tmp/addrabbitmquser.out

#HOSTNAME=$(getParameter "Please enter the target server's hostname [hostname or user@hostname] or ip [ip or user@ip]");

echo "[$HOSTNAME] Add RabbitMQ user";

RABBITMQUSER=$(getParameter "Please enter the username of RabbitMQ");
RABBITMQPASSWORD=$(getParameter "Please enter the password of RabbitMQ");

ADDUSER_RABBITMQ_SCRIPT="
sudo rabbitmqctl add_user \"$RABBITMQUSER\" \"$RABBITMQPASSWORD\";
sudo rabbitmqctl set_user_tags \"$RABBITMQUSER\" administrator;
sudo rabbitmqctl set_permissions \"$RABBITMQUSER\" \".*\" \".*\" \".*\";
sudo service rabbitmq-server restart;
";

ssh -t $HOSTNAME "bash -c '$ADDUSER_RABBITMQ_SCRIPT'" | tee $ADDRABBITMQUSERLOG;

if [ $? == 0 ];then
echo "[$HOSTNAME] Add RabbitMQ user succesfully";
else
echo "[$HOSTNAME] Add RabbitMQ user failed, the installation script will abort";
exit
fi

echo "Done";
