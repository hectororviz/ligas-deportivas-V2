# Frontend SvelteKit

El frontend de la plataforma migró de Flutter Web a SvelteKit + TypeScript. El backend NestJS, la API REST y el esquema Prisma se conservan sin cambios.

## Stack

- **SvelteKit 2** con adapter-node para server-side rendering donde aplica.
- **Svelte 5** con runes (`$state`, `$derived`, `$effect`) para reactividad.
- **TypeScript** estricto con `svelte-check`.
- **CSS vanilla** con custom properties para el sistema de paletas de colores.
- **Fetch nativo** con refresh automático de JWT.
- **Leaflet** (CDN) para mapas en el perfil público de clubes.

## Estructura

```
frontend-svelte/
  src/
    lib/
      api.ts              → cliente HTTP, tipos y funciones
      Modal.svelte         → modal reutilizable (prop `wide`)
      Sidebar.svelte       → sidebar colapsable + drawer mobile
      navigation.svelte.ts → estado del sidebar (con subniveles)
      palette.svelte.ts    → gestión de paletas (persistida en backend)
      palettes.ts          → 36 paletas de colores
      FixtureFilters.svelte → selectores encadenados Liga → Torneo → Zona
      FechaCarousel.svelte  → carrusel horizontal de fechas
      PartidoCard.svelte    → card de partido con puntos
      PlayerGoalsModal.svelte → modal de goles por jugador (2 columnas)
    routes/
      +layout.svelte       → shell con sidebar (páginas autenticadas)
      +page.svelte         → panel inicial
      login/               → inicio de sesión
      register/            → registro público
      verify-email/        → verificación de correo
      reset-password/      → recuperación de contraseña
      leagues/             → CRUD de ligas
      clubs/               → CRUD de clubes (grilla + modal)
      club/[slug]/         → detalle del club (inscripción a torneos, acordeón)
      clubs/[clubId]/roster/ → plantel del club (asignación de jugadores)
      players/             → CRUD de jugadores (manual, masivo, escaneo DNI)
      categories/          → CRUD de categorías
      tournaments/         → CRUD de torneos (selector de categorías, borrado)
      zones/               → zonas, clubes y fixture auto/manual (drag & drop)
      fixtures/            → consulta de fixture (filtros, carrusel de fechas)
      fixtures/partido/[matchId]/ → resultado y goles por jugador
      standings/           → tablas de posiciones
      stats/               → estadísticas
      settings/            → hub de configuración
      settings/account/    → perfil y contraseña
      settings/site-identity/ → identidad del sitio (con paleta)
      settings/palette/    → selector de paleta
      settings/users/      → gestión de usuarios y permisos
```

## Funcionalidades

Todas las pantallas del frontend Flutter fueron migradas a SvelteKit, y se sumaron mejoras: menú con subniveles, alta masiva de jugadores y escaneo de DNI, fixture manual con drag & drop, página de resultados con goles por jugador y paletas de colores globales (36 temas). La API REST se consume sin modificaciones. El nuevo frontend es más ligero (~130 KB comprimido) y funciona en escritorio y mobile con sidebar adaptativo.

## Desarrollo

```bash
cd frontend-svelte
npm install
npm run dev -- --open
npm run check   # type-check
npm run build   # build de producción
```
