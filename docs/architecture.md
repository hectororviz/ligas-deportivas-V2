# Arquitectura y componentes

Este documento describe la arquitectura actual del proyecto **Ligas Deportivas**, los módulos principales de cada capa y los flujos que conectan backend, frontend e infraestructura.

## 1. Visión general del sistema

- **Backend**: API REST construida con NestJS, organizada en módulos funcionales (autenticación, usuarios, RBAC, dominio competitivo, métricas) y respaldada por Prisma sobre PostgreSQL.【F:backend/src/app.module.ts†L3-L28】【F:backend/prisma/schema.prisma†L1-L401】
- **Frontend**: SPA desarrollada en Flutter Web con Riverpod para estado y `go_router` para navegación, que consume la API y respeta permisos del usuario autenticado.【F:frontend/lib/core/router/app_router.dart†L7-L88】【F:frontend/lib/services/auth_controller.dart†L11-L204】
- **Infraestructura**: Docker Compose levanta PostgreSQL, MinIO, Mailhog y contenedores para backend y frontend, reproduciendo un entorno integrado de desarrollo/demo.【F:infra/docker-compose.yml†L1-L49】

## 2. Backend

### 2.1 Configuración transversal
- `ConfigModule` centraliza variables de entorno (base de datos, JWT, SMTP, almacenamiento) cargadas al inicio de la aplicación.【F:backend/src/app.module.ts†L3-L28】【F:backend/.env†L1-L29】
- `main.ts` define prefijo global `api/v1`, CORS hacia el frontend, tuberías de validación y exposición de archivos estáticos desde `storage/uploads`.【F:backend/src/main.ts†L13-L44】

### 2.2 Autenticación y cuenta
- `AuthController` ofrece registro, login local, refresco y revocación de tokens, verificación de correo y recuperación de contraseña. La lógica complementa con envío de mails y validación de captcha configurables.【F:backend/src/auth/auth.controller.ts†L14-L55】【F:backend/src/mail/mail.service.ts†L16-L53】【F:backend/src/captcha/captcha.service.ts†L11-L39】
- El módulo `me` expone endpoints para obtener/editar el perfil, solicitar y confirmar cambio de correo, actualizar contraseña y subir un avatar. Los archivos se persisten en disco con `StorageService`, que genera rutas públicas compatibles con despliegues detrás de CDN o reverse proxies.【F:backend/src/me/me.controller.ts†L13-L45】【F:backend/src/storage/storage.service.ts†L9-L48】

### 2.3 Control de acceso
- El guard `PermissionsGuard` evalúa los permisos declarativos en cada handler combinando módulo, acción y alcance antes de ejecutar el controlador.【F:backend/src/rbac/permissions.guard.ts†L1-L55】
- `RolesController` y `UsersController` permiten listar roles, catálogos de permisos y asignar roles/alcances a usuarios autenticados con privilegios adecuados.【F:backend/src/rbac/roles.controller.ts†L9-L33】【F:backend/src/users/users.controller.ts†L13-L39】
- El seed inicial crea permisos, roles base (Administrador, Colaborador, Delegado, DT, Usuario) y asigna la matriz inicial de scopes, además de asegurar un usuario administrador configurable por variables de entorno.【F:backend/src/prisma/base-seed.ts†L4-L204】

### 2.4 Dominio competitivo
- El módulo `competition` agrupa controladores y servicios especializados para ligas, clubes, torneos, zonas, categorías, planteles, jugadores y equipos. Cada entidad expone endpoints CRUD protegidos por permisos granulares.【F:backend/src/competition/controllers/leagues.controller.ts†L11-L34】【F:backend/src/competition/controllers/clubs.controller.ts†L11-L73】【F:backend/src/competition/controllers/tournaments.controller.ts†L11-L88】【F:backend/src/competition/controllers/zones.controller.ts†L11-L88】【F:backend/src/competition/controllers/players.controller.ts†L11-L96】
- El servicio de fixture genera rondas ida y vuelta aplicando el algoritmo del círculo, valida composición de zonas, crea partidos con sus categorías y bloquea el torneo para evitar duplicaciones.【F:backend/src/competition/services/fixture.service.ts†L17-L104】
- `MatchesService` administra la edición del partido (estado/fecha), el registro de resultados por categoría, adjuntos opcionales, auditoría y notificaciones al servicio de standings.【F:backend/src/competition/services/matches.service.ts†L19-L133】【F:backend/src/competition/services/matches.service.ts†L134-L199】
- `StandingsService` recalcula tablas zonales, agrega resultados por torneo/ligas y ordena por puntos, diferencia y goles, almacenando resultados materializados en `CategoryStanding`.【F:backend/src/standings/standings.service.ts†L1-L196】

### 2.5 Modelo de datos
- El esquema Prisma define entidades para organización (ligas, torneos, zonas, clubes), competitividad (partidos, resultados, fixtures), gestión de personas (jugadores, planteles) y seguridad (usuarios, roles, permisos, tokens, auditoría).【F:backend/prisma/schema.prisma†L1-L481】
- Las enum `Module`, `Action` y `Scope` modelan el RBAC, mientras que `MatchStatus`, `Round` y `TournamentChampionMode` estructuran la lógica de negocio deportiva.【F:backend/prisma/schema.prisma†L11-L167】

## 3. Frontend

### 3.1 Estructura y navegación
- `createRouter` configura rutas protegidas que redirigen al login si el usuario no está autenticado y agrupa vistas en un `ShellRoute` con navegación lateral persistente.【F:frontend/lib/core/router/app_router.dart†L19-L88】
- `AppShell` provee `NavigationRail` colapsable, persistencia del estado de la barra lateral y encabezado con menú de usuario, adaptándose automáticamente en pantallas estrechas.【F:frontend/lib/features/shared/widgets/app_shell.dart†L8-L92】

### 3.2 Estado y servicios
- `ApiClient` encapsula `dio`, aplica timeouts, añade el header `Authorization` y reintenta solicitudes tras refrescar tokens cuando recibe un 401.【F:frontend/lib/services/api_client.dart†L1-L56】
- `AuthController` guarda tokens en `SharedPreferences`, carga el perfil desde `/me`, gestiona refresh, logout, recuperación de contraseña y operaciones de cuenta (cambio de email, contraseña, avatar).【F:frontend/lib/services/auth_controller.dart†L11-L204】

### 3.3 Funcionalidades destacadas
- `LeaguesPage` lista ligas, muestra métricas en tarjetas y ofrece formularios adaptativos (modal/bottom sheet) para crear o editar registros según el ancho disponible.【F:frontend/lib/features/leagues/presentation/leagues_page.dart†L1-L164】
- `FixturesPage` permite lanzar la generación de fixture ingresando el ID del torneo y refleja mensajes de éxito/error desde la API.【F:frontend/lib/features/fixtures/presentation/fixtures_page.dart†L1-L78】
- `AccountSettingsPage` concentra pestañas de perfil, seguridad y avatar, reutilizando la lógica del `AuthController` para persistir cambios y mostrar feedback contextual.【F:frontend/lib/features/settings/account_settings_page.dart†L1-L140】

## 4. Infraestructura y operaciones

- El archivo `infra/docker-compose.yml` define servicios persistentes (PostgreSQL, MinIO), utilitarios (Mailhog) y aplica variables de entorno alineadas al módulo de configuración del backend, exponiendo los puertos estándares para desarrollo.【F:infra/docker-compose.yml†L1-L49】
- Los scripts de `backend/package.json` proveen tareas de build, linting, pruebas, migraciones y seed, facilitando la integración en pipelines CI/CD.【F:backend/package.json†L6-L20】

## 5. Flujo de interacción ejemplar

1. Un administrador accede a `/fixtures` en el frontend; la vista invoca `POST /tournaments/:id/fixture` mediante `ApiClient` con el JWT vigente.【F:frontend/lib/features/fixtures/presentation/fixtures_page.dart†L39-L60】【F:frontend/lib/services/api_client.dart†L1-L56】
2. El endpoint en `FixtureService` valida la composición del torneo, genera el round-robin y crea partidos/categorías en una transacción de Prisma.【F:backend/src/competition/services/fixture.service.ts†L17-L104】
3. Colaboradores registran resultados desde el backend (`MatchesService`), adjuntan actas y desencadenan `StandingsService.recalculateForMatch`, que vuelca tablas normalizadas para consumo público.【F:backend/src/competition/services/matches.service.ts†L67-L133】【F:backend/src/standings/standings.service.ts†L13-L125】
4. Las tablas actualizadas se consultan mediante los endpoints de standings y pueden mostrarse en futuras vistas públicas del frontend reutilizando el mismo cliente HTTP.

Esta arquitectura modular permite evolucionar cada capa (nuevas vistas Flutter, endpoints REST adicionales, almacenamiento S3 administrado, etc.) sin comprometer los contratos existentes.
