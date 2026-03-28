# Estructura del Proyecto

Este documento describe la estructura del repositorio `Llaves-ubuntu-server-VPN`, que combina la gestión manual de configuraciones WireGuard con una aplicación web (`vpn-app`) para el registro de usuarios.

## Diagrama General del Proyecto

```mermaid
graph TD
    A[Llaves-ubuntu-server-VPN/] --> B(README.md)
    A --> C(AGENTS.md)
    A --> D(documentacion/)
    A --> E(notas-internas/)
    A --> F(configuraciones/)
    A --> G(vpn-app/)
    A --> H(.gitignore)

    D --> D1[Guías, Listas de Usuarios (.docx, .xlsx, .txt)]
    D --> D2[ESTRUCTURA_PROYECTO.md]

    E --> E1[Llaves SSH privadas (.key)]
    E --> E2[Configuraciones .conf con claves privadas]
    E --> E3[Configuración del servidor VPN-SERVER]
    E --> E4[Carpeta 'programa-windows' (Binarios/Scripts)]

    F --> F1[Configuraciones públicas (sin claves privadas)]

    G --> G1(backend/)
    G --> G2(frontend/)

    G1 --> G1A(src/)
    G1 --> G1B(package.json)
    G1 --> G1C(database/)
    G1 --> G1D(config/)
    G1 --> G1E(node_modules/)

    G1A --> G1A1(index.js)
    G1A --> G1A2(routes/)
    G1A --> G1A3(models/)
    G1A --> G1A4(controllers/)
    G1A --> G1A5(middleware/)
    G1A --> G1A6(services/)

    G1A2 --> G1A2A[usuarios.js]
    G1A2 --> G1A2B[configuraciones.js]
    G1A2 --> G1A2C[logs.js]

    G1A3 --> G1A3A[Usuario.js]
    G1A3 --> G1A3B[Configuracion.js]
    G1A3 --> G1A3C[Log.js]
    G1A3 --> G1A3D[db.js]
    G1A3 --> G1A3E[index.js]

    G2 --> G2A(src/)
    G2 --> G2B(public/)
    G2 --> G2C(package.json)

    G2A --> G2A1(App.jsx)
    G2A --> G2A2(pages/)
    G2A --> G2A3(components/)
    G2A --> G2A4(services/)
    G2A --> G2A5(hooks/)
    G2A --> G2A6(assets/)

    G2A2 --> G2A2A[Usuarios.jsx]
    G2A2 --> G2A2B[Configuracion.jsx]
    G2A2 --> G2A2C[Logs.jsx]
```

## Descripción de Componentes

### Raíz del Proyecto (`Llaves-ubuntu-server-VPN/`)
*   `README.md`: Documentación principal sobre la configuración manual de WireGuard.
*   `AGENTS.md`: Guía para agentes IA con directrices del repositorio y detalles de seguridad.
*   `.gitignore`: Define los archivos y directorios que Git debe ignorar (crítico para secretos).

### `documentacion/`
Contiene la documentación pública y recursos para la gestión de la VPN.
*   `*.docx`: Guías de configuración y uso (ej. `DERCAS_VPN_WireGuard_Oracle.docx`).
*   `Listado de usuarios.xlsx`: Archivo Excel para el registro de usuarios.
*   `*.txt`: Instrucciones específicas o notas para usuarios (ej. `Usuario-CarlosO.txt`).
*   `ESTRUCTURA_PROYECTO.md`: Este archivo, que describe la organización del proyecto.

### `notas-internas/`
**Carpeta CRÍTICA - No debe subirse a Git (protegida por `.gitignore`).** Contiene archivos sensibles.
*   `ssh-key-YYYY-MM-DD.key`: Llaves SSH privadas para acceso al servidor.
*   `VPN-SERVER`: Archivo de configuración principal del servidor WireGuard (contiene clave privada del servidor).
*   `*.conf`: Archivos de configuración de cliente WireGuard con claves privadas.
*   `programa-windows/`: Directorio que contiene posibles binarios o scripts específicos para Windows.

### `configuraciones/`
Destinada a configuraciones de WireGuard que no contienen claves privadas y, por lo tanto, pueden ser compartidas o versionadas. Actualmente podría estar vacía o contener plantillas.

### `vpn-app/`
Una aplicación web en desarrollo para gestionar usuarios VPN de forma más dinámica.

#### `vpn-app/backend/`
El servidor API desarrollado en Node.js con Express y SQLite.
*   `src/`: Contiene el código fuente del backend.
    *   `index.js`: Punto de entrada de la aplicación.
    *   `routes/`: Define las rutas de la API REST para usuarios, configuraciones y logs.
    *   `models/`: Define los modelos de datos y la interacción con la base de datos SQLite.
        *   `db.js`: Manejo de la conexión a la base de datos.
        *   `Usuario.js`: Lógica para la gestión de usuarios.
        *   `Configuracion.js`: Lógica para la gestión de configuraciones globales.
        *   `Log.js`: Lógica para el registro de auditoría.
    *   `database/`: Contiene el archivo de base de datos `vpn.db` y scripts de inicialización.
*   `package.json`: Metadatos y dependencias del backend.

#### `vpn-app/frontend/`
La interfaz de usuario desarrollada en React con Vite.
*   `src/`: Contiene el código fuente de la interfaz.
    *   `pages/`: Componentes principales que representan las diferentes vistas de la aplicación (ej. `Usuarios.jsx`, `Configuracion.jsx`, `Logs.jsx`).
    *   `components/`: Componentes reutilizables de la interfaz.
    *   `services/`: Módulos para realizar llamadas a la API del backend.
    *   `assets/`: Archivos estáticos como imágenes o íconos.
    *   `hooks/`: Hooks personalizados de React.
*   `public/`: Archivos estáticos que se sirven directamente (ej. `index.html`).
*   `package.json`: Metadatos y dependencias del frontend.

---

**Nota:** La aplicación `vpn-app` busca automatizar algunas tareas que actualmente se realizan de forma manual y documentada en otras secciones del repositorio. Es importante asegurar la coherencia y la seguridad entre ambos enfoques.