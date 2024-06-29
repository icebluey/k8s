## Install the dependencies
#### RHEL 8
```
yum install -y binutils util-linux findutils socat ethtool iptables ebtables ipvsadm ipset psmisc bash-completion conntrack-tools iproute nfs-utils 
```
#### RHEL 7 / CentOS 7
```
yum install -y binutils coreutils util-linux findutils socat ethtool iptables ebtables ipvsadm ipset psmisc bash-completion conntrack-tools iproute nfs-utils 
```
#### Debian / Ubuntu 20.04+
```
apt install -y binutils coreutils util-linux socat ethtool iptables ebtables ipvsadm ipset psmisc bash-completion conntrack iproute2 nfs-common 
```

## Settings for the kubelet
#### /etc/sysconfig/kubelet
```
KUBELET_EXTRA_ARGS="--resolv-conf=/etc/kubernetes/coredns-resolv.conf"
```
#### /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
```
# Note: This dropin only works with kubeadm and kubelet v1.11+
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
# This is a file that "kubeadm init" and "kubeadm join" generates at runtime, populating the KUBELET_KUBEADM_ARGS variable dynamically
EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env
# This is a file that the user can use for overrides of the kubelet args as a last resort. Preferably, the user should use
# the .NodeRegistration.KubeletExtraArgs object in the configuration files instead. KUBELET_EXTRA_ARGS should be sourced from this file.
EnvironmentFile=-/etc/sysconfig/kubelet
ExecStart=
ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS
```

## Settings for the kubelet kubeadm
#### kubeadm-config.yaml
```
apiVersion: kubeadm.k8s.io/v1beta3
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: node_real_ip
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///run/containerd/containerd.sock
  imagePullPolicy: IfNotPresent
  name: "node_name"
  taints: null
---
apiServer:
  extraArgs: 
    service-node-port-range: 20000-39999
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta3
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controlPlaneEndpoint: "keepalived_virtual_ipaddress(lb):port"
controllerManager: {}
dns: {}
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.k8s.io
kind: ClusterConfiguration
kubernetesVersion: 1.30.2
networking:
  dnsDomain: cluster.local
  podSubnet: 172.16.0.0/12
  serviceSubnet: 10.96.0.0/12
scheduler: {}
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
ipvs:
  strictARP: true
```
#### Initialize a Kubernetes control-plane node
```
kubeadm init --config kubeadm-config.yaml
```

#### Pull images using Containerd
```
ctr namespaces list
ctr namespaces create "k8s.io"

# https://hub.docker.com/_/nginx
ctr --namespace "k8s.io" images pull docker.io/library/nginx:1.23.3

# https://hub.docker.com/r/istio/proxyv2
ctr --namespace "k8s.io" images pull docker.io/istio/proxyv2:latest

# registry.k8s.io/pause:3.9
# ctr --namespace "k8s.io" images pull registry.k8s.io/pause:3.9
```
#### List images
```
ctr images ls
ctr --namespace "k8s.io" images ls -q | grep -iv "^sha[125]"

crictl images
crictl -r unix:///run/containerd/containerd.sock images
```
#### Copy the CA (Certificate Authority) and SA (Service Account) files to other master nodes (192.168.10.102 , 192.168.10.103)
```
USER=root
CONTROL_PLANE_IPS="192.168.10.102 192.168.10.103"
for host in ${CONTROL_PLANE_IPS}; do
    scp /etc/kubernetes/pki/ca.crt "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/ca.key "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/sa.key "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/sa.pub "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/front-proxy-ca.crt "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/front-proxy-ca.key "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/etcd/ca.crt "${USER}"@$host:/etc/kubernetes/pki/etcd/ca.crt
    # Skip the next line if you are using external etcd
    scp /etc/kubernetes/pki/etcd/ca.key "${USER}"@$host:/etc/kubernetes/pki/etcd/ca.key
done
```
