#!/bin/bash

# set this to "true" if you have loaded BOTH the rtpengine
# iptables module, and kernel module
USINGKERNEL="false"

# STOP
#--------------------------------------------------------
PID=$(pidof opensips)
if [ -e "$PID" ]
then 
  echo "opensips not running"
else
  echo "killing opensips"
  for P in $(pidof opensips)
  do
    kill -9 $P
  done
  sleep 1
fi
PID=$(pidof rtpengine)
if [ -e "$PID" ]
then 
  echo "rtpengine not running"
else
  echo "killing rtpengine"
  kill -9 $PID
  sleep 1
fi

if [ "$USINGKERNEL" == "true" ]
then
  if [ -d "/proc/rtpengine/0" ]; then
    echo "removing control table"
    echo "del 0" > /proc/rtpengine/control
  fi
  echo "removing iptables rules"
  iptables -D INPUT -p udp -j rtpengine
  iptables -D rtpengine -p udp -j RTPENGINE --id 0
  iptables -X rtpengine
  echo "unloading kernel module"
  rmmod xt_RTPENGINE
fi

sleep 1

# START
#--------------------------------------------------------
IP=$(ifconfig eth0 | grep 'inet ' | awk '{print $2}')

if [ "$USINGKERNEL" == "true" ]
then
  echo "loading kernel module"
  insmod /usr/local/src/rtpengine/kernel-module/xt_RTPENGINE.ko
  sleep 1

  echo "creating iptables rules"
  iptables -N rtpengine
  iptables -I rtpengine -p udp -j RTPENGINE --id 0
  iptables -I INPUT -p udp -j rtpengine
  sleep 1

  echo "starting rtpengine"
  /usr/local/rtpengine/rtpengine -p /var/run/rtpengine.pid --interface $IP --listen-ng $IP:60000 -m 50000 -M 55000 -L 7 --table=0 --log-facility=local3
else
  /usr/local/rtpengine/rtpengine -p /var/run/rtpengine.pid --interface $IP --listen-ng $IP:60000 -m 50000 -M 55000 -L 7 --log-facility=local3
fi
sleep 1

echo "starting opensips"
/usr/local/opensips/sbin/opensips
