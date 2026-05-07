#!/bin/bash

################################################################################
# Script: local/stop-server.sh
# Descripción: Detiene el servidor WireGuard (wg0) en el servidor remoto vía SSH
# Contexto: LOCAL — Ejecutar en tu máquina
# Uso: ./scripts/local/stop-server.sh
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
echo "║   Deteniendo Servidor WireGuard (Remoto)                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Confirmación ─────────────────────────────────────────────
echo -e "${YELLOW}  ⚠ Esto desconectará a todos los peers VPN del servidor.${NC}"
echo -e "${YELLOW}  Servidor: ${PUBLIC_IP} | Interface: ${WG_INTERFACE}${NC}"
echo ""
read -p "  ¿Estás seguro? (s/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[sS]$ ]]; then
  echo -e "${BLUE}  Operación cancelada.${NC}"
  exit 0
fi
echo ""

# ── Verificar si WireGuard está activo ───────────────────────
echo -e "${CYAN}[1/2] Verificando estado de WireGuard...${NC}"
WG_RUNNING=$(ssh -i "$SSH_KEY" -p "$SSH_PORT" \
                 -o ConnectTimeout=10 \
                 -o StrictHostKeyChecking=accept-new \
                 "${SSH_USER}@${PUBLIC_IP}" \
                 "ip link show ${WG_INTERFACE} 2>/dev/null && echo ACTIVE || echo INACTIVE")

if echo "$WG_RUNNING" | grep -q "INACTIVE"; then
  echo -e "${YELLOW}  ⚠ WireGuard (${WG_INTERFACE}) ya estaba inactivo.${NC}"
  exit 0
fi
echo -e "${GREEN}  ✓ WireGuard activo, procediendo a detener...${NC}"
echo ""

# ── Detener WireGuard ─────────────────────────────────────────
echo -e "${CYAN}[2/2] Deteniendo WireGuard en el servidor...${NC}"
ssh -i "$SSH_KEY" -p "$SSH_PORT" \
    -o ConnectTimeout=15 \
    -o StrictHostKeyChecking=accept-new \
    "${SSH_USER}@${PUBLIC_IP}" \
    "sudo wg-quick down ${WG_INTERFACE} 2>&1"

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}✓ Servidor WireGuard detenido exitosamente.${NC}"
else
  echo -e "${RED}✗ Error al detener WireGuard (código: $EXIT_CODE)${NC}"
  exit 1
fi
