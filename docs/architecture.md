# Arquitectura y Plan de Implementación

## 1. Objetivo del MVP
Implementar una plataforma web para gestionar ligas, torneos, fixtures y resultados cumpliendo con todas las reglas de negocio descritas. El alcance del MVP incluye la gestión competitiva completa, autenticación básica con verificación de correo y captcha, generación y carga de fixtures, control de roles/permisos y visualización pública de datos competitivos. Se deja la infraestructura lista para futuras exportaciones, API móviles y autenticación avanzada.

### 1.1 Entregables MVP
- Frontend Flutter Web desplegable como aplicación SPA.
- Backend Node.js (TypeScript) con API REST versionada (`/api/v1`).
- Base de datos PostgreSQL con migraciones y seeds mínimas.
- Gestión RBAC configurable por UI y persistida en base de datos.
- Algoritmo de generación de fixture (método del círculo) con rondas ida/vuelta.
- Carga de resultados por partido/categoría con validaciones y adjunto opcional.
- Módulo de autenticación con registro, verificación de correo, captcha y política de contraseña.
- Infraestructura de entornos separados `dev`/`prod` preparada (archivos de configuración, scripts de despliegue y contenedores).

## 2. Arquitectura General

| Capa | Tecnología | Descripción |
| --- | --- | --- |
| UI | Flutter Web | SPA con rutas protegidas, layout responsivo y tema configurable por liga. |
| API | Node.js + NestJS/Express (TypeScript) | API REST modular, validaciones con Joi/Zod, control RBAC y manejo de sesiones JWT + refresh tokens. |
| Base de datos | PostgreSQL 15 | Modelo relacional normalizado, funciones para cálculos de tablas y vistas materializadas opcionales. |
| Storage | Servidor propio / bucket S3-compatible | Almacenamiento de imágenes de actas (≤ 10 MB) con URLs firmadas. |
| Autenticación | JWT + verificación por correo | Registro con captcha, email de verificación y recuperación de contraseña. |
| Observabilidad | Winston + PostgreSQL logging | Logs de auditoría y métricas básicas. |

### 2.1 Diagrama lógico
1. **Flutter Web** consume `api/v1` mediante HTTPS y gestiona estado con Riverpod/Bloc.
2. **API Gateway/Backend** (Node) ofrece módulos: autenticación, ligas/torneos, fixtures, resultados, configuración y reportes.
3. **Base de datos** expone vistas y funciones para cálculos de tablas y goleadores.
4. **Storage** almacena adjuntos; la API firma URLs para subida/descarga.

## 3. Backend Node.js

### 3.1 Stack recomendado
- Node.js 20 + TypeScript.
- Framework NestJS para modularización, inyección de dependencias y validaciones.
- ORM Prisma o TypeORM para mapeo con PostgreSQL.
- Zod/Joi para validaciones de DTOs.
- JWT para autenticación, refresh tokens guardados en tabla `user_tokens`.
- Nodemailer + servicio SMTP para verificación de correo y recuperación.
- hCaptcha/Turnstile integrado desde backend para validar el token recibido desde el frontend.

### 3.2 Módulos API
1. **Auth**: registro, login, refresh, verificación de email, recuperación de contraseña.
2. **Usuarios y Roles**: CRUD, asignación múltiple de roles y pertenencias a clubes/ligas/categorías.
3. **Ligas/Torneos/Zonas**: creación, edición, asignaciones y configuración de reglas de campeones.
4. **Clubs/Categorías/Planteles**: administración de planteles y fichas de jugadores.
5. **Fixture**: generación, consulta y bloqueo; incluye algoritmo round-robin con validaciones transaccionales.
6. **Partidos**: programación, estados, carga de resultados, cierre y auditoría.
7. **Tablas y estadísticas**: endpoints para tablas, goleadores y próximas fechas.
8. **Configuración**: colores de liga, parámetros globales, intervalos de auto-actualización.

Todos los endpoints se versionan bajo `/api/v1` y se documentan con OpenAPI (Swagger) para facilitar la futura app móvil.

### 3.3 Control de Permisos
- Tabla `permissions` con acciones (view/create/update/delete) por módulo y ámbito (global, liga, club, categoría).
- Tabla `role_permissions` configurable desde la UI.
- Middleware que carga permisos de usuario y evalúa scopes antes de ejecutar el handler.
- Resolución de visibilidad: unión del rol público + roles específicos, filtrando por pertenencias.

### 3.4 Generación de Fixture (Round-Robin)
1. Normalizar lista de clubes (sin duplicados, orden original, IDs válidos).
2. Agregar marcador `None` si la cantidad es impar.
3. Para cada fecha `i` en `0..total_slots-2`:
   - Emparejar extremos (`arrangement[j]` con `arrangement[-(j+1)]`).
   - Determinar localía: si fecha es impar (1-indexada) primer club local; si es par se invierte.
   - Registrar bye cuando uno sea `None`.
   - Rotar arreglo manteniendo fijo el primer elemento y moviendo el último a la segunda posición.
4. Duplicar el calendario para la segunda ronda invirtiendo localías.
5. Persistir en transacción: verificar ausencia de fixture previo y crear partidos para ambas rondas, agrupados por zona y categoría.
6. En caso de fallo durante la transacción se lanza `FixtureGenerationError` con sugerencia de correr migraciones.

### 3.5 Gestión de Resultados
- Endpoints protegidos para Colaborador/Administrador.
- Validación que la suma de goles y "Otros jugadores" coincida con el marcador.
- Adjuntos almacenados y referenciados en tabla `match_attachments`.
- Al cerrar un partido se generan eventos para recalcular tablas (trigger o job asíncrono).
- Solo Administrador puede reabrir partido.

### 3.6 Cálculo de Tablas
- Servicio que recalcula standings por categoría/torneo/liga tras cada cierre de partido.
- Fórmula 3-1-0 con desempate: puntos, diferencia de gol, goles a favor.
- Exponer vistas materializadas `tabla_categoria`, `tabla_torneo`, `tabla_liga` para consultas rápidas.

## 4. Frontend Flutter Web

### 4.1 Stack y convenciones
- Flutter 3.22+, proyecto web con `go_router` para rutas y `Riverpod`/`Bloc` para estado.
- Layout principal con `Scaffold` + `NavigationRail` colapsable.
- Themado: tema general fijo + color primario por liga (configurable desde backend).
- Internacionalización: solo español (usando `flutter_localizations`).

### 4.2 Módulos UI
1. **Autenticación**: login, registro con captcha, verificación de email.
2. **Home**: placeholder con logo y nombre.
3. **Gestión**: páginas CRUD para ligas, torneos, zonas, clubes, categorías, jugadores y fixture.
4. **Resultados**: formularios de carga por partido/categoría con columnas local/visitante.
5. **Visualización pública**: fixture, resultados, tablas, goleadores, próximas fechas.
6. **Configuración**: administración de roles/permisos y tema por liga.

### 4.3 Componentes clave
- `AppShell` con `NavigationRail` colapsable que recuerda estado (local storage) y autocollapse en pantallas chicas.
- `PermissionGuard` que oculta rutas/items sin permiso.
- `DataTable` reutilizable con filtros y paginación.
- Formularios basados en `ReactiveForms` o `FormBuilder` con validaciones síncronas y asíncronas.

### 4.4 Integración con Backend
- Cliente REST basado en `dio` con interceptores para tokens y refresh.
- Manejo de errores y estados offline.
- Polling/actualización automática cada 10 minutos para pantallas públicas.

## 5. Base de Datos PostgreSQL

### 5.1 Tablas principales
- `ligas`, `torneos`, `zonas`, `clubes`, `club_zona`, `categorias`, `planteles`, `jugadores`, `fichas`, `partidos`, `partido_categorias`, `goles`, `otros_goleadores`, `usuarios`, `roles`, `usuario_roles`, `permissions`, `role_permissions`, `user_tokens`, `logs_cambios`, `match_attachments`.

### 5.2 Relaciones clave
- `torneos` referencia `ligas` y define reglamentación (campeón global vs por rondas).
- `zonas` referencia `torneo`; `club_zona` asegura pertenencia única.
- `partidos` se agrupan por `zona` y tienen estados `Programado`, `Pendiente`, `Finalizado`.
- `partido_categorias` representa cada categoría disputada en un partido.
- `goles` relaciona jugadores y `partido_categorias`; `otros_goleadores` almacena goles no asociados a jugador.
- `logs_cambios` registra auditorías (usuario, acción, fecha).

### 5.3 Migraciones y seeds
- Herramienta ORM para generar migraciones versionadas.
- Seeds iniciales: roles base, permisos, usuario admin, ligas/torneos de ejemplo.

## 6. Infraestructura y DevOps

### 6.1 Entornos
- `dev`: docker-compose con servicios `web`, `api`, `db`, `storage` (MinIO) y `mailhog` para pruebas de correo.
- `prod`: contenedores en VPS o servicio cloud (Railway, Render, Fly.io). Certificados SSL gestionados con Traefik/Caddy/NGINX.

### 6.2 CI/CD
- GitHub Actions con flujos:
  - Lint + pruebas unitarias (frontend/backend).
  - Migraciones en Postgres temporal.
  - Despliegue automatizado a entornos (opcional).

### 6.3 Observabilidad y backup
- Logs centralizados en archivos rotados o servicio externo.
- Backups automáticos de PostgreSQL (pg_dump) diarios y almacenamiento externo.
- Monitoreo básico (uptime, métricas) con Grafana/Prometheus en fases posteriores.

## 7. Roadmap de Implementación

1. **Preparación del repositorio**: configurar monorepo con carpetas `frontend/`, `backend/`, `infra/`, `docs/`.
2. **Base de datos**: definir esquema inicial y migraciones.
3. **Backend**:
   - Configuración de proyecto NestJS.
   - Módulo Auth con registro, login, verificación y captcha.
   - Implementar RBAC y asignación de roles.
   - CRUDs de ligas, torneos, zonas, clubes, categorías y planteles.
   - Servicio de fixture round-robin con transacciones.
   - Endpoints de resultados y tablas.
4. **Frontend**:
   - Setup Flutter Web, layout base y navegación.
   - Autenticación y guardas de rutas.
   - Vistas de gestión y visualización pública.
   - Formularios de carga de resultados con validaciones.
5. **Integración y pruebas**:
   - Pruebas unitarias backend (servicios, fixture, RBAC).
   - Tests widget/e2e en Flutter para flujos críticos.
   - Test de integración API ↔ frontend.
6. **Infraestructura**: docker-compose, pipelines CI/CD, scripts de despliegue.
7. **Hardening**: logs de auditoría, manejo de errores, pruebas de carga básicas.

## 8. Extensibilidad futura
- **Exportaciones PDF/Excel**: módulos Node reutilizando servicios actuales.
- **Notificaciones push y API móvil**: aprovechar versionado actual y ampliar endpoints.
- **2FA**: añadir tabla `user_mfa` y flujo TOTP cuando se requiera.
- **Internacionalización**: habilitar soporte multi-idioma en Flutter y backend.

## 9. Riesgos y mitigaciones
- **Complejidad del fixture**: cubrir con pruebas unitarias y escenarios de N impar/par.
- **Gestión de permisos granular**: diseñar UI clara con matrices de permisos y scopes.
- **Integridad de resultados**: usar constraints y triggers para validar sumatorias de goles.
- **Escalabilidad de almacenamiento**: permitir migrar de storage local a S3-compatible.
- **Verificación de correo**: considerar colas (BullMQ) si se requiere resiliencia.

## 10. Próximos pasos inmediatos
1. Crear estructura de monorepo y plantillas de configuración.
2. Definir esquema inicial en Prisma/TypeORM e implementar migración base.
3. Generar prototipo de autenticación y layout de Flutter para validar UX.
4. Preparar docker-compose para entorno de desarrollo.
5. Establecer políticas de codificación y convenciones en documentación adicional.

