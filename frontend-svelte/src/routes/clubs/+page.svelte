<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { getClubs, getProfile, createClub, updateClub, uploadClubLogo, canManageModule, type AuthUser, type Club, type PaginatedClubs } from '$lib/api';
  import Modal from '$lib/Modal.svelte';
  import { SlidersHorizontal } from '@lucide/svelte';

  let user: AuthUser | null = $state(null);
  let paginated: PaginatedClubs | null = $state(null);
  let loading = $state(true);
  let saving = $state(false);
  let error = $state('');
  let notice = $state('');
  let search = $state('');
  let debounce: ReturnType<typeof setTimeout> | null = null;
  let statusFilter = $state('');
  let page = $state(1);
  let editing: Club | null = $state(null);
  let showForm = $state(false);
  let showFilters = $state(false);
  let logoFile: File | null = $state(null);
  let form = $state({
    name: '', shortName: '', slug: '', primaryColor: '', secondaryColor: '',
    instagram: '', facebook: '', homeAddress: '', latitude: '', longitude: '', active: true
  });

  onMount(async () => { await fetchClubs(); });

  let canManage = $derived(canManageModule(user, 'CLUBES'));

  async function fetchClubs() {
    loading = true; error = '';
    try {
      if (!user) user = await getProfile().catch(() => null);
      paginated = await getClubs(search, statusFilter, page);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar los clubes.';
    } finally { loading = false; }
  }

  function onSearch() {
    if (debounce) clearTimeout(debounce);
    debounce = setTimeout(() => { page = 1; fetchClubs(); }, 300);
  }

  function slugify(value: string) {
    return value.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
  }

  function openCreate() {
    editing = null; showForm = true; error = ''; logoFile = null;
    form = { name: '', shortName: '', slug: '', primaryColor: '', secondaryColor: '', instagram: '', facebook: '', homeAddress: '', latitude: '', longitude: '', active: true };
  }

  function openEdit(club: Club, event: MouseEvent) {
    event.stopPropagation();
    editing = club; showForm = true; error = ''; logoFile = null;
    form = {
      name: club.name, shortName: club.shortName ?? '', slug: club.slug ?? '',
      primaryColor: club.primaryColor ?? '', secondaryColor: club.secondaryColor ?? '',
      instagram: club.instagramUrl ?? '', facebook: club.facebookUrl ?? '',
      homeAddress: club.homeAddress ?? '', latitude: club.latitude != null ? String(club.latitude) : '',
      longitude: club.longitude != null ? String(club.longitude) : '', active: club.active
    };
  }

  function closeModal() { showForm = false; editing = null; error = ''; logoFile = null; }

  function goToClub(slug: string) { goto(`/club/${slug}`); }

  function handleLogoFile(f: File | undefined) {
    if (!f) { logoFile = null; return; }
    const img = new Image();
    const url = URL.createObjectURL(f);
    img.onload = () => {
      URL.revokeObjectURL(url);
      if (img.width < 200 || img.height < 200 || img.width > 500 || img.height > 500) {
        error = `Dimensiones inválidas (${img.width}x${img.height}). El escudo debe medir entre 200x200 y 500x500 píxeles.`;
        logoFile = null;
        return;
      }
      logoFile = f;
      error = '';
    };
    img.onerror = () => { URL.revokeObjectURL(url); error = 'No se pudo leer la imagen.'; logoFile = null; };
    img.src = url;
  }

  async function save() {
    error = '';
    if (!form.name.trim()) { error = 'Ingresa el nombre del club.'; return; }
    saving = true;
    const payload: Record<string, unknown> = {
      name: form.name.trim(), shortName: form.shortName.trim() || undefined,
      slug: slugify(form.slug) || slugify(form.name),
      primaryColor: form.primaryColor.trim() || undefined,
      secondaryColor: form.secondaryColor.trim() || undefined,
      instagram: form.instagram.trim() || undefined,
      facebook: form.facebook.trim() || undefined,
      homeAddress: form.homeAddress.trim() || undefined,
      active: form.active
    };
    if (form.latitude.trim()) payload.latitude = Number(form.latitude);
    if (form.longitude.trim()) payload.longitude = Number(form.longitude);
    try {
      let savedClub: Club;
      if (editing) { savedClub = await updateClub(editing.id, payload); }
      else { savedClub = await createClub(payload); }
      if (logoFile) {
        try { await uploadClubLogo(savedClub.id, logoFile); }
        catch (logoErr) { notice = (logoErr instanceof Error ? logoErr.message : 'No se pudo subir el escudo.') + ' Los demás datos se guardaron correctamente.'; }
      }
      if (!notice) notice = editing ? 'Club actualizado correctamente.' : 'Club creado correctamente.';
      showForm = false; editing = null; logoFile = null;
      await fetchClubs();
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo guardar el club.';
    } finally { saving = false; }
  }
</script>

<svelte:head><title>Clubes | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div><p class="eyebrow">Entidades</p><h1>Clubes</h1><p class="muted">Administra los clubes afiliados, sus colores e información general.</p></div>
  </header>

  {#if loading && !paginated}
    <section class="loading-card">Cargando clubes...</section>
  {:else}
    {#if error && !showForm}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}

    <div class="filter-bar">
      <button class="button secondary" onclick={() => showFilters = !showFilters} aria-label="Filtros">
        <SlidersHorizontal size={16} strokeWidth={2} />
        {showFilters ? 'Ocultar filtros' : 'Filtros'}
      </button>
      <span class="count-pill">{paginated?.total ?? 0}</span>
      {#if canManage}<button class="button primary add-btn" onclick={openCreate} aria-label="Agregar club">+</button>{/if}
    </div>

    {#if showFilters}
      <div class="filter-row">
        <input type="text" bind:value={search} oninput={onSearch} placeholder="Buscar por nombre..." />
        <select bind:value={statusFilter} onchange={() => { page = 1; fetchClubs(); }}>
          <option value="">Todos</option>
          <option value="active">Activos</option>
          <option value="inactive">Inactivos</option>
        </select>
      </div>
    {/if}

    {#if paginated && paginated.data.length === 0}
      <div class="empty-state compact-empty"><h2>Sin clubes</h2><p>Crea el primer club para comenzar.</p></div>
    {:else if paginated}
      <div class="club-grid">
        {#each paginated.data as club}
          <!-- svelte-ignore a11y_click_events_have_key_events a11y_no_noninteractive_element_interactions -->
          <article class="club-card" onclick={() => goToClub(club.slug ?? '')}>
            {#if club.logoUrl}
              <img class="club-card-logo" src={club.logoUrl} alt={club.name} />
            {:else}
              <span class="club-card-avatar" style={club.primaryColor ? `--club-color: ${club.primaryColor}` : '--club-color: #0057b8'}>{club.name.slice(0, 2).toUpperCase()}</span>
            {/if}
            <div class="club-card-info">
              <strong>{club.name}</strong>
              {#if club.shortName}<span class="muted">{club.shortName}</span>{/if}
              {#if !club.active}<span class="inactive-badge">Inactivo</span>{/if}
            </div>
            {#if canManage}
              <button class="icon-button" onclick={(e) => openEdit(club, e)}>Editar</button>
            {/if}
          </article>
        {/each}
      </div>
      {#if paginated.total > 25}
        <div class="pagination">
          <span>{paginated.total} clubes</span>
          <div>
            <button class="button secondary" disabled={page <= 1} onclick={() => { page = Math.max(1, page - 1); fetchClubs(); }}>Anterior</button>
            <button class="button secondary" disabled={page * 25 >= paginated.total} onclick={() => { page++; fetchClubs(); }}>Siguiente</button>
          </div>
        </div>
      {/if}
    {/if}
  {/if}
</main>

{#if showForm}
  <Modal onclose={closeModal}>
    <div class="modal-form">
      <p class="eyebrow">{editing ? 'Editar club' : 'Nuevo club'}</p>
      <h2>{editing ? editing.name : 'Crear club'}</h2>
      {#if error}<p class="form-error">{error}</p>{/if}
      <form onsubmit={(event) => { event.preventDefault(); save(); }}>
        <label>Nombre<input bind:value={form.name} placeholder="Club Atlético..." disabled={saving} /></label>

        <div class="form-row-grid two">
          <label>Nombre corto<input bind:value={form.shortName} placeholder="CA..." disabled={saving} /></label>
          <label>Identificador<input bind:value={form.slug} placeholder="club-atletico" disabled={saving} /></label>
        </div>

        <div class="form-row-grid three">
          <label>Color principal<div class="color-input"><input type="color" bind:value={form.primaryColor} disabled={saving} /><input bind:value={form.primaryColor} placeholder="#0057b8" disabled={saving} /></div></label>
          <label>Color secundario<div class="color-input"><input type="color" bind:value={form.secondaryColor} disabled={saving} /><input bind:value={form.secondaryColor} placeholder="#ffffff" disabled={saving} /></div></label>
          <label>Escudo (200×200 – 500×500 px)
            <input type="file" accept="image/*" onchange={(e) => { handleLogoFile((e.target as HTMLInputElement).files?.[0]); }} disabled={saving} />
          </label>
        </div>

        <div class="form-row-grid two">
          <label>Instagram<input bind:value={form.instagram} placeholder="@club" disabled={saving} /></label>
          <label>Facebook<input bind:value={form.facebook} placeholder="@club" disabled={saving} /></label>
        </div>

        <label>Dirección<input bind:value={form.homeAddress} placeholder="Calle 123" disabled={saving} /></label>

        <div class="form-row-grid two">
          <label>Latitud<input bind:value={form.latitude} placeholder="-34.6037" disabled={saving} /></label>
          <label>Longitud<input bind:value={form.longitude} placeholder="-58.3816" disabled={saving} /></label>
        </div>

        <div class="form-row-grid two actions-row">
          <label class="checkbox-label"><input type="checkbox" bind:checked={form.active} disabled={saving} /> Club activo</label>
          <div class="form-actions">
            <button class="button primary" type="submit" disabled={saving}>{saving ? 'Guardando...' : editing ? 'Guardar cambios' : 'Crear club'}</button>
          </div>
        </div>
      </form>
    </div>
  </Modal>
{/if}

<style>
  .club-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: .75rem; }
  .club-card { display: flex; align-items: center; gap: .75rem; padding: 1rem; border: 1px solid var(--color-border); border-radius: 1rem; background: var(--color-surface); cursor: pointer; transition: border-color 150ms, box-shadow 150ms; }
  .club-card:hover { border-color: var(--color-accent); box-shadow: 0 4px 20px var(--color-shadow); }
  .club-card-logo, .club-card-avatar { width: 3rem; height: 3rem; border-radius: .75rem; flex-shrink: 0; }
  .club-card-logo { object-fit: cover; }
  .club-card-avatar { display: grid; place-items: center; color: #fff; background: var(--club-color); font-family: 'Space Grotesk', sans-serif; font-weight: 700; font-size: .9rem; }
  .club-card-info { flex: 1; min-width: 0; display: grid; gap: .15rem; }
  .club-card-info strong { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .club-card-info .muted { font-size: .78rem; }
  .modal-form h2 { margin: .5rem 0 1.5rem; font-family: 'Space Grotesk', sans-serif; font-size: 1.6rem; letter-spacing: -.04em; }
  .modal-form form { margin-top: 0; }
  input[type="file"] { padding: .6rem .8rem; font-size: .85rem; }
  .form-row-grid { display: grid; gap: .75rem 1.5rem; }
  .form-row-grid.two { grid-template-columns: 1fr 1fr; }
  .form-row-grid.three { grid-template-columns: 1fr 1fr 1fr; }
  .actions-row { align-items: center; }
  .actions-row .form-actions { justify-content: flex-end; }
  @media (max-width: 600px) {
    .form-row-grid.two, .form-row-grid.three { grid-template-columns: 1fr; }
  }
</style>
