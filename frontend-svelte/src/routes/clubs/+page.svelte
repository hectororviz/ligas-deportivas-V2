<script lang="ts">
  import { onMount } from 'svelte';
  import { getClubs, getProfile, createClub, updateClub, type AuthUser, type Club, type PaginatedClubs } from '$lib/api';

  let user: AuthUser | null = null;
  let paginated: PaginatedClubs | null = null;
  let loading = true;
  let saving = false;
  let error = '';
  let notice = '';
  let search = '';
  let debounce: ReturnType<typeof setTimeout> | null = null;
  let statusFilter = '';
  let page = 1;
  let editing: Club | null = null;
  let form = {
    name: '', shortName: '', slug: '', leagueId: '', primaryColor: '', secondaryColor: '',
    instagram: '', facebook: '', homeAddress: '', latitude: '', longitude: '', active: true
  };

  onMount(async () => { await fetchClubs(); });

  $: canManage = user?.roles.includes('ADMIN') ?? false;

  async function fetchClubs() {
    loading = true;
    error = '';
    try {
      if (!user) user = await getProfile();
      paginated = await getClubs(search, statusFilter, page);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar los clubes.';
    } finally {
      loading = false;
    }
  }

  function onSearch() {
    if (debounce) clearTimeout(debounce);
    debounce = setTimeout(() => { page = 1; fetchClubs(); }, 300);
  }

  function slugify(value: string) {
    return value.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
  }

  function openCreate() {
    editing = null;
    form = { name: '', shortName: '', slug: '', leagueId: '', primaryColor: '', secondaryColor: '', instagram: '', facebook: '', homeAddress: '', latitude: '', longitude: '', active: true };
    error = '';
    notice = '';
  }

  function openEdit(club: Club) {
    editing = club;
    form = {
      name: club.name, shortName: club.shortName ?? '', slug: club.slug ?? '',
      leagueId: '', primaryColor: club.primaryColor ?? '', secondaryColor: club.secondaryColor ?? '',
      instagram: club.instagramUrl ?? '', facebook: club.facebookUrl ?? '',
      homeAddress: club.homeAddress ?? '', latitude: club.latitude != null ? String(club.latitude) : '',
      longitude: club.longitude != null ? String(club.longitude) : '', active: club.active
    };
    error = '';
    notice = '';
  }

  async function save() {
    error = '';
    notice = '';
    if (!form.name.trim()) { error = 'Ingresa el nombre del club.'; return; }
    saving = true;
    const payload: Record<string, unknown> = {
      name: form.name.trim(),
      shortName: form.shortName.trim() || undefined,
      slug: form.slug.trim() || slugify(form.name),
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
      if (editing) await updateClub(editing.id, payload);
      else await createClub(payload);
      notice = editing ? 'Club actualizado correctamente.' : 'Club creado correctamente.';
      editing = null;
      await fetchClubs();
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo guardar el club.';
    } finally {
      saving = false;
    }
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
    {#if error}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}

    <div class="clubs-layout">
      <section class="club-list card-surface">
        <div class="search-bar">
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
                <span class="club-color" style={club.primaryColor ? `--club-color: ${club.primaryColor}` : '--club-color: #0057b8'}>{club.name.slice(0, 2).toUpperCase()}</span>
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

      {#if canManage && (editing || !editing) && !notice}
        <section class="form-card card-surface">
          <p class="eyebrow">{editing ? 'Editar club' : 'Nuevo club'}</p>
          <h2>{editing ? editing.name : 'Crear club'}</h2>
          <form onsubmit={(event) => { event.preventDefault(); save(); }}>
            <label>Nombre<input bind:value={form.name} placeholder="Club Atlético..." disabled={saving} /></label>
            <label>Nombre corto<input bind:value={form.shortName} placeholder="CA..." disabled={saving} /></label>
            <label>Identificador<input bind:value={form.slug} placeholder="club-atletico" disabled={saving} /></label>
            <label>Color principal<div class="color-input"><input type="color" bind:value={form.primaryColor} disabled={saving} /><input bind:value={form.primaryColor} placeholder="#0057b8" disabled={saving} /></div></label>
            <label>Color secundario<div class="color-input"><input type="color" bind:value={form.secondaryColor} disabled={saving} /><input bind:value={form.secondaryColor} placeholder="#ffffff" disabled={saving} /></div></label>
            <label>Instagram<input bind:value={form.instagram} placeholder="@club" disabled={saving} /></label>
            <label>Facebook<input bind:value={form.facebook} placeholder="@club" disabled={saving} /></label>
            <label>Dirección<input bind:value={form.homeAddress} placeholder="Calle 123" disabled={saving} /></label>
            <div class="form-row">
              <label>Latitud<input bind:value={form.latitude} placeholder="-34.6037" disabled={saving} /></label>
              <label>Longitud<input bind:value={form.longitude} placeholder="-58.3816" disabled={saving} /></label>
            </div>
            <label class="checkbox-label"><input type="checkbox" bind:checked={form.active} disabled={saving} /> Club activo</label>
            <div class="form-actions"><button class="button primary" type="submit" disabled={saving}>{saving ? 'Guardando...' : editing ? 'Guardar cambios' : 'Crear club'}</button>{#if editing}<button class="button secondary" type="button" onclick={openCreate} disabled={saving}>Cancelar</button>{/if}</div>
          </form>
        </section>
      {/if}
    </div>
  {/if}
</main>
