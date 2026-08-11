<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { getClubAdmin, leaveTournament, type ClubAdminOverview } from '$lib/api';

  let data: ClubAdminOverview | null = $state(null);
  let loading = $state(true);
  let error = $state('');
  let leaving: number | null = $state(null);

  onMount(() => { fetchData(); });

  $effect(() => {
    if (!data || data.club.latitude == null || data.club.longitude == null) return;
    const L = (window as any).L;
    if (!L) return;
    const el = document.getElementById('club-map');
    if (!el || (el as any)._leaflet_id) return;
    const lat = data.club.latitude;
    const lon = data.club.longitude;
    const map = L.map(el).setView([lat, lon], 16);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19, attribution: '&copy; OpenStreetMap'
    }).addTo(map);
    L.marker([lat, lon]).addTo(map);
    setTimeout(() => map.invalidateSize(), 100);
  });

  async function fetchData() {
    loading = true;
    error = '';
    try {
      data = await getClubAdmin($page.params.slug!);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo cargar la información del club.';
    } finally {
      loading = false;
    }
  }

  async function handleLeaveTournament(tournamentId: number) {
    if (!data) return;
    if (!confirm('¿Salir del torneo? Esta acción no se puede deshacer.')) return;
    leaving = tournamentId;
    try {
      await leaveTournament(data.club.id, tournamentId);
      data = await getClubAdmin($page.params.slug!);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo salir del torneo.';
    } finally {
      leaving = null;
    }
  }

  function initials(d: ClubAdminOverview | null): string {
    if (!d) return '??';
    return (d.club.shortName || d.club.name).slice(0, 2).toUpperCase();
  }
</script>

<svelte:head>
  <title>Club | Ligas Deportivas</title>
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
</svelte:head>

<main class="page-shell">
  {#if loading && !data}
    <section class="loading-card">Cargando club...</section>
  {:else if error && !data}
    <header class="page-header"><div><p class="eyebrow">Club</p><h1>Error</h1></div></header>
    <p class="error-banner">{error}</p>
    <a class="button secondary" href="/clubs">Volver a clubes</a>
  {:else if data}
    <header class="page-header">
      <div>
        <p class="eyebrow">Club</p>
        <div class="club-title-row">
          {#if data.club.logoUrl}
            <img class="club-logo" src={data.club.logoUrl} alt={data.club.name} />
          {:else}
            <span class="club-avatar" style={data.club.primaryColor ? `background:${data.club.primaryColor}` : ''}>{initials(data)}</span>
          {/if}
          <h1>{data.club.name}</h1>
        </div>
        {#if data.club.shortName && data.club.shortName !== data.club.name}
          <p class="muted">{data.club.shortName}</p>
        {/if}
      </div>
      <a class="button secondary" href="/clubs">Volver a clubes</a>
    </header>
    {#if error}<p class="error-banner">{error}</p>{/if}

    <div class="club-detail-grid">
      <section class="club-sidebar">
        <div class="card-surface club-info-card">
          <p class="eyebrow">Información</p>

          {#if data.club.primaryColor || data.club.secondaryColor}
            <div class="club-colors" style="margin-bottom:.75rem">
              <span class="info-label">Colores</span>
              <div class="color-swatches">
                {#if data.club.primaryColor}<span class="color-swatch" style={`background:${data.club.primaryColor}`}></span>{/if}
                {#if data.club.secondaryColor}<span class="color-swatch" style={`background:${data.club.secondaryColor}`}></span>{/if}
              </div>
            </div>
          {/if}

          {#if data.club.homeAddress}
            <div class="info-row">
              <span class="info-label">Dirección</span>
              <span class="info-value">{data.club.homeAddress}</span>
            </div>
          {/if}

          <div class="info-row">
            <span class="info-label">Estado</span>
            <span class={data.club.active ? 'badge-active' : 'badge-cancelled'}>{data.club.active ? 'Activo' : 'Inactivo'}</span>
          </div>

          {#if data.club.instagramUrl || data.club.facebookUrl}
            <div class="social-links">
              {#if data.club.instagramUrl}
                <a class="social-link" href={data.club.instagramUrl.startsWith('http') ? data.club.instagramUrl : `https://instagram.com/${data.club.instagramUrl.replace('@', '')}`} target="_blank" rel="noopener noreferrer">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="20" height="20" x="2" y="2" rx="5"/><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/><line x1="17.5" x2="17.51" y1="6.5" y2="6.5"/></svg>
                  Instagram
                </a>
              {/if}
              {#if data.club.facebookUrl}
                <a class="social-link" href={data.club.facebookUrl.startsWith('http') ? data.club.facebookUrl : `https://facebook.com/${data.club.facebookUrl.replace('@', '')}`} target="_blank" rel="noopener noreferrer">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z"/></svg>
                  Facebook
                </a>
              {/if}
            </div>
          {/if}
        </div>

        {#if data.club.latitude != null && data.club.longitude != null}
          <div class="card-surface map-container" id="club-map"></div>
        {/if}
      </section>

      <section class="club-main">
        <div class="card-surface">
          <div class="list-header">
            <div>
              <p class="eyebrow">Participación</p>
              <h2>Torneos</h2>
            </div>
            <span class="count-pill">{data.tournaments.length}</span>
          </div>

          {#if data.tournaments.length === 0}
            <div class="empty-state compact-empty">
              <h2>Sin torneos</h2>
              <p>El club no participa en ningún torneo actualmente.</p>
            </div>
          {:else}
            <div class="tournament-list">
              {#each data.tournaments as tournament}
                <article class="tournament-card club-tournament">
                  <div class="tournament-head">
                    <div>
                      <p class="card-kicker">{tournament.year}</p>
                      <h3>{tournament.name}</h3>
                    </div>
                    <button
                      class="button secondary leave-btn"
                      disabled={leaving === tournament.id}
                      onclick={() => handleLeaveTournament(tournament.id)}
                    >
                      {leaving === tournament.id ? 'Saliendo...' : 'Salir del torneo'}
                    </button>
                  </div>

                  {#if tournament.zone}
                    <p class="muted" style="margin:.5rem 0 0">Zona: {tournament.zone.name}</p>
                  {/if}

                  {#if tournament.categories.length > 0}
                    <div class="category-list">
                      {#each tournament.categories as cat}
                        <div class="category-item">
                          <span>{cat.category.name}</span>
                          <div class="category-meta">
                            {#if cat.kickoffTime}<span class="badge-muted">{cat.kickoffTime}</span>{/if}
                            {#if cat.countsForGeneral}<span class="tag tag-green">General</span>{/if}
                          </div>
                        </div>
                      {/each}
                    </div>
                  {:else}
                    <p class="muted" style="margin-top:.5rem">Sin categorías asignadas.</p>
                  {/if}
                </article>
              {/each}
            </div>
          {/if}
        </div>
      </section>
    </div>
  {/if}
</main>

<style>
  .club-title-row {
    display: flex;
    align-items: center;
    gap: .8rem;
    margin-top: .35rem;
  }
  .club-title-row h1 {
    margin: 0;
    font-family: 'Space Grotesk', sans-serif;
    font-size: clamp(2.5rem, 5vw, 4.5rem);
    color: var(--color-heading);
    letter-spacing: -.04em;
  }
  .club-logo {
    width: 3.5rem;
    height: 3.5rem;
    border-radius: .75rem;
    object-fit: contain;
  }
  .club-avatar {
    width: 3.5rem;
    height: 3.5rem;
    display: grid;
    place-items: center;
    border-radius: .75rem;
    color: #fff;
    background: var(--color-accent);
    font-family: 'Space Grotesk', sans-serif;
    font-weight: 700;
    font-size: 1.2rem;
  }
  .club-detail-grid {
    display: grid;
    grid-template-columns: minmax(0, 320px) minmax(0, 1fr);
    gap: 1.5rem;
    margin-top: 1rem;
  }
  .club-info-card {
    padding: 1.4rem;
  }
  .info-label {
    color: var(--color-text-muted);
    font-size: .78rem;
    font-weight: 600;
    text-transform: uppercase;
  }
  .info-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: .6rem 0;
    border-top: 1px solid var(--color-border);
  }
  .info-row:first-of-type {
    border-top: 0;
  }
  .info-value {
    color: var(--color-text);
    font-weight: 500;
    text-align: right;
    max-width: 60%;
  }
  .color-swatches {
    display: flex;
    gap: .4rem;
    margin-top: .3rem;
  }
  .color-swatch {
    width: 1.5rem;
    height: 1.5rem;
    border-radius: .4rem;
    border: 1px solid var(--color-border);
  }
  .social-links {
    display: flex;
    gap: .5rem;
    margin-top: 1rem;
    padding-top: 1rem;
    border-top: 1px solid var(--color-border);
  }
  .social-link {
    display: flex;
    align-items: center;
    gap: .4rem;
    padding: .45rem .7rem;
    border-radius: .5rem;
    color: var(--color-text-muted);
    text-decoration: none;
    font-size: .82rem;
    font-weight: 600;
    transition: background 150ms ease;
  }
  .social-link:hover {
    background: var(--color-surface-hover);
    color: var(--color-text);
  }
  .map-container {
    padding: 0;
    overflow: hidden;
    height: 250px;
    border-radius: .7rem;
  }
  .map-container :global(.leaflet-container) {
    width: 100%;
    height: 100%;
    border-radius: .7rem;
  }
  .tournament-list {
    margin-top: 1rem;
    display: grid;
    gap: .75rem;
  }
  .club-tournament {
    padding: 1.4rem;
  }
  .club-tournament h3 {
    font-family: 'Space Grotesk', sans-serif;
    font-size: 1.25rem;
    margin: .25rem 0 0;
  }
  .tournament-head {
    display: flex;
    justify-content: space-between;
    align-items: start;
    gap: 1rem;
  }
  .leave-btn {
    white-space: nowrap;
    font-size: .82rem;
    padding: .55rem .85rem;
  }
  .category-list {
    margin-top: .75rem;
    display: grid;
    gap: .35rem;
  }
  .category-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: .55rem .75rem;
    border-radius: .5rem;
    background: var(--color-surface-hover);
    font-size: .88rem;
    font-weight: 500;
  }
  .category-meta {
    display: flex;
    align-items: center;
    gap: .4rem;
  }
  .club-title-row {
    margin-top: .35rem;
  }

  @media (max-width: 767px) {
    .club-detail-grid {
      grid-template-columns: 1fr;
    }
    .tournament-head {
      flex-direction: column;
    }
  }
</style>
