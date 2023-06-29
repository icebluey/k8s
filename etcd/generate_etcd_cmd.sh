#!/bin/bash

if [ $# -lt 1 ]; then
  echo "Usage: $0 <node1> [<node2> <node3> ...]"
  exit 1
fi

# Read the node arguments into an array
node=("$@")

# Generate output for each node
for ((i=0; i<${#node[@]}; i++)); do
  initial_cluster=""
  for ((j=0; j<${#node[@]}; j++)); do
    if [ $j -gt 0 ]; then
      initial_cluster+=","
    fi
    initial_cluster+="${node[$j]%=*}=https://${node[$j]#*=}:2380"
  done

  echo "# node ${node[$i]%=*}"
  echo "etcd \\"
  echo "--initial-cluster=${initial_cluster} \\"
  echo "--initial-advertise-peer-urls=https://${node[$i]#*=}:2380 \\"
  echo "--advertise-client-urls=https://${node[$i]#*=}:2379 \\"
  echo "--listen-client-urls=https://127.0.0.1:2379,https://${node[$i]#*=}:2379 \\"
  echo "--listen-peer-urls=https://${node[$i]#*=}:2380 \\"
  echo "--listen-metrics-urls=http://127.0.0.1:2381 \\"
  echo "--name=${node[$i]%=*} \\"
  echo "--peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt \\"
  echo "--peer-key-file=/etc/kubernetes/pki/etcd/peer.key \\"
  echo "--peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt \\"
  echo "--peer-client-cert-auth=true \\"
  echo "--cert-file=/etc/kubernetes/pki/etcd/server.crt \\"
  echo "--key-file=/etc/kubernetes/pki/etcd/server.key \\"
  echo "--trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt \\"
  echo "--client-cert-auth=true \\"
  echo "--data-dir=/var/lib/etcd \\"
  echo "--snapshot-count=10000 \\"
  echo "--experimental-initial-corrupt-check=true \\"
  echo "--experimental-watch-progress-notify-interval=5s"
  echo
done
exit
