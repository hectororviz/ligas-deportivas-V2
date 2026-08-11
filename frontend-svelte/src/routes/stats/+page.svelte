<script lang="ts">
  import { onMount } from 'svelte';
  import { getTournaments, getLeaderboards, type Tournament } from '$lib/api';

  let tournaments: Tournament[] = [];
  let selectedTournament: number | null = null;
  let leaderboards: any = null;
  let loading = true;
  let loadingStats = false;
  let error = '';

  onMount(async () => {
    try {
      tournaments = await getTournaments(true);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar los torneos.';
    } finally { loading = false; }
  });

  async function fetchLeaderboards() {
    if (!selectedTournament) return;
    loadingStats = true; error = ''; leaderboards = null;
    try {
      leaderboards = await getLeaderboards(selectedTournament);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar las estadísticas.';
    } finally { loadingStats = false; }
  }

  function sectionTitle(key: string) {
    const titles: Record<string, string> = {
      topScorersPlayers: 'Máximos goleadores',
      mostMatchesScoringPlayers: 'Jugadores con más partidos anotando',
      topScoringTeams: 'Equipos más goleadores',
      bestDefenseTeams: 'Equipos con mejor defensa',
      mostCleanSheetsTeams: 'Más vallas invictas',
      mostWinsTeams: 'Equipos con más victorias',
      mostGoalsMatches: 'Partidos con más goles',
      biggestWinsMatches: 'Mayores goleadas'
    };
    return titles[key] ?? key;
  }
</script>

<svelte:head><title>Estadísticas | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div><p class="eyebrow">Competencia</p><h1>Estadísticas</h1><p class="muted">Tablas de líderes, goleadores y más datos de cada torneo.</p></div>
    <a class="button secondary" href="/">Volver al panel</a>
  </header>

  {#if loading}
    <section class="loading-card">Cargando torneos...</section>
  {:else if tournaments.length === 0}
    <div class="empty-state compact-empty"><h2>Sin torneos</h2><p>No hay torneos registrados para consultar estadísticas.</p></div>
  {:else}
    <section class="card-surface">
      <div class="stats-controls">
        <label>
          Torneo
          <select bind:value={selectedTournament} onchange={fetchLeaderboards}>
            <option value={null}>Seleccionar torneo...</option>
            {#each tournaments as t}
              <option value={t.id}>{t.name} {t.year} · {t.league.name}</option>
            {/each}
          </select>
        </label>
      </div>

      {#if loadingStats}
        <p class="stats-loading">Cargando estadísticas...</p>
      {/if}

      {#if error}<p class="form-error">{error}</p>{/if}

      {#if leaderboards}
        {#each Object.entries(leaderboards) as [key, data]}
          {#if Array.isArray(data) && data.length > 0}
            <section class="leaderboard-section">
              <h2>{sectionTitle(key)}</h2>
              <div class="leaderboard-list">
                {#each data as item, i}
                  <div class="leaderboard-row">
                    <span class="leaderboard-pos">{i + 1}</span>
                    <span class="leaderboard-name">{item.name ?? item.teamName ?? item.clubName ?? item.playerName ?? `#${item.id}`}</span>
                    <span class="leaderboard-value">{item.value ?? item.goals ?? item.points ?? item.matches ?? item.totalGoals ?? ''}</span>
                  </div>
                {/each}
              </div>
            </section>
          {/if}
        {/each}
      {/if}
    </section>
  {/if}
</main>

<style>
  .stats-controls { display: flex; gap: .6rem; flex-wrap: wrap; align-items: end; margin-bottom: 1.5rem; }
  .stats-controls label { max-width: 380px; }
  .stats-loading { color: var(--color-text-muted); text-align: center; padding: 2rem 0; }
  .leaderboard-section { margin-bottom: 1.5rem; }
  .leaderboard-section h2 {
    margin: 0 0 .75rem; font-family: 'Space Grotesk', sans-serif; font-size: 1.1rem;
    letter-spacing: -.02em; color: var(--color-accent-text);
  }
  .leaderboard-list { border: 1px solid var(--color-border); border-radius: .8rem; overflow: hidden; }
  .leaderboard-row {
    display: flex; align-items: center; gap: .6rem; padding: .65rem 1rem;
    border-bottom: 1px solid var(--color-border); font-size: .88rem;
  }
  .leaderboard-row:last-child { border-bottom: 0; }
  .leaderboard-row:nth-child(even) { background: var(--color-sidebar); }
  .leaderboard-pos {
    width: 1.5rem; height: 1.5rem; display: grid; place-items: center; flex: 0 0 auto;
    border-radius: 50%; color: var(--color-accent-text); background: var(--color-accent-bg);
    font-size: .72rem; font-weight: 700;
  }
  .leaderboard-name { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .leaderboard-value { flex: 0 0 auto; font-weight: 700; color: var(--color-text); }
</style>
