# Ligas Deportivas

Monorepo para una plataforma web que administra ligas deportivas, torneos, fixtures y resultados. El repositorio agrupa una API construida con NestJS + Prisma, un frontend Flutter Web y los artefactos de infraestructura para ejecutar la solución completa en entornos locales o de despliegue.

## Características principales

### Backend API (NestJS + Prisma)
- Autenticación con registro, inicio de sesión, refresh de tokens, verificación de correo y recuperación de contraseña. ([backend/src/auth/auth.controller.ts](backend/src/auth/auth.controller.ts)) ([backend/src/mail/mail.service.ts](backend/src/mail/mail.service.ts)) ([backend/src/captcha/captcha.service.ts](backend/src/captcha/captcha.service.ts))
- Área personal para actualizar perfil, contraseña, correo y avatar usando almacenamiento local de archivos. ([backend/src/me/me.controller.ts](backend/src/me/me.controller.ts)) ([backend/src/storage/storage.service.ts](backend/src/storage/storage.service.ts))
- Administración de roles, permisos y usuarios con guardas basadas en RBAC y scopes personalizados. ([backend/src/rbac/roles.controller.ts](backend/src/rbac/roles.controller.ts)) ([backend/src/users/users.controller.ts](backend/src/users/users.controller.ts)) ([backend/src/prisma/base-seed.ts](backend/src/prisma/base-seed.ts))
- Gestión completa del dominio competitivo: ligas, clubes, torneos, zonas, categorías, jugadores y planteles, expuesta mediante controladores específicos. ([backend/src/competition/controllers/leagues.controller.ts](backend/src/competition/controllers/leagues.controller.ts)) ([backend/src/competition/controllers/clubs.controller.ts](backend/src/competition/controllers/clubs.controller.ts)) ([backend/src/competition/controllers/tournaments.controller.ts](backend/src/competition/controllers/tournaments.controller.ts)) ([backend/src/competition/controllers/zones.controller.ts](backend/src/competition/controllers/zones.controller.ts)) ([backend/src/competition/controllers/players.controller.ts](backend/src/competition/controllers/players.controller.ts))
- Generación automática de fixture ida y vuelta (método del círculo), bloqueo del torneo y creación masiva de partidos. ([backend/src/competition/services/fixture.service.ts](backend/src/competition/services/fixture.service.ts))
- Registro de resultados por categoría, control de adjuntos, bitácora de cambios y disparo del recálculo de tablas tras cada cierre. ([backend/src/competition/services/matches.service.ts](backend/src/competition/services/matches.service.ts))
- Servicio de standings que actualiza tablas zonales, por torneo y por liga aplicando la configuración de puntos definida en cada torneo. ([backend/src/standings/standings.service.ts](backend/src/standings/standings.service.ts))
- Configuración centralizada, mailer SMTP y verificación de captchas integrados como módulos reutilizables. ([backend/src/app.module.ts](backend/src/app.module.ts)) ([backend/src/mail/mail.module.ts](backend/src/mail/mail.module.ts)) ([backend/src/captcha/captcha.service.ts](backend/src/captcha/captcha.service.ts))

### Frontend Flutter Web
- Router con protección de rutas, shell con `NavigationRail` colapsable y menú de usuario persistente en `SharedPreferences`. ([frontend/lib/core/router/app_router.dart](frontend/lib/core/router/app_router.dart)) ([frontend/lib/features/shared/widgets/app_shell.dart](frontend/lib/features/shared/widgets/app_shell.dart))
- Cliente HTTP basado en `dio` con interceptores para JWT y renovación automática de sesión. ([frontend/lib/services/api_client.dart](frontend/lib/services/api_client.dart)) ([frontend/lib/services/auth_controller.dart](frontend/lib/services/auth_controller.dart))
- Pantallas de gestión para ligas, fixture y configuración de cuenta, incluyendo formularios adaptables y asistentes de guardado rápido. ([frontend/lib/features/leagues/presentation/leagues_page.dart](frontend/lib/features/leagues/presentation/leagues_page.dart)) ([frontend/lib/features/fixtures/presentation/fixtures_page.dart](frontend/lib/features/fixtures/presentation/fixtures_page.dart)) ([frontend/lib/features/settings/account_settings_page.dart](frontend/lib/features/settings/account_settings_page.dart))

### Infraestructura
- Orquestación con Docker Compose que levanta PostgreSQL, MinIO, Mailhog, la API NestJS y el frontend web compilado. ([infra/docker-compose.yml](infra/docker-compose.yml))

## Estructura del repositorio

```
backend/   → API REST en Node.js + NestJS + Prisma
frontend/  → Aplicación Flutter Web
infra/     → Docker Compose y configuración de servicios auxiliares
docs/      → Documentación técnica y funcional
```

## Requisitos

- Node.js 20 o superior para el backend. ([backend/package.json](backend/package.json))
- PostgreSQL 15 o superior (local o en contenedor). ([infra/docker-compose.yml](infra/docker-compose.yml))
- Flutter 3.19+ para ejecutar el cliente web. ([frontend/pubspec.yaml](frontend/pubspec.yaml))
- Docker Desktop/Engine (opcional) para levantar la pila completa con `docker compose`. ([infra/docker-compose.yml](infra/docker-compose.yml))

## Configuración del backend

1. Copia el archivo de entorno base (`backend/.env`) o crea uno nuevo tomando como referencia el existente para definir conexión a la base, secretos JWT, credenciales SMTP y almacenamiento. ([backend/.env](backend/.env))
2. Instala dependencias y genera el cliente de Prisma:
   ```bash
   cd backend
   npm install
   npx prisma generate
   ```
3. Genera una migración inicial fresca (se eliminaron las migraciones anteriores) y aplica los datos base (roles, permisos, usuario administrador, datos de ejemplo):
   ```bash
   npx prisma migrate dev
   npm run seed
   ```
   El usuario administrador por defecto es `admin@ligas.local` / `Admin123`, y puede personalizarse mediante variables de entorno antes de ejecutar el seed. ([backend/src/prisma/base-seed.ts](backend/src/prisma/base-seed.ts))
4. Levanta la API en modo desarrollo con recarga en caliente:
   ```bash
   npm run start:dev
   ```
   Todos los endpoints quedan disponibles bajo `http://localhost:3000/api/v1` y comparten tuberías globales de validación y CORS configurados para el frontend. ([backend/src/main.ts](backend/src/main.ts))

### Migraciones Prisma (dev vs prod)

- **Local/desarrollo:** usa `npx prisma migrate dev` para aplicar cambios y mantener el historial de migraciones en tu entorno.
- **Producción/staging:** usa `npx prisma migrate deploy` (sin generar nuevas migraciones).
- **Validación legacy/limpia:** confirma que la tabla real de torneos es `tournament` (minúsculas sin comillas) antes de aplicar migraciones recientes:
  ```bash
  psql "$DATABASE_URL" -c "SELECT to_regclass('public.tournament') AS tournament_table;"
  ```
  En bases legacy debería devolver `tournament`; en bases limpias asegúrate de tener el esquema base aplicado antes de correr migraciones nuevas (por ejemplo, generando una migración inicial o restaurando un dump).
- **Bases antiguas/inconsistentes:** las migraciones ahora crean y alteran la tabla `"SiteIdentity"` de forma defensiva. Si necesitas simular un estado viejo, puedes eliminarla y volver a correr el deploy:
  ```bash
  psql "$DATABASE_URL" -c 'DROP TABLE IF EXISTS "SiteIdentity";'
  npx prisma migrate deploy
  ```
- **Bootstrap desde cero:** en producción/staging, el flujo recomendado es crear la base vacía y ejecutar `npx prisma migrate deploy`. En local, `npx prisma migrate dev` es el camino recomendado para recrear y evolucionar el esquema.

> Nota sobre naming: para tablas nuevas usa snake_case en minúsculas sin comillas. La tabla de torneos usa `tournament` (minúsculas) por compatibilidad legacy, mientras que `"SiteIdentity"` mantiene PascalCase con comillas por compatibilidad histórica. Si ejecutas SQL manual, respeta los nombres exactos para evitar conflictos con variaciones en minúsculas.

> Migración baseline: `backend/prisma/migrations/20250101000000_baseline_init` crea el esquema core (incluye `tournament`, `"SiteIdentity"` y el resto de las tablas base). `prisma migrate deploy` sobre una DB vacía debe aplicarla antes de las migraciones incrementales.

### Correo SMTP sin Docker

Si ejecutas el backend directamente desde Visual Studio Code o desde la raíz del repositorio (por ejemplo con `npm run start:dev --prefix backend`), NestJS ahora carga automáticamente el archivo `backend/.env` además de cualquier `.env` ubicado en la raíz. Aun así, necesitas reemplazar los valores de Mailhog por las credenciales reales del proveedor SMTP que vayas a usar.

1. Genera una contraseña de aplicación en el proveedor (por ejemplo, en Gmail habilita la verificación en dos pasos y crea una contraseña de aplicación para SMTP).
2. Edita `backend/.env` y configura el bloque **Email (SMTP)**, por ejemplo:
   ```ini
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=465
   SMTP_USER=tu_correo@gmail.com
   SMTP_PASS=contraseña_de_aplicacion
   SMTP_FROM="Tu Nombre <tu_correo@gmail.com>"
   SMTP_SECURE=true
   ```
   También puedes usar STARTTLS en el puerto 587 con `SMTP_REQUIRE_TLS=true`, `SMTP_IGNORE_TLS=false` y `SMTP_TLS_REJECT_UNAUTHORIZED=true` según lo requiera tu proveedor.
3. Reinicia el backend (`npm run start:dev`) para que NestJS reconstruya el transporte de correo con los nuevos valores.

Si la API no puede conectarse al servidor SMTP, el panel te mostrará el error y los logs incluirán el host y puerto utilizados para ayudarte a diagnosticar la configuración.

### Scripts de calidad

- `npm run lint` ejecuta ESLint sobre `src/`.
- `npm test` corre las pruebas unitarias con Jest.
- `npm run test:cov` genera el reporte de cobertura. ([backend/package.json](backend/package.json))

## Configuración del frontend

1. Instala dependencias y genera código:
   ```bash
   cd frontend
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
2. Ejecuta la aplicación en Chrome apuntando al backend local:
   ```bash
   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api/v1
   ```
   El cliente lee la URL base desde la variable `API_BASE_URL` y adjunta tokens automáticamente en cada solicitud. ([frontend/lib/services/api_client.dart](frontend/lib/services/api_client.dart))
3. Pruebas y análisis estático:
   ```bash
   flutter test
   flutter analyze
   ```


## Alta rápida de jugadores por escaneo DNI (PDF417)

### Uso
1. En **Jugadores**, usar el botón **Escanear DNI** (ícono QR).
2. En Android/Chrome Web se solicita cámara con preferencia por la trasera (`capture=environment`).
3. El frontend envía la imagen como `multipart/form-data` a `POST /players/dni/scan`.
4. Si la lectura es correcta, se muestra un modal de confirmación con: apellido, nombre, sexo, DNI y fecha de nacimiento.
5. Solo al confirmar se crea el jugador con `POST /players`.

### Endpoint backend
- `POST /api/v1/players/dni/scan`
  - Campo: `file`
  - Respuesta: `{ lastName, firstName, sex, dni, birthDate }`
  - Errores: `400` sin archivo, `415` tipo inválido, `422` si no se puede decodificar o faltan datos.
- La imagen se procesa en memoria (multer `memoryStorage`) y se descarta inmediatamente.

### Variables de entorno relacionadas
- `DNI_SCAN_DECODER_COMMAND`: comando externo para decodificar PDF417 (lee bytes de imagen por `stdin` y responde el payload por `stdout`). Si no se define, backend usa por defecto `/usr/local/bin/dni-pdf417-decoder --format PDF417`.
- `DNI_SCAN_DEBUG=true`: loguea solo estado general (`ok/no`) de la decodificación, sin PII.

En Docker, el backend instala `zxing-cpp-tools` y publica el wrapper `/usr/local/bin/dni-pdf417-decoder`, que usa archivos temporales únicamente en `/tmp` y los borra siempre al finalizar.

### Limitaciones prácticas
- La lectura depende de enfoque, luz y reflejos del DNI.
- Si falla, reintentar acercando el código PDF417 y mejorando iluminación.

## Infraestructura con Docker Compose

Puedes levantar toda la plataforma con un único comando:

```bash
cd infra
docker compose up --build
```

Antes de iniciar, crea el archivo `infra/.env` con las variables requeridas:

```ini
POSTGRES_PASSWORD=ligas_db_password_2024
JWT_ACCESS_SECRET=8c50d5110a7a4f1c8f3b1c86b5e8a4f3
JWT_REFRESH_SECRET=2e94f8c2d7c44109b7f3f71c49c5d9ad
APP_URL=http://ligas.local
FRONTEND_URL=http://ligas.local
# DB_SCHEMA_ENFORCEMENT=strict
# SMTP_HOST=mailhog
# SMTP_PORT=1025
# SMTP_USER=
# SMTP_PASS=
# SMTP_FROM=noreply@ligas.local
```

Los servicios quedan detrás del proxy Nginx en `http://localhost`, que enruta `/api` y `/storage` al backend y sirve el frontend para el resto de las rutas. La base de datos y los contenedores internos no exponen puertos hacia el host para evitar accesos directos; si necesitas acceder a Mailhog o a PostgreSQL desde fuera del clúster, utiliza `docker compose exec` o agrega temporalmente un `ports:` en tu entorno local.

La base de datos y los archivos subidos se persisten en volúmenes (`postgres-data`, `backend-storage`) definidos en el Compose.

La base de datos y los archivos subidos se persisten en volúmenes (`postgres-data`, `backend-storage`) definidos en el Compose.

Las variables de entorno del contenedor `backend` se basan en los mismos nombres definidos en `backend/.env`, por lo que puedes adaptarlas para entornos de staging o producción. ([infra/docker-compose.yml](infra/docker-compose.yml))

Para controlar el enforcement del esquema, define `DB_SCHEMA_ENFORCEMENT=strict|soft` (por defecto `strict`). En `strict`, el backend aborta el arranque si la DB no está migrada; en `soft`, la API inicia pero responde 503 en `/api/v1/health/db` y en endpoints dependientes de la DB hasta que se ejecuten las migraciones.

### Migraciones Prisma en despliegues

En producción/staging las migraciones se ejecutan **antes** de levantar el backend, usando un servicio separado llamado `migrate`. Esto evita loops de reinicio ante errores y te permite controlar los despliegues de esquema.

#### Despliegue recomendado (único camino soportado)

El flujo obligatorio y automatizable es ejecutar `infra/deploy.sh`, que realiza en orden:

1. `docker compose down` (sin `-v` por defecto, con opción para resetear DB).
2. `git fetch --all` + `git pull` (opcionalmente checkout de una rama).
3. `docker compose up -d db` y espera el healthcheck.
4. `docker compose run --rm migrate` (si falla, el deploy se aborta).
5. `docker compose up -d backend frontend`.
6. `docker compose ps` y logs resumidos si algo queda unhealthy.

```bash
cd infra
./deploy.sh
```

Si necesitas poblar datos base en entornos no productivos, agrega `--seed` para ejecutar el seed dentro del job de migraciones:

```bash
cd infra
./deploy.sh --seed
```

También puedes ejecutar el seed con `RUN_SEED=1`:

```bash
cd infra
RUN_SEED=1 ./deploy.sh
```

Ejemplos adicionales:

```bash
# Resetear DB (Peligroso: elimina volúmenes)
./deploy.sh --reset-db

# Evitar down previo (debug)
./deploy.sh --no-down

# Deploy de una rama específica
./deploy.sh --branch feature/nueva
```

Flujo recomendado (orden correcto):

```bash
cd infra
./deploy.sh
```

En CI/CD, ejecuta el job de migraciones como paso previo al despliegue del backend:

```bash
cd infra
./deploy.sh
```

#### Failed migrations recovery

Si el deploy falla con migraciones fallidas en `_prisma_migrations` (por ejemplo cuando una migración fue corregida en el repo pero quedó marcada como failed en una DB existente), primero resuelve el estado y luego vuelve a correr el deploy.

**Cómo detectar migraciones fallidas**

- El job `migrate` imprime las migraciones con `finished_at` y `rolled_back_at` en `NULL`.
- También puedes listarlas manualmente con el helper:
  ```bash
  cd infra
  ./recover_failed_migrations.sh
  ```

**Qué significa rolled-back vs applied**

- `--rolled-back`: úsalo si la migración falló y **no** aplicaste cambios manualmente en la DB. Marca la migración como rollback para que puedas reintentar el deploy.
- `--applied`: úsalo solo si **ya aplicaste manualmente** los cambios de esa migración y quieres marcarla como aplicada.

**Ejemplos con recover_failed_migrations.sh**

```bash
# Listar migraciones fallidas y comandos recomendados
cd infra
./recover_failed_migrations.sh

# Marcar una migración como rolled-back
./recover_failed_migrations.sh --rollback 20240101000000_example_migration

# Marcar una migración como applied (si ya aplicaste cambios manualmente)
./recover_failed_migrations.sh --apply 20240101000000_example_migration
```

Luego vuelve a ejecutar:

```bash
cd infra
./deploy.sh
```

En CI/CD, el stage/job `migrate` debe ser obligatorio y el despliegue del backend debe depender de que las migraciones finalicen con éxito. Si el job `migrate` falla, **no** se debe iniciar el backend.

El contenedor `backend` **no** ejecuta migraciones automáticamente, por lo que `docker compose run --rm backend <comando>` ejecuta el comando solicitado sin interceptarlo.

#### Validación automatizable de migraciones

Para validar que `prisma migrate deploy` funciona en una DB limpia, puedes ejecutar:

```bash
cd infra
./validate-migrations.sh
```

El script recrea el volumen de PostgreSQL, levanta la DB, corre `migrate` y limpia los recursos. Úsalo en CI/CD o en local antes de despliegues críticos.

## Datos de ejemplo

Si necesitas poblar rápidamente la tabla de jugadores con datos de prueba, puedes ejecutar el comando `npm run seed:players` dentro del directorio `backend`. El script utiliza Prisma y la misma conexión configurada en `DATABASE_URL`, por lo que siempre apuntará a la base correcta. Inserta 66 jugadores con la distribución de edades y géneros solicitada y sin asociación a clubes.

Antes de correrlo, asegúrate de haber aplicado las migraciones de Prisma para que la tabla `Player` exista (por ejemplo con `npx prisma migrate deploy` o `npx prisma migrate dev`).

Si prefieres interactuar directamente con PostgreSQL, el archivo SQL original sigue disponible en `backend/prisma/seed_players.sql`.

Ejecuta el script con `psql`, reemplazando las variables de conexión por las de tu entorno:

```bash
psql \
  --host=<HOST> \
  --port=<PUERTO> \
  --username=<USUARIO> \
  --dbname=<BASE_DE_DATOS> \
  --file=backend/prisma/seed_players.sql
```

Si estás usando Docker Compose, puedes aprovechar el contenedor de PostgreSQL directamente:

```bash
cd infra
docker compose exec -T db \
  psql --username=postgres --dbname=ligas \
  < ../backend/prisma/seed_players.sql
```

El script detecta automáticamente en qué esquema existe la tabla `Player`, ajusta el `search_path` y utiliza `ON CONFLICT ("dni") DO NOTHING`, por lo que puedes ejecutarlo varias veces sin duplicar registros. Si la tabla no está presente recibirás un mensaje indicando que debes aplicar las migraciones primero. Adapta el nombre de la base, usuario o ruta del archivo según tu configuración (por ejemplo, si cambiaste `POSTGRES_DB`, `POSTGRES_USER` o ejecutas el comando desde otro directorio).

## Documentación adicional

- [Arquitectura y componentes](docs/architecture.md)
- [Guía de desarrollo y entornos](docs/desarrollo-entornos.md)
- [Respaldo y restauración de la base de datos](docs/postgres-backup-restore.md)

Ambos documentos detallan la estructura modular, flujos de datos, recomendaciones de entornos y procedimientos de trabajo colaborativo.
