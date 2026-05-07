# Scripts de Gestión VPN - Guía de Uso

Colección de scripts bash para gestionar, monitorear y mantener la aplicación VPN en servidores Ubuntu/Linux.

## 📋 Tabla de Contenidos

- [Descripción General](#descripción-general)
- [Scripts Disponibles](#scripts-disponibles)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Uso Básico](#uso-básico)
- [Uso Avanzado](#uso-avanzado)
- [Logs y Monitoreo](#logs-y-monitoreo)
- [Solución de Problemas](#solución-de-problemas)

## 🎯 Descripción General

Estos scripts automatizan las tareas más comunes en la administración de la aplicación VPN:

- ✅ Iniciar/detener servicios (backend y frontend)
- ✅ Monitorear estado de la VPN
- ✅ Gestionar base de datos
- ✅ Crear y restaurar backups
- ✅ Verificar salud del sistema
- ✅ Registrar eventos en logs

## 📦 Scripts Disponibles

### 1. `master-vpn-control.sh` ⭐ (RECOMENDADO)

Script maestro que controla todos los servicios desde una única interfaz.

**Ubicación:** `scripts/master-vpn-control.sh`

**Comandos:**

```bash
# Ver menú interactivo
./scripts/master-vpn-control.sh

# Iniciar todos los servicios
./scripts/master-vpn-control.sh start

# Detener todos los servicios
./scripts/master-vpn-control.sh stop

# Reiniciar servicios
./scripts/master-vpn-control.sh restart

# Ver estado actual
./scripts/master-vpn-control.sh status

# Monitoreo en tiempo real
./scripts/master-vpn-control.sh monitor

# Ver logs recientes
./scripts/master-vpn-control.sh logs
```

**Características:**

- Detecta si `tmux` está disponible
- Si está disponible, usa tmux para gestionar sesiones
- Si no está disponible, inicia los servicios en background
- Control centralizado desde un único script

---

### 2. `01-start-vpn-backend.sh`

Inicia el servidor backend de la API.

**Ubicación:** `scripts/01-start-vpn-backend.sh`

**Comandos:**

```bash
# Modo desarrollo (default, con nodemon)
./scripts/01-start-vpn-backend.sh dev

# Modo producción
./scripts/01-start-vpn-backend.sh prod
```

**Características:**

- Verifica dependencias (Node.js, npm)
- Instala módulos si no existen
- Inicializa la base de datos automáticamente
- Registra logs en `logs/backend.log`
- Modo desarrollo con auto-reinicio (nodemon)

**Puerto:** `3001` (configurable en `.env`)

---

### 3. `02-start-vpn-frontend.sh`

Inicia el servidor frontend (Vite).

**Ubicación:** `scripts/02-start-vpn-frontend.sh`

**Comandos:**

```bash
# Servidor desarrollo
./scripts/02-start-vpn-frontend.sh dev

# Compilar para producción
./scripts/02-start-vpn-frontend.sh build

# Previsualizar build de producción
./scripts/02-start-vpn-frontend.sh preview
```

**Características:**

- Servidor de desarrollo Vite
- Compilación optimizada para producción
- Recarga en caliente (HMR)
- Registra logs en `logs/frontend.log`

**Puertos:**
- Desarrollo: `3000`
- Preview: `4173`

---

### 4. `03-monitor-vpn-status.sh`

Monitorea el estado de la VPN y la salud de los servicios.

**Ubicación:** `scripts/03-monitor-vpn-status.sh`

**Comandos:**

```bash
# Monitoreo continuo (5s intervalo)
./scripts/03-monitor-vpn-status.sh continuous

# Reporte único
./scripts/03-monitor-vpn-status.sh once

# Solo verificar salud del backend
./scripts/03-monitor-vpn-status.sh health
```

**Variables de Entorno:**

```bash
# Cambiar intervalo de actualización (en segundos)
REFRESH_INTERVAL=10 ./scripts/03-monitor-vpn-status.sh continuous
```

**Monitorea:**

- ✓ Estado de la interfaz WireGuard
- ✓ Número de peers conectados
- ✓ Salud del servidor backend
- ✓ Uptime del sistema
- ✓ Carga del servidor

---

### 5. `04-stop-vpn-services.sh`

Detiene los servicios de forma segura.

**Ubicación:** `scripts/04-stop-vpn-services.sh`

**Comandos:**

```bash
# Detener todos los servicios
./scripts/04-stop-vpn-services.sh all

# Detener solo backend
./scripts/04-stop-vpn-services.sh backend

# Detener solo frontend
./scripts/04-stop-vpn-services.sh frontend
```

**Características:**

- Señales SIGTERM primero
- SIGKILL si es necesario
- Registra eventos en logs
- Verifica puertos en uso

---

### 6. `05-database-manager.sh`

Gestiona la base de datos SQLite.

**Ubicación:** `scripts/05-database-manager.sh`

**Comandos:**

```bash
# Inicializar nueva BD
./scripts/05-database-manager.sh init

# Resetear BD (limpia todos los datos)
./scripts/05-database-manager.sh reset

# Crear backup
./scripts/05-database-manager.sh backup

# Restaurar desde backup
./scripts/05-database-manager.sh restore

# Ver estado de la BD
./scripts/05-database-manager.sh status
```

**Características:**

- Inicialización automática
- Backups automáticos antes de reset
- Restauración interactiva
- Historial de cambios

**Ubicación de Backups:** `backups/`

---

## 📋 Requisitos

### Sistema Operativo

- Ubuntu 18.04+
- Debian 9+
- Cualquier Linux con bash

### Software Requerido

```bash
# Node.js 14+ y npm 6+
node --version  # v14.0.0 o superior
npm --version   # 6.0.0 o superior

# Herramientas opcionales pero recomendadas
tmux           # Para gestión de sesiones
curl           # Para health checks
lsof           # Para verificar puertos
wireguard-tools # Para monitoreo de VPN
```

### Instalación de Dependencias

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y nodejs npm tmux curl lsof wireguard-tools

# Verificar instalación
node -v && npm -v && tmux -V
```

---

## 🚀 Instalación

### Paso 1: Clonar/Descargar el Repositorio

```bash
cd /ruta/del/proyecto
ls scripts/
```

### Paso 2: Hacer Scripts Ejecutables

```bash
chmod +x scripts/*.sh
```

### Paso 3: Crear Directorios Necesarios

```bash
mkdir -p logs backups
```

### Paso 4: Verificar Permisos

```bash
ls -la scripts/
# Todos los archivos .sh deben tener permiso 'x'
```

---

## 💻 Uso Básico

### Iniciar Todo

```bash
./scripts/master-vpn-control.sh start
```

O manualmente:

```bash
# Terminal 1: Backend
./scripts/01-start-vpn-backend.sh dev

# Terminal 2: Frontend
./scripts/02-start-vpn-frontend.sh dev

# Terminal 3: Monitor
./scripts/03-monitor-vpn-status.sh continuous
```

### Acceder a la Aplicación

```
Frontend: http://localhost:3000
Backend API: http://localhost:3001/api/health
```

### Detener Todo

```bash
./scripts/master-vpn-control.sh stop
```

---

## 🔧 Uso Avanzado

### Usar tmux para Sesiones Persistentes

```bash
# Iniciar en tmux
./scripts/master-vpn-control.sh start

# Adjuntarse a la sesión
tmux attach-session -t vpn-app

# Navegar entre ventanas
Ctrl+B, N          # Siguiente ventana
Ctrl+B, P          # Ventana anterior
Ctrl+B, 0          # Ventana 0 (Backend)
Ctrl+B, 1          # Ventana 1 (Frontend)

# Desadjuntarse sin cerrar
Ctrl+B, D
```

### Monitoreo Personalizado

```bash
# Intervalo de 10 segundos
REFRESH_INTERVAL=10 ./scripts/03-monitor-vpn-status.sh continuous

# Solo health check
./scripts/03-monitor-vpn-status.sh health

# Reporte único
./scripts/03-monitor-vpn-status.sh once
```

### Gestión Avanzada de BD

```bash
# Ver estado de la BD
./scripts/05-database-manager.sh status

# Crear backup manual
./scripts/05-database-manager.sh backup

# Listar y restaurar backups
./scripts/05-database-manager.sh restore

# Resetear con confirmación
./scripts/05-database-manager.sh reset
```

### Modo Producción

```bash
# Backend en producción
./scripts/01-start-vpn-backend.sh prod

# Frontend (compilado)
./scripts/02-start-vpn-frontend.sh build
./scripts/02-start-vpn-frontend.sh preview
```

---

## 📊 Logs y Monitoreo

### Ubicación de Logs

```
logs/
├── backend.log          # Logs del servidor backend
├── frontend.log         # Logs del servidor frontend
├── vpn-monitor.log      # Logs del monitor de VPN
├── services-stop.log    # Logs de parada de servicios
├── database-manager.log # Logs del gestor de BD
└── master-control.log   # Logs del control maestro
```

### Ver Logs en Tiempo Real

```bash
# Backend
tail -f logs/backend.log

# Frontend
tail -f logs/frontend.log

# Monitor
tail -f logs/vpn-monitor.log
```

### Ver Todos los Logs Recientes

```bash
./scripts/master-vpn-control.sh logs
```

### Limpiar Logs Antiguos

```bash
# Mantener solo los últimos 7 días
find logs/ -type f -mtime +7 -delete

# Limpiar todos
rm logs/*
```

---

## 🐛 Solución de Problemas

### Problema: "No such file or directory"

**Causa:** Scripts no están en la ruta correcta o no son ejecutables

**Solución:**

```bash
# Verificar ubicación
ls -la scripts/01-start-vpn-backend.sh

# Hacer ejecutables
chmod +x scripts/*.sh

# Ejecutar desde la raíz del proyecto
cd /ruta/del/proyecto
./scripts/master-vpn-control.sh start
```

### Problema: Puerto 3000/3001 ya en uso

**Causa:** Proceso anterior no fue detenido correctamente

**Solución:**

```bash
# Detener servicios
./scripts/04-stop-vpn-services.sh all

# Verificar puertos
lsof -i :3000
lsof -i :3001

# Matar procesos específicos (si es necesario)
kill -9 <PID>

# Reintentar
./scripts/master-vpn-control.sh start
```

### Problema: "npm command not found"

**Causa:** Node.js/npm no está instalado

**Solución:**

```bash
# Instalar Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verificar
node --version
npm --version
```

### Problema: "Permission denied"

**Causa:** Scripts no tienen permisos de ejecución

**Solución:**

```bash
chmod +x scripts/*.sh
chmod 755 scripts/

# Verificar
ls -la scripts/ | grep "\.sh"
```

### Problema: Base de datos corrupta

**Causa:** Proceso interrumpido durante transacción

**Solución:**

```bash
# Crear backup
./scripts/05-database-manager.sh backup

# Resetear BD
./scripts/05-database-manager.sh reset

# O restaurar backup anterior
./scripts/05-database-manager.sh restore
```

### Problema: tmux no encontrado

**Causa:** tmux no está instalado

**Solución:**

```bash
# Opción 1: Instalar tmux
sudo apt install -y tmux

# Opción 2: Usar sin tmux (scripts inician en background)
./scripts/master-vpn-control.sh start
# Los servicios correrán en segundo plano
```

---

## 📝 Ejemplos Prácticos

### Escenario 1: Iniciar Servidor Completo

```bash
# Ejecutar desde terminal
cd /path/to/vpn-app
./scripts/master-vpn-control.sh start

# Se iniciará con tmux (si está instalado)
# Acceder a:
# - Frontend: http://localhost:3000
# - Backend API: http://localhost:3001
```

### Escenario 2: Monitoreo 24/7

```bash
# Terminal 1: Iniciar servicios
./scripts/master-vpn-control.sh start

# Terminal 2: Monitoreo continuo
./scripts/03-monitor-vpn-status.sh continuous

# El monitor mostrará estado cada 5 segundos
```

### Escenario 3: Backup de Datos

```bash
# Crear backup manual
./scripts/05-database-manager.sh backup

# Backup se guarda en: backups/vpn.db.backup-YYYYMMDD_HHMMSS.db
```

### Escenario 4: Reset Completo

```bash
# 1. Crear backup
./scripts/05-database-manager.sh backup

# 2. Detener servicios
./scripts/04-stop-vpn-services.sh all

# 3. Resetear BD
./scripts/05-database-manager.sh reset

# 4. Reiniciar
./scripts/master-vpn-control.sh start
```

---

## 🔐 Consideraciones de Seguridad

### Permisos de Archivo

```bash
# Mantener directorios con permisos restrictivos
chmod 700 logs/
chmod 700 backups/
chmod 700 scripts/
```

### Backups Regulares

```bash
# Crear backup diario (crontab)
0 2 * * * /path/to/scripts/05-database-manager.sh backup
```

### Monitoreo de Logs

```bash
# Revisar logs regularmente en busca de errores
grep -i error logs/*.log

# Monitorear crecimiento de logs
ls -lh logs/
```

---

## 📞 Soporte

Para problemas o sugerencias:

1. Revisa los logs: `./scripts/master-vpn-control.sh logs`
2. Comprueba el estado: `./scripts/master-vpn-control.sh status`
3. Consulta la guía de troubleshooting arriba

---

## 📄 Licencia

Estos scripts son parte del proyecto VPN Manager y se proporcionan bajo la misma licencia.

---

**Última actualización:** 2 de Mayo, 2026
