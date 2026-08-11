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
      Modal.svelte         → modal reutilizable
      Sidebar.svelte       → sidebar colapsable + drawer mobile
      navigation.svelte.ts → estado del sidebar
      palette.svelte.ts    → gestión de paletas
      palettes.ts          → 8 paletas de colores
    routes/
      +layout.svelte       → shell con sidebar (páginas autenticadas)
      +page.svelte         → panel inicial
      login/               → inicio de sesión
      register/            → registro público
      verify-email/        → verificación de correo
      reset-password/      → recuperación de contraseña
      leagues/             → CRUD de ligas
      clubs/               → CRUD de clubes (grilla + modal)
      club/[slug]/         → perfil público con mapa
      clubs/[clubId]/roster/ → plantel del club
      players/             → CRUD de jugadores
      categories/          → CRUD de categorías
      tournaments/         → CRUD de torneos
      zones/               → zonas y generación de fixture
      standings/           → tablas de posiciones
      stats/               → estadísticas
      settings/            → hub de configuración
      settings/account/    → perfil y contraseña
      settings/site-identity/ → identidad del sitio
      settings/palette/    → selector de paleta
      settings/users/      → gestión de usuarios
```

## Funcionalidades

Todas las pantallas del frontend Flutter fueron migradas a SvelteKit. La API REST se consume sin modificaciones. El nuevo frontend es más ligero (~130 KB comprimido) y funciona en escritorio y mobile con sidebar adaptativo.

## Desarrollo

```bash
cd frontend-svelte
npm install
npm run dev -- --open
npm run check   # type-check
npm run build   # build de producción
```
