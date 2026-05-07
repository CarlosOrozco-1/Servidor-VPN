#!/bin/bash

################################################################################
# Script: master-vpn-control.sh
# Descripción: Script maestro para controlar todos los servicios VPN
# Ubicación: scripts/master-vpn-control.sh
# Uso: ./scripts/master-vpn-control.sh [start|stop|restart|status]
#
# Este script es el punto de entrada principal para gestionar todos los
# servicios de la aplicación VPN desde una única interfaz.
################################################################################

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_ROOT/logs"
MASTER_LOG="$LOG_DIR/master-control.log"

# Crear directorio de logs
mkdir -p "$LOG_DIR"

# Función para obtener timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Función para registrar en log
log_event() {
    local message="$1"
    echo "[$(get_timestamp)] $message" >> "$MASTER_LOG"
}

# Función para mostrar menú
show_menu() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║           VPN APPLICATION - MASTER CONTROL                ║"
    echo "║     Control Central de la Aplicación de Gestión VPN       ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${BLUE}Comandos disponibles:${NC}"
    echo "  ${GREEN}start${NC}    - Inicia los servicios (backend + frontend)"
    echo "  ${GREEN}stop${NC}     - Detiene todos los servicios"
    echo "  ${GREEN}restart${NC}  - Reinicia todos los servicios"
    echo "  ${GREEN}status${NC}   - Verifica el estado de los servicios"
    echo "  ${GREEN}monitor${NC}  - Monitorea la VPN en tiempo real"
    echo "  ${GREEN}logs${NC}     - Muestra los logs más recientes"
    echo "  ${GREEN}help${NC}     - Muestra esta ayuda"
    echo ""
}

# Función para iniciar todos los servicios
start_services() {
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║   Iniciando Servicios VPN                                 ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    log_event "Starting all services"
    
    # Detectar si usar tmux o solo iniciar
    if command -v tmux &> /dev/null; then
        echo -e "${BLUE}⚙ Usando tmux para gestionar sesiones...${NC}"
        echo ""
        
        # Crear sesión tmux si no existe
        tmux has-session -t vpn-app 2>/dev/null
        if [ $? -ne 0 ]; then
            echo -e "${YELLOW}Creando nueva sesión tmux: vpn-app${NC}"
            tmux new-session -d -s vpn-app -x 200 -y 50
        fi
        
        # Backend en ventana 0
        echo -e "${BLUE}[1/2] Iniciando Backend en ventana tmux...${NC}"
        tmux send-keys -t vpn-app:0 "cd \"$PROJECT_ROOT/vpn-app/backend\" && npm run dev" Enter
        sleep 3
        
        # Frontend en ventana 1
        echo -e "${BLUE}[2/2] Iniciando Frontend en nueva ventana tmux...${NC}"
        tmux new-window -t vpn-app
        tmux send-keys -t vpn-app:1 "cd \"$PROJECT_ROOT/vpn-app/frontend\" && npm run dev" Enter
        
        echo ""
        echo -e "${GREEN}✓ Servicios iniciados en tmux${NC}"
        echo -e "${BLUE}Acceder a la sesión:${NC}"
        echo "  ${CYAN}tmux attach-session -t vpn-app${NC}"
        echo ""
        echo -e "${BLUE}URLs disponibles:${NC}"
        echo "  Frontend: ${CYAN}http://localhost:3000${NC}"
        echo "  Backend:  ${CYAN}http://localhost:3001${NC}"
        
        log_event "Services started in tmux session"
        
    else
        echo -e "${YELLOW}⚠ tmux no está disponible, usando modo directo${NC}"
        echo ""
        
        # Iniciar backend
        echo -e "${BLUE}[1/2] Iniciando Backend...${NC}"
        "$SCRIPT_DIR/01-start-vpn-backend.sh" &
        BACKEND_PID=$!
        sleep 2
        
        # Iniciar frontend
        echo -e "${BLUE}[2/2] Iniciando Frontend...${NC}"
        "$SCRIPT_DIR/02-start-vpn-frontend.sh" &
        FRONTEND_PID=$!
        
        echo ""
        echo -e "${GREEN}✓ Servicios iniciados${NC}"
        echo -e "${BLUE}PIDs:${NC}"
        echo "  Backend:  $BACKEND_PID"
        echo "  Frontend: $FRONTEND_PID"
        echo ""
        echo -e "${BLUE}URLs disponibles:${NC}"
        echo "  Frontend: ${CYAN}http://localhost:3000${NC}"
        echo "  Backend:  ${CYAN}http://localhost:3001${NC}"
        
        log_event "Services started - Backend PID: $BACKEND_PID, Frontend PID: $FRONTEND_PID"
        
        # Esperar a que se detengan
        wait
    fi
}

# Función para detener todos los servicios
stop_services() {
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║   Deteniendo Servicios VPN                                ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    log_event "Stopping all services"
    
    # Detener sesión tmux si existe
    if tmux has-session -t vpn-app 2>/dev/null; then
        echo -e "${BLUE}Terminando sesión tmux: vpn-app${NC}"
        tmux kill-session -t vpn-app
        echo -e "${GREEN}✓ Sesión tmux finalizada${NC}"
    fi
    
    # Ejecutar script de parada
    "$SCRIPT_DIR/04-stop-vpn-services.sh" all
    
    log_event "All services stopped"
}

# Función para reiniciar servicios
restart_services() {
    echo -e "${YELLOW}Reiniciando servicios...${NC}"
    echo ""
    
    log_event "Restarting all services"
    stop_services
    
    echo ""
    sleep 2
    echo ""
    
    start_services
}

# Función para mostrar estado
show_status() {
    "$SCRIPT_DIR/03-monitor-vpn-status.sh" once
}

# Función para monitoreo continuo
start_monitor() {
    "$SCRIPT_DIR/03-monitor-vpn-status.sh" continuous
}

# Función para mostrar logs
show_logs() {
    echo -e "${BLUE}┌─ Logs Recientes ──────────────────────────────────────────┐${NC}"
    echo ""
    
    if [ -f "$MASTER_LOG" ]; then
        echo -e "${YELLOW}Master Control Log:${NC}"
        tail -n 20 "$MASTER_LOG"
    fi
    
    echo ""
    
    if [ -f "$LOG_DIR/backend.log" ]; then
        echo -e "${YELLOW}Backend Log (últimas 10 líneas):${NC}"
        tail -n 10 "$LOG_DIR/backend.log"
    fi
    
    echo ""
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
}

# Función de utilidad para verificar dependencias
check_dependencies() {
    local missing_deps=()
    
    if ! command -v node &> /dev/null; then
        missing_deps+=("node (Node.js)")
    fi
    
    if ! command -v npm &> /dev/null; then
        missing_deps+=("npm")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}❌ Dependencias faltantes:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo "   - $dep"
        done
        return 1
    fi
    
    return 0
}

# Función de ayuda
show_help() {
    show_menu
    echo -e "${BLUE}Ejemplos de uso:${NC}"
    echo ""
    echo "  1. Iniciar todos los servicios:"
    echo "     ${CYAN}./scripts/master-vpn-control.sh start${NC}"
    echo ""
    echo "  2. Ver estado actual:"
    echo "     ${CYAN}./scripts/master-vpn-control.sh status${NC}"
    echo ""
    echo "  3. Monitorear en tiempo real:"
    echo "     ${CYAN}./scripts/master-vpn-control.sh monitor${NC}"
    echo ""
    echo "  4. Detener todos los servicios:"
    echo "     ${CYAN}./scripts/master-vpn-control.sh stop${NC}"
    echo ""
    echo "  5. Reiniciar todos los servicios:"
    echo "     ${CYAN}./scripts/master-vpn-control.sh restart${NC}"
    echo ""
    echo -e "${BLUE}Requisitos:${NC}"
    echo "  - Node.js 14+"
    echo "  - npm 6+"
    echo "  - Linux/macOS (bash)"
    echo ""
    echo -e "${BLUE}Directorio de logs:${NC}"
    echo "  ${CYAN}$LOG_DIR${NC}"
    echo ""
}

# Verificar argumentos
if [ $# -eq 0 ]; then
    show_menu
    read -p "Ingresa un comando: " command
else
    command="$1"
fi

# Log del comando ejecutado
log_event "Command: $command"

# Ejecutar según comando
case "$command" in
    start)
        check_dependencies || exit 1
        start_services
        ;;
        
    stop)
        stop_services
        ;;
        
    restart)
        check_dependencies || exit 1
        restart_services
        ;;
        
    status)
        show_status
        ;;
        
    monitor)
        start_monitor
        ;;
        
    logs)
        show_logs
        ;;
        
    help|--help|-h)
        show_help
        ;;
        
    *)
        echo -e "${RED}❌ Comando desconocido: $command${NC}"
        echo ""
        show_menu
        exit 1
        ;;
esac
