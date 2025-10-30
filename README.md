# Ligas Deportivas

Monorepo para una plataforma web que administra ligas deportivas, torneos, fixtures y resultados. El repositorio agrupa una API construida con NestJS + Prisma, un frontend Flutter Web y los artefactos de infraestructura para ejecutar la solución completa en entornos locales o de despliegue.

## Características principales

### Backend API (NestJS + Prisma)
- Autenticación con registro, inicio de sesión, refresh de tokens, verificación de correo y recuperación de contraseña.【F:backend/src/auth/auth.controller.ts†L14-L55】【F:backend/src/mail/mail.service.ts†L16-L53】【F:backend/src/captcha/captcha.service.ts†L11-L39】
- Área personal para actualizar perfil, contraseña, correo y avatar usando almacenamiento local de archivos.【F:backend/src/me/me.controller.ts†L13-L45】【F:backend/src/storage/storage.service.ts†L9-L48】
- Administración de roles, permisos y usuarios con guardas basadas en RBAC y scopes personalizados.【F:backend/src/rbac/roles.controller.ts†L9-L33】【F:backend/src/users/users.controller.ts†L13-L39】【F:backend/src/prisma/base-seed.ts†L4-L118】
- Gestión completa del dominio competitivo: ligas, clubes, torneos, zonas, categorías, jugadores y planteles, expuesta mediante controladores específicos.【F:backend/src/competition/controllers/leagues.controller.ts†L11-L34】【F:backend/src/competition/controllers/clubs.controller.ts†L11-L73】【F:backend/src/competition/controllers/tournaments.controller.ts†L11-L88】【F:backend/src/competition/controllers/zones.controller.ts†L11-L88】【F:backend/src/competition/controllers/players.controller.ts†L11-L96】
- Generación automática de fixture ida y vuelta (método del círculo), bloqueo del torneo y creación masiva de partidos.【F:backend/src/competition/services/fixture.service.ts†L17-L104】
- Registro de resultados por categoría, control de adjuntos, bitácora de cambios y disparo del recálculo de tablas tras cada cierre.【F:backend/src/competition/services/matches.service.ts†L19-L133】【F:backend/src/competition/services/matches.service.ts†L134-L199】
- Servicio de standings que actualiza tablas zonales, por torneo y por liga aplicando la configuración de puntos definida en cada torneo.【F:backend/src/standings/standings.service.ts†L1-L196】
- Configuración centralizada, mailer SMTP y verificación de captchas integrados como módulos reutilizables.【F:backend/src/app.module.ts†L3-L28】【F:backend/src/mail/mail.module.ts†L1-L28】【F:backend/src/captcha/captcha.service.ts†L11-L39】

### Frontend Flutter Web
- Router con protección de rutas, shell con `NavigationRail` colapsable y menú de usuario persistente en `SharedPreferences`.【F:frontend/lib/core/router/app_router.dart†L7-L88】【F:frontend/lib/features/shared/widgets/app_shell.dart†L8-L92】
- Cliente HTTP basado en `dio` con interceptores para JWT y renovación automática de sesión.【F:frontend/lib/services/api_client.dart†L1-L56】【F:frontend/lib/services/auth_controller.dart†L11-L113】
- Pantallas de gestión para ligas, fixture y configuración de cuenta, incluyendo formularios adaptables y asistentes de guardado rápido.【F:frontend/lib/features/leagues/presentation/leagues_page.dart†L1-L164】【F:frontend/lib/features/fixtures/presentation/fixtures_page.dart†L1-L78】【F:frontend/lib/features/settings/account_settings_page.dart†L1-L140】

### Infraestructura
- Orquestación con Docker Compose que levanta PostgreSQL, MinIO, Mailhog, la API NestJS y el frontend web compilado.【F:infra/docker-compose.yml†L1-L49】

## Estructura del repositorio

```
backend/   → API REST en Node.js + NestJS + Prisma
frontend/  → Aplicación Flutter Web
infra/     → Docker Compose y configuración de servicios auxiliares
docs/      → Documentación técnica y funcional
```

## Requisitos

- Node.js 20 o superior para el backend.【F:backend/package.json†L1-L77】
- PostgreSQL 15 o superior (local o en contenedor).【F:infra/docker-compose.yml†L1-L21】
- Flutter 3.19+ para ejecutar el cliente web.【F:frontend/pubspec.yaml†L1-L25】
- Docker Desktop/Engine (opcional) para levantar la pila completa con `docker compose`.【F:infra/docker-compose.yml†L1-L49】

## Configuración del backend

1. Copia el archivo de entorno base (`backend/.env`) o crea uno nuevo tomando como referencia el existente para definir conexión a la base, secretos JWT, credenciales SMTP y almacenamiento.【F:backend/.env†L1-L29】
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
   El usuario administrador por defecto es `admin@ligas.local` / `Admin123`, y puede personalizarse mediante variables de entorno antes de ejecutar el seed.【F:backend/src/prisma/base-seed.ts†L120-L204】
4. Levanta la API en modo desarrollo con recarga en caliente:
   ```bash
   npm run start:dev
   ```
   Todos los endpoints quedan disponibles bajo `http://localhost:3000/api/v1` y comparten tuberías globales de validación y CORS configurados para el frontend.【F:backend/src/main.ts†L13-L44】

### Scripts de calidad

- `npm run lint` ejecuta ESLint sobre `src/`.
- `npm test` corre las pruebas unitarias con Jest.
- `npm run test:cov` genera el reporte de cobertura.【F:backend/package.json†L6-L20】

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
   El cliente lee la URL base desde la variable `API_BASE_URL` y adjunta tokens automáticamente en cada solicitud.【F:frontend/lib/services/api_client.dart†L9-L55】
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

Los servicios quedarán disponibles en:
- API: `http://localhost:3000`
- Frontend estático: `http://localhost:8080`
- Mailhog (correo de prueba): `http://localhost:8025`
- Consola MinIO: `http://localhost:9001`
- PostgreSQL: `localhost:5432`

Las variables de entorno del contenedor `backend` se basan en los mismos nombres definidos en `backend/.env`, por lo que puedes adaptarlas para entornos de staging o producción.【F:infra/docker-compose.yml†L15-L49】

## Documentación adicional

- [Arquitectura y componentes](docs/architecture.md)
- [Guía de desarrollo y entornos](docs/desarrollo-entornos.md)

Ambos documentos detallan la estructura modular, flujos de datos, recomendaciones de entornos y procedimientos de trabajo colaborativo.
