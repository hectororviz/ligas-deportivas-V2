<script lang="ts">
  import { onMount } from 'svelte';
  import { getHomeSummary, getProfile, hasSession, logout, listAllClubs, getSiteIdentity, type AuthUser, type HomeSummary, type HomeMatchday, type Club, type HomeBackgroundConfig } from '$lib/api';
  import { loginModalState } from '$lib/login-modal.svelte';

  let user: AuthUser | null = null;
  let summary: HomeSummary | null = null;
  let loading = true;
  let error = '';
  let selectedTournamentId: number | null = null;
  let clubs: Club[] = [];
  let bannerShields: { logoUrl: string | null | undefined; color: string | null | undefined; label: string }[] = [];
  let homeBg: HomeBackgroundConfig = { enabled: true, opacity: 0.6, speed: 25, shieldSize: 90, shieldGap: 30 };

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
      bannerShields = buildBannerShields(cs);
    } catch {
      error = 'No pudimos cargar el resumen de torneos.';
    } finally {
      loading = false;
    }
  });

  function buildBannerShields(list: Club[]) {
    let base: typeof bannerShields;
    if (list.length > 0) {
      base = list.slice(0, 16).map((c) => ({ logoUrl: c.logoUrl, color: c.primaryColor, label: c.shortName || c.name }));
    } else {
      const palette = ['#759b51', '#3b82c4', '#c46a3b', '#7c5cbf', '#d46050', '#b8860b', '#0062a8', '#c05078'];
      base = palette.map((color) => ({ logoUrl: null, color, label: '' }));
    }
    let arr = base;
    while (arr.length < 8) arr = arr.concat(base);
    return arr;
  }

  function toggleTournament(id: number) {
    selectedTournamentId = selectedTournamentId === id ? null : id;
  }

  async function signOut() {
    await logout();
    window.location.href = '/';
  }

  function formatNextMatchday(md: HomeMatchday | null): string {
    if (!md) return 'Sin próxima fecha';
    const base = `Fecha ${md.matchday}`;
    if (!md.date) return base;
    const d = new Date(md.date);
    if (isNaN(d.getTime())) return base;
    const weekday = d.toLocaleDateString('es-AR', { weekday: 'long' });
    const capitalized = weekday.charAt(0).toUpperCase() + weekday.slice(1);
    const dayMonth = d.toLocaleDateString('es-AR', { day: '2-digit', month: '2-digit' });
    return `${capitalized} ${dayMonth} - Fecha ${md.matchday}`;
  }
</script>

{#if loading}
  <main class="loading-screen">Cargando sesión...</main>
{:else}
  <main class="dashboard-shell">
    <section
      class="home-banner"
      style={`--shield-size: ${homeBg.shieldSize}px; --shield-gap: ${homeBg.shieldGap}px; --marquee-speed: ${homeBg.speed}s; --glass-opacity: ${homeBg.opacity};`}
    >
      {#if homeBg.enabled}
        <div class="banner-engine" aria-hidden="true">
          <div class="shield-row row-1">
            <div class="shield-track track-right">
              {#each [...bannerShields, ...bannerShields] as shield, i (i)}
                <span class="shield" style={shield.color ? `background:${shield.color}` : ''}>
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
                <span class="shield" style={shield.color ? `background:${shield.color}` : ''}>
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
                <span class="shield" style={shield.color ? `background:${shield.color}` : ''}>
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

      <div class="banner-content">
        <p class="banner-eyebrow">{user ? `Hola, ${user.firstName}` : 'Ligas Deportivas'}</p>
        <h1>Torneos vigentes</h1>
        <p class="banner-sub">Resumen de torneos activos y posiciones por zona.</p>
        <div class="banner-actions">
          {#if user}
            <a class="button primary" href="/leagues">Ver ligas</a>
            <button class="button secondary" onclick={signOut}>Cerrar sesión</button>
          {:else}
            <button class="button primary" onclick={() => loginModalState.openModal()}>Ingresar</button>
          {/if}
        </div>
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

      <div class="tournament-chips">
        {#each summary?.tournaments ?? [] as tournament}
          <button
            class="chip"
            class:active={selectedTournamentId === tournament.id}
            onclick={() => toggleTournament(tournament.id)}
          >
            {tournament.leagueName} - {tournament.year}
          </button>
        {/each}
      </div>

      <section class="zone-grid">
        {#each summary?.tournaments ?? [] as tournament}
          {#if selectedTournamentId == null || tournament.id === selectedTournamentId}
            {#each tournament.zones as zone}
              <article class="zone-card">
                <div class="zone-header">
                  <p class="card-kicker">{tournament.leagueName} · {tournament.year}</p>
                  <div class="zone-title-row">
                    <h3>Zona {zone.name}</h3>
                    <div class="zone-actions">
                      <a class="zone-btn" href={`/fixtures?torneo=${tournament.id}&zona=${zone.id}`}>Fixture</a>
                      <a class="zone-btn" href={`/standings?torneo=${tournament.id}&zona=${zone.id}`}>Tabla</a>
                    </div>
                  </div>
                </div>

                {#if zone.top.length}
                  <div class="standings">
                    {#each zone.top as row, index}
                      <div class="stand-row">
                        <span class="stand-pos">{index + 1}</span>
                        <span class="stand-club">{row.clubName}</span>
                        <span class="stand-pts">{row.points} pts</span>
                      </div>
                    {/each}
                  </div>
                {:else}
                  <p class="muted compact">Todavía no hay posiciones.</p>
                {/if}

                <div class="zone-footer">
                  {#if zone.nextMatchday}Próxima Fecha: {formatNextMatchday(zone.nextMatchday)}{:else}Sin próxima fecha{/if}
                </div>
              </article>
            {/each}
          {/if}
        {/each}
      </section>
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
    min-height: 340px;
    border-radius: 1.5rem;
    background: var(--color-hero);
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
  .shield-row.row-1 { top: -6%; transform: skewX(-30deg); }
  .shield-row.row-2 { top: 34%; transform: skewX(30deg); }
  .shield-row.row-3 { bottom: -6%; transform: skewX(-30deg); }
  .shield-track { display: flex; width: max-content; }
  .track-right { animation: marquee-right var(--marquee-speed) linear infinite; }
  .track-left { animation: marquee-left var(--marquee-speed) linear infinite; }
  .shield {
    flex: 0 0 auto;
    width: var(--shield-size);
    height: var(--shield-size);
    margin-right: var(--shield-gap);
    border-radius: 50%;
    background: var(--color-accent);
    display: grid;
    place-items: center;
    color: #fff;
    font-weight: 700;
    overflow: hidden;
    box-shadow: 0 4px 14px rgba(0,0,0,.25);
  }
  .shield img { width: 100%; height: 100%; object-fit: cover; }
  .shield-initials { font-size: calc(var(--shield-size) * 0.3); }
  .row-1 .shield, .row-3 .shield { transform: skewX(30deg); }
  .row-2 .shield { transform: skewX(-30deg); }

  .banner-glass {
    position: absolute;
    inset: 0;
    backdrop-filter: blur(8px);
    background: rgba(15, 23, 42, var(--glass-opacity));
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
  .banner-eyebrow {
    margin: 0;
    font-size: .74rem;
    font-weight: 700;
    letter-spacing: .18em;
    text-transform: uppercase;
    color: rgba(255,255,255,.8);
    text-shadow: 0 2px 8px rgba(0,0,0,.4);
  }
  .banner-content h1 {
    margin: 0;
    font-family: 'Space Grotesk', sans-serif;
    font-size: clamp(2rem, 5vw, 3.6rem);
    letter-spacing: -.04em;
    line-height: 1.05;
    text-shadow: 0 3px 16px rgba(0,0,0,.45);
  }
  .banner-sub {
    margin: 0;
    color: rgba(255,255,255,.88);
    text-shadow: 0 2px 8px rgba(0,0,0,.4);
    line-height: 1.5;
  }
  .banner-actions { display: flex; gap: .6rem; flex-wrap: wrap; justify-content: center; margin-top: .75rem; }

  @keyframes marquee-right {
    from { transform: translateX(-50%); }
    to { transform: translateX(0); }
  }
  @keyframes marquee-left {
    from { transform: translateX(0); }
    to { transform: translateX(-50%); }
  }

  .tournament-chips {
    display: flex;
    flex-wrap: wrap;
    gap: .5rem;
    margin: .75rem 0 1.5rem;
  }
  .chip {
    border: 1px solid var(--color-border);
    background: var(--color-surface);
    color: var(--color-text-muted);
    padding: .45rem .95rem;
    border-radius: 999px;
    font-size: .84rem;
    font-weight: 600;
    cursor: pointer;
    transition: background 150ms ease, color 150ms ease, border-color 150ms ease;
  }
  .chip:hover { background: var(--color-surface-hover); color: var(--color-text); }
  .chip.active {
    background: var(--color-accent-bg);
    border-color: var(--color-accent);
    color: var(--color-accent-text);
  }

  .zone-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 1rem;
  }
  .zone-card {
    display: flex;
    flex-direction: column;
    padding: 1.25rem;
    border: 1px solid var(--color-border);
    border-radius: 1.2rem;
    background: var(--color-surface);
    box-shadow: 0 16px 45px var(--color-shadow);
  }
  .zone-header { display: block; }
  .zone-title-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: .75rem;
    margin-top: .35rem;
  }
  .zone-title-row h3 {
    margin: 0;
    font-family: 'Space Grotesk', sans-serif;
    font-size: 1.25rem;
    letter-spacing: -.02em;
    min-width: 0;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .card-kicker {
    margin: 0;
    color: var(--color-accent-text);
    font-size: .72rem;
    font-weight: 700;
    letter-spacing: .08em;
    text-transform: uppercase;
  }
  .zone-actions {
    display: flex;
    gap: .35rem;
    flex: 0 0 auto;
  }
  .zone-btn {
    display: inline-flex;
    align-items: center;
    padding: .35rem .6rem;
    border: 1px solid var(--color-border);
    border-radius: .55rem;
    color: var(--color-accent-text);
    background: var(--color-accent-bg);
    font-size: .74rem;
    font-weight: 700;
    text-decoration: none;
    white-space: nowrap;
    transition: background 150ms ease, border-color 150ms ease;
  }
  .zone-btn:hover { background: var(--color-accent); border-color: var(--color-accent); color: #fff; }

  .standings { margin-top: .9rem; }
  .stand-row {
    display: flex;
    align-items: center;
    gap: .5rem;
    padding: .4rem 0;
    border-top: 1px solid var(--color-border);
    font-size: .88rem;
  }
  .stand-pos {
    width: 1.35rem;
    height: 1.35rem;
    display: grid;
    place-items: center;
    border-radius: 50%;
    color: var(--color-accent-text);
    background: var(--color-accent-bg);
    font-size: .68rem;
    font-weight: 700;
    flex: 0 0 auto;
  }
  .stand-club {
    min-width: 0;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    font-weight: 500;
  }
  .stand-pts {
    margin-left: auto;
    color: var(--color-text-muted);
    font-size: .78rem;
    font-weight: 700;
    white-space: nowrap;
  }

  .zone-footer {
    margin-top: auto;
    padding-top: .6rem;
    border-top: 1px solid var(--color-border);
    color: var(--color-accent-text);
    font-size: .78rem;
    font-weight: 600;
  }
</style>
