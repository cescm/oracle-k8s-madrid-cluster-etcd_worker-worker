#cloud-config
package_update: true
package_upgrade: true
packages:
  - jq
  - curl
  - cloud-guest-utils
  - gdisk
  - parted

users:
  - default
  - name: opc
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${ssh_public_key}

write_files:
  - path: /usr/local/bin/bootstrap-node.sh
    permissions: '0755'
    content: |
      #!/usr/bin/env bash
      set -euo pipefail
      if [ "$EUID" -ne 0 ]; then echo "Run as root"; exit 1; fi
      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get -y upgrade
      apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common jq
      swapoff -a
      sed -i '/ swap / s/^/#/' /etc/fstab
      cat >/etc/sysctl.d/k8s.conf <<'EOF'
      net.bridge.bridge-nf-call-ip6tables = 1
      net.bridge.bridge-nf-call-iptables = 1
      net.ipv4.ip_forward = 1
      EOF
      sysctl --system
      apt-get install -y containerd
      mkdir -p /etc/containerd
      containerd config default > /etc/containerd/config.toml
      sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
      systemctl restart containerd
      systemctl enable containerd
      mkdir -p /etc/apt/keyrings
      curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
      echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' > /etc/apt/sources.list.d/kubernetes.list
      apt-get update
      apt-get install -y kubelet kubeadm kubectl
      apt-mark hold kubelet kubeadm kubectl
      echo "bootstrap complete"
  - path: /usr/local/bin/mount-local-storage.sh
    permissions: '0755'
    content: |
      #!/usr/bin/env bash
      set -euo pipefail
      MOUNT_POINT="/mnt/k8s-localstorage"
      mkdir -p "$MOUNT_POINT"
      ROOT_SRC="$(findmnt -n -o SOURCE / || true)"
      ROOT_DEV="$(echo "$ROOT_SRC" | sed 's/[0-9]*$//' | sed 's|/dev/||')"
      CANDIDATES="$(lsblk -dn -o NAME,TYPE | awk '$2=="disk"{print $1}' | grep -v "^${ROOT_DEV}$" || true)"
      if [ -z "$CANDIDATES" ]; then exit 0; fi
      DEV="$(echo "$CANDIDATES" | head -n1)"
      DEV_PATH="/dev/${DEV}"
      PART="${DEV_PATH}1"
      if [ ! -b "$PART" ]; then
        parted -s "$DEV_PATH" mklabel gpt
        parted -s -a optimal "$DEV_PATH" mkpart primary 0% 100%
        sleep 2
      fi
      if ! blkid "$PART" >/dev/null 2>&1; then
        mkfs.ext4 -F "$PART"
      fi
      if ! grep -q "$MOUNT_POINT" /etc/fstab; then
        UUID="$(blkid -s UUID -o value "$PART")"
        echo "UUID=${UUID}  $MOUNT_POINT  ext4  defaults,noatime  0  2" >> /etc/fstab
      fi
      mount -a
      mkdir -p "$MOUNT_POINT/local-path"
runcmd:
  - [ bash, -lc, "/usr/local/bin/mount-local-storage.sh" ]
  - [ bash, -lc, "/usr/local/bin/bootstrap-node.sh" ]
final_message: "Cloud-init finished"
