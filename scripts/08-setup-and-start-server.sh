#!/bin/bash

################################################################################
# Script: 08-setup-and-start-server.sh
# Descripción: Setup y inicia el servidor WireGuard con las claves de notas-internas
# Ubicación: scripts/08-setup-and-start-server.sh
# Uso: sudo ./scripts/08-setup-and-start-server.sh [setup|start|stop|restart|status]
#
# Configuración del Servidor:
# - IP: 10.0.0.1/24
# - Claves y credenciales: notas-internas/.env (ver .env.example)
# - Endpoint público: definido en notas-internas/.env
################################################################################

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
NOTAS_INTERNAS="$PROJECT_ROOT/notas-internas"
LOG_DIR="$PROJECT_ROOT/logs"
SERVER_LOG="$LOG_DIR/server-setup.log"

# ── Cargar variables de entorno desde notas-internas/.env ────
ENV_FILE="$NOTAS_INTERNAS/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo -e "\033[0;31m❌ No se encontró el archivo de credenciales:\033[0m"
  echo -e "   \033[1;33m$ENV_FILE\033[0m"
  echo -e "   Crea el archivo basándote en scripts/.env.example"
  exit 1
fi
source "$ENV_FILE"

# Variables derivadas del .env
WG_INTERFACE="${WG_INTERFACE:-wg0}"
WG_CONFIG="/etc/wireguard/${WG_INTERFACE}.conf"

# Crear directorio de logs
mkdir -p "$LOG_DIR"

# Función para obtener timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Función para registrar en log
log_event() {
    local message="$1"
    echo "[$(get_timestamp)] $message" >> "$SERVER_LOG"
}

# Verificar si es root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}❌ Este script requiere permisos root${NC}"
        echo "   Usa: sudo ./scripts/08-setup-and-start-server.sh [comando]"
        exit 1
    fi
}

# Banner
show_banner() {
    echo -e "${MAGENTA}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║   WireGuard Server - Setup & Start                        ║"
    echo "║   Configuración e Inicio del Servidor WireGuard           ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Función para configurar WireGuard
setup_wireguard() {
    echo -e "${BLUE}┌─ Setup de WireGuard Server ────────────────────────────────┐${NC}"
    
    # Verificar WireGuard instalado
    if ! command -v wg &> /dev/null; then
        echo -e "│  ${RED}✗ WireGuard no está instalado${NC}"
        echo -e "│  ${YELLOW}Instalando WireGuard...${NC}"
        apt update > /dev/null
        apt install -y wireguard wireguard-tools > /dev/null 2>&1
        
        if ! command -v wg &> /dev/null; then
            echo -e "│  ${RED}✗ Error instalando WireGuard${NC}"
            log_event "Failed to install WireGuard"
            return 1
        fi
        echo -e "│  ${GREEN}✓ WireGuard instalado${NC}"
    else
        echo -e "│  ${GREEN}✓ WireGuard ya está instalado${NC}"
    fi
    
    # Crear directorio si no existe
    if [ ! -d /etc/wireguard ]; then
        mkdir -p /etc/wireguard
        chmod 700 /etc/wireguard
        echo -e "│  ${GREEN}✓ Directorio /etc/wireguard creado${NC}"
    fi
    
    # Crear archivo de configuración
    echo -e "│"
    echo -e "│  Creando archivo de configuración..."
    
    cat > "$WG_CONFIG" << EOF
[Interface]
PrivateKey = $SERVER_PRIVATE_KEY
Address = 10.0.0.1/24
ListenPort = $LISTEN_PORT
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
SaveConfig = true

# Peers serán agregados aquí automáticamente
EOF
    
    chmod 600 "$WG_CONFIG"
    echo -e "│  ${GREEN}✓ Archivo de configuración creado${NC}"
    echo -e "│    Ubicación: $WG_CONFIG"
    
    # Habilitar IP forwarding
    echo -e "│"
    echo -e "│  Configurando IP Forwarding..."
    
    if grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        echo -e "│  ${GREEN}✓ IP Forwarding ya estaba habilitado${NC}"
    else
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
        sysctl -p > /dev/null 2>&1
        echo -e "│  ${GREEN}✓ IP Forwarding habilitado${NC}"
    fi
    
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
    
    log_event "WireGuard setup completed successfully"
    return 0
}

# Función para iniciar el servidor
start_server() {
    echo -e "${BLUE}┌─ Iniciando Servidor WireGuard ────────────────────────────┐${NC}"
    
    # Verificar que la configuración existe
    if [ ! -f "$WG_CONFIG" ]; then
        echo -e "│  ${YELLOW}⚠ Configuración no encontrada${NC}"
        echo -e "│  Ejecutando setup primero..."
        setup_wireguard || return 1
    fi
    
    # Verificar si ya está corriendo
    if ip link show "$WG_INTERFACE" > /dev/null 2>&1; then
        echo -e "│  ${YELLOW}⚠ La interfaz $WG_INTERFACE ya está activa${NC}"
        echo -e "│  Deteniendo primero..."
        wg-quick down "$WG_INTERFACE" 2>&1 | grep -v "^$"
        sleep 1
    fi
    
    # Iniciar WireGuard
    echo -e "│  Iniciando $WG_INTERFACE..."
    wg-quick up "$WG_INTERFACE" 2>&1 | grep -v "^$" | while IFS= read -r line; do
        echo -e "│  $line"
    done
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo -e "│"
        echo -e "│  ${GREEN}✓ Servidor iniciado exitosamente${NC}"
        
        # Mostrar información
        sleep 1
        local ip_addr=$(ip addr show "$WG_INTERFACE" 2>/dev/null | grep "inet " | awk '{print $2}')
        local link_status=$(ip link show "$WG_INTERFACE" | grep "state" | awk '{print $NF}' | tr -d '>')
        
        echo -e "│  Interface:    $WG_INTERFACE"
        echo -e "│  IP Address:   ${GREEN}$ip_addr${NC}"
        echo -e "│  Link:         ${GREEN}$link_status${NC}"
        echo -e "│  Puerto:       ${GREEN}$LISTEN_PORT${NC}"
        echo -e "│  Endpoint:     ${GREEN}$PUBLIC_IP:$LISTEN_PORT${NC}"
        echo -e "│  Clave Pública: ${GREEN}${SERVER_PUBLIC_KEY:0:20}...${NC}"
        
        log_event "Server started successfully"
    else
        echo -e "│  ${RED}✗ Error al iniciar el servidor${NC}"
        log_event "Failed to start server"
        return 1
    fi
    
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
}

# Función para detener el servidor
stop_server() {
    echo -e "${BLUE}┌─ Deteniendo Servidor WireGuard ───────────────────────────┐${NC}"
    
    if ! ip link show "$WG_INTERFACE" > /dev/null 2>&1; then
        echo -e "│  ${YELLOW}⚠ La interfaz no está activa${NC}"
        echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
        return 0
    fi
    
    echo -e "│  Deteniendo $WG_INTERFACE..."
    wg-quick down "$WG_INTERFACE"
    
    if [ $? -eq 0 ]; then
        echo -e "│  ${GREEN}✓ Servidor detenido exitosamente${NC}"
        log_event "Server stopped successfully"
    else
        echo -e "│  ${RED}✗ Error al detener el servidor${NC}"
        log_event "Failed to stop server"
        return 1
    fi
    
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
}

# Función para reiniciar
restart_server() {
    stop_server
    sleep 2
    start_server
}

# Función para mostrar estado
show_status() {
    echo -e "${CYAN}┌─ Estado del Servidor ─────────────────────────────────────┐${NC}"
    
    if ! ip link show "$WG_INTERFACE" > /dev/null 2>&1; then
        echo -e "│  Status:       ${RED}● INACTIVO${NC}"
        echo -e "│  Interface:    $WG_INTERFACE"
        echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
        return 1
    fi
    
    # Información general
    local ip_addr=$(ip addr show "$WG_INTERFACE" 2>/dev/null | grep "inet " | awk '{print $2}')
    local link_status=$(ip link show "$WG_INTERFACE" | grep "state" | awk '{print $NF}' | tr -d '>')
    
    echo -e "│  Status:       ${GREEN}● ACTIVO${NC}"
    echo -e "│  Interface:    $WG_INTERFACE"
    echo -e "│  IP Address:   $ip_addr"
    echo -e "│  Link:         $link_status"
    echo -e "│  Puerto:       $LISTEN_PORT"
    echo -e "│  Endpoint:     $PUBLIC_IP:$LISTEN_PORT"
    echo -e "│"
    
    # Información detallada
    echo -e "│  ${CYAN}Información Detallada:${NC}"
    wg show "$WG_INTERFACE" 2>/dev/null | while IFS= read -r line; do
        echo -e "│  $line"
    done
    
    echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
    return 0
}

# Función de ayuda
show_help() {
    echo -e "${BLUE}Uso:${NC}"
    echo "  sudo ./scripts/08-setup-and-start-server.sh [comando]"
    echo ""
    echo -e "${BLUE}Comandos:${NC}"
    echo "  setup    - Configura WireGuard (primera vez)"
    echo "  start    - Inicia el servidor"
    echo "  stop     - Detiene el servidor"
    echo "  restart  - Reinicia el servidor"
    echo "  status   - Muestra el estado actual"
    echo "  help     - Muestra esta ayuda"
    echo ""
    echo -e "${BLUE}Configuración del Servidor:${NC}"
    echo "  IP Privada:      10.0.0.1/24"
    echo "  IP Pública:      $PUBLIC_IP"
    echo "  Puerto:          $LISTEN_PORT"
    echo "  Clave Pública:   $SERVER_PUBLIC_KEY"
    echo ""
    echo -e "${BLUE}Ejemplos:${NC}"
    echo "  sudo ./scripts/08-setup-and-start-server.sh setup"
    echo "  sudo ./scripts/08-setup-and-start-server.sh start"
    echo "  sudo ./scripts/08-setup-and-start-server.sh status"
}

# Main
show_banner

# Procesar comando
case "${1:-help}" in
    setup)
        check_root
        setup_wireguard
        ;;
        
    start)
        check_root
        start_server
        ;;
        
    stop)
        check_root
        stop_server
        ;;
        
    restart)
        check_root
        restart_server
        ;;
        
    status)
        show_status
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
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Operación completada${NC}"
else
    echo -e "${RED}✗ Error en la operación${NC}"
fi

echo "   Logs: $SERVER_LOG"
