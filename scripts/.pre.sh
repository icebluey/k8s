# ubuntu 20.04

apt update -y -qqq

apt install -y -qqq bash
sleep 1
ln -svf bash /bin/sh

ln -svf ../usr/share/zoneinfo/UTC /etc/localtime
DEBIAN_FRONTEND=noninteractive apt install -y tzdata
dpkg-reconfigure --frontend noninteractive tzdata

apt install -y -qqq binutils coreutils findutils util-linux libc-bin passwd pkg-config
apt install -y -qqq make gcc g++ perl libperl-dev groff-base dpkg-dev cmake libtool m4
apt install -y -qqq zlib1g-dev libzstd-dev liblzma-dev libbz2-dev gzip bzip2 xz-utils tar
apt install -y -qqq libssl-dev openssl ca-certificates wget curl git sed grep gawk
apt install -y -qqq file patch procps iproute2 net-tools iputils-ping
apt install -y -qqq libseccomp-dev libseccomp2

# install gcc 10
apt install -y -qqq gcc-10 g++-10 libstdc++-10-dev cpp-10
sleep 2
ln -svf cpp-10 /usr/bin/x86_64-linux-gnu-cpp
ln -svf g++-10 /usr/bin/g++
ln -svf g++-10 /usr/bin/x86_64-linux-gnu-g++
ln -svf gcc-10 /usr/bin/gcc
ln -svf gcc-10 /usr/bin/x86_64-linux-gnu-gcc
ln -svf gcc-ar-10 /usr/bin/gcc-ar
ln -svf gcc-ar-10 /usr/bin/x86_64-linux-gnu-gcc-ar
ln -svf gcc-nm-10 /usr/bin/gcc-nm
ln -svf gcc-nm-10 /usr/bin/x86_64-linux-gnu-gcc-nm
ln -svf gcc-ranlib-10 /usr/bin/gcc-ranlib
ln -svf gcc-ranlib-10 /usr/bin/x86_64-linux-gnu-gcc-ranlib
ln -svf gcov-10 /usr/bin/gcov
ln -svf gcov-10 /usr/bin/x86_64-linux-gnu-gcov
ln -svf gcov-dump-10 /usr/bin/gcov-dump
ln -svf gcov-dump-10 /usr/bin/x86_64-linux-gnu-gcov-dump
ln -svf gcov-tool-10 /usr/bin/gcov-tool
ln -svf gcov-tool-10 /usr/bin/x86_64-linux-gnu-gcov-tool

apt upgrade -y -qqq
sleep 2
/sbin/ldconfig

sleep 2
exit

