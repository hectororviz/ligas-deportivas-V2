<script lang="ts">
  import '../app.css';
  import Sidebar from '$lib/Sidebar.svelte';
  import LoginModal from '$lib/LoginModal.svelte';
  import { usePalette } from '$lib/palette.svelte';
  import { getSiteIdentity } from '$lib/api';

  const palette = usePalette();
  palette.initPalette();

  $effect(() => {
    getSiteIdentity()
      .then((identity) => {
        if (identity.favicon?.url) {
          const href = identity.favicon.url;
          let link = document.querySelector<HTMLLinkElement>('link[rel="icon"]');
          if (!link) {
            link = document.createElement('link');
            link.rel = 'icon';
            document.head.appendChild(link);
          }
          link.href = href;
        }
      })
      .catch(() => {});
  });
</script>

<svelte:head>
  <title>Ligas Deportivas</title>
  <meta name="description" content="Gestión de ligas y torneos deportivos" />
</svelte:head>

<Sidebar />
<main class="app-main"><slot /></main>
<LoginModal />

<style>
  .app-main { margin-left: 240px; min-height: 100vh; transition: margin-left 200ms ease; }
  :global(body.sidebar-collapsed) .app-main { margin-left: 64px; }

  @media (max-width: 767px) {
    .app-main { margin-left: 0 !important; }
  }
</style>
