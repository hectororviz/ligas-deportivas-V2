# API de Ligas Deportivas V2 (para consumo desde APK)

Este documento describe el funcionamiento **actual** de la API (backend NestJS) para integrar una APK que consuma los datos de la plataforma.

## 1. Base URL, prefijo y formato

- **Prefijo global:** todas las rutas están bajo `/api/v1`.
  - Ejemplo: `https://<dominio>/api/v1/leagues`.
- **Formato principal:** JSON (`Content-Type: application/json`).
- **Archivos/estáticos:**
  - Subidas generales se sirven en:
    - `/storage/uploads/<archivo>`
    - `/api/v1/storage/uploads/<archivo>`
  - Avatares se sirven por endpoint dedicado (ver sección **Usuarios y perfil**).

## 2. Autenticación y autorización

### 2.1. Token de acceso (JWT)
- **Cabecera:** `Authorization: Bearer <accessToken>`.
- **Se exige JWT** en endpoints con `@UseGuards(JwtAuthGuard)`.

### 2.2. Refresh token
- **Formato:** `<id>.<token>` (el id corresponde al registro en base de datos).
- **Uso:** se envía a `/auth/refresh` para renovar el acceso.

### 2.3. Permisos (RBAC)
- Muchos endpoints requieren además permisos específicos por módulo/acción (ej. `Module.CLUBES`, `Action.UPDATE`).
- La validación se ejecuta con `PermissionsGuard`.

## 3. Respuestas y errores

- **Errores de validación y dominio** devuelven `4xx` con mensaje en español.
- **Errores de autenticación** (`401`) para token inválido/expirado.
- **Respuestas paginadas** (por ejemplo clubes, jugadores):
  ```json
  {
    "data": ["..."],
    "total": 123,
    "page": 1,
    "pageSize": 25
  }
  ```

## 4. Endpoints por módulo

> Todas las rutas están bajo `/api/v1`.

### 4.1. Autenticación (`/auth`)

| Método | Ruta | Auth | Descripción | Body/Notas |
| --- | --- | --- | --- | --- |
| POST | `/auth/register` | Público | Registro de usuario | `{ email, password, firstName, lastName, captchaToken }` (password mínimo 8, debe incluir mayús/minús/números). |
| POST | `/auth/login` | Público | Login | `{ email, password }` devuelve `{ user, accessToken, refreshToken }`. |
| POST | `/auth/refresh` | Público | Renovar tokens | `{ refreshToken }` devuelve `{ user, accessToken, refreshToken }`. |
| POST | `/auth/logout` | Público | Invalidar refresh token | `{ refreshToken }`. |
| POST | `/auth/verify-email` | Público | Verificar email | `{ token }` (token enviado por email). |
| POST | `/auth/password/request-reset` | Público | Solicitar reset de contraseña | `{ email }` (si no existe el usuario, responde success igualmente). |
| POST | `/auth/password/reset` | Público | Resetear contraseña | `{ token, password }`. |
| GET | `/auth/profile` | JWT | Perfil actual | Devuelve el `RequestUser` del token. |

### 4.2. Perfil del usuario (`/me`)

Requiere JWT en todas las rutas.

| Método | Ruta | Descripción | Body/Notas |
| --- | --- | --- | --- |
| GET | `/me` | Perfil completo | Devuelve perfil con roles/permisos y club asociado. |
| PUT | `/me` | Actualizar perfil | `UpdateProfileDto`. |
| POST | `/me/email/request-change` | Solicitar cambio de email | `RequestEmailChangeDto`. |
| POST | `/me/email/confirm` | Confirmar cambio de email | `ConfirmEmailChangeDto`. |
| POST | `/me/password` | Cambiar contraseña | `ChangePasswordDto`. |
| POST | `/me/avatar` | Subir avatar | `multipart/form-data` con campo `avatar`. |

### 4.3. Usuarios y roles

#### Usuarios (`/users`)
Requiere JWT + permisos de usuarios/roles.

| Método | Ruta | Descripción | Query/Body |
| --- | --- | --- | --- |
| GET | `/users` | Listar usuarios | Query: `page`, `pageSize`, `search`. |
| PATCH | `/users/:id` | Actualizar usuario | `UpdateUserDto`. |
| POST | `/users/:id/password-reset` | Enviar reset de contraseña | Sin body. |
| POST | `/users/:id/roles` | Asignar rol | `AssignRoleDto`. |
| DELETE | `/users/roles/:assignmentId` | Quitar rol | Sin body. |

#### Roles (`/roles`)
Requiere JWT + permisos de roles/permisos.

| Método | Ruta | Descripción | Body |
| --- | --- | --- | --- |
| GET | `/roles` | Listar roles | - |
| GET | `/roles/permissions` | Listar permisos | - |
| PATCH | `/roles/:roleId/permissions` | Actualizar permisos de rol | `SetRolePermissionsDto` (array `permissionIds`). |

### 4.4. Identidad del sitio (`/site-identity`)

| Método | Ruta | Auth | Descripción | Body/Notas |
| --- | --- | --- | --- | --- |
| GET | `/site-identity` | Público | Datos de identidad (nombre, etc.). | - |
| GET | `/site-identity/icon` | Público | Obtener ícono | Devuelve archivo con cache 5 min. |
| GET | `/site-identity/flyer` | Público | Obtener flyer | Devuelve archivo con cache 5 min. |
| PUT | `/site-identity` | JWT + permisos | Actualizar identidad | `multipart/form-data` con campos `icon`, `flyer` y `UpdateSiteIdentityDto`. |

### 4.5. Competencias (flyer templates)

| Método | Ruta | Auth | Descripción | Body/Notas |
| --- | --- | --- | --- | --- |
| GET | `/competitions/:competitionId/flyer-template` | JWT + permisos | Obtener template del flyer | - |
| PUT | `/competitions/:competitionId/flyer-template` | JWT + permisos | Upsert template | `multipart/form-data` con `background` y `layout`. |
| DELETE | `/competitions/:competitionId/flyer-template` | JWT + permisos | Eliminar template | - |
| GET | `/competitions/:competitionId/flyer-template/preview` | JWT + permisos | Preview del template | Devuelve imagen binaria. |

### 4.6. Ligas (`/leagues`)

| Método | Ruta | Auth | Descripción |
| --- | --- | --- | --- |
| GET | `/leagues` | Público | Listado de ligas. |
| GET | `/leagues/:id` | Público | Detalle de liga. |
| POST | `/leagues` | JWT + permisos | Crear liga. |
| PATCH | `/leagues/:id` | JWT + permisos | Actualizar liga. |

### 4.7. Torneos y zonas

#### Torneos (`/tournaments`)

| Método | Ruta | Auth | Descripción | Query/Notas |
| --- | --- | --- | --- | --- |
| GET | `/tournaments` | Público | Listar todos los torneos. | - |
| GET | `/tournaments/active` | Público | Listar solo torneos activos. | Atajo equivalente a `/tournaments` sin `includeInactive`. |
| GET | `/leagues/:leagueId/tournaments` | Público | Torneos por liga. | - |
| GET | `/tournaments/:id` | Público | Detalle del torneo. | - |
| GET | `/tournaments/:id/zones/clubs` | Público | Clubes para asignación de zonas | Query opcional `zoneId` para filtrar. |
| POST | `/tournaments` | JWT + permisos | Crear torneo. | `CreateTournamentDto`. |
| PUT | `/tournaments/:id` | JWT + permisos | Actualizar torneo. | `UpdateTournamentDto`. |
| POST | `/tournaments/:id/zones` | JWT + permisos | Crear zona en torneo. | `CreateZoneDto`. |
| POST | `/tournaments/:id/categories` | JWT + permisos | Agregar categoría al torneo. | `AddTournamentCategoryDto`. |


**Ejemplo de respuesta (`GET /tournaments/active`)**

```json
[
  {
    "id": 3,
    "leagueId": 1,
    "name": "Apertura",
    "year": 2026,
    "gender": "MIXTO",
    "status": "ACTIVE",
    "pointsWin": 3,
    "pointsDraw": 1,
    "pointsLoss": 0,
    "championMode": "GLOBAL",
    "startDate": "2026-03-10T00:00:00.000Z",
    "endDate": null,
    "createdAt": "2026-03-01T12:00:00.000Z",
    "updatedAt": "2026-03-12T09:30:00.000Z",
    "league": {
      "id": 1,
      "name": "Liga Regional",
      "slug": "liga-regional",
      "colorHex": "#0057b8",
      "gameDay": "DOMINGO",
      "createdAt": "2026-02-20T10:00:00.000Z",
      "updatedAt": "2026-03-12T09:00:00.000Z"
    }
  }
]
```

#### Zonas (`/zones`)

| Método | Ruta | Auth | Descripción | Body/Notas |
| --- | --- | --- | --- | --- |
| GET | `/zones` | Público | Listar zonas. | - |
| GET | `/zones/:id` | Público | Detalle de zona. | - |
| POST | `/zones/:zoneId/clubs` | JWT + permisos | Asignar club a zona. | `AssignClubZoneDto` (clubId). |
| DELETE | `/zones/:zoneId/clubs/:clubId` | JWT + permisos | Quitar club de zona. | - |
| POST | `/zones/:zoneId/finalize` | JWT + permisos | Finalizar zona. | - |
| POST | `/zones/:zoneId/fixture/preview` | JWT + permisos | Vista previa del fixture. | `ZoneFixtureOptionsDto`. |
| POST | `/zones/:zoneId/fixture` | JWT + permisos | Generar fixture. | `ZoneFixtureOptionsDto`. |

#### Fixture automático de torneo

| Método | Ruta | Auth | Descripción | Body |
| --- | --- | --- | --- | --- |
| POST | `/tournaments/:id/fixtures/generate` | JWT + permisos | Generar fixture del torneo. | `GenerateFixtureDto`. |

### 4.8. Clubes (`/clubs`)

| Método | Ruta | Auth | Descripción | Query/Body |
| --- | --- | --- | --- | --- |
| GET | `/clubs` | Público | Listado paginado. | Query: `search`, `status` (`active|inactive`), `page`, `pageSize` (25/50). |
| GET | `/clubs/:id` | Público | Detalle de club. | - |
| GET | `/clubs/:slug/admin` | Público | Vista admin por slug (equipos, zonas). | - |
| GET | `/clubs/:clubId/tournament-categories/:tournamentCategoryId/eligible-players` | Público | Jugadores elegibles en roster. | Query: `page`, `pageSize`, `onlyEnabled`. |
| PUT | `/clubs/:clubId/tournament-categories/:tournamentCategoryId/eligible-players` | JWT + permisos | Actualizar roster elegible. | `UpdateRosterPlayersDto`. |
| GET | `/clubs/:clubId/available-tournaments` | Público | Torneos disponibles para un club. | - |
| POST | `/clubs/:clubId/available-tournaments` | JWT + permisos | Inscribir club en torneo. | `JoinTournamentDto`. |
| DELETE | `/clubs/:clubId/tournaments/:tournamentId` | JWT + permisos | Quitar club del torneo. | - |
| POST | `/clubs` | JWT + permisos | Crear club. | `CreateClubDto`. |
| PATCH | `/clubs/:id` | JWT + permisos | Actualizar club. | `UpdateClubDto`. |
| PUT | `/clubs/:id/teams` | JWT + permisos | Actualizar equipos. | `UpdateClubTeamsDto`. |
| PUT | `/clubs/:id/logo` | JWT + permisos | Subir logo | `multipart/form-data` con `logo`. |
| DELETE | `/clubs/:id/logo` | JWT + permisos | Eliminar logo. | - |

### 4.9. Equipos (`/teams`)

| Método | Ruta | Auth | Descripción |
| --- | --- | --- | --- |
| POST | `/teams` | JWT + permisos | Crear equipo. (`CreateTeamDto`). |

### 4.10. Jugadores (`/players`)

| Método | Ruta | Auth | Descripción | Query/Body |
| --- | --- | --- | --- | --- |
| GET | `/players` | Opcional | Listado paginado. | Query: `search`, `dni`, `status` (`all|active|inactive`), `gender`, `page`, `pageSize` (10/25/50/100), `clubId`, `birthYear`, `birthYearMin`, `birthYearMax`. |
| GET | `/players/:id` | Público | Detalle de jugador. | - |
| POST | `/players` | JWT + permisos | Crear jugador. | `CreatePlayerDto`. |
| PATCH | `/players/:id` | JWT + permisos | Actualizar jugador. | `UpdatePlayerDto`. |

> Nota: si se envía `Authorization` en `/players`, se aplican restricciones por permisos/club del usuario.

### 4.11. Partidos y resultados

| Método | Ruta | Auth | Descripción | Body/Notas |
| --- | --- | --- | --- | --- |
| GET | `/zones/:zoneId/matches` | Público | Partidos de una zona. | - |
| POST | `/zones/:zoneId/matchdays/:matchday/finalize` | JWT + permisos | Finalizar jornada. | - |
| GET | `/zones/:zoneId/matchdays/:matchday/summary` | Público | Resumen de jornada. | - |
| PATCH | `/zones/:zoneId/matchdays/:matchday` | JWT + permisos | Actualizar fecha de jornada. | `UpdateMatchdayDto`. |
| GET | `/matches/:matchId/categories/:categoryId/result` | Público | Resultado de un partido por categoría. | - |
| POST | `/matches/:matchId/categories/:categoryId/result` | JWT + permisos | Registrar resultado. | `RecordMatchResultDto` + `multipart/form-data` con `attachment` opcional. |
| PATCH | `/matches/:matchId` | JWT + permisos | Actualizar partido. | `UpdateMatchDto`. |
| GET | `/matches/flyer/tokens` | Público | Tokens disponibles para flyers. | - |
| GET | `/matches/:matchId/flyer` | Público | Descargar flyer del partido. | Respuesta binaria con `Content-Disposition`. |

### 4.12. Posiciones / standings

| Método | Ruta | Auth | Descripción |
| --- | --- | --- | --- |
| GET | `/zones/:zoneId/standings` | Público | Resumen de tabla de zona. |
| GET | `/zones/:zoneId/categories/:categoryId/standings` | Público | Tabla por categoría. |
| GET | `/tournaments/:tournamentId/standings` | Público | Tabla del torneo. |
| GET | `/leagues/:leagueId/standings` | Público | Tabla de liga. |

### 4.13. Avatares estáticos

| Método | Ruta | Auth | Descripción |
| --- | --- | --- | --- |
| GET | `/storage/avatars/:userId/:file` | Público | Descarga de avatar por usuario. |

## 5. Recomendaciones para la APK

- **Cache local**: aprovechar endpoints públicos (ligas, torneos, zonas, standings) con cache local y refrescos periódicos.
- **Tokens**: guardar `refreshToken` de manera segura; si falla un request con 401, refrescar token y reintentar.
- **Archivos**: para uploads, usar `multipart/form-data` y respetar los nombres de campo indicados.
- **Errores**: mostrar mensajes de error en español, ya que el backend los devuelve en ese idioma.
- **CORS**: no aplica para APK, pero sí para web; si se monta un WebView, validar el dominio permitido.

## 6. Módulos internos relevantes (para referencia técnica)

- Prefijo global y CORS: `backend/src/main.ts`.
- JWT y estrategia bearer: `backend/src/auth/strategies/jwt.strategy.ts`.
- Guardas de permisos: `backend/src/rbac/permissions.guard.ts`.
- Controladores de rutas: `backend/src/**/controllers/*.ts`.
