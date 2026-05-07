#!/bin/bash

################################################################################
# Script: 06-start-wireguard-server.sh
# Descripción: Inicia y gestiona el servidor WireGuard en Ubuntu
# Ubicación: scripts/06-start-wireguard-server.sh
# Uso: ./scripts/06-start-wireguard-server.sh [start|stop|status|restart|show]
# 
# Este script requiere permisos de sudo para funcionar correctamente
# ya que gestiona servicios del sistema (wg0, iptables, etc)
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
WG_LOG="$LOG_DIR/wireguard-server.log"
WG_INTERFACE="${WG_INTERFACE:-wg0}"
WG_CONFIG="/etc/wireguard/$WG_INTERFACE.conf"

# Crear directorio de logs
mkdir -p "$LOG_DIR"

# Función para obtener timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Función para registrar en log
log_event() {
    local message="$1"
    echo "[$(get_timestamp)] $message" >> "$WG_LOG"
}

# Función para verificar si se ejecuta como root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}❌ Error: Este script requiere permisos de root (sudo)${NC}"
        echo "   Uso: sudo ./scripts/06-start-wireguard-server.sh [comando]"
        exit 1
    fi
}

# Función para verificar si WireGuard está instalado
check_wireguard_installed() {
    if ! command -v wg &> /dev/null; then
        echo -e "${RED}❌ Error: WireGuard no está instalado${NC}"
        echo "   Instálalo con: sudo apt install -y wireguard wireguard-tools"
        return 1
    fi
    return 0
}

# Función para verificar si systemd-resolved está disponible
check_dns_resolution() {
    if ! command -v systemctl &> /dev/null; then
        echo -e "${YELLOW}⚠ systemd no disponible${NC}"
        return 1
    fi
    return 0
}

# Banner
show_banner() {
    echo -e "${MAGENTA}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║   WireGuard Server Manager                                ║"
    echo "║   Gestor del Servidor WireGuard                           ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Función para iniciar WireGuard
start_wireguard() {
    echo -e "${BLUE}┌─ Iniciando WireGuard ─────────────────────────────────────┐${NC}"
    
    # Verificar que el archivo de configuración existe
    if [ ! -f "$WG_CONFIG" ]; then
        echo -e "│  ${RED}✗ Archivo de configuración no encontrado${NC}"
        echo -e "│  Ubicación esperada: $WG_CONFIG"
        echo -e "│  ${BLUE}Debes crear la configuración de WireGuard primero${NC}"
        echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
        log_event "Start failed: Config file not found at $WG_CONFIG"
        return 1
    fi
    
    # Traer la interfaz
    echo -e "│  Activando interfaz $WG_INTERFACE..."
    ip link add dev "$WG_INTERFACE" type wireguard 2>/dev/null
    
    # Cargar configuración
    echo -e "│  Cargando configuración..."
    wg-quick up "$WG_INTERFACE" 2>&1 | grep -v "^$"
    
    if [ $? -eq 0 ]; then
        echo -e "│  ${GREEN}✓ WireGuard iniciado exitosamente${NC}"
        log_event "WireGuard started successfully"
    else
        echo -e "│  ${RED}✗ Error al iniciar WireGuard${NC}"
        log_event "WireGuard start failed"
        return 1
    fi
    
    # Verificar estado
    sleep 1
    if ip link show "$WG_INTERFACE" > /dev/null 2>&1; then
        local ip_address=$(ip addr show "$WG_INTERFACE" 2>/dev/null | grep "inet " | awk '{print $2}')
        echo -e "│  IP Address: ${GREEN}$ip_address${NC}"
    fi
    
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
}

# Función para detener WireGuard
stop_wireguard() {
    echo -e "${BLUE}┌─ Deteniendo WireGuard ────────────────────────────────────┐${NC}"
    
    if ! ip link show "$WG_INTERFACE" > /dev/null 2>&1; then
        echo -e "│  ${YELLOW}⚠ Interfaz $WG_INTERFACE no está activa${NC}"
        echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
        return 0
    fi
    
    echo -e "│  Deteniendo interfaz..."
    wg-quick down "$WG_INTERFACE"
    
    if [ $? -eq 0 ]; then
        echo -e "│  ${GREEN}✓ WireGuard detenido exitosamente${NC}"
        log_event "WireGuard stopped successfully"
    else
        echo -e "│  ${RED}✗ Error al detener WireGuard${NC}"
        log_event "WireGuard stop failed"
        return 1
    fi
    
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
}

# Función para reiniciar WireGuard
restart_wireguard() {
    stop_wireguard
    sleep 2
    start_wireguard
}

# Función para mostrar estado
show_status() {
    echo -e "${CYAN}┌─ Estado de WireGuard ─────────────────────────────────────┐${NC}"
    
    # Verificar si la interfaz está activa
    if ip link show "$WG_INTERFACE" > /dev/null 2>&1; then
        echo -e "│  Status:      ${GREEN}● ACTIVO${NC}"
        
        # IP Address
        local ip_address=$(ip addr show "$WG_INTERFACE" 2>/dev/null | grep "inet " | awk '{print $2}')
        echo -e "│  Interface:   $WG_INTERFACE"
        echo -e "│  IP Address:  $ip_address"
        
        # Estado del link
        local link_status=$(ip link show "$WG_INTERFACE" | grep "state" | awk '{print $NF}' | tr -d '>')
        echo -e "│  Link:        $link_status"
        
        # MTU
        local mtu=$(ip link show "$WG_INTERFACE" | grep "mtu" | awk '{print $5}')
        echo -e "│  MTU:         $mtu"
        
    else
        echo -e "│  Status:      ${YELLOW}● INACTIVO${NC}"
        echo -e "│  Interface:   $WG_INTERFACE"
        echo -e "│  Mensaje:     ${YELLOW}No está disponible${NC}"
    fi
    
    echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
}

# Función para mostrar información detallada de WireGuard
show_wireguard_info() {
    echo -e "${CYAN}┌─ Información Detallada de WireGuard ───────────────────────┐${NC}"
    
    if ! ip link show "$WG_INTERFACE" > /dev/null 2>&1; then
        echo -e "│  ${YELLOW}⚠ La interfaz $WG_INTERFACE no está activa${NC}"
        echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
        return
    fi
    
    echo -e "│  ${BLUE}Interfaz: $WG_INTERFACE${NC}"
    echo -e "│"
    
    # Mostrar configuración del servidor (requiere sudo)
    wg show "$WG_INTERFACE"
    
    echo -e "│"
    echo -e "│  ${BLUE}Tabla de Rutas:${NC}"
    ip route show table all | grep "$WG_INTERFACE" | while read line; do
        echo -e "│  $line"
    done
    
    echo -e "│"
    echo -e "│  ${BLUE}Estadísticas de Red:${NC}"
    ip -s link show "$WG_INTERFACE" | tail -n +3 | while read line; do
        echo -e "│  $line"
    done
    
    echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
}

# Función para listar peers conectados
show_connected_peers() {
    echo -e "${CYAN}┌─ Peers Conectados ────────────────────────────────────────┐${NC}"
    
    if ! ip link show "$WG_INTERFACE" > /dev/null 2>&1; then
        echo -e "│  ${YELLOW}⚠ La interfaz $WG_INTERFACE no está activa${NC}"
        echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
        return
    fi
    
    # Obtener peers del archivo de configuración
    if [ -f "$WG_CONFIG" ]; then
        local peer_count=$(grep -c "^\[Peer\]" "$WG_CONFIG")
        echo -e "│  Total de peers configurados: ${GREEN}$peer_count${NC}"
        
        # Obtener información de peers activos
        wg show "$WG_INTERFACE" peers | while read peer; do
            echo -e "│  Peer: $peer"
        done
    else
        echo -e "│  ${YELLOW}⚠ Archivo de configuración no encontrado${NC}"
    fi
    
    echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
}

# Función para mostrar la ayuda
show_help() {
    echo -e "${BLUE}Uso:${NC}"
    echo "  sudo ./scripts/06-start-wireguard-server.sh [comando]"
    echo ""
    echo -e "${BLUE}Comandos:${NC}"
    echo "  start      - Inicia el servidor WireGuard"
    echo "  stop       - Detiene el servidor WireGuard"
    echo "  restart    - Reinicia el servidor"
    echo "  status     - Muestra el estado actual"
    echo "  show       - Muestra información detallada y peers"
    echo "  peers      - Lista todos los peers conectados"
    echo "  help       - Muestra esta ayuda"
    echo ""
    echo -e "${BLUE}Ejemplos:${NC}"
    echo "  sudo ./scripts/06-start-wireguard-server.sh start"
    echo "  sudo ./scripts/06-start-wireguard-server.sh status"
    echo "  sudo ./scripts/06-start-wireguard-server.sh show"
    echo ""
    echo -e "${BLUE}Requisitos:${NC}"
    echo "  - Permisos root (sudo)"
    echo "  - WireGuard instalado: sudo apt install wireguard wireguard-tools"
    echo "  - Archivo de configuración en: $WG_CONFIG"
    echo ""
    echo -e "${BLUE}Más información:${NC}"
    echo "  man wg"
    echo "  man wg-quick"
    echo "  man wireguard"
}

# Mostrar banner
show_banner

# Verificar requisitos
check_wireguard_installed || exit 1

# Ejecutar comando
case "${1:-status}" in
    start)
        check_root
        start_wireguard
        ;;
        
    stop)
        check_root
        stop_wireguard
        ;;
        
    restart)
        check_root
        restart_wireguard
        ;;
        
    status)
        show_status
        ;;
        
    show)
        show_wireguard_info
        ;;
        
    peers)
        show_connected_peers
        ;;
        
    help|--help|-h)
        show_help
        ;;
        
    *)
        echo -e "${RED}❌ Comando desconocido: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✓ Operación completada${NC}"
echo "   Logs: $WG_LOG"
