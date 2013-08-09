#!/bin/bash

## VIRUSTOTAL APIKEY
VTAPI=""

##HPFRIENDS 
IDENT=""
SECRET=""

## Check to see if we are running as root first.
if [ "$(id -u)" != "0" ]; then
    echo "Please use sudo" 1>&2
    exit 1
fi

echo "Cheking resolv"
host cython.org
host carnivore.it
host infradead.org
host schmorp.de
host python.org
host github.com

echo "STARTING INSTALLATION"

apt-get update
apt-get upgrade -y

apt-get install aptitude libudns-dev libglib2.0-dev libssl-dev libcurl4-openssl-dev libreadline-dev libsqlite3-dev python-dev libtool automake autoconf build-essential subversion git-core flex bison pkg-config curl htop -y

mkdir /opt/dionaea
chown ubuntu:ubuntu /opt/dionaea



############# liblcfg #############
cd /tmp
git clone git://git.carnivore.it/liblcfg.git liblcfg
cd liblcfg/code
autoreconf -vi
./configure --prefix=/opt/dionaea
make install

############# libemu ############# 
cd /tmp
git clone git://git.carnivore.it/libemu.git libemu
cd libemu
autoreconf -vi
./configure --prefix=/opt/dionaea
sudo make install

############# libnl #############
cd /tmp
git clone git://git.infradead.org/users/tgr/libnl.git
cd libnl
autoreconf -vi
export LDFLAGS=-Wl,-rpath,/opt/dionaea/lib
./configure --prefix=/opt/dionaea
make
make install

############# libev #############
cd /tmp
wget http://dist.schmorp.de/libev/Attic/libev-4.15.tar.gz
tar xfz libev-4.15.tar.gz
cd libev-4.15
./configure --prefix=/opt/dionaea
make install

############# sqlite3 ############# 
apt-get install sqlite3 -y

############# Python ############# 
cd /tmp
wget http://www.python.org/ftp/python/3.3.2/Python-3.3.2.tgz
tar xfz Python-3.3.2.tgz
cd Python-3.3.2/
./configure --enable-shared --prefix=/opt/dionaea --with-computed-gotos --enable-ipv6 LDFLAGS="-Wl,-rpath=/opt/dionaea/lib/ -L/usr/lib/i386-linux-gnu/"
make
make install

############# Cython ############# 
cd /tmp
wget http://cython.org/release/Cython-0.19.tar.gz
tar xfz Cython-0.19.tar.gz
cd Cython-0.19
/opt/dionaea/bin/python3.3 setup.py install

############# libpcap ############# 
cd /tmp
wget http://www.tcpdump.org/release/libpcap-1.4.0.tar.gz
tar xfz libpcap-1.4.0.tar.gz
cd libpcap-1.4.0
./configure --prefix=/opt/dionaea
makee
make install 

############# dionaea #############
cd /tmp
git clone git@github.com:xarly/dionaea.git dionaea
cd dionaea
autoreconf -vi
./configure --with-lcfg-include=/opt/dionaea/include/ --with-lcfg-lib=/opt/dionaea/lib/ --with-python=/opt/dionaea/bin/python3.3 --with-cython-dir=/opt/dionaea/bin --with-udns-include=/opt/dionaea/include/ --with-udns-lib=/opt/dionaea/lib/ --with-emu-include=/opt/dionaea/include/ --with-emu-lib=/opt/dionaea/lib/ --with-gc-include=/usr/include/gc --with-ev-include=/opt/dionaea/include --with-ev-lib=/opt/dionaea/lib --with-nl-include=/opt/dionaea/include --with-nl-lib=/opt/dionaea/lib/ --with-curl-config=/usr/bin/ --with-pcap-include=/opt/dionaea/include --with-pcap-lib=/opt/dionaea/lib/
make
make install

############# p0F ############# 
apt-get install p0f -y

############# CONFIGURE ############# 
sed -i 's/mode = "getifaddrs"/mode = "manual"/g' /opt/dionaea/etc/dionaea/dionaea.conf
sed -i 's/^\/\/\t\t\t"p0f"/\t\t\t"p0f"/' /opt/dionaea/etc/dionaea/dionaea.conf
sed -i 's/^\/\/\t\t\t"virustotal"/\t\t\t"virustotal"/' /opt/dionaea/etc/dionaea/dionaea.conf
sed -i 's/ident = ""/ident = "'$IDENT'"/' /opt/dionaea/etc/dionaea/dionaea.conf
sed -i 's/secret = ""/secret = "'$SECRET'"/' /opt/dionaea/etc/dionaea/dionaea.conf
sed -i 's/apikey =/apikey = "'$VTAPI'" \/\//g' /opt/dionaea/etc/dionaea/dionaea.conf
sed -i 's/"epmap", "sip","mssql", "mysql"/"mysql"\/*"epmap", "sip", "mssql"*\//' /opt/dionaea/etc/dionaea/dionaea.conf
sed -i 's/"Welcome to the ftp service"/"Microsoft FTP Service"/g' /opt/dionaea/lib/dionaea/python/dionaea/ftp.py

chown nobody:nogroup /opt/dionaea/var/dionaea -R
chown nobody:nogroup /opt/dionaea/var/log

############# CHANGE SSH PORT ############# 
sed -i 's/Port 22/Port 4576/g' /etc/ssh/sshd_config

############# INIT SCRIPT #############
wget -O /etc/init.d/dionaea https://raw.github.com/xarly/HoneyPFG/master/initScripts/dionaea
chmod 755 /etc/init.d/dionaea
sleep 2
update-rc.d dionaea defaults
echo "Dionaea & P0f ready. System is restarting, remember change ssh port on client to 4576"
sleep 4
reboot now
