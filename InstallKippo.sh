#!/bin/bash

## Check to see if we are running as root first.
if [ "$(id -u)" != "0" ]; then
    echo "Please use sudo" 1>&2
    exit 1
fi

############ INSTALL DEPENDENCIES
apt-get update
echo "Please use abc123 as MySQL root password. Change it later if you want"
sleep 2
apt-get install -y subversion python-dev openssl python-openssl python-pyasn1 python-twisted python-mysqldb mysql-server


############ USER KIPPO
adduser kippo


############ KIPPO BINS
su kippo -c 'svn checkout http://kippo.googlecode.com/svn/trunk/ ~/kippo/'


############ MYSQL STUFF
Q1="CREATE DATABASE IF NOT EXISTS kippodb;"
Q2="GRANT ALL ON kippodb.* TO 'kippousr'@'localhost' IDENTIFIED BY 'abc123';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"
mysql -uroot -pabc123 -e "$SQL"
mysql -uroot -pabc123 kippodb < /home/kippo/kippo/doc/sql/mysql.sql

############ KIPPO CONFIG
su kippo -c 'cp ~/kippo/kippo.cfg.dist ~/kippo/kippo.cfg'
sed -i 's/ssh_port = 2222/ssh_port = 9999/g' /home/kippo/kippo/kippo.cfg
sed -i 's/\#\[database_mysql\]/\[database_mysql\]/' /home/kippo/kippo/kippo.cfg
sed -i 's/\#host = localhost/host = localhost/' /home/kippo/kippo/kippo.cfg
sed -i 's/\#database = kippo/database = kippodb/' /home/kippo/kippo/kippo.cfg
sed -i 's/\#username = kippo/username = kippousr/' /home/kippo/kippo/kippo.cfg
sed -i 's/\#password = secret/password = abc123/' /home/kippo/kippo/kippo.cfg
sed -i 's/\#port = 3306/port = 3306/g' /home/kippo/kippo/kippo.cfg



############# PORT 22 STUFF ############# 
iptables -t nat -A PREROUTING -p tcp --dport 22 -j REDIRECT --to-port 9999
sleep 2

#setup iptables restore script
iptables-save > /etc/kippo.iptables
touch /etc/network/if-up.d/kippo
echo '#!/bin/sh' >> /etc/network/if-up.d/kippo
echo 'iptables-restore < /etc/kippo.iptables' >> /etc/network/if-up.d/kippo
echo 'exit 0' >> /etc/network/if-up.d/kippo

#enable restore script
chmod +x /etc/network/if-up.d/kippo 

# CHANGE REAL SSH PORT #
sed -i 's/Port 22/Port 4576/g' /etc/ssh/sshd_config


############# INIT SCRIPT #############
wget -O /etc/init.d/kippo https://raw.github.com/xarly/HoneyPFG/master/initScripts/kippo
chmod 755 /etc/init.d/kippo
sleep 2
update-rc.d kippo defaults
echo "Kippo ready. System is restarting, remember change ssh port on client to 4576"
sleep 2
reboot now


