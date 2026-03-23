#!/usr/bin/env bash
set -euo pipefail
COMPARTMENT_ID="${COMPARTMENT_ID:-<COMPARTMENT_OCID>}"
VOLUME_ID="${VOLUME_ID:-<BLOCK_VOLUME_OCID>}"
TS=$(date -u +%Y%m%dT%H%M%SZ)
DISPLAY_NAME="snapshot-${TS}"
oci bv volume-backup create --volume-id "${VOLUME_ID}" --compartment-id "${COMPARTMENT_ID}" --display-name "${DISPLAY_NAME}"
echo "Requested snapshot for volume ${VOLUME_ID}: ${DISPLAY_NAME}"
