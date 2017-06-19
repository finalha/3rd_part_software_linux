# convert existing standalone to master

echo "New password for the redis master? "
read redis_master_password

#function getParameter()
#{
#	local PARAMETER=''
#	while test -z "$PARAMETER"
#	do
#	  read -p "$1 : " PARAMETER
#	done
#	echo $PARAMETER;
#}
#
#redis_master_password=$(getParameter "Enter the password for the redis master")

sed -i 's/appendonly no/appendonly yes/g' /etc/redis.conf
sed -i 's/redis.log/redis-master.log/g' /etc/redis.conf
sed -i 's/tcp-keepalive 300/tcp-keepalive 60/g' /etc/redis.conf
sed -i 's/bind 127.0.0.1/#bind 127.0.0.1/g' /etc/redis.conf
echo "requirepass $redis_master_password" >> /etc/redis.conf

systemctl stop redis
sleep 5
#systemctl status redis
systemctl start redis
sleep 5
systemctl status redis
