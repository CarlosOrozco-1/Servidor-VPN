# 🚀 QUICK START - Guía Rápida

Inicia tu aplicación VPN en 30 segundos.

## ⚡ En 3 Pasos

### 1️⃣ Requisitos
```bash
# Verificar que tienes Node.js y npm
node --version  # v14+
npm --version   # v6+
```

### 2️⃣ Preparar Scripts
```bash
# Desde la raíz del proyecto
cd /ruta/del/proyecto

# Hacer scripts ejecutables
chmod +x scripts/*.sh

# Crear directorios
mkdir -p logs backups
```

### 3️⃣ ¡A Funcionar!
```bash
# Opción A: Comando simple (RECOMENDADO)
./scripts/master-vpn-control.sh start

# Opción B: Componentes por separado
# Terminal 1:
./scripts/01-start-vpn-backend.sh dev

# Terminal 2:
./scripts/02-start-vpn-frontend.sh dev

# Terminal 3:
./scripts/03-monitor-vpn-status.sh continuous
```

## 🌐 Acceder a la Aplicación

```
Frontend:      http://localhost:3000
Backend API:   http://localhost:3001/api
Health Check:  http://localhost:3001/api/health
```

## 🛑 Detener

```bash
# Parar todos los servicios
./scripts/master-vpn-control.sh stop

# O simplemente presiona Ctrl+C en cada terminal
```

---

## 📊 Comandos Más Comunes

| Acción | Comando |
|--------|---------|
| **Iniciar todo** | `./scripts/master-vpn-control.sh start` |
| **Ver estado** | `./scripts/master-vpn-control.sh status` |
| **Monitorear VPN** | `./scripts/master-vpn-control.sh monitor` |
| **Detener todo** | `./scripts/master-vpn-control.sh stop` |
| **Ver logs** | `./scripts/master-vpn-control.sh logs` |
| **Reiniciar** | `./scripts/master-vpn-control.sh restart` |

---

## 🐛 Problemas Comunes

### Puerto en uso
```bash
# Matar procesos antiguos
./scripts/04-stop-vpn-services.sh all

# Reiniciar
./scripts/master-vpn-control.sh start
```

### npm: command not found
```bash
# Instalar Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

### Permission denied
```bash
# Hacer ejecutables
chmod +x scripts/*.sh
```

---

## 📖 Documentación Completa

Para más detalles, ver: [`scripts/README.md`](README.md)

---

**Tip:** Usa `tmux` para sesiones persistentes que sobrevivan a desconexiones SSH:

```bash
# Instalar (primera vez)
sudo apt install -y tmux

# Los scripts usarán tmux automáticamente
./scripts/master-vpn-control.sh start

# Reconectar después
tmux attach-session -t vpn-app
```

---

✅ **¡Listo!** Tu aplicación VPN está funcionando.

Disfruta! 🎉
