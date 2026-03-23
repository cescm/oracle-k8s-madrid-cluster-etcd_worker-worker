1. Ejecuta `scripts/generate-wireguard-configs.sh`
2. Copia `output/madrid-cp-01-wg0.conf` al control-plane
3. Copia `output/madrid-wk-01-wg0.conf` al worker
4. Ejecuta `scripts/install-wireguard-peer.sh /ruta/al/wg0.conf` en cada nodo
5. Verifica ping entre 10.100.0.1 y 10.100.0.2
