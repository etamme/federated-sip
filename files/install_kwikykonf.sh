#!/bin/bash
CWD=$(pwd)
CENTOS="centos"
DEBIAN="debian"

function get_ip {
  if [ "$OS" == "$CENTOS" ] ; then
    IP=$(ifconfig eth0 | awk '/inet /{print substr($2,1)}')
  elif  [ "$OS" == "$DEBIAN" ] ; then
    IP=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
  fi
}


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

set_os
get_ip

if [ "$OS" == "$CENTOS" ]
then
  yum -y install epel-release
  yum -y install lighttpd
elif [ "$OS" == "$DEBIAN" ]
then
  apt-get install -y lighttpd
fi

cd /usr/local/src
git clone https://github.com/etamme/kwikykonf.git

cd kwikykonf
cp config.var.rb.sample config.var.rb
sed -i -e "s/example.com/$IP/g" config.var.rb
./build.rb

if [ "$OS" == "$CENTOS" ]
then
  rm -rf /var/www/lighttpd/*
  cp -R /usr/local/src/kwikykonf/* /var/www/lighttpd/
elif [ "$OS" == "$DEBIAN" ]
then
  rm -rf /var/www/html/*
  cp -R /usr/local/src/kwikykonf/* /var/www/html/
fi
systemctl start lighttpd
cd $CWD
