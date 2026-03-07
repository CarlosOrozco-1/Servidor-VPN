# Servidor-VPN

Este proyecto documenta el proceso de creación y gestión de usuarios para una VPN basada en **WireGuard** sobre un servidor Ubuntu.

## Estructura del Proyecto

* **Usuarios-VPN/**: Contiene los archivos de texto con las claves y configuraciones específicas para cada usuario (ej. `Usuario-CarlosO.txt`, `mikeoc.txt`).

## Guía de Configuración

### 1. Generación de Claves

Para añadir un nuevo usuario, primero se deben generar las claves privada y pública:

```bash
wg genkey | tee nombreusuario_private.key | wg pubkey > nombreusuario_public.key
```

### 2. Asignación de IP

Se debe asignar una IP interna única dentro del rango de la VPN (ej. `10.6.0.x`).
* **Servidor**: `10.6.0.1`
* **Clientes**: `10.6.0.2`, `10.6.0.3`, etc.

### 3. Configuración en el Servidor

Editar el archivo `/etc/wireguard/wg0.conf` en el servidor para agregar el nuevo Peer:

```ini
[Peer]
PublicKey = <CLAVE_PUBLICA_DEL_USUARIO>
AllowedIPs = 10.6.0.X/32
```

### 4. Configuración del Cliente

El archivo de configuración para el cliente debe seguir este formato.

**Datos del Servidor:**
* **Endpoint**: `161.153.28.223:51820`
* **Server Public Key**: `fZrG0x6jFTRM/wwOasP7+ww4uc1bHnKJ6Zhnx6ZB8gk=`

**Plantilla de configuración (Cliente):**

```ini
[Interface]
PrivateKey = <CLAVE_PRIVADA_DEL_USUARIO>
Address = 10.6.0.X/24
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = fZrG0x6jFTRM/wwOasP7+ww4uc1bHnKJ6Zhnx6ZB8gk=
Endpoint = 161.153.28.223:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

## Instalación de Herramientas

* **Linux**: `sudo dnf install wireguard-tools -y` (o `apt install wireguard`).
* **Windows**: Instalar la aplicación oficial de WireGuard, crear un túnel vacío y pegar la configuración del cliente.
