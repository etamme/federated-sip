#!/bin/bash
PWD=$(pwd)
useradd -s /bin/false opensips
yum -y install vim-enhanced libcurl-devel ncurses-devel  glib2 glib2-devel xmlrpc-c-devel xmlrpc-c sqlite sqlite-devel
yum -y group install "Development Tools"
cd /usr/local/src
git clone https://github.com/OpenSIPS/opensips.git
git clone https://github.com/sipwise/rtpengine.git
git clone https://github.com/ralight/sqlite3-pcre.git
cd opensips
cp Makefile.conf.template Makefile.conf
sed -i -e 's/include_modules?=/include_modules?= db_sqlite/g' Makefile.conf 
sed -i -e 's/PREFIX=\/usr\/local\//PREFIX=\/usr\/local\/opensips\//g' Makefile.conf
make all && make all install
mkdir /var/db/opensips && chown opensips:opensips /var/db/opensips
sudo -u opensips sqlite3 /var/db/opensips/opensips < standard-create.sql
sudo -u opensips sqlite3 /var/db/opensips/opensips < dialog-create.sql
sudo -u opensips sqlite3 /var/db/opensips/opensips < domain-create.sql
sudo -u opensips sqlite3 /var/db/opensips/opensips < auth_db-create.sql
sudo -u opensips sqlite3 /var/db/opensips/opensips < usrloc-create.sql
sudo -u opensips sqlite3 /var/db/opensips/opensips < $PWD/create_translations_table.sqlite
sed -i -e 's/# DBENGINE=MYSQL/DBENGINE=SQLITE/g' /usr/local/opensips/etc/opensips/opensipsctlrc
sed -i -e 's/# DB_PATH="\/usr\/local\/etc\/opensips\/dbtext"/DB_PATH=\/var\/db\/opensips\/opensips/g' /usr/local/opensips/etc/opensips/opensipsctlrc
