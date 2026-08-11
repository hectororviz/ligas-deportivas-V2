<script lang="ts">
  import { getPlayers, getProfile, createPlayer, updatePlayer, type AuthUser, type Player, type PaginatedPlayers } from '$lib/api';
  import Modal from '$lib/Modal.svelte';

  let user: AuthUser | null = $state(null);
  let paginated: PaginatedPlayers | null = $state(null);
  let loading = $state(true);
  let saving = $state(false);
  let error = $state('');
  let notice = $state('');
  let search = $state('');
  let debounce: ReturnType<typeof setTimeout> | null = null;
  let page = $state(1);
  let editing: Player | null = $state(null);
  let showForm = $state(false);
  let form = $state({
    firstName: '', lastName: '', dni: '', birthDate: '', gender: 'MASCULINO', active: true,
    addressStreet: '', addressNumber: '', addressCity: '',
    emergencyName: '', emergencyRelationship: '', emergencyPhone: ''
  });

  let canManage = $derived(((user as AuthUser | null)?.roles ?? []).includes('ADMIN'));

  $effect(() => { fetchPlayers(); });

  async function fetchPlayers() {
    loading = true; error = '';
    try {
      if (!user) user = await getProfile();
      paginated = await getPlayers(search, page);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar los jugadores.';
    } finally { loading = false; }
  }

  function onSearch() {
    if (debounce) clearTimeout(debounce);
    debounce = setTimeout(() => { page = 1; fetchPlayers(); }, 300);
  }

  function openCreate() {
    editing = null; showForm = true; error = '';
    form = {
      firstName: '', lastName: '', dni: '', birthDate: '', gender: 'MASCULINO', active: true,
      addressStreet: '', addressNumber: '', addressCity: '',
      emergencyName: '', emergencyRelationship: '', emergencyPhone: ''
    };
  }

  function openEdit(player: Player) {
    editing = player; showForm = true; error = '';
    form = {
      firstName: player.firstName,
      lastName: player.lastName,
      dni: player.dni,
      birthDate: player.birthDate ? player.birthDate.split('T')[0] : '',
      gender: player.gender,
      active: player.active,
      addressStreet: player.addressStreet ?? '',
      addressNumber: player.addressNumber ?? '',
      addressCity: player.addressCity ?? '',
      emergencyName: player.emergencyName ?? '',
      emergencyRelationship: player.emergencyRelationship ?? '',
      emergencyPhone: player.emergencyPhone ?? ''
    };
  }

  function closeModal() { showForm = false; editing = null; error = ''; }

  async function save() {
    error = '';
    if (!form.firstName.trim()) { error = 'Ingresa el nombre del jugador.'; return; }
    if (!form.lastName.trim()) { error = 'Ingresa el apellido del jugador.'; return; }
    if (!form.dni.trim()) { error = 'Ingresa el DNI del jugador.'; return; }
    saving = true;
    const payload: Record<string, unknown> = {
      firstName: form.firstName.trim(),
      lastName: form.lastName.trim(),
      dni: form.dni.trim(),
      birthDate: form.birthDate || undefined,
      gender: form.gender,
      active: form.active,
      addressStreet: form.addressStreet.trim() || undefined,
      addressNumber: form.addressNumber.trim() || undefined,
      addressCity: form.addressCity.trim() || undefined,
      emergencyName: form.emergencyName.trim() || undefined,
      emergencyRelationship: form.emergencyRelationship.trim() || undefined,
      emergencyPhone: form.emergencyPhone.trim() || undefined
    };
    try {
      if (editing) await updatePlayer(editing.id, payload);
      else await createPlayer(payload);
      notice = editing ? 'Jugador actualizado correctamente.' : 'Jugador creado correctamente.';
      showForm = false; editing = null;
      await fetchPlayers();
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo guardar el jugador.';
    } finally { saving = false; }
  }

  function birthYear(dateStr: string): string {
    if (!dateStr) return '—';
    return dateStr.split('-')[0] ?? '—';
  }

  function initials(player: Player): string {
    return `${player.firstName[0] ?? ''}${player.lastName[0] ?? ''}`.toUpperCase();
  }

  function genderLabel(g: string): string {
    return g === 'MASCULINO' ? 'Masculino' : g === 'FEMENINO' ? 'Femenino' : g;
  }
</script>

<svelte:head><title>Jugadores | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div>
      <p class="eyebrow">Personas</p>
      <h1>Jugadores</h1>
      <p class="muted">Administra los jugadores, sus datos personales y contactos de emergencia.</p>
    </div>
  </header>

  {#if loading && !paginated}
    <section class="loading-card">Cargando jugadores...</section>
  {:else}
    {#if error && !showForm}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}

    <section class="card-surface">
      <div class="search-bar">
        <input type="text" bind:value={search} oninput={onSearch} placeholder="Buscar por nombre o DNI..." />
        {#if canManage}<button class="button primary" onclick={openCreate}>Agregar jugador</button>{/if}
      </div>

      {#if paginated && paginated.data.length === 0}
        <div class="empty-state compact-empty"><h2>Sin jugadores</h2><p>Crea el primer jugador para comenzar.</p></div>
      {:else if paginated}
        <div class="club-table">
          {#each paginated.data as player}
            <article class="club-row">
              <span class="club-color">{initials(player)}</span>
              <div class="club-info">
                <div class="club-name-row">
                  <strong>{player.firstName} {player.lastName}</strong>
                  {#if !player.active}<span class="inactive-badge">Inactivo</span>{/if}
                </div>
                <span>DNI {player.dni} · Nac. {birthYear(player.birthDate)} · {genderLabel(player.gender)}</span>
              </div>
              {#if canManage}<button class="icon-button" onclick={() => openEdit(player)}>Editar</button>{/if}
            </article>
          {/each}
        </div>
        {#if paginated.total > 25}
          <div class="pagination">
            <span>{paginated.total} jugadores</span>
            <div>
              <button class="button secondary" disabled={page <= 1} onclick={() => { page = Math.max(1, page - 1); fetchPlayers(); }}>Anterior</button>
              <button class="button secondary" disabled={page * 25 >= paginated.total} onclick={() => { page++; fetchPlayers(); }}>Siguiente</button>
            </div>
          </div>
        {/if}
      {/if}
    </section>
  {/if}
</main>

{#if showForm}
  <Modal onclose={closeModal}>
    <div class="modal-form">
      <p class="eyebrow">{editing ? 'Editar jugador' : 'Nuevo jugador'}</p>
      <h2>{editing ? `${editing.firstName} ${editing.lastName}` : 'Crear jugador'}</h2>
      {#if error}<p class="form-error">{error}</p>{/if}
      <form onsubmit={(event) => { event.preventDefault(); save(); }}>
        <label>Nombre<input bind:value={form.firstName} placeholder="Juan" disabled={saving} /></label>
        <label>Apellido<input bind:value={form.lastName} placeholder="Pérez" disabled={saving} /></label>
        <label>DNI<input bind:value={form.dni} placeholder="12345678" disabled={saving} /></label>
        <div class="form-row">
          <label>Fecha de nacimiento<input type="date" bind:value={form.birthDate} disabled={saving} /></label>
          <label>Género<select bind:value={form.gender} disabled={saving}><option value="MASCULINO">Masculino</option><option value="FEMENINO">Femenino</option></select></label>
        </div>
        <label class="checkbox-label"><input type="checkbox" bind:checked={form.active} disabled={saving} /> Jugador activo</label>

        <h3>Dirección</h3>
        <label>Calle<input bind:value={form.addressStreet} placeholder="Av. Siempre Viva" disabled={saving} /></label>
        <div class="form-row">
          <label>Número<input bind:value={form.addressNumber} placeholder="742" disabled={saving} /></label>
          <label>Ciudad<input bind:value={form.addressCity} placeholder="Springfield" disabled={saving} /></label>
        </div>

        <h3>Contacto de emergencia</h3>
        <label>Nombre<input bind:value={form.emergencyName} placeholder="María Pérez" disabled={saving} /></label>
        <div class="form-row">
          <label>Parentesco<input bind:value={form.emergencyRelationship} placeholder="Madre" disabled={saving} /></label>
          <label>Teléfono<input bind:value={form.emergencyPhone} placeholder="+549..." disabled={saving} /></label>
        </div>

        <div class="form-actions"><button class="button primary" type="submit" disabled={saving}>{saving ? 'Guardando...' : editing ? 'Guardar cambios' : 'Crear jugador'}</button></div>
      </form>
    </div>
  </Modal>
{/if}

<style>
  .modal-form h2 { margin: .5rem 0 1.5rem; font-family: 'Space Grotesk', sans-serif; font-size: 1.6rem; letter-spacing: -.04em; }
  .modal-form h3 { margin: 1.5rem 0 .75rem; font-family: 'Space Grotesk', sans-serif; font-size: 1.05rem; color: var(--color-text-muted); }
  .modal-form form { margin-top: 0; }
</style>
