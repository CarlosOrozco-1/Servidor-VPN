# 🚀 Iniciar Servidor WireGuard - Guía Rápida

Script principal para configurar e iniciar el servidor WireGuard.

## ⚡ Quick Start (2 minutos)

### Paso 1: Setup Inicial (Primera Vez)

```bash
sudo ./scripts/08-setup-and-start-server.sh setup
```

Esto:
- Verifica/instala WireGuard
- Crea configuración en `/etc/wireguard/wg0.conf`
- Habilita IP forwarding
- Configura reglas de firewall

### Paso 2: Iniciar Servidor

```bash
sudo ./scripts/08-setup-and-start-server.sh start
```

### Paso 3: Verificar Estado

```bash
sudo ./scripts/08-setup-and-start-server.sh status
```

---

## 📋 Comandos

```bash
# Setup (primera vez)
sudo ./scripts/08-setup-and-start-server.sh setup

# Iniciar servidor
sudo ./scripts/08-setup-and-start-server.sh start

# Detener servidor
sudo ./scripts/08-setup-and-start-server.sh stop

# Reiniciar servidor
sudo ./scripts/08-setup-and-start-server.sh restart

# Ver estado actual
sudo ./scripts/08-setup-and-start-server.sh status

# Ver ayuda
sudo ./scripts/08-setup-and-start-server.sh help
```

---

## 📊 Configuración del Servidor

| Parámetro | Valor |
|-----------|-------|
| **IP Privada** | 10.0.0.1/24 |
| **IP Pública** | 161.153.28.223 |
| **Puerto** | 51820 |
| **Interfaz** | wg0 |
| **Subnet** | 10.0.0.0/24 |

---

## 🔑 Claves (desde notas-internas)

**Clave Privada del Servidor:**
```
SBgz+Mu4O+AeCk4RY0s4UN1WpbI/SbTrQ25ncuy/6GI=
```

**Clave Pública del Servidor:**
```
fZrG0x6jFTRM/wwOasP7+ww4uc1bHnKJ6Zhnx6ZB8gk=
```

---

## 📍 Output de Ejemplo

```
╔════════════════════════════════════════════════════════════╗
║   WireGuard Server - Setup & Start                        ║
║   Configuración e Inicio del Servidor WireGuard           ║
╚════════════════════════════════════════════════════════════╝

┌─ Setup de WireGuard Server ────────────────────────────────┐
│  ✓ WireGuard ya está instalado
│  ✓ Directorio /etc/wireguard creado
│  Creando archivo de configuración...
│  ✓ Archivo de configuración creado
│    Ubicación: /etc/wireguard/wg0.conf
│
│  Configurando IP Forwarding...
│  ✓ IP Forwarding habilitado
└────────────────────────────────────────────────────────────┘

┌─ Iniciando Servidor WireGuard ────────────────────────────┐
│  Iniciando wg0...
│  ✓ Servidor iniciado exitosamente
│
│  Interface:    wg0
│  IP Address:   10.0.0.1/24
│  Link:         UP
│  Puerto:       51820
│  Endpoint:     161.153.28.223:51820
│  Clave Pública: fZrG0x6jFTRM/wwOasP7...
└────────────────────────────────────────────────────────────┘

✓ Operación completada
   Logs: logs/server-setup.log
```

---

## 🆘 Problemas

### ❌ Permission denied
```bash
chmod +x scripts/08-setup-and-start-server.sh
```

### ❌ Requiere permisos root
```bash
# Todos los comandos necesitan sudo
sudo ./scripts/08-setup-and-start-server.sh start
```

### ❌ Puerto 51820 en uso
```bash
# Ver qué está usando el puerto
sudo lsof -i :51820

# Matar proceso si es necesario
sudo kill -9 <PID>
```

---

## 📝 Archivo de Configuración

Se crea automáticamente en: `/etc/wireguard/wg0.conf`

```ini
[Interface]
PrivateKey = SBgz+Mu4O+AeCk4RY0s4UN1WpbI/SbTrQ25ncuy/6GI=
Address = 10.0.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
SaveConfig = true

# Los peers se agregan aquí
```

---

## 🔗 Próximos Pasos

1. ✅ Iniciar servidor: `sudo ./scripts/08-setup-and-start-server.sh start`
2. ✅ Verificar: `sudo ./scripts/08-setup-and-start-server.sh status`
3. ✅ Agregar clientes (desde notas-internas/)
4. ✅ Monitorear: `sudo ./scripts/07-monitor-wireguard-peers.sh continuous`

---

## 📞 Conexión Remota al Servidor

Para conectarte por SSH desde otra máquina:

```bash
ssh -i /path/to/ssh-key-2026-02-23.key ubuntu@161.153.28.223
```

---

## 🎯 Cheatsheet

```bash
# Setup
sudo ./scripts/08-setup-and-start-server.sh setup

# Iniciar
sudo ./scripts/08-setup-and-start-server.sh start

# Parar
sudo ./scripts/08-setup-and-start-server.sh stop

# Estado
sudo ./scripts/08-setup-and-start-server.sh status

# Monitorear peers
sudo ./scripts/07-monitor-wireguard-peers.sh continuous

# Ver logs
tail -f logs/server-setup.log

# Config manual
sudo nano /etc/wireguard/wg0.conf
```

---

✅ **¡Listo!** Tu servidor WireGuard está operativo. 🚀
