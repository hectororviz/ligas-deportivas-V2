<script lang="ts">
  import { onMount } from 'svelte';
  import Modal from '$lib/Modal.svelte';
  import { getTournaments, getProfile, createTournament, updateTournament, updateTournamentStatus, deleteTournament, getLeagues, getCategories, type AuthUser, type Tournament, type League, type Category } from '$lib/api';

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

  interface FormCategory {
    categoryId: number;
    name: string;
    enabled: boolean;
    countsForGeneral: boolean;
    kickoffTime: string;
  }

  let user: AuthUser | null = $state(null);
  let tournaments: Tournament[] = $state([]);
  let leagues: League[] = $state([]);
  let allCategories: Category[] = $state([]);
  let loading = $state(true);
  let saving = $state(false);
  let error = $state('');
  let notice = $state('');
  let editing: Tournament | null = $state(null);
  let showInactive = $state(false);
  let showForm = $state(false);
  let showFilters = $state(false);
  let showCatPicker = $state(false);
  let canManage = $state(false);

  let showDeleteModal = $state(false);
  let deleteTarget: Tournament | null = $state(null);
  let deleteEmail = $state('');
  let deletePassword = $state('');
  let deleteError = $state('');
  let deleting = $state(false);
  let form = $state({
    leagueId: '', name: '', year: new Date().getFullYear(), gender: 'MASCULINO',
    championMode: 'ROUND_AND_ANNUAL', pointsWin: 3, pointsDraw: 1, pointsLoss: 0,
    startDate: '', endDate: '', controlsPlayers: true
  });
  let formCategories = $state<FormCategory[]>([]);
  let catPickerData = $state<FormCategory[]>([]);

  let catCount = $derived(formCategories.filter(c => c.enabled).length);

  onMount(async () => {
    try {
      const [u, l, cats] = await Promise.all([getProfile(), getLeagues(), getCategories()]);
      user = u; leagues = l; allCategories = cats;
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
      startDate: '', endDate: '', controlsPlayers: true
    };
    formCategories = allCategories.filter(c => c.active && c.gender === form.gender).map(c => ({
      categoryId: c.id, name: c.name, enabled: false, countsForGeneral: true, kickoffTime: ''
    }));
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
      endDate: tournament.endDate ? tournament.endDate.split('T')[0] : '',
      controlsPlayers: tournament.controlsPlayers ?? true
    };
    formCategories = allCategories.filter(c => c.active && c.gender === form.gender).map(c => ({
      categoryId: c.id, name: c.name, enabled: false, countsForGeneral: true, kickoffTime: ''
    }));
    loadExistingCategories(tournament.id);
    error = '';
    showForm = true;
  }

  async function loadExistingCategories(tournamentId: number) {
    try {
      const data = await fetch(`${import.meta.env.PUBLIC_API_BASE_URL || '/api/v1'}/tournaments/${tournamentId}/categories`, {
        headers: { Authorization: `Bearer ${localStorage.getItem('ligas.accessToken')}` }
      });
      const existing = await data.json() as any[];
      formCategories = formCategories.map(c => {
        const ex = existing.find((e: any) => e.categoryId === c.categoryId || e.category?.id === c.categoryId);
        return ex
          ? { ...c, enabled: ex.enabled ?? true, countsForGeneral: ex.countsForGeneral ?? true, kickoffTime: ex.kickoffTime || '' }
          : c;
      });
    } catch {}
  }

  function openCatPicker() {
    const genderCats = allCategories.filter(c => c.active && c.gender === form.gender).map(c => ({
      categoryId: c.id, name: c.name, enabled: false, countsForGeneral: true, kickoffTime: ''
    }));
    const existingById = new Map(formCategories.map(c => [c.categoryId, c]));
    catPickerData = genderCats.map(c => {
      const ex = existingById.get(c.categoryId);
      return ex || c;
    });
    showCatPicker = true;
  }

  function closeCatPicker() {
    showCatPicker = false;
  }

  function applyCatPicker() {
    formCategories = catPickerData.map(c => ({ ...c }));
    showCatPicker = false;
  }

  function toggleCatEnabled(idx: number) {
    catPickerData[idx].enabled = !catPickerData[idx].enabled;
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
    const enabledCats = formCategories.filter(c => c.enabled);
    if (enabledCats.length === 0) { error = 'Selecciona al menos una categoría.'; return; }

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
      endDate: form.endDate || undefined,
      controlsPlayers: form.controlsPlayers,
      categories: formCategories.map(c => ({
        categoryId: c.categoryId,
        enabled: c.enabled,
        countsForGeneral: c.countsForGeneral,
        kickoffTime: c.enabled ? (c.kickoffTime || undefined) : undefined
      }))
    };
    try {
      if (editing) await updateTournament(editing.id, payload);
      else await createTournament(payload);
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

  function openDeleteModal(tournament: Tournament) {
    deleteTarget = tournament;
    deleteEmail = '';
    deletePassword = '';
    deleteError = '';
    showDeleteModal = true;
  }

  async function confirmDeleteTournament() {
    if (!deleteTarget) return;
    if (!deleteEmail.trim() || !deletePassword) { deleteError = 'Ingresá tu usuario y contraseña.'; return; }
    deleting = true;
    deleteError = '';
    try {
      await deleteTournament(deleteTarget.id, deleteEmail.trim(), deletePassword);
      notice = `Torneo "${deleteTarget.name}" eliminado correctamente.`;
      showDeleteModal = false;
      deleteTarget = null;
      showForm = false;
      editing = null;
      await fetchTournaments();
    } catch (cause) {
      deleteError = cause instanceof Error ? cause.message : 'No se pudo eliminar el torneo.';
    } finally {
      deleting = false;
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
      <p class="muted">Crea y administra los torneos de cada liga, asigna categorias participantes.</p>
    </div>
  </header>

  {#if loading}
    <section class="loading-card">Cargando torneos...</section>
  {:else}
    {#if error && !showForm && !showCatPicker}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}

    <section class="tournament-list card-surface">
      <div class="filter-bar">
        <button class="button secondary" onclick={() => showFilters = !showFilters} aria-label="Filtros">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="4" y1="21" x2="4" y2="14"/><line x1="4" y1="10" x2="4" y2="3"/><line x1="12" y1="21" x2="12" y2="12"/><line x1="12" y1="8" x2="12" y2="3"/><line x1="20" y1="21" x2="20" y2="16"/><line x1="20" y1="12" x2="20" y2="3"/><line x1="1" y1="14" x2="7" y2="14"/><line x1="9" y1="8" x2="15" y2="8"/><line x1="17" y1="16" x2="23" y2="16"/></svg>
          {showFilters ? 'Ocultar filtros' : 'Filtros'}
        </button>
        <span class="count-pill">{tournaments.length}</span>
        {#if canManage}<button class="button primary add-btn" onclick={openCreate} aria-label="Agregar torneo">+</button>{/if}
      </div>
      {#if showFilters}
        <div class="filter-row">
          <label class="checkbox-label"><input type="checkbox" bind:checked={showInactive} onchange={toggleInactive} /> Incluir inactivos</label>
        </div>
      {/if}

      {#if tournaments.length === 0}
        <div class="empty-state compact-empty"><h2>Sin torneos todavia</h2><p>Crea el primer torneo para comenzar.</p></div>
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
</main>

{#if showForm && canManage}
  <Modal onclose={closeModal}>
    <div class="modal-form">
      <p class="eyebrow">{editing ? 'Editar torneo' : 'Nuevo torneo'}</p>
      <h2>{editing ? editing.name : 'Crear torneo'}</h2>
      {#if error}<p class="form-error">{error}</p>{/if}
      <form onsubmit={(event) => { event.preventDefault(); save(); }}>
        <div class="form-grid">
          <div class="form-col">
            <label>Liga
              <select bind:value={form.leagueId} disabled={saving}>
                <option value="">Seleccionar liga...</option>
                {#each leagues as league}<option value={league.id}>{league.name}</option>{/each}
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
          </div>
          <div class="form-col">
            <div class="form-row">
              <label>Pts Victoria<input type="number" bind:value={form.pointsWin} disabled={saving} /></label>
              <label>Pts Empate<input type="number" bind:value={form.pointsDraw} disabled={saving} /></label>
              <label>Pts Derrota<input type="number" bind:value={form.pointsLoss} disabled={saving} /></label>
            </div>
            <label>Fecha de inicio<input type="date" bind:value={form.startDate} disabled={saving} /></label>
            <label>Fecha de fin<input type="date" bind:value={form.endDate} disabled={saving} /></label>
            <label class="checkbox-label"><input type="checkbox" bind:checked={form.controlsPlayers} disabled={saving} /> Controlar jugadores</label>

            <div class="categories-section">
              <div style="display:flex;align-items:center;justify-content:space-between;gap:.5rem;">
                <label class="cat-label">Categorías ({catCount} seleccionadas)</label>
                <button type="button" class="button secondary small" disabled={!form.gender || saving} onclick={openCatPicker}>
                  Seleccionar
                </button>
              </div>
              {#if catCount > 0}
                <div class="cat-tags">
                  {#each formCategories.filter(c => c.enabled) as c}
                    <span class="cat-tag">{c.name}</span>
                  {/each}
                </div>
              {/if}
            </div>
          </div>
        </div>
        <div class="form-actions">
          <button class="button primary" type="submit" disabled={saving}>{saving ? 'Guardando...' : editing ? 'Guardar cambios' : 'Crear torneo'}</button>
          {#if editing}<button class="button secondary" type="button" onclick={openCreate} disabled={saving}>Cancelar</button>{/if}
          {#if editing}<button class="button secondary" type="button" onclick={() => openDeleteModal(editing!)} disabled={saving} style="color:var(--color-error);">Eliminar torneo</button>{/if}
        </div>
      </form>
    </div>
  </Modal>
{/if}

{#if showCatPicker}
  <Modal onclose={closeCatPicker}>
    <div class="modal-form cat-picker-modal">
      <p class="eyebrow">Categorías</p>
      <h2>Seleccionar categorías</h2>
      <p class="muted">Categorías que coinciden con el género <strong>{genders.find(([v]) => v === form.gender)?.[1] ?? form.gender}</strong>.{form.gender === 'MIXTO' ? ' Se muestran todas las categorías.' : ''}</p>

      <div class="cat-table-wrapper">
        <table class="cat-table">
          <thead>
            <tr>
              <th style="width:50px">Act.</th>
              <th>Nombre</th>
              <th style="width:90px">Promocional</th>
              <th style="width:100px">Horario</th>
            </tr>
          </thead>
          <tbody>
            {#each catPickerData as cat, i}
              <tr class:cat-enabled={cat.enabled}>
                <td class="td-center">
                  <input type="checkbox" checked={cat.enabled} onchange={() => toggleCatEnabled(i)} />
                </td>
                <td>{cat.name}</td>
                <td class="td-center">
                  <input type="checkbox" checked={!cat.countsForGeneral} disabled={!cat.enabled} title="Promocional: no suma puntos para la tabla general"
                    onchange={() => catPickerData[i].countsForGeneral = !catPickerData[i].countsForGeneral} />
                </td>
                <td>
                  <input type="time" bind:value={catPickerData[i].kickoffTime} disabled={!cat.enabled} style="width:100%;font-size:.82rem;padding:.25rem .35rem;" />
                </td>
              </tr>
            {/each}
          </tbody>
        </table>
      </div>
      {#if catPickerData.length === 0}
        <p class="muted" style="text-align:center;padding:2rem;">No hay categorías activas para este género. Crea categorías antes de continuar.</p>
      {/if}

      <div class="form-actions" style="margin-top:1rem;">
        <button class="button secondary" type="button" onclick={closeCatPicker}>Cancelar</button>
        <button class="button primary" type="button" onclick={applyCatPicker}>Aceptar</button>
      </div>
    </div>
  </Modal>
{/if}

{#if showDeleteModal && deleteTarget}
  <Modal onclose={() => { if (!deleting) showDeleteModal = false; }}>
    <div class="modal-form delete-modal">
      <p class="eyebrow">Eliminar torneo</p>
      <h2>{deleteTarget.name}</h2>
      <p class="muted">Esta acción eliminará el torneo y <strong>todos</strong> sus datos: zonas, clubes asignados, partidos, fixture, goles y resultados. No se puede deshacer.</p>
      {#if deleteError}<p class="form-error">{deleteError}</p>{/if}
      <form onsubmit={(event) => { event.preventDefault(); confirmDeleteTournament(); }}>
        <label>Usuario (email)<input type="email" bind:value={deleteEmail} placeholder="admin@example.com" disabled={deleting} autocomplete="username" /></label>
        <label>Contraseña<input type="password" bind:value={deletePassword} placeholder="••••••••" disabled={deleting} autocomplete="current-password" /></label>
        <div class="form-actions">
          <button class="button secondary" type="button" disabled={deleting} onclick={() => showDeleteModal = false}>Cancelar</button>
          <button class="button primary" type="submit" disabled={deleting} style="background:var(--color-error);color:#fff;">{deleting ? 'Eliminando...' : 'Eliminar definitivamente'}</button>
        </div>
      </form>
    </div>
  </Modal>
{/if}

<style>
  .tournament-color { background: var(--league-color, var(--color-accent)); color: #fff; }
  .tournament-list { align-self: start; }

  .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 0 1.5rem; align-items: start; }
  .form-grid label { display: block; margin-bottom: .75rem; }
  .form-grid label:last-child { margin-bottom: 0; }
  .form-col { display: flex; flex-direction: column; }

  .categories-section { margin-top: .5rem; padding-top: .75rem; border-top: 1px solid var(--color-border); }
  .cat-label { font-size: .78rem; font-weight: 600; color: var(--color-text-muted); text-transform: uppercase; margin: 0; }
  .cat-tags { display: flex; flex-wrap: wrap; gap: .3rem; margin-top: .4rem; }
  .cat-tag {
    padding: .2rem .55rem; border-radius: 999px; font-size: .72rem; font-weight: 600;
    background: var(--color-accent-bg); color: var(--color-accent-text);
  }

  .cat-picker-modal { max-width: 620px !important; }

  .cat-table-wrapper { max-height: 50vh; overflow-y: auto; border: 1px solid var(--color-border); border-radius: .6rem; margin: .5rem 0; }
  .cat-table { width: 100%; border-collapse: collapse; font-size: .84rem; }
  .cat-table th {
    background: var(--color-surface-hover); color: var(--color-text-muted);
    font-size: .7rem; font-weight: 700; text-transform: uppercase; letter-spacing: .04em;
    padding: .5rem .6rem; text-align: left; position: sticky; top: 0; z-index: 1;
    border-bottom: 1px solid var(--color-border);
  }
  .cat-table td { padding: .45rem .6rem; border-bottom: 1px solid var(--color-border); }
  .cat-table tbody tr:hover { background: var(--color-surface-hover); }
  .cat-table tbody tr.cat-enabled { background: var(--color-accent-bg); }
  .td-center { text-align: center; }

  .button.small { padding: .35rem .65rem; font-size: .78rem; }

  .delete-modal { max-width: 460px; }
  .delete-modal h2 { margin: .4rem 0 .5rem; font-family: 'Space Grotesk', sans-serif; font-size: 1.4rem; letter-spacing: -.03em; }
  .delete-modal .muted { margin: 0 0 1rem; }
  .delete-modal .muted strong { color: var(--color-error); }

  @media (max-width: 600px) {
    .form-grid { grid-template-columns: 1fr; }
    .form-col { gap: 0; }
  }
</style>
