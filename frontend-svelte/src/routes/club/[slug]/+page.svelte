<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { getClubAdmin, getAvailableTournaments, joinTournament, leaveTournament, getProfile, canManageModule, type ClubAdminOverview, type AvailableTournament, type AuthUser } from '$lib/api';
  import Modal from '$lib/Modal.svelte';
  import { Plus, MapPin, Navigation, ArrowUpRight } from '@lucide/svelte';

  const statusLabels: Record<string, string> = {
    DRAFT: 'Borrador', ACTIVE: 'Activo', FINISHED: 'Finalizado', CANCELLED: 'Cancelado'
  };
  const statusClasses: Record<string, string> = {
    DRAFT: 'badge-muted', ACTIVE: 'badge-active', FINISHED: 'badge-finished', CANCELLED: 'badge-cancelled'
  };

  let data: ClubAdminOverview | null = $state(null);
  let user = $state<AuthUser | null>(null);
  let loading = $state(true);
  let error = $state('');
  let notice = $state('');
  let saving = $state(false);
  let leaving: number | null = $state(null);

  let showJoinModal = $state(false);
  let availableTournaments = $state<AvailableTournament[]>([]);
  let loadingAvailable = $state(false);

  let canManageClubes = $derived.by(() => {
    if (canManageModule(user, 'CLUBES')) return true;
    if (!user || !data) return false;
    const clubId = user.club?.id ?? null;
    return user.moduleLevels?.CLUBES === 'MODIFICACION_CLUB' && clubId != null && clubId === data.club.id;
  });

  let socials = $derived.by(() => {
    const c = data?.club;
    if (!c) return [];
    const list: { kind: 'facebook' | 'instagram'; label: string; href: string; handle: string }[] = [];
    if (c.facebookUrl) list.push({ kind: 'facebook', label: 'Facebook', href: socialHref(c.facebookUrl, 'facebook'), handle: socialHandle(c.facebookUrl, 'facebook') });
    if (c.instagramUrl) list.push({ kind: 'instagram', label: 'Instagram', href: socialHref(c.instagramUrl, 'instagram'), handle: socialHandle(c.instagramUrl, 'instagram') });
    return list;
  });

  let genderBadges = $derived.by(() => {
    if (!data) return [];
    const genders = new Set<string>();
    for (const t of data.tournaments) for (const c of t.categories) if (c.gender) genders.add(c.gender);
    return [...genders].sort().map(genderChipLabel);
  });

  let categoryCount = $derived.by(() => {
    if (!data) return 0;
    const names = new Set<string>();
    for (const t of data.tournaments) for (const c of t.categories) names.add(c.category.name);
    return names.size;
  });

  let mapsHref = $derived.by(() => {
    const c = data?.club;
    if (!c) return '';
    const lat = Number(c.latitude);
    const lon = Number(c.longitude);
    if (c.latitude != null && c.longitude != null && Number.isFinite(lat) && Number.isFinite(lon)) {
      return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(`${lat},${lon}`)}`;
    }
    if (c.homeAddress) {
      return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(c.homeAddress)}`;
    }
    return '';
  });

  function genderChipLabel(g: string): string {
    if (g === 'MASCULINO') return 'Fútbol Masculino';
    if (g === 'FEMENINO') return 'Fútbol Femenino';
    if (g === 'MIXTO') return 'Fútbol Mixto';
    return g;
  }

  function socialHref(url: string, kind: 'facebook' | 'instagram'): string {
    if (/^https?:\/\//i.test(url)) return url;
    const base = kind === 'instagram' ? 'https://instagram.com/' : 'https://facebook.com/';
    return base + url.replace(/^@/, '').replace(/^\/+/, '');
  }

  function socialHandle(url: string, kind: 'facebook' | 'instagram'): string {
    const clean = url
      .replace(/^https?:\/\/(www\.)?(instagram|facebook)\.com\//i, '')
      .replace(/^@/, '')
      .replace(/\/+$/, '');
    if (kind === 'instagram' && clean) return `@${clean}`;
    return clean;
  }

  onMount(() => {
    fetchData();
    getProfile().then((u) => user = u).catch(() => {});
  });

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
    loading = true; error = '';
    try {
      data = await getClubAdmin($page.params.slug!);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo cargar la informacion del club.';
    } finally { loading = false; }
  }

  async function openJoinModal() {
    if (!data) return;
    showJoinModal = true;
    loadingAvailable = true;
    try {
      availableTournaments = await getAvailableTournaments(data.club.id);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar los torneos disponibles.';
    } finally { loadingAvailable = false; }
  }

  function closeJoinModal() { showJoinModal = false; }

  async function handleJoin(tournament: AvailableTournament) {
    if (!data) return;
    saving = true; error = '';
    const allCatIds = tournament.categories.map(c => c.tournamentCategoryId);
    try {
      await joinTournament(data.club.id, {
        tournamentId: tournament.id,
        tournamentCategoryIds: allCatIds
      });
      notice = 'Club agregado al torneo.';
      showJoinModal = false;
      data = await getClubAdmin($page.params.slug!);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo agregar el club al torneo.';
    } finally {
      saving = false;
      setTimeout(() => notice = '', 2500);
    }
  }

  async function handleLeaveTournament(tournamentId: number) {
    if (!data) return;
    if (!confirm('¿Salir del torneo? Esta accion no se puede deshacer.')) return;
    leaving = tournamentId;
    try {
      await leaveTournament(data.club.id, tournamentId);
      data = await getClubAdmin($page.params.slug!);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo salir del torneo.';
    } finally { leaving = null; }
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

<main class="page-shell club-page">
  {#if loading && !data}
    <section class="loading-card">Cargando club...</section>
  {:else if error && !data}
    <header class="page-header"><div><p class="eyebrow">Club</p><h1>Error</h1></div></header>
    <p class="error-banner">{error}</p>
  {:else if data}
    <section
      class="club-hero"
      style={`--club-primary: ${data.club.primaryColor || '#759b51'}; --club-secondary: ${data.club.secondaryColor || '#d0e87c'};`}
    >
      <div class="hero-shape hero-shape-a"></div>
      <div class="hero-shape hero-shape-b"></div>
      <div class="hero-stripes"></div>

      <div class="hero-inner">
        <div class="hero-logo">
          {#if data.club.logoUrl}
            <img src={data.club.logoUrl} alt={`Escudo de ${data.club.name}`} />
          {:else}
            <span>{initials(data)}</span>
          {/if}
        </div>

        <div class="hero-text">
          <p class="hero-kicker">Club</p>
          <h1>{data.club.name}</h1>
          {#if data.club.shortName && data.club.shortName !== data.club.name}
            <p class="hero-short">{data.club.shortName}</p>
          {/if}
          <div class="hero-badges">
            <span class="hero-badge" class:inactive={!data.club.active}>{data.club.active ? 'Activo' : 'Inactivo'}</span>
            {#each genderBadges as g}<span class="hero-badge">{g}</span>{/each}
            <span class="hero-badge">{data.tournaments.length} {data.tournaments.length === 1 ? 'torneo' : 'torneos'}</span>
            {#if categoryCount > 0}<span class="hero-badge">{categoryCount} {categoryCount === 1 ? 'categoría' : 'categorías'}</span>{/if}
          </div>
        </div>

        {#if socials.length > 0}
          <div class="hero-socials">
            {#each socials as s}
              <a class="hero-social" href={s.href} target="_blank" rel="noopener noreferrer" aria-label={s.label}>
                {#if s.kind === 'facebook'}
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z"/></svg>
                {:else if s.kind === 'instagram'}
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="20" height="20" x="2" y="2" rx="5"/><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/><line x1="17.5" x2="17.51" y1="6.5" y2="6.5"/></svg>
                {/if}
                <span>{s.label}</span>
              </a>
            {/each}
          </div>
        {/if}
      </div>
    </section>

    {#if error && !showJoinModal}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}

    <div class="profile-grid" class:single={socials.length === 0}>
      <section class="card-surface participation-card">
        <div class="list-header">
          <div>
            <p class="eyebrow">Competencia</p>
            <h2>Mi participación</h2>
          </div>
          <div style="display:flex;align-items:center;gap:.5rem">
            <button class="button primary small" disabled={saving || !canManageClubes} onclick={openJoinModal}>
              <Plus size={14} strokeWidth={2} />
              Participar
            </button>
            <span class="count-pill">{data.tournaments.length}</span>
          </div>
        </div>

        {#if data.tournaments.length === 0}
          <div class="empty-state compact-empty">
            <h2>Sin torneos</h2>
            <p>El club no participa en ningun torneo actualmente.</p>
          </div>
        {:else}
          <div class="tournament-list">
            {#each data.tournaments as tournament}
              <article class="club-tournament">
                <div class="t-card-top">
                  <div class="t-card-heading">
                    <span class="t-year">{tournament.year}</span>
                    <h3>{tournament.name}</h3>
                    <p class="muted">{tournament.leagueName}</p>
                  </div>
                  {#if tournament.status && statusLabels[tournament.status]}
                    <span class={statusClasses[tournament.status] ?? 'badge-muted'}>{statusLabels[tournament.status]}</span>
                  {/if}
                </div>

                <div class="t-card-meta">
                  {#if tournament.zone}
                    <span class="chip"><MapPin size={13} strokeWidth={2} /> Zona {tournament.zone.name}</span>
                  {/if}
                  <span class="chip">{tournament.categories.length} {tournament.categories.length === 1 ? 'categoría' : 'categorías'}</span>
                </div>

                {#if tournament.categories.length > 0}
                  <div class="t-card-cats">
                    {#each tournament.categories as cat}
                      <span class="cat-chip">
                        {cat.category.name}
                        {#if cat.kickoffTime}<span class="cat-chip-time">{cat.kickoffTime}</span>{/if}
                        {#if cat.countsForGeneral}<span class="cat-chip-general">General</span>{/if}
                      </span>
                    {/each}
                  </div>
                {/if}

                <div class="t-card-actions">
                  <button
                    class="leave-btn"
                    disabled={leaving === tournament.id || !canManageClubes}
                    onclick={() => handleLeaveTournament(tournament.id)}
                  >
                    {leaving === tournament.id ? 'Saliendo...' : 'Salir del torneo'}
                  </button>
                  <a class="button primary small" href={`/standings?torneo=${tournament.id}`}>Ver torneo</a>
                </div>
              </article>
            {/each}
          </div>
        {/if}
      </section>

      {#if socials.length > 0}
        <aside class="card-surface follow-card">
          <p class="eyebrow">Redes sociales</p>
          <h2>Seguinos</h2>
          <div class="follow-list">
            {#each socials as s}
              <a class="follow-row" href={s.href} target="_blank" rel="noopener noreferrer">
                <span class="follow-icon">
                  {#if s.kind === 'facebook'}
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z"/></svg>
                  {:else if s.kind === 'instagram'}
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="20" height="20" x="2" y="2" rx="5"/><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/><line x1="17.5" x2="17.51" y1="6.5" y2="6.5"/></svg>
                  {/if}
                </span>
                <span class="follow-text">
                  <strong>{s.label}</strong>
                  {#if s.handle}<span class="muted">{s.handle}</span>{/if}
                </span>
                <ArrowUpRight size={16} strokeWidth={2} class="follow-arrow" />
              </a>
            {/each}
          </div>
        </aside>
      {/if}
    </div>

    <section class="card-surface location-card">
      <div class="location-header">
        <div>
          <p class="eyebrow">Ubicación</p>
          <h2>Dónde estamos</h2>
        </div>
        {#if mapsHref}
          <a class="button primary" href={mapsHref} target="_blank" rel="noopener noreferrer">
            <Navigation size={16} strokeWidth={2} />
            Cómo llegar
          </a>
        {/if}
      </div>

      <div class="location-body">
        {#if data.club.homeAddress || data.club.primaryColor || data.club.secondaryColor}
          <div class="location-info">
            {#if data.club.homeAddress}
              <p class="location-address">
                <MapPin size={16} strokeWidth={2} class="addr-icon" />
                <span>{data.club.homeAddress}</span>
              </p>
            {/if}
            {#if data.club.primaryColor || data.club.secondaryColor}
              <div class="location-colors">
                <span class="info-label">Colores del club</span>
                <div class="color-swatches">
                  {#if data.club.primaryColor}<span class="color-swatch" style={`background:${data.club.primaryColor}`}></span>{/if}
                  {#if data.club.secondaryColor}<span class="color-swatch" style={`background:${data.club.secondaryColor}`}></span>{/if}
                </div>
              </div>
            {/if}
          </div>
        {/if}

        {#if data.club.latitude != null && data.club.longitude != null}
          <div class="map-container" id="club-map"></div>
        {/if}
      </div>
    </section>
  {/if}
</main>

{#if showJoinModal}
  <Modal onclose={closeJoinModal}>
    <div class="modal-form" style="max-width:520px;">
      <p class="eyebrow">Participar en torneo</p>
      <h2>Agregar club a torneo</h2>
      {#if error}<p class="form-error">{error}</p>{/if}

      {#if loadingAvailable}
        <p class="muted">Cargando torneos disponibles...</p>
      {:else if availableTournaments.length === 0}
        <p class="muted">El club ya participa en todos los torneos disponibles.</p>
      {:else}
        <div class="tournament-join-list">
          {#each availableTournaments as t}
            <div class="join-row">
              <div>
                <strong>{t.name} {t.year}</strong>
                <span class="muted">{t.leagueName} · {t.categories.length} categorías</span>
              </div>
              <button class="button primary small" disabled={saving || !canManageClubes} onclick={() => handleJoin(t)}>
                {saving ? '...' : 'Participar'}
              </button>
            </div>
          {/each}
        </div>
      {/if}
    </div>
  </Modal>
{/if}

<style>
  .club-page { max-width: 1200px; margin: 0 auto; }

  /* Hero */
  .club-hero {
    position: relative;
    overflow: hidden;
    border-radius: 1.5rem;
    color: #fff;
    padding: clamp(1.75rem, 4vw, 3rem);
    background:
      radial-gradient(120% 90% at 100% 0%, color-mix(in srgb, var(--club-primary) 50%, transparent) 0%, transparent 55%),
      radial-gradient(100% 90% at 0% 100%, color-mix(in srgb, var(--club-secondary) 38%, transparent) 0%, transparent 55%),
      linear-gradient(125deg, #0c1612 0%, #172a22 100%);
    box-shadow: 0 24px 60px var(--color-shadow);
  }
  .hero-shape {
    position: absolute;
    z-index: 0;
    border-radius: 1.5rem;
    pointer-events: none;
  }
  .hero-shape-a {
    width: 420px; height: 420px; right: -130px; top: -170px;
    background: color-mix(in srgb, var(--club-primary) 45%, transparent);
    transform: rotate(28deg);
  }
  .hero-shape-b {
    width: 300px; height: 300px; left: -110px; bottom: -150px;
    background: color-mix(in srgb, var(--club-secondary) 32%, transparent);
    transform: rotate(-18deg);
  }
  .hero-stripes {
    position: absolute;
    inset: 0;
    z-index: 0;
    opacity: .28;
    background: repeating-linear-gradient(
      115deg,
      transparent 0 26px,
      color-mix(in srgb, var(--club-primary) 30%, transparent) 26px 28px,
      transparent 28px 54px,
      color-mix(in srgb, var(--club-secondary) 25%, transparent) 54px 56px,
      transparent 56px 84px
    );
    mask-image: linear-gradient(180deg, rgba(0,0,0,.9) 0%, rgba(0,0,0,.2) 60%, transparent 100%);
  }
  .hero-inner {
    position: relative;
    z-index: 2;
    display: flex;
    align-items: center;
    gap: clamp(1.25rem, 3vw, 2.25rem);
    flex-wrap: wrap;
  }
  .hero-logo {
    flex: 0 0 auto;
    width: clamp(88px, 12vw, 120px);
    height: clamp(88px, 12vw, 120px);
    display: grid;
    place-items: center;
    border-radius: 1.5rem;
    background: #fff;
    box-shadow: 0 16px 40px rgba(0,0,0,.35);
    padding: .75rem;
  }
  .hero-logo img {
    width: 100%; height: 100%;
    object-fit: contain;
    border-radius: 1rem;
  }
  .hero-logo span {
    font-family: 'Space Grotesk', sans-serif;
    font-weight: 700;
    font-size: clamp(1.8rem, 4vw, 2.6rem);
    color: var(--club-primary);
  }
  .hero-text { flex: 1 1 320px; min-width: 0; }
  .hero-kicker {
    margin: 0;
    font-size: .74rem;
    font-weight: 700;
    letter-spacing: .18em;
    text-transform: uppercase;
    color: rgba(255,255,255,.65);
  }
  .hero-text h1 {
    margin: .35rem 0 0;
    font-family: 'Space Grotesk', sans-serif;
    font-size: clamp(2rem, 5vw, 3.4rem);
    letter-spacing: -.04em;
    line-height: 1.05;
    text-wrap: balance;
  }
  .hero-short {
    margin: .4rem 0 0;
    color: rgba(255,255,255,.75);
    font-weight: 500;
    font-size: 1rem;
  }
  .hero-badges {
    display: flex;
    flex-wrap: wrap;
    gap: .45rem;
    margin-top: 1rem;
  }
  .hero-badge {
    padding: .3rem .7rem;
    border-radius: 999px;
    font-size: .78rem;
    font-weight: 600;
    color: #fff;
    background: rgba(255,255,255,.14);
    border: 1px solid rgba(255,255,255,.18);
  }
  .hero-badge.inactive {
    background: rgba(214, 74, 64, .4);
    border-color: rgba(255,255,255,.25);
  }
  .hero-socials {
    display: flex;
    gap: .5rem;
    flex-wrap: wrap;
    align-items: center;
  }
  .hero-social {
    display: inline-flex;
    align-items: center;
    gap: .45rem;
    padding: .55rem .8rem;
    border-radius: 999px;
    color: #fff;
    text-decoration: none;
    font-size: .82rem;
    font-weight: 600;
    background: rgba(255,255,255,.14);
    border: 1px solid rgba(255,255,255,.2);
    transition: background 150ms ease, transform 150ms ease;
  }
  .hero-social:hover { background: rgba(255,255,255,.24); transform: translateY(-1px); }
  .hero-social:focus-visible { outline: 2px solid #fff; outline-offset: 2px; }

  /* Grid */
  .profile-grid {
    display: grid;
    grid-template-columns: minmax(0, 1fr) minmax(0, 340px);
    gap: 1.5rem;
    margin-top: 1.5rem;
    align-items: start;
  }
  .profile-grid.single { grid-template-columns: minmax(0, 1fr); }
  .participation-card, .follow-card, .location-card { padding: 1.5rem; }
  .participation-card h2, .follow-card h2, .location-card h2 {
    margin: .35rem 0 0;
    font-family: 'Space Grotesk', sans-serif;
    letter-spacing: -.04em;
    font-size: 1.5rem;
  }

  /* Participation */
  .tournament-list { margin-top: 1.25rem; display: grid; gap: .9rem; }
  .club-tournament {
    padding: 1.25rem;
    border: 1px solid var(--color-border);
    border-radius: 1rem;
    background: var(--color-input);
  }
  .t-card-top {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 1rem;
  }
  .t-card-heading .t-year {
    font-size: .72rem;
    font-weight: 700;
    letter-spacing: .1em;
    text-transform: uppercase;
    color: var(--color-accent-text);
  }
  .t-card-heading h3 {
    margin: .25rem 0 0;
    font-family: 'Space Grotesk', sans-serif;
    font-size: 1.2rem;
    letter-spacing: -.02em;
  }
  .t-card-heading .muted { margin: .15rem 0 0; font-size: .82rem; }
  .t-card-meta { display: flex; flex-wrap: wrap; gap: .4rem; margin-top: .85rem; }
  .chip {
    display: inline-flex;
    align-items: center;
    gap: .35rem;
    padding: .25rem .6rem;
    border-radius: 999px;
    font-size: .76rem;
    font-weight: 600;
    color: var(--color-text-muted);
    background: var(--color-surface-hover);
  }
  .t-card-cats { display: flex; flex-wrap: wrap; gap: .4rem; margin-top: .85rem; }
  .cat-chip {
    display: inline-flex;
    align-items: center;
    gap: .4rem;
    padding: .3rem .6rem;
    border-radius: .5rem;
    font-size: .8rem;
    font-weight: 600;
    color: var(--color-accent-text);
    background: var(--color-accent-bg);
  }
  .cat-chip-time { font-weight: 500; opacity: .8; }
  .cat-chip-general {
    font-size: .68rem;
    font-weight: 700;
    padding: .1rem .4rem;
    border-radius: 999px;
    color: var(--color-success);
    background: var(--color-success-bg);
  }
  .t-card-actions {
    display: flex;
    align-items: center;
    gap: .75rem;
    margin-top: 1rem;
    padding-top: 1rem;
    border-top: 1px solid var(--color-border);
  }
  .t-card-actions .button.primary { margin-left: auto; }
  .leave-btn {
    border: 0;
    background: transparent;
    color: var(--color-text-muted);
    font-size: .82rem;
    font-weight: 600;
    cursor: pointer;
    padding: .5rem .6rem;
    border-radius: .5rem;
  }
  .leave-btn:hover:not(:disabled) { background: var(--color-error-bg); color: var(--color-error); }
  .leave-btn:disabled { opacity: .5; cursor: default; }

  /* Seguinos */
  .follow-list { display: grid; gap: .4rem; margin-top: 1rem; }
  .follow-row {
    display: flex;
    align-items: center;
    gap: .75rem;
    padding: .7rem .75rem;
    border-radius: .75rem;
    text-decoration: none;
    color: var(--color-text);
    transition: background 150ms ease;
  }
  .follow-row:hover { background: var(--color-surface-hover); }
  .follow-row:focus-visible { outline: 2px solid var(--color-input-focus); outline-offset: 2px; }
  .follow-icon {
    width: 2.4rem; height: 2.4rem;
    display: grid; place-items: center;
    flex: 0 0 auto;
    border-radius: .7rem;
    color: var(--color-accent-text);
    background: var(--color-accent-bg);
  }
  .follow-text { flex: 1; min-width: 0; display: grid; gap: .1rem; }
  .follow-text strong { font-size: .9rem; }
  .follow-text .muted { font-size: .78rem; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .follow-arrow { color: var(--color-text-light); flex: 0 0 auto; }

  /* Location */
  .location-card { margin-top: 1.5rem; }
  .location-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 1rem;
    flex-wrap: wrap;
  }
  .location-body { margin-top: 1.25rem; display: grid; gap: 1rem; }
  .location-address {
    display: flex;
    align-items: center;
    gap: .5rem;
    margin: 0;
    font-weight: 500;
    color: var(--color-text);
  }
  .addr-icon { color: var(--color-accent-text); flex: 0 0 auto; }
  .location-colors { margin-top: 1rem; }
  .location-colors .info-label { display: block; margin-bottom: .3rem; }
  .info-label { color: var(--color-text-muted); font-size: .78rem; font-weight: 600; text-transform: uppercase; }
  .color-swatches { display: flex; gap: .4rem; }
  .color-swatch { width: 1.5rem; height: 1.5rem; border-radius: .4rem; border: 1px solid var(--color-border); }
  .map-container {
    padding: 0;
    overflow: hidden;
    height: 260px;
    border-radius: .8rem;
    border: 1px solid var(--color-border);
    position: relative;
    z-index: 0;
  }
  .map-container :global(.leaflet-container) { width: 100%; height: 100%; border-radius: .8rem; z-index: 0; }
  .map-container :global(.leaflet-pane),
  .map-container :global(.leaflet-top),
  .map-container :global(.leaflet-bottom) { z-index: 1; }

  .button.small { padding: .4rem .7rem; font-size: .8rem; display: inline-flex; align-items: center; gap: .4rem; }

  .tournament-join-list { display: grid; gap: .5rem; margin: .5rem 0; }
  .join-row {
    display: flex; align-items: center; justify-content: space-between; gap: .75rem;
    padding: .7rem .85rem; border: 1px solid var(--color-border); border-radius: .6rem;
    background: var(--color-input);
  }
  .join-row strong { font-size: .88rem; display: block; }
  .join-row span { font-size: .75rem; }

  @media (max-width: 767px) {
    .profile-grid { grid-template-columns: 1fr; }
    .hero-inner { flex-direction: column; align-items: flex-start; }
    .hero-socials { width: 100%; }
  }
</style>
