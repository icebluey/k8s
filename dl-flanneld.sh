#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ

_install_go () {
    cd /tmp
    rm -fr /tmp/.dl.go.tmp
    mkdir /tmp/.dl.go.tmp
    cd /tmp/.dl.go.tmp
    # Latest version of go
    #_go_version="$(wget -qO- 'https://golang.org/dl/' | grep -i 'linux-amd64\.tar\.' | sed 's/"/\n/g' | grep -i 'linux-amd64\.tar\.' | cut -d/ -f3 | grep -i '\.gz$' | sed 's/go//g; s/.linux-amd64.tar.gz//g' | grep -ivE 'alpha|beta|rc' | sort -V | uniq | tail -n 1)"
    # go1.19.X
    #_go_version="$(wget -qO- 'https://golang.org/dl/' | grep -i 'linux-amd64\.tar\.' | sed 's/"/\n/g' | grep -i 'linux-amd64\.tar\.' | cut -d/ -f3 | grep -i '\.gz$' | sed 's/go//g; s/.linux-amd64.tar.gz//g' | grep -ivE 'alpha|beta|rc' | sort -V | uniq | grep '^1\.19\.' | tail -n 1)"
    #wget -q -c -t 0 -T 9 "https://dl.google.com/go/go${_go_version}.linux-amd64.tar.gz"
    # go1.20.X
    _go_version="$(wget -qO- 'https://golang.org/dl/' | grep -i 'linux-amd64\.tar\.' | sed 's/"/\n/g' | grep -i 'linux-amd64\.tar\.' | cut -d/ -f3 | grep -i '\.gz$' | sed 's/go//g; s/.linux-amd64.tar.gz//g' | grep -ivE 'alpha|beta|rc' | sort -V | uniq | grep '^1\.20\.' | tail -n 1)"
    wget -q -c -t 0 -T 9 "https://dl.google.com/go/go${_go_version}.linux-amd64.tar.gz"
    rm -fr /usr/local/go
    sleep 1
    mkdir /usr/local/go
    tar -xof "go${_go_version}.linux-amd64.tar.gz" --strip-components=1 -C /usr/local/go/
    sleep 1
    cd /tmp
    rm -fr /tmp/.dl.go.tmp
}

_install_go

# Go programming language
export GOROOT='/usr/local/go'
export GOPATH="$GOROOT/home"
export GOTMPDIR='/tmp'
export GOBIN="$GOROOT/bin"
export PATH="$GOROOT/bin:$PATH"
alias go="$GOROOT/bin/go"
alias gofmt="$GOROOT/bin/gofmt"
echo
go version
echo
rm -fr ~/.cache/go-build

CC=gcc
export CC
CXX=g++
export CXX
/sbin/ldconfig

set -e

_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"
rm -fr /tmp/flannel

_tag_ver="$(wget -qO- 'https://github.com/flannel-io/flannel/releases' | grep -i 'href="/flannel-io/flannel/tree/' | sed 's/"/\n/g' | grep -i '^/flannel-io/flannel/tree' | sed -e 's|.*tree/v||g' -e 's|/.*||g' | grep -ivE 'alpha|beta|rc' | sort -V | tail -n 1)"
wget -q -c -t 0 -T 9 "https://github.com/flannel-io/flannel/archive/refs/tags/v${_tag_ver}.tar.gz"
sleep 2
tar -xf "v${_tag_ver}.tar.gz"
sleep 2
rm -f *.tar*
cd flannel-${_tag_ver}
rm -f dist/flanneld
sleep 1

if wget -q -T 9 "https://github.com/flannel-io/flannel/releases/download/v${_tag_ver}/flanneld-amd64" -O /dev/null 2>/dev/null; then
    wget -q -c -t 0 -T 9 "https://github.com/flannel-io/flannel/releases/download/v${_tag_ver}/flanneld-amd64" -O dist/flanneld
    sleep 2
    chmod 0755 dist/flanneld
else
    CGO_ENABLED=1 \
    go build -o dist/flanneld \
    -ldflags "-s -w -X github.com/flannel-io/flannel/version.Version=v${_tag_ver} -extldflags '-static'" -trimpath
fi

echo
install -m 0755 -d /tmp/flannel/usr/bin
install -m 0755 -d /tmp/flannel/usr/libexec/flannel
install -m 0755 -d /tmp/flannel/etc/flannel
install -m 0755 -d /tmp/flannel/etc/sysconfig
#install -m 0755 -d /tmp/flannel/etc/systemd/system/docker.service.d
#install -m 0755 -d /tmp/flannel/usr/lib/tmpfiles.d
sleep 1

install -v -c -m 0755 dist/flanneld /tmp/flannel/usr/bin/
install -v -c -m 0755 dist/mk-docker-opts.sh /tmp/flannel/usr/libexec/flannel/

cd /tmp/flannel

sleep 2
find usr/bin/ -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' strip '{}'
sleep 2

echo '[Unit]
Description=Flanneld overlay address etcd agent
After=network.target
After=network-online.target
Wants=network-online.target
After=etcd.service
Before=docker.service

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/flanneld
EnvironmentFile=-/etc/sysconfig/docker-network
ExecStart=/usr/bin/flanneld -etcd-endpoints=${FLANNEL_ETCD_ENDPOINTS} -etcd-prefix=${FLANNEL_ETCD_PREFIX} $FLANNEL_OPTIONS
ExecStartPost=/usr/libexec/flannel/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker
Restart=on-failure

[Install]
WantedBy=multi-user.target
RequiredBy=docker.service' > etc/flannel/flanneld.service

echo '# Flanneld configuration options  

# etcd url location.  Point this to the server where etcd runs
FLANNEL_ETCD_ENDPOINTS="http://127.0.0.1:2379"

# etcd config key.  This is the configuration key that flannel queries
# For address range assignment
FLANNEL_ETCD_PREFIX="/atomic.io/network"

# Any additional options that you want to pass
#FLANNEL_OPTIONS=""
' > etc/sysconfig/flanneld
sleep 1
chmod 0644 etc/sysconfig/flanneld

echo '
cd "$(dirname "$0")"
rm -f /lib/systemd/system/flanneld.service
sleep 1
install -c -m 0644 flanneld.service /lib/systemd/system/

install -m 0755 -d /etc/systemd/system/docker.service.d
sleep 1
echo '\''[Service]
EnvironmentFile=-/run/flannel/docker'\'' > /etc/systemd/system/docker.service.d/flannel.conf
sleep 1
chmod 0644 /etc/systemd/system/docker.service.d/flannel.conf

echo '\''d /run/flannel 0755 root root -'\'' > /usr/lib/tmpfiles.d/flannel.conf
sleep 1
chmod 0644 /usr/lib/tmpfiles.d/flannel.conf

systemctl daemon-reload >/dev/null 2>&1 || : 
' > etc/flannel/.install.txt

echo
sleep 2
#tar -Jcvf /tmp/"flannel_${_tag_ver}-1_static.tar.xz" *
tar --format=gnu -cf - * | xz --threads=2 -v -f -z -9 > /tmp/"flannel_${_tag_ver}-1_static.tar.xz"
echo
sleep 2
cd /tmp
openssl dgst -r -sha256 "flannel_${_tag_ver}-1_static.tar.xz" > "flannel_${_tag_ver}-1_static.tar.xz".sha256

cd /tmp
rm -fr /tmp/flannel
rm -fr "${_tmp_dir}"
rm -fr ~/.cache/go-build
rm -fr /usr/local/go
sleep 2
echo
echo " package flannel ${_tag_ver} done"
echo
exit

