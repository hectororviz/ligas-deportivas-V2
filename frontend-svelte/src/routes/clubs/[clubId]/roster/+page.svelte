<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { getClubRoster, type RosterCategory } from '$lib/api';

  let clubId: number = $derived(Number($page.params.clubId));
  let categories: RosterCategory[] = $state([]);
  let loading = $state(true);
  let error = $state('');

  onMount(() => {
    fetchRoster();
  });

  async function fetchRoster() {
    loading = true;
    error = '';
    try {
      const res = await getClubRoster(clubId);
      categories = res.tournamentCategories;
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo cargar el plantel.';
    } finally {
      loading = false;
    }
  }
</script>

<svelte:head><title>Plantel | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div>
      <p class="eyebrow">Club</p>
      <h1>Plantel</h1>
      <p class="muted">Jugadores registrados por torneo y categoría.</p>
    </div>
    <a class="button secondary" href="/clubs">Volver a clubes</a>
  </header>

  {#if loading}
    <section class="loading-card">Cargando plantel...</section>
  {:else if error && categories.length === 0}
    <p class="error-banner">{error}</p>
  {:else}
    {#if error}<p class="error-banner">{error}</p>{/if}

    {#if categories.length === 0}
      <section class="card-surface">
        <div class="empty-state compact-empty">
          <h2>Sin jugadores</h2>
          <p>No se encontraron jugadores registrados en este plantel.</p>
        </div>
      </section>
    {:else}
      {#each categories as rosterCat}
        <section class="card-surface roster-section">
          <div class="roster-header">
            <div>
              <p class="eyebrow">{rosterCat.tournamentCategory.tournament.name}</p>
              <h2>{rosterCat.tournamentCategory.category.name}</h2>
            </div>
            <div class="roster-meta">
              {#if rosterCat.lockedAt}
                <span class="tag tag-red">Cerrado</span>
              {/if}
              <span class="count-pill">{rosterCat.players.length}</span>
            </div>
          </div>

          {#if rosterCat.players.length === 0}
            <p class="muted">Sin jugadores en esta categoría.</p>
          {:else}
            <table class="standings-table roster-table">
              <thead>
                <tr>
                  <th>#</th>
                  <th>Nombre</th>
                  <th>Apellido</th>
                  <th>DNI</th>
                </tr>
              </thead>
              <tbody>
                {#each rosterCat.players as entry}
                  <tr>
                    <td>{entry.jersey ?? '-'}</td>
                    <td>{entry.player.firstName}</td>
                    <td>{entry.player.lastName}</td>
                    <td>{entry.player.dni}</td>
                  </tr>
                {/each}
              </tbody>
            </table>
          {/if}
        </section>
      {/each}
    {/if}
  {/if}
</main>

<style>
  .roster-section {
    padding: 1.5rem;
    margin-bottom: 1rem;
  }
  .roster-header {
    display: flex;
    justify-content: space-between;
    align-items: start;
    gap: 1rem;
    margin-bottom: 1rem;
    padding-bottom: 1rem;
    border-bottom: 1px solid var(--color-border);
  }
  .roster-header h2 {
    margin: .25rem 0 0;
    font-family: 'Space Grotesk', sans-serif;
    font-size: 1.3rem;
    letter-spacing: -.04em;
  }
  .roster-meta {
    display: flex;
    align-items: center;
    gap: .5rem;
    flex-shrink: 0;
  }
  .roster-table td:first-child,
  .roster-table th:first-child {
    width: 3rem;
    text-align: center;
    padding-left: .8rem;
  }
</style>
