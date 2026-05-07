# 🔐 WireGuard Server Scripts - Guía Completa

Documentación sobre los scripts para gestionar WireGuard en el servidor Ubuntu.

## 📋 Tabla de Contenidos

- [Requisitos](#requisitos)
- [Scripts Disponibles](#scripts-disponibles)
- [Uso Rápido](#uso-rápido)
- [Ejemplos Prácticos](#ejemplos-prácticos)
- [Troubleshooting](#troubleshooting)

---

## 🔧 Requisitos

### Instalación de WireGuard

```bash
# Actualizar repositorios
sudo apt update

# Instalar WireGuard y herramientas
sudo apt install -y wireguard wireguard-tools

# Verificar instalación
wg --version
wg-quick --version
```

### Generación de Claves (Servidor)

Si aún no tienes configurado WireGuard, genera las claves:

```bash
# Crear directorio
sudo mkdir -p /etc/wireguard

# Generar claves del servidor
cd /etc/wireguard
sudo wg genkey | sudo tee server_private.key | wg pubkey | sudo tee server_public.key

# Permisos seguros
sudo chmod 600 server_private.key
sudo chmod 644 server_public.key
```

### Archivo de Configuración

El archivo de configuración debe estar en: `/etc/wireguard/wg0.conf`

**Plantilla:**

```ini
[Interface]
PrivateKey = <CLAVE_PRIVADA_SERVIDOR>
Address = 10.6.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = <CLAVE_PUBLICA_CLIENTE_1>
AllowedIPs = 10.6.0.2/32

[Peer]
PublicKey = <CLAVE_PUBLICA_CLIENTE_2>
AllowedIPs = 10.6.0.3/32
```

---

## 📜 Scripts Disponibles

### `06-start-wireguard-server.sh` - Gestor del Servidor

Script para iniciar, detener y gestionar el servidor WireGuard.

#### Uso

```bash
sudo ./scripts/06-start-wireguard-server.sh [comando]
```

#### Comandos

| Comando | Descripción |
|---------|-------------|
| `start` | Inicia el servidor WireGuard |
| `stop` | Detiene el servidor |
| `restart` | Reinicia el servidor |
| `status` | Muestra el estado actual |
| `show` | Muestra información detallada + peers |
| `peers` | Lista todos los peers conectados |
| `help` | Muestra ayuda |

#### Ejemplos

```bash
# Iniciar servidor
sudo ./scripts/06-start-wireguard-server.sh start

# Ver estado
sudo ./scripts/06-start-wireguard-server.sh status

# Ver información detallada
sudo ./scripts/06-start-wireguard-server.sh show

# Detener servidor
sudo ./scripts/06-start-wireguard-server.sh stop

# Reiniciar
sudo ./scripts/06-start-wireguard-server.sh restart
```

#### Output de Ejemplo

```
╔════════════════════════════════════════════════════════════╗
║   WireGuard Server Manager                                ║
║   Gestor del Servidor WireGuard                           ║
╚════════════════════════════════════════════════════════════╝

┌─ Estado de WireGuard ─────────────────────────────────────┐
│  Status:      ● ACTIVO
│  Interface:   wg0
│  IP Address:  10.6.0.1/24
│  Link:        UP
│  MTU:         1420
└────────────────────────────────────────────────────────────┘
```

---

### `07-monitor-wireguard-peers.sh` - Monitor de Peers

Script para monitorear peers conectados y tráfico en tiempo real.

#### Uso

```bash
sudo ./scripts/07-monitor-wireguard-peers.sh [modo]
```

#### Modos

| Modo | Descripción |
|------|-------------|
| `continuous` | Monitoreo continuo (3s intervalo) - **RECOMENDADO** |
| `once` | Reporte único |
| `traffic` | Mostrar solo tráfico de datos |
| `peers` | Listar solo peers configurados |

#### Ejemplos

```bash
# Monitoreo continuo en tiempo real
sudo ./scripts/07-monitor-wireguard-peers.sh continuous

# Ver estado actual una sola vez
sudo ./scripts/07-monitor-wireguard-peers.sh once

# Solo ver tráfico
sudo ./scripts/07-monitor-wireguard-peers.sh traffic

# Solo listar peers
sudo ./scripts/07-monitor-wireguard-peers.sh peers

# Personalizar intervalo
REFRESH_INTERVAL=5 sudo ./scripts/07-monitor-wireguard-peers.sh continuous
```

#### Output de Ejemplo

```
╔════════════════════════════════════════════════════════════╗
║   WireGuard Peers Monitor                                 ║
║   Monitor de Peers WireGuard                              ║
╚════════════════════════════════════════════════════════════╝

┌─ Estado General ──────────────────────────────────────────┐
│  Status:       ● ACTIVO
│  Interface:    wg0
│  IP Address:   10.6.0.1/24
│  Link:         UP
│  Hora:         2026-05-02 14:30:45
└────────────────────────────────────────────────────────────┘

┌─ Peers Conectados ────────────────────────────────────────┐
│  
│  Peer 1: 4Q8H2k9...
│    Endpoint:        192.168.1.100:54821
│    Allowed IPs:     10.6.0.2/32
│    Last Handshake:  2m ago
│    Download:        2.34 MB
│    Upload:          1.56 MB
│
│  Peer 2: 7mK3pJ9...
│    Endpoint:        192.168.1.101:52341
│    Allowed IPs:     10.6.0.3/32
│    Last Handshake:  5s ago
│    Download:        156.23 MB
│    Upload:          45.67 MB
│
└────────────────────────────────────────────────────────────┘
```

---

## 🚀 Uso Rápido

### Escenario 1: Iniciar el Servidor por Primera Vez

```bash
# 1. Verificar instalación
wg --version

# 2. Crear configuración (si no existe)
sudo nano /etc/wireguard/wg0.conf

# 3. Iniciar WireGuard
sudo ./scripts/06-start-wireguard-server.sh start

# 4. Verificar estado
sudo ./scripts/06-start-wireguard-server.sh status

# 5. Ver peers conectados
sudo ./scripts/06-start-wireguard-server.sh show
```

### Escenario 2: Monitoreo Continuo 24/7

```bash
# En una terminal
sudo ./scripts/07-monitor-wireguard-peers.sh continuous

# Actualizar cada 5 segundos
REFRESH_INTERVAL=5 sudo ./scripts/07-monitor-wireguard-peers.sh continuous
```

### Escenario 3: Diagnóstico de Conexiones

```bash
# Ver información detallada
sudo ./scripts/06-start-wireguard-server.sh show

# Ver solo peers
sudo ./scripts/06-start-wireguard-server.sh peers

# Ver tráfico en tiempo real
sudo ./scripts/07-monitor-wireguard-peers.sh traffic
```

### Escenario 4: Reiniciar Servidor

```bash
# Opción 1: Reinicio limpio
sudo ./scripts/06-start-wireguard-server.sh restart

# Opción 2: Manualmente
sudo ./scripts/06-start-wireguard-server.sh stop
sleep 2
sudo ./scripts/06-start-wireguard-server.sh start
```

---

## 📊 Ejemplos Prácticos

### Ejemplo 1: Setup Inicial en Servidor

```bash
#!/bin/bash
# Script de setup WireGuard

# 1. Instalar
sudo apt update
sudo apt install -y wireguard wireguard-tools

# 2. Generar claves
sudo wg genkey | sudo tee /etc/wireguard/server_private.key | wg pubkey | sudo tee /etc/wireguard/server_public.key

# 3. Crear configuración
sudo nano /etc/wireguard/wg0.conf

# 4. Iniciar
sudo ./scripts/06-start-wireguard-server.sh start

# 5. Verificar
sudo ./scripts/06-start-wireguard-server.sh show
```

### Ejemplo 2: Monitoreo Automático

```bash
#!/bin/bash
# Script para monitoreo continuo

# Crear sesión tmux
tmux new-session -d -s wireguard-monitor

# Inicia monitoreo
tmux send-keys -t wireguard-monitor "cd /path/to/scripts && sudo ./07-monitor-wireguard-peers.sh continuous" Enter

# Adjuntarse cuando necesites
# tmux attach-session -t wireguard-monitor
```

### Ejemplo 3: Automatizar Reinicio Diario

```bash
# Agregar a crontab
sudo crontab -e

# Agregar esta línea (reinicia a las 3 AM)
0 3 * * * /path/to/scripts/06-start-wireguard-server.sh restart >> /var/log/wireguard-restart.log 2>&1
```

### Ejemplo 4: Reporte de Conexiones

```bash
#!/bin/bash
# Genera reporte de peers activos

echo "=== WireGuard Status Report ===" >> /tmp/wg-report.txt
echo "Date: $(date)" >> /tmp/wg-report.txt
echo "" >> /tmp/wg-report.txt

# Estado
sudo ./scripts/06-start-wireguard-server.sh status >> /tmp/wg-report.txt

echo "" >> /tmp/wg-report.txt

# Peers
sudo ./scripts/06-start-wireguard-server.sh peers >> /tmp/wg-report.txt

# Tráfico
sudo ./scripts/07-monitor-wireguard-peers.sh traffic >> /tmp/wg-report.txt

# Ver reporte
cat /tmp/wg-report.txt
```

---

## 🐛 Troubleshooting

### Problema 1: "Permission denied"

**Error:**
```
./scripts/06-start-wireguard-server.sh: permission denied
```

**Solución:**
```bash
chmod +x scripts/06-start-wireguard-server.sh
chmod +x scripts/07-monitor-wireguard-peers.sh
```

---

### Problema 2: "Este script requiere permisos de root"

**Error:**
```
❌ Error: Este script requiere permisos de root (sudo)
```

**Solución:**
```bash
# Los scripts WireGuard requieren sudo
sudo ./scripts/06-start-wireguard-server.sh start
sudo ./scripts/07-monitor-wireguard-peers.sh continuous
```

---

### Problema 3: "Archivo de configuración no encontrado"

**Error:**
```
│  ✗ Archivo de configuración no encontrado
│  Ubicación esperada: /etc/wireguard/wg0.conf
```

**Solución:**
```bash
# Crear archivo de configuración
sudo nano /etc/wireguard/wg0.conf

# O copiar desde plantilla
sudo cp /path/to/template/wg0.conf /etc/wireguard/

# Verificar permisos
sudo chmod 600 /etc/wireguard/wg0.conf
```

---

### Problema 4: "No se puede obtener información de peers"

**Error:**
```
⚠ No se pudo obtener información de peers
Nota: Necesitas ejecutar con sudo
```

**Solución:**
```bash
# Asegúrate de usar sudo
sudo ./scripts/07-monitor-wireguard-peers.sh continuous

# Verificar que WireGuard está activo
sudo ./scripts/06-start-wireguard-server.sh status
```

---

### Problema 5: "WireGuard no está instalado"

**Error:**
```
❌ Error: WireGuard no está instalado
```

**Solución:**
```bash
# Instalar
sudo apt install -y wireguard wireguard-tools

# Verificar
wg --version
```

---

### Problema 6: Puerto 51820 ya en uso

**Error:**
```
Error al iniciar WireGuard (puerto en uso)
```

**Solución:**
```bash
# Verificar qué está usando el puerto
sudo lsof -i :51820

# Matar proceso si es necesario
sudo kill -9 <PID>

# O cambiar puerto en configuración
sudo nano /etc/wireguard/wg0.conf
# Cambiar: ListenPort = 51820 a otro puerto
```

---

## 📝 Referencia de Variables de Entorno

### Para `07-monitor-wireguard-peers.sh`

```bash
# Intervalo de actualización (en segundos)
REFRESH_INTERVAL=5

# Interfaz a monitorear
WG_INTERFACE=wg0
```

**Ejemplo:**
```bash
REFRESH_INTERVAL=10 WG_INTERFACE=wg0 sudo ./scripts/07-monitor-wireguard-peers.sh continuous
```

---

## 🔐 Consideraciones de Seguridad

### Backups de Configuración

```bash
# Crear backup
sudo cp /etc/wireguard/wg0.conf /etc/wireguard/wg0.conf.backup

# Restaurar
sudo cp /etc/wireguard/wg0.conf.backup /etc/wireguard/wg0.conf
```

### Permisos de Archivo

```bash
# Configuración debe ser restringida
sudo chmod 600 /etc/wireguard/wg0.conf

# Claves privadas
sudo chmod 600 /etc/wireguard/*private.key
```

### Firewall

```bash
# Permitir tráfico WireGuard
sudo ufw allow 51820/udp

# Habilitar IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Hacer permanente
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

---

## 📞 Logs

### Ubicación de Logs

```
logs/wireguard-server.log    # Eventos del servidor
logs/wireguard-monitor.log   # Eventos de monitoreo
```

### Ver Logs en Tiempo Real

```bash
# Servidor
tail -f logs/wireguard-server.log

# Monitor
tail -f logs/wireguard-monitor.log

# Combinado
tail -f logs/wireguard-*.log
```

---

## 🎯 Cheatsheet Rápido

```bash
# ✅ Iniciar
sudo ./scripts/06-start-wireguard-server.sh start

# ✅ Parar
sudo ./scripts/06-start-wireguard-server.sh stop

# ✅ Estado
sudo ./scripts/06-start-wireguard-server.sh status

# ✅ Monitorear
sudo ./scripts/07-monitor-wireguard-peers.sh continuous

# ✅ Información detallada
sudo ./scripts/06-start-wireguard-server.sh show

# ✅ Listar peers
sudo ./scripts/06-start-wireguard-server.sh peers

# ✅ Tráfico
sudo ./scripts/07-monitor-wireguard-peers.sh traffic

# ✅ Ver logs
tail -f logs/wireguard-*.log
```

---

## 📖 Recursos Adicionales

- [WireGuard Official](https://www.wireguard.com/)
- [WireGuard Quick Start](https://www.wireguard.com/quickstart/)
- `man wg`
- `man wg-quick`
- `man wireguard`

---

**Última actualización:** 2 de Mayo, 2026

**Estado:** ✅ Scripts WireGuard listos para usar

🔐 **¡Administra tu servidor WireGuard con confianza!** 🔐
