#!/bin/bash

################################################################################
# Script: server/generate-report.sh
# Descripción: Genera un reporte completo de WireGuard en archivo .txt y .md
# Contexto: SERVIDOR — Ejecutar dentro del servidor
# Uso: sudo ./generate-report.sh [directorio_salida]
#      Si no se especifica directorio, guarda en ~/vpn-reports/
################################################################################

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; NC='\033[0m'

WG_IFACE="${WG_INTERFACE:-wg0}"
OUTPUT_DIR="${1:-$HOME/vpn-reports}"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
REPORT_TXT="${OUTPUT_DIR}/wg-report-${TIMESTAMP}.txt"
REPORT_MD="${OUTPUT_DIR}/wg-report-${TIMESTAMP}.md"

[ "$EUID" -ne 0 ] && { echo -e "${RED}❌ Requiere sudo${NC}"; exit 1; }
! command -v wg &>/dev/null && { echo -e "${RED}❌ WireGuard no instalado${NC}"; exit 1; }

mkdir -p "$OUTPUT_DIR"

# ── Helpers ───────────────────────────────────────────────────
format_bytes() {
  local b=${1:-0}
  if [ "$b" -ge 1073741824 ]; then echo "$(awk "BEGIN{printf \"%.2f\",${b}/1073741824}") GB"
  elif [ "$b" -ge 1048576 ]; then echo "$(awk "BEGIN{printf \"%.2f\",${b}/1048576}") MB"
  elif [ "$b" -ge 1024 ]; then echo "$(awk "BEGIN{printf \"%.2f\",${b}/1024}") KB"
  else echo "${b} B"; fi
}

format_time_ago() {
  local ts=${1:-0}; local now; now=$(date +%s); local ago=$((now - ts))
  [ "$ts" -eq 0 ] && { echo "Nunca"; return; }
  if [ "$ago" -lt 60 ]; then echo "${ago}s"
  elif [ "$ago" -lt 3600 ]; then echo "$((ago/60))m $((ago%60))s"
  elif [ "$ago" -lt 86400 ]; then echo "$((ago/3600))h $((ago%3600/60))m"
  else echo "$((ago/86400))d $((ago%86400/3600))h"; fi
}

peer_status_text() {
  local ts=${1:-0}; local now; now=$(date +%s); local ago=$((now - ts))
  [ "$ts" -eq 0 ] && { echo "SIN HANDSHAKE"; return; }
  [ "$ago" -lt 180 ] && echo "ACTIVO" && return
  echo "INACTIVO"
}

# ── Banner ────────────────────────────────────────────────────
echo -e "${MAGENTA}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   WireGuard Report Generator                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${BLUE}  Interface:  ${GREEN}${WG_IFACE}${NC}"
echo -e "${BLUE}  Salida TXT: ${GREEN}${REPORT_TXT}${NC}"
echo -e "${BLUE}  Salida MD:  ${GREEN}${REPORT_MD}${NC}"
echo ""

# ════════════════════════════════════════════════════════════
# Recopilar datos
# ════════════════════════════════════════════════════════════
echo -e "${CYAN}[1/5] Recopilando información del sistema...${NC}"
HOSTNAME=$(hostname)
OS_INFO=$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2)
KERNEL=$(uname -r)
UPTIME_STR=$(uptime -p)
LOAD_AVG=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
MEM_USED=$(free -h | awk '/^Mem:/{print $3}')
MEM_TOTAL=$(free -h | awk '/^Mem:/{print $2}')
DISK_USED=$(df -h / | awk 'NR==2{print $3}')
DISK_TOTAL=$(df -h / | awk 'NR==2{print $2}')
DATE_STR=$(date '+%Y-%m-%d %H:%M:%S %Z')
WG_INSTALLED=$(wg --version 2>/dev/null | head -1)

echo -e "${CYAN}[2/5] Recopilando estado de WireGuard...${NC}"
WG_ACTIVE=false
WG_IP=""
WG_PORT=""
WG_PUBKEY=""
if ip link show "$WG_IFACE" &>/dev/null; then
  WG_ACTIVE=true
  WG_IP=$(ip addr show "$WG_IFACE" 2>/dev/null | grep "inet " | awk '{print $2}')
  WG_PORT=$(wg show "$WG_IFACE" listen-port 2>/dev/null)
  WG_PUBKEY=$(wg show "$WG_IFACE" public-key 2>/dev/null)
fi

echo -e "${CYAN}[3/5] Recopilando información de peers...${NC}"
declare -a PEER_KEYS PEER_ENDPOINTS PEER_ALLOWED_IPS PEER_LAST_HS PEER_RX PEER_TX PEER_KEEPALIVE
PEER_COUNT=0
ACTIVE_COUNT=0
INACTIVE_COUNT=0
NEVER_COUNT=0
TOTAL_RX=0
TOTAL_TX=0
NOW=$(date +%s)

if $WG_ACTIVE; then
  while IFS=$'\t' read -r key psk endpoint allowed_ips last_hs rx tx keepalive; do
    PEER_COUNT=$((PEER_COUNT + 1))
    PEER_KEYS+=("$key")
    PEER_ENDPOINTS+=("${endpoint:-(none)}")
    PEER_ALLOWED_IPS+=("$allowed_ips")
    PEER_LAST_HS+=("${last_hs:-0}")
    PEER_RX+=("${rx:-0}")
    PEER_TX+=("${tx:-0}")
    PEER_KEEPALIVE+=("${keepalive:-off}")
    TOTAL_RX=$((TOTAL_RX + ${rx:-0}))
    TOTAL_TX=$((TOTAL_TX + ${tx:-0}))
    local_status=$(peer_status_text "${last_hs:-0}")
    case "$local_status" in
      ACTIVO)        ACTIVE_COUNT=$((ACTIVE_COUNT + 1)) ;;
      INACTIVO)      INACTIVE_COUNT=$((INACTIVE_COUNT + 1)) ;;
      "SIN HANDSHAKE") NEVER_COUNT=$((NEVER_COUNT + 1)) ;;
    esac
  done < <(wg show "$WG_IFACE" dump 2>/dev/null | tail -n +2)
fi

echo -e "${CYAN}[4/5] Generando reporte TXT...${NC}"

# ════════════════════════════════════════════════════════════
# REPORTE TXT
# ════════════════════════════════════════════════════════════
{
echo "============================================================"
echo "  REPORTE WIREGUARD VPN"
echo "  Generado: ${DATE_STR}"
echo "  Servidor: ${HOSTNAME}"
echo "============================================================"
echo ""

echo "------------------------------------------------------------"
echo "  INFORMACIÓN DEL SISTEMA"
echo "------------------------------------------------------------"
echo "  Hostname:       ${HOSTNAME}"
echo "  OS:             ${OS_INFO}"
echo "  Kernel:         ${KERNEL}"
echo "  WireGuard:      ${WG_INSTALLED}"
echo "  Uptime:         ${UPTIME_STR}"
echo "  Carga (1/5/15): ${LOAD_AVG}"
echo "  Memoria:        ${MEM_USED} / ${MEM_TOTAL}"
echo "  Disco (/):      ${DISK_USED} / ${DISK_TOTAL}"
echo ""

echo "------------------------------------------------------------"
echo "  ESTADO WIREGUARD: ${WG_IFACE}"
echo "------------------------------------------------------------"
if $WG_ACTIVE; then
  echo "  Estado:         ACTIVO"
  echo "  IP VPN:         ${WG_IP}"
  echo "  Puerto:         ${WG_PORT}"
  echo "  Clave pública:  ${WG_PUBKEY}"
else
  echo "  Estado:         INACTIVO"
fi
echo ""

echo "------------------------------------------------------------"
echo "  RESUMEN DE PEERS"
echo "------------------------------------------------------------"
echo "  Total peers:       ${PEER_COUNT}"
echo "  Activos (< 3min):  ${ACTIVE_COUNT}"
echo "  Inactivos:         ${INACTIVE_COUNT}"
echo "  Sin handshake:     ${NEVER_COUNT}"
echo "  Total RX:          $(format_bytes $TOTAL_RX)"
echo "  Total TX:          $(format_bytes $TOTAL_TX)"
echo ""

echo "------------------------------------------------------------"
echo "  DETALLE DE PEERS"
echo "------------------------------------------------------------"
for i in "${!PEER_KEYS[@]}"; do
  num=$((i + 1))
  local_status=$(peer_status_text "${PEER_LAST_HS[$i]}")
  ago=$(format_time_ago "${PEER_LAST_HS[$i]}")
  echo ""
  echo "  [Peer ${num}]"
  echo "  Estado:       ${local_status}"
  echo "  IP Asignada:  ${PEER_ALLOWED_IPS[$i]}"
  echo "  Endpoint:     ${PEER_ENDPOINTS[$i]}"
  echo "  Último HS:    ${ago}"
  echo "  RX Recibido:  $(format_bytes ${PEER_RX[$i]})"
  echo "  TX Enviado:   $(format_bytes ${PEER_TX[$i]})"
  echo "  Keepalive:    ${PEER_KEEPALIVE[$i]}"
  echo "  Clave:        ${PEER_KEYS[$i]}"
done
echo ""

echo "------------------------------------------------------------"
echo "  TABLA DE RUTAS (${WG_IFACE})"
echo "------------------------------------------------------------"
ip route show | grep "$WG_IFACE" 2>/dev/null || echo "  Sin rutas"
echo ""

echo "------------------------------------------------------------"
echo "  wg show ${WG_IFACE} (salida completa)"
echo "------------------------------------------------------------"
wg show "$WG_IFACE" 2>/dev/null || echo "  Interfaz inactiva"
echo ""

echo "============================================================"
echo "  FIN DEL REPORTE"
echo "  ${DATE_STR}"
echo "============================================================"
} > "$REPORT_TXT"

echo -e "${CYAN}[5/5] Generando reporte Markdown...${NC}"

# ════════════════════════════════════════════════════════════
# REPORTE MARKDOWN
# ════════════════════════════════════════════════════════════
{
echo "# 📊 Reporte WireGuard VPN"
echo ""
echo "> **Generado:** ${DATE_STR}  "
echo "> **Servidor:** \`${HOSTNAME}\`  "
echo "> **Interfaz:** \`${WG_IFACE}\`"
echo ""
echo "---"
echo ""

echo "## 🖥️ Sistema"
echo ""
echo "| Parámetro | Valor |"
echo "|-----------|-------|"
echo "| Hostname | \`${HOSTNAME}\` |"
echo "| OS | ${OS_INFO} |"
echo "| Kernel | \`${KERNEL}\` |"
echo "| WireGuard | \`${WG_INSTALLED}\` |"
echo "| Uptime | ${UPTIME_STR} |"
echo "| Carga (1/5/15) | \`${LOAD_AVG}\` |"
echo "| Memoria | ${MEM_USED} / ${MEM_TOTAL} |"
echo "| Disco (/) | ${DISK_USED} / ${DISK_TOTAL} |"
echo ""

echo "## 🔐 Estado WireGuard (\`${WG_IFACE}\`)"
echo ""
if $WG_ACTIVE; then
  echo "> ✅ **ACTIVO**"
  echo ""
  echo "| Parámetro | Valor |"
  echo "|-----------|-------|"
  echo "| IP VPN | \`${WG_IP}\` |"
  echo "| Puerto | \`${WG_PORT}\` |"
  echo "| Clave pública | \`${WG_PUBKEY}\` |"
else
  echo "> ❌ **INACTIVO** — La interfaz \`${WG_IFACE}\` no está disponible"
fi
echo ""

echo "## 👥 Resumen de Peers"
echo ""
echo "| Estado | Cantidad |"
echo "|--------|----------|"
echo "| ✅ Activos (< 3 min) | **${ACTIVE_COUNT}** |"
echo "| 🔴 Inactivos | **${INACTIVE_COUNT}** |"
echo "| ⚪ Sin handshake | **${NEVER_COUNT}** |"
echo "| **Total** | **${PEER_COUNT}** |"
echo ""
echo "| Métrica | Valor |"
echo "|---------|-------|"
echo "| Total recibido ↓ | $(format_bytes $TOTAL_RX) |"
echo "| Total enviado ↑ | $(format_bytes $TOTAL_TX) |"
echo ""

echo "## 📋 Detalle de Peers"
echo ""
echo "| # | IP Asignada | Estado | Endpoint | Último HS | ↓ RX | ↑ TX |"
echo "|---|-------------|--------|----------|-----------|------|------|"
for i in "${!PEER_KEYS[@]}"; do
  num=$((i + 1))
  local_status=$(peer_status_text "${PEER_LAST_HS[$i]}")
  ago=$(format_time_ago "${PEER_LAST_HS[$i]}")
  case "$local_status" in
    ACTIVO)          icon="✅" ;;
    INACTIVO)        icon="🔴" ;;
    "SIN HANDSHAKE") icon="⚪" ;;
    *)               icon="❓" ;;
  esac
  ip_clean=$(echo "${PEER_ALLOWED_IPS[$i]}" | cut -d'/' -f1)
  endpoint="${PEER_ENDPOINTS[$i]}"
  [ "$endpoint" = "(none)" ] && endpoint="—"
  echo "| ${num} | \`${ip_clean}\` | ${icon} ${local_status} | \`${endpoint}\` | ${ago} | $(format_bytes ${PEER_RX[$i]}) | $(format_bytes ${PEER_TX[$i]}) |"
done
echo ""

echo "---"
echo ""
echo "*Reporte generado automáticamente por \`generate-report.sh\`*"
} > "$REPORT_MD"

# ── Resultado ─────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✓ Reporte generado exitosamente                         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}  Archivos generados:${NC}"
echo -e "  📄 TXT: ${CYAN}${REPORT_TXT}${NC}"
echo -e "  📝 MD:  ${CYAN}${REPORT_MD}${NC}"
echo ""
echo -e "${BLUE}  Resumen:${NC}"
echo -e "  Peers totales:  ${PEER_COUNT}"
echo -e "  Activos:        ${GREEN}${ACTIVE_COUNT}${NC}"
echo -e "  Inactivos:      ${YELLOW}${INACTIVE_COUNT}${NC}"
echo -e "  Sin HS:         ${INACTIVE_COUNT}"
echo -e "  Total RX:       $(format_bytes $TOTAL_RX)"
echo -e "  Total TX:       $(format_bytes $TOTAL_TX)"
echo ""
echo -e "${GRAY}  Para ver el reporte: cat ${REPORT_TXT}${NC}"
echo -e "${GRAY}  Reportes previos:    ls -la ${OUTPUT_DIR}/${NC}"
