#!/bin/bash

# get some basic vars for later
DIR=$(pwd)
if [[ $DIR == *scripts ]]
then
  echo "going up to project root directory"
  cd ..
  DIR=$(pwd)
fi
IP=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
NUM=$(( ( RANDOM % 1000 )  + 1 ))

# get optional domain and user from user input
echo "Enter your domain name, or press enter for a randomly generated subdomain"
read DOMAIN
if [ -z "$DOMAIN" ]
then
  DOMAIN="proxy$NUM.uphreak.com"
fi
echo "Enter a user name, or press enter for a randomly generated user"
read USER
if [ -z "$USER" ]
then
  USER="user$NUM"
fi

# update package lists
apt-get update

# install required dependencies and build tools
apt-get install -y build-essential bison flex pkgconf ruby libpcre3-dev libsqlite3-dev libncurses5-dev sqlite3 libglib2.0-dev libssl-dev libxml2-dev libxmlrpc-core-c3-dev libcurl4-openssl-dev tcpdump

# add opensips user with no shell
useradd -s /bin/false opensips

# clone required repos to local directory
cd /usr/local/src
git clone https://github.com/OpenSIPS/opensips.git
git clone https://github.com/sipwise/rtpengine.git
git clone https://github.com/ralight/sqlite3-pcre.git

# build opensips
cd opensips
cp Makefile.conf.template Makefile.conf
sed -i -e 's/include_modules?=/include_modules?= db_sqlite/g' Makefile.conf 
sed -i -e 's/PREFIX=\/usr\/local\//PREFIX=\/usr\/local\/opensips\//g' Makefile.conf
make all && make all install

# set up our sqlite database
mkdir -p /var/db/opensips
sqlite3 /var/db/opensips/opensips < ./scripts/sqlite/standard-create.sql
sqlite3 /var/db/opensips/opensips < ./scripts/sqlite/dialog-create.sql
sqlite3 /var/db/opensips/opensips < ./scripts/sqlite/domain-create.sql
sqlite3 /var/db/opensips/opensips < ./scripts/sqlite/auth_db-create.sql
sqlite3 /var/db/opensips/opensips < ./scripts/sqlite/usrloc-create.sql
sqlite3 /var/db/opensips/opensips < $DIR/scripts/create_translations_table.sqlite
sqlite3 /var/db/opensips/opensips "insert into translations (from_domain,match_regex,tran_domain) values ('$DOMAIN','^\+18[045678]{2}[0-9]{7}$','tf.arctele.com');"

chown -R opensips:opensips /var/db/opensips

# set up opensipsctlrc to use our sqlite database
sed -i -e 's/# DBENGINE=MYSQL/DBENGINE=SQLITE/g' /usr/local/opensips/etc/opensips/opensipsctlrc
sed -i -e 's/# DB_PATH="\/usr\/local\/etc\/opensips\/dbtext"/DB_PATH=\/var\/db\/opensips\/opensips/g' /usr/local/opensips/etc/opensips/opensipsctlrc

# add our ip to our domain table
/usr/local/opensips/sbin/opensipsctl domain add $DOMAIN:5060
/usr/local/opensips/sbin/opensipsctl domain add $DOMAIN

# build rtpengine daemon
cd /usr/local/src/rtpengine/daemon && make
mkdir /usr/local/rtpengine && cp rtpengine /usr/local/rtpengine/

# start rtpengine
/usr/local/rtpengine/rtpengine -p /var/run/rtpengine.pid --interface $IP --listen-ng $IP:60000 -m 50000 -M 55000 -E -L 3 &

# build sqlite pcre extension
cd /usr/local/src/sqlite3-pcre
make && make install

# configure federated opensips.var.rb
cd $DIR/core
cp opensips.var.rb.sample opensips.var.rb

# disable tls and ipv6
sed -i -e 's/enable_tls      = true/enable_tls      = false/g' opensips.var.rb
sed -i -e 's/enable_ipv6     = true/enable_ipv6     = false/' opensips.var.rb
# set our listening IP address
sed -i -e "s/listen_ip       = 'xxx.xxx.xxx.xxx'/listen_ip       = '$IP'/g" opensips.var.rb
# set our modules directory
sed -i -e 's#/usr/local/lib64/opensips/modules/#/usr/local/opensips/lib64/opensips/modules/#g' opensips.var.rb

# build the config
./build.rb && cp opensips.cfg /usr/local/opensips/etc/opensips/opensips.cfg

# start opensips
cd /usr/local/opensips && sbin/opensips

# add a subscriber
sbin/opensipsctl add "$USER@$DOMAIN" "ilikeopensips$NUM"

# sleep to get nicer output then print info
sleep 5
echo ""
echo ""
echo ""
echo "AOR     : $USER@$DOMAIN"
echo "PASSWORD: ilikeopensips$NUM"
echo "PROXY   : $IP"

