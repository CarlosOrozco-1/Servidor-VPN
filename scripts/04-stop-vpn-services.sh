#!/bin/bash

################################################################################
# Script: 04-stop-vpn-services.sh
# Descripción: Detiene todos los servicios de la aplicación VPN
# Ubicación: scripts/04-stop-vpn-services.sh
# Uso: ./scripts/04-stop-vpn-services.sh [backend|frontend|all]
# Parámetros:
#   backend  - Detiene solo el backend
#   frontend - Detiene solo el frontend
#   all      - Detiene todos los servicios (default)
################################################################################

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_ROOT/logs"
STOP_LOG="$LOG_DIR/services-stop.log"

# Crear directorio de logs
mkdir -p "$LOG_DIR"

# Modo de parada
MODE="${1:-all}"

# Función para obtener timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Función para registrar en log
log_event() {
    local message="$1"
    echo "[$(get_timestamp)] $message" >> "$STOP_LOG"
}

# Banner
echo -e "${MAGENTA}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   VPN Services - Stop Script                              ║"
echo "║   Script para detener servicios VPN                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Función para detener el backend
stop_backend() {
    echo -e "${BLUE}┌─ Deteniendo Backend ──────────────────────────────────────┐${NC}"
    
    # Buscar procesos Node.js en el directorio del backend
    local backend_pids=$(lsof -ti:3001 2>/dev/null)
    
    if [ -n "$backend_pids" ]; then
        echo -e "│  Proceso(s) encontrado(s): ${YELLOW}$backend_pids${NC}"
        
        for pid in $backend_pids; do
            echo -e "│  Deteniendo PID: ${YELLOW}$pid${NC}"
            kill -SIGTERM "$pid" 2>/dev/null
            
            # Esperar 2 segundos
            sleep 2
            
            # Si sigue corriendo, fuerza kill
            if kill -0 "$pid" 2>/dev/null; then
                echo -e "│  ${YELLOW}Forzando kill${NC} al proceso $pid..."
                kill -9 "$pid" 2>/dev/null
            fi
        done
        
        echo -e "│  ${GREEN}✓ Backend detenido exitosamente${NC}"
        log_event "Backend stopped successfully (PID: $backend_pids)"
    else
        echo -e "│  ${YELLOW}⚠ No se encontraron procesos en puerto 3001${NC}"
        log_event "Backend not running on port 3001"
    fi
    
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Función para detener el frontend
stop_frontend() {
    echo -e "${BLUE}┌─ Deteniendo Frontend ─────────────────────────────────────┐${NC}"
    
    # Buscar procesos Vite/node en puerto 3000
    local frontend_pids=$(lsof -ti:3000 2>/dev/null)
    
    if [ -n "$frontend_pids" ]; then
        echo -e "│  Proceso(s) encontrado(s): ${YELLOW}$frontend_pids${NC}"
        
        for pid in $frontend_pids; do
            echo -e "│  Deteniendo PID: ${YELLOW}$pid${NC}"
            kill -SIGTERM "$pid" 2>/dev/null
            
            # Esperar 2 segundos
            sleep 2
            
            # Si sigue corriendo, fuerza kill
            if kill -0 "$pid" 2>/dev/null; then
                echo -e "│  ${YELLOW}Forzando kill${NC} al proceso $pid..."
                kill -9 "$pid" 2>/dev/null
            fi
        done
        
        echo -e "│  ${GREEN}✓ Frontend detenido exitosamente${NC}"
        log_event "Frontend stopped successfully (PID: $frontend_pids)"
    else
        echo -e "│  ${YELLOW}⚠ No se encontraron procesos en puerto 3000${NC}"
        log_event "Frontend not running on port 3000"
    fi
    
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Función para mostrar estado actual
show_current_status() {
    echo -e "${BLUE}┌─ Estado Actual de Puertos ────────────────────────────────┐${NC}"
    
    # Verificar puerto 3001 (backend)
    if lsof -ti:3001 > /dev/null 2>&1; then
        echo -e "│  Puerto 3001 (Backend):  ${GREEN}● EN USO${NC}"
    else
        echo -e "│  Puerto 3001 (Backend):  ${YELLOW}○ DISPONIBLE${NC}"
    fi
    
    # Verificar puerto 3000 (frontend)
    if lsof -ti:3000 > /dev/null 2>&1; then
        echo -e "│  Puerto 3000 (Frontend): ${GREEN}● EN USO${NC}"
    else
        echo -e "│  Puerto 3000 (Frontend): ${YELLOW}○ DISPONIBLE${NC}"
    fi
    
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Verificar que lsof está disponible
if ! command -v lsof &> /dev/null; then
    echo -e "${YELLOW}⚠ Advertencia: 'lsof' no está instalado${NC}"
    echo "   Instalalo con: sudo apt install lsof"
    echo ""
fi

# Ejecutar según modo
case "$MODE" in
    backend)
        stop_backend
        show_current_status
        ;;
        
    frontend)
        stop_frontend
        show_current_status
        ;;
        
    all)
        stop_backend
        stop_frontend
        show_current_status
        ;;
        
    *)
        echo -e "${RED}❌ Modo desconocido: $MODE${NC}"
        echo ""
        echo -e "${BLUE}Uso:${NC}"
        echo "  ./scripts/04-stop-vpn-services.sh backend  - Detiene solo backend"
        echo "  ./scripts/04-stop-vpn-services.sh frontend - Detiene solo frontend"
        echo "  ./scripts/04-stop-vpn-services.sh all      - Detiene todos (default)"
        exit 1
        ;;
esac

# Resumen final
echo -e "${GREEN}✓ Operación completada${NC}"
echo "   Logs disponibles en: $STOP_LOG"
