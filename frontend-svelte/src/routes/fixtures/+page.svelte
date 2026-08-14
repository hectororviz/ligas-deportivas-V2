<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { browser } from '$app/environment';
  import {
    getLeagues,
    getTournaments,
    getZones,
    getZoneMatches,
    getProfile,
    updateMatchday,
    finalizeMatchday,
    type League,
    type Tournament,
    type Zone,
    type ZoneMatchesResponse,
    type ZoneMatchday,
    type ZoneMatch,
    type AuthUser,
  } from '$lib/api';
  import FixtureFilters from '$lib/FixtureFilters.svelte';
  import FechaCarousel from '$lib/FechaCarousel.svelte';
  import PartidoCard from '$lib/PartidoCard.svelte';

  const STORAGE_KEY = 'ligas:fixture-selection';

  let leagues: League[] = $state([]);
  let tournaments: Tournament[] = $state([]);
  let zones: Zone[] = $state([]);

  let selectedLeagueId: number | null = $state(null);
  let selectedTournamentId: number | null = $state(null);
  let selectedZoneId: number | null = $state(null);
  let selectedMatchday: number | null = $state(null);

  let matchesData: ZoneMatchesResponse | null = $state(null);
  let loading = $state(true);
  let matchesLoading = $state(false);
  let error = $state('');

  let user: AuthUser | null = $state(null);
  let finalizing = $state(false);
  let updatingDate = $state(false);
  let notice = $state('');

  let canManage = $derived(((user as AuthUser | null)?.roles ?? []).includes('ADMIN'));

  let currentMatchday = $derived.by(() => {
    if (!matchesData || selectedMatchday == null) return null;
    return matchesData.matchdays.find((m) => m.matchday === selectedMatchday) ?? null;
  });

  let currentMatches = $derived.by(() => {
    if (!matchesData || selectedMatchday == null) return [];
    return matchesData.matches.filter((m) => m.matchday === selectedMatchday);
  });

  let selectedZone = $derived(zones.find((z) => z.id === selectedZoneId) ?? null);

  onMount(async () => {
    try {
      [leagues, tournaments, zones, user] = await Promise.all([
        getLeagues(),
        getTournaments(),
        getZones(),
        getProfile(),
      ]);
      const initial = readInitialSelection();
      applySelection(initial);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar los datos.';
    } finally {
      loading = false;
    }
  });

  function readInitialSelection(): { leagueId: number | null; tournamentId: number | null; zoneId: number | null; matchday: number | null } {
    const qp = $page.url.searchParams;
    if (qp.has('league') || qp.has('torneo') || qp.has('zona')) {
      return {
        leagueId: toId(qp.get('league')),
        tournamentId: toId(qp.get('torneo')),
        zoneId: toId(qp.get('zona')),
        matchday: toId(qp.get('fecha')),
      };
    }
    if (browser) {
      try {
        const raw = localStorage.getItem(STORAGE_KEY);
        if (raw) {
          const parsed = JSON.parse(raw);
          return {
            leagueId: toId(parsed.leagueId),
            tournamentId: toId(parsed.tournamentId),
            zoneId: toId(parsed.zoneId),
            matchday: toId(parsed.matchday),
          };
        }
      } catch {}
    }
    return { leagueId: null, tournamentId: null, zoneId: null, matchday: null };
  }

  async function applySelection(sel: { leagueId: number | null; tournamentId: number | null; zoneId: number | null; matchday: number | null }) {
    let { leagueId, tournamentId, zoneId } = sel;
    if (leagueId != null && !leagues.some((l) => l.id === leagueId)) leagueId = null;
    if (tournamentId != null && !tournaments.some((t) => t.id === tournamentId)) tournamentId = null;
    if (tournamentId != null && leagueId != null && !tournaments.some((t) => t.id === tournamentId && t.leagueId === leagueId)) tournamentId = null;
    if (zoneId != null && !zones.some((z) => z.id === zoneId)) zoneId = null;
    if (zoneId != null && tournamentId != null && !zones.some((z) => z.id === zoneId && z.tournamentId === tournamentId)) zoneId = null;

    selectedLeagueId = leagueId;
    selectedTournamentId = tournamentId;
    selectedZoneId = zoneId;

    if (zoneId != null) {
      await loadMatches(zoneId, sel.matchday);
    } else {
      matchesData = null;
      selectedMatchday = null;
    }
    syncUrl();
  }

  async function loadMatches(zoneId: number, preferredMatchday: number | null = null) {
    matchesLoading = true;
    error = '';
    try {
      matchesData = await getZoneMatches(zoneId);
      selectedMatchday = pickCurrentMatchday(matchesData.matchdays, preferredMatchday);
    } catch (cause) {
      matchesData = null;
      selectedMatchday = null;
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar los partidos.';
    } finally {
      matchesLoading = false;
    }
  }

  function pickCurrentMatchday(matchdays: ZoneMatchday[], preferred: number | null): number | null {
    if (matchdays.length === 0) return null;
    if (preferred != null && matchdays.some((m) => m.matchday === preferred)) return preferred;
    const inProgress = matchdays.find((m) => m.status === 'IN_PROGRESS');
    if (inProgress) return inProgress.matchday;
    const pending = matchdays.find((m) => m.status === 'PENDING');
    if (pending) return pending.matchday;
    return matchdays[matchdays.length - 1].matchday;
  }

  function onLeagueChange(id: number | null) {
    selectedLeagueId = id;
    selectedTournamentId = null;
    selectedZoneId = null;
    selectedMatchday = null;
    matchesData = null;
    persist();
    syncUrl();
  }

  function onTournamentChange(id: number | null) {
    selectedTournamentId = id;
    selectedZoneId = null;
    selectedMatchday = null;
    matchesData = null;
    persist();
    syncUrl();
  }

  async function onZoneChange(id: number | null) {
    selectedZoneId = id;
    selectedMatchday = null;
    matchesData = null;
    if (id != null) {
      await loadMatches(id);
    }
    persist();
    syncUrl();
  }

  function onMatchdaySelect(matchday: number) {
    selectedMatchday = matchday;
    persist();
    syncUrl();
  }

  function onMatchClick(matchId: number) {
    const params = new URLSearchParams();
    if (selectedZoneId != null) params.set('zona', String(selectedZoneId));
    if (selectedMatchday != null) params.set('fecha', String(selectedMatchday));
    goto(`/fixtures/partido/${matchId}${params.toString() ? `?${params}` : ''}`);
  }

  function persist() {
    if (!browser) return;
    localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify({
        leagueId: selectedLeagueId,
        tournamentId: selectedTournamentId,
        zoneId: selectedZoneId,
        matchday: selectedMatchday,
      })
    );
  }

  function syncUrl() {
    const params = new URLSearchParams();
    if (selectedLeagueId != null) params.set('league', String(selectedLeagueId));
    if (selectedTournamentId != null) params.set('torneo', String(selectedTournamentId));
    if (selectedZoneId != null) params.set('zona', String(selectedZoneId));
    if (selectedMatchday != null) params.set('fecha', String(selectedMatchday));
    const qs = params.toString();
    goto(`/fixtures${qs ? `?${qs}` : ''}`, { replaceState: true, noScroll: true });
  }

  function toId(value: string | null | undefined): number | null {
    if (value == null || value === '') return null;
    const n = Number(value);
    return Number.isFinite(n) && n > 0 ? n : null;
  }

  function dateValue(md: ZoneMatchday | null): string {
    return md?.date ? md.date.slice(0, 10) : '';
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

  function categorySummary(matches: ZoneMatch[]): { closed: number; toZero: number; pending: number } {
    let closed = 0;
    let toZero = 0;
    let pending = 0;
    for (const match of matches) {
      for (const category of match.categories) {
        if (category.closedAt) closed++;
        else if (category.isPending) pending++;
        else toZero++;
      }
    }
    return { closed, toZero, pending };
  }

  async function onDateChange(value: string) {
    if (!canManage || selectedZoneId == null || selectedMatchday == null || updatingDate) return;
    updatingDate = true;
    error = '';
    try {
      await updateMatchday(selectedZoneId, selectedMatchday, value || null);
      notice = `Fecha actualizada.`;
      await loadMatches(selectedZoneId, selectedMatchday);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo actualizar la fecha.';
    } finally {
      updatingDate = false;
    }
  }

  async function onFinalize() {
    if (!canManage || selectedZoneId == null || selectedMatchday == null || finalizing) return;
    const summary = categorySummary(currentMatches);
    const message =
      `¿Finalizar la Fecha ${selectedMatchday}?\n\n` +
      `• ${summary.closed} resultado(s) cargado(s)\n` +
      `• ${summary.toZero} se fijarán como 0-0\n` +
      `• ${summary.pending} pendiente(s) (no suman puntos)`;
    if (!confirm(message)) return;
    finalizing = true;
    error = '';
    try {
      await finalizeMatchday(selectedZoneId, selectedMatchday);
      notice = `Fecha ${selectedMatchday} finalizada.`;
      await loadMatches(selectedZoneId, selectedMatchday);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo finalizar la fecha.';
    } finally {
      finalizing = false;
    }
  }
</script>

<svelte:head><title>Fixture | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div>
      <p class="eyebrow">Competencia</p>
      <h1>Fixture</h1>
      <p class="muted">Consultá los partidos por liga, torneo y zona.</p>
    </div>
  </header>

  {#if loading}
    <section class="loading-card">Cargando fixture...</section>
  {:else}
    <FixtureFilters
      {leagues}
      {tournaments}
      {zones}
      leagueId={selectedLeagueId}
      tournamentId={selectedTournamentId}
      zoneId={selectedZoneId}
      onLeagueChange={onLeagueChange}
      onTournamentChange={onTournamentChange}
      onZoneChange={onZoneChange}
    />

    {#if error}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}

    {#if !selectedZoneId}
      <div class="empty-state">
        <div class="empty-icon">🗓</div>
        <h2>Seleccioná una zona</h2>
        <p class="muted">Elegí liga, torneo y zona para ver los partidos.</p>
      </div>
    {:else if matchesLoading}
      <section class="loading-card">Cargando partidos...</section>
    {:else if matchesData && matchesData.matchdays.length === 0}
      <div class="empty-state">
        <div class="empty-icon">🏟</div>
        <h2>Sin fechas</h2>
        <p class="muted">Esta zona todavía no tiene un fixture generado.</p>
      </div>
    {:else if matchesData}
      <div class="zone-context">
        <p class="eyebrow">{selectedZone?.tournament.league.name} · {selectedZone?.tournament.name}</p>
        <h2 class="zone-title">Zona {selectedZone?.name}</h2>
      </div>

      <FechaCarousel
        matchdays={matchesData.matchdays}
        selectedMatchday={selectedMatchday}
        onSelect={onMatchdaySelect}
      />

      {#if currentMatches.length === 0}
        <div class="empty-state compact-empty">
          <h2>Sin partidos en esta fecha</h2>
          <p class="muted">No hay cruces cargados para la Fecha {selectedMatchday}.</p>
        </div>
      {:else}
        <div class="matches-grid">
          {#each currentMatches as match}
            <PartidoCard {match} onclick={onMatchClick} />
          {/each}
        </div>
      {/if}

      {#if canManage && selectedMatchday != null}
        <section class="matchday-admin">
          <div class="matchday-admin-head">
            <h2>Fecha {selectedMatchday}</h2>
            <span class="status-badge {statusClass(currentMatchday?.status ?? '')}">{statusLabel(currentMatchday?.status ?? '')}</span>
          </div>
          <div class="matchday-admin-body">
            <label class="date-field">
              Día de juego
              <input
                type="date"
                value={dateValue(currentMatchday)}
                disabled={updatingDate}
                onchange={(e) => onDateChange((e.currentTarget as HTMLInputElement).value)}
              />
            </label>
            {#if currentMatchday?.date}
              <button class="button secondary small" disabled={updatingDate} onclick={() => onDateChange('')}>Quitar fecha</button>
            {/if}
            {#if currentMatchday?.status === 'IN_PROGRESS' || currentMatchday?.status === 'INCOMPLETE'}
              <button class="button primary small" disabled={finalizing} onclick={onFinalize}>
                {finalizing ? 'Finalizando...' : 'Finalizar fecha'}
              </button>
            {/if}
          </div>
        </section>
      {/if}
    {/if}
  {/if}
</main>

<style>
  .zone-context { margin-top: 1.5rem; min-width: 0; }
  .zone-context .eyebrow { margin: 0; }
  .zone-title {
    margin: .3rem 0 0;
    font-family: 'Space Grotesk', sans-serif;
    font-size: 1.5rem;
    letter-spacing: -.03em;
    color: var(--color-heading);
    overflow-wrap: break-word;
  }
  .matches-grid {
    display: grid;
    grid-template-columns: minmax(0, 1fr);
    gap: .6rem;
    margin-top: .5rem;
  }
  @media (min-width: 720px) {
    .matches-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  }

  .matchday-admin {
    margin-top: 1.5rem;
    padding: 1.25rem 1.5rem;
    border: 1px solid var(--color-border);
    border-radius: 1.2rem;
    background: var(--color-surface);
    box-shadow: 0 16px 45px var(--color-shadow);
  }
  .matchday-admin-head { display: flex; align-items: center; gap: .6rem; flex-wrap: wrap; }
  .matchday-admin-head h2 { margin: 0; font-family: 'Space Grotesk', sans-serif; letter-spacing: -.03em; }
  .matchday-admin-body { display: flex; align-items: flex-end; gap: .6rem; flex-wrap: wrap; margin-top: .75rem; }

  .button.small { padding: .5rem .8rem; font-size: .82rem; }
  .date-field { display: inline-grid; gap: .35rem; }
  .date-field input {
    padding: .4rem .6rem; border: 1px solid var(--color-border); border-radius: .5rem;
    background: var(--color-input); color: var(--color-text); font-family: inherit; font-size: .85rem;
  }

  .status-badge { padding: .25rem .65rem; border-radius: 999px; font-size: .72rem; font-weight: 700; white-space: nowrap; }
  .md-pending { color: #c62828; background: #fdeded; }
  .md-in-progress { color: #b57800; background: #fff4cf; }
  .md-incomplete { color: #6d4c41; background: #f1e0d6; }
  .md-played { color: #00897b; background: #dbedf1; }
</style>
