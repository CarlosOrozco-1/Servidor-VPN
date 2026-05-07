#!/bin/bash

################################################################################
# Script: server/wireguard-status.sh
# Descripción: Reporte rápido del estado de WireGuard para ejecutar en el servidor
# Contexto: SERVIDOR — Copiar al servidor y ejecutar ahí
# Uso: sudo ./wireguard-status.sh [wg0]
#      El primer argumento es la interfaz (default: wg0)
################################################################################

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

WG_IFACE="${1:-${WG_INTERFACE:-wg0}}"

# ── Verificar sudo ───────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Requiere permisos root: sudo ./wireguard-status.sh${NC}"
  exit 1
fi

# ── Verificar WireGuard instalado ────────────────────────────
if ! command -v wg &>/dev/null; then
  echo -e "${RED}❌ WireGuard no instalado: sudo apt install wireguard wireguard-tools${NC}"
  exit 1
fi

# ── Función de formato de bytes ──────────────────────────────
format_bytes() {
  local b=${1:-0}
  if [ "$b" -ge 1073741824 ]; then echo "$(awk "BEGIN {printf \"%.2f\",${b}/1073741824}") GB"
  elif [ "$b" -ge 1048576 ]; then echo "$(awk "BEGIN {printf \"%.2f\",${b}/1048576}") MB"
  elif [ "$b" -ge 1024 ]; then echo "$(awk "BEGIN {printf \"%.2f\",${b}/1024}") KB"
  else echo "${b} B"; fi
}

# ── Banner ───────────────────────────────────────────────────
echo -e "${MAGENTA}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   WireGuard Status Report                                 ║"
echo "║   $(date '+%Y-%m-%d %H:%M:%S')                                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Estado de la interfaz ────────────────────────────────────
echo -e "${CYAN}┌─ Interfaz: ${WG_IFACE} ───────────────────────────────────────┐${NC}"

if ! ip link show "$WG_IFACE" > /dev/null 2>&1; then
  echo -e "│  ${RED}● INACTIVO — La interfaz ${WG_IFACE} no existe.${NC}"
  echo -e "│  ${YELLOW}Inicia con: sudo wg-quick up ${WG_IFACE}${NC}"
  echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
  exit 1
fi

IP_ADDR=$(ip addr show "$WG_IFACE" 2>/dev/null | grep "inet " | awk '{print $2}')
WG_PORT=$(wg show "$WG_IFACE" listen-port 2>/dev/null)
WG_PUBKEY=$(wg show "$WG_IFACE" public-key 2>/dev/null)

echo -e "│  ${GREEN}● ACTIVO${NC}"
echo -e "│  IP VPN:       ${GREEN}${IP_ADDR}${NC}"
echo -e "│  Puerto escucha: ${WG_PORT}"
echo -e "│  Clave pública: ${WG_PUBKEY:0:35}..."
echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
echo ""

# ── Peers ────────────────────────────────────────────────────
NOW=$(date +%s)
PEER_NUM=0
ACTIVE_PEERS=0
TOTAL_RX=0
TOTAL_TX=0

echo -e "${CYAN}┌─ Peers ───────────────────────────────────────────────────┐${NC}"
echo -e "│  ${GRAY}#   IP Asignada     Estado      Último HS    ↓ RX      ↑ TX${NC}"
echo -e "│  ${GRAY}─────────────────────────────────────────────────────────${NC}"

while IFS=$'\t' read -r PUB_KEY PSK ENDPOINT ALLOWED_IPS LAST_HS RX TX KEEPALIVE; do
  PEER_NUM=$((PEER_NUM + 1))
  RX=${RX:-0}
  TX=${TX:-0}
  TOTAL_RX=$((TOTAL_RX + RX))
  TOTAL_TX=$((TOTAL_TX + TX))

  # Estado basado en último handshake
  if [ "${LAST_HS:-0}" -gt 0 ] 2>/dev/null; then
    AGO=$((NOW - LAST_HS))
    if [ "$AGO" -lt 180 ]; then
      STATUS="${GREEN}ACTIVO   ${NC}"
      ACTIVE_PEERS=$((ACTIVE_PEERS + 1))
    elif [ "$AGO" -lt 3600 ]; then
      STATUS="${YELLOW}$((AGO/60))m atrás ${NC}"
    elif [ "$AGO" -lt 86400 ]; then
      STATUS="${YELLOW}$((AGO/3600))h atrás ${NC}"
    else
      STATUS="${RED}$((AGO/86400))d atrás${NC}"
    fi
  else
    STATUS="${RED}sin HS   ${NC}"
  fi

  # Formatear IP asignada (sin el /32 o /24)
  IP_CLEAN=$(echo "$ALLOWED_IPS" | cut -d'/' -f1)

  printf "│  %-3d %-17s " "$PEER_NUM" "$IP_CLEAN"
  printf "$(echo -e "${STATUS}")  "
  printf "%-11s  %-10s  %s\n" \
    "${AGO:-?}s" \
    "$(format_bytes $RX)" \
    "$(format_bytes $TX)"

done < <(wg show "$WG_IFACE" dump 2>/dev/null | tail -n +2)

if [ "$PEER_NUM" -eq 0 ]; then
  echo -e "│  ${YELLOW}No hay peers configurados.${NC}"
fi

echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
echo ""

# ── Resumen ──────────────────────────────────────────────────
echo -e "${BLUE}┌─ Resumen ──────────────────────────────────────────────────┐${NC}"
if [ "$ACTIVE_PEERS" -gt 0 ]; then
  echo -e "│  Activos (< 3min):  ${GREEN}${ACTIVE_PEERS} / ${PEER_NUM}${NC}"
else
  echo -e "│  Activos (< 3min):  ${YELLOW}0 / ${PEER_NUM}${NC}"
fi
echo -e "│  Total recibido:    $(format_bytes $TOTAL_RX)"
echo -e "│  Total enviado:     $(format_bytes $TOTAL_TX)"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${GREEN}✓ Reporte completado — $(date '+%H:%M:%S')${NC}"
