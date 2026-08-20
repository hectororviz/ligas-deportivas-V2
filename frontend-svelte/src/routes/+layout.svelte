<script lang="ts">
  import '../app.css';
  import { browser } from '$app/environment';
  import Sidebar from '$lib/Sidebar.svelte';
  import LoginModal from '$lib/LoginModal.svelte';
  import Splash from '$lib/Splash.svelte';
  import { usePalette } from '$lib/palette.svelte';
  import { getSiteIdentity } from '$lib/api';

  const palette = usePalette();
  palette.initPalette();

  const SPLASH_STORAGE_KEY = 'ligas.splash';
  const DEFAULT_SPLASH_DURATION = 5000;

  interface CachedSplash {
    url: string;
    duration: number;
  }

  function readCachedSplash(): CachedSplash | null {
    if (!browser) return null;
    try {
      const raw = localStorage.getItem(SPLASH_STORAGE_KEY);
      if (!raw) return null;
      const parsed = JSON.parse(raw);
      if (parsed && typeof parsed.url === 'string' && parsed.url) {
        return { url: parsed.url, duration: Number(parsed.duration) || DEFAULT_SPLASH_DURATION };
      }
      return null;
    } catch {
      return null;
    }
  }

  function writeCachedSplash(cache: CachedSplash) {
    if (!browser) return;
    try {
      localStorage.setItem(SPLASH_STORAGE_KEY, JSON.stringify(cache));
    } catch {}
  }

  const cachedSplash = readCachedSplash();

  let loadingAnimationUrl = $state<string | null>(cachedSplash?.url ?? null);
  let loadingAnimationDuration = $state<number>(cachedSplash?.duration ?? DEFAULT_SPLASH_DURATION);
  let showSplash = $state(cachedSplash?.url != null);

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

        const freshUrl = identity.loadingAnimationUrl ?? null;
        if (freshUrl) {
          const duration = identity.loadingAnimationDuration ?? DEFAULT_SPLASH_DURATION;
          writeCachedSplash({ url: freshUrl, duration });
          if (!showSplash) {
            loadingAnimationUrl = freshUrl;
            loadingAnimationDuration = duration;
            showSplash = true;
          }
        } else {
          try {
            localStorage.removeItem(SPLASH_STORAGE_KEY);
          } catch {}
          showSplash = false;
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
  <Splash url={loadingAnimationUrl} duration={loadingAnimationDuration} onDone={() => (showSplash = false)} />
{/if}

<style>
  .app-main { margin-left: 240px; min-height: 100vh; transition: margin-left 200ms ease; }
  :global(body.sidebar-collapsed) .app-main { margin-left: 64px; }

  @media (max-width: 767px) {
    .app-main { margin-left: 0 !important; }
  }
</style>
