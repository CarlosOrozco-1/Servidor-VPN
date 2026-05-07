#!/bin/bash

################################################################################
# Script: 05-database-manager.sh
# Descripción: Gestiona la base de datos SQLite de la aplicación VPN
# Ubicación: scripts/05-database-manager.sh
# Uso: ./scripts/05-database-manager.sh [init|reset|backup|restore]
# Parámetros:
#   init    - Inicializa una nueva base de datos
#   reset   - Limpia y reinicia la base de datos
#   backup  - Crea una copia de seguridad
#   restore - Restaura desde una copia de seguridad
#   status  - Muestra información de la base de datos
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
BACKEND_DIR="$PROJECT_ROOT/vpn-app/backend"
DB_FILE="$BACKEND_DIR/database/vpn.db"
DB_DIR="$BACKEND_DIR/database"
BACKUP_DIR="$PROJECT_ROOT/backups"
LOG_FILE="$PROJECT_ROOT/logs/database-manager.log"
LOG_DIR="$PROJECT_ROOT/logs"

# Crear directorios si no existen
mkdir -p "$LOG_DIR" "$BACKUP_DIR"

# Función para obtener timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Función para registrar en log
log_event() {
    local message="$1"
    echo "[$(get_timestamp)] $message" >> "$LOG_FILE"
}

# Banner
echo -e "${MAGENTA}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   VPN Database Manager                                    ║"
echo "║   Gestor de Base de Datos SQLite                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Función para inicializar BD
init_database() {
    echo -e "${BLUE}┌─ Inicializando Base de Datos ─────────────────────────────┐${NC}"
    
    if [ -f "$DB_FILE" ]; then
        echo -e "│  ${YELLOW}⚠ La base de datos ya existe en: $DB_FILE${NC}"
        read -p "   ¿Deseas sobrescribirla? (s/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            echo -e "│  ${YELLOW}Operación cancelada${NC}"
            echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
            return
        fi
        rm "$DB_FILE"
    fi
    
    cd "$BACKEND_DIR" || exit 1
    
    # Verificar si npm está disponible
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}❌ npm no encontrado${NC}"
        exit 1
    fi
    
    echo -e "│  Ejecutando: ${CYAN}npm run init-db${NC}"
    npm run init-db
    
    if [ $? -eq 0 ] && [ -f "$DB_FILE" ]; then
        echo -e "│  ${GREEN}✓ Base de datos inicializada correctamente${NC}"
        echo -e "│  Ubicación: ${GREEN}$DB_FILE${NC}"
        echo -e "│  Tamaño: $(ls -lh \"$DB_FILE\" | awk '{print $5}')"
        log_event "Database initialized successfully"
    else
        echo -e "│  ${RED}✗ Error durante la inicialización${NC}"
        log_event "Database initialization failed"
    fi
    
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
}

# Función para resetear BD
reset_database() {
    echo -e "${BLUE}┌─ Reseteando Base de Datos ────────────────────────────────┐${NC}"
    
    if [ ! -f "$DB_FILE" ]; then
        echo -e "│  ${YELLOW}⚠ La base de datos no existe${NC}"
        echo -e "│  ${BLUE}Creando nueva...${NC}"
        init_database
        return
    fi
    
    echo -e "│  ${RED}⚠ Advertencia: Se eliminarán todos los datos${NC}"
    read -p "   ¿Confirmar reset? (s/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo -e "│  ${YELLOW}Operación cancelada${NC}"
        echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
        return
    fi
    
    # Crear backup antes de resetear
    echo -e "│  Creando backup de seguridad antes del reset..."
    local backup_file="$BACKUP_DIR/vpn.db.backup-before-reset-$(date +%Y%m%d_%H%M%S)"
    cp "$DB_FILE" "$backup_file"
    echo -e "│  ${GREEN}✓ Backup guardado en: $backup_file${NC}"
    
    # Eliminar y reinitializar
    rm "$DB_FILE"
    
    cd "$BACKEND_DIR" || exit 1
    npm run init-db
    
    if [ $? -eq 0 ]; then
        echo -e "│  ${GREEN}✓ Base de datos reseteada correctamente${NC}"
        log_event "Database reset successfully"
    else
        echo -e "│  ${RED}✗ Error durante el reset${NC}"
        log_event "Database reset failed"
    fi
    
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
}

# Función para crear backup
backup_database() {
    echo -e "${BLUE}┌─ Creando Backup ──────────────────────────────────────────┐${NC}"
    
    if [ ! -f "$DB_FILE" ]; then
        echo -e "│  ${YELLOW}⚠ La base de datos no existe${NC}"
        echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
        return
    fi
    
    local backup_file="$BACKUP_DIR/vpn.db.backup-$(date +%Y%m%d_%H%M%S).db"
    
    cp "$DB_FILE" "$backup_file"
    
    if [ -f "$backup_file" ]; then
        local size=$(ls -lh "$backup_file" | awk '{print $5}')
        echo -e "│  ${GREEN}✓ Backup creado exitosamente${NC}"
        echo -e "│  Ubicación: ${GREEN}$backup_file${NC}"
        echo -e "│  Tamaño: ${GREEN}$size${NC}"
        log_event "Database backup created: $backup_file"
    else
        echo -e "│  ${RED}✗ Error al crear backup${NC}"
        log_event "Database backup failed"
    fi
    
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
}

# Función para restaurar backup
restore_database() {
    echo -e "${BLUE}┌─ Restaurar Backup ────────────────────────────────────────┐${NC}"
    
    # Listar backups disponibles
    echo -e "│  ${BLUE}Backups disponibles:${NC}"
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z \"$(ls -A \"$BACKUP_DIR\" 2>/dev/null)\" ]; then
        echo -e "│  ${YELLOW}⚠ No hay backups disponibles${NC}"
        echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
        return
    fi
    
    ls -1 "$BACKUP_DIR"/*.db 2>/dev/null | nl
    
    echo -e "│  "
    read -p "   Selecciona el número del backup (o Enter para cancelar): " backup_num
    
    if [ -z "$backup_num" ]; then
        echo -e "│  ${YELLOW}Operación cancelada${NC}"
        echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
        return
    fi
    
    local selected_backup=$(ls -1 "$BACKUP_DIR"/*.db 2>/dev/null | sed -n "${backup_num}p")
    
    if [ -z "$selected_backup" ]; then
        echo -e "│  ${RED}✗ Selección inválida${NC}"
        echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
        return
    fi
    
    # Crear backup de la BD actual antes de restaurar
    if [ -f "$DB_FILE" ]; then
        cp "$DB_FILE" "$BACKUP_DIR/vpn.db.backup-before-restore-$(date +%Y%m%d_%H%M%S).db"
    fi
    
    # Restaurar
    cp "$selected_backup" "$DB_FILE"
    
    echo -e "│  ${GREEN}✓ Base de datos restaurada desde: $selected_backup${NC}"
    log_event "Database restored from: $selected_backup"
    
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
}

# Función para mostrar estado
show_status() {
    echo -e "${BLUE}┌─ Estado de la Base de Datos ──────────────────────────────┐${NC}"
    
    if [ -f "$DB_FILE" ]; then
        local size=$(ls -lh "$DB_FILE" | awk '{print $5}')
        local modified=$(ls -l "$DB_FILE" | awk '{print $6, $7, $8}')
        
        echo -e "│  Status:     ${GREEN}● EXISTE${NC}"
        echo -e "│  Ruta:       $DB_FILE"
        echo -e "│  Tamaño:     $size"
        echo -e "│  Modificado: $modified"
    else
        echo -e "│  Status:     ${YELLOW}○ NO EXISTE${NC}"
        echo -e "│  Ruta:       $DB_FILE"
    fi
    
    echo -e "│"
    echo -e "│  ${BLUE}Backups disponibles:${NC} $(ls -1 \"$BACKUP_DIR\"/*.db 2>/dev/null | wc -l)"
    echo -e "│  Ubicación de backups: $BACKUP_DIR"
    
    echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
}

# Ejecutar según comando
case "${1:-help}" in
    init)
        init_database
        ;;
        
    reset)
        reset_database
        ;;
        
    backup)
        backup_database
        ;;
        
    restore)
        restore_database
        ;;
        
    status)
        show_status
        ;;
        
    *)
        echo -e "${BLUE}Uso:${NC}"
        echo "  ./scripts/05-database-manager.sh init       - Inicializar BD"
        echo "  ./scripts/05-database-manager.sh reset      - Resetear BD (limpia datos)"
        echo "  ./scripts/05-database-manager.sh backup     - Crear backup"
        echo "  ./scripts/05-database-manager.sh restore    - Restaurar desde backup"
        echo "  ./scripts/05-database-manager.sh status     - Ver estado"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✓ Operación completada${NC}"
echo "   Logs: $LOG_FILE"
