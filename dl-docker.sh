#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ
umask 022
/sbin/ldconfig

set -e

_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"
mkdir static re-pack compose rootless-extras buildx
rm -fr /tmp/docker*.tar*

cd static

# Latest version
#_filename="$(wget -qO- 'https://download.docker.com/linux/static/stable/x86_64/' | grep '<a href="' | sed -e '/extras/d' | grep 'tgz"' | cut -d'"' -f2 | grep 'tgz$' | sort -V | uniq | tail -n 1)"

# 20.10.X
#_filename="$(wget -qO- 'https://download.docker.com/linux/static/stable/x86_64/' | grep '<a href="' | sed -e '/extras/d' | grep 'tgz"' | cut -d'"' -f2 | grep 'tgz$' | grep '20\.10\.' | sort -V | uniq | tail -n 1)"

# 23.0.X
_filename="$(wget -qO- 'https://download.docker.com/linux/static/stable/x86_64/' | grep '<a href="' | sed -e '/extras/d' | grep 'tgz"' | cut -d'"' -f2 | grep 'tgz$' | grep '23\.0\.' | sort -V | uniq | tail -n 1)"

# 26.1.X
#_filename="$(wget -qO- 'https://download.docker.com/linux/static/stable/x86_64/' | grep '<a href="' | sed -e '/extras/d' | grep 'tgz"' | cut -d'"' -f2 | grep 'tgz$' | grep '26\.1\.' | sort -V | uniq | tail -n 1)"

# 27.1.X
#_filename="$(wget -qO- 'https://download.docker.com/linux/static/stable/x86_64/' | grep '<a href="' | sed -e '/extras/d' | grep 'tgz"' | cut -d'"' -f2 | grep 'tgz$' | grep '27\.1\.' | sort -V | uniq | tail -n 1)"

# 27.2.X
_filename="$(wget -qO- 'https://download.docker.com/linux/static/stable/x86_64/' | grep '<a href="' | sed -e '/extras/d' | grep 'tgz"' | cut -d'"' -f2 | grep 'tgz$' | grep '27\.2\.' | sort -V | uniq | tail -n 1)"

_version="$(echo "${_filename}" | sed 's/\.tgz$//g' | cut -d- -f2)"
echo "Docker version ${_version}"
wget -q -c -t 0 -T 9 "https://download.docker.com/linux/static/stable/x86_64/${_filename}"
sleep 2
tar -xof "${_filename}"
sleep 2
rm -f "${_filename}"

cd ../rootless-extras
wget -q -c -t 0 -T 9 "https://download.docker.com/linux/static/stable/x86_64/docker-rootless-extras-${_version}.tgz"
sleep 2
tar -xof "docker-rootless-extras-${_version}.tgz"
sleep 2
rm -f "docker-rootless-extras-${_version}.tgz"

cd ../compose
_compose_ver="$(wget -qO- 'https://github.com/docker/compose/releases/' | grep -i '<a href="/docker/compose/tree/' | sed 's/ /\n/g' | grep -i '^href="/docker/compose/tree/' | sed 's@href="/docker/compose/tree/@@g' | sed 's/"//g' | grep -ivE 'alpha|beta|rc' | sed 's|[Vv]||g' | sort -V | uniq | tail -n 1)"
wget -q -c -t 0 -T 9 "https://github.com/docker/compose/releases/download/v${_compose_ver}/docker-compose-linux-x86_64.sha256"
wget -q -c -t 0 -T 9 "https://github.com/docker/compose/releases/download/v${_compose_ver}/docker-compose-linux-x86_64"
echo
sleep 2
sha256sum -c "docker-compose-linux-x86_64.sha256"
rc=$?
if [[ $rc != 0 ]]; then
    exit 1
fi
sleep 2
rm -f *.sha*
echo
mv -f docker-compose-linux-x86_64 docker-compose
echo

cd ../buildx
_buildx_ver="$(wget -qO- 'https://github.com/docker/buildx/releases' | grep -i 'a href="/docker/buildx/releases/download/' | sed 's|"|\n|g' | grep -i '^/docker/buildx/releases/download/.*linux-amd64.*' | grep -ivE 'alpha|beta|rc[0-9]' | sed -e 's|.*/buildx-v||g' -e 's|\.linux.*||g' | sort -V | uniq | tail -n 1)"
wget -q -c -t 0 -T 9 "https://github.com/docker/buildx/releases/download/v${_buildx_ver}/buildx-v${_buildx_ver}.linux-amd64"
sleep 2
mv -f "buildx-v${_buildx_ver}.linux-amd64" docker-buildx
sleep 2
chmod 0755 docker-buildx

cd ../re-pack

install -m 0755 -d usr/bin
install -m 0755 -d usr/libexec/docker/cli-plugins
install -m 0755 -d etc/containerd
install -m 0755 -d etc/docker
install -m 0755 -d var/lib/docker
install -m 0755 -d var/lib/docker-engine
install -m 0755 -d var/lib/containerd
install -m 0755 -d etc/systemd/system/docker.service.d
sleep 1
install -v -c -m 0755 ../static/docker/* usr/bin/
install -v -c -m 0755 ../rootless-extras/docker-rootless-extras/* usr/bin/
install -v -c -m 0755 ../compose/docker-compose usr/libexec/docker/cli-plugins/
install -v -c -m 0755 ../buildx/docker-buildx usr/libexec/docker/cli-plugins/

##############################################################################

echo '#   Copyright 2018-2021 Docker Inc.

#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at

#       https://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

disabled_plugins = ["cri"]

#root = "/var/lib/containerd"
#state = "/run/containerd"
#subreaper = true
#oom_score = 0

#[grpc]
#  address = "/run/containerd/containerd.sock"
#  uid = 0
#  gid = 0

#[debug]
#  address = "/run/containerd/debug.sock"
#  uid = 0
#  gid = 0
#  level = "info"' > etc/containerd/config.toml
sleep 1
chmod 0644 etc/containerd/config.toml

echo '{"platform":"Docker Engine - Community","engine_image":"engine-community-dm","containerd_min_version":"1.2.0-beta.1","runtime":"host_install"}' > var/lib/docker-engine/distribution_based_engine.json
sleep 1
chmod 0644 var/lib/docker-engine/distribution_based_engine.json

##############################################################################

echo '[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
BindsTo=containerd.service
After=network-online.target firewalld.service
After=flanneld.service containerd.service
Wants=network-online.target
Requires=docker.socket

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock $DOCKER_NETWORK_OPTIONS
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutSec=0
RestartSec=2
Restart=always

# Note that StartLimit* options were moved from "Service" to "Unit" in systemd 229.
# Both the old, and new location are accepted by systemd 229 and up, so using the old location
# to make them work for either version of systemd.
StartLimitBurst=3

# Note that StartLimitInterval was renamed to StartLimitIntervalSec in systemd 230.
# Both the old, and new name are accepted by systemd 230 and up, so using the old name to make
# this option work for either version of systemd.
StartLimitInterval=60s

# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not support it.
# Only systemd 226 and above support this option.
TasksMax=infinity

# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes

# kill only the docker process, not all processes in the cgroup
KillMode=process

[Install]
WantedBy=multi-user.target' > etc/docker/docker.service
sleep 1
chmod 0644 etc/docker/docker.service

##############################################################################

echo '[Unit]
Description=Docker Socket for the API
PartOf=docker.service

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target' > etc/docker/docker.socket
sleep 1
chmod 0644 etc/docker/docker.socket

##############################################################################

echo '# Copyright The containerd Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/bin/containerd
Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=1048576
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target' > etc/docker/containerd.service
sleep 1
chmod 0644 etc/docker/containerd.service

##############################################################################

echo '{
  "dns": [
    "8.8.8.8"
  ],
  "exec-opts": [
    "native.cgroupdriver=systemd"
  ],
  "storage-driver": "overlay2"
}' > etc/docker/daemon.json
sleep 1
chmod 0644 etc/docker/daemon.json

##############################################################################

echo '
cd "$(dirname "$0")"
rm -f /lib/systemd/system/containerd.service
rm -f /lib/systemd/system/docker.service
rm -f /lib/systemd/system/docker.socket
sleep 1
/bin/systemctl daemon-reload
install -v -c -m 0644 containerd.service /lib/systemd/system/
install -v -c -m 0644 docker.service /lib/systemd/system/
install -v -c -m 0644 docker.socket /lib/systemd/system/
sleep 1
/bin/systemctl daemon-reload > /dev/null 2>&1 || :
getent group docker >/dev/null 2>&1 || groupadd -r docker
' > etc/docker/.install.txt
sleep 1
chmod 0644 etc/docker/.install.txt

echo '
systemctl daemon-reload > /dev/null 2>&1 || : 
sleep 1
systemctl stop docker.socket > /dev/null 2>&1 || : 
systemctl stop docker.service > /dev/null 2>&1 || : 
sleep 1
systemctl stop containerd.service > /dev/null 2>&1 || : 
sleep 1
ip link set docker0 down > /dev/null 2>&1 || : 
sleep 1
ip link delete docker0 > /dev/null 2>&1 || : 

systemctl disable docker.socket > /dev/null 2>&1 || : 
systemctl disable docker.service > /dev/null 2>&1 || : 
systemctl disable containerd.service > /dev/null 2>&1 || : 

rm -fr /run/containerd
rm -fr /run/docker.sock
rm -fr /var/run/containerd
rm -fr /var/run/docker.sock
#rm -fr /run/docker
#rm -fr /var/run/docker
' > etc/docker/.stop-disable.txt
sleep 1
chmod 0644 etc/docker/.stop-disable.txt

##############################################################################

echo
sleep 2
file usr/bin/* | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' strip '{}'
file usr/libexec/docker/cli-plugins/* | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' strip '{}'

echo
sleep 2
##tar -Jcvf /tmp/"docker-${_version}-1_amd64.tar.xz" *
tar --format=gnu -cf - * | xz --threads=2 -v -f -z -9 > /tmp/"docker-${_version}-1_amd64.tar.xz"
echo
sleep 2
cd /tmp
openssl dgst -r -sha256 "docker-${_version}-1_amd64.tar.xz" > "docker-${_version}-1_amd64.tar.xz".sha256
sleep 2

cd /tmp
rm -fr "${_tmp_dir}"
sleep 2
echo
echo " package docker ${_version} done"
echo
exit

