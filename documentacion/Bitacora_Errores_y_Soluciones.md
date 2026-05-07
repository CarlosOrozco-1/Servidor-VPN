# Bitácora de Errores y Soluciones (Troubleshooting)

Este documento registra los problemas detectados en la plataforma VPN Manager y las soluciones aplicadas para su resolución. Sirve como base de conocimiento para futuros mantenimientos.

## 📅 03 de Mayo de 2026

### 1. Error 500 al generar claves automáticamente (Falta de dependencia `wg`)

*   **Descripción del Problema:**
    Al intentar crear un usuario en donde el sistema debía generar el par de claves automáticamente, el backend arrojaba un Error 500. El log indicaba `wg: command not found`.
*   **Causa Raíz:**
    La función `generarClavesWireGuard` en `usuarios.js` utilizaba `execSync('wg genkey')` para llamar a la herramienta WireGuard directamente en la terminal. Al correr el entorno de desarrollo en una máquina que no tiene WireGuard instalado, el proceso de Node.js fallaba.
*   **Solución Aplicada:**
    Se eliminó la dependencia a la terminal y se implementó la librería nativa `tweetnacl` en el backend. Ahora las claves se generan usando matemáticas puras de Javascript con el algoritmo Curve25519 (`nacl.box.keyPair()`), que es exactamente el mismo estándar de encriptación que usa WireGuard. Esto hace que el backend sea agnóstico a la máquina donde se ejecuta.

---

### 2. Error 500 al registrar usuario con llave pública propia (Constraint NOT NULL)

*   **Descripción del Problema:**
    Al registrar un usuario especificando la clave pública proveniente de un dispositivo externo (ej. Android o Windows), la aplicación fallaba con un Error 500.
*   **Causa Raíz:**
    El log mostraba `NOT NULL constraint failed: usuarios.clave_privada`. Cuando el usuario proporciona su propia llave, el sistema no conoce la llave privada. Originalmente, el código enviaba un valor `null` a la base de datos, pero la estructura SQLite exigía un valor obligatorio (`NOT NULL`).
*   **Solución Aplicada:**
    Se modificó la lógica en la ruta `POST /usuarios`. Ahora, cuando el usuario manda su propia llave pública, el campo de la clave privada se guarda en la base de datos como el texto de control `[GENERADA EN EL DISPOSITIVO]`, satisfaciendo la regla estricta de la base de datos sin comprometer la lógica de seguridad.

---

### 3. Error 500 al asignar IP repetida (UNIQUE constraint failed: usuarios.ip_asignada)

*   **Descripción del Problema:**
    Al sobrepasar la asignación de la IP terminada en `.9` e intentar crear un nuevo usuario, el sistema fallaba indicando que la IP estaba duplicada.
*   **Causa Raíz:**
    La función `Usuario.getNextIp()` utilizaba SQL para encontrar la IP más alta: `ORDER BY ip_asignada DESC`. Dado que las IPs se guardaban como texto (String), SQLite ordenaba `.9` por encima de `.10` (porque el carácter '9' es mayor que '1'). Como resultado, el código consideraba que la `.9` era la IP más alta y volvía a intentar crear la IP `.10`, chocando con el registro ya existente.
*   **Solución Aplicada:**
    Se reescribió la lógica en el modelo `Usuario.js`. Ahora la función extrae todas las IPs, las separa por sus puntos y utiliza `parseInt` en Javascript para evaluar y comparar matemáticamente el último octeto. Esto garantiza que el sistema siempre encuentre el número más alto real y sume 1 correctamente.
