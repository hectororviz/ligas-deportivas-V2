<script lang="ts">
  import { onMount } from 'svelte';
  import { browser } from '$app/environment';
  import { page } from '$app/stores';
  import {
    getLeagues,
    getTournaments,
    getZones,
    getZoneStandings,
    type Club,
    type League,
    type Tournament,
    type Zone,
    type ZoneStanding,
  } from '$lib/api';
  import ClubCarousel from '$lib/ClubCarousel.svelte';
  import FixtureFilters from '$lib/FixtureFilters.svelte';
  import StandingsBlock from '$lib/StandingsBlock.svelte';

  const STORAGE_KEY = 'ligas:standings-selection';

  let leagues: League[] = $state([]);
  let tournaments: Tournament[] = $state([]);
  let zones: Zone[] = $state([]);
  let selectedClubId: number | null = $state(null);
  let selectedLeagueId: number | null = $state(null);
  let selectedTournamentId: number | null = $state(null);
  let selectedZoneId: number | null = $state(null);

  let zoneStanding: ZoneStanding | null = $state(null);
  let clubStandings: Record<number, ZoneStanding> = $state({});
  let loading = $state(true);
  let standingsLoading = $state(false);
  let error = $state('');

  let clubs = $derived.by(() => {
    const unique = new Map<number, Club>();
    for (const zone of zones) {
      for (const assignment of zone.clubZones ?? []) unique.set(assignment.club.id, assignment.club);
    }
    return [...unique.values()].sort((a, b) => (a.shortName?.trim() || a.name).localeCompare(b.shortName?.trim() || b.name, 'es'));
  });
  let selectedClub = $derived(clubs.find((club) => club.id === selectedClubId) ?? null);

  function clubZonesFor(clubId: number | null): Zone[] {
    if (clubId == null) return [];
    return zones.filter((zone) => (zone.clubZones ?? []).some((assignment) => assignment.club.id === clubId));
  }

  let clubZones = $derived(clubZonesFor(selectedClubId));
  let selectedZone = $derived(zones.find((zone) => zone.id === selectedZoneId) ?? null);

  onMount(async () => {
    try {
      [leagues, tournaments, zones] = await Promise.all([getLeagues(), getTournaments(), getZones()]);
      await applySelection(readInitialSelection());
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar los datos.';
    } finally {
      loading = false;
    }
  });

  function toId(value: string | null | undefined): number | null {
    if (value == null || value === '') return null;
    const n = Number(value);
    return Number.isFinite(n) && n > 0 ? n : null;
  }

  function readInitialSelection(): { clubId: number | null; leagueId: number | null; tournamentId: number | null; zoneId: number | null } {
    const qp = $page.url.searchParams;
    if (qp.has('club') || qp.has('league') || qp.has('torneo') || qp.has('zona')) {
      return { clubId: toId(qp.get('club')), leagueId: toId(qp.get('league')), tournamentId: toId(qp.get('torneo')), zoneId: toId(qp.get('zona')) };
    }
    if (browser) {
      try {
        const raw = localStorage.getItem(STORAGE_KEY);
        if (raw) {
          const parsed = JSON.parse(raw);
          return { clubId: toId(parsed.clubId), leagueId: toId(parsed.leagueId), tournamentId: toId(parsed.tournamentId), zoneId: toId(parsed.zoneId) };
        }
      } catch {}
    }
    return { clubId: null, leagueId: null, tournamentId: null, zoneId: null };
  }

  async function applySelection(selection: { clubId: number | null; leagueId: number | null; tournamentId: number | null; zoneId: number | null }) {
    let { clubId, leagueId, tournamentId, zoneId } = selection;
    if (clubId != null && !zones.some((zone) => (zone.clubZones ?? []).some((assignment) => assignment.club.id === clubId))) clubId = null;
    if (clubId != null) {
      leagueId = null;
      tournamentId = null;
      zoneId = null;
    }
    if (leagueId != null && !leagues.some((league) => league.id === leagueId)) leagueId = null;
    if (tournamentId != null && !tournaments.some((tournament) => tournament.id === tournamentId && (!leagueId || tournament.leagueId === leagueId))) tournamentId = null;
    if (zoneId != null && !zones.some((zone) => zone.id === zoneId && (!tournamentId || zone.tournamentId === tournamentId))) zoneId = null;

    selectedClubId = clubId;
    selectedLeagueId = leagueId;
    selectedTournamentId = tournamentId;
    selectedZoneId = zoneId;
    if (clubId != null) await loadClubStandings(clubId);
    else if (zoneId != null) await loadZoneStanding(zoneId);
    syncUrl();
  }

  async function loadZoneStanding(zoneId: number) {
    standingsLoading = true;
    error = '';
    zoneStanding = null;
    try {
      zoneStanding = await getZoneStandings(zoneId);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar las posiciones.';
    } finally {
      standingsLoading = false;
    }
  }

  async function loadClubStandings(clubId: number) {
    standingsLoading = true;
    error = '';
    zoneStanding = null;
    clubStandings = {};
    try {
      const responses = await Promise.all(clubZonesFor(clubId).map(async (zone) => [zone.id, await getZoneStandings(zone.id)] as const));
      clubStandings = Object.fromEntries(responses);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar las posiciones.';
    } finally {
      standingsLoading = false;
    }
  }

  function onClubChange(id: number | null) {
    selectedClubId = id;
    if (id != null) {
      selectedLeagueId = null;
      selectedTournamentId = null;
      selectedZoneId = null;
      void loadClubStandings(id);
    } else {
      clubStandings = {};
    }
    zoneStanding = null;
    persist();
    syncUrl();
  }

  function onLeagueChange(id: number | null) {
    selectedClubId = null;
    selectedLeagueId = id;
    selectedTournamentId = null;
    selectedZoneId = null;
    zoneStanding = null;
    clubStandings = {};
    persist();
    syncUrl();
  }

  function onTournamentChange(id: number | null) {
    selectedClubId = null;
    selectedTournamentId = id;
    selectedZoneId = null;
    zoneStanding = null;
    clubStandings = {};
    persist();
    syncUrl();
  }

  async function onZoneChange(id: number | null) {
    selectedClubId = null;
    selectedZoneId = id;
    clubStandings = {};
    if (id != null) await loadZoneStanding(id);
    else zoneStanding = null;
    persist();
    syncUrl();
  }

  function persist() {
    if (!browser) return;
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ clubId: selectedClubId, leagueId: selectedLeagueId, tournamentId: selectedTournamentId, zoneId: selectedZoneId }));
  }

  function syncUrl() {
    const params = new URLSearchParams();
    if (selectedClubId != null) params.set('club', String(selectedClubId));
    if (selectedLeagueId != null) params.set('league', String(selectedLeagueId));
    if (selectedTournamentId != null) params.set('torneo', String(selectedTournamentId));
    if (selectedZoneId != null) params.set('zona', String(selectedZoneId));
    const query = params.toString();
    history.replaceState({}, '', `/standings${query ? `?${query}` : ''}`);
  }
</script>

<svelte:head><title>Tablas | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div>
      <p class="eyebrow">Competencia</p>
      <h1>Tablas de posiciones</h1>
      <p class="muted">Consultá las posiciones por liga, torneo, zona o club.</p>
    </div>
  </header>

  {#if loading}
    <section class="loading-card">Cargando tablas...</section>
  {:else}
    <ClubCarousel clubs={clubs} selectedClubId={selectedClubId} onSelect={onClubChange} />
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

    {#if standingsLoading}
      <section class="loading-card">Cargando posiciones...</section>
    {:else if selectedClubId != null}
      {#if clubZones.length === 0}
        <div class="empty-state"><span class="empty-icon">&#8693;</span><h2>Sin participaciones</h2><p>{selectedClub?.name ?? 'Este club'} no tiene zonas asignadas.</p></div>
      {:else}
        <div class="standings-results">
          {#each clubZones as zone (zone.id)}
            {#if clubStandings[zone.id]}<StandingsBlock {zone} standing={clubStandings[zone.id]} />{/if}
          {/each}
        </div>
      {/if}
    {:else if selectedZoneId != null && zoneStanding && selectedZone}
      <StandingsBlock zone={selectedZone} standing={zoneStanding} />
    {:else}
      <div class="empty-state"><span class="empty-icon">&#8693;</span><h2>Seleccioná una zona</h2><p>Elegí liga, torneo y zona para ver sus posiciones.</p></div>
    {/if}
  {/if}
</main>

<style>
  .standings-results { display: grid; gap: 1.25rem; }
</style>
