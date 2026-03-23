#!/usr/bin/env bash
set -euo pipefail
CONTROL_PLANE_ENDPOINT="${CONTROL_PLANE_ENDPOINT:-10.100.0.1}"
POD_CIDR="${POD_CIDR:-10.244.0.0/16}"
sudo kubeadm init --apiserver-advertise-address="${CONTROL_PLANE_ENDPOINT}" --control-plane-endpoint="${CONTROL_PLANE_ENDPOINT}:6443" --pod-network-cidr="${POD_CIDR}"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/calico.yaml
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true
echo "Cluster Madrid inicializado"
echo "Ejecuta: kubeadm token create --print-join-command"
