#!/usr/bin/env bash
set -euo pipefail
echo "Pega aquí el comando de join:"
read -r JOIN_CMD
if [[ "$JOIN_CMD" != *"kubeadm join"* ]]; then echo "Comando no válido"; exit 1; fi
sudo bash -lc "$JOIN_CMD"
