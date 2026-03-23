#!/usr/bin/env bash
set -euo pipefail
ADVERTISE_IP="${ADVERTISE_IP:-$(hostname -I | awk '{print $1}')}"
POD_CIDR="${POD_CIDR:-10.244.0.0/16}"
sudo kubeadm init --apiserver-advertise-address="${ADVERTISE_IP}" --control-plane-endpoint="${ADVERTISE_IP}:6443" --pod-network-cidr="${POD_CIDR}"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/calico.yaml
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true
