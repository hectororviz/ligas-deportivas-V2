<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { getClubAdmin, getAvailableTournaments, joinTournament, leaveTournament, getProfile, canManageModule, getClubUpcomingEvents, type ClubAdminOverview, type ClubAdminTournament, type AvailableTournament, type AuthUser, type ClubUpcomingEvent } from '$lib/api';
  import Modal from '$lib/Modal.svelte';
  import { Plus, MapPin, ArrowUpRight, Calendar } from '@lucide/svelte';
  import CrossTable from '$lib/CrossTable.svelte';

  const statusLabels: Record<string, string> = {
    DRAFT: 'Borrador', ACTIVE: 'Activo', FINISHED: 'Finalizado', CANCELLED: 'Cancelado'
  };
  const statusClasses: Record<string, string> = {
    DRAFT: 'badge-muted', ACTIVE: 'badge-active', FINISHED: 'badge-finished', CANCELLED: 'badge-cancelled'
  };
  const MONTHS = ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'];

  let data: ClubAdminOverview | null = $state(null);
  let events: ClubUpcomingEvent[] = $state([]);
  let user = $state<AuthUser | null>(null);
  let loading = $state(true);
  let error = $state('');
  let notice = $state('');
  let saving = $state(false);
  let leaving: number | null = $state(null);

  let showJoinModal = $state(false);
  let availableTournaments = $state<AvailableTournament[]>([]);
  let loadingAvailable = $state(false);

  let showCrosses = $state(false);
  let crossesTournament: ClubAdminTournament | null = $state(null);

  function openCrosses(tournament: ClubAdminTournament) {
    if (!tournament.zone) return;
    crossesTournament = tournament;
    showCrosses = true;
  }

  function closeCrosses() {
    showCrosses = false;
    crossesTournament = null;
  }

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

  function eventDay(date: string | null): string {
    if (!date) return '—';
    const d = new Date(date);
    if (isNaN(d.getTime())) return '—';
    return String(d.getUTCDate());
  }

  function eventMonth(date: string | null): string {
    if (!date) return '';
    const d = new Date(date);
    if (isNaN(d.getTime())) return '';
    return MONTHS[d.getUTCMonth()] ?? '';
  }

  function eventDetail(ev: ClubUpcomingEvent): string {
    const parts: string[] = [];
    if (ev.leagueName && ev.leagueName !== '—') parts.push(ev.leagueName);
    parts.push(`Zona ${ev.zoneName}`);
    if (ev.kickoffTime) parts.push(ev.kickoffTime);
    return parts.join(' · ');
  }

  onMount(async () => {
    await fetchData();
    if (data) await loadEvents();
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

  async function loadEvents() {
    if (!data) return;
    try {
      events = await getClubUpcomingEvents(data.club.id);
    } catch { events = []; }
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
      style={`--club-primary: ${data.club.primaryColor || '#759b51'}; --club-secondary: ${data.club.secondaryColor || '#38622e'};`}
    >
      <div class="hero-layer hero-dots"></div>
      <div class="hero-layer hero-lines"></div>
      <div class="hero-layer hero-wedge"></div>
      <div class="hero-layer hero-accent"></div>
      <div class="hero-layer hero-light"></div>
      <div class="hero-layer hero-shadow"></div>

      <span class="hero-status" class:inactive={!data.club.active}>{data.club.active ? 'Activo' : 'Inactivo'}</span>

      <div class="hero-inner">
        <div class="hero-logo">
          {#if data.club.logoUrl}
            <img src={data.club.logoUrl} alt={`Escudo de ${data.club.name}`} />
          {:else}
            <span>{initials(data)}</span>
          {/if}
        </div>

        <div class="hero-text">
          <h1>{data.club.name}</h1>
          {#if data.club.shortName && data.club.shortName !== data.club.name}
            <h2>{data.club.shortName}</h2>
          {/if}
          {#if data.club.description}
            <p class="hero-tagline">{data.club.description}</p>
          {/if}
          <div class="hero-badges">
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

    <div class="club-layout">
      <div class="club-main">
        <section class="card-surface">
          <div class="section-title-row">
            <div>
              <p class="eyebrow">Competencia</p>
              <h2>Mi participación</h2>
            </div>
            <div class="title-actions">
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
                <article class="tournament-card">
                  <div class="t-head">
                    <div class="t-title">
                      <span class="t-year">{tournament.year}</span>
                      <h3>{tournament.leagueName} - {tournament.name}</h3>
                      {#if tournament.zone}
                        <span class="t-zone">Zona: {tournament.zone.name}</span>
                      {/if}
                    </div>
                    <div class="t-actions">
                      {#if tournament.status && statusLabels[tournament.status]}
                        <span class="t-status {statusClasses[tournament.status] ?? 'badge-muted'}">{statusLabels[tournament.status]}</span>
                      {/if}
                    </div>
                  </div>

                  {#if canManageClubes}
                    <div class="t-foot">
                      <button class="t-btn" onclick={() => openCrosses(tournament)}>Cruces</button>
                      <a class="t-btn" href={`/standings?club=${data.club.id}`}>Tabla</a>
                      <a class="t-btn" href={`/fixtures?club=${data.club.id}`}>Fixture</a>
                      {#if user?.isAdmin}
                        <button
                          class="t-btn t-btn-danger"
                          disabled={!tournament.canLeave || leaving === tournament.id}
                          onclick={() => handleLeaveTournament(tournament.id)}
                        >
                          {leaving === tournament.id ? 'Saliendo...' : 'Salir del torneo'}
                        </button>
                      {/if}
                    </div>
                  {/if}
                </article>
              {/each}
            </div>
          {/if}
        </section>

        <section class="card-surface location-card">
          <div class="section-title-row">
            <div>
              <p class="eyebrow">Ubicación</p>
              <h2 class="icon-title"><MapPin size={20} strokeWidth={2} class="icon-accent" /> Dónde estamos</h2>
            </div>
            {#if mapsHref}
              <a class="button secondary outline" href={mapsHref} target="_blank" rel="noopener noreferrer">
                Cómo llegar
                <ArrowUpRight size={15} strokeWidth={2} />
              </a>
            {/if}
          </div>

          <div class="location-grid">
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
                  <div class="color-dots">
                    {#if data.club.primaryColor}<span class="color-dot" style={`background:${data.club.primaryColor}`}></span>{/if}
                    {#if data.club.secondaryColor}<span class="color-dot" style={`background:${data.club.secondaryColor}`}></span>{/if}
                  </div>
                </div>
              {/if}
            </div>

            {#if data.club.latitude != null && data.club.longitude != null}
              <div class="map-container" id="club-map"></div>
            {/if}
          </div>
        </section>
      </div>

      <div class="club-side">
        {#if socials.length > 0}
          <aside class="card-surface">
            <div class="section-title-row">
              <div>
                <p class="eyebrow">Redes</p>
                <h2>Seguinos</h2>
              </div>
            </div>
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
                  <span class="follow-arrow">></span>
                </a>
              {/each}
            </div>
          </aside>
        {/if}

        <aside class="card-surface">
          <div class="section-title-row">
            <div>
              <p class="eyebrow">Agenda</p>
              <h2 class="icon-title"><Calendar size={20} strokeWidth={2} class="icon-accent" /> Próximos eventos</h2>
            </div>
          </div>

          {#if events.length > 0}
            <div class="event-list">
              {#each events as ev}
                <a class="event-row" href={`/fixtures?torneo=${ev.tournamentId}&zona=${ev.zoneId}&fecha=${ev.matchday}`}>
                  <div class="event-date">
                    <strong>{eventDay(ev.date)}</strong>
                    {#if eventMonth(ev.date)}<span>{eventMonth(ev.date)}</span>{/if}
                  </div>
                  <div class="event-info">
                    <strong>{ev.tournamentName}</strong>
                    <span class="muted">{eventDetail(ev)}</span>
                  </div>
                </a>
              {/each}
            </div>
          {:else}
            <p class="muted">Sin próximos eventos.</p>
          {/if}
        </aside>
      </div>
    </div>
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

{#if showCrosses && crossesTournament?.zone && data}
  <Modal onclose={closeCrosses} wide>
    <div class="modal-form cross-modal">
      <CrossTable zoneId={crossesTournament.zone.id} clubId={data.club.id} />
    </div>
  </Modal>
{/if}

<style>
  .club-page { max-width: 1200px; margin: 0 auto; }

  /* ===== Hero ===== */
  .club-hero {
    position: relative;
    overflow: hidden;
    border-radius: 1.5rem;
    color: #fff;
    padding: clamp(1.75rem, 4vw, 3rem);
    background-color: var(--club-primary);
    box-shadow: 0 24px 60px var(--color-shadow);
  }

  /* Capas geométricas */
  .hero-layer { position: absolute; pointer-events: none; }

  .hero-dots {
    inset: 0;
    z-index: 0;
    background-image: radial-gradient(rgba(255,255,255,0.08) 1px, transparent 1px);
    background-size: 18px 18px;
  }
  .hero-lines {
    inset: 0;
    z-index: 0;
    background-image: repeating-linear-gradient(45deg, rgba(255,255,255,0.05) 0 1px, transparent 1px 14px);
  }
  .hero-wedge {
    top: -80%;
    right: -10%;
    width: 60%;
    height: 250%;
    transform: skewX(-25deg);
    z-index: 1;
    background: linear-gradient(135deg, transparent 40%, var(--club-secondary) 100%);
    opacity: 0.4;
  }
  .hero-accent {
    bottom: -40%;
    left: -10%;
    width: 40%;
    height: 80%;
    transform: rotate(15deg) skewX(-15deg);
    border-radius: 60px;
    z-index: 1;
    background: var(--club-secondary);
    opacity: 0.15;
  }
  .hero-light {
    top: -40%;
    left: -15%;
    width: 40%;
    height: 120%;
    transform: rotate(45deg);
    z-index: 1;
    background: rgba(255,255,255,0.15);
  }
  .hero-shadow {
    bottom: 0;
    left: 0;
    right: 0;
    height: 45%;
    z-index: 1;
    background: linear-gradient(to top, rgba(0,0,0,0.15), transparent);
  }

  .hero-status {
    position: absolute;
    top: 1rem;
    right: 1rem;
    z-index: 10;
    padding: .35rem .85rem;
    border-radius: 999px;
    background: var(--color-success);
    color: #fff;
    font-size: .78rem;
    font-weight: 700;
  }
  .hero-status.inactive { background: var(--color-error); }
  .hero-inner {
    position: relative;
    z-index: 10;
    display: flex;
    align-items: center;
    gap: clamp(1.25rem, 3vw, 2.25rem);
    flex-wrap: wrap;
  }
  .hero-logo {
    flex: 0 0 auto;
    width: clamp(148px, 19.5vw, 203px);
    height: clamp(148px, 19.5vw, 203px);
    display: grid;
    place-items: center;
  }
  .hero-logo img { width: 100%; height: 100%; object-fit: contain; filter: drop-shadow(0 12px 24px rgba(0,0,0,.45)); }
  .hero-logo span {
    font-family: 'Space Grotesk', sans-serif;
    font-weight: 700;
    font-size: clamp(2.3rem, 5vw, 3.3rem);
    color: var(--club-primary);
  }
  .hero-text { flex: 1 1 320px; min-width: 0; }
  .hero-text h1 {
    margin: 0;
    font-family: 'Space Grotesk', sans-serif;
    font-size: clamp(2rem, 5vw, 3.2rem);
    letter-spacing: -.04em;
    line-height: 1.05;
    text-wrap: balance;
    text-shadow: 0 2px 10px rgba(0,0,0,0.3);
  }
  .hero-text h2 {
    margin: .4rem 0 0;
    font-size: 1rem;
    font-weight: 500;
    color: rgba(255,255,255,.85);
    text-shadow: 0 1px 6px rgba(0,0,0,0.3);
  }
  .hero-tagline {
    margin: .6rem 0 0;
    color: rgba(255,255,255,.9);
    line-height: 1.5;
    max-width: 46ch;
    text-shadow: 0 1px 6px rgba(0,0,0,0.3);
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
    background: rgba(255,255,255,0.1);
    border: 1px solid rgba(255,255,255,0.3);
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
    padding: .55rem .85rem;
    border-radius: 999px;
    color: #fff;
    text-decoration: none;
    font-size: .82rem;
    font-weight: 600;
    background: transparent;
    border: 1px solid rgba(255,255,255,0.55);
    transition: background 150ms ease, transform 150ms ease;
  }
  .hero-social:hover { background: rgba(255,255,255,0.18); transform: translateY(-1px); }
  .hero-social:focus-visible { outline: 2px solid #fff; outline-offset: 2px; }

  /* ===== Layout ===== */
  .club-layout {
    display: grid;
    grid-template-columns: minmax(0, 7fr) minmax(0, 3fr);
    gap: 1.5rem;
    margin-top: 1.5rem;
    align-items: start;
  }
  .club-main { display: grid; gap: 1.5rem; min-width: 0; }
  .club-side { display: grid; gap: 1.5rem; min-width: 0; }
  .club-layout .card-surface { padding: 1.5rem; }

  .section-title-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
    flex-wrap: wrap;
  }
  .section-title-row h2 {
    margin: .35rem 0 0;
    font-family: 'Space Grotesk', sans-serif;
    letter-spacing: -.04em;
    font-size: 1.5rem;
  }
  .section-title-row h2.icon-title { display: inline-flex; align-items: center; gap: .5rem; }
  .icon-accent { color: var(--color-accent-text); }
  .title-actions { display: flex; align-items: center; gap: .5rem; }

  /* ===== Participación ===== */
  .tournament-list { margin-top: 1.25rem; display: grid; gap: .9rem; }
  .tournament-card {
    padding: 1.25rem;
    border: 1px solid var(--color-border);
    border-radius: 1rem;
    background: var(--color-input);
  }
  .t-head { display: flex; justify-content: space-between; align-items: flex-start; gap: 1rem; }
  .t-title { min-width: 0; }
  .t-title .t-year {
    font-size: .78rem;
    font-weight: 600;
    color: var(--color-text-muted);
  }
  .t-title h3 {
    margin: .2rem 0 0;
    font-family: 'Space Grotesk', sans-serif;
    font-size: 1.25rem;
    letter-spacing: -.02em;
    overflow-wrap: break-word;
  }
  .t-title .t-zone { display: block; margin-top: .3rem; font-size: .84rem; color: var(--color-text-muted); }
  .t-actions { display: flex; align-items: center; gap: .6rem; flex: 0 0 auto; }

  .t-status {
    padding: .25rem .75rem;
    border-radius: 999px;
    font-size: .72rem;
    font-weight: 700;
    white-space: nowrap;
  }
  .t-foot { margin-top: 1rem; display: flex; flex-wrap: wrap; gap: .5rem; }
  .t-btn {
    padding: .45rem .8rem;
    border-radius: .6rem;
    border: 1px solid var(--color-border);
    background: var(--color-surface);
    color: var(--color-text);
    font-size: .82rem;
    font-weight: 600;
    cursor: pointer;
    text-decoration: none;
    display: inline-flex;
    align-items: center;
    gap: .4rem;
  }
  .t-btn:hover { background: var(--color-surface-hover); }
  .t-btn:disabled { opacity: .45; cursor: default; }
  .t-btn-danger { color: var(--color-error); }
  .t-btn-danger:hover:not(:disabled) { background: var(--color-error-bg); }
  .cross-modal { max-width: 960px; width: 100%; margin: 0 auto; }

  /* ===== Ubicación ===== */
  .location-grid {
    margin-top: 1.25rem;
    display: grid;
    grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
    gap: 1.25rem;
    align-items: center;
  }
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
  .location-colors .info-label { display: block; margin-bottom: .4rem; }
  .info-label { color: var(--color-text-muted); font-size: .78rem; font-weight: 600; text-transform: uppercase; }
  .color-dots { display: flex; gap: .5rem; }
  .color-dot { width: 1.75rem; height: 1.75rem; border-radius: 50%; border: 1px solid var(--color-border); }

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

  .button.outline {
    border: 1px solid var(--color-border);
    background: transparent;
    color: var(--color-text);
    display: inline-flex;
    align-items: center;
    gap: .4rem;
  }
  .button.outline:hover { background: var(--color-surface-hover); }

  /* ===== Seguinos ===== */
  .follow-list { margin-top: 1rem; }
  .follow-row {
    display: flex;
    align-items: center;
    gap: .75rem;
    padding: .8rem 0;
    border-bottom: 1px solid var(--color-border);
    text-decoration: none;
    color: var(--color-text);
    transition: opacity 150ms ease;
  }
  .follow-row:first-child { padding-top: .4rem; }
  .follow-row:last-child { border-bottom: 0; padding-bottom: .4rem; }
  .follow-row:hover { opacity: .75; }
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
  .follow-arrow { color: var(--color-text-light); font-weight: 700; flex: 0 0 auto; }

  /* ===== Eventos ===== */
  .event-list { margin-top: 1rem; }
  .event-row {
    display: flex;
    align-items: center;
    gap: .9rem;
    padding: .7rem 0;
    border-bottom: 1px solid var(--color-border);
    text-decoration: none;
    color: var(--color-text);
    transition: opacity 150ms ease;
  }
  .event-row:hover { opacity: .7; }
  .event-row:first-child { padding-top: .3rem; }
  .event-row:last-child { border-bottom: 0; }
  .event-date {
    width: 3rem; height: 3rem;
    border-radius: .9rem;
    background: var(--color-accent-bg);
    color: var(--color-accent-text);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    flex: 0 0 auto;
  }
  .event-date strong { font-size: 1.1rem; line-height: 1; font-family: 'Space Grotesk', sans-serif; }
  .event-date span { font-size: .62rem; font-weight: 700; letter-spacing: .06em; }
  .event-info { min-width: 0; display: grid; gap: .15rem; }
  .event-info strong { font-size: .9rem; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .event-info .muted { font-size: .78rem; }

  .button.small { padding: .4rem .7rem; font-size: .8rem; display: inline-flex; align-items: center; gap: .4rem; }

  .tournament-join-list { display: grid; gap: .5rem; margin: .5rem 0; }
  .join-row {
    display: flex; align-items: center; justify-content: space-between; gap: .75rem;
    padding: .7rem .85rem; border: 1px solid var(--color-border); border-radius: .6rem;
    background: var(--color-input);
  }
  .join-row strong { font-size: .88rem; display: block; }
  .join-row span { font-size: .75rem; }

  @media (max-width: 900px) {
    .club-layout { grid-template-columns: 1fr; }
  }
  @media (max-width: 767px) {
    .hero-inner { flex-direction: column; align-items: flex-start; }
    .hero-socials { width: 100%; }
    .location-grid { grid-template-columns: 1fr; }
  }
</style>
