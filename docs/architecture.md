# Arquitectura y componentes

Este documento describe la arquitectura del proyecto **Ligas Deportivas**, los módulos principales de cada capa y los flujos que conectan backend, frontend e infraestructura.

## 1. Visión general del sistema

- **Backend**: API REST construida con NestJS, organizada en módulos funcionales (autenticación, usuarios, RBAC, dominio competitivo, métricas) y respaldada por Prisma sobre PostgreSQL.
- **Frontend**: SPA desarrollada en SvelteKit + TypeScript con `@sveltejs/adapter-node`, estado reactivo con runes de Svelte 5, cliente HTTP con fetch nativo y refresh automático de tokens. Sidebar colapsable en desktop, drawer deslizante en mobile.
- **Infraestructura**: Docker Compose con PostgreSQL, Mailhog y contenedores para backend y frontend. Las imágenes se construyen y publican automáticamente en GitHub Container Registry mediante GitHub Actions. El proxy inverso es `caddy-docker-proxy` compartido con otros servicios del VPS.

## 2. Backend

### 2.1 Configuración transversal
- `ConfigModule` centraliza variables de entorno (base de datos, JWT, SMTP, almacenamiento).
- `main.ts` define prefijo global `api/v1`, CORS hacia el frontend, tuberías de validación y exposición de archivos estáticos desde `storage/uploads`.

### 2.2 Autenticación y cuenta
- `AuthController` ofrece registro, login local, refresco y revocación de tokens, verificación de correo y recuperación de contraseña.
- El módulo `me` expone endpoints para obtener/editar el perfil, cambiar correo/contraseña y subir un avatar.

### 2.3 Control de acceso
- `PermissionsGuard` evalúa permisos declarativos (módulo, acción, alcance) antes de ejecutar cada controlador.
- `RolesController` y `UsersController` gestionan roles y permisos.
- El seed inicial crea permisos, roles base (Administrador, Colaborador, Delegado, DT, Usuario) y un usuario administrador.

### 2.4 Dominio competitivo
- El módulo `competition` expone endpoints CRUD para ligas, clubes, torneos, zonas, categorías, planteles, jugadores y equipos.
- `FixtureService` genera rondas ida y vuelta con el algoritmo del círculo, y soporta fixture manual por zona.
- `MatchesService` administra partidos, resultados, goles y adjuntos.
- `StandingsService` recalcula tablas zonales, por torneo y por liga.

### 2.5 Modelo de datos
- El esquema Prisma define entidades para organización (ligas, torneos, zonas, clubes), competitividad (partidos, resultados), personas (jugadores, planteles) y seguridad (usuarios, roles, permisos, tokens).
- Las enum `Module`, `Action` y `Scope` modelan el RBAC.

## 3. Frontend (SvelteKit)

### 3.1 Estructura
```
frontend-svelte/
  src/
    lib/
      api.ts           → cliente HTTP, tipos y funciones de API
      Modal.svelte      → componente modal reutilizable
      Sidebar.svelte    → navegación lateral colapsable + drawer mobile
      navigation.svelte.ts → estado de navegación (clase con $state)
      palette.svelte.ts → gestión de paletas de colores
      palettes.ts       → 8 paletas predefinidas
    routes/
      +layout.svelte    → layout principal con sidebar
      +page.svelte       → panel inicial (home summary)
      login/             → autenticación
      leagues/           → CRUD de ligas
      clubs/             → CRUD de clubes con grilla y modal
      club/[slug]/       → perfil público del club con mapa Leaflet
      players/           → CRUD de jugadores
      categories/        → CRUD de categorías
      tournaments/       → CRUD de torneos
      zones/             → listado de zonas y generación de fixture
      standings/         → tablas de posiciones
      stats/             → estadísticas y leaderboards
      settings/          → cuenta, identidad, paleta, usuarios
      register/          → registro público
      verify-email/      → verificación de correo
      reset-password/    → recuperación de contraseña
```

### 3.2 Estado y servicios
- `api.ts`: cliente HTTP basado en `fetch` con interceptores para JWT y renovación automática ante 401. Persistencia de tokens en `localStorage`.
- `navigation.svelte.ts`: estado del sidebar con clase y runes de Svelte 5 (`$state`). Colapso persistido en `localStorage`. MatchMedia para detectar mobile.
- `palette.svelte.ts`: 8 paletas de colores aplicables a todo el sitio mediante CSS custom properties en `:root`.

### 3.3 Funcionalidades destacadas
- Login con validación client-side y refresh automático.
- Panel inicial con resumen de torneos activos, zonas y posiciones.
- CRUD completo para ligas, clubes, categorías, torneos y jugadores con modales.
- Perfil público de club con mapa Leaflet, colores y redes sociales.
- Generación de fixture ida/vuelta desde el panel de zonas.
- Tablas de posiciones por zona y torneo.
- Estadísticas con leaderboards (goleadores, defensas, etc.).
- Selector de paleta de colores con 8 temas (2 oscuros).
- Registro, verificación de correo y recuperación de contraseña públicos.

## 4. Infraestructura y operaciones

- `docker-compose.yml` consume imágenes pre-built desde GHCR. El proxy inverso es `caddy-docker-proxy` compartido del VPS, conectado mediante la red externa `caddy_net`. Las labels del servicio `frontend` publican el dominio y enrutan `/api/*` y `/storage/*` al backend.
- GitHub Actions (`.github/workflows/docker-publish.yml`) ejecuta tests del backend, chequeo de tipos del frontend, y construye/publica ambas imágenes en `ghcr.io/hectororviz/ligas-deportivas-v2`.
- `infra/deploy.sh` automatiza el despliegue: `git pull`, `docker compose pull`, migraciones Prisma y `docker compose up -d`.
