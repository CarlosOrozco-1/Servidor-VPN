#!/bin/bash

################################################################################
# Script: server/wg-monitor-advanced.sh
# Descripción: Monitor avanzado con todos los comandos de diagnóstico WireGuard
# Contexto: SERVIDOR — Ejecutar dentro del servidor
# Uso: sudo ./wg-monitor-advanced.sh [modo]
#
# Modos:
#   full, peers, endpoints, transfer, handshakes, allowed-ips,
#   keepalive, routes, firewall, sockets, service, logs, all
################################################################################

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'
GRAY='\033[0;37m'; BOLD='\033[1m'; NC='\033[0m'

WG_IFACE="${WG_INTERFACE:-wg0}"
MODE="${1:-full}"

[ "$EUID" -ne 0 ] && { echo -e "${RED}❌ Requiere sudo${NC}"; exit 1; }
! command -v wg &>/dev/null && { echo -e "${RED}❌ WireGuard no instalado${NC}"; exit 1; }

section() { echo ""; echo -e "${MAGENTA}${BOLD}▶ $1${NC}"; echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}"; }
check_iface() { ip link show "$WG_IFACE" &>/dev/null || { echo -e "${RED}  ✗ Interfaz ${WG_IFACE} inactiva${NC}"; return 1; }; }

format_bytes() {
  local b=${1:-0}
  if [ "$b" -ge 1073741824 ]; then echo "$(awk "BEGIN{printf \"%.2f\",${b}/1073741824}") GB"
  elif [ "$b" -ge 1048576 ]; then echo "$(awk "BEGIN{printf \"%.2f\",${b}/1048576}") MB"
  elif [ "$b" -ge 1024 ]; then echo "$(awk "BEGIN{printf \"%.2f\",${b}/1024}") KB"
  else echo "${b} B"; fi
}

format_time_ago() {
  local ts=${1:-0}; local now; now=$(date +%s); local ago=$((now - ts))
  [ "$ts" -eq 0 ] && { echo "nunca"; return; }
  if [ "$ago" -lt 60 ]; then echo "${ago}s atrás"
  elif [ "$ago" -lt 3600 ]; then echo "$((ago/60))m $((ago%60))s atrás"
  elif [ "$ago" -lt 86400 ]; then echo "$((ago/3600))h $((ago%3600/60))m atrás"
  else echo "$((ago/86400))d $((ago%86400/3600))h atrás"; fi
}

peer_status() {
  local ts=${1:-0}; local now; now=$(date +%s); local ago=$((now - ts))
  [ "$ts" -eq 0 ] && { echo -e "${RED}✗ SIN HS${NC}"; return; }
  [ "$ago" -lt 180 ] && echo -e "${GREEN}● ACTIVO  ${NC}" && return
  echo -e "${RED}◌ INACTIVO${NC}"
}

# ── Modos de diagnóstico ─────────────────────────────────────

cmd_full() {
  section "wg show ${WG_IFACE} — Vista Completa"
  check_iface || return
  wg show "$WG_IFACE"
}

cmd_peers() {
  section "Peers — Claves Públicas"
  check_iface || return
  local num=0
  while read -r key; do
    num=$((num + 1))
    echo -e "  ${CYAN}Peer ${num}:${NC} ${key}"
  done < <(wg show "$WG_IFACE" peers)
  echo -e "\n  Total: ${GREEN}${num} peer(s)${NC}"
}

cmd_endpoints() {
  section "Endpoints — IP:Puerto actual de cada peer"
  check_iface || return
  printf "  ${GRAY}%-3s  %-44s  %s${NC}\n" "#" "PEER" "ENDPOINT"
  echo -e "${BLUE}  ──────────────────────────────────────────────────────────${NC}"
  local num=0
  wg show "$WG_IFACE" endpoints | while read -r key endpoint; do
    num=$((num + 1))
    if [ "$endpoint" = "(none)" ]; then
      printf "  %-3d  %-44s  ${YELLOW}%s${NC}\n" "$num" "${key:0:42}..." "sin endpoint"
    else
      printf "  %-3d  %-44s  ${GREEN}%s${NC}\n" "$num" "${key:0:42}..." "$endpoint"
    fi
  done
}

cmd_transfer() {
  section "Tráfico de Transferencia por Peer"
  check_iface || return
  printf "  ${GRAY}%-3s  %-34s  %-16s  %s${NC}\n" "#" "PEER" "↓ RECIBIDO" "↑ ENVIADO"
  echo -e "${BLUE}  ──────────────────────────────────────────────────────────${NC}"
  local num=0
  local total_rx=0; local total_tx=0
  wg show "$WG_IFACE" transfer | while read -r key rx tx; do
    num=$((num + 1))
    total_rx=$((total_rx + rx)); total_tx=$((total_tx + tx))
    printf "  %-3d  %-34s  %-16s  %s\n" \
      "$num" "${key:0:32}..." "$(format_bytes $rx)" "$(format_bytes $tx)"
  done
  echo -e "${BLUE}  ──────────────────────────────────────────────────────────${NC}"
  printf "  %-38s  %-16s  %s\n" "TOTAL:" "$(format_bytes $total_rx)" "$(format_bytes $total_tx)"
}

cmd_handshakes() {
  section "Último Handshake por Peer"
  check_iface || return
  printf "  ${GRAY}%-3s  %-10s  %-26s  %s${NC}\n" "#" "ESTADO" "ÚLTIMO HANDSHAKE" "PEER"
  echo -e "${BLUE}  ──────────────────────────────────────────────────────────${NC}"
  local num=0
  wg show "$WG_IFACE" latest-handshakes | while read -r key ts; do
    num=$((num + 1))
    local status; status=$(peer_status "$ts")
    local time_str; time_str=$(format_time_ago "$ts")
    printf "  %-3d  " "$num"
    echo -ne "$(echo -e "${status}")  "
    printf "%-26s  %s\n" "$time_str" "${key:0:30}..."
  done
}

cmd_allowed_ips() {
  section "IPs Asignadas (Allowed IPs) por Peer"
  check_iface || return
  printf "  ${GRAY}%-3s  %-22s  %s${NC}\n" "#" "IP ASIGNADA" "PEER"
  echo -e "${BLUE}  ──────────────────────────────────────────────────────────${NC}"
  local num=0
  wg show "$WG_IFACE" allowed-ips | while read -r key ips; do
    num=$((num + 1))
    printf "  %-3d  ${GREEN}%-22s${NC}  %s\n" "$num" "$ips" "${key:0:35}..."
  done
}

cmd_keepalive() {
  section "Persistent Keepalive por Peer"
  check_iface || return
  local num=0
  wg show "$WG_IFACE" persistent-keepalive | while read -r key ka; do
    num=$((num + 1))
    if [ "$ka" = "off" ]; then
      echo -e "  Peer ${num}: ${YELLOW}desactivado${NC}  ${GRAY}${key:0:35}...${NC}"
    else
      echo -e "  Peer ${num}: ${GREEN}${ka}s${NC}  ${GRAY}${key:0:35}...${NC}"
    fi
  done
}

cmd_routes() {
  section "Tabla de Rutas — ${WG_IFACE}"
  check_iface || return
  echo -e "  ${GRAY}Rutas directas:${NC}"
  ip route show | grep "$WG_IFACE" | while read -r line; do
    echo -e "  ${GREEN}→${NC} $line"
  done
  echo -e "\n  ${GRAY}Todas las tablas:${NC}"
  ip route show table all | grep "$WG_IFACE" | while read -r line; do
    echo -e "  ${CYAN}→${NC} $line"
  done
}

cmd_firewall() {
  section "Reglas iptables — WireGuard"
  local port; port=$(wg show "$WG_IFACE" listen-port 2>/dev/null)
  echo -e "  Puerto WireGuard: ${GREEN}${port}${NC}\n"
  echo -e "  ${GRAY}FORWARD rules (${WG_IFACE}):${NC}"
  iptables -L FORWARD -n -v 2>/dev/null | grep -E "wg|${WG_IFACE}" | \
    while read -r line; do echo "  $line"; done
  echo -e "\n  ${GRAY}NAT POSTROUTING:${NC}"
  iptables -t nat -L POSTROUTING -n -v 2>/dev/null | \
    grep -v "^Chain\|^target\|^$" | head -5 | while read -r line; do echo "  $line"; done
  echo -e "\n  ${GRAY}Socket UDP puerto ${port}:${NC}"
  ss -unp 2>/dev/null | grep ":${port}" | while read -r line; do
    echo -e "  ${GREEN}$line${NC}"
  done
}

cmd_sockets() {
  section "Socket y Estadísticas de Red — ${WG_IFACE}"
  local port; port=$(wg show "$WG_IFACE" listen-port 2>/dev/null)
  echo -e "  ${GRAY}Socket UDP activo (puerto ${port}):${NC}"
  ss -unp 2>/dev/null | grep ":${port}" | while read -r l; do echo "  $l"; done
  echo -e "\n  ${GRAY}Estadísticas de la interfaz (ip -s):${NC}"
  ip -s link show "$WG_IFACE" 2>/dev/null | while read -r l; do echo "  $l"; done
  echo -e "\n  ${GRAY}Datos del kernel (/proc/net/dev):${NC}"
  grep "$WG_IFACE" /proc/net/dev 2>/dev/null | awk '
    {print "  RX bytes:",$2,"  TX bytes:",$10}
  '
}

cmd_service() {
  section "Servicio systemd — wg-quick@${WG_IFACE}"
  systemctl status "wg-quick@${WG_IFACE}" --no-pager -l 2>/dev/null || \
    echo -e "  ${YELLOW}⚠ No es un servicio systemd activo${NC}"
  echo -e "\n  ${GRAY}IP Forwarding:${NC}"
  local fwd; fwd=$(sysctl -n net.ipv4.ip_forward 2>/dev/null)
  [ "$fwd" = "1" ] && echo -e "  ${GREEN}✓ net.ipv4.ip_forward=1 (habilitado)${NC}" || \
    echo -e "  ${RED}✗ net.ipv4.ip_forward=0 (DESHABILITADO)${NC}"
}

cmd_logs() {
  section "Logs del Sistema — WireGuard"
  echo -e "  ${GRAY}Últimas 30 líneas:${NC}\n"
  journalctl -u "wg-quick@${WG_IFACE}" --no-pager -n 30 2>/dev/null || \
  journalctl -k --no-pager -n 50 2>/dev/null | grep -i "wireguard\|wg" || \
    echo -e "  ${YELLOW}⚠ No hay logs de WireGuard en el journal${NC}"
}

cmd_all() {
  echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${MAGENTA}║   WireGuard — Diagnóstico Completo                        ║${NC}"
  echo -e "${MAGENTA}║   $(date '+%Y-%m-%d %H:%M:%S')                                    ║${NC}"
  echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
  cmd_full; cmd_handshakes; cmd_transfer; cmd_endpoints
  cmd_allowed_ips; cmd_keepalive; cmd_routes; cmd_firewall
  cmd_sockets; cmd_service; cmd_logs
  echo -e "\n${GREEN}✓ Diagnóstico completo — $(date '+%H:%M:%S')${NC}"
}

show_help() {
  echo -e "${BLUE}Uso:${NC} sudo ./wg-monitor-advanced.sh [modo]\n"
  echo -e "${BLUE}Modos disponibles:${NC}"
  local modos=(
    "full        Vista completa de wg show (default)"
    "peers       Claves públicas de todos los peers"
    "endpoints   IP:Puerto actual de cada peer"
    "transfer    Tráfico ↓RX / ↑TX por peer (con totales)"
    "handshakes  Último handshake con estado activo/inactivo"
    "allowed-ips IPs VPN asignadas a cada peer"
    "keepalive   Configuración persistent-keepalive"
    "routes      Tabla de rutas de la interfaz"
    "firewall    Reglas iptables + socket UDP"
    "sockets     Socket UDP y estadísticas kernel"
    "service     Estado del servicio systemd"
    "logs        Logs recientes (últimas 30 líneas)"
    "all         TODOS los diagnósticos en secuencia"
  )
  for m in "${modos[@]}"; do
    echo -e "  ${CYAN}$m${NC}"
  done
  echo -e "\n${BLUE}Ejemplos:${NC}"
  echo "  sudo ./wg-monitor-advanced.sh handshakes"
  echo "  sudo ./wg-monitor-advanced.sh transfer"
  echo "  sudo ./wg-monitor-advanced.sh all"
}

# ── Banner y ejecución ────────────────────────────────────────
echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║   WireGuard Monitor Avanzado │ $(date '+%H:%M:%S')                  ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"

case "$MODE" in
  full)         cmd_full ;;
  peers)        cmd_peers ;;
  endpoints)    cmd_endpoints ;;
  transfer)     cmd_transfer ;;
  handshakes)   cmd_handshakes ;;
  allowed-ips)  cmd_allowed_ips ;;
  keepalive)    cmd_keepalive ;;
  routes)       cmd_routes ;;
  firewall)     cmd_firewall ;;
  sockets)      cmd_sockets ;;
  service)      cmd_service ;;
  logs)         cmd_logs ;;
  all)          cmd_all ;;
  help|--help|-h) show_help ;;
  *)
    echo -e "${RED}❌ Modo desconocido: ${MODE}${NC}\n"
    show_help; exit 1 ;;
esac

echo -e "\n${GREEN}✓ Listo — $(date '+%H:%M:%S')${NC}"
