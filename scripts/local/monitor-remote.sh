#!/bin/bash

################################################################################
# Script: local/monitor-remote.sh
# Descripción: Abre un monitor en tiempo real del servidor WireGuard vía SSH
# Contexto: LOCAL — Ejecutar en tu máquina
# Uso: ./scripts/local/monitor-remote.sh
# Notas: Corre el monitor de forma interactiva en el servidor.
#        Presiona Ctrl+C para salir.
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
REFRESH="${REFRESH_INTERVAL:-5}"

# ── Validaciones ─────────────────────────────────────────────
if [ ! -f "$SSH_KEY" ]; then
  echo -e "${RED}❌ Llave SSH no encontrada: ${SSH_KEY}${NC}"
  exit 1
fi

chmod 600 "$SSH_KEY"

# ── Banner ───────────────────────────────────────────────────
echo -e "${MAGENTA}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Monitor WireGuard Remoto (Tiempo Real)                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${BLUE}  Servidor:  ${GREEN}${PUBLIC_IP}${NC}"
echo -e "${BLUE}  Interface: ${GREEN}${WG_INTERFACE}${NC}"
echo -e "${BLUE}  Refresco:  ${GREEN}cada ${REFRESH}s${NC}"
echo ""
echo -e "${YELLOW}  Conectando al monitor remoto... (Ctrl+C para salir)${NC}"
echo ""
sleep 1

# ── Monitor remoto vía SSH con pseudo-TTY ────────────────────
# -t fuerza la asignación de TTY para permitir clear y colores
ssh -t -i "$SSH_KEY" -p "$SSH_PORT" \
    -o ConnectTimeout=10 \
    -o StrictHostKeyChecking=accept-new \
    "${SSH_USER}@${PUBLIC_IP}" \
    "REFRESH_INTERVAL=${REFRESH} WG_INTERFACE=${WG_INTERFACE} bash -s" << 'REMOTE_MONITOR'

WG_IFACE="${WG_INTERFACE:-wg0}"
REFRESH="${REFRESH_INTERVAL:-5}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;37m'
NC='\033[0m'

format_bytes() {
  local b=${1:-0}
  if [ "$b" -ge 1073741824 ]; then echo "$(awk "BEGIN {printf \"%.1f\",${b}/1073741824}") GB"
  elif [ "$b" -ge 1048576 ]; then echo "$(awk "BEGIN {printf \"%.1f\",${b}/1048576}") MB"
  elif [ "$b" -ge 1024 ]; then echo "$(awk "BEGIN {printf \"%.1f\",${b}/1024}") KB"
  else echo "${b} B"; fi
}

format_time() {
  local s=${1:-0}
  if [ "$s" -lt 60 ]; then echo "${s}s"
  elif [ "$s" -lt 3600 ]; then echo "$((s/60))m $((s%60))s"
  elif [ "$s" -lt 86400 ]; then echo "$((s/3600))h $((s%3600/60))m"
  else echo "$((s/86400))d $((s%86400/3600))h"; fi
}

trap 'echo ""; echo -e "${YELLOW}⚠ Monitor detenido.${NC}"; exit 0' INT TERM

ITERATION=0

while true; do
  clear
  NOW=$(date +%s)
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  ITERATION=$((ITERATION + 1))

  echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${MAGENTA}║   WireGuard Monitor │ ${TIMESTAMP}      ║${NC}"
  echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""

  # ── Estado del sistema ──────────────────────────────────────
  echo -e "${BLUE}┌─ Sistema ─────────────────────────────────────────────────┐${NC}"
  echo -e "│  Hostname:  $(hostname)"
  echo -e "│  Uptime:    $(uptime -p)"
  LOAD=$(cat /proc/loadavg | awk '{print $1}')
  echo -e "│  Carga:     ${LOAD}"
  echo -e "│  Memoria:   $(free -h | awk '/^Mem:/ {print $3 " / " $2}')"
  echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
  echo ""

  # ── Estado de WireGuard ─────────────────────────────────────
  if ! ip link show "$WG_IFACE" > /dev/null 2>&1; then
    echo -e "${RED}  ✗ La interfaz ${WG_IFACE} no está activa.${NC}"
    echo -e "${YELLOW}  Inicia el servidor con: sudo wg-quick up ${WG_IFACE}${NC}"
    sleep "$REFRESH"
    continue
  fi

  IP_ADDR=$(ip addr show "$WG_IFACE" 2>/dev/null | grep "inet " | awk '{print $2}')
  echo -e "${CYAN}┌─ WireGuard: ${WG_IFACE} │ ${GREEN}● ACTIVO${CYAN} │ IP: ${GREEN}${IP_ADDR}${NC}"
  echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
  echo ""

  # ── Tabla de peers ──────────────────────────────────────────
  echo -e "${CYAN}┌─ Peers ───────────────────────────────────────────────────┐${NC}"

  PEER_NUM=0
  ACTIVE_PEERS=0
  TOTAL_RX=0
  TOTAL_TX=0

  while IFS=$'\t' read -r PUB_KEY PSK ENDPOINT ALLOWED_IPS LAST_HS RX TX KEEPALIVE; do
    PEER_NUM=$((PEER_NUM + 1))
    SHORT_KEY="${PUB_KEY:0:22}..."
    RX=${RX:-0}
    TX=${TX:-0}
    TOTAL_RX=$((TOTAL_RX + RX))
    TOTAL_TX=$((TOTAL_TX + TX))

    if [ "${LAST_HS:-0}" -gt 0 ] 2>/dev/null; then
      AGO=$((NOW - LAST_HS))
      if [ "$AGO" -lt 180 ]; then
        STATUS_ICON="${GREEN}● ACTIVO  ${NC}"
        ACTIVE_PEERS=$((ACTIVE_PEERS + 1))
      else
        STATUS_ICON="${YELLOW}◌ INACTIVO${NC}"
      fi
      HS_STR=$(format_time $AGO)
    else
      STATUS_ICON="${RED}✗ SIN HS  ${NC}"
      HS_STR="nunca"
    fi

    echo -e "│"
    echo -e "│  ${CYAN}[Peer ${PEER_NUM}]${NC} ${SHORT_KEY}"
    echo -e "│  Estado:   $(echo -e "${STATUS_ICON}")  │  IP: ${ALLOWED_IPS}"
    echo -e "│  Endpoint: ${ENDPOINT:-no disponible}"
    echo -e "│  Último HS: ${HS_STR}  │  ↓ $(format_bytes $RX)  │  ↑ $(format_bytes $TX)"
  done < <(sudo wg show "$WG_IFACE" dump 2>/dev/null | tail -n +2)

  if [ "$PEER_NUM" -eq 0 ]; then
    echo -e "│  ${YELLOW}No hay peers configurados.${NC}"
  fi

  echo -e "│"
  echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
  echo ""

  # ── Resumen ─────────────────────────────────────────────────
  echo -e "${BLUE}┌─ Resumen ──────────────────────────────────────────────────┐${NC}"
  echo -e "│  Total peers:    ${PEER_NUM}"
  echo -e "│  Peers activos:  ${GREEN}${ACTIVE_PEERS}${NC}"
  echo -e "│  Peers inactivos: ${YELLOW}$((PEER_NUM - ACTIVE_PEERS))${NC}"
  echo -e "│  Tráfico total:  ↓ $(format_bytes $TOTAL_RX)  │  ↑ $(format_bytes $TOTAL_TX)"
  echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
  echo ""
  echo -e "${GRAY}  Iteración: ${ITERATION} │ Refresco: ${REFRESH}s │ Ctrl+C para salir${NC}"

  sleep "$REFRESH"
done

REMOTE_MONITOR

echo ""
echo -e "${GREEN}✓ Monitor cerrado.${NC}"
