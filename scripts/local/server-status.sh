#!/bin/bash

################################################################################
# Script: local/server-status.sh
# Descripción: Consulta el estado del servidor WireGuard vía SSH
# Contexto: LOCAL — Ejecutar en tu máquina
# Uso: ./scripts/local/server-status.sh
################################################################################

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Rutas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
ENV_FILE="$PROJECT_ROOT/notas-internas/.env"

# ── Cargar variables de entorno ──────────────────────────────
if [ ! -f "$ENV_FILE" ]; then
  echo -e "${RED}❌ No se encontró: ${ENV_FILE}${NC}"
  exit 1
fi

source "$ENV_FILE"

SSH_KEY="$PROJECT_ROOT/$SSH_KEY_PATH"

# ── Validaciones ─────────────────────────────────────────────
if [ ! -f "$SSH_KEY" ]; then
  echo -e "${RED}❌ Llave SSH no encontrada: ${SSH_KEY}${NC}"
  exit 1
fi

chmod 600 "$SSH_KEY"

# ── Banner ───────────────────────────────────────────────────
echo -e "${MAGENTA}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Estado del Servidor VPN (Remoto)                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${BLUE}  Consultando servidor ${GREEN}${PUBLIC_IP}${BLUE}...${NC}"
echo ""

# ── Obtener estado del servidor ───────────────────────────────
ssh -i "$SSH_KEY" -p "$SSH_PORT" \
    -o ConnectTimeout=10 \
    -o StrictHostKeyChecking=accept-new \
    "${SSH_USER}@${PUBLIC_IP}" \
    bash -s -- "${WG_INTERFACE}" << 'REMOTE_SCRIPT'

WG_IFACE="$1"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Estado del Sistema ────────────────────────────────────────
echo -e "${BLUE}┌─ Sistema ─────────────────────────────────────────────────┐${NC}"
echo -e "│  Hostname:  $(hostname)"
echo -e "│  Uptime:    $(uptime -p)"
echo -e "│  Carga:     $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
echo -e "│  Memoria:   $(free -h | awk '/^Mem:/ {print $3 " usada / " $2 " total"}')"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""

# ── Estado de WireGuard ───────────────────────────────────────
echo -e "${CYAN}┌─ WireGuard (${WG_IFACE}) ─────────────────────────────────────┐${NC}"

if ip link show "$WG_IFACE" > /dev/null 2>&1; then
  IP_ADDR=$(ip addr show "$WG_IFACE" 2>/dev/null | grep "inet " | awk '{print $2}')
  LINK_STATE=$(ip link show "$WG_IFACE" | grep -oP '(?<=state )\w+')

  echo -e "│  Status:     ${GREEN}● ACTIVO${NC}"
  echo -e "│  Interface:  ${WG_IFACE}"
  echo -e "│  IP VPN:     ${GREEN}${IP_ADDR}${NC}"
  echo -e "│  Link:       ${LINK_STATE}"

  # Peers conectados
  if command -v wg > /dev/null 2>&1; then
    TOTAL_PEERS=$(sudo wg show "$WG_IFACE" peers 2>/dev/null | wc -l)
    echo -e "│  Peers:      ${GREEN}${TOTAL_PEERS} configurado(s)${NC}"
    echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    # Detalle de cada peer
    echo -e "${CYAN}┌─ Peers Conectados ────────────────────────────────────────┐${NC}"
    PEER_NUM=0
    NOW=$(date +%s)

    sudo wg show "$WG_IFACE" dump 2>/dev/null | tail -n +2 | while IFS=$'\t' read -r PUB_KEY PSK ENDPOINT ALLOWED_IPS LAST_HS RX TX KEEPALIVE; do
      PEER_NUM=$((PEER_NUM + 1))
      SHORT_KEY="${PUB_KEY:0:20}..."

      # Estado del peer (handshake < 3 minutos = activo)
      if [ "$LAST_HS" -gt 0 ] 2>/dev/null; then
        AGO=$((NOW - LAST_HS))
        if [ "$AGO" -lt 180 ]; then
          STATUS="${GREEN}● ACTIVO${NC}"
          HS_TEXT="${AGO}s atrás"
        else
          STATUS="${YELLOW}● INACTIVO${NC}"
          if [ "$AGO" -lt 3600 ]; then
            HS_TEXT="$((AGO / 60))m atrás"
          elif [ "$AGO" -lt 86400 ]; then
            HS_TEXT="$((AGO / 3600))h atrás"
          else
            HS_TEXT="$((AGO / 86400))d atrás"
          fi
        fi
      else
        STATUS="${RED}● SIN CONEXIÓN${NC}"
        HS_TEXT="nunca"
      fi

      # Formato de bytes
      format_bytes() {
        local b=$1
        if [ "$b" -ge 1073741824 ]; then echo "$(awk "BEGIN {printf \"%.1f\",${b}/1073741824}") GB"
        elif [ "$b" -ge 1048576 ]; then echo "$(awk "BEGIN {printf \"%.1f\",${b}/1048576}") MB"
        elif [ "$b" -ge 1024 ]; then echo "$(awk "BEGIN {printf \"%.1f\",${b}/1024}") KB"
        else echo "${b} B"; fi
      }

      echo -e "│"
      echo -e "│  ${CYAN}Peer ${PEER_NUM}:${NC} ${SHORT_KEY}"
      echo -e "│  Estado:        $(echo -e "$STATUS")"
      echo -e "│  IP Asignada:   ${ALLOWED_IPS}"
      echo -e "│  Endpoint:      ${ENDPOINT:-no disponible}"
      echo -e "│  Último HS:     ${HS_TEXT}"
      echo -e "│  ↓ Recibido:    $(format_bytes ${RX:-0})"
      echo -e "│  ↑ Enviado:     $(format_bytes ${TX:-0})"
    done

    echo -e "│"
    echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
  fi
else
  echo -e "│  Status:     ${RED}● INACTIVO${NC}"
  echo -e "│  Interface:  ${WG_IFACE} no encontrada"
  echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
fi

REMOTE_SCRIPT

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -ne 0 ]; then
  echo -e "${RED}✗ Error al consultar el servidor (código: $EXIT_CODE)${NC}"
  echo -e "${YELLOW}  Verifica conectividad: ping ${PUBLIC_IP}${NC}"
  exit 1
fi
