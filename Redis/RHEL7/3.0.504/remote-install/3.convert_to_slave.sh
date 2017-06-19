# convert standalone to master

echo "What is the IP of the redis master?"
read redis_master_ip
echo "What is the current password for the redis master? "
read redis_master_password
#our code decide the password of master and slave must be the same
#echo "New password for the redis slave?"
#read redis_slave_password

sed -i 's/redis.log/redis-slave.log/g' /etc/redis.conf
sed -i 's/bind 127.0.0.1/#bind 127.0.0.1/g' /etc/redis.conf
#echo "requirepass $redis_slave_password" >> /etc/redis.conf
echo "requirepass $redis_master_password" >> /etc/redis.conf
echo "slaveof $redis_master_ip 6379" >> /etc/redis.conf
echo "masterauth $redis_master_password" >> /etc/redis.conf

systemctl stop redis
sleep 5
#systemctl status redis
systemctl start redis
sleep 5
systemctl status redis
