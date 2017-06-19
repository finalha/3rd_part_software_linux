#!/bin/bash

set -e



# This script is part of my blog post : 

# http://thoughtsimproved.wordpress.com/2015/01/03/tech-recipe-setup-a-rabbitmq-cluster-on-ubuntu/ 



# It sets up a RabbitMQ cluster by connecting to user-provided master and slave servers 

# and ringing them up to a cluster on the fly.



# RabbitMQ Clustering is described in detail here :

# https://www.rabbitmq.com/clustering.html





function getHostname()

{

	local HOST=''



	while test -z "$HOST"

	do

	  read -p "$1 : " HOST

	done



	echo $HOST;

}



#SETUP_MASTER_SCRIPT='
#
#sudo rabbitmqctl stop_app;
#
#sudo rabbitmqctl reset;
#
#sudo rabbitmqctl start_app;
#
#';

SETUP_MASTER_SCRIPT='

sudo rabbitmqctl stop_app;

sudo rabbitmqctl start_app;

';


# Step 1 : Setup the Master and get the erlang cookie



echo "Setup RabbitMQ Master";

echo "=====================";



OUT=/tmp/master.out

MASTER_HOSTNAME=$(getHostname "Enter the master server's hostname [hostname or user@hostname]");

echo "[$MASTER_HOSTNAME] Setting up master";

ssh -t $MASTER_HOSTNAME "bash -c '$SETUP_MASTER_SCRIPT sudo cat /var/lib/rabbitmq/.erlang.cookie;'" | tee $OUT;
#ssh -t $MASTER_HOSTNAME "bash -c 'sudo cat /var/lib/rabbitmq/.erlang.cookie;'" | tee $OUT;

COOKIE=$(cat $OUT | tail -n1)

#rm $OUT;

echo "Master's Erlang Cookie : '$COOKIE'"



MASTER_IP=$(getHostname "Enter the master server's IP as seen from the slaves (Use a local IP if available)");

echo "Master's IP: '$MASTER_IP'"
#MASTER_IP=${MASTER_IP//./\\.}
#echo "Master's IP: '$MASTER_IP'"

# Step 3 : Setup the slaves



#SETUP_SLAVE_SCRIPT="
#
#sudo sed -i \"s/^$/$MASTER_IP    $MASTER_HOSTNAME\n/\" /etc/hosts;
#
#sudo bash -c \"echo -n '$COOKIE' > /var/lib/rabbitmq/.erlang.cookie\";
#
#sudo rabbitmqctl stop_app;
#
#sudo rabbitmqctl reset;
#
#sudo rabbitmqctl join_cluster --ram rabbit@$MASTER_HOSTNAME;
#
#sudo rabbitmqctl start_app;
#
#sudo rabbitmqctl cluster_status;
#
#";

#sudo sed -i "/$/a 10.10.3.137    localhost137\n" /etc/hosts
#sudo sed -i \"$a $MASTER_IP    $MASTER_HOSTNAME\n\" /etc/hosts;
#sudo sed -i \"s/^$/$MASTER_IP    $MASTER_HOSTNAME\n/\" /etc/hosts;

SETUP_SLAVE_SCRIPT="

sudo echo \"$MASTER_IP    $MASTER_HOSTNAME\" >> /etc/hosts;

sudo bash -c \"echo -n '$COOKIE' > /var/lib/rabbitmq/.erlang.cookie\";

sudo service rabbitmq-server restart;

sudo rabbitmqctl stop_app;

sudo rabbitmqctl join_cluster --ram rabbit@$MASTER_HOSTNAME;

sudo rabbitmqctl start_app;

sudo rabbitmqctl cluster_status;

";


echo "Setup RabbitMQ Slaves";

echo "=====================";



#S="Enter the slave server's hostname [hostname or user@hostname] or 'q' to quit : "

#SERVER=$(getHostname $S);

SERVER=$(getHostname "Enter the slave server's hostname [hostname or user@hostname] or 'q' to quit");

while test "$SERVER" != "q"

do

	echo "[SERVER] Setting up slave";

	ssh -t $SERVER "bash -c '$SETUP_SLAVE_SCRIPT'";

	SERVER=$(getHostname "Enter the slave server's hostname [hostname or user@hostname] or 'q' to quit");

done



echo "Done";