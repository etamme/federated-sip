#!/bin/bash
CWD=$(pwd)
IP=$(ifconfig eth0 | awk '/inet /{print substr($2,1)}')

yum -y install epel-release
yum -y install lighttpd
cd /usr/local/src
git clone https://github.com/etamme/kwikykonf.git

cd kwikykonf
cp config.var.rb.sample config.var.rb
sed -i -e "s/example.com/$IP/g" config.var.rb
./build.rb
rm -rf /var/www/lighttpd/*
cp -R /usr/local/src/kwikykonf/* /var/www/lighttpd/
systemctl start lighttpd
cd $CWD
