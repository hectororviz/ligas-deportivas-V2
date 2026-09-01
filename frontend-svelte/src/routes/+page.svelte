<script lang="ts">
  import { onMount } from 'svelte';
  import TournamentZonesRow from '$lib/TournamentZonesRow.svelte';
  import { getHomeSummary, getProfile, hasSession, listAllClubs, getSiteIdentity, type AuthUser, type HomeSummary, type Club, type HomeBackgroundConfig } from '$lib/api';

  let user: AuthUser | null = null;
  let summary: HomeSummary | null = null;
  let loading = true;
  let error = '';
  let clubs: Club[] = [];
  let bannerShields: { logoUrl: string | null | undefined; label: string }[] = [];
  let homeBg: HomeBackgroundConfig = { enabled: true, opacity: 0.6, speed: 25, shieldSize: 90, shieldGap: 30, backgroundColor: '#173d35' };
  let siteTitle = 'Ligas Deportivas';
  let siteSlogan = '';

  onMount(async () => {
    try {
      const profilePromise = hasSession() ? getProfile().catch(() => null) : Promise.resolve(null);
      const clubsPromise = listAllClubs().catch(() => [] as Club[]);
      const identityPromise = getSiteIdentity().catch(() => null);
      const [u, s, cs, ident] = await Promise.all([profilePromise, getHomeSummary(), clubsPromise, identityPromise]);
      user = u;
      summary = s;
      clubs = cs;
      if (ident?.homeBackground) homeBg = ident.homeBackground;
      if (ident) {
        if (ident.title) siteTitle = ident.title;
        siteSlogan = ident.slogan ?? '';
      }
      bannerShields = buildBannerShields(cs);
    } catch {
      error = 'No pudimos cargar el resumen de torneos.';
    } finally {
      loading = false;
    }
  });

  function buildBannerShields(list: Club[]) {
    const base = list.slice(0, 16).map((c) => ({ logoUrl: c.logoUrl, label: c.shortName || c.name }));
    let arr = base;
    while (arr.length > 0 && arr.length < 8) arr = arr.concat(base);
    return arr;
  }
</script>

{#if loading}
  <main class="loading-screen">Cargando sesión...</main>
{:else}
  <main class="dashboard-shell">
    <section
      class="home-banner"
      style={`--shield-size: ${homeBg.shieldSize}px; --shield-gap: ${homeBg.shieldGap}px; --marquee-speed: ${homeBg.speed}s; --glass-opacity: ${homeBg.opacity}; --banner-bg: ${homeBg.backgroundColor};`}
    >
      {#if homeBg.enabled}
        <div class="banner-engine" aria-hidden="true">
          <div class="shield-row row-1">
            <div class="shield-track track-right">
              {#each [...bannerShields, ...bannerShields] as shield, i (i)}
                <span class="shield">
                  {#if shield.logoUrl}
                    <img src={shield.logoUrl} alt="" loading="lazy" />
                  {:else}
                    <span class="shield-initials">{shield.label.slice(0, 2).toUpperCase()}</span>
                  {/if}
                </span>
              {/each}
            </div>
          </div>
          <div class="shield-row row-2">
            <div class="shield-track track-left">
              {#each [...bannerShields, ...bannerShields] as shield, i (i)}
                <span class="shield">
                  {#if shield.logoUrl}
                    <img src={shield.logoUrl} alt="" loading="lazy" />
                  {:else}
                    <span class="shield-initials">{shield.label.slice(0, 2).toUpperCase()}</span>
                  {/if}
                </span>
              {/each}
            </div>
          </div>
          <div class="shield-row row-3">
            <div class="shield-track track-right">
              {#each [...bannerShields, ...bannerShields] as shield, i (i)}
                <span class="shield">
                  {#if shield.logoUrl}
                    <img src={shield.logoUrl} alt="" loading="lazy" />
                  {:else}
                    <span class="shield-initials">{shield.label.slice(0, 2).toUpperCase()}</span>
                  {/if}
                </span>
              {/each}
            </div>
          </div>
        </div>
        <div class="banner-glass"></div>
      {/if}

      {#if user}
        <p class="banner-greeting">Hola, {user.firstName}</p>
      {/if}

      <div class="banner-content">
        <h1>{siteTitle}</h1>
        {#if siteSlogan}
          <p class="banner-sub">{siteSlogan}</p>
        {/if}
      </div>
    </section>
    {#if error}
      <section class="error-banner">{error}</section>
    {:else if summary?.tournaments.length === 0}
      <section class="empty-state">
        <span class="empty-icon">+</span>
        <h2>No hay torneos vigentes</h2>
        <p>Cuando haya torneos activos podrás ver aquí el resumen por zonas.</p>
      </section>
    {:else}
      <section class="section-heading">
        <div>
          <p class="eyebrow">Competencia</p>
          <h2>Torneos vigentes</h2>
        </div>
      </section>

      {#each summary?.tournaments ?? [] as tournament}
        <TournamentZonesRow tournament={tournament} />
      {/each}
    {/if}
  </main>
{/if}

<style>
  /* ===== Banner ===== */
  .home-banner {
    position: relative;
    overflow: hidden;
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 272px;
    border-radius: 1.5rem;
    background: var(--banner-bg, var(--color-hero));
    box-shadow: 0 24px 60px var(--color-shadow);
    padding: clamp(2rem, 5vw, 4rem);
  }
  .banner-engine { position: absolute; inset: 0; pointer-events: none; }
  .shield-row {
    position: absolute;
    left: -10%;
    right: -10%;
    overflow: hidden;
  }
  .shield-row.row-1 { top: calc(var(--shield-size) * -0.5); transform: skewX(-30deg); }
  .shield-row.row-2 { top: 50%; transform: translateY(-50%) skewX(30deg); }
  .shield-row.row-3 { bottom: calc(var(--shield-size) * -0.5); transform: skewX(-30deg); }
  .shield-track { display: flex; width: max-content; }
  .track-right { animation: marquee-right var(--marquee-speed) linear infinite; }
  .track-left { animation: marquee-left var(--marquee-speed) linear infinite; }
  .shield {
    flex: 0 0 auto;
    width: var(--shield-size);
    height: var(--shield-size);
    margin-right: var(--shield-gap);
    display: grid;
    place-items: center;
    color: #fff;
    font-weight: 700;
  }
  .shield img {
    width: 100%;
    height: 100%;
    object-fit: contain;
    filter: drop-shadow(0 2px 4px rgba(0,0,0,.35));
  }
  .shield-initials { font-size: calc(var(--shield-size) * 0.3); text-shadow: 0 2px 6px rgba(0,0,0,.5); }
  .row-1 .shield, .row-3 .shield { transform: skewX(30deg); }
  .row-2 .shield { transform: skewX(-30deg); }

  .banner-glass {
    position: absolute;
    inset: 0;
    backdrop-filter: blur(8px);
    background: rgba(15, 23, 42, var(--glass-opacity));
  }

  .banner-greeting {
    position: absolute;
    top: 1rem;
    left: 1.25rem;
    z-index: 10;
    margin: 0;
    font-size: .9rem;
    font-weight: 600;
    color: rgba(255,255,255,.92);
    text-shadow: 0 2px 8px rgba(0,0,0,.45);
  }
  .banner-content {
    position: relative;
    z-index: 10;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
    gap: .5rem;
    color: #fff;
  }
  .banner-content h1 {
    margin: 0;
    font-family: 'Space Grotesk', sans-serif;
    font-size: clamp(3rem, 7.5vw, 5.4rem);
    letter-spacing: -.04em;
    line-height: 1.05;
    text-shadow:
      0 3px 16px rgba(0,0,0,.45),
      -1px -1px 0 rgba(0,0,0,.55),
      1px -1px 0 rgba(0,0,0,.55),
      -1px 1px 0 rgba(0,0,0,.55),
      1px 1px 0 rgba(0,0,0,.55);
  }
  .banner-sub {
    margin: 0;
    color: rgba(255,255,255,.88);
    text-shadow: 0 2px 8px rgba(0,0,0,.4);
    line-height: 1.5;
    max-width: 56ch;
  }

  @keyframes marquee-right {
    from { transform: translateX(-50%); }
    to { transform: translateX(0); }
  }
  @keyframes marquee-left {
    from { transform: translateX(0); }
    to { transform: translateX(-50%); }
  }
</style>
