# Seguimiento de migración del frontend

Este documento registra la migración del cliente Flutter Web a SvelteKit + TypeScript.
El backend NestJS, la API REST y el esquema Prisma se conservan durante la transición.

## Estados

- `Pendiente`: todavía no iniciado.
- `En progreso`: implementación activa.
- `Migrado`: implementado en SvelteKit.
- `Validado`: migrado y probado contra la API real.

## Inventario

| Área | Pantalla o función | Ruta | Estado |
|---|---|---|---|
| Auth | Login, refresh, perfil, logout | `/login` | Migrado |
| Auth | Registro | `/register` | Pendiente |
| Auth | Verificación de correo | `/verify-email` | Pendiente |
| Auth | Recuperación de contraseña | `/reset-password` | Pendiente |
| Inicio | Panel con torneos activos | `/` | Migrado |
| Ligas | CRUD de ligas | `/leagues` | Migrado |
| Clubes | Listado, búsqueda y CRUD | `/clubs` | Migrado |
| Clubes | Administración por slug | `/club/:slug` | Pendiente |
| Clubes | Plantel del club | `/clubs/:clubId/roster` | Pendiente |
| Categorías | CRUD de categorías | `/categories` | Migrado |
| Jugadores | CRUD + escaneo DNI | `/players` | Pendiente |
| Torneos | CRUD de torneos | `/tournaments` | Migrado |
| Torneos | Jugadores del torneo | `/tournaments/:id/players` | Pendiente |
| Torneos | Plantillas de posters | `/tournaments/:id/poster-template` | Pendiente |
| Zonas | Listado y enlaces | `/zones` | Migrado |
| Fixture | Generación automática | `/fixtures` | Pendiente |
| Fixture | Fixture por zona | `/zones/:id/fixture` | Pendiente |
| Fixture | Constructor manual | `/zones/:id/fixture/manual` | Pendiente |
| Partidos | Detalle, resultado y goles | Partidos | Pendiente |
| Partidos | Resumen de fecha | Matchdays | Pendiente |
| Tablas | General y por zona | `/standings` | Migrado |
| Estadísticas | Rankings | `/stats` | Pendiente |
| Configuración | Cuenta y cambio de contraseña | `/settings/account` | Migrado |
| Configuración | Identidad del sitio | `/settings/site-identity` | Migrado |
| Configuración | Gestión de usuarios | `/settings/users` | Pendiente |
| Configuración | Colores de ligas | `/settings/colors` | Pendiente |
| Configuración | Roles y permisos | `/settings/permissions` | Pendiente |

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
| 2026-08-10 | Creado frontend SvelteKit, login, refresh, perfil, logout, panel inicial, navbar. |
| 2026-08-10 | Migrados ligas, clubes, categorías, torneos, zonas, tablas, cuenta e identidad del sitio. |
| 2026-08-10 | Formularios de creación/edición convertidos a modales. |
| 2026-08-10 | Sidebar colapsable con navegación completa y drawer mobile. |
