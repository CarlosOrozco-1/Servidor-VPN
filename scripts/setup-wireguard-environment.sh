#!/bin/bash

################################################################################
# Script: setup-wireguard-environment.sh
# Descripción: Script de setup para preparar el entorno WireGuard
# Ubicación: scripts/setup-wireguard-environment.sh
# Uso: sudo ./scripts/setup-wireguard-environment.sh
# 
# Este script verifica e instala las dependencias necesarias para WireGuard
################################################################################

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Banner
echo -e "${MAGENTA}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   WireGuard Environment Setup                             ║"
echo "║   Setup del Entorno WireGuard                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verificar si es root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Este script requiere permisos root${NC}"
    echo "   Usa: sudo ./scripts/setup-wireguard-environment.sh"
    exit 1
fi

# Detectar sistema operativo
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}❌ No se puede detectar el sistema operativo${NC}"
    exit 1
fi

echo -e "${BLUE}Detectado: $OS ($VERSION_ID)${NC}"
echo ""

# Actualizar repositorios
echo -e "${YELLOW}Actualizando repositorios...${NC}"
apt update

echo ""
echo -e "${YELLOW}┌─ Instalando Dependencias ─────────────────────────────────┐${NC}"

# Instalar WireGuard
echo -e "│  Instalando WireGuard..."
if ! apt install -y wireguard wireguard-tools > /dev/null 2>&1; then
    echo -e "│  ${RED}✗ Error instalando WireGuard${NC}"
    exit 1
fi
echo -e "│  ${GREEN}✓ WireGuard instalado${NC}"

# Verificar instalación
if command -v wg &> /dev/null; then
    local wg_version=$(wg --version | head -n1)
    echo -e "│  ${GREEN}✓ $wg_version${NC}"
else
    echo -e "│  ${RED}✗ WireGuard no se instaló correctamente${NC}"
    exit 1
fi

# Instalar herramientas adicionales (opcionales)
echo -e "│"
echo -e "│  Instalando herramientas adicionales..."

# lsof
apt install -y lsof > /dev/null 2>&1
echo -e "│  ${GREEN}✓ lsof${NC}"

# curl
apt install -y curl > /dev/null 2>&1
echo -e "│  ${GREEN}✓ curl${NC}"

# net-tools
apt install -y net-tools > /dev/null 2>&1
echo -e "│  ${GREEN}✓ net-tools${NC}"

echo -e "│"
echo -e "${YELLOW}└────────────────────────────────────────────────────────────┘${NC}"

echo ""
echo -e "${BLUE}┌─ Configuración del Sistema ───────────────────────────────┐${NC}"

# Habilitar IP forwarding
echo -e "│  Habilitando IP Forwarding..."
if grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo -e "│  ${GREEN}✓ Ya estaba habilitado${NC}"
else
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p > /dev/null
    echo -e "│  ${GREEN}✓ IP Forwarding habilitado${NC}"
fi

# Crear directorio de configuración si no existe
if [ ! -d /etc/wireguard ]; then
    echo -e "│  Creando directorio /etc/wireguard..."
    mkdir -p /etc/wireguard
    chmod 700 /etc/wireguard
    echo -e "│  ${GREEN}✓ Directorio creado${NC}"
fi

echo -e "│"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"

echo ""
echo -e "${GREEN}✓ Setup completado exitosamente${NC}"
echo ""
echo -e "${BLUE}Próximos pasos:${NC}"
echo "  1. Crear/editar configuración: sudo nano /etc/wireguard/wg0.conf"
echo "  2. Iniciar WireGuard: sudo ./scripts/06-start-wireguard-server.sh start"
echo "  3. Verificar estado: sudo ./scripts/06-start-wireguard-server.sh status"
echo "  4. Monitorear: sudo ./scripts/07-monitor-wireguard-peers.sh continuous"
echo ""
echo -e "${YELLOW}Comandos útiles:${NC}"
echo "  Ver configuración actual: wg show"
echo "  Ver estadísticas: wg show all"
echo "  Ver específicamente: sudo wg show wg0"
