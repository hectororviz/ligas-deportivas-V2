<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { getMatchDetail, getProfile, canManageModule, matchPosterUrl, type MatchDetail, type MatchClub, type AuthUser } from '$lib/api';
  import PlayerGoalsModal from '$lib/PlayerGoalsModal.svelte';

  let match: MatchDetail | null = $state(null);
  let loading = $state(true);
  let error = $state('');
  let user: AuthUser | null = $state(null);

  let openCategory: { tournamentCategoryId: number; categoryName: string } | null = $state(null);

  let canManage = $derived(canManageModule(user, 'TORNEOS') || canManageModule(user, 'ZONAS'));
  let hasScores = $derived.by(() => match?.categories.some((c) => c.closedAt) ?? false);

  let backHref = $derived.by(() => {
    const zona = $page.url.searchParams.get('zona');
    const fecha = $page.url.searchParams.get('fecha');
    const params = new URLSearchParams();
    if (zona) params.set('zona', zona);
    if (fecha) params.set('fecha', fecha);
    return `/fixtures${params.toString() ? `?${params}` : ''}`;
  });

  onMount(async () => {
    try {
      const id = Number($page.params.matchId);
      const [m, u] = await Promise.all([getMatchDetail(id), getProfile().catch(() => null)]);
      match = m;
      user = u;
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo cargar el partido.';
    } finally {
      loading = false;
    }
  });

  function initials(club: MatchClub | null): string {
    if (!club) return '??';
    const name = club.shortName || club.name;
    return name.slice(0, 2).toUpperCase();
  }

  function homeOutcome(cat: MatchDetail['categories'][number]): string {
    if (cat.isPending) return 'pendiente';
    if (!cat.closedAt) return 'pending';
    if (cat.homeScore > cat.awayScore) return 'win';
    if (cat.homeScore < cat.awayScore) return 'loss';
    return 'draw';
  }

  function awayOutcome(cat: MatchDetail['categories'][number]): string {
    if (cat.isPending) return 'pendiente';
    if (!cat.closedAt) return 'pending';
    if (cat.awayScore > cat.homeScore) return 'win';
    if (cat.awayScore < cat.homeScore) return 'loss';
    return 'draw';
  }

  function scoreLabel(cat: MatchDetail['categories'][number], side: 'home' | 'away'): string {
    if (cat.isPending) return 'Pendiente';
    if (!cat.closedAt) return '–';
    return String(side === 'home' ? cat.homeScore : cat.awayScore);
  }

  function pointsLabel(points: number): string {
    if (!hasScores) return '—';
    return points === 1 ? '1 pt' : `${points} pts`;
  }

  function openGoals(cat: MatchDetail['categories'][number]) {
    openCategory = { tournamentCategoryId: cat.tournamentCategoryId, categoryName: cat.categoryName };
  }

  async function refresh() {
    if (!match) return;
    try {
      match = await getMatchDetail(match.id);
    } catch {}
  }
</script>

<svelte:head><title>Partido | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  {#if loading}
    <section class="loading-card">Cargando partido...</section>
  {:else if error}
    <header class="page-header"><div><p class="eyebrow">Partido</p><h1>Error</h1></div></header>
    <p class="error-banner">{error}</p>
    <a class="button secondary" href={backHref}>Volver al fixture</a>
  {:else if match}
    <header class="page-header">
      <div>
        <p class="eyebrow">Partido · Fecha {match.matchday}{match.round === 'SECOND' ? ' · Rueda 2' : ''}</p>
        <h1 class="page-title">Resultado</h1>
      </div>
      <div class="header-actions">
        <a class="button secondary" href={backHref}>Volver al fixture</a>
      </div>
    </header>

    <div class="versus">
      <div class="club-block">
        <div class="crest" class:has-logo={!!match.homeClub?.logoUrl} style={match.homeClub?.primaryColor ? `--club-color: ${match.homeClub.primaryColor}` : ''}>
          {#if match.homeClub?.logoUrl}
            <img src={match.homeClub.logoUrl} alt={match.homeClub.name} />
          {:else}
            <span>{initials(match.homeClub)}</span>
          {/if}
        </div>
        <strong class="club-name">{match.homeClub?.name ?? '—'}</strong>
        <span class="points">{pointsLabel(match.pointsHome)}</span>
      </div>

      <span class="vs">VS</span>

      <div class="club-block">
        <div class="crest" class:has-logo={!!match.awayClub?.logoUrl} style={match.awayClub?.primaryColor ? `--club-color: ${match.awayClub.primaryColor}` : ''}>
          {#if match.awayClub?.logoUrl}
            <img src={match.awayClub.logoUrl} alt={match.awayClub.name} />
          {:else}
            <span>{initials(match.awayClub)}</span>
          {/if}
        </div>
        <strong class="club-name">{match.awayClub?.name ?? '—'}</strong>
        <span class="points">{pointsLabel(match.pointsAway)}</span>
      </div>

      <div class="versus-actions">
        <a class="button secondary" href={matchPosterUrl(match.id)} target="_blank" rel="noopener">Flyer</a>
        <button class="button secondary" disabled>Listado</button>
      </div>
    </div>

    {#if match.categories.length === 0}
      <div class="empty-state">
        <div class="empty-icon">🏟</div>
        <h2>Sin categorías</h2>
        <p class="muted">Este partido no tiene categorías cargadas.</p>
      </div>
    {:else}
      <div class="card-surface table-card">
        <table class="score-table">
          <thead>
            <tr>
              <th>Categoría</th>
              <th class="num">Goles local</th>
              <th class="num">Goles visitante</th>
            </tr>
          </thead>
          <tbody>
            {#each match.categories as cat}
              <tr class="clickable" onclick={() => openGoals(cat)} onkeydown={(e) => e.key === 'Enter' && openGoals(cat)} role="button" tabindex="0">
                <td class="cat-name">
                  {cat.categoryName}
                  {#if cat.countsForGeneral}<span class="tag tag-green" title="Cuenta para la tabla general">General</span>{/if}
                  {#if cat.isPromocional}<span class="tag tag-amber">Promocional</span>{/if}
                </td>
                <td class="num"><span class="score-cell {homeOutcome(cat)}">{scoreLabel(cat, 'home')}</span></td>
                <td class="num"><span class="score-cell {awayOutcome(cat)}">{scoreLabel(cat, 'away')}</span></td>
              </tr>
            {/each}
          </tbody>
        </table>
      </div>
    {/if}
  {/if}
</main>

{#if match && openCategory}
  <PlayerGoalsModal
    matchId={match.id}
    tournamentCategoryId={openCategory.tournamentCategoryId}
    categoryName={openCategory.categoryName}
    homeClub={match.homeClub}
    awayClub={match.awayClub}
    controlsPlayers={match.tournament.controlsPlayers}
    canEdit={canManage}
    onclose={() => openCategory = null}
    onsaved={refresh}
  />
{/if}

<style>
  .page-title { font-size: clamp(2rem, 5vw, 3.5rem); }

  .header-actions { display: flex; gap: .5rem; align-items: center; flex-wrap: wrap; }

  .versus {
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: clamp(1rem, 4vw, 3rem);
    padding: 1.5rem;
    border: 1px solid var(--color-border);
    border-radius: 1.2rem;
    background: var(--color-surface);
    box-shadow: 0 16px 45px var(--color-shadow);
  }
  .versus-actions {
    position: absolute;
    top: 1rem;
    right: 1rem;
    display: flex;
    flex-direction: column;
    align-items: stretch;
    gap: .5rem;
  }
  .club-block {
    flex: 1;
    max-width: 220px;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: .5rem;
    text-align: center;
    min-width: 0;
  }
  .crest {
    width: 4rem;
    height: 4rem;
    display: grid;
    place-items: center;
    border-radius: 50%;
    overflow: hidden;
    color: #fff;
    background: var(--club-color, var(--color-accent));
    font-family: 'Space Grotesk', sans-serif;
    font-weight: 700;
    font-size: 1.1rem;
  }
  .crest.has-logo { background: transparent; border-radius: 0; }
  .crest img { width: 100%; height: 100%; object-fit: contain; }
  .club-name {
    font-family: 'Space Grotesk', sans-serif;
    font-size: 1.05rem;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    max-width: 100%;
  }
  .points { color: var(--color-text-muted); font-size: .9rem; font-weight: 600; }
  .vs {
    font-family: 'Space Grotesk', sans-serif;
    font-size: 1.4rem;
    font-weight: 700;
    color: var(--color-text-light);
  }

  .table-card { padding: 0; overflow: hidden; margin-top: 1.5rem; }
  .score-table { width: 100%; border-collapse: collapse; font-size: .9rem; }
  .score-table th, .score-table td { padding: .8rem 1rem; border-bottom: 1px solid var(--color-border); text-align: left; vertical-align: middle; }
  .score-table th { color: var(--color-text-muted); font-size: .75rem; text-transform: uppercase; letter-spacing: .06em; }
  .score-table tbody tr:last-child td { border-bottom: 0; }
  .score-table tr.clickable { cursor: pointer; }
  .score-table tr.clickable:hover { background: var(--color-surface-hover); }
  .score-table .num { text-align: center; }
  .cat-name { font-weight: 600; }
  .cat-name .tag { display: inline-block; margin-left: .4rem; vertical-align: middle; }

  .score-cell {
    display: inline-block;
    min-width: 2.4rem;
    padding: .3rem .6rem;
    border-radius: .5rem;
    font-family: 'Space Grotesk', sans-serif;
    font-weight: 700;
    font-size: 1rem;
  }
  .score-cell.win { color: #2e7d32; background: #e8f5e9; }
  .score-cell.draw { color: #f9a825; background: #fff8e1; }
  .score-cell.loss { color: #c62828; background: #ffebee; }
  .score-cell.pending { color: var(--color-text-light); background: var(--color-surface-hover); }
  .score-cell.pendiente { color: #6d4c41; background: #f1e0d6; font-size: .72rem; font-weight: 600; }

  @media (max-width: 560px) {
    .versus { flex-direction: row; gap: .75rem; padding: 1rem; }
    .club-block { max-width: 40%; }
    .crest { width: 3.25rem; height: 3.25rem; }
    .club-name { font-size: .9rem; }
  }
</style>
