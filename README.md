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
3. Ejecuta las migraciones y datos base (roles, permisos, usuario administrador, datos de ejemplo):
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
# SMTP_HOST=mailhog
# SMTP_PORT=1025
# SMTP_USER=
# SMTP_PASS=
# SMTP_FROM=noreply@ligas.local
```

Los servicios quedan detrás del proxy Nginx en `http://localhost`, que enruta `/api` y `/storage` al backend y sirve el frontend para el resto de las rutas. La base de datos y los contenedores internos no exponen puertos hacia el host para evitar accesos directos; si necesitas acceder a Mailhog o a PostgreSQL desde fuera del clúster, utiliza `docker compose exec` o agrega temporalmente un `ports:` en tu entorno local.

La base de datos y los archivos subidos se persisten en volúmenes (`postgres-data`, `backend-storage`) definidos en el Compose.

Las variables de entorno del contenedor `backend` se basan en los mismos nombres definidos en `backend/.env`, por lo que puedes adaptarlas para entornos de staging o producción. ([infra/docker-compose.yml](infra/docker-compose.yml))

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
