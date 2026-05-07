#!/bin/bash

################################################################################
# Script: 07-monitor-wireguard-peers.sh
# Descripción: Monitorea WireGuard en tiempo real (peers, tráfico, estadísticas)
# Ubicación: scripts/07-monitor-wireguard-peers.sh
# Uso: ./scripts/07-monitor-wireguard-peers.sh [continuous|once|traffic|peers]
# 
# Este script muestra estadísticas en tiempo real de los peers conectados,
# incluyendo tráfico, latencia, last handshake, etc.
# Requiere: sudo (para ver información de WireGuard)
################################################################################

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_ROOT/logs"
WG_MONITOR_LOG="$LOG_DIR/wireguard-monitor.log"
WG_INTERFACE="${WG_INTERFACE:-wg0}"
REFRESH_INTERVAL="${REFRESH_INTERVAL:-3}"

# Crear directorio de logs
mkdir -p "$LOG_DIR"

# Función para obtener timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Función para registrar en log
log_event() {
    local message="$1"
    echo "[$(get_timestamp)] $message" >> "$WG_MONITOR_LOG"
}

# Función para convertir bytes a formato legible
format_bytes() {
    local bytes=$1
    if [ "$bytes" -ge 1073741824 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1073741824}") GB"
    elif [ "$bytes" -ge 1048576 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1048576}") MB"
    elif [ "$bytes" -ge 1024 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1024}") KB"
    else
        echo "$bytes B"
    fi
}

# Función para obtener tiempo legible desde segundos
format_time() {
    local seconds=$1
    if [ "$seconds" -lt 60 ]; then
        echo "${seconds}s"
    elif [ "$seconds" -lt 3600 ]; then
        local mins=$((seconds / 60))
        echo "${mins}m"
    elif [ "$seconds" -lt 86400 ]; then
        local hours=$((seconds / 3600))
        echo "${hours}h"
    else
        local days=$((seconds / 86400))
        echo "${days}d"
    fi
}

# Función para verificar si WireGuard está activo
check_wireguard_active() {
    if ! ip link show "$WG_INTERFACE" > /dev/null 2>&1; then
        return 1
    fi
    return 0
}

# Banner
show_banner() {
    echo -e "${MAGENTA}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║   WireGuard Peers Monitor                                 ║"
    echo "║   Monitor de Peers WireGuard                              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Función para mostrar estado general
show_general_status() {
    echo -e "${BLUE}┌─ Estado General ──────────────────────────────────────────┐${NC}"
    
    if ! check_wireguard_active; then
        echo -e "│  Status:       ${RED}● INACTIVO${NC}"
        echo -e "│  Interface:    $WG_INTERFACE"
        echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
        return 1
    fi
    
    # Información de la interfaz
    local ip_addr=$(ip addr show "$WG_INTERFACE" 2>/dev/null | grep "inet " | awk '{print $2}')
    local link_status=$(ip link show "$WG_INTERFACE" | grep "state" | awk '{print $NF}' | tr -d '>')
    
    echo -e "│  Status:       ${GREEN}● ACTIVO${NC}"
    echo -e "│  Interface:    $WG_INTERFACE"
    echo -e "│  IP Address:   $ip_addr"
    echo -e "│  Link:         $link_status"
    echo -e "│  Hora:         $(get_timestamp)"
    
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
    return 0
}

# Función para mostrar tabla de peers
show_peers_table() {
    echo ""
    echo -e "${CYAN}┌─ Peers Conectados ────────────────────────────────────────┐${NC}"
    echo -e "│${CYAN}"
    
    # Obtener información de WireGuard
    local peers_info=$(sudo wg show "$WG_INTERFACE" 2>/dev/null)
    
    if [ -z "$peers_info" ]; then
        echo -e "│  ${YELLOW}⚠ No se pudo obtener información de peers${NC}"
        echo -e "│  ${BLUE}Nota: Necesitas ejecutar con sudo${NC}"
        echo -e "│${NC}"
        echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
        return
    fi
    
    # Procesar peers
    local peer_count=0
    local in_peer=false
    local current_peer=""
    
    echo "$peers_info" | while IFS= read -r line; do
        # Detectar inicio de un peer
        if [[ "$line" =~ ^peer: ]]; then
            in_peer=true
            current_peer=$(echo "$line" | sed 's/peer: //')
            peer_count=$((peer_count + 1))
            
            echo -e "│  ${GREEN}Peer $peer_count: $(echo $current_peer | cut -c1-20)...${NC}"
            
        # Procesar líneas de peer
        elif [ "$in_peer" = true ]; then
            if [[ "$line" =~ ^[[:space:]]+endpoint: ]]; then
                local endpoint=$(echo "$line" | sed 's/^[[:space:]]*endpoint: //')
                echo -e "│    Endpoint:        $endpoint"
                
            elif [[ "$line" =~ ^[[:space:]]+allowed\ ips: ]]; then
                local ips=$(echo "$line" | sed 's/^[[:space:]]*allowed ips: //')
                echo -e "│    Allowed IPs:     $ips"
                
            elif [[ "$line" =~ ^[[:space:]]+latest\ handshake: ]]; then
                local handshake=$(echo "$line" | sed 's/^[[:space:]]*latest handshake: //')
                local now=$(date +%s)
                local ago=$((now - handshake))
                echo -e "│    Last Handshake:  $(format_time $ago) ago"
                
            elif [[ "$line" =~ ^[[:space:]]+transfer: ]]; then
                local transfer=$(echo "$line" | sed 's/^[[:space:]]*transfer: //')
                local recv=$(echo "$transfer" | cut -d' ' -f1)
                local sent=$(echo "$transfer" | cut -d' ' -f3)
                echo -e "│    Download:        $(format_bytes $recv)"
                echo -e "│    Upload:          $(format_bytes $sent)"
                echo -e "│"
            fi
        fi
    done
    
    echo -e "│${NC}"
    echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
}

# Función para monitoreo continuo
continuous_monitor() {
    echo -e "${GREEN}Iniciando monitoreo continuo (intervalo: ${REFRESH_INTERVAL}s)${NC}"
    echo -e "${GREEN}Presiona Ctrl+C para detener${NC}"
    echo ""
    
    log_event "Continuous monitoring started"
    
    local iteration=0
    
    while true; do
        clear
        show_banner
        show_general_status || exit 1
        show_peers_table
        
        iteration=$((iteration + 1))
        echo ""
        echo -e "${GRAY}Iteración: $iteration | Próxima actualización en ${REFRESH_INTERVAL}s | Presiona Ctrl+C para salir${NC}"
        
        sleep "$REFRESH_INTERVAL"
    done
}

# Función para reporte único
single_report() {
    clear
    show_banner
    show_general_status || exit 1
    show_peers_table
    
    log_event "Single report requested"
}

# Función para mostrar solo tráfico
show_traffic_only() {
    echo -e "${CYAN}┌─ Tráfico de Datos ────────────────────────────────────────┐${NC}"
    echo -e "│${CYAN} Peer | Download | Upload | Última Conexión${NC}"
    echo -e "│${CYAN}────────────────────────────────────────────────────────────${NC}${NC}"
    
    local peers_info=$(sudo wg show "$WG_INTERFACE" 2>/dev/null)
    local peer_num=0
    
    echo "$peers_info" | awk '
    BEGIN {
        peer = 0
        endpoint = ""
        transfer = ""
    }
    /^peer:/ {
        peer++
        pubkey = substr($2, 1, 15) "..."
    }
    /endpoint:/ {
        endpoint = $NF
    }
    /transfer:/ {
        recv = $3
        sent = $5
        
        # Format bytes
        if (recv >= 1073741824) recv = sprintf("%.2f GB", recv/1073741824)
        else if (recv >= 1048576) recv = sprintf("%.2f MB", recv/1048576)
        else if (recv >= 1024) recv = sprintf("%.2f KB", recv/1024)
        else recv = recv " B"
        
        if (sent >= 1073741824) sent = sprintf("%.2f GB", sent/1073741824)
        else if (sent >= 1048576) sent = sprintf("%.2f MB", sent/1048576)
        else if (sent >= 1024) sent = sprintf("%.2f KB", sent/1024)
        else sent = sent " B"
    }
    /latest handshake:/ {
        handshake = $NF
        now = systime()
        ago = now - handshake
        
        if (ago < 60) time = ago "s"
        else if (ago < 3600) time = int(ago/60) "m"
        else if (ago < 86400) time = int(ago/3600) "h"
        else time = int(ago/86400) "d"
        
        printf "│ %2d  | %8s | %6s | %s\n", peer, recv, sent, time
    }
    END {
        printf "│────────────────────────────────────────────────────────────\n"
    }
    '
    
    echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
}

# Función para mostrar solo peers
show_peers_only() {
    echo -e "${CYAN}┌─ Lista de Peers ──────────────────────────────────────────┐${NC}"
    
    local peers_info=$(sudo wg show "$WG_INTERFACE" 2>/dev/null)
    local peer_num=0
    
    echo "$peers_info" | awk '
    /^peer:/ {
        peer = substr($2, 1, 25)
        printf "│ Peer %d: %s\n", ++num, peer
    }
    /allowed ips:/ {
        printf "│   IPs: %s\n", $NF
    }
    /endpoint:/ {
        printf "│   Endpoint: %s\n", $NF
    }
    ' | head -50
    
    echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
}

# Función de ayuda
show_help() {
    echo -e "${BLUE}Uso:${NC}"
    echo "  sudo ./scripts/07-monitor-wireguard-peers.sh [modo]"
    echo "  ./scripts/07-monitor-wireguard-peers.sh [modo]"
    echo ""
    echo -e "${BLUE}Modos de Monitoreo:${NC}"
    echo "  continuous  - Monitoreo continuo (3s intervalo) - ${GREEN}RECOMENDADO${NC}"
    echo "  once        - Reporte único"
    echo "  traffic     - Mostrar solo tráfico de datos"
    echo "  peers       - Listar solo peers configurados"
    echo ""
    echo -e "${BLUE}Variables de Entorno:${NC}"
    echo "  REFRESH_INTERVAL  - Intervalo en segundos (default: 3)"
    echo "  WG_INTERFACE      - Interfaz a monitorear (default: wg0)"
    echo ""
    echo -e "${BLUE}Ejemplos:${NC}"
    echo "  sudo ./scripts/07-monitor-wireguard-peers.sh continuous"
    echo "  sudo ./scripts/07-monitor-wireguard-peers.sh once"
    echo "  REFRESH_INTERVAL=5 sudo ./scripts/07-monitor-wireguard-peers.sh continuous"
    echo ""
    echo -e "${BLUE}Nota:${NC}"
    echo "  Este script requiere sudo para obtener información completa de WireGuard"
}

# Mostrar banner
show_banner

# Verificar si WireGuard está instalado
if ! command -v wg &> /dev/null; then
    echo -e "${RED}❌ Error: WireGuard no está instalado${NC}"
    echo "   Instálalo con: sudo apt install wireguard wireguard-tools"
    exit 1
fi

# Ejecutar según modo
case "${1:-continuous}" in
    continuous)
        continuous_monitor
        ;;
        
    once)
        single_report
        ;;
        
    traffic)
        show_general_status || exit 1
        show_traffic_only
        log_event "Traffic report requested"
        ;;
        
    peers)
        show_general_status || exit 1
        show_peers_only
        log_event "Peers report requested"
        ;;
        
    help|--help|-h)
        show_help
        ;;
        
    *)
        echo -e "${RED}❌ Modo desconocido: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac

# Trap para detener correctamente
trap 'echo ""; echo -e "${YELLOW}⚠ Monitoreo detenido${NC}"; log_event "Monitoring stopped"; exit 0' INT TERM

echo ""
echo -e "${GREEN}✓ Operación completada${NC}"
echo "   Logs: $WG_MONITOR_LOG"
