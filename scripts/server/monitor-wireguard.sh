#!/bin/bash

################################################################################
# Script: server/monitor-wireguard.sh
# Descripción: Monitor continuo de WireGuard para ejecutar DENTRO del servidor
# Contexto: SERVIDOR — Copiar al servidor y ejecutar ahí
# Uso: sudo ./monitor-wireguard.sh [continuous|once]
#      continuous  - Monitoreo en tiempo real (default, refresco 5s)
#      once        - Reporte único y sale
# Variables de entorno:
#   REFRESH_INTERVAL  - Intervalo en segundos (default: 5)
#   WG_INTERFACE      - Interfaz a monitorear (default: wg0)
################################################################################

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;37m'
NC='\033[0m'

# Configuración
WG_IFACE="${WG_INTERFACE:-wg0}"
REFRESH="${REFRESH_INTERVAL:-5}"
MODE="${1:-continuous}"

# ── Verificar sudo ───────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Este script requiere permisos root.${NC}"
  echo -e "   Usa: ${YELLOW}sudo ./monitor-wireguard.sh${NC}"
  exit 1
fi

# ── Verificar WireGuard instalado ───────────────────────────
if ! command -v wg &>/dev/null; then
  echo -e "${RED}❌ WireGuard no está instalado.${NC}"
  echo -e "   Instala con: ${YELLOW}sudo apt install wireguard wireguard-tools${NC}"
  exit 1
fi

# ── Funciones de formato ─────────────────────────────────────
format_bytes() {
  local b=${1:-0}
  if [ "$b" -ge 1073741824 ]; then echo "$(awk "BEGIN {printf \"%.2f\",${b}/1073741824}") GB"
  elif [ "$b" -ge 1048576 ]; then echo "$(awk "BEGIN {printf \"%.2f\",${b}/1048576}") MB"
  elif [ "$b" -ge 1024 ]; then echo "$(awk "BEGIN {printf \"%.2f\",${b}/1024}") KB"
  else echo "${b} B"; fi
}

format_time() {
  local s=${1:-0}
  if [ "$s" -lt 60 ]; then echo "${s}s"
  elif [ "$s" -lt 3600 ]; then echo "$((s/60))m $((s%60))s"
  elif [ "$s" -lt 86400 ]; then echo "$((s/3600))h $((s%3600/60))m"
  else echo "$((s/86400))d $((s%86400/3600))h"; fi
}

# ── Función de reporte ───────────────────────────────────────
show_report() {
  local NOW
  NOW=$(date +%s)
  local TIMESTAMP
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

  echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${MAGENTA}║   WireGuard Monitor Server │ ${TIMESTAMP}  ║${NC}"
  echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""

  # ── Sistema ─────────────────────────────────────────────────
  echo -e "${BLUE}┌─ Sistema ─────────────────────────────────────────────────┐${NC}"
  echo -e "│  Hostname:   $(hostname)"
  echo -e "│  Uptime:     $(uptime -p)"
  echo -e "│  Carga:      $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
  echo -e "│  Memoria:    $(free -h | awk '/^Mem:/ {print $3 " usada / " $2 " total"}')"
  echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
  echo ""

  # ── Estado de la interfaz ────────────────────────────────────
  if ! ip link show "$WG_IFACE" > /dev/null 2>&1; then
    echo -e "${RED}┌─ WireGuard (${WG_IFACE}) ─────────────────────────────────────┐${NC}"
    echo -e "│  Status:  ${RED}● INACTIVO - Interfaz no encontrada${NC}"
    echo -e "${RED}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${YELLOW}  Inicia WireGuard con: sudo wg-quick up ${WG_IFACE}${NC}"
    return 1
  fi

  local IP_ADDR
  IP_ADDR=$(ip addr show "$WG_IFACE" 2>/dev/null | grep "inet " | awk '{print $2}')
  local WG_PORT
  WG_PORT=$(wg show "$WG_IFACE" listen-port 2>/dev/null)
  local WG_PUBKEY
  WG_PUBKEY=$(wg show "$WG_IFACE" public-key 2>/dev/null)

  echo -e "${GREEN}┌─ WireGuard: ${WG_IFACE} ● ACTIVO ─────────────────────────────┐${NC}"
  echo -e "│  IP VPN:       ${GREEN}${IP_ADDR}${NC}"
  echo -e "│  Puerto:       ${GREEN}${WG_PORT}${NC}"
  echo -e "│  Clave pública: ${GREEN}${WG_PUBKEY:0:30}...${NC}"
  echo -e "${GREEN}└────────────────────────────────────────────────────────────┘${NC}"
  echo ""

  # ── Peers ────────────────────────────────────────────────────
  echo -e "${CYAN}┌─ Peers ───────────────────────────────────────────────────┐${NC}"

  local PEER_NUM=0
  local ACTIVE_PEERS=0
  local TOTAL_RX=0
  local TOTAL_TX=0

  while IFS=$'\t' read -r PUB_KEY PSK ENDPOINT ALLOWED_IPS LAST_HS RX TX KEEPALIVE; do
    PEER_NUM=$((PEER_NUM + 1))
    local SHORT_KEY="${PUB_KEY:0:24}..."
    RX=${RX:-0}
    TX=${TX:-0}
    TOTAL_RX=$((TOTAL_RX + RX))
    TOTAL_TX=$((TOTAL_TX + TX))

    local STATUS_ICON HS_STR
    if [ "${LAST_HS:-0}" -gt 0 ] 2>/dev/null; then
      local AGO=$((NOW - LAST_HS))
      if [ "$AGO" -lt 180 ]; then
        STATUS_ICON="${GREEN}● ACTIVO  ${NC}"
        ACTIVE_PEERS=$((ACTIVE_PEERS + 1))
      else
        STATUS_ICON="${YELLOW}◌ INACTIVO${NC}"
      fi
      HS_STR="$(format_time $AGO) atrás"
    else
      STATUS_ICON="${RED}✗ SIN HS  ${NC}"
      HS_STR="sin handshake"
    fi

    echo -e "│"
    echo -e "│  ${CYAN}Peer ${PEER_NUM}:${NC} ${SHORT_KEY}"
    printf  "│  Estado:    "
    echo -e "${STATUS_ICON}"
    echo -e "│  IP:        ${ALLOWED_IPS}"
    echo -e "│  Endpoint:  ${ENDPOINT:-(no disponible)}"
    echo -e "│  Último HS: ${HS_STR}"
    echo -e "│  Tráfico:   ↓ $(format_bytes $RX)  │  ↑ $(format_bytes $TX)"
  done < <(wg show "$WG_IFACE" dump 2>/dev/null | tail -n +2)

  if [ "$PEER_NUM" -eq 0 ]; then
    echo -e "│  ${YELLOW}⚠ No hay peers configurados en ${WG_IFACE}.${NC}"
  fi

  echo -e "│"
  echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
  echo ""

  # ── Resumen ──────────────────────────────────────────────────
  echo -e "${BLUE}┌─ Resumen ──────────────────────────────────────────────────┐${NC}"
  echo -e "│  Total peers:     ${PEER_NUM}"
  echo -e "│  Activos (< 3m):  ${GREEN}${ACTIVE_PEERS}${NC}"
  echo -e "│  Inactivos:       ${YELLOW}$((PEER_NUM - ACTIVE_PEERS))${NC}"
  echo -e "│  Total recibido:  $(format_bytes $TOTAL_RX)"
  echo -e "│  Total enviado:   $(format_bytes $TOTAL_TX)"
  echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
}

# ── Main ─────────────────────────────────────────────────────
trap 'echo ""; echo -e "${YELLOW}⚠ Monitor detenido.${NC}"; exit 0' INT TERM

case "$MODE" in
  continuous)
    echo -e "${GREEN}Iniciando monitor continuo (cada ${REFRESH}s) — Ctrl+C para salir${NC}"
    sleep 1
    ITERATION=0
    while true; do
      clear
      ITERATION=$((ITERATION + 1))
      show_report
      echo ""
      echo -e "${GRAY}  Iteración: ${ITERATION} │ Refresco: ${REFRESH}s │ Ctrl+C para salir${NC}"
      sleep "$REFRESH"
    done
    ;;

  once)
    show_report
    ;;

  *)
    echo -e "${RED}❌ Modo desconocido: $MODE${NC}"
    echo ""
    echo -e "${BLUE}Uso:${NC}"
    echo "  sudo ./monitor-wireguard.sh [continuous|once]"
    echo ""
    echo -e "${BLUE}Variables de entorno:${NC}"
    echo "  REFRESH_INTERVAL=5   - Intervalo de refresco en segundos"
    echo "  WG_INTERFACE=wg0     - Interfaz a monitorear"
    exit 1
    ;;
esac
