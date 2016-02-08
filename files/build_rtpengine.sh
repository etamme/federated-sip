#!/bin/bash
cd /usr/local/src
git clone https://github.com/sipwise/rtpengine.git
cd /usr/local/src/rtpengine/daemon
git checkout -t origin/mr4.0.1
make
mkdir /usr/local/rtpengine && cp rtpengine /usr/local/rtpengine/
