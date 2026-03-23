#!/usr/bin/env bash
set -euo pipefail
SNAP_DIR="/var/backups/etcd"
mkdir -p "$SNAP_DIR"
TS=$(date -u +%Y%m%dT%H%M%SZ)
SNAPFILE="${SNAP_DIR}/etcd-snapshot-${TS}.db"
sudo kubeadm snapshot save "$SNAPFILE"
echo "Snapshot saved: $SNAPFILE"
