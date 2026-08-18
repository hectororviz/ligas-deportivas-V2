<script lang="ts">
  import { page } from '$app/stores';
  import '../app.css';
  import Sidebar from '$lib/Sidebar.svelte';
  import { usePalette } from '$lib/palette.svelte';

  const palette = usePalette();
  palette.initPalette();

const publicRoutes = ['/login'];
$: isPublic = publicRoutes.some((route) => $page.url.pathname === route || $page.url.pathname.startsWith(route + '/'));
</script>

<svelte:head>
  <title>Ligas Deportivas</title>
  <meta name="description" content="Gestión de ligas y torneos deportivos" />
</svelte:head>

{#if isPublic}
  <slot />
{:else}
  <Sidebar />
  <main class="app-main"><slot /></main>
{/if}

<style>
  .app-main { margin-left: 240px; min-height: 100vh; transition: margin-left 200ms ease; }
  :global(body.sidebar-collapsed) .app-main { margin-left: 64px; }

  @media (max-width: 767px) {
    .app-main { margin-left: 0 !important; }
  }
</style>
