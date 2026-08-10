# Seguimiento de migración del frontend

Este documento registra la migración del cliente Flutter Web a SvelteKit + TypeScript.
El backend NestJS, la API REST y el esquema Prisma se conservan durante la transición.

## Estados

- `Pendiente`: todavía no iniciado.
- `En progreso`: implementación activa.
- `Migrado`: implementado en SvelteKit.
- `Validado`: migrado y probado contra la API real.

## Inventario

| Área | Pantalla o función | Ruta | Endpoint o dependencia | Estado | Observaciones |
|---|---|---|---|---|---|
| Base | Shell, navegación y layout responsive | `/` | SvelteKit | En progreso | Base creada junto con el login |
| Auth | Inicio de sesión | `/login` | `POST /auth/login` | Migrado | Valida formulario y conserva tokens |
| Auth | Refresh automático | Global | `POST /auth/refresh` | Migrado | Se ejecuta ante respuestas 401 |
| Auth | Perfil de sesión | Global | `GET /auth/profile` | Migrado | Protege la pantalla inicial |
| Auth | Cierre de sesión | Global | `POST /auth/logout` | Migrado | Limpia la sesión local |
| Auth | Registro | `/register` | `POST /auth/register` | Pendiente | |
| Auth | Verificación de correo | `/verify-email` | `POST /auth/verify-email` | Pendiente | |
| Auth | Recuperación de contraseña | `/reset-password` | `POST /auth/password/*` | Pendiente | |
| Inicio | Resumen del panel | `/home` | `GET /competition/home-summary` | Pendiente | |
| Ligas | Listado y edición de ligas | `/leagues` | `/leagues` | Pendiente | |
| Clubes | Listado y administración de clubes | `/clubs` | `/clubs` | Pendiente | |
| Clubes | Administración pública/privada de club | `/club/:slug` | `/clubs/*` | Pendiente | |
| Clubes | Plantel de club | `/clubs/:clubId/roster` | `/rosters/*`, `/players/*` | Pendiente | |
| Categorías | Catálogo y edición | `/categories` | `/categories` | Pendiente | |
| Jugadores | Alta, edición, búsqueda y baja | `/players` | `/players` | Pendiente | Incluye escaneo DNI PDF417 |
| Torneos | Listado y configuración | `/tournaments` | `/tournaments` | Pendiente | |
| Torneos | Jugadores del torneo | `/tournaments/:id/players` | `/players/*` | Pendiente | |
| Torneos | Plantillas de posters | `/tournaments/:id/poster-template` | `/poster-templates/*` | Pendiente | |
| Zonas | Gestión de zonas | `/zones` | `/zones` | Pendiente | |
| Fixture | Generación automática | `/fixtures` | `POST /tournaments/:id/fixture` | Pendiente | |
| Fixture | Fixture por zona | `/zones/:id/fixture` | `/zones/:id/fixture` | Pendiente | |
| Fixture | Constructor manual | `/zones/:id/fixture/manual` | `/zones/:id/fixture/manual` | Pendiente | |
| Partidos | Detalle y resultado | `/zones/:zoneId/fixture/matches/:matchId` | `/matches/*` | Pendiente | Incluye goles y adjuntos |
| Partidos | Resumen de fecha | `/zones/:zoneId/fixture/matchdays/:matchday/summary` | `/matchdays/*` | Pendiente | |
| Tablas | Tabla general | `/standings` | `/standings` | Pendiente | |
| Tablas | Tabla por zona | `/zones/:id/standings` | `/standings/*` | Pendiente | |
| Estadísticas | Rankings y estadísticas | `/stats` | `/leaderboards` | Pendiente | |
| Configuración | Menú de configuración | `/settings` | RBAC | Pendiente | |
| Configuración | Identidad del sitio | `/settings/identity` | `/site-identity` | Pendiente | Logo, favicon, flyer y fondo |
| Configuración | Cuenta y avatar | `/settings/account` | `/me` | Pendiente | |
| Configuración | Usuarios | `/settings/users` | `/users` | Pendiente | |
| Configuración | Colores de ligas | `/settings/colors` | `/leagues` | Pendiente | |
| Configuración | Roles y permisos | `/settings/permissions` | `/roles`, `/permissions` | Pendiente | |

## Criterio de validación

Una pantalla pasa a `Validado` cuando:

1. Funciona en móvil y escritorio.
2. Consume la API real, no datos simulados.
3. Respeta autenticación, permisos y estados de error.
4. Tiene una prueba manual documentada o una prueba automatizada apropiada.
5. Se actualizó este inventario y se comprobó el flujo principal.

## Registro de cambios

| Fecha | Cambio |
|---|---|
| 2026-08-10 | Creado frontend SvelteKit, login, refresh, perfil, logout y pantalla protegida inicial. |
