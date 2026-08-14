<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import {
    getZoneMatches,
    getZones,
    getProfile,
    updateMatchday,
    finalizeMatchday,
    type Zone,
    type ZoneMatchesResponse,
    type ZoneMatchday,
    type ZoneMatch,
    type AuthUser,
  } from '$lib/api';

  const zoneId = Number($page.params.zoneId);

  let zone: Zone | null = $state(null);
  let matchesData: ZoneMatchesResponse | null = $state(null);
  let user: AuthUser | null = $state(null);
  let loading = $state(true);
  let error = $state('');
  let notice = $state('');

  let finalizing = $state<number | null>(null);
  let updating = $state<number | null>(null);

  let canManage = $derived(((user as AuthUser | null)?.roles ?? []).includes('ADMIN'));

  const matchdays = $derived.by(() => {
    if (!matchesData) return [];
    return [...matchesData.matchdays].sort((a, b) => a.matchday - b.matchday);
  });

  function matchesFor(matchday: number): ZoneMatch[] {
    return matchesData?.matches.filter((m) => m.matchday === matchday) ?? [];
  }

  function roundLabel(matchday: number): string {
    const first = matchesFor(matchday)[0];
    if (!first) return '';
    return first.round === 'SECOND' ? 'Rueda 2' : 'Rueda 1';
  }

  function statusLabel(status: string): string {
    const map: Record<string, string> = {
      PENDING: 'Pendiente',
      IN_PROGRESS: 'En juego',
      INCOMPLETE: 'Incompleta',
      PLAYED: 'Jugada',
    };
    return map[status] ?? status;
  }

  function statusClass(status: string): string {
    const map: Record<string, string> = {
      PENDING: 'md-pending',
      IN_PROGRESS: 'md-in-progress',
      INCOMPLETE: 'md-incomplete',
      PLAYED: 'md-played',
    };
    return map[status] ?? 'md-pending';
  }

  function dateValue(md: ZoneMatchday): string {
    return md.date ? md.date.slice(0, 10) : '';
  }

  function formatDate(date: string | null): string {
    if (!date) return 'Sin fecha';
    const [y, m, d] = date.slice(0, 10).split('-');
    return `${d}/${m}/${y}`;
  }

  function categorySummary(matchday: number) {
    let closed = 0;
    let toZero = 0;
    let pending = 0;
    for (const match of matchesFor(matchday)) {
      for (const category of match.categories) {
        if (category.closedAt) closed++;
        else if (category.isPending) pending++;
        else toZero++;
      }
    }
    return { closed, toZero, pending };
  }

  async function load() {
    loading = true;
    error = '';
    try {
      const [zones, matches, profile] = await Promise.all([
        getZones(true),
        getZoneMatches(zoneId),
        getProfile(),
      ]);
      zone = zones.find((z) => z.id === zoneId) ?? null;
      matchesData = matches;
      user = profile;
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo cargar la zona.';
    } finally {
      loading = false;
    }
  }

  async function onDateChange(md: ZoneMatchday, value: string) {
    if (!canManage || updating !== null) return;
    updating = md.matchday;
    error = '';
    try {
      await updateMatchday(zoneId, md.matchday, value || null);
      notice = `Fecha ${md.matchday} actualizada.`;
      await load();
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo actualizar la fecha.';
    } finally {
      updating = null;
    }
  }

  async function onFinalize(md: ZoneMatchday) {
    if (!canManage || finalizing !== null) return;
    const summary = categorySummary(md.matchday);
    const message =
      `¿Finalizar la Fecha ${md.matchday}?\n\n` +
      `• ${summary.closed} resultado(s) cargado(s)\n` +
      `• ${summary.toZero} se fijarán como 0-0\n` +
      `• ${summary.pending} pendiente(s) (no suman puntos)`;
    if (!confirm(message)) return;
    finalizing = md.matchday;
    error = '';
    try {
      await finalizeMatchday(zoneId, md.matchday);
      notice = `Fecha ${md.matchday} finalizada.`;
      await load();
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo finalizar la fecha.';
    } finally {
      finalizing = null;
    }
  }

  onMount(load);
</script>

<svelte:head><title>Fechas | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div>
      <p class="eyebrow">Competencia</p>
      <h1>Fechas {#if zone}· Zona {zone.name}{/if}</h1>
      <p class="muted">
        {#if zone}{zone.tournament.name} {zone.tournament.year} · {zone.tournament.league.name}{/if}
      </p>
    </div>
    <div class="header-actions">
      <a class="button secondary" href="/zones">Volver a zonas</a>
    </div>
  </header>

  {#if loading}
    <section class="loading-card">Cargando fechas...</section>
  {:else}
    {#if error}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}

    {#if !zone}
      <div class="empty-state">
        <div class="empty-icon">🗓</div>
        <h2>Zona no encontrada</h2>
        <p class="muted">No se encontró la zona indicada.</p>
      </div>
    {:else if matchdays.length === 0}
      <div class="empty-state">
        <div class="empty-icon">🏟</div>
        <h2>Sin fechas</h2>
        <p class="muted">Esta zona todavía no tiene un fixture generado.</p>
      </div>
    {:else}
      <div class="matchdays-list">
        {#each matchdays as md}
          {@const summary = categorySummary(md.matchday)}
          <article class="matchday-card" class:is-current={md.status === 'IN_PROGRESS'}>
            <div class="matchday-header">
              <div class="matchday-title">
                <h2>Fecha {md.matchday}</h2>
                {#if roundLabel(md.matchday)}<span class="badge-muted">{roundLabel(md.matchday)}</span>{/if}
                <span class="status-badge {statusClass(md.status)}">{statusLabel(md.status)}</span>
                {#if summary.pending > 0}<span class="badge-muted" title="Resultados pendientes de cargar">{summary.pending} pendiente(s)</span>{/if}
              </div>

              <div class="matchday-actions">
                {#if canManage}
                  <label class="date-field">
                    <input
                      type="date"
                      value={dateValue(md)}
                      disabled={updating === md.matchday}
                      onchange={(e) => onDateChange(md, (e.currentTarget as HTMLInputElement).value)}
                    />
                  </label>
                  {#if md.date}
                    <button class="button secondary small" disabled={updating === md.matchday} onclick={() => onDateChange(md, '')} title="Quitar fecha">
                      Quitar fecha
                    </button>
                  {/if}
                {:else}
                  <span class="date-readonly">{formatDate(md.date)}</span>
                {/if}

                {#if canManage && (md.status === 'IN_PROGRESS' || md.status === 'INCOMPLETE')}
                  <button class="button primary small" disabled={finalizing !== null} onclick={() => onFinalize(md)}>
                    {finalizing === md.matchday ? 'Finalizando...' : 'Finalizar'}
                  </button>
                {/if}
              </div>
            </div>

            <div class="matchday-matches">
              {#each matchesFor(md.matchday) as match}
                <a class="match-row" href={`/fixtures/partido/${match.id}?zona=${zoneId}&fecha=${md.matchday}`}>
                  <span class="match-club home">{match.homeClub?.name ?? 'Local'}</span>
                  <span class="match-score">
                    {#if match.categories.some((c) => c.closedAt)}
                      {match.pointsHome} - {match.pointsAway}
                    {:else}
                      vs
                    {/if}
                  </span>
                  <span class="match-club away">{match.awayClub?.name ?? 'Visitante'}</span>
                </a>
              {/each}
            </div>
          </article>
        {/each}
      </div>
    {/if}
  {/if}
</main>

<style>
  .header-actions { display: flex; gap: .6rem; align-items: center; }
  .button.small { padding: .5rem .8rem; font-size: .82rem; }

  .matchdays-list { display: grid; gap: 1rem; }

  .matchday-card {
    border: 1px solid var(--color-border);
    border-radius: 1.2rem;
    background: var(--color-surface);
    box-shadow: 0 16px 45px var(--color-shadow);
    padding: 1.25rem 1.5rem;
  }
  .matchday-card.is-current { border-color: var(--color-accent); border-style: dashed; }

  .matchday-header {
    display: flex; align-items: center; justify-content: space-between;
    gap: 1rem; flex-wrap: wrap;
  }
  .matchday-title { display: flex; align-items: center; gap: .5rem; flex-wrap: wrap; }
  .matchday-title h2 { margin: 0; font-family: 'Space Grotesk', sans-serif; letter-spacing: -.03em; }

  .matchday-actions { display: flex; align-items: center; gap: .5rem; flex-wrap: wrap; }
  .date-field { display: inline-flex; }
  .date-field input {
    padding: .4rem .6rem; border: 1px solid var(--color-border); border-radius: .5rem;
    background: var(--color-input); color: var(--color-text); font-family: inherit; font-size: .85rem;
  }
  .date-readonly { font-size: .85rem; color: var(--color-text-muted); font-weight: 600; }

  .status-badge { padding: .25rem .65rem; border-radius: 999px; font-size: .72rem; font-weight: 700; white-space: nowrap; }
  .md-pending { color: #c62828; background: #fdeded; }
  .md-in-progress { color: #b57800; background: #fff4cf; }
  .md-incomplete { color: #6d4c41; background: #f1e0d6; }
  .md-played { color: #00897b; background: #dbedf1; }

  .matchday-matches { margin-top: 1rem; border-top: 1px solid var(--color-border); padding-top: .5rem; display: grid; gap: .25rem; }
  .match-row {
    display: flex; align-items: center; gap: .75rem; padding: .5rem .25rem;
    text-decoration: none; color: inherit; border-radius: .5rem;
  }
  .match-row:hover { background: var(--color-surface-hover); }
  .match-club { flex: 1; font-size: .9rem; font-weight: 600; }
  .match-club.home { text-align: right; }
  .match-score {
    min-width: 4.5rem; text-align: center; font-family: 'Space Grotesk', sans-serif;
    font-weight: 700; font-size: .9rem; color: var(--color-text-muted);
  }

  @media (max-width: 640px) {
    .matchday-header { flex-direction: column; align-items: stretch; }
    .matchday-actions { justify-content: flex-start; }
  }
</style>
