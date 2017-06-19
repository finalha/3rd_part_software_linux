# convert standalone to master

echo "What is the IP of the redis master?"
read redis_master_ip
echo "What is the current password for the redis master? "
read redis_master_password
#echo "New password for the redis slave?"
#read redis_slave_password

#mv /etc/redis.conf /etc/redis.conf.bk
cat > /etc/redis-sentinel.conf << EOF 
port 6380
logfile "/opt/redis-sentinel.log"
loglevel debug
sentinel monitor nbreplica $redis_master_ip 6379 1
sentinel down-after-milliseconds nbreplica 5000
sentinel failover-timeout nbreplica 5000
sentinel auth-pass nbreplica $redis_master_password
timeout 0
EOF

#sed -i 's/bind 127.0.0.1/#bind 127.0.0.1/g' /etc/redis.conf
##echo "requirepass $redis_slave_password" >> /etc/redis.conf
#echo "slaveof $redis_master_ip 6379" >> /etc/redis.conf
#echo "masterauth $redis_master_password" >> /etc/redis.conf

systemctl stop redis-sentinel
sleep 5
#systemctl status redis-sentinel
systemctl start redis-sentinel
sleep 5
systemctl status redis-sentinel
chkconfig redis-sentinel on


