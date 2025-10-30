# Arquitectura y componentes

Este documento describe la arquitectura actual del proyecto **Ligas Deportivas**, los módulos principales de cada capa y los flujos que conectan backend, frontend e infraestructura.

## 1. Visión general del sistema

- **Backend**: API REST construida con NestJS, organizada en módulos funcionales (autenticación, usuarios, RBAC, dominio competitivo, métricas) y respaldada por Prisma sobre PostgreSQL. ([backend/src/app.module.ts](backend/src/app.module.ts)) ([backend/prisma/schema.prisma](backend/prisma/schema.prisma))
- **Frontend**: SPA desarrollada en Flutter Web con Riverpod para estado y `go_router` para navegación, que consume la API y respeta permisos del usuario autenticado. ([frontend/lib/core/router/app_router.dart](frontend/lib/core/router/app_router.dart)) ([frontend/lib/services/auth_controller.dart](frontend/lib/services/auth_controller.dart))
- **Infraestructura**: Docker Compose levanta PostgreSQL, MinIO, Mailhog y contenedores para backend y frontend, reproduciendo un entorno integrado de desarrollo/demo. ([infra/docker-compose.yml](infra/docker-compose.yml))

## 2. Backend

### 2.1 Configuración transversal
- `ConfigModule` centraliza variables de entorno (base de datos, JWT, SMTP, almacenamiento) cargadas al inicio de la aplicación. ([backend/src/app.module.ts](backend/src/app.module.ts)) ([backend/.env](backend/.env))
- `main.ts` define prefijo global `api/v1`, CORS hacia el frontend, tuberías de validación y exposición de archivos estáticos desde `storage/uploads`. ([backend/src/main.ts](backend/src/main.ts))

### 2.2 Autenticación y cuenta
- `AuthController` ofrece registro, login local, refresco y revocación de tokens, verificación de correo y recuperación de contraseña. La lógica complementa con envío de mails y validación de captcha configurables. ([backend/src/auth/auth.controller.ts](backend/src/auth/auth.controller.ts)) ([backend/src/mail/mail.service.ts](backend/src/mail/mail.service.ts)) ([backend/src/captcha/captcha.service.ts](backend/src/captcha/captcha.service.ts))
- El módulo `me` expone endpoints para obtener/editar el perfil, solicitar y confirmar cambio de correo, actualizar contraseña y subir un avatar. Los archivos se persisten en disco con `StorageService`, que genera rutas públicas compatibles con despliegues detrás de CDN o reverse proxies. ([backend/src/me/me.controller.ts](backend/src/me/me.controller.ts)) ([backend/src/storage/storage.service.ts](backend/src/storage/storage.service.ts))

### 2.3 Control de acceso
- El guard `PermissionsGuard` evalúa los permisos declarativos en cada handler combinando módulo, acción y alcance antes de ejecutar el controlador. ([backend/src/rbac/permissions.guard.ts](backend/src/rbac/permissions.guard.ts))
- `RolesController` y `UsersController` permiten listar roles, catálogos de permisos y asignar roles/alcances a usuarios autenticados con privilegios adecuados. ([backend/src/rbac/roles.controller.ts](backend/src/rbac/roles.controller.ts)) ([backend/src/users/users.controller.ts](backend/src/users/users.controller.ts))
- El seed inicial crea permisos, roles base (Administrador, Colaborador, Delegado, DT, Usuario) y asigna la matriz inicial de scopes, además de asegurar un usuario administrador configurable por variables de entorno. ([backend/src/prisma/base-seed.ts](backend/src/prisma/base-seed.ts))

### 2.4 Dominio competitivo
- El módulo `competition` agrupa controladores y servicios especializados para ligas, clubes, torneos, zonas, categorías, planteles, jugadores y equipos. Cada entidad expone endpoints CRUD protegidos por permisos granulares. ([backend/src/competition/controllers/leagues.controller.ts](backend/src/competition/controllers/leagues.controller.ts)) ([backend/src/competition/controllers/clubs.controller.ts](backend/src/competition/controllers/clubs.controller.ts)) ([backend/src/competition/controllers/tournaments.controller.ts](backend/src/competition/controllers/tournaments.controller.ts)) ([backend/src/competition/controllers/zones.controller.ts](backend/src/competition/controllers/zones.controller.ts)) ([backend/src/competition/controllers/players.controller.ts](backend/src/competition/controllers/players.controller.ts))
- El servicio de fixture genera rondas ida y vuelta aplicando el algoritmo del círculo, valida composición de zonas, crea partidos con sus categorías y bloquea el torneo para evitar duplicaciones. ([backend/src/competition/services/fixture.service.ts](backend/src/competition/services/fixture.service.ts))
- `MatchesService` administra la edición del partido (estado/fecha), el registro de resultados por categoría, adjuntos opcionales, auditoría y notificaciones al servicio de standings. ([backend/src/competition/services/matches.service.ts](backend/src/competition/services/matches.service.ts))
- `StandingsService` recalcula tablas zonales, agrega resultados por torneo/ligas y ordena por puntos, diferencia y goles, almacenando resultados materializados en `CategoryStanding`. ([backend/src/standings/standings.service.ts](backend/src/standings/standings.service.ts))

### 2.5 Modelo de datos
- El esquema Prisma define entidades para organización (ligas, torneos, zonas, clubes), competitividad (partidos, resultados, fixtures), gestión de personas (jugadores, planteles) y seguridad (usuarios, roles, permisos, tokens, auditoría). ([backend/prisma/schema.prisma](backend/prisma/schema.prisma))
- Las enum `Module`, `Action` y `Scope` modelan el RBAC, mientras que `MatchStatus`, `Round` y `TournamentChampionMode` estructuran la lógica de negocio deportiva. ([backend/prisma/schema.prisma](backend/prisma/schema.prisma))

## 3. Frontend

### 3.1 Estructura y navegación
- `createRouter` configura rutas protegidas que redirigen al login si el usuario no está autenticado y agrupa vistas en un `ShellRoute` con navegación lateral persistente. ([frontend/lib/core/router/app_router.dart](frontend/lib/core/router/app_router.dart))
- `AppShell` provee `NavigationRail` colapsable, persistencia del estado de la barra lateral y encabezado con menú de usuario, adaptándose automáticamente en pantallas estrechas. ([frontend/lib/features/shared/widgets/app_shell.dart](frontend/lib/features/shared/widgets/app_shell.dart))

### 3.2 Estado y servicios
- `ApiClient` encapsula `dio`, aplica timeouts, añade el header `Authorization` y reintenta solicitudes tras refrescar tokens cuando recibe un 401. ([frontend/lib/services/api_client.dart](frontend/lib/services/api_client.dart))
- `AuthController` guarda tokens en `SharedPreferences`, carga el perfil desde `/me`, gestiona refresh, logout, recuperación de contraseña y operaciones de cuenta (cambio de email, contraseña, avatar). ([frontend/lib/services/auth_controller.dart](frontend/lib/services/auth_controller.dart))

### 3.3 Funcionalidades destacadas
- `LeaguesPage` lista ligas, muestra métricas en tarjetas y ofrece formularios adaptativos (modal/bottom sheet) para crear o editar registros según el ancho disponible. ([frontend/lib/features/leagues/presentation/leagues_page.dart](frontend/lib/features/leagues/presentation/leagues_page.dart))
- `FixturesPage` permite lanzar la generación de fixture ingresando el ID del torneo y refleja mensajes de éxito/error desde la API. ([frontend/lib/features/fixtures/presentation/fixtures_page.dart](frontend/lib/features/fixtures/presentation/fixtures_page.dart))
- `AccountSettingsPage` concentra pestañas de perfil, seguridad y avatar, reutilizando la lógica del `AuthController` para persistir cambios y mostrar feedback contextual. ([frontend/lib/features/settings/account_settings_page.dart](frontend/lib/features/settings/account_settings_page.dart))

## 4. Infraestructura y operaciones

- El archivo `infra/docker-compose.yml` define servicios persistentes (PostgreSQL, MinIO), utilitarios (Mailhog) y aplica variables de entorno alineadas al módulo de configuración del backend, exponiendo los puertos estándares para desarrollo. ([infra/docker-compose.yml](infra/docker-compose.yml))
- Los scripts de `backend/package.json` proveen tareas de build, linting, pruebas, migraciones y seed, facilitando la integración en pipelines CI/CD. ([backend/package.json](backend/package.json))

## 5. Flujo de interacción ejemplar

1. Un administrador accede a `/fixtures` en el frontend; la vista invoca `POST /tournaments/:id/fixture` mediante `ApiClient` con el JWT vigente. ([frontend/lib/features/fixtures/presentation/fixtures_page.dart](frontend/lib/features/fixtures/presentation/fixtures_page.dart)) ([frontend/lib/services/api_client.dart](frontend/lib/services/api_client.dart))
2. El endpoint en `FixtureService` valida la composición del torneo, genera el round-robin y crea partidos/categorías en una transacción de Prisma. ([backend/src/competition/services/fixture.service.ts](backend/src/competition/services/fixture.service.ts))
3. Colaboradores registran resultados desde el backend (`MatchesService`), adjuntan actas y desencadenan `StandingsService.recalculateForMatch`, que vuelca tablas normalizadas para consumo público. ([backend/src/competition/services/matches.service.ts](backend/src/competition/services/matches.service.ts)) ([backend/src/standings/standings.service.ts](backend/src/standings/standings.service.ts))
4. Las tablas actualizadas se consultan mediante los endpoints de standings y pueden mostrarse en futuras vistas públicas del frontend reutilizando el mismo cliente HTTP.

Esta arquitectura modular permite evolucionar cada capa (nuevas vistas Flutter, endpoints REST adicionales, almacenamiento S3 administrado, etc.) sin comprometer los contratos existentes.
