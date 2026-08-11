<script lang="ts">
  import { onMount } from 'svelte';
  import { getClubs, getProfile, createClub, updateClub, uploadClubLogo, type AuthUser, type Club, type PaginatedClubs } from '$lib/api';
  import Modal from '$lib/Modal.svelte';

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
  let logoFile: File | null = $state(null);
  let form = $state({
    name: '', shortName: '', slug: '', primaryColor: '', secondaryColor: '',
    instagram: '', facebook: '', homeAddress: '', latitude: '', longitude: '', active: true
  });

  onMount(async () => { await fetchClubs(); });

  let canManage = $derived(((user as AuthUser | null)?.roles ?? []).includes('ADMIN'));

  async function fetchClubs() {
    loading = true; error = '';
    try {
      if (!user) user = await getProfile();
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

  function openEdit(club: Club) {
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
      if (editing) {
        savedClub = await updateClub(editing.id, payload);
        if (logoFile) await uploadClubLogo(editing.id, logoFile);
      } else {
        savedClub = await createClub(payload);
        if (logoFile) await uploadClubLogo(savedClub.id, logoFile);
      }
      notice = editing ? 'Club actualizado correctamente.' : 'Club creado correctamente.';
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
    <a class="button secondary" href="/">Volver al panel</a>
  </header>

  {#if loading && !paginated}
    <section class="loading-card">Cargando clubes...</section>
  {:else}
    {#if error && !showForm}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}

    <section class="card-surface" style="padding: 1.5rem;">
      <div class="search-bar" style="margin-bottom: 0;">
        <input type="text" bind:value={search} oninput={onSearch} placeholder="Buscar por nombre..." />
        <select bind:value={statusFilter} onchange={() => { page = 1; fetchClubs(); }}>
          <option value="">Todos</option>
          <option value="active">Activos</option>
          <option value="inactive">Inactivos</option>
        </select>
        {#if canManage}<button class="button primary" onclick={openCreate}>Agregar club</button>{/if}
      </div>

      {#if paginated && paginated.data.length === 0}
        <div class="empty-state compact-empty"><h2>Sin clubes</h2><p>Crea el primer club para comenzar.</p></div>
      {:else if paginated}
        <div class="club-table">
          {#each paginated.data as club}
            <article class="club-row">
              {#if club.logoUrl}
                <img class="club-logo" src={club.logoUrl} alt={club.name} />
              {:else}
                <span class="club-color" style={club.primaryColor ? `--club-color: ${club.primaryColor}` : '--club-color: #0057b8'}>{club.name.slice(0, 2).toUpperCase()}</span>
              {/if}
              <div class="club-info">
                <div class="club-name-row"><strong>{club.name}</strong>{#if !club.active}<span class="inactive-badge">Inactivo</span>{/if}</div>
                {#if club.slug || club.league}<span>{[club.slug, club.league?.name].filter(Boolean).join(' · ')}</span>{/if}
              </div>
              {#if canManage}<button class="icon-button" onclick={() => openEdit(club)}>Editar</button>{/if}
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
    </section>
  {/if}
</main>

{#if showForm}
  <Modal onclose={closeModal}>
    <div class="modal-form" style="padding-right: 0.5rem;">
      <p class="eyebrow">{editing ? 'Editar club' : 'Nuevo club'}</p>
      <h2>{editing ? editing.name : 'Crear club'}</h2>
      {#if error}<p class="form-error">{error}</p>{/if}
      <form onsubmit={(event) => { event.preventDefault(); save(); }}>
        <label>Nombre<input bind:value={form.name} placeholder="Club Atlético..." disabled={saving} /></label>
        <label>Nombre corto<input bind:value={form.shortName} placeholder="CA..." disabled={saving} /></label>
        <label>Identificador<input bind:value={form.slug} placeholder="club-atletico" disabled={saving} /></label>
        <div class="form-row">
          <label>Color principal<div class="color-input"><input type="color" bind:value={form.primaryColor} disabled={saving} /><input bind:value={form.primaryColor} placeholder="#0057b8" disabled={saving} /></div></label>
          <label>Color secundario<div class="color-input"><input type="color" bind:value={form.secondaryColor} disabled={saving} /><input bind:value={form.secondaryColor} placeholder="#ffffff" disabled={saving} /></div></label>
        </div>
        <label>Escudo
          <input type="file" accept="image/*" onchange={(e) => { const f = (e.target as HTMLInputElement).files?.[0]; if (f) logoFile = f; }} disabled={saving} />
        </label>
        <label>Instagram<input bind:value={form.instagram} placeholder="@club" disabled={saving} /></label>
        <label>Facebook<input bind:value={form.facebook} placeholder="@club" disabled={saving} /></label>
        <label>Dirección<input bind:value={form.homeAddress} placeholder="Calle 123" disabled={saving} /></label>
        <div class="form-row">
          <label>Latitud<input bind:value={form.latitude} placeholder="-34.6037" disabled={saving} /></label>
          <label>Longitud<input bind:value={form.longitude} placeholder="-58.3816" disabled={saving} /></label>
        </div>
        <label class="checkbox-label"><input type="checkbox" bind:checked={form.active} disabled={saving} /> Club activo</label>
        <div class="form-actions"><button class="button primary" type="submit" disabled={saving}>{saving ? 'Guardando...' : editing ? 'Guardar cambios' : 'Crear club'}</button></div>
      </form>
    </div>
  </Modal>
{/if}

<style>
  .club-logo { width: 2.5rem; height: 2.5rem; border-radius: .75rem; object-fit: cover; flex: 0 0 auto; }
  .modal-form h2 { margin: .5rem 0 1.5rem; font-family: 'Space Grotesk', sans-serif; font-size: 1.6rem; letter-spacing: -.04em; }
  .modal-form form { margin-top: 0; }
  input[type="file"] { padding: .6rem .8rem; font-size: .85rem; }
</style>
