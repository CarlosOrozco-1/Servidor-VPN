#!/bin/bash

################################################################################
# Script: local/deploy-server-scripts.sh
# Descripción: Copia los scripts de servidor al servidor remoto vía SCP
# Contexto: LOCAL — Ejecutar en tu máquina
# Uso: ./scripts/local/deploy-server-scripts.sh
#
# Copia scripts/server/*.sh al servidor en ~/vpn-scripts/
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
SERVER_SCRIPTS_DIR="$PROJECT_ROOT/scripts/server"

# Destino en el servidor
REMOTE_DIR="~/vpn-scripts"

# ── Cargar variables de entorno ──────────────────────────────
if [ ! -f "$ENV_FILE" ]; then
  echo -e "${RED}❌ No se encontró: ${ENV_FILE}${NC}"
  exit 1
fi
source "$ENV_FILE"

SSH_KEY="$PROJECT_ROOT/$SSH_KEY_PATH"
chmod 600 "$SSH_KEY"

# ── Banner ───────────────────────────────────────────────────
echo -e "${MAGENTA}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Deploy: Scripts al Servidor VPN                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${BLUE}  Origen:   ${GREEN}scripts/server/${NC}"
echo -e "${BLUE}  Destino:  ${GREEN}${SSH_USER}@${PUBLIC_IP}:${REMOTE_DIR}${NC}"
echo ""

# ── Crear directorio en el servidor ─────────────────────────
echo -e "${CYAN}[1/3] Creando directorio en el servidor...${NC}"
ssh -i "$SSH_KEY" -p "$SSH_PORT" \
    -o ConnectTimeout=10 \
    -o StrictHostKeyChecking=accept-new \
    "${SSH_USER}@${PUBLIC_IP}" \
    "mkdir -p ${REMOTE_DIR}" 2>&1

if [ $? -ne 0 ]; then
  echo -e "${RED}  ✗ No se pudo crear el directorio en el servidor.${NC}"
  exit 1
fi
echo -e "${GREEN}  ✓ Directorio ${REMOTE_DIR} listo${NC}"
echo ""

# ── Copiar scripts ───────────────────────────────────────────
echo -e "${CYAN}[2/3] Copiando scripts al servidor...${NC}"
scp -i "$SSH_KEY" -P "$SSH_PORT" \
    -o StrictHostKeyChecking=accept-new \
    "$SERVER_SCRIPTS_DIR"/*.sh \
    "${SSH_USER}@${PUBLIC_IP}:${REMOTE_DIR}/"

if [ $? -ne 0 ]; then
  echo -e "${RED}  ✗ Error al copiar los scripts.${NC}"
  exit 1
fi
echo -e "${GREEN}  ✓ Scripts copiados exitosamente${NC}"
echo ""

# ── Dar permisos de ejecución ────────────────────────────────
echo -e "${CYAN}[3/3] Asignando permisos de ejecución...${NC}"
ssh -i "$SSH_KEY" -p "$SSH_PORT" \
    -o ConnectTimeout=10 \
    -o StrictHostKeyChecking=accept-new \
    "${SSH_USER}@${PUBLIC_IP}" \
    "chmod +x ${REMOTE_DIR}/*.sh && ls -la ${REMOTE_DIR}/"

if [ $? -ne 0 ]; then
  echo -e "${RED}  ✗ Error asignando permisos.${NC}"
  exit 1
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✓ Scripts desplegados exitosamente                      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}  Cómo usar los scripts en el servidor:${NC}"
echo ""
echo -e "  1. Conéctate al servidor:"
echo -e "     ${YELLOW}./scripts/local/connect-server.sh${NC}"
echo ""
echo -e "  2. Dentro del servidor, ejecuta:"
echo -e "     ${CYAN}sudo ~/vpn-scripts/wireguard-status.sh${NC}       # Reporte rápido"
echo -e "     ${CYAN}sudo ~/vpn-scripts/monitor-wireguard.sh${NC}      # Monitor continuo"
echo ""
echo -e "  O desde tu máquina (sin entrar al servidor):"
echo -e "     ${YELLOW}./scripts/local/monitor-remote.sh${NC}"
