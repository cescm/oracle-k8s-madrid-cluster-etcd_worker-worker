# Instalación detallada

## Arquitectura
- **Madrid**: `madrid-cp-01` (control-plane + worker) y `madrid-wk-01` (worker)
- **Frankfurt**: `fra-cp-01` (control-plane + worker)
- **Rancher**: en homelab, importando ambos clusters

## Recomendación de red
Como los dos nodos de Madrid están en tenancies distintas, usa una red privada overlay:
- WireGuard
- Tailscale
- Zerotier

IP sugeridas:
- `madrid-cp-01`: `10.100.0.1`
- `madrid-wk-01`: `10.100.0.2`

## 1) Terraform
Hay 3 carpetas:
- `terraform/madrid-control-plane`
- `terraform/madrid-worker`
- `terraform/frankfurt-single`

En cada una:
```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
terraform init
terraform apply
```

## 2) Validación
En cada VM:
```bash
ssh -i <SSH_PRIVATE_KEY> opc@<PUBLIC_IP>
df -h | grep k8s-localstorage || true
ls -la /mnt/k8s-localstorage/local-path
kubeadm version
```

## 3) Crear cluster Madrid
En `madrid-cp-01`:
```bash
chmod +x kubeadm/init-madrid-control-plane.sh
CONTROL_PLANE_ENDPOINT=10.100.0.1 bash kubeadm/init-madrid-control-plane.sh
kubectl get nodes -o wide
```

Obtén el join command:
```bash
kubeadm token create --print-join-command
```

En `madrid-wk-01`:
```bash
chmod +x kubeadm/join-madrid-worker.sh
bash kubeadm/join-madrid-worker.sh
```

Verifica desde `madrid-cp-01`:
```bash
kubectl get nodes
```

## 4) Crear cluster Frankfurt
En `fra-cp-01`:
```bash
chmod +x kubeadm/init-frankfurt-single-node.sh
bash kubeadm/init-frankfurt-single-node.sh
kubectl get nodes
```

## 5) Instalar storage local
En ambos clusters:
```bash
kubectl apply -f manifests/local-path/local-path-deploy.yaml
kubectl apply -f manifests/local-path/local-path-storageclass.yaml
kubectl get storageclass
```

## 6) Jenkins en Madrid
```bash
kubectl apply -f manifests/jenkins/00-namespace.yaml
kubectl apply -f manifests/jenkins/10-pvc.yaml
kubectl apply -f manifests/jenkins/20-deployment.yaml
kubectl apply -f manifests/jenkins/30-service.yaml
```

Jenkins queda fijado a `madrid-cp-01`.

## 7) Nexus en Madrid
```bash
helm repo add sonatype https://sonatype.github.io/helm3-charts/
helm repo update
kubectl create namespace nexus
helm install nexus sonatype/nexus-repository-manager -n nexus -f manifests/nexus/nexus-values.yaml
```

Nexus queda fijado a `madrid-wk-01`.

## 8) ArgoCD en Madrid
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## 9) Rancher en homelab
Pasos resumidos:
```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.30.0+k3s1" sh -s -
kubectl apply -f https://github.com/jetstack/cert-manager/releases/latest/download/cert-manager.yaml
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update
kubectl create namespace cattle-system
helm install rancher rancher-latest/rancher --namespace cattle-system --set hostname="rancher.home.example" --set replicas=1
```

Luego importa:
- cluster Madrid
- cluster Frankfurt

## 10) Backups
Snapshot etcd:
```bash
bash runbooks/backup-etcd.sh
```

Snapshot Block Volume:
```bash
export COMPARTMENT_ID="<COMPARTMENT_OCID>"
export VOLUME_ID="<BLOCK_VOLUME_OCID>"
bash runbooks/snapshot-block-volume.sh
```

## 11) Placeholders a sustituir
En `terraform/*/terraform.tfvars.example` cambia:
- `<TENANCY_OCID_...>`
- `<USER_OCID>`
- `<FINGERPRINT>`
- `<PATH_TO_API_PRIVATE_KEY_PEM>`
- `<COMPARTMENT_OCID>`
- `<AD_NAME_OR_OCID>`
- `<SSH_PUBLIC_KEY>`
- `<IMAGE_OCID_FOR_ARM>`

## 12) Notas operativas
- Frankfurt no reemplaza automáticamente a Madrid.
- Jenkins y Nexus son stateful; con `local-path` no tienen failover transparente entre clusters.
- Esta arquitectura te da un cluster principal útil en Madrid y un cluster independiente en Frankfurt.
