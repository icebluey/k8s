#!/bin/bash

if [ $# -lt 1 ]; then
  echo "Usage: $0 <node1> [<node2> <node3> ...]"
  exit 1
fi

nodes=("$@")

# Generate output for each node
for ((i=0; i<${#nodes[@]}; i++)); do
  initial_cluster=""
  for ((j=0; j<${#nodes[@]}; j++)); do
    if [ $j -gt 0 ]; then
      initial_cluster+=","
    fi
    initial_cluster+="${nodes[$j]%=*}=https://${nodes[$j]#*=}:2380"
  done

  echo "initial-cluster: '${initial_cluster}'" > "etcd$((i+1)).conf"
  echo "initial-advertise-peer-urls: 'https://${nodes[$i]#*=}:2380'" >> "etcd$((i+1)).conf"
  echo "advertise-client-urls: 'https://${nodes[$i]#*=}:2379'" >> "etcd$((i+1)).conf"
  echo "listen-client-urls: 'https://127.0.0.1:2379,https://${nodes[$i]#*=}:2379'" >> "etcd$((i+1)).conf"
  echo "listen-peer-urls: 'https://${nodes[$i]#*=}:2380'" >> "etcd$((i+1)).conf"
  echo "listen-metrics-urls: 'http://127.0.0.1:2381'" >> "etcd$((i+1)).conf"
  echo "name: '${nodes[$i]%=*}'" >> "etcd$((i+1)).conf"
  echo "peer-transport-security:" >> "etcd$((i+1)).conf"
  echo "  cert-file: '/etc/kubernetes/pki/etcd/peer.crt'" >> "etcd$((i+1)).conf"
  echo "  key-file: '/etc/kubernetes/pki/etcd/peer.key'" >> "etcd$((i+1)).conf"
  echo "  trusted-ca-file: '/etc/kubernetes/pki/etcd/ca.crt'" >> "etcd$((i+1)).conf"
  echo "  client-cert-auth: true" >> "etcd$((i+1)).conf"
  echo "client-transport-security:" >> "etcd$((i+1)).conf"
  echo "  cert-file: '/etc/kubernetes/pki/etcd/server.crt'" >> "etcd$((i+1)).conf"
  echo "  key-file: '/etc/kubernetes/pki/etcd/server.key'" >> "etcd$((i+1)).conf"
  echo "  trusted-ca-file: '/etc/kubernetes/pki/etcd/ca.crt'" >> "etcd$((i+1)).conf"
  echo "  client-cert-auth: true" >> "etcd$((i+1)).conf"
  echo "data-dir: '/var/lib/etcd'" >> "etcd$((i+1)).conf"
  echo "#initial-cluster-token: 'etcd-cluster'" >> "etcd$((i+1)).conf"
  echo "#initial-cluster-state: 'existing'" >> "etcd$((i+1)).conf"
  echo "#initial-cluster-state: 'new'" >> "etcd$((i+1)).conf"
  echo "snapshot-count: 10000" >> "etcd$((i+1)).conf"
  echo "experimental-initial-corrupt-check: true" >> "etcd$((i+1)).conf"
  echo "#experimental-watch-progress-notify-interval: '5s'" >> "etcd$((i+1)).conf"
done
exit
