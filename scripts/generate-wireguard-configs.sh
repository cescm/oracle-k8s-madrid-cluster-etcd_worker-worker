#!/usr/bin/env bash
set -euo pipefail
OUTDIR="${OUTDIR:-output}"
CP_PUBLIC_IP="${CP_PUBLIC_IP:-<MADRID_CP_PUBLIC_IP>}"
WK_PUBLIC_IP="${WK_PUBLIC_IP:-<MADRID_WK_PUBLIC_IP>}"
CP_PORT="${CP_PORT:-51820}"
WK_PORT="${WK_PORT:-51820}"
mkdir -p "$OUTDIR"
umask 077
wg genkey | tee "$OUTDIR/cp_private.key" | wg pubkey > "$OUTDIR/cp_public.key"
wg genkey | tee "$OUTDIR/wk_private.key" | wg pubkey > "$OUTDIR/wk_public.key"
CP_PRIV=$(cat "$OUTDIR/cp_private.key")
CP_PUB=$(cat "$OUTDIR/cp_public.key")
WK_PRIV=$(cat "$OUTDIR/wk_private.key")
WK_PUB=$(cat "$OUTDIR/wk_public.key")
cat > "$OUTDIR/madrid-cp-01-wg0.conf" <<EOF
[Interface]
Address = 10.100.0.1/24
ListenPort = ${CP_PORT}
PrivateKey = ${CP_PRIV}
SaveConfig = true

[Peer]
PublicKey = ${WK_PUB}
AllowedIPs = 10.100.0.2/32
Endpoint = ${WK_PUBLIC_IP}:${WK_PORT}
PersistentKeepalive = 25
EOF
cat > "$OUTDIR/madrid-wk-01-wg0.conf" <<EOF
[Interface]
Address = 10.100.0.2/24
ListenPort = ${WK_PORT}
PrivateKey = ${WK_PRIV}
SaveConfig = true

[Peer]
PublicKey = ${CP_PUB}
AllowedIPs = 10.100.0.1/32
Endpoint = ${CP_PUBLIC_IP}:${CP_PORT}
PersistentKeepalive = 25
EOF
echo "Ficheros generados en $OUTDIR"
