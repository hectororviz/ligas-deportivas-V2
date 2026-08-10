<script lang="ts">
  import { onMount } from 'svelte';
  import Modal from '$lib/Modal.svelte';
  import { getTournaments, getProfile, createTournament, updateTournament, getLeagues, type AuthUser, type Tournament, type League } from '$lib/api';

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

  let user: AuthUser | null = null;
  let tournaments: Tournament[] = [];
  let leagues: League[] = [];
  let loading = true;
  let saving = false;
  let error = '';
  let notice = '';
  let editing: Tournament | null = null;
  let showInactive = false;
  let showForm = false;
  let form = {
    leagueId: '', name: '', year: new Date().getFullYear(), gender: 'MASCULINO',
    championMode: 'ROUND_AND_ANNUAL', pointsWin: 3, pointsDraw: 1, pointsLoss: 0,
    startDate: '', endDate: ''
  };

  onMount(async () => {
    try {
      [user, tournaments, leagues] = await Promise.all([getProfile(), getTournaments(), getLeagues()]);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar los torneos.';
    } finally {
      loading = false;
    }
  });

  $: canManage = user?.roles.includes('ADMIN') ?? false;

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
    loading = true;
    error = '';
    try {
      tournaments = await getTournaments(showInactive);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar los torneos.';
    } finally {
      loading = false;
    }
  }

  async function save() {
    error = '';
    notice = '';
    if (!form.name.trim()) { error = 'Ingresa el nombre del torneo.'; return; }
    if (!form.leagueId) { error = 'Selecciona una liga.'; return; }
    saving = true;
    const payload: Record<string, unknown> = {
      name: form.name.trim(),
      year: form.year,
      gender: form.gender,
      championMode: form.championMode,
      pointsWin: form.pointsWin,
      pointsDraw: form.pointsDraw,
      pointsLoss: form.pointsLoss,
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
        tournaments = [...tournaments, created].sort((a, b) => new Date(b.startDate ?? '').getTime() - new Date(a.startDate ?? '').getTime());
      }
      notice = editing ? 'Torneo actualizado correctamente.' : 'Torneo creado correctamente.';
      editing = null;
      showForm = false;
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo guardar el torneo.';
    } finally {
      saving = false;
    }
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
    <div style="display:flex;align-items:center;gap:.6rem">
      {#if canManage}<button class="button primary" onclick={openCreate}>Agregar torneo</button>{/if}
      <a class="button secondary" href="/">Volver al panel</a>
    </div>
  </header>

  {#if loading}
    <section class="loading-card">Cargando torneos...</section>
  {:else}
    {#if error}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}

    <section class="tournament-list card-surface">
      <div class="list-header">
        <div><p class="eyebrow">Catálogo</p><h2>Torneos registrados</h2></div>
        <div style="display:flex;align-items:center;gap:.6rem">
          <label class="checkbox-label"><input type="checkbox" bind:checked={showInactive} onchange={toggleInactive} /> Incluir inactivos</label>
          <span class="count-pill">{tournaments.length}</span>
        </div>
      </div>

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
        </div>
      </form>
    </Modal>
  {/if}
</main>

<style>
  .tournament-color {
    background: var(--league-color, #527638);
    color: #fff;
  }

  .badge-muted {
    padding: .15rem .5rem;
    border-radius: 999px;
    color: #66736c;
    background: #e8eee4;
    font-size: .68rem;
    font-weight: 700;
    white-space: nowrap;
  }

  .badge-active {
    padding: .15rem .5rem;
    border-radius: 999px;
    color: #38622e;
    background: #e4edcf;
    font-size: .68rem;
    font-weight: 700;
    white-space: nowrap;
  }

  .badge-finished {
    padding: .15rem .5rem;
    border-radius: 999px;
    color: #527638;
    background: #d0e87c55;
    font-size: .68rem;
    font-weight: 700;
    white-space: nowrap;
  }

  .badge-cancelled {
    padding: .15rem .5rem;
    border-radius: 999px;
    color: #a43d36;
    background: #fff0ed;
    font-size: .68rem;
    font-weight: 700;
    white-space: nowrap;
  }

  .tournament-list {
    align-self: start;
  }
</style>
