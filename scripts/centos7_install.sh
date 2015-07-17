#!/bin/bash
# get some basica vars for later
PWD=$(pwd)
IP=$(ifconfig eth0 | awk '/inet /{print substr($2,1)}')
# add opensips user with no shell
useradd -s /bin/false opensips
# install required deps and build tools
yum -y install vim-enhanced libcurl-devel ncurses-devel  glib2 glib2-devel xmlrpc-c-devel xmlrpc-c sqlite sqlite-devel pcre pcre-devel openssl openssl-devel
yum -y group install "Development Tools"
# clone required repos
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
mkdir /var/db/opensips && chown opensips:opensips /var/db/opensips
sudo -u opensips sqlite3 /var/db/opensips/opensips < standard-create.sql
sudo -u opensips sqlite3 /var/db/opensips/opensips < dialog-create.sql
sudo -u opensips sqlite3 /var/db/opensips/opensips < domain-create.sql
sudo -u opensips sqlite3 /var/db/opensips/opensips < auth_db-create.sql
sudo -u opensips sqlite3 /var/db/opensips/opensips < usrloc-create.sql
sudo -u opensips sqlite3 /var/db/opensips/opensips < $PWD/create_translations_table.sqlite
# set up opensipsctlrc to use our sqlite database
sed -i -e 's/# DBENGINE=MYSQL/DBENGINE=SQLITE/g' /usr/local/opensips/etc/opensips/opensipsctlrc
sed -i -e 's/# DB_PATH="\/usr\/local\/etc\/opensips\/dbtext"/DB_PATH=\/var\/db\/opensips\/opensips/g' /usr/local/opensips/etc/opensips/opensipsctlrc
# add our ip to our domain table
/usr/local/opensips/sbin/opensipsctl domain add $IP:5060
# build rtpengine daemon
cd /usr/local/src/rtpengine/daemon && make
mkdir /usr/local/rtpengine && cp rtpengine /usr/local/rtpengine/
# start rtpengine
/usr/local/rtpengine/rtpengine -p /var/run/rtpengine.pid --interface $IP --listen-ng $IP:60000 -m 50000 -M 55000 -E -L 3 &
