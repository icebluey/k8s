#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ

set -e

_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"
_etcd_ver="$(wget -qO- 'https://github.com/etcd-io/etcd/releases/' | grep -i 'href="/etcd-io/etcd/tree/' | sed 's|"|\n|g' | grep -i '^/etcd-io/etcd/tree/v[0-9]' | sed 's|/etcd-io/etcd/tree/v||g' | grep -ivE 'alpha|beta|rc' | sort -V | uniq | tail -n 1)"
wget -q -c -t 0 -T 9 "https://github.com/etcd-io/etcd/releases/download/v${_etcd_ver}/etcd-v${_etcd_ver}-linux-amd64.tar.gz"
sleep 2
tar -xf etcd-v${_etcd_ver}-linux-amd64.tar.gz
sleep 2
rm -f *.tar*
cd etcd-v${_etcd_ver}-*

rm -fr /tmp/etcd
sleep 1
install -m 0755 -d /tmp/etcd/usr/bin
install -m 0755 -d /tmp/etcd/etc/etcd
#install -m 0755 -d /tmp/etcd/var/lib/etcd
sleep 1
install -c -m 0755 etcd /tmp/etcd/usr/bin/
install -c -m 0755 etcdctl /tmp/etcd/usr/bin/
install -c -m 0755 etcdutl /tmp/etcd/usr/bin/

cd /tmp/etcd

sleep 2
find usr/bin/ -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' strip '{}'
sleep 2

echo '#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export ETCDCTL_API=2
exec /usr/bin/etcdctl \
"$@"
' > usr/bin/etcdctl-v2
sleep 1
chmod 0755 usr/bin/etcdctl-v2

echo '# [member]
ETCD_ENABLE_V2=true
ETCD_NAME=default
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
#ETCD_WAL_DIR=""
#ETCD_SNAPSHOT_COUNT="10000"
#ETCD_HEARTBEAT_INTERVAL="100"
#ETCD_ELECTION_TIMEOUT="1000"
#ETCD_LISTEN_PEER_URLS="http://localhost:2380"
ETCD_LISTEN_CLIENT_URLS="http://localhost:2379"
#ETCD_MAX_SNAPSHOTS="5"
#ETCD_MAX_WALS="5"
#ETCD_CORS=""
#
#[cluster]
#ETCD_INITIAL_ADVERTISE_PEER_URLS="http://localhost:2380"
# if you use different ETCD_NAME (e.g. test), set ETCD_INITIAL_CLUSTER value for this name, i.e. "test=http://..."
#ETCD_INITIAL_CLUSTER="default=http://localhost:2380"
#ETCD_INITIAL_CLUSTER_STATE="new"
#ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="http://localhost:2379"
#ETCD_DISCOVERY=""
#ETCD_DISCOVERY_SRV=""
#ETCD_DISCOVERY_FALLBACK="proxy"
#ETCD_DISCOVERY_PROXY=""
#ETCD_STRICT_RECONFIG_CHECK="false"
#ETCD_AUTO_COMPACTION_RETENTION="0"
#
#[proxy]
#ETCD_PROXY="off"
#ETCD_PROXY_FAILURE_WAIT="5000"
#ETCD_PROXY_REFRESH_INTERVAL="30000"
#ETCD_PROXY_DIAL_TIMEOUT="1000"
#ETCD_PROXY_WRITE_TIMEOUT="5000"
#ETCD_PROXY_READ_TIMEOUT="0"
#
#[security]
#ETCD_CERT_FILE=""
#ETCD_KEY_FILE=""
#ETCD_CLIENT_CERT_AUTH="false"
#ETCD_TRUSTED_CA_FILE=""
#ETCD_AUTO_TLS="false"
#ETCD_PEER_CERT_FILE=""
#ETCD_PEER_KEY_FILE=""
#ETCD_PEER_CLIENT_CERT_AUTH="false"
#ETCD_PEER_TRUSTED_CA_FILE=""
#ETCD_PEER_AUTO_TLS="false"
#
#[logging]
#ETCD_DEBUG="false"
# examples for -log-package-levels etcdserver=WARNING,security=DEBUG
#ETCD_LOG_PACKAGE_LEVELS=""' > etc/etcd/etcd.conf
sleep 1
chmod 0644 etc/etcd/etcd.conf
sleep 1
mv -f etc/etcd/etcd.conf etc/etcd/etcd.conf.default

echo '[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
EnvironmentFile=-/etc/etcd/etcd.conf
User=etcd
Group=etcd
# set GOMAXPROCS to number of processors
ExecStart=/bin/bash -c "GOMAXPROCS=$(nproc) /usr/bin/etcd"
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target' > etc/etcd/etcd.service

echo '
cd "$(dirname "$0")"
groupdel -f etcd >/dev/null 2>&1 || : 
userdel -f -r etcd >/dev/null 2>&1 || : 
rm -f /lib/systemd/system/etcd.service
install -m 0755 -d /var/lib/etcd
sleep 1
getent group etcd >/dev/null || groupadd -r etcd
getent passwd etcd >/dev/null || useradd -r -g etcd -d /var/lib/etcd \
    -s /usr/sbin/nologin -c "etcd user" etcd
install -c -m 0644 etcd.service /lib/systemd/system/
chown -R etcd:etcd /var/lib/etcd
sleep 1
systemctl daemon-reload >/dev/null 2>&1 || : 
' > etc/etcd/.install.txt

echo
sleep 2
#tar -Jcvf /tmp/"etcd_${_etcd_ver}-1_static.tar.xz" *
tar --format=gnu -cf - * | xz --threads=2 -v -f -z -9 > /tmp/"etcd_${_etcd_ver}-1_static.tar.xz"
echo
sleep 2
cd /tmp
sha256sum "etcd_${_etcd_ver}-1_static.tar.xz" > "etcd_${_etcd_ver}-1_static.tar.xz".sha256

cd /tmp
rm -fr /tmp/etcd
rm -fr "${_tmp_dir}"
sleep 2
echo
echo " package etcd ${_etcd_ver} done"
echo
exit

