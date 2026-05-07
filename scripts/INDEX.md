# 📁 Índice de Scripts - Estructura Completa

## 📂 Directorio: `/scripts`

Este directorio contiene todos los scripts necesarios para gestionar la aplicación VPN en un servidor Ubuntu.

---

## 📜 Scripts Disponibles

### 🎛️ Control Principal

```
├── master-vpn-control.sh          ⭐ PUNTO DE ENTRADA PRINCIPAL
│   └── Orquestra todos los servicios desde una interfaz única
│       Comandos: start | stop | restart | status | monitor | logs | help
```

---

### 🚀 Servicios (Iniciadores)

```
├── 01-start-vpn-backend.sh        [Node.js + Express API]
│   ├── Modo: dev (development con nodemon) | prod (producción)
│   ├── Puerto: 3001
│   ├── Inicializa BD automáticamente
│   └── Logs: logs/backend.log
│
├── 02-start-vpn-frontend.sh       [React + Vite Frontend]
│   ├── Modo: dev (servidor Vite) | build (compilar) | preview (vista previa)
│   ├── Puerto: 3000 (dev) | 4173 (preview)
│   ├── Recarga en caliente (HMR)
│   └── Logs: logs/frontend.log
│
└── 05-database-manager.sh         [Gestor de Base de Datos SQLite]
    ├── Comando: init | reset | backup | restore | status
    ├── Ubicación: vpn-app/backend/database/vpn.db
    ├── Backups: backups/vpn.db.backup-*
    └── Logs: logs/database-manager.log
```

---

### � WireGuard Server (Servidor)

```
├── 06-start-wireguard-server.sh   [Gestor del Servidor WireGuard]
│   ├── Comando: start | stop | restart | status | show | peers
│   ├── Requiere: sudo (permisos root)
│   ├── Configura la interfaz wg0
│   └── Logs: logs/wireguard-server.log
│
└── 07-monitor-wireguard-peers.sh  [Monitor de Peers WireGuard]
    ├── Modo: continuous | once | traffic | peers
    ├── Requiere: sudo (para información completa)
    ├── Muestra: Peers activos, tráfico, handshakes
    └── Logs: logs/wireguard-monitor.log
```

---

### 📊 Monitoreo y Mantenimiento

```
├── 03-monitor-vpn-status.sh       [Monitor de Estado VPN - App]
│   ├── Modo: continuous (5s intervalo) | once (reporte único) | health
│   ├── Monitorea: Backend API, Sistema, Conectividad
│   ├── Requiere: curl, lsof (opcional: wireguard-tools)
│   └── Logs: logs/vpn-monitor.log
│
└── 04-stop-vpn-services.sh        [Parada Segura de Servicios - App]
    ├── Targets: backend | frontend | all
    ├── SIGTERM → espera → SIGKILL si es necesario
    ├── Verifica: Puerto 3000 y 3001
    └── Logs: logs/services-stop.log
```

---

### 📚 Documentación

```
├── README.md                      [Documentación Completa]
│   ├── Descripción de cada script
│   ├── Ejemplos de uso
│   ├── Solución de problemas
│   ├── Logs y monitoreo
│   └── Casos de uso avanzados
│
├── QUICK_START.md                 [Guía de 30 Segundos]
│   ├── Requisitos
│   ├── 3 pasos para empezar
│   ├── Comandos más comunes
│   └── Troubleshooting rápido
│
├── .env.example                   [Archivo de Configuración de Ejemplo]
│   └── Variables para backend, frontend, monitor, base de datos
│
└── INDEX.md                       [Este archivo]
    └── Estructura y referencias de todos los scripts
```

---

## 📊 Árbol de Directorios Completo

```
Llaves-ubuntu-server-VPN/
├── scripts/                         ← 🎯 SCRIPTS (AQUÍ)
│   ├── 01-start-vpn-backend.sh     ✓ Ejecutable
│   ├── 02-start-vpn-frontend.sh    ✓ Ejecutable
│   ├── 03-monitor-vpn-status.sh    ✓ Ejecutable
│   ├── 04-stop-vpn-services.sh     ✓ Ejecutable
│   ├── 05-database-manager.sh      ✓ Ejecutable
│   ├── 06-start-wireguard-server.sh    ✓ Ejecutable (NUEVO)
│   ├── 07-monitor-wireguard-peers.sh   ✓ Ejecutable (NUEVO)
│   ├── master-vpn-control.sh       ✓ Ejecutable (PRINCIPAL)
│   ├── README.md                   📖 Documentación completa
│   ├── QUICK_START.md              🚀 Inicio rápido
│   ├── INDEX.md                    📑 Este archivo
│   └── .env.example                ⚙️  Configuración ejemplo
│
├── logs/                            ← Generado automáticamente
│   ├── backend.log
│   ├── frontend.log
│   ├── vpn-monitor.log
│   ├── services-stop.log
│   ├── database-manager.log
│   └── master-control.log
│
├── backups/                         ← Generado automáticamente
│   └── vpn.db.backup-YYYYMMDD_HHMMSS.db
│
├── vpn-app/
│   ├── backend/
│   │   ├── src/
│   │   │   ├── index.js
│   │   │   ├── routes/
│   │   │   ├── models/
│   │   │   ├── controllers/
│   │   │   └── services/
│   │   ├── database/
│   │   │   └── vpn.db (generado por init-db)
│   │   └── package.json
│   │
│   └── frontend/
│       ├── src/
│       │   ├── App.jsx
│       │   ├── pages/
│       │   ├── components/
│       │   └── services/
│       ├── index.html
│       └── package.json
│
├── README.md                       📖 Documentación principal
├── AGENTS.md                       🤖 Guía para agentes IA
└── ...
```

---

## 🔄 Flujo de Ejecución Recomendado

### Opción 1: ⭐ Recomendado (Script Maestro)

```bash
./scripts/master-vpn-control.sh start

    ↓
    ├─→ Inicializa directorio de logs
    ├─→ Verifica Node.js y npm
    ├─→ Detecta tmux
    ├─→ Inicia backend en sesión tmux
    ├─→ Inicia frontend en nueva ventana
    └─→ Ambos servicios corren en paralelo
```

### Opción 2: Manual (Componentes Individuales)

```bash
# Terminal 1
./scripts/01-start-vpn-backend.sh dev
    ↓
    ├─→ Verifica dependencias
    ├─→ npm install (si es necesario)
    ├─→ npm run init-db (si no existe)
    └─→ npm run dev (nodemon activo)

# Terminal 2
./scripts/02-start-vpn-frontend.sh dev
    ↓
    ├─→ Verifica dependencias
    ├─→ npm install (si es necesario)
    └─→ npm run dev (Vite server)

# Terminal 3
./scripts/03-monitor-vpn-status.sh continuous
    ↓
    ├─→ Verifica cada 5s
    ├─→ Muestra estado WireGuard
    ├─→ Verifica salud backend
    └─→ Actualiza métricas sistema
```

---

## 🎯 Casos de Uso Típicos

### 📌 Uso 1: Iniciar Servidor Completo

```bash
cd /path/to/Llaves-ubuntu-server-VPN
./scripts/master-vpn-control.sh start

# Acceder:
# http://localhost:3000  (Frontend)
# http://localhost:3001  (Backend)
```

---

### 📌 Uso 2: Monitoreo Continuo en Producción

```bash
# Terminal 1: Servicios
./scripts/master-vpn-control.sh start

# Terminal 2: Monitor
./scripts/03-monitor-vpn-status.sh continuous

# Resultado: Monitor en tiempo real cada 5 segundos
```

---

### 📌 Uso 3: Backup y Reset de Base de Datos

```bash
# 1. Ver estado actual
./scripts/05-database-manager.sh status

# 2. Crear backup
./scripts/05-database-manager.sh backup

# 3. Reset (si es necesario)
./scripts/05-database-manager.sh reset

# 4. Reiniciar servicios
./scripts/master-vpn-control.sh restart
```

---

### 📌 Uso 4: Recuperación de Errores

```bash
# 1. Ver estado
./scripts/master-vpn-control.sh status

# 2. Ver logs
./scripts/master-vpn-control.sh logs

# 3. Detener todo
./scripts/master-vpn-control.sh stop

# 4. Reiniciar limpio
./scripts/master-vpn-control.sh start
```

---

## 🔧 Requisitos Previos Checklist

```bash
# ✓ Verificar requisitos
✓ Node.js 14+          → node --version
✓ npm 6+               → npm --version
✓ Bash shell           → bash --version
✓ curl (opcional)      → curl --version
✓ lsof (opcional)      → lsof -V
✓ tmux (recomendado)   → tmux -V

# ✓ Permisos de archivos
chmod +x scripts/*.sh

# ✓ Directorios necesarios
mkdir -p logs backups
```

---

## 📞 Comandos de Referencia Rápida

```bash
# 🎯 PRINCIPAL
./scripts/master-vpn-control.sh start       # Inicia todo
./scripts/master-vpn-control.sh status      # Ver estado
./scripts/master-vpn-control.sh monitor     # Monitoreo continuo
./scripts/master-vpn-control.sh stop        # Detiene todo

# 🚀 BACKEND
./scripts/01-start-vpn-backend.sh dev       # Desarrollo
./scripts/01-start-vpn-backend.sh prod      # Producción

# 🎨 FRONTEND
./scripts/02-start-vpn-frontend.sh dev      # Desarrollo
./scripts/02-start-vpn-frontend.sh build    # Compilar
./scripts/02-start-vpn-frontend.sh preview  # Previsualizar

# 📊 MONITOREO APP
./scripts/03-monitor-vpn-status.sh once        # Reporte único
./scripts/03-monitor-vpn-status.sh continuous  # Continuo
./scripts/03-monitor-vpn-status.sh health      # Solo salud

# 🛑 PARADA
./scripts/04-stop-vpn-services.sh backend   # Solo backend
./scripts/04-stop-vpn-services.sh frontend  # Solo frontend
./scripts/04-stop-vpn-services.sh all       # Todo

# 💾 BASE DE DATOS
./scripts/05-database-manager.sh status     # Ver estado
./scripts/05-database-manager.sh backup     # Crear backup
./scripts/05-database-manager.sh restore    # Restaurar
./scripts/05-database-manager.sh reset      # Reset (cuidado!)

# 🔐 WIREGUARD SERVER
sudo ./scripts/06-start-wireguard-server.sh start      # Iniciar WG
sudo ./scripts/06-start-wireguard-server.sh stop       # Detener WG
sudo ./scripts/06-start-wireguard-server.sh restart    # Reiniciar WG
sudo ./scripts/06-start-wireguard-server.sh status     # Estado
sudo ./scripts/06-start-wireguard-server.sh show       # Info detallada
sudo ./scripts/06-start-wireguard-server.sh peers      # Listar peers

# 📡 MONITOREO WIREGUARD
sudo ./scripts/07-monitor-wireguard-peers.sh continuous  # Monitor 24/7
sudo ./scripts/07-monitor-wireguard-peers.sh once        # Reporte único
sudo ./scripts/07-monitor-wireguard-peers.sh traffic     # Solo tráfico
sudo ./scripts/07-monitor-wireguard-peers.sh peers       # Solo peers
```

---

## 📝 Convenciones de Nombres

Los scripts siguen un sistema de numeración y nombres descriptivos:

```
01-start-vpn-backend.sh      ← Número + proceso + componente
02-start-vpn-frontend.sh     ← Facilita ordenamiento y búsqueda
03-monitor-vpn-status.sh     ← Nombres descriptivos en inglés
04-stop-vpn-services.sh      ← "vpn" = contexto del proyecto
05-database-manager.sh       ← Números evitan confusión

master-vpn-control.sh        ← Script maestro (sin número)
.env.example                 ← Archivos de configuración
README.md                    ← Documentación
QUICK_START.md              ← Guías rápidas
INDEX.md                    ← Este archivo (índice)
```

---

## 🎓 Documentación Adicional

- **README.md**: Guía completa con todos los detalles
- **QUICK_START.md**: Inicia en 30 segundos
- **scripts/.env.example**: Variables de configuración
- **AGENTS.md**: Información del proyecto (raíz)

---

## ✅ Verificación Final

Para confirmar que todo está listo:

```bash
# 1. Navega al directorio
cd /path/to/Llaves-ubuntu-server-VPN

# 2. Verifica scripts
ls -la scripts/*.sh

# 3. Verifica permisos
ls scripts/*.sh | grep -E "^-rwx"

# 4. Verifica Node.js
node --version && npm --version

# 5. ¡Inicia!
./scripts/master-vpn-control.sh start
```

---

## 📍 Próximas Acciones

1. ✅ Leer: [`QUICK_START.md`](QUICK_START.md) (5 min)
2. ✅ Ejecutar: `chmod +x scripts/*.sh`
3. ✅ Probar: `./scripts/master-vpn-control.sh status`
4. ✅ Iniciar: `./scripts/master-vpn-control.sh start`
5. 📖 Referencia: [`README.md`](README.md) (según necesites)

---

**Última actualización:** 2 de Mayo, 2026

**Estado:** ✅ Todos los scripts listos para usar

🚀 **¡Bienvenido! Disfruta administrando tu VPN.** 🚀
