<script lang="ts">
  import { onMount } from 'svelte';
  import {
    getTournaments,
    getTournamentStandings,
    getZones,
    getZoneStandings,
    type Tournament,
    type Zone,
    type StandingRow,
    type ZoneStanding
  } from '$lib/api';

  interface TournamentStanding {
    zoneId: number;
    zoneName: string;
    categories: { categoryId: number; categoryName: string; standings: StandingRow[] }[];
  }

  let tournaments: Tournament[] = [];
  let zones: Zone[] = [];
  let loading = true;
  let error = '';

  let activeTab: 'zona' | 'torneo' = 'zona';

  let selectedZoneId: number | null = null;
  let selectedTournamentId: number | null = null;

  let zoneStandings: ZoneStanding | null = null;
  let tournamentStandings: TournamentStanding[] = [];
  let standingsLoading = false;

  onMount(async () => {
    try {
      [tournaments, zones] = await Promise.all([getTournaments(), getZones()]);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar los datos.';
    } finally {
      loading = false;
    }
  });

  async function loadZoneStandings() {
    if (!selectedZoneId) return;
    standingsLoading = true;
    error = '';
    zoneStandings = null;
    try {
      zoneStandings = await getZoneStandings(selectedZoneId);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar las posiciones.';
    } finally {
      standingsLoading = false;
    }
  }

  async function loadTournamentStandings() {
    if (!selectedTournamentId) return;
    standingsLoading = true;
    error = '';
    tournamentStandings = [];
    try {
      const data = await getTournamentStandings(selectedTournamentId);
      tournamentStandings = data as TournamentStanding[];
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar las posiciones.';
    } finally {
      standingsLoading = false;
    }
  }

  $: {
    if (selectedZoneId && activeTab === 'zona') loadZoneStandings();
  }

  $: {
    if (selectedTournamentId && activeTab === 'torneo') loadTournamentStandings();
  }

  function formatStandingHeaders(): string[] {
    return ['Pos', 'Club', 'J', 'G', 'E', 'P', 'GF', 'GC', 'DG', 'Pts'];
  }
</script>

<svelte:head><title>Tablas | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div>
      <p class="eyebrow">Competencia</p>
      <h1>Tablas de posiciones</h1>
      <p class="muted">Consultá las posiciones por zona o por torneo.</p>
    </div>
  </header>

  {#if loading}
    <section class="loading-card">Cargando torneos...</section>
  {:else}
    {#if error}
      <p class="error-banner">{error}</p>
    {/if}

    <div class="tabs">
      <button
        class="tab"
        class:active={activeTab === 'zona'}
        onclick={() => { activeTab = 'zona'; zoneStandings = null; }}>
        Por zona
      </button>
      <button
        class="tab"
        class:active={activeTab === 'torneo'}
        onclick={() => { activeTab = 'torneo'; tournamentStandings = []; }}>
        Por torneo
      </button>
    </div>

    <div class="standings-content card-surface">
      {#if activeTab === 'zona'}
        <p class="eyebrow">Seleccionar zona</p>
        <div class="select-row">
          <select
            bind:value={selectedZoneId}
            disabled={zones.length === 0}>
            <option value={null}>-- Elegir zona --</option>
            {#each zones as zone}
              <option value={zone.id}>
                {zone.name} — {zone.tournament.name} {zone.tournament.year} ({zone.tournament.league.name})
              </option>
            {/each}
          </select>
        </div>

        {#if standingsLoading}
          <section class="loading-card">Cargando posiciones...</section>
        {:else if zoneStandings}
          <div class="standings-section">
            <h2>{zoneStandings.zoneName}</h2>
            <p class="muted">{zoneStandings.tournamentName}</p>
            {#each zoneStandings.categories as category}
              <div class="category-block">
                <h3 class="category-title">{category.categoryName}</h3>
                {#if category.standings.length === 0}
                  <p class="muted compact">Sin posiciones en esta categoría.</p>
                {:else}
                  <table class="standings-table">
                    <thead>
                      <tr>
                        {#each formatStandingHeaders() as header}
                          <th>{header}</th>
                        {/each}
                      </tr>
                    </thead>
                    <tbody>
                      {#each category.standings as row, index}
                        <tr>
                          <td><span class="position">{index + 1}</span></td>
                          <td>{row.clubName}</td>
                          <td>{row.played}</td>
                          <td>{row.wins}</td>
                          <td>{row.draws}</td>
                          <td>{row.losses}</td>
                          <td>{row.goalsFor}</td>
                          <td>{row.goalsAgainst}</td>
                          <td>{row.goalDifference}</td>
                          <td class="pts">{row.points}</td>
                        </tr>
                      {/each}
                    </tbody>
                  </table>
                {/if}
              </div>
            {/each}
          </div>
        {:else}
          <div class="empty-state compact-empty">
            <span class="empty-icon">&#8693;</span>
            <h2>Seleccioná una zona</h2>
            <p>Elegí una zona para ver sus posiciones.</p>
          </div>
        {/if}
      {:else}
        <p class="eyebrow">Seleccionar torneo</p>
        <div class="select-row">
          <select
            bind:value={selectedTournamentId}
            disabled={tournaments.length === 0}>
            <option value={null}>-- Elegir torneo --</option>
            {#each tournaments as tournament}
              <option value={tournament.id}>
                {tournament.name} {tournament.year} ({tournament.league.name})
              </option>
            {/each}
          </select>
        </div>

        {#if standingsLoading}
          <section class="loading-card">Cargando posiciones...</section>
        {:else if tournamentStandings.length > 0}
          <div class="standings-section">
            {#each tournamentStandings as zoneData}
              <h2>{zoneData.zoneName}</h2>
              {#each zoneData.categories as category}
                <div class="category-block">
                  <h3 class="category-title">{category.categoryName}</h3>
                  {#if category.standings.length === 0}
                    <p class="muted compact">Sin posiciones en esta categoría.</p>
                  {:else}
                    <table class="standings-table">
                      <thead>
                        <tr>
                          {#each formatStandingHeaders() as header}
                            <th>{header}</th>
                          {/each}
                        </tr>
                      </thead>
                      <tbody>
                        {#each category.standings as row, index}
                          <tr>
                            <td><span class="position">{index + 1}</span></td>
                            <td>{row.clubName}</td>
                            <td>{row.played}</td>
                            <td>{row.wins}</td>
                            <td>{row.draws}</td>
                            <td>{row.losses}</td>
                            <td>{row.goalsFor}</td>
                            <td>{row.goalsAgainst}</td>
                            <td>{row.goalDifference}</td>
                            <td class="pts">{row.points}</td>
                          </tr>
                        {/each}
                      </tbody>
                    </table>
                  {/if}
                </div>
              {/each}
            {/each}
          </div>
        {:else}
          <div class="empty-state compact-empty">
            <span class="empty-icon">&#8693;</span>
            <h2>Seleccioná un torneo</h2>
            <p>Elegí un torneo para ver sus posiciones.</p>
          </div>
        {/if}
      {/if}
    </div>
  {/if}
</main>

<style>
  .tabs {
    display: flex;
    gap: 0.4rem;
    margin-bottom: 1rem;
  }
  .tab {
    border: 1px solid var(--color-border); border-radius: 0.7rem; padding: 0.7rem 1.4rem;
    background: var(--color-surface); color: var(--color-text-muted);
    cursor: pointer; font-weight: 600; font-size: 0.9rem;
  }
  .tab.active { color: var(--color-hero); background: var(--color-hero-accent); border-color: var(--color-hero-accent); }
  .select-row { margin: 0.8rem 0 1.5rem; }
  .select-row select { width: 100%; max-width: 480px; border: 1px solid var(--color-input-border); border-radius: 0.7rem; padding: 0.85rem 1rem; color: var(--color-text); background: var(--color-input); }
  .standings-section h2 { margin: 1.5rem 0 0.2rem; font-family: 'Space Grotesk', sans-serif; font-size: 1.5rem; letter-spacing: -0.04em; }
  .category-block { margin-top: 1.5rem; }
  .category-title { margin: 0 0 0.8rem; font-family: 'Space Grotesk', sans-serif; font-size: 1.15rem; color: var(--color-text); }
  .standings-table { width: 100%; border-collapse: collapse; font-size: 0.9rem; }
  .standings-table th { padding: 0.6rem 0.4rem; border-bottom: 2px solid var(--color-border); color: var(--color-accent-text); font-size: 0.75rem; font-weight: 700; text-transform: uppercase; text-align: center; }
  .standings-table th:nth-child(2) { text-align: left; }
  .standings-table td { padding: 0.55rem 0.4rem; border-top: 1px solid var(--color-border); text-align: center; }
  .standings-table td:nth-child(2) { text-align: left; font-weight: 600; }
  .standings-table .position { display: inline-grid; }
  .standings-table .pts { font-weight: 700; color: var(--color-heading); }
</style>
