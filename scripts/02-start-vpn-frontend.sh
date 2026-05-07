#!/bin/bash

################################################################################
# Script: 02-start-vpn-frontend.sh
# Descripción: Inicia el servidor frontend (Vite) de la aplicación de gestión VPN
# Ubicación: scripts/02-start-vpn-frontend.sh
# Uso: ./scripts/02-start-vpn-frontend.sh [dev|build|preview]
# Parámetros:
#   dev     - Inicia servidor de desarrollo Vite (default)
#   build   - Compila para producción
#   preview - Previsualiza build de producción
################################################################################

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FRONTEND_DIR="$PROJECT_ROOT/vpn-app/frontend"
LOG_FILE="$PROJECT_ROOT/logs/frontend.log"
LOG_DIR="$PROJECT_ROOT/logs"
VITE_PORT="${VITE_PORT:-3000}"

# Crear directorio de logs si no existe
mkdir -p "$LOG_DIR"

# Modo de ejecución (dev, build, preview)
MODE="${1:-dev}"

# Banner
echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   VPN Frontend Server - Initialization Script             ║"
echo "║   Iniciando servidor frontend de gestión VPN              ║"
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

# Cambiar al directorio del frontend
if [ ! -d "$FRONTEND_DIR" ]; then
    echo -e "${RED}❌ Error: Directorio del frontend no encontrado en $FRONTEND_DIR${NC}"
    exit 1
fi

cd "$FRONTEND_DIR" || exit 1
echo -e "${GREEN}✓${NC} Directorio de frontend: $FRONTEND_DIR"

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

# Mostrar configuración
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Configuración del servidor frontend:${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

case "$MODE" in
    dev)
        echo -e "${BLUE}Modo: DESARROLLO${NC}"
        echo -e "${BLUE}Puerto: $VITE_PORT${NC}"
        echo -e "${BLUE}URL: ${CYAN}http://localhost:$VITE_PORT${NC}"
        echo -e "${BLUE}Backend URL esperado: ${CYAN}http://localhost:3001${NC}"
        echo -e "${BLUE}Para detener, presiona Ctrl+C${NC}"
        echo ""
        echo -e "${YELLOW}Iniciando servidor de desarrollo Vite...${NC}"
        npm run dev 2>&1 | tee -a "$LOG_FILE"
        ;;
        
    build)
        echo -e "${BLUE}Modo: COMPILACIÓN PRODUCCIÓN${NC}"
        echo -e "${BLUE}Directorio output: dist/${NC}"
        echo ""
        echo -e "${YELLOW}Compilando aplicación para producción...${NC}"
        npm run build
        if [ $? -eq 0 ]; then
            echo ""
            echo -e "${GREEN}✓ Compilación completada exitosamente${NC}"
            echo -e "${GREEN}✓ Archivos disponibles en: dist/${NC}"
            echo ""
            echo -e "${BLUE}Próximos pasos:${NC}"
            echo "  1. Usar 'npm run preview' para visualizar la compilación"
            echo "  2. Copiar contenido de 'dist/' a servidor web (nginx, Apache, etc)"
        else
            echo -e "${RED}❌ Error durante la compilación${NC}"
            exit 1
        fi
        ;;
        
    preview)
        echo -e "${BLUE}Modo: PREVISUALIZACIÓN PRODUCCIÓN${NC}"
        echo -e "${BLUE}Puerto: 4173${NC}"
        echo -e "${BLUE}URL: ${CYAN}http://localhost:4173${NC}"
        echo ""
        
        # Verificar si existe el directorio dist
        if [ ! -d "dist" ]; then
            echo -e "${YELLOW}⚠ El directorio 'dist' no existe. Compilando primero...${NC}"
            npm run build
        fi
        
        echo -e "${YELLOW}Iniciando previsualización...${NC}"
        npm run preview 2>&1 | tee -a "$LOG_FILE"
        ;;
        
    *)
        echo -e "${RED}❌ Modo desconocido: $MODE${NC}"
        echo ""
        echo -e "${BLUE}Uso:${NC}"
        echo "  ./scripts/02-start-vpn-frontend.sh dev      - Servidor desarrollo"
        echo "  ./scripts/02-start-vpn-frontend.sh build    - Compilar para producción"
        echo "  ./scripts/02-start-vpn-frontend.sh preview  - Previsualizar producción"
        exit 1
        ;;
esac

echo ""
echo -e "${YELLOW}⚠ Servidor frontend detenido${NC}"
echo "   Revisa los logs en: $LOG_FILE"
