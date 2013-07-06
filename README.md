This is a generalized configuration for an OpenSIPS proxy server.

Overview:


Core:

This project contains a core OpenSIPS proxy server which can act as a registrar, as well as a federated SIP proxy.  The default behavior is to allow any external entity to call a domain that is hosted with the core proxy, and to authenticate any call to an external domain.  This allows authenticated users of the core proxy to call out to any external domain, or between domains hosted on the proxy.

How does the proxy know what domains are "external"? Easy, you tell it.  This script config uses the domain module which allows you to load domain names into a database.  The proxy can then check to see if the domain in the request URI is a domain that is "local" or "external" and do a registration lookup for "local" domains, or authenticate the user making an external request and forward it to the "external" domain based on DNS.

The core config also makes use of aliases, and custom routing translations.  Aliasas simply map a request user and domain to one or more different request users and domains.  With aliases you can creat things like ring groups or "extensions" for registered users so they can be called from a phone that only has a number pad.

Custom routing translations are very powerful and allow simple integration with external services, such as a PSTN carrier.  You can use the translations to match a regular expression, then translate the user and domain portions of the request uri.  The translations allow for stripping, prefixing, or complete replacement.

App: 




Edit: opensips.vars.rb and set appropriate variables
Run: ./build.rb to generate an opensips.cfg

You will need to populate your database (mysql) to accomodate the modules used in the config.

You will need to install rtpproxy as well to relay media for clients behind NAT.

scripts/ contains init scripts for opensips and rtpproxy.  The rtpproxy script will need to have RTP_IP_ADDRESS changed.
The opensips init script has conventions for a preix of /usr/local/opensips which you must change if you have a different
install prefix.
