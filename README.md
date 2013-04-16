This is a generalized configuration for an OpenSIPS proxy server

Edit: opensips.vars.rb and set appropriate variables
Run: ./build.rb to generate an opensips.cfg

You will need to populate your database (mysql) to accomodate the modules used in the config.

You will need to install rtpproxy as well to relay media for clients behind NAT.

scripts/ contains init scripts for opensips and rtpproxy.  The rtpproxy script will need to have RTP_IP_ADDRESS changed.
The opensips init script has conventions for a preix of /usr/local/opensips which you must change if you have a different
install prefix.
