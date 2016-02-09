IP server
====================

The Federated SIP project is a set of scripts designed to run OpenSIPS + rtpengine in a way that will provide federated, open communication with any other SIP server on the internet.

Federated SIP Features
----------------------

- SIP registrar with multiple domain support, including authenticated and unauthenticated users.
- Complete server side NAT handling for clients behind NAT.
- Federated SIP proxy server that follows RFC3263 for locating SIP servers.
- WebSocket, TCP, TLS, and UDP connectivity on IPV4 or IPV6.
- Media interop between DTLS-SRTP, SRTP and RTP
- Powerful regular expression based outbound translations for dynamic routing.
- Centos and Debian system set up scripts to turn a bare OS install into a full SIP system in a matter of minutes.

Also Checkout KwikyKonf:

- [code](https://github.com/etamme/kwickykonf)
- [demo](http://video.uphreak.com/#github)

Together with Federate-SIP they make a fast and light WebRTC video chat.

Installation
----------------------

- ```apt-get install ansible``` or ```yum install ansible``` on your local machine.
- ```cp hosts.sample  hosts``` and edit to include your servers domain or ip.
- run ```ansible-playbook -i hosts federated-sip.yml --extra-vars="firstrun=true"```
- after ansible finishes, you will have to add your domain to the sqlite database: ```opensipsctl domain add mydomain.com```
- finally you can add users ```opensipsctl add alice@mydomain.com passwordforalice```

Ansible will automatically utilize the primary ipv4 and ipv6 address on your remote server.  For more complex installations such as TLS, or WSS edit variables.yml to enable or disable specific options, and specify things like the location of private keys.

