#!/bin/bash

################################################################################
# Script: local/start-server.sh
# Descripción: Inicia el servidor WireGuard (wg0) en el servidor remoto vía SSH
# Contexto: LOCAL — Ejecutar en tu máquina
# Uso: ./scripts/local/start-server.sh
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
echo "║   Iniciando Servidor WireGuard (Remoto)                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${BLUE}  Servidor:   ${GREEN}${PUBLIC_IP}:${SSH_PORT}${NC}"
echo -e "${BLUE}  Interface:  ${GREEN}${WG_INTERFACE}${NC}"
echo -e "${BLUE}  VPN Port:   ${GREEN}${LISTEN_PORT}${NC}"
echo ""

# ── Verificar conectividad primero ───────────────────────────
echo -e "${CYAN}[1/3] Verificando conectividad con el servidor...${NC}"
if ! ssh -i "$SSH_KEY" -p "$SSH_PORT" \
         -o ConnectTimeout=10 \
         -o StrictHostKeyChecking=accept-new \
         -o BatchMode=yes \
         "${SSH_USER}@${PUBLIC_IP}" "echo OK" &>/dev/null; then
  echo -e "${RED}  ✗ No se pudo conectar al servidor ${PUBLIC_IP}${NC}"
  echo -e "${YELLOW}  Verifica que el servidor esté encendido.${NC}"
  exit 1
fi
echo -e "${GREEN}  ✓ Servidor alcanzable${NC}"
echo ""

# ── Verificar estado actual de WireGuard ─────────────────────
echo -e "${CYAN}[2/3] Verificando estado actual de WireGuard...${NC}"
WG_RUNNING=$(ssh -i "$SSH_KEY" -p "$SSH_PORT" \
                 -o ConnectTimeout=10 \
                 -o StrictHostKeyChecking=accept-new \
                 "${SSH_USER}@${PUBLIC_IP}" \
                 "ip link show ${WG_INTERFACE} 2>/dev/null && echo ACTIVE || echo INACTIVE")

if echo "$WG_RUNNING" | grep -q "ACTIVE"; then
  echo -e "${YELLOW}  ⚠ WireGuard (${WG_INTERFACE}) ya está activo en el servidor.${NC}"
  echo ""
  echo -e "${BLUE}  Estado actual:${NC}"
  ssh -i "$SSH_KEY" -p "$SSH_PORT" \
      -o ConnectTimeout=10 \
      -o StrictHostKeyChecking=accept-new \
      "${SSH_USER}@${PUBLIC_IP}" \
      "sudo wg show ${WG_INTERFACE} 2>/dev/null | head -20"
  echo ""
  echo -e "${GREEN}  El servidor ya estaba corriendo. No se realizaron cambios.${NC}"
  exit 0
fi
echo -e "${GREEN}  ✓ WireGuard está inactivo, procediendo a iniciar...${NC}"
echo ""

# ── Iniciar WireGuard ─────────────────────────────────────────
echo -e "${CYAN}[3/3] Iniciando WireGuard en el servidor...${NC}"
ssh -i "$SSH_KEY" -p "$SSH_PORT" \
    -o ConnectTimeout=15 \
    -o StrictHostKeyChecking=accept-new \
    "${SSH_USER}@${PUBLIC_IP}" \
    "sudo wg-quick up ${WG_INTERFACE} 2>&1"

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║   ✓ Servidor WireGuard iniciado exitosamente              ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${BLUE}  Endpoint público:  ${GREEN}${PUBLIC_IP}:${LISTEN_PORT}${NC}"
  echo -e "${BLUE}  Clave pública:     ${GREEN}${SERVER_PUBLIC_KEY:0:25}...${NC}"
  echo ""
  echo -e "${CYAN}  Tip: Para monitorear los peers conectados ejecuta:${NC}"
  echo -e "  ${YELLOW}./scripts/local/monitor-remote.sh${NC}"
else
  echo -e "${RED}✗ Error al iniciar WireGuard (código: $EXIT_CODE)${NC}"
  echo -e "${YELLOW}  Verifica que /etc/wireguard/${WG_INTERFACE}.conf exista en el servidor.${NC}"
  exit 1
fi
