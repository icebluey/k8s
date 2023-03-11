# Install the dependencies
## RHEL 8
```
yum install -y binutils util-linux findutils socat ethtool iptables ebtables ipvsadm ipset psmisc bash-completion conntrack-tools iproute nfs-utils 
yum install -y coreutils-single
```
## RHEL 7 / CentOS 7
```
yum install -y binutils coreutils util-linux findutils socat ethtool iptables ebtables ipvsadm ipset psmisc bash-completion conntrack-tools iproute nfs-utils 
```
## Debian / Ubuntu 20.04+
```
apt install -y binutils coreutils util-linux socat ethtool iptables ebtables ipvsadm ipset psmisc bash-completion conntrack iproute2 nfs-common 
```
