helm repo add sonatype https://sonatype.github.io/helm3-charts/
helm repo update
kubectl create namespace nexus
helm install nexus sonatype/nexus-repository-manager -n nexus -f manifests/nexus/nexus-values.yaml
