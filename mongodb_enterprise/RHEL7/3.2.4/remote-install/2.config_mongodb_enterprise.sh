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

#if /usr/sbin/service $dbservicename status|grep -q \"(dead)\"

STOP_MONGODB_SERVICE_SCRIPT="
if [ service mongod status|grep -q \"(dead)\" ];then
:
else
sudo service mongod stop;
fi;
sudo mv /etc/mongod.conf /etc/mongod.conf.bk;
";

## Step 1 : Stop MongoDB Enterprise service remote

echo "Stop MongoDB Service";

echo "=====================";

LOG1=/tmp/stopmongodbenterprise.out

HOSTNAME=$(getParameter "Please enter the target server's hostname [hostname or user@hostname] or ip [ip or user@ip]");

echo "[$HOSTNAME] Stop MongoDB Enterprise Service remote";

ssh -t $HOSTNAME "bash -c '$STOP_MONGODB_SERVICE_SCRIPT'" | tee $LOG1;

if [ $? == 0 ];then
echo "[$HOSTNAME] Stop MongoDB Enterprise Service remote succesfully";
else
echo "[$HOSTNAME] Stop MongoDB Enterprise Service remote failed, the installation script will abort";
exit
fi

## Step 2 : Write MongoDB Enterprise install conf

echo "Please input parameters of MongoDB";

echo "=====================";

LOG2=/tmp/wirtemongodbinstallconf.out

MONGODBIP=$(getParameter "Please enter the ip of MongoDB Server");
MONGODBPORT=$(getParameter "Please enter the port of MongoDB Server");
MONGODBRSNAME=$(getParameter "Please enter the replicaset name of MongoDB Server");
MONGODBREQUIRESSL=$(getParameter "Please Determine whether SSL is required for MongoDB,'y' or 'n'");
if [ "$MONGODBREQUIRESSL" == "y" ];then
MONGODBREQUIRESSL="yes";
MONGODBCERTPATH=$(getParameter "Please enter the path of cert for MongoDB Server, e.g., /etc/ssl/cert.pem");
MONGODBKEYPATH=$(getParameter "Please enter the path of key for MongoDB Server, e.g., /etc/ssl/key.pem");
else
MONGODBREQUIRESSL="no";
MONGODBCERTPATH=;
MONGODBKEYPATH=;
fi
MONGODBUSER=$(getParameter "Please enter the username of MongoDB");
MONGODBPASSWORD=$(getParameter "Please enter the password of MongoDB");
MONGODBCPULIMIT=$(getParameter "Please Enter the percentage of cpu limits, e.g.90");
MONGODBMEMORYLIMIT=$(getParameter "Please Enter the percentage of memory limits, e.g.90");
MONGODBREQUIRECLSTER=$(getParameter "Please Determine whether cluster is required for MongoDB,'y' or 'n'");
if [ "$MONGODBREQUIRECLSTER" == "y" ];then
MONGODBREQUIRECLSTER="yes";
MONGODBSINGLENODE="no"
MONGODBMEMBERS=$(getParameter "Please enter the members of cluster for MongoDB Server , e.g., 10.10.3.142:27017 10.10.3.143:27017  10.10.3.144:27017");
else
MONGODBREQUIRECLSTER="no";
MONGODBSINGLENODE="yes"
MONGODBMEMBERS=;
fi

WRITE_MONGODB_INSTALL_CONF_SCRIPT="
if [ ! -f "/etc/install.conf" ];then
sudo cat>/etc/install.conf<<EOF
#NetBrain Database config file
DBServiceName      mongod
ConfPath           /etc
DataPath           /var/lib/mongo
LogPath            /var/log/mongodb
BindIp             $MONGODBIP
DBPort             $MONGODBPORT
ReplicaSetName     $MONGODBRSNAME
RequireSSL         $MONGODBREQUIRESSL
CertPath           $MONGODBCERTPATH
KeyPath            $MONGODBKEYPATH
#either dbuser or dbpassword was set to empty,mongodbconfig.sh will not add user and password
DBUser             $MONGODBUSER
DBPassword         $MONGODBPASSWORD

#CGroups config
CPULimit           $MONGODBCPULIMIT
MemoryLimit        $MONGODBMEMORYLIMIT

#single node or multi-node replicaset 
SingleNode         $MONGODBSINGLENODE

#write all odd replicaset members,the first will be primary and the last will be arbiter, weight from 1000, 970, 940 ......
ReplicaSetMembers  $MONGODBMEMBERS
EOF
fi;
";

ssh -t $HOSTNAME "bash -c '$WRITE_MONGODB_INSTALL_CONF_SCRIPT'" | tee $LOG2;

if [ $? == 0 ];then
echo "[$HOSTNAME] write install.conf of MongoDB Enterprise Service succesfully";
else
echo "[$HOSTNAME] write install.conf of MongoDB Enterprise Service failed, the installation script will abort";
exit
fi


## Step 3 : Write MongoDB Enterprise mongod.conf

echo "Rewrite config file of MongoDB";

echo "=====================";

LOG3=/tmp/rewirtemongodconf.out
REMOTEFREEMEMORY=/tmp/remotefreememory.out
ssh -t $HOSTNAME "bash -c '$WRITE_MONGODB_CONF_SCRIPT'" | tee $LOG3;

GET_REMOTE_SERVER_FREE_MEMORY="
sudo free -g | awk '/^Mem:/{print $2}';
";

ssh -t $HOSTNAME "bash -c '$GET_REMOTE_SERVER_FREE_MEMORY'" | tee $REMOTEFREEMEMORY;
totalMemoryInGB=$(cat $REMOTEFREEMEMORY)
echo $totalMemoryInGB
cgroupMemoryInGB=$(awk "BEGIN {printf \"%.0f\n\", ($totalMemoryInGB*$MONGODBMEMORYLIMIT)/100}")
echo $cgroupMemoryInGB
#cacheSizeInGB=cgroupMemoryInGB*60%-1>1?cgroupMemoryInGB*60%-1:1
cachevalueGB=$(awk "BEGIN {printf \"%.0f\n\", ($cgroupMemoryInGB*60)/100-1}")
if [ "$cachevalueGB" -ge "1" ];then cacheSizeInGB=$cachevalueGB;else cacheSizeInGB=1;fi;
echo $cacheSizeInGB

WRITE_MONGODB_CONF_SCRIPT="
if [ ! -f "/etc/mongod.conf" ];then
sudo cat>/etc/mongod.conf<<EOF
# mongod.conf

# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# where to write logging data.
systemLog:
  destination: file
  logAppend: false
  path: /var/log/mongodb/mongod.log
  timeStampFormat: iso8601-utc

# Where and how to store data.
storage:
  dbPath: /var/lib/mongo
  journal:
    enabled: true
  engine: wiredTiger
#  mmapv1:
  wiredTiger:
    engineConfig:
      cacheSizeGB: $cacheSizeInGB  # 60% of memory available for MongoDB  - 1G, or 1G, which ever is larger	 
# how the process runs
processManagement:
  fork: true  # fork and run in background
  pidFilePath: /var/run/mongodb/mongod.pid  # location of pidfile

# network interfaces
net:
  port: $MONGODBPORT
  bindIp: $MONGODBIP,127.0.0.1  # Listen to local interface only, comment to listen on all interfaces.
  #ssl:
     #mode: requireSSL
     #PEMKeyFile: /etc/ssl/mongodb.pem

security:
    authorization: enabled
    #keyFile: /mnt/mongod1/mongodb-keyfile

#operationProfiling:

replication:
    oplogSizeMB: 10000
    replSetName: $MONGODBRSNAME

#sharding:

## Enterprise-Only Options

#auditLog:

#snmp:
EOF
fi;
sudo service mongod start;
sudo systemctl set-property mongod MemoryLimit=$cgroupMemoryInGB"G"
";

ssh -t $HOSTNAME "bash -c '$WRITE_MONGODB_CONF_SCRIPT'" | tee $LOG3;

if [ $? == 0 ];then
echo "[$HOSTNAME] write mongod.conf of MongoDB Enterprise Service succesfully";
else
echo "[$HOSTNAME] write mongod.conf of MongoDB Enterprise Service failed, the installation script will abort";
exit
fi

## Step 4 : Execute mongodbconfig.sh to init replicaset and add username/password

echo "Init replicaset and username/password of MongoDB";

echo "=====================";

LOG4=/tmp/initmongodb.out

#ssh -t $HOSTNAME "bash -c '$WRITE_MONGODB_CONF_SCRIPT'" | tee $LOG4;
#ssh -t $HOSTNAME "bash -s < 'mongodbconfig.sh'" | tee $LOG4;
#ssh root@MachineB 'echo "rootpass" | sudo -Sv && bash -s' < local_script.sh
ssh -t $HOSTNAME "bash -s" < "./mongodbconfig.sh"

if [ $? == 0 ];then
echo "[$HOSTNAME] init replicaset and username/password of MongoDB succesfully";
else
echo "[$HOSTNAME] init replicaset and username/password of MongoDB failed, the installation script will abort";
exit
fi

echo Done;

#sudo sed -i "s@/etc/mongod1/log@$logpath@g" /etc/mongod.conf
#sudo sed -i "s@/var/lib/mongodb@$datapath@g" /etc/mongod.conf
#sudo sed -i "s/25101/$dbport/g" /etc/mongod.conf
#sudo sed -i "s/127.0.0.1/$bindip,127.0.0.1/g" /etc/mongod.conf
#sudo sed -i "s@replSetName: rs@replSetName: $replicasetname@g" /etc/mongod.conf
#sudo sed -i "s@pidFilePath: /var/run/mongodb/mongod.pid@pidFilePath: /var/run/$dbservicename/mongod.pid@g" /etc/mongod.conf
#sudo sed -i "s@cacheSizeGB: 1@cacheSizeGB: $cacheSizeInGB@g" /etc/mongod.conf
#if [ "$requiressl" == "yes" ]; then
#sudo sed -i "s@#ssl:@ssl:@g" /etc/mongod.conf
#sudo sed -i "s@#mode: requireSSL@mode: requireSSL@g" /etc/mongod.conf
#sudo sed -i "s@#PEMKeyFile: /etc/ssl/mongodb.pem@PEMKeyFile: /etc/ssl/mongodb.pem@g" /etc/mongod.conf
#fi
