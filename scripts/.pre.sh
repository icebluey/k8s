#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ
umask 022
ln -svf ../usr/share/zoneinfo/UTC /etc/localtime
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y tzdata
dpkg-reconfigure --frontend noninteractive tzdata
snap remove --purge lxd
snap remove --purge firefox
snap remove --purge snap-store
snap remove --purge core
snap remove --purge core18
snap remove --purge core20
snap remove --purge snapd-desktop-integration
systemctl stop docker.socket
systemctl stop podman.socket
systemctl stop docker.service
systemctl stop containerd.service
systemctl stop podman.service
systemctl disable docker.socket
systemctl disable podman.socket
systemctl disable docker.service
systemctl disable containerd.service
systemctl disable podman.service
systemctl stop snapd.service
systemctl stop snapd.socket
systemctl stop snapd.seeded.service
systemctl disable snapd.service
systemctl disable snapd.socket
systemctl disable snapd.seeded.service
apt autoremove --purge -y snapd
apt autoremove --purge -y firefox
apt autoremove --purge -y moby-engine
apt autoremove --purge -y moby-cli
apt autoremove --purge -y moby-buildx
apt autoremove --purge -y moby-compose
apt autoremove --purge -y moby-containerd
apt autoremove --purge -y moby-runc
apt autoremove --purge -y podman
apt autoremove --purge -y crun
rm -fr ~/snap
rm -fr /snap
rm -fr /var/snap
rm -fr /var/lib/snapd
rm -fr /var/cache/snapd
rm -fr /tmp/snap*
rm -fr /etc/apt/preferences.d/firefox*
systemctl stop systemd-resolved.service
systemctl stop systemd-timesyncd
systemctl stop unattended-upgrades
systemctl stop udisks2.service
systemctl disable systemd-resolved.service
systemctl disable systemd-timesyncd
systemctl disable unattended-upgrades
systemctl disable udisks2.service
rm -fr /etc/resolv.conf
echo "nameserver 8.8.8.8" >/etc/resolv.conf 
apt install -y chrony
systemctl stop chrony.service
sed -e "/^pool/d" -i /etc/chrony/chrony.conf
sed -e "/^server/d" -i /etc/chrony/chrony.conf
sed -e "s|^refclock|#refclock|g" -i /etc/chrony/chrony.conf
sed -e "1iserver time1.google.com iburst minpoll 4 maxpoll 5\nserver time2.google.com iburst minpoll 4 maxpoll 5\nserver time3.google.com iburst minpoll 4 maxpoll 5\nserver time4.google.com iburst minpoll 4 maxpoll 5" -i /etc/chrony/chrony.conf
systemctl start chrony.service
systemctl enable chrony.service
sleep 10
chronyc makestep
apt install -y binutils coreutils util-linux findutils diffutils pkg-config
apt install -y systemd passwd patch sed gawk grep file tar gzip bzip2 xz-utils
apt install -y socat ethtool ipvsadm ipset psmisc bash-completion conntrack iproute2 nfs-common
apt install -y daemon procps net-tools
apt install -y iptables
apt install -y ebtables
apt install -y nftables
apt install -y libseccomp-dev libseccomp2

apt install -y binutils coreutils util-linux findutils diffutils patch sed gawk grep file tar gzip bzip2 xz-utils
apt install -y libc-bin passwd pkg-config groff-base
apt install -y zlib1g-dev libzstd-dev liblzma-dev libbz2-dev tar gzip bzip2 xz-utils
apt install -y libssl-dev openssl procps iproute2 net-tools iputils-ping vim bind9-dnsutils libxml2-utils
apt install -y daemon procps psmisc net-tools
apt install -y lsof strace sysstat tcpdump
apt install -y make gcc g++ perl libperl-dev groff-base dpkg-dev cmake m4
# build from src
apt install -y autoconf autoconf-archive autogen automake autopoint autotools-dev libtool m4 bison flex
# build openssl 1.1.1
apt install -y libsctp-dev
# build nginx
apt install -y bc uuid-dev libgd-dev libxslt1-dev libxml2-dev libpcre2-dev libpcre3-dev libpng-dev libjpeg-dev
# build pinentry (gnupg)
apt install -y libncurses-dev libreadline-dev libldap2-dev libsqlite3-dev libusb-1.0-0-dev libsecret-1-dev
# build openssh
apt install -y libedit-dev libssh2-1-dev libpam0g-dev libsystemd-dev groff-base
# build haproxy
apt install -y libsystemd-dev libcrypt-dev
apt install -y libtinfo-dev libncurses-dev
# run keepalived
apt install -y libnl-3-200 libnl-genl-3-200 libsnmp-dev libnftnl11 libsystemd0
apt install -y libnftables-dev nftables
apt install -y libipset-dev ipset
apt install -y iptables
apt install -y libsnmp-dev libmnl-dev libnftnl-dev libnl-3-dev libnl-genl-3-dev libnfnetlink-dev
# build nettle for gnutls
apt install -y libgmp-dev
# build gnutls for chrony
apt install -y libp11-kit-dev libidn2-dev
# build chrony
apt install -y libseccomp-dev libcap-dev
# build libfido2
apt install -y libcbor-dev libpcsclite-dev
apt install -y daemon procps psmisc net-tools chrpath libtasn1-6-dev gettext
apt install -y libnftables-dev nftables || : 
apt install -y libipset-dev ipset || : 
apt install -y iptables || : 
apt install -y libsnmp-dev libmnl-dev libnftnl-dev libnl-3-dev libnl-genl-3-dev libnfnetlink-dev || : 

exit
