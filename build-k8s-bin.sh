#!/bin/bash
TZ="UTC"; export TZ
umask 022
set -e
_install_go() {
    umask 022
    set -e
    cd /tmp
    _tmp_dir="$(mktemp -d)"
    cd "${_tmp_dir}"
    #wget -q -c -t 0 -T 9 "https://dl.google.com/go/go${_go_version}.linux-amd64.tar.gz"
    if [[ $(echo "${_go_ver}" | grep -o "\." | wc -l) -gt 1 ]]; then
        _go_version="$(wget -qO- "https://golang.org/dl/" | grep -ivE "alpha|beta|rc[1-9]" | grep -i "linux-amd64\.tar\." | sed 's/"/\n/g' | grep -i "linux-amd64\.tar\." | cut -d/ -f3 | grep -i "\.gz$" | sed "s/go//g; s/.linux-amd64.tar.gz//g" | sort -V | uniq | grep "${_go_ver%.*}\." | sort -V | uniq | tail -n1)"
    else
        _go_version="${_go_ver}"
    fi
    wget -c -t 0 -T 9 "https://dl.google.com/go/go${_go_version}.linux-amd64.tar.gz"
    rm -fr /usr/local/go
    sleep 1
    install -m 0755 -d /usr/local/go
    tar -xof "go${_go_version}.linux-amd64.tar.gz" --strip-components=1 -C /usr/local/go/
    install -m 0755 -d /usr/local/go/home
    sleep 1
    cd /tmp
    rm -fr "${_tmp_dir}"
    # Go programming language
    export GOROOT="/usr/local/go"
    export GOPATH="$GOROOT/home"
    export GOTMPDIR="/tmp"
    export GOBIN="$GOROOT/bin"
    export PATH="$GOROOT/bin:$PATH"
    alias go="$GOROOT/bin/go"
    alias gofmt="$GOROOT/bin/gofmt"
    echo
    go version
    echo
}
_k8s_ver="${1}"
wget -q -c -t 0 -T 9 -O /tmp/kubeadm.bin "https://dl.k8s.io/release/v${_k8s_ver}/bin/linux/amd64/kubeadm"
chmod 0755 /tmp/kubeadm.bin
_go_ver="$(/tmp/kubeadm.bin version | sed 's|"|\n|g' | grep -i '^go[1-9]' | sed 's|go||g')"
sleep 1
rm -fr /tmp/kubeadm.bin
_install_go "${_go_ver}"
_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"
wget -c -t 9 -T 9 "https://github.com/kubernetes/kubernetes/archive/refs/tags/v${_k8s_ver}.tar.gz"
tar -xof *.tar*
sleep 1
rm -f *.tar*
cd k*
# Go programming language
export GOROOT="/usr/local/go"
export GOPATH="$GOROOT/home"
export GOTMPDIR="/tmp"
export GOBIN="$GOROOT/bin"
export PATH="$GOROOT/bin:$PATH"
alias go="$GOROOT/bin/go"
alias gofmt="$GOROOT/bin/gofmt"
rm -fr ~/.cache/go-build
# staging/src/k8s.io/client-go/util/cert/cert.go
sed '/NotAfter:/s|\(duration365d \* 10\)|\(duration365d * 100\)|g' -i staging/src/k8s.io/client-go/util/cert/cert.go
# cmd/kubeadm/app/constants/constants.go
sed '/CertificateValidity =/s|time.Hour \* 24 \* 365$|time.Hour * 24 * 365 * 100|g' -i cmd/kubeadm/app/constants/constants.go
grep -i 'NotAfter:.*duration365d ' staging/src/k8s.io/client-go/util/cert/cert.go
grep -i 'CertificateValidity = time.Hour ' cmd/kubeadm/app/constants/constants.go
_files=(
"kubeadm"
"kubectl"
"kubelet"
"kube-proxy"
"kubectl-convert"
)
for file in ${_files[@]}; do
    make -j2 all WHAT=cmd/"${file}" GOFLAGS="-v"
done
rm -fr /tmp/.k8s_bin
sleep 1
mkdir /tmp/.k8s_bin
cp -afr _output/bin/* /tmp/.k8s_bin/
echo
echo ' build k8s bin done'
echo
exit
