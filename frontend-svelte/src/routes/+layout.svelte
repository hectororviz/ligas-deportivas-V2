<script lang="ts">
  import '../app.css';
  import Sidebar from '$lib/Sidebar.svelte';
  import LoginModal from '$lib/LoginModal.svelte';
  import Splash from '$lib/Splash.svelte';
  import { usePalette } from '$lib/palette.svelte';
  import { getSiteIdentity } from '$lib/api';

  const palette = usePalette();
  palette.initPalette();

  let loadingAnimationUrl = $state<string | null>(null);
  let showSplash = $state(false);

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
        if (identity.loadingAnimationUrl) {
          loadingAnimationUrl = identity.loadingAnimationUrl;
          showSplash = true;
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

{#if showSplash && loadingAnimationUrl}
  <Splash url={loadingAnimationUrl} onDone={() => (showSplash = false)} />
{/if}

<style>
  .app-main { margin-left: 240px; min-height: 100vh; transition: margin-left 200ms ease; }
  :global(body.sidebar-collapsed) .app-main { margin-left: 64px; }

  @media (max-width: 767px) {
    .app-main { margin-left: 0 !important; }
  }
</style>
