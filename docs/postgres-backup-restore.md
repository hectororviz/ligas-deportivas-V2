# Instructivo de respaldo y restauración de la base de datos

Este instructivo describe cómo generar y restaurar respaldos de la base de datos PostgreSQL 18 empleada en el proyecto, cubriendo los sistemas operativos Ubuntu, Arch Linux y Windows (mediante la psql shell incluida en la instalación oficial).

## Consideraciones previas

- Asegúrate de contar con credenciales válidas (usuario, contraseña y host) y conocer el nombre de la base de datos.
- Los ejemplos utilizan variables de entorno para evitar exponer contraseñas en texto plano. Ajusta los comandos según corresponda.
- `pg_dump` crea copias de seguridad lógicas y `psql` o `pg_restore` permiten restaurarlas.
- Los comandos se ejecutan con PostgreSQL 18; versiones anteriores podrían requerir ajustes menores.

## Ubuntu

### Respaldo

```bash
export PGPASSWORD="<tu_contraseña>"
pg_dump \
  --host <host> \
  --port 5432 \
  --username <usuario> \
  --format custom \
  --file ~/respaldos/$(date +"%Y%m%d_%H%M")_basededatos.backup \
  <nombre_base>
```

- `--format custom` genera un archivo comprimido y flexible para restaurar objetos individuales si es necesario.
- Asegúrate de que el directorio `~/respaldos/` exista o ajústalo a tu ruta preferida.

### Restauración

```bash
export PGPASSWORD="<tu_contraseña>"
pg_restore \
  --host <host> \
  --port 5432 \
  --username <usuario> \
  --dbname <nombre_base> \
  --clean \
  --create \
  ~/respaldos/<archivo.backup>
```

- Usa `--clean` para eliminar objetos antes de recrearlos y evitar conflictos.
- Si la base no existe, `--create` la generará a partir del respaldo.

## Arch Linux

En Arch Linux, los paquetes de PostgreSQL instalan utilidades en `/usr/bin`. Antes de operar, inicia el servicio si aún no está ejecutándose:

```bash
sudo systemctl start postgresql
```

### Respaldo

```bash
export PGPASSWORD="<tu_contraseña>"
/usr/bin/pg_dump \
  --host <host> \
  --port 5432 \
  --username <usuario> \
  --format tar \
  --file ~/respaldos/$(date +"%Y%m%d_%H%M")_basededatos.tar \
  <nombre_base>
```

- El formato `tar` es útil si deseas inspeccionar el contenido con herramientas estándar.

### Restauración

```bash
export PGPASSWORD="<tu_contraseña>"
/usr/bin/pg_restore \
  --host <host> \
  --port 5432 \
  --username <usuario> \
  --dbname <nombre_base> \
  --clean \
  ~/respaldos/<archivo.tar>
```

- Omite `--create` si prefieres crear manualmente la base antes de restaurar.

## Windows (psql Shell)

La instalación oficial de PostgreSQL para Windows incluye la *SQL Shell (psql)* y las utilidades `pg_dump` y `pg_restore`. Para ejecutar los comandos:

1. Abre el menú inicio y ejecuta **SQL Shell (psql)**.
2. Ingresa los datos solicitados (host, puerto, nombre de la base, usuario). Cuando se solicite la contraseña, escríbela y presiona Enter.
3. Dentro de la shell, usa `\!` para ejecutar comandos del sistema.

### Respaldo

```sql
\! "C:\\Program Files\\PostgreSQL\\18\\bin\\pg_dump.exe" \
    --host <host> \
    --port 5432 \
    --username <usuario> \
    --format custom \
    --file "C:\\respaldos\\%DATE:~-4%%DATE:~4,2%%DATE:~7,2%_%TIME:~0,2%%TIME:~3,2%_basededatos.backup" \
    <nombre_base>
```

- Asegúrate de que `C:\\respaldos` exista.
- El uso de `%DATE%` y `%TIME%` crea nombres de archivo con marca temporal. Ajusta la regionalización si tu formato de fecha difiere.

### Restauración

```sql
\! "C:\\Program Files\\PostgreSQL\\18\\bin\\pg_restore.exe" \
    --host <host> \
    --port 5432 \
    --username <usuario> \
    --dbname <nombre_base> \
    --clean \
    --create \
    "C:\\respaldos\\<archivo.backup>"
```

- Para evitar introducir la contraseña en cada ejecución, define la variable de entorno `PGPASSWORD` en Windows (Panel de control → Sistema → Configuración avanzada → Variables de entorno) antes de abrir la *SQL Shell*.
- Si prefieres usar `psql` directamente para restaurar archivos `.sql` generados con `pg_dump --format plain`, ejecuta:

```sql
\! "C:\\Program Files\\PostgreSQL\\18\\bin\\psql.exe" \
    --host <host> \
    --port 5432 \
    --username <usuario> \
    --dbname <nombre_base> \
    --file "C:\\respaldos\\<archivo.sql>"
```

## Verificación posterior a la restauración

1. Revisa que el proceso finalice sin errores en la consola.
2. Conéctate a la base de datos y verifica que las tablas críticas contengan registros.
3. Si utilizaste `--clean`, confirma que no haya objetos faltantes (funciones, índices, etc.).

## Automatización y buenas prácticas

- Programa respaldos periódicos con `cron` (Linux) o el Programador de tareas (Windows).
- Comprueba regularmente la integridad de los archivos generados intentando restaurarlos en un entorno de prueba.
- Mantén los respaldos en ubicaciones seguras y considera cifrarlos antes de almacenarlos externamente.
- Documenta cada restauración realizada (fecha, responsable y resultados) para auditoría y trazabilidad.

