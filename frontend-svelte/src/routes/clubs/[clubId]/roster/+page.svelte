<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { getClubRoster, searchPlayersByDni, assignPlayerToClub, removePlayerFromClub, type RosterCategory, type Player } from '$lib/api';
  import Modal from '$lib/Modal.svelte';

  let clubId: number = $derived(Number($page.params.clubId));
  let categories: RosterCategory[] = $state([]);
  let loading = $state(true);
  let error = $state('');
  let notice = $state('');
  let saving = $state(false);

  let showPlayerPicker = $state(false);
  let pickerTournamentId = $state(0);
  let pickerTournamentCategoryId = $state(0);
  let searchDni = $state('');
  let searchResults = $state<Player[]>([]);
  let searching = $state(false);
  let searchError = $state('');

  onMount(() => { fetchRoster(); });

  async function fetchRoster() {
    loading = true; error = '';
    try {
      const res = await getClubRoster(clubId);
      categories = res.tournamentCategories;
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo cargar el plantel.';
    } finally { loading = false; }
  }

  function openPlayerPicker(tournamentId: number, tournamentCategoryId: number) {
    pickerTournamentId = tournamentId;
    pickerTournamentCategoryId = tournamentCategoryId;
    searchDni = '';
    searchResults = [];
    searchError = '';
    showPlayerPicker = true;
  }

  function closePlayerPicker() { showPlayerPicker = false; }

  async function searchPlayer() {
    if (!searchDni.trim()) { searchError = 'Ingresa un DNI para buscar.'; return; }
    searching = true; searchError = ''; searchResults = [];
    try {
      searchResults = await searchPlayersByDni(searchDni.trim());
      if (searchResults.length === 0) searchError = 'No se encontro ningun jugador con ese DNI.';
    } catch (cause) {
      searchError = cause instanceof Error ? cause.message : 'Error al buscar.';
    } finally { searching = false; }
  }

  async function assignPlayer(playerId: number) {
    saving = true; error = '';
    try {
      await assignPlayerToClub(pickerTournamentId, { playerId, clubId, tournamentCategoryId: pickerTournamentCategoryId });
      notice = 'Jugador asignado al plantel.';
      showPlayerPicker = false;
      await fetchRoster();
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'Error al asignar jugador.';
    } finally {
      saving = false;
      setTimeout(() => notice = '', 2500);
    }
  }

  async function removePlayer(tournamentId: number, playerId: number) {
    if (!confirm('¿Remover jugador del plantel?')) return;
    saving = true; error = '';
    try {
      await removePlayerFromClub(tournamentId, clubId, playerId);
      notice = 'Jugador removido del plantel.';
      await fetchRoster();
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'Error al remover jugador.';
    } finally {
      saving = false;
      setTimeout(() => notice = '', 2500);
    }
  }
</script>

<svelte:head><title>Plantel | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div>
      <p class="eyebrow">Club</p>
      <h1>Plantel</h1>
      <p class="muted">Jugadores registrados por torneo y categoria. Agrega o remueve jugadores.</p>
    </div>
  </header>

  {#if notice}<p class="success-banner">{notice}</p>{/if}
  {#if error && !showPlayerPicker}<p class="error-banner">{error}</p>{/if}

  {#if loading}
    <section class="loading-card">Cargando plantel...</section>
  {:else if categories.length === 0}
    <section class="card-surface">
      <div class="empty-state compact-empty">
        <h2>Sin datos de plantel</h2>
        <p>El club no tiene categorias de torneo asignadas.</p>
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
            {:else}
              <button class="button primary small" disabled={saving} onclick={() => openPlayerPicker(rosterCat.tournamentCategory.tournament.id, rosterCat.tournamentCategoryId)}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" x2="12" y1="5" y2="19"/><line x1="5" x2="19" y1="12" y2="12"/></svg>
                Agregar
              </button>
            {/if}
            <span class="count-pill">{rosterCat.players.length}</span>
          </div>
        </div>

        {#if rosterCat.players.length === 0}
          <p class="muted">Sin jugadores en esta categoria.</p>
        {:else}
          <table class="standings-table roster-table">
            <thead>
              <tr>
                <th>#</th>
                <th>Nombre</th>
                <th>Apellido</th>
                <th>DNI</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {#each rosterCat.players as entry}
                <tr>
                  <td>{entry.jersey ?? '-'}</td>
                  <td>{entry.player.firstName}</td>
                  <td>{entry.player.lastName}</td>
                  <td>{entry.player.dni}</td>
                  <td>
                    {#if !rosterCat.lockedAt}
                      <button class="icon-button remove-row" onclick={() => removePlayer(rosterCat.tournamentCategory.tournament.id, entry.player.id)} aria-label="Remover jugador">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" x2="6" y1="6" y2="18"/><line x1="6" x2="18" y1="6" y2="18"/></svg>
                      </button>
                    {/if}
                  </td>
                </tr>
              {/each}
            </tbody>
          </table>
        {/if}
      </section>
    {/each}
  {/if}
</main>

{#if showPlayerPicker}
  <Modal onclose={closePlayerPicker}>
    <div class="modal-form">
      <p class="eyebrow">Agregar jugador</p>
      <h2>Buscar por DNI</h2>
      {#if searchError}<p class="form-error">{searchError}</p>{/if}
      {#if error}<p class="form-error">{error}</p>{/if}
      <div class="search-row">
        <input type="text" bind:value={searchDni} placeholder="DNI del jugador" disabled={searching || saving} onkeydown={(e) => e.key === 'Enter' && searchPlayer()} />
        <button class="button primary" onclick={searchPlayer} disabled={searching}>Buscar</button>
      </div>
      {#if searchResults.length > 0}
        <div class="search-results">
          {#each searchResults as player}
            <div class="player-result">
              <div>
                <strong>{player.lastName}, {player.firstName}</strong>
                <span class="muted">DNI {player.dni}</span>
              </div>
              <button class="button primary small" onclick={() => assignPlayer(player.id)} disabled={saving}>Agregar</button>
            </div>
          {/each}
        </div>
      {/if}
    </div>
  </Modal>
{/if}

<style>
  .roster-section { padding: 1.5rem; margin-bottom: 1rem; }
  .roster-header {
    display: flex; justify-content: space-between; align-items: start; gap: 1rem;
    margin-bottom: 1rem; padding-bottom: 1rem; border-bottom: 1px solid var(--color-border);
  }
  .roster-header h2 { margin: .25rem 0 0; font-family: 'Space Grotesk', sans-serif; font-size: 1.3rem; letter-spacing: -.04em; }
  .roster-meta { display: flex; align-items: center; gap: .5rem; flex-shrink: 0; }
  .roster-table td:first-child, .roster-table th:first-child { width: 3rem; text-align: center; padding-left: .8rem; }

  .search-row { display: flex; gap: .5rem; margin: 1rem 0; }
  .search-row input { flex: 1; }
  .search-results { display: grid; gap: .4rem; margin-top: .75rem; max-height: 40vh; overflow-y: auto; }
  .player-result {
    display: flex; align-items: center; justify-content: space-between;
    padding: .6rem .75rem; border: 1px solid var(--color-border); border-radius: .5rem;
    background: var(--color-input);
  }
  .player-result strong { display: block; font-size: .88rem; }
  .player-result span { font-size: .78rem; }

  .button.small { padding: .35rem .65rem; font-size: .78rem; }
  .remove-row { opacity: .4; }
  .remove-row:hover { opacity: 1; color: var(--color-error); }
</style>
