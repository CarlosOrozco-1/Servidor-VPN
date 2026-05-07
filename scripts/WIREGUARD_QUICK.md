# ⚡ WireGuard - Quick Start (5 Minutos)

Inicia tu servidor WireGuard en 5 pasos.

## 🚀 Paso 1: Instalar WireGuard

```bash
# Ejecutar setup (requiere sudo)
sudo ./scripts/setup-wireguard-environment.sh

# Verifica instalación
wg --version
```

## 🔑 Paso 2: Crear Configuración

```bash
# Abrir editor
sudo nano /etc/wireguard/wg0.conf
```

**Plantilla mínima:**

```ini
[Interface]
PrivateKey = <TU_CLAVE_PRIVADA>
Address = 10.6.0.1/24
ListenPort = 51820

[Peer]
PublicKey = <CLAVE_PUBLICA_CLIENTE>
AllowedIPs = 10.6.0.2/32
```

## ✅ Paso 3: Iniciar Servidor

```bash
sudo ./scripts/06-start-wireguard-server.sh start
```

## 📊 Paso 4: Verificar Estado

```bash
# Ver estado
sudo ./scripts/06-start-wireguard-server.sh status

# Ver información detallada
sudo ./scripts/06-start-wireguard-server.sh show
```

## 📡 Paso 5: Monitorear

```bash
# Monitor en tiempo real
sudo ./scripts/07-monitor-wireguard-peers.sh continuous

# O solo una vez
sudo ./scripts/07-monitor-wireguard-peers.sh once
```

---

## 📖 Comandos Principales

```bash
# Iniciar
sudo ./scripts/06-start-wireguard-server.sh start

# Detener
sudo ./scripts/06-start-wireguard-server.sh stop

# Reiniciar
sudo ./scripts/06-start-wireguard-server.sh restart

# Estado
sudo ./scripts/06-start-wireguard-server.sh status

# Info detallada
sudo ./scripts/06-start-wireguard-server.sh show

# Listar peers
sudo ./scripts/06-start-wireguard-server.sh peers

# Monitorear peers
sudo ./scripts/07-monitor-wireguard-peers.sh continuous

# Solo tráfico
sudo ./scripts/07-monitor-wireguard-peers.sh traffic

# Solo peers
sudo ./scripts/07-monitor-wireguard-peers.sh peers
```

---

## 🆘 Problemas Comunes

### ❌ "Permission denied"
```bash
chmod +x scripts/06-start-wireguard-server.sh
chmod +x scripts/07-monitor-wireguard-peers.sh
```

### ❌ "Requiere permisos root"
```bash
# Todos los comandos WireGuard necesitan sudo
sudo ./scripts/06-start-wireguard-server.sh start
```

### ❌ "WireGuard no está instalado"
```bash
sudo ./scripts/setup-wireguard-environment.sh
```

### ❌ "Archivo de configuración no encontrado"
```bash
# Crear configuración
sudo nano /etc/wireguard/wg0.conf

# Verificar permisos
sudo chmod 600 /etc/wireguard/wg0.conf
```

---

## 📞 Contacto Rápido

```bash
# Ver logs
tail -f logs/wireguard-*.log

# Guía completa
cat scripts/WIREGUARD.md

# Índice general
cat scripts/INDEX.md

# Todos los scripts
ls -la scripts/*.sh
```

---

**¡Listo para usar en segundos!** ⚡🔐
