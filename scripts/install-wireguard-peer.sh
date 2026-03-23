#!/usr/bin/env bash
set -euo pipefail
CFG_PATH="${1:-}"
if [ -z "$CFG_PATH" ]; then echo "Uso: $0 /ruta/al/wg0.conf"; exit 1; fi
sudo mkdir -p /etc/wireguard
sudo cp "$CFG_PATH" /etc/wireguard/wg0.conf
sudo chmod 600 /etc/wireguard/wg0.conf
sudo systemctl enable wg-quick@wg0
sudo systemctl restart wg-quick@wg0
sudo wg show
ip addr show wg0
