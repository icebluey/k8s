#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ
umask 022

cd "$(dirname "$0")"

#https://dl.k8s.io/release/v1.31.1/bin/linux/amd64/kubeadm
#https://dl.k8s.io/release/v1.31.1/bin/linux/amd64/kubelet
#https://dl.k8s.io/release/v1.31.1/bin/linux/amd64/kubectl

_clean_start_docker() {
    systemctl daemon-reload > /dev/null 2>&1 || : 
    sleep 1
    systemctl stop docker.socket > /dev/null 2>&1 || : 
    systemctl stop docker.service > /dev/null 2>&1 || : 
    sleep 1
    systemctl stop containerd.service > /dev/null 2>&1 || : 
    sleep 1
    /bin/rm -fr /var/lib/docker/* /var/lib/containerd/* /mnt/docker-data/*
    ip link set docker0 down > /dev/null 2>&1 || : 
    ip link delete docker0 > /dev/null 2>&1 || : 
    systemctl start containerd.service
    sleep 1
    systemctl start docker.service
    sleep 1
}

_clean_docker() {
    systemctl daemon-reload > /dev/null 2>&1 || : 
    sleep 1
    systemctl stop docker.socket > /dev/null 2>&1 || : 
    systemctl stop docker.service > /dev/null 2>&1 || : 
    sleep 1
    systemctl stop containerd.service > /dev/null 2>&1 || : 
    sleep 1
    /bin/rm -fr /var/lib/docker/* /var/lib/containerd/* /mnt/docker-data/*
    ip link set docker0 down > /dev/null 2>&1 || : 
    ip link delete docker0 > /dev/null 2>&1 || : 
}
_clean_docker

set -e

if [[ -n "${1}" ]]; then
    rm -fr /tmp/kubeadm.bin
    wget -q -c -t 0 -T 9 -O /tmp/kubeadm.bin "https://dl.k8s.io/release/v${1}/bin/linux/amd64/kubeadm"
    sleep 1
    chmod 0755 /tmp/kubeadm.bin
    _k8s_ver="$(/tmp/kubeadm.bin config images list 2>/dev/null | grep -i 'kube-apiserver:' | awk -F : '{print $NF}' | sed 's/[Vv]//g')"
    /bin/rm -fr /tmp/kubeadm.bin
else
    _k8s_ver="$(wget -qO- "https://dl.k8s.io/release/stable.txt" | sed 's|^[Vv]||g')"
fi
echo
echo 'k8s version: '"${_k8s_ver}"
echo
###############################################################################
#
# Build my own binaries
#
#_clean_start_docker
#docker run --cpus="2.0" --hostname 'x86-040.build.eng.bos.redhat.com' --rm --name al8 -itd icebluey/almalinux:8 bash
#chmod 0755 build-k8s-bin.sh
#docker exec al8 yum clean all
#docker exec al8 yum makecache
#docker exec al8 /bin/bash -c 'rm -fr /tmp/*'
#docker cp build-k8s-bin.sh al8:/home/
#docker exec al8 /bin/bash /home/build-k8s-bin.sh "${_k8s_ver}"
#rm -fr /tmp/.k8s_bin
#docker cp al8:/tmp/.k8s_bin /tmp/
#sleep 10
#ls -la /tmp/.k8s_bin/
#_clean_docker
###############################################################################

_arch="amd64"

rm -fr /tmp/.k8s_bin
mkdir /tmp/.k8s_bin
cd /tmp/.k8s_bin

_files=(
'kubeadm'
'kubectl'
'kubelet'
'kube-proxy'
'kubectl-convert'
)
for file in ${_files[@]}; do
    wget -q -c -t 0 -T 9 "https://dl.k8s.io/release/v${_k8s_ver}/bin/linux/${_arch}/${file}"
    wget -q -c -t 0 -T 9 "https://dl.k8s.io/release/v${_k8s_ver}/bin/linux/${_arch}/${file}.sha256"
    echo "$(<${file}.sha256)  ${file}" | sha256sum --check
    chmod 0755 "${file}"
done
sleep 1
rm -f kube*.sha256
/bin/ls -lah
echo
echo
./kubeadm config images list
echo
echo

###############################################################################

_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"

_cni_plugins_ver="$(wget -qO- 'https://github.com/containernetworking/plugins/releases' | grep -i "cni-plugins-linux.*\.t" | grep -i 'href="/containernetworking/plugins/releases/download/' | sed 's|"|\n|g' | grep -i '^/containernetworking/plugins/releases/download/' | sed -e 's|.*/v||g' -e 's|/c.*||g' | sort -V | uniq | tail -n 1)"
wget -c -t 0 -T 9 "https://github.com/containernetworking/plugins/releases/download/v${_cni_plugins_ver}/cni-plugins-linux-${_arch}-v${_cni_plugins_ver}.tgz.sha256"
wget -c -t 0 -T 9 "https://github.com/containernetworking/plugins/releases/download/v${_cni_plugins_ver}/cni-plugins-linux-${_arch}-v${_cni_plugins_ver}.tgz"

_flannel_cni_plugin_ver="$(wget -qO- 'https://github.com/flannel-io/cni-plugin/releases' | grep -i 'href="/flannel-io/cni-plugin/tree/v[0-9]' | sed 's|"|\n|g' | grep '^/flannel-io/cni-plugin/tree/' | sed 's|.*/v||g' | sort -V | uniq | tail -n 1)"
wget -c -t 0 -T 9 "https://github.com/flannel-io/cni-plugin/releases/download/v${_flannel_cni_plugin_ver}/flannel-amd64"

_cri_tools_ver="$(wget -qO- 'https://github.com/kubernetes-sigs/cri-tools/releases' | grep -i 'crictl.*linux.*\.t' | grep -i 'href="/kubernetes-sigs/cri-tools/releases/download/' | sed 's|"|\n|g' | grep -i '^/kubernetes-sigs/cri-tools/releases/download/' | sed -e 's|.*/v||g' -e 's|/c.*||g' | sort -V | uniq | tail -n 1)"
wget -c -t 0 -T 9 "https://github.com/kubernetes-sigs/cri-tools/releases/download/v${_cri_tools_ver}/crictl-v${_cri_tools_ver}-linux-${_arch}.tar.gz.sha256"
wget -c -t 0 -T 9 "https://github.com/kubernetes-sigs/cri-tools/releases/download/v${_cri_tools_ver}/crictl-v${_cri_tools_ver}-linux-${_arch}.tar.gz"

_metallb_ver="$(wget -qO- 'https://github.com/metallb/metallb/tags' | grep -i 'href="/metallb/metallb/releases/tag/' | sed 's|"|\n|g' | grep -i '^/metallb/metallb/releases/tag/' | sed 's|.*/v||g' | grep -iv 'chart' | sort -V | uniq | tail -n 1)"
wget -c -t 0 -T 9 "https://github.com/metallb/metallb/archive/refs/tags/v${_metallb_ver}.tar.gz" -O metallb-${_metallb_ver}.tar.gz

# release-v${_calico_ver}.tgz contains images
_calico_ver="$(wget -qO- 'https://github.com/projectcalico/calico/releases' | grep -i 'release-.*\.tgz' | sed -e 's|release-|\nrelease-|g' -e 's|tgz|tgz\n|g' | grep -i '^release-.*\.tgz' | sed -e 's|release-v||g' -e 's|\.tgz||g' | grep -ivE 'alpha|beta|rc' | sort -V | uniq | tail -n 1)"
wget -c -t 0 -T 9 "https://github.com/projectcalico/calico/releases/download/v${_calico_ver}/release-v${_calico_ver}.tgz"

#_dashboard_tag="$(wget -qO- 'https://github.com/kubernetes/dashboard/tags' | grep -i 'href="/kubernetes/dashboard/archive/refs/tags/v[1-9].*\.tar\.gz' | sed 's|"|\n|g' | grep '^/kubernetes/dashboard/archive/refs/tags/.*\.tar\.gz' | sed -e 's|.*tags/||g' -e 's|\.tar.*||g' | sort -V | uniq | tail -n 1)"
#wget -c -t 0 -T 9 "https://raw.githubusercontent.com/kubernetes/dashboard/${_dashboard_tag}/aio/deploy/recommended.yaml" -O kube-dashboard.yaml
#_dashboard_url="$(wget -qO- 'https://github.com/kubernetes/dashboard/releases' | grep -i 'https://raw.githubusercontent.com/kubernetes/dashboard/v' | sed -e 's| |\n|g' -e 's|"|\n|g' | grep -i '^https://raw.githubusercontent.com/kubernetes/dashboard/v' | sed 's|\.yaml.*|.yaml|g' | grep -ivE 'alpha|beta|rc[0-9]' | sort -V | uniq | tail -n1)"
#wget -c -t 0 -T 9 "${_dashboard_url}" -O kube-dashboard.yaml

#_istio_ver="$(wget -qO- 'https://github.com/istio/istio/releases' | grep -i 'istio.*linux.*\.t' | grep -i 'href="/istio/istio/releases/download/' | sed 's|"|\n|g' | grep -i '^/istio/istio/releases/download/' | sed 's|/istio/istio/releases/download/||g' | sed 's|/.*||g' | grep -ivE 'alpha|beta|rc' | sort -V | uniq | tail -n 1)"
#wget -c -t 0 -T 9 "https://github.com/istio/istio/releases/download/${_istio_ver}/istio-${_istio_ver}-linux-${_arch}.tar.gz.sha256"
#wget -c -t 0 -T 9 "https://github.com/istio/istio/releases/download/${_istio_ver}/istio-${_istio_ver}-linux-${_arch}.tar.gz"

#wget -c -t 0 -T 9 "https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml" -O kube-flannel.yaml
#wget -c -t 0 -T 9 "https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml" -O ingress-nginx.yaml

sha256sum -c "cni-plugins-linux-${_arch}-v${_cni_plugins_ver}.tgz.sha256"
sleep 1
rm -f "cni-plugins-linux-${_arch}-v${_cni_plugins_ver}.tgz.sha256"
mkdir plugins.tmp
tar -xof "cni-plugins-linux-${_arch}-v${_cni_plugins_ver}.tgz" -C plugins.tmp/
sleep 1
rm -f "cni-plugins-linux-${_arch}-v${_cni_plugins_ver}.tgz"
ls -la plugins.tmp/portmap
rm -f plugins.tmp/LICENSE*
rm -f plugins.tmp/README*

rm -f plugins.tmp/flannel
chmod 0755 flannel-amd64
sleep 1
mv -f flannel-amd64 plugins.tmp/flannel

_helm_ver="$(wget -qO- 'https://github.com/helm/helm/releases' | grep -i 'helm/releases/tag/v[1-9]' | sed 's/"/\n/g' | grep -i 'helm/releases/tag/v[1-9]' | sed 's|.*/tag/v||g' | grep -iv -E 'alpha|beta|rc' | sort -V | tail -n 1)"
wget -c -t 9 -T 9 "https://get.helm.sh/helm-v${_helm_ver}-linux-amd64.tar.gz"
mkdir helm.tmp
tar -xof helm-*.tar* -C helm.tmp/
rm -f helm-*.tar*

#sha256sum -c "crictl-v${_cri_tools_ver}-linux-${_arch}.tar.gz.sha256"
echo "$(awk '{print $1}' "crictl-v${_cri_tools_ver}-linux-${_arch}.tar.gz.sha256")  crictl-v${_cri_tools_ver}-linux-${_arch}.tar.gz" | sha256sum -c -
sleep 1
rm -f "crictl-v${_cri_tools_ver}-linux-${_arch}.tar.gz.sha256"
tar -xof "crictl-v${_cri_tools_ver}-linux-${_arch}.tar.gz"
sleep 1
rm -f "crictl-v${_cri_tools_ver}-linux-${_arch}.tar.gz"

#sha256sum -c "istio-${_istio_ver}-linux-${_arch}.tar.gz.sha256"
#sleep 1
#rm -f "istio-${_istio_ver}-linux-${_arch}.tar.gz.sha256"
#rm -fr istioctl
#tar -xof "istio-${_istio_ver}-linux-${_arch}.tar.gz"
#sleep 1
#rm -f "istio-${_istio_ver}-linux-${_arch}.tar.gz"
#mv -f "istio-${_istio_ver}/bin/istioctl" ./
#sleep 1
#rm -fr "istio-${_istio_ver}/bin"

tar -xof "metallb-${_metallb_ver}.tar.gz"
sleep 1
rm -f "metallb-${_metallb_ver}.tar.gz"

mkdir /tmp/.calico.extr.tmp
tar -xof "release-v${_calico_ver}.tgz" -C /tmp/.calico.extr.tmp/
sleep 1
rm -f "release-v${_calico_ver}.tgz"
_calico_release_dir="$(find /tmp/.calico.extr.tmp/ -type f -iname 'calicoctl' -o -iname 'calicoctl-linux-amd64' | grep '/bin/calicoctl' | sed 's|/bin/.*||g' | sort | uniq | tail -n 1)"
mv -v -f "${_calico_release_dir}" "calico-${_calico_ver}"
sleep 1
chown -R root:root "calico-${_calico_ver}"
find "calico-${_calico_ver}"/ -type d | xargs --no-run-if-empty -I '{}' chmod 0755 '{}'
find "calico-${_calico_ver}"/bin/ -type f -iname 'calicoctl' -o -iname 'calicoctl-linux-*' -o -iname 'calico-bpf' | grep -v '/bin/cni/' | xargs --no-run-if-empty -I '{}' chmod 0755 '{}'
chmod 0644 "calico-${_calico_ver}"/images/*tar*
rm -f "calico-${_calico_ver}"/bin/*darwin*
rm -f "calico-${_calico_ver}"/bin/*windows*
rm -f "calico-${_calico_ver}"/bin/*.exe
rm -f "calico-${_calico_ver}"/bin/calicoctl/calicoctl-*{arm64,armv7,ppc64,s390x,darwin,windows}*
rm -fr "calico-${_calico_ver}"/bin/cni/*{arm64,armv7,ppc64,s390x,darwin,windows}*
rm -fr /tmp/.calico.extr.tmp
_calico_release_dir=''
ls -1 "calico-${_calico_ver}"/images/*.tar | xargs -I '{}' gzip -f -9 '{}'
find "calico-${_calico_ver}"/bin/ -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | grep -iv '/calico-bpf' | xargs --no-run-if-empty -I '{}' strip '{}'
sleep 1

if [ -f /.calico.images.done.txt ]; then
    rm -fr "calico-${_calico_ver}"/images
else
    mv -f "calico-${_calico_ver}"/images "calico-${_calico_ver}"-images
    sleep 1
    tar -zcvf /tmp/"calico-${_calico_ver}"-images.tar.gz "calico-${_calico_ver}"-images
    sleep 2
    rm -fr "calico-${_calico_ver}"-images
    echo 1 > /.calico.images.done.txt
fi

#_release_ver="$(wget -qO- 'https://github.com/kubernetes/release/tags' | grep -i 'href="/kubernetes/release/releases/tag/' | sed 's|"|\n|g' | grep -i '^/kubernetes/release/releases/tag' | sed 's|.*/v||g' | sort -V | uniq | tail -n 1)"
#wget -c -t 0 -T 9 "https://raw.githubusercontent.com/kubernetes/release/v${_release_ver}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service"
#wget -c -t 0 -T 9 "https://raw.githubusercontent.com/kubernetes/release/v${_release_ver}/cmd/kubepkg/templates/latest/rpm/kubeadm/10-kubeadm.conf"

wget -c -t 0 -T 9 'https://raw.githubusercontent.com/icebluey/k8s/refs/heads/master/templates/10-kubeadm.conf'
wget -c -t 0 -T 9 'https://raw.githubusercontent.com/icebluey/k8s/refs/heads/master/templates/kubelet.service'

rm -fr /tmp/kubernetes
sleep 1
install -m 0755 -d /tmp/kubernetes/usr/bin
install -m 0755 -d /tmp/kubernetes/usr/share/kubernetes/cni-plugins
#install -m 0755 -d /tmp/kubernetes/usr/share/kubernetes/images
#install -m 0755 -d /tmp/kubernetes/etc/sysconfig
#install -m 0755 -d /tmp/kubernetes/etc/systemd/system/kubelet.service.d
#install -m 0755 -d /tmp/kubernetes/etc/kubernetes/manifests
#install -m 0755 -d /tmp/kubernetes/etc/kubernetes/pki/etcd

#for file in ${_files[@]}; do
#    install -v -c -m 0755 ${file} /tmp/kubernetes/usr/bin/
#done

install -v -c -m 0755 /tmp/.k8s_bin/* /tmp/kubernetes/usr/bin/
sleep 2
rm -fr /tmp/.k8s_bin

install -v -c -m 0755 helm.tmp/linux-amd64/helm /tmp/kubernetes/usr/bin/
install -v -c -m 0755 crictl /tmp/kubernetes/usr/bin/
install -v -c -m 0644 10-kubeadm.conf /tmp/kubernetes/usr/share/kubernetes/10-kubeadm.conf.example
install -v -c -m 0644 kubelet.service /tmp/kubernetes/usr/share/kubernetes/
install -v -c -m 0755 plugins.tmp/* /tmp/kubernetes/usr/share/kubernetes/cni-plugins/

#install -v -c -m 0644 kube-flannel.yaml /tmp/kubernetes/usr/share/kubernetes/
#install -v -c -m 0644 kube-dashboard.yaml /tmp/kubernetes/usr/share/kubernetes/
#install -v -c -m 0644 ingress-nginx.yaml /tmp/kubernetes/usr/share/kubernetes/
#install -v -c -m 0755 istioctl /tmp/kubernetes/usr/bin/
#cp -pfr "istio-${_istio_ver}" /tmp/kubernetes/usr/share/kubernetes/

cp -pfr "metallb-${_metallb_ver}" /tmp/kubernetes/usr/share/kubernetes/

if [[ -f "calico-${_calico_ver}"/bin/calicoctl/calicoctl-linux-amd64 ]]; then
    install -v -c -m 0755 "calico-${_calico_ver}"/bin/calicoctl/calicoctl-linux-amd64 /tmp/kubernetes/usr/bin/calicoctl
elif [[ -f "calico-${_calico_ver}"/bin/calicoctl ]]; then
    install -v -c -m 0755 "calico-${_calico_ver}"/bin/calicoctl /tmp/kubernetes/usr/bin/calicoctl
fi
if [[ -f "calico-${_calico_ver}"/bin/calico-bpf ]]; then
    install -v -c -m 0755 "calico-${_calico_ver}"/bin/calico-bpf /tmp/kubernetes/usr/bin/
fi
cp -pfr "calico-${_calico_ver}" /tmp/kubernetes/usr/share/kubernetes/

# jq
rm -fr /tmp/jq
wget -q -c "https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64" -O /tmp/jq
chmod 0755 /tmp/jq
strip /tmp/jq
install -m 0755 -d /tmp/kubernetes/usr/share/kubernetes/jq
sleep 1
mv -f /tmp/jq /tmp/kubernetes/usr/share/kubernetes/jq/jq

###############################################################################

cd /tmp/kubernetes

#echo '
#kubectl create secret generic memberlist -n metallb-system --from-literal=secretkey="$(openssl rand -base64 256)"
#' > usr/share/kubernetes/metallb-${_metallb_ver}/manifests/create-secret.sh
#sleep 1
#chmod 0755 usr/share/kubernetes/metallb-${_metallb_ver}/manifests/create-secret.sh

sed '/^After=/s|[ \t]*docker.service||g' -i usr/share/kubernetes/kubelet.service
sed '/^After=/s|docker.service||g' -i usr/share/kubernetes/kubelet.service
sed -e '/^After=$/d' -i usr/share/kubernetes/kubelet.service
#sed '/^After=/aAfter=containerd.service docker.service' -i usr/share/kubernetes/kubelet.service
sed '/^After=/aAfter=containerd.service' -i usr/share/kubernetes/kubelet.service

find usr/bin/ -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' strip '{}'
find usr/share/kubernetes/cni-plugins/ -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' strip '{}'
sleep 2

if [[ "$(./usr/bin/kubeadm config images list 2>&1 | grep -iE 'k8s\.gcr|k8s\.io' | wc -l)" != "$(./usr/bin/kubeadm config images list 2>/dev/null | wc -l)" ]]; then
    echo -e '# See more info, run:\n./kubeadm config images list'
    echo
    ./usr/bin/kubeadm config images list 2>&1
    echo
    #exit 1
fi

# save images

#_images=''
#_images=($(cat usr/share/kubernetes/kube-dashboard.yaml | grep -i 'image: ' | awk '{print $2}' | sed 's|@sha.*||g' | sort -V | uniq))
###############################################################################
#_clean_start_docker
#for image in ${_images[@]}; do
#    docker pull "$(echo ${image} | sed "s|^'||g" | sed "s|'$||g")"
#    sleep 2
#done
#echo
#sleep 2
#docker images -a
#echo
#sleep 2
#docker image save -o usr/share/kubernetes/images/kube-dashboard.tar ${_images[@]}
#sleep 2
#chmod 0644 usr/share/kubernetes/images/kube-dashboard.tar
#sleep 2
#gzip -f -9 usr/share/kubernetes/images/kube-dashboard.tar
#sleep 2
###############################################################################

#_images=''
#_images=($(./usr/bin/kubeadm config images list 2>/dev/null) $(cat usr/share/kubernetes/kube-dashboard.yaml | grep -i 'image: ' | awk '{print $2}' | sed 's|@sha.*||g' | sort -V | uniq))
################################################################################
#_clean_start_docker
#for image in ${_images[@]}; do
#    docker pull "$(echo ${image} | sed "s|^'||g" | sed "s|'$||g")"
#    sleep 2
#done
#echo
#sleep 2
#docker images -a
#echo
#sleep 2
#docker image save -o usr/share/kubernetes/images/k8s.tar ${_images[@]}
#sleep 2
#chmod 0644 usr/share/kubernetes/images/k8s.tar
#sleep 2
#gzip -f -9 usr/share/kubernetes/images/k8s.tar
#sleep 2
###############################################################################

#_images=''
#_images=($(cat usr/share/kubernetes/kube-flannel.yaml | grep -i 'image: ' | awk '{print $2}' | sed 's|@sha.*||g' | sort -V | uniq))
###############################################################################
#_clean_start_docker
#for image in ${_images[@]}; do
#    docker pull "$(echo ${image} | sed "s|^'||g" | sed "s|'$||g")"
#    sleep 2
#done
#echo
#sleep 2
#docker images -a
#echo
#sleep 2
#docker image save -o usr/share/kubernetes/images/flannel.tar ${_images[@]}
#sleep 2
#chmod 0644 usr/share/kubernetes/images/flannel.tar
#sleep 2
#gzip -f -9 usr/share/kubernetes/images/flannel.tar
#sleep 2
###############################################################################

#_images=''
###############################################################################
#_clean_start_docker
#_traefik_ver="$(wget -qO- 'https://github.com/traefik/traefik/releases' | grep -i 'href="/traefik/traefik/releases/download/' | sed 's|"|\n|g' | grep -i '^/traefik/traefik/releases/download/' | sed -e 's|.*/v||g' -e 's|/traefik.*||g' | grep -ivE 'alpha|beta|rc' | sort -V | uniq | tail -n 1)"
#docker pull "traefik:v${_traefik_ver}"
#sleep 2
#docker image save -o usr/share/kubernetes/images/"traefik-${_traefik_ver}".tar "traefik:v${_traefik_ver}"
#sleep 2
#chmod 0644 usr/share/kubernetes/images/"traefik-${_traefik_ver}".tar
#sleep 2
#gzip -f -9 usr/share/kubernetes/images/"traefik-${_traefik_ver}".tar
#sleep 2
###############################################################################

#_images=''
#_images=($(cat usr/share/kubernetes/ingress-nginx.yaml | grep -i 'image: ' | awk '{print $2}' | sed 's|@sha.*||g' | sort -V | uniq))
###############################################################################
#_clean_start_docker
#for image in ${_images[@]}; do
#    docker pull "$(echo ${image} | sed "s|^'||g" | sed "s|'$||g")"
#    sleep 2
#done
#echo
#sleep 2
#docker image save -o usr/share/kubernetes/images/ingress-nginx.tar ${_images[@]}
#sleep 2
#chmod 0644 usr/share/kubernetes/images/ingress-nginx.tar
#sleep 2
#gzip -f -9 usr/share/kubernetes/images/ingress-nginx.tar
#sleep 2
###############################################################################

_images=''
_images=($(./usr/bin/kubeadm config images list 2>/dev/null))
###############################################################################
install -m 0755 -d .k8s.images.tmp
for image in ${_images[@]}; do
    _clean_start_docker
    sleep 5
    _name="$(echo ${image} | awk -F/ '{print $NF}' | awk -F: '{print $1}')"
    _ver="$(echo ${image} | awk -F/ '{print $NF}' | awk -F: '{print $2}' | sed 's|^[Vv]||g')"
    docker pull "$(echo ${image} | sed "s|^'||g" | sed "s|'$||g")"
    sleep 2
    docker images -a
    sleep 2
    docker image save -o .k8s.images.tmp/"${_name}_${_ver}.tar" "$(echo ${image} | sed "s|^'||g" | sed "s|'$||g")"
    sleep 2
    _name=''
    _ver=''
done
chmod 0644 .k8s.images.tmp/*.tar
sleep 1
/bin/ls -1 .k8s.images.tmp/*.tar | xargs --no-run-if-empty -I '{}' gzip -f -9 '{}'
sleep 2
mv -f .k8s.images.tmp k8s-"${_k8s_ver}"-images
sleep 1
tar -zcvf /tmp/k8s-"${_k8s_ver}"-images.tar.gz k8s-"${_k8s_ver}"-images
sleep 2
/bin/rm -fr k8s-"${_k8s_ver}"-images
###############################################################################

###############################################################################
if [ ! -f /.metallb.images.done.txt ]; then
    _images=''
    _images=($(cat usr/share/kubernetes/"metallb-${_metallb_ver}"/config/manifests/metallb-frr.yaml usr/share/kubernetes/"metallb-${_metallb_ver}"/config/manifests/metallb-native.yaml | grep -i 'image: ' | awk '{print $2}' | sed 's|@sha.*||g' | sort -V | uniq))
    _clean_start_docker
    install -m 0755 -d .metallb.images.tmp
    for image in ${_images[@]}; do
        _clean_start_docker
        sleep 5
        _name="$(echo ${image} | awk -F/ '{print $NF}' | awk -F: '{print $1}')"
        _ver="$(echo ${image} | awk -F/ '{print $NF}' | awk -F: '{print $2}' | sed 's|^[Vv]||g')"
        docker pull "$(echo ${image} | sed "s|^'||g" | sed "s|'$||g")"
        sleep 2
        docker images -a
        sleep 2
        docker image save -o .metallb.images.tmp/"${_name}_${_ver}.tar" "$(echo ${image} | sed "s|^'||g" | sed "s|'$||g")"
        sleep 2
        _name=''
        _ver=''
    done
    chmod 0644 .metallb.images.tmp/*.tar
    sleep 1
    /bin/ls -1 .metallb.images.tmp/*.tar | xargs --no-run-if-empty -I '{}' gzip -f -9 '{}'
    sleep 2
    mv -f .metallb.images.tmp "metallb-${_metallb_ver}"-images
    sleep 1
    tar -zcvf /tmp/"metallb-${_metallb_ver}"-images.tar.gz "metallb-${_metallb_ver}"-images
    sleep 2
    /bin/rm -fr "metallb-${_metallb_ver}"-images
    echo 1 > /.metallb.images.done.txt
fi
###############################################################################

#_images=''
###############################################################################
#_clean_start_docker
#docker pull istio/pilot:${_istio_ver}
#sleep 2
#docker pull istio/proxyv2:${_istio_ver}
#echo
#sleep 2
#docker image save -o /tmp/"istio-${_istio_ver}".tar istio/pilot:${_istio_ver} istio/proxyv2:${_istio_ver}
#sleep 2
#chmod 0644 /tmp/"istio-${_istio_ver}".tar
#sleep 2
#gzip -f -9 /tmp/"istio-${_istio_ver}".tar
###############################################################################

_images=''
_clean_docker

echo 'runtime-endpoint: "unix:///run/containerd/containerd.sock"' > usr/share/kubernetes/crictl.yaml.example
sleep 1
chmod 0644 usr/share/kubernetes/crictl.yaml.example

echo 'KUBELET_EXTRA_ARGS="--resolv-conf=/etc/kubernetes/coredns-resolv.conf"' > usr/share/kubernetes/kubelet.sysconfig
sleep 1
chmod 0644 usr/share/kubernetes/kubelet.sysconfig

./usr/bin/kubeadm config print init-defaults | sed "s|kubernetesVersion: .*|kubernetesVersion: ${_k8s_ver}|g" > usr/share/kubernetes/example-kubeadm-config.yaml
sed 's| criSocket: .*| criSocket: unix:///run/containerd/containerd.sock|g' -i usr/share/kubernetes/example-kubeadm-config.yaml
sed "/ serviceSubnet:/i \  podSubnet: 172.16.0.0/12" -i usr/share/kubernetes/example-kubeadm-config.yaml
sed '/ timeoutForControlPlane: /i \  extraArgs: \n\    service-node-port-range: 20000-39999' -i usr/share/kubernetes/example-kubeadm-config.yaml
sed '/^controllerManager:/icontrolPlaneEndpoint: "lb_ip:port"' -i usr/share/kubernetes/example-kubeadm-config.yaml
sed 's| advertiseAddress: .*| advertiseAddress: node_ip|g' -i usr/share/kubernetes/example-kubeadm-config.yaml
sed 's|  name: node|  name: "node_name"|g' -i usr/share/kubernetes/example-kubeadm-config.yaml

sed 's|caCertificateValidityPeriod:.*|caCertificateValidityPeriod: 876000h0m0s|g' -i usr/share/kubernetes/example-kubeadm-config.yaml
sed 's|certificateValidityPeriod:.*|certificateValidityPeriod: 876000h0m0s|g' -i usr/share/kubernetes/example-kubeadm-config.yaml
sed 's|encryptionAlgorithm:.*|encryptionAlgorithm: RSA-4096|g' -i usr/share/kubernetes/example-kubeadm-config.yaml

echo '---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
ipvs:
  strictARP: true' >> usr/share/kubernetes/example-kubeadm-config.yaml
sleep 1
chmod 0644 usr/share/kubernetes/example-kubeadm-config.yaml

echo '
cd "$(dirname "$0")"
/bin/systemctl daemon-reload >/dev/null 2>&1 || : 
rm -f /lib/systemd/system/kubelet.service
sleep 1
install -v -c -m 0644 kubelet.service /lib/systemd/system/
echo "nf_conntrack
br_netfilter
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_lc
ip_vs_wlc
ip_vs_lblc
ip_vs_lblcr
ip_vs_sh
ip_vs_dh
ip_vs_sed
ip_vs_nq
ip_vs_mh" > /etc/modules-load.d/k8s.conf
sleep 1
chmod 0644 /etc/modules-load.d/k8s.conf

echo "net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-arptables = 1
fs.file-max = 6553600
vm.max_map_count = 655360
net.core.somaxconn = 32768
net.netfilter.nf_conntrack_max = 1000000
net.ipv4.ip_local_port_range = 40000 65500
net.ipv4.ip_forward = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 10" > /etc/sysctl.d/999-k8s.conf
sleep 1
chmod 0644 /etc/sysctl.d/999-k8s.conf

[ -d /etc/kubernetes/manifests ] || install -m 0755 -d /etc/kubernetes/manifests && chown root:root /etc/kubernetes/manifests
[ -d /etc/kubernetes/pki/etcd ] || install -m 0755 -d /etc/kubernetes/pki/etcd && chown root:root /etc/kubernetes/pki/etcd
[ -d /var/lib/etcd ] || install -m 0700 -d /var/lib/etcd && chown root:root /var/lib/etcd
[ -d /var/lib/kubelet ] || install -m 0700 -d /var/lib/kubelet && chown root:root /var/lib/kubelet
[ -d /etc/cni/net.d ] || install -m 0700 -d /etc/cni/net.d && chown root:root /etc/cni/net.d

[ -f /etc/kubernetes/coredns-resolv.conf ] || echo "nameserver 8.8.8.8" > /etc/kubernetes/coredns-resolv.conf
[ -f /etc/crictl.yaml ] || install -m 0644 crictl.yaml.example /etc/crictl.yaml
[ -f /etc/sysconfig/kubelet ] || install -m 0644 kubelet.sysconfig /etc/sysconfig/kubelet
[ -d /etc/systemd/system/kubelet.service.d ] || install -m 0755 -d /etc/systemd/system/kubelet.service.d
[ -f /etc/systemd/system/kubelet.service.d/10-kubeadm.conf ] || install -m 0644 10-kubeadm.conf.example /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

install -m 0755 -d /opt/cni/bin
install -m 0755 cni-plugins/* /opt/cni/bin/
[ -f /usr/bin/jq ] || install -m 0755 jq/jq /usr/bin/

/sbin/sysctl --system >/dev/null 2>&1 || : 
/bin/systemctl daemon-reload >/dev/null 2>&1 || : 
' > usr/share/kubernetes/.install.txt

echo '
cd "$(dirname "$0")"
/bin/systemctl daemon-reload >/dev/null 2>&1 || : 
sleep 1
/bin/systemctl start containerd.service >/dev/null 2>&1 || : 
sleep 2
if ! ctr namespaces list | sed "1d" | grep -q -i "k8s\.io"; then ctr namespaces create "k8s.io"; fi
sleep 1
/bin/ls -1 *.tar.gz 2>/dev/null | xargs --no-run-if-empty -I {} bash -c "gzip -c -d {} | ctr --namespace k8s.io images import -"
/bin/ls -1 *.tar 2>/dev/null | xargs --no-run-if-empty -I "{}" ctr --namespace "k8s.io" images import "{}"
echo
sleep 1
ctr --namespace "k8s.io" images ls -q | grep -iv "^sha256:"
echo
sleep 1
crictl -r unix:///run/containerd/containerd.sock images
' > usr/share/kubernetes/load-images.sh
sleep 1
chmod 0755 usr/share/kubernetes/load-images.sh

echo '## Install the dependencies
#### RHEL 8/9
```
yum install -y binutils util-linux findutils socat ethtool iptables ebtables ipvsadm ipset psmisc bash-completion conntrack-tools iproute nfs-utils 
```
#### RHEL 7 / CentOS 7
```
yum install -y binutils coreutils util-linux findutils socat ethtool iptables ebtables ipvsadm ipset psmisc bash-completion conntrack-tools iproute nfs-utils 
```
#### Debian / Ubuntu 20.04
```
apt install -y binutils coreutils util-linux socat ethtool iptables ebtables ipvsadm ipset psmisc bash-completion conntrack iproute2 nfs-common 
```

# example-kubeadm-config.yaml
kubeadm config print init-defaults

# Initialize a Kubernetes control-plane node
## using config yaml file
kubeadm init --config kubeadm-config.yaml
## using command line
kubeadm init --cri-socket /run/containerd/containerd.sock --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=node_ip

#echo '\''export CONTAINER_RUNTIME_ENDPOINT="unix:///run/containerd/containerd.sock"'\'' >> /etc/profile
#or create /etc/crictl.yaml
echo '\''runtime-endpoint: "unix:///run/containerd/containerd.sock"'\'' > /etc/crictl.yaml

# /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# vi /etc/sysconfig/kubelet
# --image-gc-high-threshold=98 --image-gc-low-threshold=96 --minimum-image-ttl-duration=2400h --eviction-hard=nodefs.available<5% --eviction-hard=imagefs.available<5%

# Deploy pods in master node
kubectl taint nodes --all node-role.kubernetes.io/master:NoSchedule-

# Manually change default service-node-port-range
# Add --service-node-port-range=20000-39999 to /etc/kubernetes/manifests/kube-apiserver.yaml

# Manually change proxy mode
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_lc
modprobe -- ip_vs_wlc
modprobe -- ip_vs_lblc
modprobe -- ip_vs_lblcr
modprobe -- ip_vs_sh
modprobe -- ip_vs_dh
modprobe -- ip_vs_sed
modprobe -- ip_vs_nq
modprobe -- ip_vs_mh
modprobe -- nf_conntrack
#modprobe -- nf_conntrack_ipv4

kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e '\''s/mode: ""/mode: "ipvs"/'\'' | \
kubectl apply -f - -n kube-system

kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e '\''s/strictARP: false/strictARP: true/'\'' | \
kubectl apply -f - -n kube-system

# CNI
# Deploy Calico
# <= 50 nodes
wget https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml
kubectl apply -f calico.yaml
# > 50 nodes
wget https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico-typha.yaml
kubectl apply -f calico-typha.yaml

# MetalLB
# Create namespace metallb-system first
kubectl create secret generic memberlist -n metallb-system --from-literal=secretkey="$(openssl rand -base64 256)"

' > usr/share/kubernetes/README.md

sleep 2
chown -R root:root /tmp/kubernetes
echo
sleep 2
tar --format=gnu -cvf - * | xz --threads=2 -f -z -9 > /tmp/"k8s-${_k8s_ver}-1_amd64.tar.xz"
echo
sleep 2
cd /tmp
openssl dgst -r -sha256 "k8s-${_k8s_ver}-1_amd64.tar.xz" > "k8s-${_k8s_ver}-1_amd64.tar.xz".sha256
sleep 2

cd /tmp
rm -fr "${_tmp_dir}"
rm -fr /tmp/kubernetes
sleep 2
echo
echo " package k8s ${_k8s_ver} done"
echo
_clean_docker
sha256sum *.tar.{gz,bz2,xz} 2>/dev/null || true 
exit
