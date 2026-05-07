#!/bin/bash

################################################################################
# Script: 01-start-vpn-backend.sh
# Descripción: Inicia el servidor backend de la aplicación de gestión VPN
# Ubicación: scripts/01-start-vpn-backend.sh
# Uso: ./scripts/01-start-vpn-backend.sh [dev|prod]
# Parámetros:
#   dev  - Inicia en modo desarrollo con nodemon (default)
#   prod - Inicia en modo producción
################################################################################

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$PROJECT_ROOT/vpn-app/backend"
LOG_FILE="$PROJECT_ROOT/logs/backend.log"
LOG_DIR="$PROJECT_ROOT/logs"

# Crear directorio de logs si no existe
mkdir -p "$LOG_DIR"

# Modo de ejecución (dev o prod)
MODE="${1:-dev}"

# Banner
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   VPN Backend Server - Initialization Script              ║"
echo "║   Iniciando servidor backend de gestión VPN               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verificar que Node.js está instalado
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Error: Node.js no está instalado${NC}"
    echo "   Por favor instala Node.js desde https://nodejs.org"
    exit 1
fi

echo -e "${GREEN}✓${NC} Node.js detectado: $(node --version)"

# Verificar que npm está instalado
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ Error: npm no está instalado${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} npm detectado: $(npm --version)"

# Cambiar al directorio del backend
if [ ! -d "$BACKEND_DIR" ]; then
    echo -e "${RED}❌ Error: Directorio del backend no encontrado en $BACKEND_DIR${NC}"
    exit 1
fi

cd "$BACKEND_DIR" || exit 1
echo -e "${GREEN}✓${NC} Directorio de backend: $BACKEND_DIR"

# Verificar e instalar dependencias
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}⚠ node_modules no encontrado, instalando dependencias...${NC}"
    npm install
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Error al instalar dependencias${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓${NC} Dependencias verificadas"

# Inicializar base de datos si no existe
if [ ! -f "database/vpn.db" ]; then
    echo -e "${YELLOW}⚠ Base de datos no encontrada, inicializando...${NC}"
    npm run init-db
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Error al inicializar la base de datos${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} Base de datos inicializada"
fi

# Iniciar el servidor
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Iniciando servidor backend...${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ "$MODE" == "dev" ]; then
    echo -e "${BLUE}Modo: DESARROLLO (con nodemon)${NC}"
    echo -e "${BLUE}Puerto: 3001 (configurable en .env)${NC}"
    echo -e "${BLUE}Para detener, presiona Ctrl+C${NC}"
    echo ""
    
    npm run dev 2>&1 | tee -a "$LOG_FILE"
    
elif [ "$MODE" == "prod" ]; then
    echo -e "${BLUE}Modo: PRODUCCIÓN${NC}"
    echo -e "${BLUE}Puerto: 3001 (configurable en .env)${NC}"
    echo -e "${BLUE}Para detener, presiona Ctrl+C${NC}"
    echo ""
    
    npm start 2>&1 | tee -a "$LOG_FILE"
else
    echo -e "${RED}❌ Modo desconocido: $MODE${NC}"
    echo "   Uso: ./scripts/01-start-vpn-backend.sh [dev|prod]"
    exit 1
fi

# Si el script llega aquí, significa que fue detenido
echo ""
echo -e "${YELLOW}⚠ Servidor backend detenido${NC}"
echo "   Revisa los logs en: $LOG_FILE"
