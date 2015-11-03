#!/bin/bash

INSTALL_KWIKYKONF="true"
IPV6="false"
# TLS is not supported by this script
TLS="false"
TCP="true"
WS="true"
NOAUTH="true"

DIR=$(pwd)
if [[ $DIR == *scripts ]]
then
  echo "going up to project root directory"
  cd ..
  DIR=$(pwd)
fi

CENTOS="centos"
DEBIAN="debian"
NUM=$(( ( RANDOM % 1000 )  + 1 ))

# sets our OS variable based
function set_os {
  if [ -s /etc/system-release ]
  then
    OS=$CENTOS
  elif [ -s /etc/os-release ]
  then
    OS=$DEBIAN
  else
    echo "OS is not compatible"
    exit
  fi
}

# gets the ip address of eth0
function get_ip {
  if [ "$OS" == "$CENTOS" ] ; then
    IP=$(ifconfig eth0 | awk '/inet /{print substr($2,1)}')
  elif  [ "$OS" == "$DEBIAN" ] ; then
    IP=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
  fi
}

# get user input and set the domain, or set it to our IP if we get no input
function set_domain {
# get optional domain and user from user input
  echo "Enter your domain name, or press enter if you do not have one"
  read DOMAIN
  if [ -z "$DOMAIN" ]
  then
    DOMAIN="$IP"
  fi
}

# get user input and set username
function set_user {
  echo "Enter a user name, or press enter if you do not want to set up a user"
  read USER
  if [ -z "$USER" ]
  then
    USER=""
  fi
}


function install_deps {
 
  if [ "$OS" == "$CENTOS" ] ; then
    # install required deps and build tools
    yum -y install vim-enhanced libcurl-devel ncurses-devel ruby glib2 glib2-devel xmlrpc-c-devel xmlrpc-c sqlite sqlite-devel pcre pcre-devel openssl openssl-devel tcpdump iptables-devel kernel-devel kernel epel-release
    yum -y group install "Development Tools"
  elif  [ "$OS" == "$DEBIAN" ] ; then
    # update package lists
    apt-get update
    # install required dependencies and build tools
    apt-get install -y build-essential bison flex pkgconf ruby libpcre3-dev libsqlite3-dev libncurses5-dev sqlite3 libglib2.0-dev libssl-dev libxml2-dev libxmlrpc-core-c3-dev libcurl4-openssl-dev tcpdump
  fi
}

# call our functions in appropriate order
set_os
get_ip
set_domain
set_user
install_deps

# add opensips user with no shell
useradd -s /bin/false opensips

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
cd scripts/sqlite
mkdir -p /var/db/opensips && chown opensips:opensips /var/db/opensips
chown -R opensips:opensips /var/db/opensips
sqlite3 /var/db/opensips/opensips < standard-create.sql
sqlite3 /var/db/opensips/opensips < dialog-create.sql
sqlite3 /var/db/opensips/opensips < domain-create.sql
sqlite3 /var/db/opensips/opensips < auth_db-create.sql
sqlite3 /var/db/opensips/opensips < usrloc-create.sql
sqlite3 /var/db/opensips/opensips < $DIR/scripts/create_translations_table.sqlite
sqlite3 /var/db/opensips/opensips "insert into translations (from_domain,match_regex,tran_domain, tran_strip) values ('$DOMAIN','^\+18[045678]{2}[0-9]{7}$','tf.arctele.com',1);"

# set up opensipsctlrc to use our sqlite database
sed -i -e 's/# DBENGINE=MYSQL/DBENGINE=SQLITE/g' /usr/local/opensips/etc/opensips/opensipsctlrc
sed -i -e 's/# DB_PATH="\/usr\/local\/etc\/opensips\/dbtext"/DB_PATH=\/var\/db\/opensips\/opensips/g' /usr/local/opensips/etc/opensips/opensipsctlrc

# add our ip to our domain table
/usr/local/opensips/sbin/opensipsctl domain add $IP
/usr/local/opensips/sbin/opensipsctl domain add $IP:5060
/usr/local/opensips/sbin/opensipsctl domain add $IP:8080
/usr/local/opensips/sbin/opensipsctl domain add $DOMAIN
/usr/local/opensips/sbin/opensipsctl domain add $DOMAIN:5060
/usr/local/opensips/sbin/opensipsctl domain add $DOMAIN:8080

if [ "$NOAUTH" == "true" ]
then
  # make all our domains unauthenticated
  sqlite3 /var/db/opensips/opensips "update domain set attrs='noauth';"
fi
# build rtpengine daemon

cd /usr/local/src/rtpengine/daemon
git checkout -t origin/mr4.0.1
make
mkdir /usr/local/rtpengine && cp rtpengine /usr/local/rtpengine/

# start rtpengine
/usr/local/rtpengine/rtpengine -p /var/run/rtpengine.pid --interface $IP --listen-ng $IP:60000 -m 50000 -M 55000 -E -L 3 &

# build sqlite pcre extension
cd /usr/local/src/sqlite3-pcre
make && make install

# configure federated opensips.var.rb
cd $DIR/core
cp opensips.var.rb.sample opensips.var.rb

# disable tls
if [ "$TLS" == "false" ]
then
  sed -i -e 's/enable_tls      = true/enable_tls      = false/g' opensips.var.rb
fi

# disable ipv6
if [ "$IPV6" == "false" ]
then
  sed -i -e 's/enable_ipv6     = true/enable_ipv6      = false/g' opensips.var.rb
fi

# set our listening IP address
sed -i -e "s/listen_ip       = 'xxx.xxx.xxx.xxx'/listen_ip      = '$IP'/g" opensips.var.rb

# set our modules directory
sed -i -e 's#/usr/local/lib64/opensips/modules/#/usr/local/opensips/lib64/opensips/modules/#g' opensips.var.rb


# build the config
./build.rb && cp opensips.cfg /usr/local/opensips/etc/opensips/opensips.cfg

if [ "$INSTALL_KWIKYKONF" == "true" ]
then
  /usr/local/src/federated-sip/scripts/install_kwikykonf.sh
fi

# start opensips
cd /usr/local/opensips && sbin/opensips

# sleep to get nicer output, then print info
sleep 5;
echo ""
echo ""
echo ""

# add a subscriber
if [ -e "$USER" ]
then
 sbin/opensipsctl add "$USER@$DOMAIN" "ilikeopensips$NUM"
 echo "AOR     : $USER@$DOMAIN"
 echo "PASSWORD: ilikeopensips$NUM"
fi
echo "PROXY   : $IP"

