#!/bin/bash

################################################################################
# Script: local/connect-server.sh
# Descripción: Abre una sesión SSH interactiva al servidor VPN
# Contexto: LOCAL — Ejecutar en tu máquina
# Uso: ./scripts/local/connect-server.sh
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
  echo -e "${RED}❌ No se encontró el archivo de configuración:${NC}"
  echo -e "   ${YELLOW}$ENV_FILE${NC}"
  echo -e "   Crea el archivo con las credenciales del servidor."
  exit 1
fi

source "$ENV_FILE"

# Ruta absoluta a la llave SSH
SSH_KEY="$PROJECT_ROOT/$SSH_KEY_PATH"

# ── Validaciones ─────────────────────────────────────────────
if [ ! -f "$SSH_KEY" ]; then
  echo -e "${RED}❌ Llave SSH no encontrada: ${SSH_KEY}${NC}"
  exit 1
fi

# Asegurar permisos correctos en la llave
chmod 600 "$SSH_KEY"

# ── Banner ───────────────────────────────────────────────────
echo -e "${MAGENTA}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Conectando al Servidor VPN                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${BLUE}  Servidor:  ${GREEN}${PUBLIC_IP}${NC}"
echo -e "${BLUE}  Usuario:   ${GREEN}${SSH_USER}${NC}"
echo -e "${BLUE}  Puerto:    ${GREEN}${SSH_PORT}${NC}"
echo -e "${BLUE}  Llave SSH: ${GREEN}${SSH_KEY_PATH}${NC}"
echo ""
echo -e "${YELLOW}  Iniciando sesión SSH... (Ctrl+D o 'exit' para salir)${NC}"
echo ""

# ── Conectar al servidor ──────────────────────────────────────
ssh -i "$SSH_KEY" \
    -p "$SSH_PORT" \
    -o StrictHostKeyChecking=accept-new \
    -o ConnectTimeout=10 \
    "${SSH_USER}@${PUBLIC_IP}"

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}✓ Sesión SSH cerrada correctamente.${NC}"
else
  echo -e "${RED}✗ La conexión SSH terminó con error (código: $EXIT_CODE).${NC}"
  echo -e "${YELLOW}  Verifica que el servidor esté encendido y accesible.${NC}"
fi
