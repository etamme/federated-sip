# Welcome to Federated SIP

# Overview
The Federated SIP project is a set of scripts designed to run OpenSIPS + rtpengine in a way that will provide federated, open communication with any other SIP server on the internet.

Complete documentation at [federated-sip.readthedocs.io](https://federated-sip.readthedocs.io/en/latest/)

```mermaid
flowchart LR
    bob[bob@biloxi.com] -->|INVITE alice@acme.com|biloxi((biloxi.com))
    biloxi((biloxi.com))-->|RFC 3263 location
                            INVITE alice@acme.com|acme((acme.com))
    acme((acme.com))-->|INVITE alice@acme.com|alice[alice@acme.com]
```
# Features
----------------------

- SIP registrar with multiple domain support, including authenticated and unauthenticated users.
- Complete server side NAT handling for clients behind NAT.
- Federated SIP proxy server that follows RFC3263 for locating SIP servers.
- WebSocket, TCP, TLS, and UDP connectivity on IPV4 or IPV6.
- Media interop between DTLS-SRTP, SRTP and RTP
- Powerful regular expression based outbound translations for dynamic routing.
- Centos and Debian system set up scripts to turn a bare OS install into a full SIP system in a matter of minutes.

## P2P video conferencing
----------------------
Federated SIP can facilitate peer to peer video conferencing with anonymous registration and dynamic rooms with KwikyKonf. Together with Federate-SIP they make a fast and light WebRTC video chat.

- [code](https://github.com/etamme/kwickykonf)
- [demo](http://video.uphreak.com/#github)


# Installation
----------------------

Federated-SIP has been updated to use ansible.  Ansible allows you to manage remote hosts without needing to install any client software on the remote servers.

- ```apt-get install ansible``` or ```yum install ansible``` on your local machine.
- ```cp hosts.sample  hosts``` and edit to include your servers domain or ip.
- ```cp variables.yml.sample  variables.yml``` and edit to include your servers domain.
- run ```ansible-playbook -i hosts federated-sip.yml --extra-vars="firstrun=true"```
- after ansible finishes, you can tell opensips about other domains this proxy hosts by running: ```opensipsctl domain add mydomain.com```
- finally you can add users that will be able to register to opensips ```opensipsctl add alice@mydomain.com passwordforalice```
- subsequent runs of ansible should be made with the firstrun variable set to false
- run ```ansible-playbook -i hosts federated-sip.yml --extra-vars="firstrun=false"```


Ansible will automatically utilize the primary ipv4 and ipv6 address on your remote server.  For more complex installations such as TLS, or WSS edit variables.yml to enable or disable specific options, and specify things like the location of private keys.

