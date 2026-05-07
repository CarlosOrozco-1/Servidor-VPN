#!/bin/bash

################################################################################
# Script: 03-monitor-vpn-status.sh
# Descripción: Monitorea el estado de la VPN y la salud de los servicios
# Ubicación: scripts/03-monitor-vpn-status.sh
# Uso: ./scripts/03-monitor-vpn-status.sh [continuous|once|health]
# Parámetros:
#   continuous - Monitoreo continuo (default, actualiza cada 5 segundos)
#   once       - Reporte único
#   health     - Solo verificar salud de servicios (backend)
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
MONITOR_LOG="$LOG_DIR/vpn-monitor.log"
BACKEND_URL="http://localhost:3001/api/health"
VPN_INTERFACE="wg0"
REFRESH_INTERVAL="${REFRESH_INTERVAL:-5}"

# Crear directorio de logs
mkdir -p "$LOG_DIR"

# Modo de monitoreo
MODE="${1:-continuous}"

# Función para obtener timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Función para registrar en log
log_event() {
    local message="$1"
    echo "[$(get_timestamp)] $message" >> "$MONITOR_LOG"
}

# Función para verificar si WireGuard está disponible
check_wireguard_available() {
    if command -v wg &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Función para obtener estado de WireGuard
get_wireguard_status() {
    if check_wireguard_available; then
        # Verificar si existe la interfaz
        if ip link show "$VPN_INTERFACE" > /dev/null 2>&1; then
            echo "ACTIVE"
        else
            echo "INACTIVE"
        fi
    else
        echo "NOT_INSTALLED"
    fi
}

# Función para obtener información de peers conectados
get_connected_peers() {
    if check_wireguard_available && [ "$(get_wireguard_status)" == "ACTIVE" ]; then
        # Requiere permisos sudo para ver información completa
        if sudo wg show "$VPN_INTERFACE" 2>/dev/null | grep -q "peer"; then
            sudo wg show "$VPN_INTERFACE" 2>/dev/null | grep -c "peer"
        else
            echo "0"
        fi
    else
        echo "0"
    fi
}

# Función para verificar salud del backend
check_backend_health() {
    local response=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL" 2>/dev/null)
    
    if [ "$response" == "200" ]; then
        echo "UP"
    else
        echo "DOWN"
    fi
}

# Función para obtener versión del backend
get_backend_version() {
    curl -s "$BACKEND_URL" 2>/dev/null | grep -o '"version":"[^"]*"' | cut -d'"' -f4
}

# Función para mostrar estado resumido
show_status_summary() {
    local wg_status=$(get_wireguard_status)
    local backend_status=$(check_backend_health)
    local peers=$(get_connected_peers)
    
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║   VPN STATUS MONITOR - $(get_timestamp)     ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Estado de WireGuard
    echo -e "${BLUE}┌─ WireGuard Interface ─────────────────────────────────────┐${NC}"
    case "$wg_status" in
        ACTIVE)
            echo -e "│  Status:     ${GREEN}● ACTIVO${NC}"
            echo -e "│  Interface:  ${GREEN}$VPN_INTERFACE${NC}"
            echo -e "│  Peers:      ${GREEN}$peers peer(s) conectado(s)${NC}"
            ;;
        INACTIVE)
            echo -e "│  Status:     ${YELLOW}● INACTIVO${NC}"
            echo -e "│  Interface:  ${YELLOW}$VPN_INTERFACE${NC}"
            ;;
        NOT_INSTALLED)
            echo -e "│  Status:     ${RED}● NO INSTALADO${NC}"
            echo -e "│  Mensaje:    ${RED}WireGuard tools no está instalado${NC}"
            ;;
    esac
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Estado del Backend
    echo -e "${BLUE}┌─ Backend API Server ──────────────────────────────────────┐${NC}"
    case "$backend_status" in
        UP)
            echo -e "│  Status:     ${GREEN}● OPERACIONAL${NC}"
            echo -e "│  URL:        ${GREEN}$BACKEND_URL${NC}"
            echo -e "│  Port:       ${GREEN}3001${NC}"
            ;;
        DOWN)
            echo -e "│  Status:     ${RED}● NO RESPONDE${NC}"
            echo -e "│  URL:        ${YELLOW}$BACKEND_URL${NC}"
            echo -e "│  Acción:     ${YELLOW}Ejecutar: ./scripts/01-start-vpn-backend.sh${NC}"
            ;;
    esac
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Estadísticas del Sistema
    echo -e "${BLUE}┌─ Información del Sistema ─────────────────────────────────┐${NC}"
    echo -e "│  Hostname:   $(hostname)"
    echo -e "│  Uptime:     $(uptime | awk -F, '{print $1}')"
    echo -e "│  Carga:      $(uptime | awk -F, '{print $NF}')"
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Registro de evento
    log_event "Check - WG: $wg_status | Backend: $backend_status | Peers: $peers"
}

# Función para mostrar solo salud
show_health_check() {
    local backend_status=$(check_backend_health)
    
    echo -e "${CYAN}┌─ Health Check ────────────────────────────────────────────┐${NC}"
    
    if [ "$backend_status" == "UP" ]; then
        echo -e "│  ${GREEN}✓ Backend API${NC}  - Status: ${GREEN}OK${NC}"
        log_event "Health: Backend OK"
    else
        echo -e "│  ${RED}✗ Backend API${NC}  - Status: ${RED}ERROR${NC}"
        log_event "Health: Backend ERROR"
    fi
    
    echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Función para monitoreo continuo
continuous_monitor() {
    echo -e "${GREEN}Iniciando monitoreo continuo (intervalo: ${REFRESH_INTERVAL}s)${NC}"
    echo -e "${GREEN}Presiona Ctrl+C para detener${NC}"
    echo ""
    log_event "Continuous monitoring started"
    
    while true; do
        clear
        show_status_summary
        
        # Contador de ciclo
        echo -e "${GRAY}Próxima actualización en ${REFRESH_INTERVAL}s | Presiona Ctrl+C para salir${NC}"
        sleep "$REFRESH_INTERVAL"
    done
}

# Función para reporte único
single_report() {
    clear
    show_status_summary
    log_event "Single report requested"
}

# Banner inicial
echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   VPN Monitor - Status & Health Check                     ║"
echo "║   Monitor de Estado y Salud de Servicios VPN              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Ejecutar según modo
case "$MODE" in
    continuous)
        continuous_monitor
        ;;
    once)
        single_report
        ;;
    health)
        show_health_check
        ;;
    *)
        echo -e "${RED}❌ Modo desconocido: $MODE${NC}"
        echo ""
        echo -e "${BLUE}Uso:${NC}"
        echo "  ./scripts/03-monitor-vpn-status.sh continuous  - Monitoreo continuo (5s intervalo)"
        echo "  ./scripts/03-monitor-vpn-status.sh once        - Reporte único"
        echo "  ./scripts/03-monitor-vpn-status.sh health      - Solo salud servicios"
        echo ""
        echo -e "${BLUE}Variables de entorno:${NC}"
        echo "  REFRESH_INTERVAL - Intervalo de actualización en segundos (default: 5)"
        exit 1
        ;;
esac

# Trap para detener correctamente
trap 'echo ""; echo -e "${YELLOW}⚠ Monitoreo detenido${NC}"; log_event "Monitoring stopped"; exit 0' INT TERM
