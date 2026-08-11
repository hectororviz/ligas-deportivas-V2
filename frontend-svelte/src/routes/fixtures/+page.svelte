<script lang="ts">
  import { onMount } from 'svelte';
  import { getZones, getZoneMatches, recordMatchResult, finalizeMatchday, type Zone, type ZoneMatchesResponse, type ZoneMatch } from '$lib/api';
  import { goto } from '$app/navigation';

  let zones: Zone[] = $state([]);
  let selectedZoneId = $state<number | null>(null);
  let matchesData = $state<ZoneMatchesResponse | null>(null);
  let loading = $state(true);
  let saving = $state(false);
  let error = $state('');
  let notice = $state('');
  let expandedMatch = $state<number | null>(null);
  let showSidebar = $state(false);

  onMount(async () => {
    try {
      zones = await getZones(true);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'Error al cargar zonas.';
    } finally {
      loading = false;
    }
  });

  async function loadMatches(zoneId: number) {
    selectedZoneId = zoneId;
    loading = true; error = '';
    try {
      matchesData = await getZoneMatches(zoneId);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'Error al cargar partidos.';
      matchesData = null;
    } finally {
      loading = false;
    }
  }

  async function saveResult(match: ZoneMatch, cat: { tournamentCategoryId: number; categoryName: string; homeGoals: number | null; awayGoals: number | null }) {
    const homeInput = document.getElementById(`home-${match.matchId}-${cat.tournamentCategoryId}`) as HTMLInputElement;
    const awayInput = document.getElementById(`away-${match.matchId}-${cat.tournamentCategoryId}`) as HTMLInputElement;
    const hg = parseInt(homeInput?.value || '');
    const ag = parseInt(awayInput?.value || '');
    if (isNaN(hg) || isNaN(ag)) { error = 'Ingresá ambos resultados.'; return; }

    saving = true; error = ''; notice = '';
    try {
      await recordMatchResult(match.matchId, cat.tournamentCategoryId, { homeGoals: hg, awayGoals: ag });
      notice = `Resultado ${match.homeClubName} ${hg}-${ag} ${match.awayClubName} guardado.`;
      if (matchesData) matchesData = await getZoneMatches(selectedZoneId!);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'Error al guardar el resultado.';
    } finally {
      saving = false;
      setTimeout(() => notice = '', 3000);
    }
  }

  async function handleFinalize(matchday: number) {
    if (!confirm(`¿Finalizar fecha ${matchday}? No se podrá modificar después.`)) return;
    saving = true; error = '';
    try {
      await finalizeMatchday(selectedZoneId!, matchday);
      notice = `Fecha ${matchday} finalizada.`;
      matchesData = await getZoneMatches(selectedZoneId!);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'Error al finalizar la fecha.';
    } finally {
      saving = false;
    }
  }

  function matchStatusBadge(status: string) {
    const map: Record<string, string> = { PENDING: 'badge-muted', PLAYED: 'badge-finished', CANCELLED: 'badge-cancelled' };
    return map[status] || 'badge-muted';
  }

  function resultClass(cat: { homeGoals: number | null; awayGoals: number | null }, match: ZoneMatch): string {
    if (cat.homeGoals === null || cat.awayGoals === null) return '';
    if (cat.homeGoals > cat.awayGoals) return 'winner-home';
    if (cat.homeGoals < cat.awayGoals) return 'winner-away';
    return 'draw';
  }
</script>

<svelte:head><title>Fixture | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header" class:with-sidebar={showSidebar}>
    <div><p class="eyebrow">Competencia</p><h1>Fixture</h1><p class="muted">Consultá y cargá los resultados de los partidos.</p></div>
    {#if zones.length > 0}
      <button class="button secondary" onclick={() => showSidebar = !showSidebar} aria-label="Seleccionar zona">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect width="18" height="18" x="3" y="3" rx="2"/><path d="M3 9h18M9 3v18"/></svg>
        {selectedZoneId ? zones.find(z => z.id === selectedZoneId)?.name || 'Zona' : 'Elegir zona'}
      </button>
    {/if}
  </header>

  {#if loading && !matchesData}
    <section class="loading-card">Cargando fixture...</section>
  {:else}
    {#if error}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}

    <div class="fixture-layout" class:show-sidebar={showSidebar}>
      <aside class="zone-sidebar" class:open={showSidebar}>
        <div class="zone-sidebar-header">
          <h3>Zonas</h3>
          <button class="icon-button" onclick={() => showSidebar = !showSidebar} aria-label="Cerrar">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" x2="6" y1="6" y2="18"/><line x1="6" x2="18" y1="6" y2="18"/></svg>
          </button>
        </div>
        <div class="zone-list">
          {#each zones as zone}
            <button class="zone-item" class:selected={selectedZoneId === zone.id} onclick={() => { loadMatches(zone.id); showSidebar = false; }}>
              <div><strong>{zone.name}</strong><span class="muted">{zone.tournament.league.name} · {zone.tournament.name}</span></div>
            </button>
          {/each}
        </div>
      </aside>

      <div class="fixture-main">
        {#if !selectedZoneId}
          <div class="empty-state"><h2>Seleccioná una zona</h2><p>Elegí una zona para ver sus partidos y cargar resultados.</p></div>
        {:else if matchesData && matchesData.matches.length === 0}
          <div class="empty-state"><h2>Sin partidos</h2><p>Generá el fixture desde la sección Zonas.</p></div>
        {:else if matchesData}
          <div class="matchdays">
            {#each matchesData.matchdays as md}
              <section class="matchday-card">
                <div class="matchday-header">
                  <h3>Fecha {md.matchday}</h3>
                  <div class="matchday-meta">
                    {#if md.date}<span class="badge-muted">{new Date(md.date).toLocaleDateString('es-AR')}</span>{/if}
                    <span class={md.status === 'FINALIZED' ? 'badge-finished' : 'badge-muted'}>{md.status === 'FINALIZED' ? 'Cerrada' : 'Abierta'}</span>
                  </div>
                  {#if md.finalizable}
                    <button class="button secondary small" disabled={saving} onclick={() => handleFinalize(md.matchday)}>Finalizar fecha</button>
                  {/if}
                </div>

                <div class="match-list">
                  {#each matchesData.matches.filter(m => m.matchday === md.matchday) as match}
                    <div class="match-card" class:expanded={expandedMatch === match.matchId} class:played={match.status !== 'PENDING'}>
                      <button class="match-header" onclick={() => expandedMatch = expandedMatch === match.matchId ? null : match.matchId} aria-label={expandedMatch === match.matchId ? 'Colapsar' : 'Expandir'}>
                        <div class="match-teams">
                          <span class="team home" class:winner={expandedMatch === match.matchId && match.categories.some(c => (c.homeGoals ?? 0) > (c.awayGoals ?? 0))}>{match.homeClubName}</span>
                          <span class="vs">vs</span>
                          <span class="team away" class:winner={expandedMatch === match.matchId && match.categories.some(c => (c.awayGoals ?? 0) > (c.homeGoals ?? 0))}>{match.awayClubName}</span>
                        </div>
                        <span class={matchStatusBadge(match.status)}>{match.status === 'PENDING' ? 'Pendiente' : match.status === 'PLAYED' ? 'Jugado' : 'Cancelado'}</span>
                        <svg class="chevron" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
                      </button>

                      {#if expandedMatch === match.matchId}
                        <div class="match-detail">
                          {#each match.categories as cat}
                            <div class="category-result">
                              <span class="cat-name">{cat.categoryName}</span>
                              {#if cat.homeGoals !== null && cat.awayGoals !== null}
                                <span class="result-num {resultClass(cat, match)}">{cat.homeGoals} - {cat.awayGoals}</span>
                              {:else}
                                <div class="result-input">
                                  <input type="number" id="home-{match.matchId}-{cat.tournamentCategoryId}" min="0" class="score-input" placeholder="0" disabled={saving || md.status === 'FINALIZED'} />
                                  <span>-</span>
                                  <input type="number" id="away-{match.matchId}-{cat.tournamentCategoryId}" min="0" class="score-input" placeholder="0" disabled={saving || md.status === 'FINALIZED'} />
                                  <button class="button primary small" disabled={saving || md.status === 'FINALIZED'} onclick={() => saveResult(match, cat)}>Guardar</button>
                                </div>
                              {/if}
                            </div>
                          {/each}
                        </div>
                      {/if}
                    </div>
                  {/each}
                </div>
              </section>
            {/each}
          </div>
        {/if}
      </div>
    </div>
  {/if}
</main>

<style>
  .fixture-layout { display: grid; grid-template-columns: 280px 1fr; gap: 1.5rem; align-items: start; }
  .fixture-layout:not(.show-sidebar) { grid-template-columns: 1fr; }
  .zone-sidebar { display: none; }
  .zone-sidebar.open { display: block; }
  .fixture-layout.show-sidebar .zone-sidebar { display: block; }
  .zone-sidebar-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: .75rem; }
  .zone-sidebar-header h3 { margin: 0; font-family: 'Space Grotesk', sans-serif; font-size: 1rem; }
  .zone-list { display: grid; gap: .35rem; }
  .zone-item {
    display: grid; gap: .15rem; padding: .7rem .85rem; border: 1px solid var(--color-border);
    border-radius: .6rem; background: var(--color-surface); cursor: pointer; text-align: left;
    transition: background 150ms ease, border-color 150ms ease; font-family: inherit;
  }
  .zone-item:hover { background: var(--color-surface-hover); }
  .zone-item.selected { border-color: var(--color-accent); background: var(--color-accent-bg); }
  .zone-item strong { font-size: .88rem; }
  .zone-item span { font-size: .75rem; display: block; }

  .matchdays { display: grid; gap: 1.5rem; }
  .matchday-card { background: var(--color-surface); border: 1px solid var(--color-border); border-radius: .8rem; padding: 1.2rem; }
  .matchday-header { display: flex; align-items: center; gap: .75rem; flex-wrap: wrap; margin-bottom: 1rem; }
  .matchday-header h3 { margin: 0; font-family: 'Space Grotesk', sans-serif; font-size: 1.15rem; }
  .matchday-meta { display: flex; gap: .4rem; flex-wrap: wrap; }
  .matchday-header .button { margin-left: auto; }

  .match-list { display: grid; gap: .5rem; }
  .match-card { border: 1px solid var(--color-border); border-radius: .6rem; overflow: hidden; }
  .match-card.played { opacity: .85; }
  .match-header {
    display: flex; align-items: center; gap: .75rem; padding: .7rem 1rem;
    background: transparent; border: 0; cursor: pointer; width: 100%; font-family: inherit;
    transition: background 150ms ease;
  }
  .match-header:hover { background: var(--color-surface-hover); }
  .match-teams { display: flex; align-items: center; gap: .5rem; flex: 1; min-width: 0; }
  .team { font-weight: 600; font-size: .9rem; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .team.home { text-align: right; flex: 1; }
  .team.away { text-align: left; flex: 1; }
  .team.winner { color: var(--color-accent); }
  .vs { color: var(--color-text-muted); font-size: .75rem; font-weight: 600; flex-shrink: 0; }
  .chevron { flex-shrink: 0; color: var(--color-text-muted); transition: transform 200ms ease; }
  .expanded .chevron { transform: rotate(180deg); }

  .match-detail { padding: .5rem 1rem 1rem; border-top: 1px solid var(--color-border); display: grid; gap: .5rem; }
  .category-result { display: flex; align-items: center; gap: .75rem; padding: .4rem 0; }
  .cat-name { font-size: .82rem; color: var(--color-text-muted); font-weight: 600; min-width: 80px; }
  .result-num { font-family: 'Space Grotesk', sans-serif; font-size: 1rem; font-weight: 700; }
  .result-num.winner-home { color: var(--color-success); }
  .result-num.winner-away { color: var(--color-accent); }
  .result-num.draw { color: var(--color-text-muted); }

  .result-input { display: flex; align-items: center; gap: .4rem; }
  .score-input {
    width: 48px; padding: .35rem; text-align: center; font-size: .9rem; font-weight: 700;
    border: 1px solid var(--color-input-border); border-radius: .4rem; background: var(--color-input); color: var(--color-text);
  }
  .score-input:focus { outline: none; border-color: var(--color-input-focus); }

  .button.small { padding: .35rem .65rem; font-size: .78rem; }

  @media (max-width: 767px) {
    .fixture-layout { grid-template-columns: 1fr !important; }
    .zone-sidebar { position: fixed; top: 0; left: 0; bottom: 0; z-index: 95; width: min(75vw, 280px); background: var(--color-surface); border-right: 1px solid var(--color-border); padding: 1rem; overflow-y: auto; }
    .fixture-layout .zone-sidebar { display: none; }
    .zone-sidebar.open { display: block; }
  }
</style>
