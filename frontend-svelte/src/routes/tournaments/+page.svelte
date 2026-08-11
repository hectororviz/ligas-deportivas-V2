<script lang="ts">
  import { onMount } from 'svelte';
  import Modal from '$lib/Modal.svelte';
  import { getTournaments, getProfile, createTournament, updateTournament, updateTournamentStatus, getLeagues, type AuthUser, type Tournament, type League } from '$lib/api';

  const genders = [
    ['MASCULINO', 'Masculino'], ['FEMENINO', 'Femenino'], ['MIXTO', 'Mixto']
  ];
  const championModes = [
    ['ROUND_AND_ANNUAL', 'Por ronda y anual'], ['GLOBAL', 'Global']
  ];
  const statusLabels: Record<string, string> = {
    DRAFT: 'Borrador', ACTIVE: 'Activo', FINISHED: 'Finalizado', CANCELLED: 'Cancelado'
  };
  const statusClasses: Record<string, string> = {
    DRAFT: 'badge-muted', ACTIVE: 'badge-active', FINISHED: 'badge-finished', CANCELLED: 'badge-cancelled'
  };

  let user: AuthUser | null = $state(null);
  let tournaments: Tournament[] = $state([]);
  let leagues: League[] = $state([]);
  let loading = $state(true);
  let saving = $state(false);
  let error = $state('');
  let notice = $state('');
  let editing: Tournament | null = $state(null);
  let showInactive = $state(false);
  let showForm = $state(false);
  let showFilters = $state(false);
  let canManage = $state(false);
  let form = $state({
    leagueId: '', name: '', year: new Date().getFullYear(), gender: 'MASCULINO',
    championMode: 'ROUND_AND_ANNUAL', pointsWin: 3, pointsDraw: 1, pointsLoss: 0,
    startDate: '', endDate: ''
  });

  onMount(async () => {
    try {
      const [u, l] = await Promise.all([getProfile(), getLeagues()]);
      user = u; leagues = l;
      canManage = (u?.roles ?? []).includes('ADMIN');
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar los torneos.';
    }
    await fetchTournaments();
  });

  function openCreate() {
    editing = null;
    form = {
      leagueId: '', name: '', year: new Date().getFullYear(), gender: 'MASCULINO',
      championMode: 'ROUND_AND_ANNUAL', pointsWin: 3, pointsDraw: 1, pointsLoss: 0,
      startDate: '', endDate: ''
    };
    error = '';
    showForm = true;
  }

  function openEdit(tournament: Tournament) {
    editing = tournament;
    form = {
      leagueId: String(tournament.leagueId),
      name: tournament.name,
      year: tournament.year,
      gender: tournament.gender,
      championMode: tournament.championMode,
      pointsWin: tournament.pointsWin,
      pointsDraw: tournament.pointsDraw,
      pointsLoss: tournament.pointsLoss,
      startDate: tournament.startDate ? tournament.startDate.split('T')[0] : '',
      endDate: tournament.endDate ? tournament.endDate.split('T')[0] : ''
    };
    error = '';
    showForm = true;
  }

  function closeModal() {
    showForm = false;
    editing = null;
    error = '';
  }

  async function toggleInactive() {
    showInactive = !showInactive;
    await fetchTournaments();
  }

  async function save() {
    error = '';
    notice = '';
    if (!form.name.trim()) { error = 'Ingresa el nombre del torneo.'; return; }
    if (!form.leagueId) { error = 'Selecciona una liga.'; return; }
    saving = true;
    const payload: Record<string, unknown> = {
      name: form.name.trim(),
      year: Number(form.year),
      gender: form.gender,
      championMode: form.championMode,
      pointsWin: Number(form.pointsWin),
      pointsDraw: Number(form.pointsDraw),
      pointsLoss: Number(form.pointsLoss),
      leagueId: Number(form.leagueId),
      startDate: form.startDate || undefined,
      endDate: form.endDate || undefined
    };
    try {
      if (editing) {
        const updated = await updateTournament(editing.id, payload);
        tournaments = tournaments.map((t) => t.id === updated.id ? updated : t);
      } else {
        const created = await createTournament(payload);
        tournaments = [...tournaments, created];
      }
      notice = editing ? 'Torneo actualizado correctamente.' : 'Torneo creado correctamente.';
      editing = null;
      showForm = false;
      await fetchTournaments();
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo guardar el torneo.';
    } finally {
      saving = false;
    }
  }

  async function deleteTournament(tournament: Tournament) {
    if (!tournament || !confirm(`¿Eliminar el torneo "${tournament.name}"?`)) return;
    saving = true;
    try {
      await updateTournamentStatus(tournament.id, 'INACTIVE');
      notice = 'Torneo eliminado correctamente.';
      await fetchTournaments();
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo eliminar el torneo.';
    } finally {
      saving = false;
    }
  }

  async function fetchTournaments() {
    loading = true; error = '';
    try {
      tournaments = await getTournaments(showInactive);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar los torneos.';
    } finally { loading = false; }
  }
</script>

<svelte:head><title>Torneos | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div>
      <p class="eyebrow">Competencia</p>
      <h1>Torneos</h1>
      <p class="muted">Crea y administra los torneos de cada liga.</p>
    </div>
  </header>

  {#if loading}
    <section class="loading-card">Cargando torneos...</section>
  {:else}
    {#if error && !showForm}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}

    <section class="tournament-list card-surface">
      <div class="filter-bar">
        <button class="button secondary" onclick={() => showFilters = !showFilters} aria-label="Filtros">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="4" y1="21" x2="4" y2="14"/><line x1="4" y1="10" x2="4" y2="3"/><line x1="12" y1="21" x2="12" y2="12"/><line x1="12" y1="8" x2="12" y2="3"/><line x1="20" y1="21" x2="20" y2="16"/><line x1="20" y1="12" x2="20" y2="3"/><line x1="1" y1="14" x2="7" y2="14"/><line x1="9" y1="8" x2="15" y2="8"/><line x1="17" y1="16" x2="23" y2="16"/></svg>
          {showFilters ? 'Ocultar filtros' : 'Filtros'}
        </button>
        {#if canManage}<button class="button primary" onclick={openCreate}>Agregar torneo</button>{/if}
        <span class="count-pill">{tournaments.length}</span>
      </div>
      {#if showFilters}
        <div class="filter-row">
          <label class="checkbox-label"><input type="checkbox" bind:checked={showInactive} onchange={toggleInactive} /> Incluir inactivos</label>
        </div>
      {/if}

      {#if tournaments.length === 0}
        <div class="empty-state compact-empty">
          <h2>Sin torneos todavía</h2>
          <p>Crea el primer torneo para comenzar.</p>
        </div>
      {:else}
        <div class="league-table">
          {#each tournaments as tournament}
            <article class="league-row">
              <span class="league-color tournament-color">{tournament.name.slice(0, 2).toUpperCase()}</span>
              <div class="league-info">
                <strong>{tournament.name}</strong>
                <span>{tournament.league.name} · {tournament.year} · {genders.find(([value]) => value === tournament.gender)?.[1] ?? tournament.gender}</span>
              </div>
              <span class={statusClasses[tournament.status] ?? 'badge-muted'}>{statusLabels[tournament.status] ?? tournament.status}</span>
              {#if canManage}<button class="icon-button" onclick={() => openEdit(tournament)} aria-label={`Editar ${tournament.name}`}>Editar</button>{/if}
            </article>
          {/each}
        </div>
      {/if}
    </section>
  {/if}

  {#if showForm && canManage}
    <Modal onclose={closeModal}>
      <p class="eyebrow">{editing ? 'Editar torneo' : 'Nuevo torneo'}</p>
      <h2>{editing ? editing.name : 'Crear torneo'}</h2>
      {#if error}<p class="form-error">{error}</p>{/if}
      <form onsubmit={(event) => { event.preventDefault(); save(); }}>
        <label>Liga
          <select bind:value={form.leagueId} disabled={saving}>
            <option value="">Seleccionar liga...</option>
            {#each leagues as league}
              <option value={league.id}>{league.name}</option>
            {/each}
          </select>
        </label>
        <label>Nombre<input bind:value={form.name} placeholder="Torneo Apertura 2026" disabled={saving} /></label>
        <label>Año<input type="number" bind:value={form.year} disabled={saving} /></label>
        <label>Género
          <select bind:value={form.gender} disabled={saving}>
            {#each genders as [value, label]}<option value={value}>{label}</option>{/each}
          </select>
        </label>
        <label>Modo de campeón
          <select bind:value={form.championMode} disabled={saving}>
            {#each championModes as [value, label]}<option value={value}>{label}</option>{/each}
          </select>
        </label>
        <div class="form-row">
          <label>Pts Victoria<input type="number" bind:value={form.pointsWin} disabled={saving} /></label>
          <label>Pts Empate<input type="number" bind:value={form.pointsDraw} disabled={saving} /></label>
          <label>Pts Derrota<input type="number" bind:value={form.pointsLoss} disabled={saving} /></label>
        </div>
        <label>Fecha de inicio<input type="date" bind:value={form.startDate} disabled={saving} /></label>
        <label>Fecha de fin<input type="date" bind:value={form.endDate} disabled={saving} /></label>
        <div class="form-actions">
          <button class="button primary" type="submit" disabled={saving}>{saving ? 'Guardando...' : editing ? 'Guardar cambios' : 'Crear torneo'}</button>
          {#if editing}<button class="button secondary" type="button" onclick={openCreate} disabled={saving}>Cancelar</button>{/if}
          {#if editing}<button class="button secondary" type="button" onclick={() => deleteTournament(editing!)} disabled={saving} style="color:var(--color-error);">Eliminar torneo</button>{/if}
        </div>
      </form>
    </Modal>
  {/if}
</main>

<style>
  .tournament-color { background: var(--league-color, var(--color-accent)); color: #fff; }
  .tournament-list { align-self: start; }
</style>
