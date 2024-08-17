#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ
umask 022
/sbin/ldconfig

_install_go() {
    umask 022
    set -e
    cd /tmp
    _tmp_dir="$(mktemp -d)"
    cd "${_tmp_dir}"
    # Latest version of go
    #_go_version="$(wget -qO- 'https://golang.org/dl/' | grep -i 'linux-amd64\.tar\.' | sed 's/"/\n/g' | grep -i 'linux-amd64\.tar\.' | cut -d/ -f3 | grep -i '\.gz$' | sed 's/go//g; s/.linux-amd64.tar.gz//g' | grep -ivE 'alpha|beta|rc' | sort -V | uniq | tail -n 1)"
    # Go1.17.X
    #_go_version="$(wget -qO- 'https://golang.org/dl/' | grep -i 'linux-amd64\.tar\.' | sed 's/"/\n/g' | grep -i 'linux-amd64\.tar\.' | cut -d/ -f3 | grep -i '\.gz$' | sed 's/go//g; s/.linux-amd64.tar.gz//g' | grep -ivE 'alpha|beta|rc' | sort -V | uniq | grep '^1\.17\.' | tail -n 1)"
    #wget -q -c -t 0 -T 9 "https://dl.google.com/go/go${_go_version}.linux-amd64.tar.gz"
    # Go1.18.X
    #_go_version="$(wget -qO- 'https://golang.org/dl/' | grep -i 'linux-amd64\.tar\.' | sed 's/"/\n/g' | grep -i 'linux-amd64\.tar\.' | cut -d/ -f3 | grep -i '\.gz$' | sed 's/go//g; s/.linux-amd64.tar.gz//g' | grep -ivE 'alpha|beta|rc' | sort -V | uniq | grep '^1\.18\.' | tail -n 1)"
    #wget -q -c -t 0 -T 9 "https://dl.google.com/go/go${_go_version}.linux-amd64.tar.gz"
    # Go1.20.X
    _go_version="$(wget -qO- 'https://golang.org/dl/' | grep -i 'linux-amd64\.tar\.' | sed 's/"/\n/g' | grep -i 'linux-amd64\.tar\.' | cut -d/ -f3 | grep -i '\.gz$' | sed 's/go//g; s/.linux-amd64.tar.gz//g' | grep -ivE 'alpha|beta|rc' | sort -V | uniq | grep '^1\.20\.' | tail -n 1)"
    wget -q -c -t 0 -T 9 "https://dl.google.com/go/go${_go_version}.linux-amd64.tar.gz"
    rm -fr /usr/local/go
    sleep 1
    install -m 0755 -d /usr/local/go
    tar -xof "go${_go_version}.linux-amd64.tar.gz" --strip-components=1 -C /usr/local/go/
    install -m 0755 -d /usr/local/go/home
    sleep 1
    cd /tmp
    rm -fr "${_tmp_dir}"
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
rm -fr ~/.cache/go-build

set -e

_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"

rm -fr runc
rm -fr runc.tmp
sleep 1
mkdir runc.tmp
cd runc.tmp

#_filename="$(wget -qO- 'https://download.docker.com/linux/static/stable/x86_64/' | grep '<a href="' | sed -e '/extras/d' | grep 'tgz"' | cut -d'"' -f2 | grep 'tgz$' | sort -V | uniq | tail -n 1)"
#_version="$(echo "${_filename}" | sed 's/\.tgz$//g' | cut -d- -f2)"
#wget -q -c -t 0 -T 9 "https://download.docker.com/linux/static/stable/x86_64/${_filename}"
#sleep 2
#tar -xf "${_filename}"
#sleep 2
#rm -f "${_filename}"
#ls -1 docker/runc
#sleep 1
#mv -f docker/runc ../
#sleep 2

git clone 'https://github.com/opencontainers/runc.git' runc.build
cd runc.build
sleep 1
git fetch --all --tags
sleep 1
_runc_ver="$(git tag --list | grep -ivE 'alpha|beta|rc' | sed 's/^[Vv]//g' | sort -V | tail -n 1)"
_runc_tag="$(git tag --list | grep -ivE 'alpha|beta|rc' | grep -i "${_runc_ver}")"
git checkout ${_runc_tag}
sleep 2
EXTRA_LDFLAGS='-s -w' make static
sleep 2
mv -f runc ../../
cd ..
sleep 2

cd ..
rm -fr runc.tmp

_containerd_ver="$(wget -qO- 'https://github.com/containerd/containerd/releases' | grep -i "containerd.*linux.*\.t" | grep -i 'href="/containerd/containerd/releases/download/' | sed 's|"|\n|g' | grep -i '^/containerd/containerd/releases/download/' | sed -e 's|.*/v||g' -e 's|/c.*||g' | grep -ivE 'alpha|beta|rc' | sort -V | uniq | tail -n 1)"
wget -q -c -t 0 -T 9 "https://github.com/containerd/containerd/releases/download/v${_containerd_ver}/containerd-${_containerd_ver}-linux-amd64.tar.gz.sha256sum"
wget -q -c -t 0 -T 9 "https://github.com/containerd/containerd/releases/download/v${_containerd_ver}/containerd-${_containerd_ver}-linux-amd64.tar.gz"
sleep 2
sha256sum -c "containerd-${_containerd_ver}-linux-amd64.tar.gz.sha256sum"
sleep 2
rm -f "containerd-${_containerd_ver}-linux-amd64.tar.gz.sha256sum"
tar -xof "containerd-${_containerd_ver}-linux-amd64.tar.gz"

rm -fr /tmp/containerd
sleep 2
install -m 0755 -d /tmp/containerd/usr/bin
install -m 0755 -d /tmp/containerd/etc/containerd/certs.d
install -m 0755 -d /tmp/containerd/etc/containerd/ocicrypt/keys
install -m 0755 -d /tmp/containerd/var/lib/containerd

install -v -c -m 0755 bin/* /tmp/containerd/usr/bin/
rm -f /tmp/containerd/usr/bin/runc
sleep 1
install -v -c -m 0755 runc /tmp/containerd/usr/bin/

cd /tmp/containerd
sleep 2
file usr/bin/* | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' strip '{}'

./usr/bin/containerd config default | sed 's|SystemdCgroup =.*|SystemdCgroup = true|g' | sed '/disable_apparmor/s|false|true|g' > etc/containerd/config.toml
sleep 1
chmod 0644 etc/containerd/config.toml
sed "$(cat -n etc/containerd/config.toml | grep '\[plugins."io.containerd.grpc.v1.cri".registry\]' -A 2 | grep 'config_path' | awk '{print $1}')s|config_path =.*|config_path = "\""/etc/containerd/certs.d"\""|g" -i etc/containerd/config.toml
sleep 1
mv -f etc/containerd/config.toml etc/containerd/config.toml.example

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
WantedBy=multi-user.target' > etc/containerd/containerd.service
sleep 1
chmod 0644 etc/containerd/containerd.service

echo '
cd "$(dirname "$0")"
[ -f /etc/containerd/config.toml ] || cp -f /etc/containerd/config.toml.example /etc/containerd/config.toml
rm -f /lib/systemd/system/containerd.service
sleep 1
/bin/systemctl daemon-reload
install -v -c -m 0644 containerd.service /lib/systemd/system/
sleep 1
/bin/systemctl daemon-reload > /dev/null 2>&1 || :
' > etc/containerd/.install.txt
sleep 1
chmod 0644 etc/containerd/.install.txt

echo
sleep 2
##tar -Jcvf /tmp/"containerd-${_containerd_ver}-1_amd64.tar.xz" *
tar --format=gnu -cf - * | xz --threads=2 -v -f -z -9 > /tmp/"containerd-${_containerd_ver}-1_amd64.tar.xz"
echo
sleep 2
cd /tmp
openssl dgst -r -sha256 "containerd-${_containerd_ver}-1_amd64.tar.xz" > "containerd-${_containerd_ver}-1_amd64.tar.xz".sha256
sleep 2

cd /tmp
rm -fr "${_tmp_dir}"
rm -fr /tmp/containerd
rm -fr /usr/local/go
rm -fr ~/.cache/go-build
sleep 2
echo
echo " package containerd ${_containerd_ver} done"
echo
exit

