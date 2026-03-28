# AGENTS.md - Guía para Agentes IA

Este repositorio contiene archivos de configuración de WireGuard VPN, claves y documentación para administrar un servidor VPN en Ubuntu.

## Estructura del Repositorio

```
/
├── documentacion/          # Guías y documentación pública
│   ├── *.docx            # Guías de configuración
│   ├── Listado*.xlsx    # Lista de usuarios
│   └── *.txt            # Instrucciones de creación de usuarios
├── notas-internas/       # Archivos sensibles (NO subir a git)
│   ├── *.conf           # Configuraciones con claves privadas
│   ├── *.key            # Llaves privadas SSH
│   └── VPN-SERVER       # Configuración del servidor
├── configuraciones/     # Configuraciones públicas (sin claves privadas)
├── AGENTS.md            # Este archivo
├── .gitignore           # Archivos ignorados por git
└── README.md            # Documentación principal
```

## Propósito del Repositorio

**NO es un proyecto de software.** Almacena:
- Llaves SSH públicas/privadas para acceso al servidor
- Configuraciones de cliente WireGuard (`.conf`)
- Credenciales de usuarios en `notas-internas/`
- Documentación en `documentacion/`

## Comandos de Build/Lint/Test

**No disponibles.** Este repositorio no contiene código.

## Guías de Estilo de Archivos

### Archivos de Configuración VPN (`.conf`)
- Usar formato INI de WireGuard
- Carpeta: `notas-internas/` (contienen claves privadas)
- Incluir: `PrivateKey`, `Address`, `DNS`, sección `Peer`
- Indentación consistente (2 espacios)

### Archivos de Documentación
- Markdown (`.md`) para guías
- Excel (`.xlsx`) para lista de usuarios
- `.txt` para instrucciones

### Archivos de Llaves
- SSH: `ssh-key-*.key`, `ssh-key-*.key.pub`
- WireGuard: generar con `wg genkey`

## Directrices de Seguridad

### Crítico: NUNCA subir secretos a git
- **NUNCA** agregar llaves privadas a git
- Las llaves privadas terminan en `.key` - NO agregar a git
- Solo rastrear claves públicas (`.pub`)
- Carpeta `notas-interna` está en `.gitignore`

### Archivos Actuales con Secretos (ya protegidos)
- Llave SSH privada: `notas-internas/ssh-key-2026-02-23.key`
- Llave privada servidor WireGuard: `notas-internas/VPN-SERVER`
- Configuraciones de usuarios: `notas-internas/*.conf`

### Credenciales de Acceso
- Endpoint servidor: `161.153.28.223:51820`
- Clave pública servidor: `fZrG0x6jFTRM/wwOasP7+ww4uc1bHnKJ6Zhnx6ZB8gk=`
- SSH: `ssh -i notas-internas/ssh-key-2026-02-23.key ubuntu@161.153.28.223`

## Cómo Agregar Nuevos Usuarios

1. Generar keypair: `wg genkey | tee private.key | wg pubkey > public.key`
2. Asignar IP libre (ver archivos existentes en `notas-internas/`)
3. Crear archivo `.conf` en `notas-internas/` con plantilla WireGuard
4. **Guardar clave privada en gestor de contraseñas**, NO en repo
5. Agregar usuario a `documentacion/Listado de usuarios.xlsx`

## Convenciones de Nombres

- Archivos usuario: `Usuario-Nombre.txt` o `Nombre.conf`
- Llaves SSH: `ssh-key-YYYY-MM-DD.key`
- Nombres descriptivos pero no reveladores

## Reglas de Cursor/Copilot

No hay reglas personalizadas de Cursor o Copilot.

## Trabajando en Este Repositorio

Al hacer cambios:
1. NO escribir código a menos que se solicite
2. Enfocarse en documentación o gestión de configuraciones
3. Nunca generar o modificar claves privadas reales
4. Si se pide hacer commit, verificar que no haya claves privadas
5. Preferir leer configs existentes antes de crear nuevas

---

# Proyecto: VPN Manager App

Aplicación web para gestionar usuarios VPN WireGuard.

## Estructura

```
vpn-app/
├── backend/           # Node.js + Express + SQLite (sql.js)
│   ├── src/
│   │   ├── index.js
│   │   ├── routes/    # API REST
│   │   ├── models/    # Modelos DB
│   │   └── database/  # Inicialización
│   └── package.json
└── frontend/          # React + Vite
    ├── src/
    │   ├── pages/     # Componentes de página
    │   ├── services/  # API calls
    │   └── App.jsx
    └── package.json
```

## Ejecutar la Aplicación

```bash
# Backend (puerto 3001)
cd vpn-app/backend
npm install
npm run init-db
npm start

# Frontend (puerto 3000)
cd vpn-app/frontend
npm install
npm run dev
```

## API Endpoints

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/usuarios` | Listar todos |
| POST | `/api/usuarios` | Crear usuario |
| PUT | `/api/usuarios/:id` | Actualizar |
| DELETE | `/api/usuarios/:id` | Eliminar |
| POST | `/api/usuarios/:id/toggle` | Activar/Desactivar |
| GET | `/api/usuarios/proxima-ip` | Siguiente IP |
| GET | `/api/configuraciones` | Listar configs |
| PUT | `/api/configuraciones/:clave` | Actualizar config |
| GET | `/api/logs` | Ver auditoría |

## Tech Stack

- **Backend:** Node.js, Express, sql.js (SQLite en WebAssembly)
- **Frontend:** React 18, Vite
- **DB:** SQLite local (vpn-app/backend/database/vpn.db)
