# Instalación detallada

## Arquitectura
- Madrid: `madrid-cp-01` (control-plane + worker) y `madrid-wk-01` (worker)
- Frankfurt: `fra-cp-01` (control-plane + worker)
- Rancher: en homelab

## 1) Terraform
En cada carpeta `terraform/*`:
```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
terraform init
terraform apply
```

## 2) WireGuard en Madrid
```bash
chmod +x scripts/generate-wireguard-configs.sh
CP_PUBLIC_IP=<IP_PUBLICA_CP> WK_PUBLIC_IP=<IP_PUBLICA_WORKER> ./scripts/generate-wireguard-configs.sh
```
Copia:
- `output/madrid-cp-01-wg0.conf` al control-plane
- `output/madrid-wk-01-wg0.conf` al worker

En cada nodo:
```bash
chmod +x scripts/install-wireguard-peer.sh
./scripts/install-wireguard-peer.sh /ruta/al/wg0.conf
```
Valida:
```bash
ping 10.100.0.2
ping 10.100.0.1
```

## 3) Cluster Madrid
En `madrid-cp-01`:
```bash
chmod +x kubeadm/init-madrid-control-plane.sh
CONTROL_PLANE_ENDPOINT=10.100.0.1 bash kubeadm/init-madrid-control-plane.sh
kubeadm token create --print-join-command
```
En `madrid-wk-01`:
```bash
chmod +x kubeadm/join-madrid-worker.sh
bash kubeadm/join-madrid-worker.sh
```

## 4) Cluster Frankfurt
En `fra-cp-01`:
```bash
chmod +x kubeadm/init-frankfurt-single-node.sh
bash kubeadm/init-frankfurt-single-node.sh
```

## 5) local-path
En ambos clusters:
```bash
kubectl apply -f manifests/local-path/local-path-deploy.yaml
kubectl apply -f manifests/local-path/local-path-storageclass.yaml
```

## 6) ingress-nginx
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
kubectl create namespace ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx -f manifests/ingress-nginx/values.yaml
```

## 7) cert-manager
```bash
kubectl apply -f https://github.com/jetstack/cert-manager/releases/latest/download/cert-manager.yaml
kubectl apply -f manifests/cert-manager/clusterissuer-letsencrypt-staging.yaml
# cuando todo funcione bien:
kubectl apply -f manifests/cert-manager/clusterissuer-letsencrypt-prod.yaml
```

## 8) Jenkins por Helm
Edita `manifests/jenkins/values.yaml`:
- `CHANGEME_JENKINS_PASSWORD`
- `jenkins.example.com`

Luego:
```bash
helm repo add jenkins https://charts.jenkins.io
helm repo update
kubectl create namespace jenkins
helm install jenkins jenkins/jenkins -n jenkins -f manifests/jenkins/values.yaml
```

## 9) Nexus OSS
Edita `manifests/nexus/nexus-values.yaml`:
- `nexus.example.com`

Luego:
```bash
helm repo add sonatype https://sonatype.github.io/helm3-charts/
helm repo update
kubectl create namespace nexus
helm install nexus sonatype/nexus-repository-manager -n nexus -f manifests/nexus/nexus-values.yaml
```

## 10) ArgoCD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## 11) Rancher en homelab
```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.30.0+k3s1" sh -s -
kubectl apply -f https://github.com/jetstack/cert-manager/releases/latest/download/cert-manager.yaml
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update
kubectl create namespace cattle-system
helm install rancher rancher-latest/rancher --namespace cattle-system --set hostname="rancher.home.example" --set replicas=1
```
Importa ambos clusters.

## 12) Backups
```bash
bash runbooks/backup-etcd.sh
export COMPARTMENT_ID="<COMPARTMENT_OCID>"
export VOLUME_ID="<BLOCK_VOLUME_OCID>"
bash runbooks/snapshot-block-volume.sh
```

## 13) Placeholders
Terraform:
- `<TENANCY_OCID_...>`
- `<USER_OCID>`
- `<FINGERPRINT>`
- `<PATH_TO_API_PRIVATE_KEY_PEM>`
- `<COMPARTMENT_OCID>`
- `<AD_NAME_OR_OCID>`
- `<SSH_PUBLIC_KEY>`
- `<IMAGE_OCID_FOR_ARM>`

WireGuard:
- `<MADRID_CP_PUBLIC_IP>`
- `<MADRID_WK_PUBLIC_IP>`

Jenkins:
- `CHANGEME_JENKINS_PASSWORD`
- `jenkins.example.com`

Nexus:
- `nexus.example.com`

cert-manager:
- `tu-email@example.com`
