<script lang="ts">
  import { onMount } from 'svelte';
  import { getClubs, getProfile, createClub, uploadClubLogo, canManageModule, type AuthUser, type Club } from '$lib/api';
  import Modal from '$lib/Modal.svelte';
  import { Search, Plus } from '@lucide/svelte';

  let user: AuthUser | null = $state(null);
  let clubs: Club[] = $state([]);
  let total = $state(0);
  let loading = $state(true);
  let saving = $state(false);
  let error = $state('');
  let notice = $state('');
  let search = $state('');
  let showForm = $state(false);
  let logoFile: File | null = $state(null);
  let form = $state({
    name: '', shortName: '', slug: '', description: '', primaryColor: '', secondaryColor: '',
    instagram: '', facebook: '', homeAddress: '', latitude: '', longitude: '', active: true
  });

  onMount(async () => { await fetchClubs(); });

  let canManage = $derived(canManageModule(user, 'CLUBES'));

  let filteredClubs = $derived(
    search.trim() ? clubs.filter((club) => matchesClub(club, search)) : clubs
  );

  function normalize(value: string) {
    return value.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');
  }

  function matchesClub(club: Club, query: string) {
    const q = normalize(query.trim());
    if (!q) return true;
    if (normalize(club.name).includes(q)) return true;
    if (club.shortName && normalize(club.shortName).includes(q)) return true;
    return false;
  }

  function label(club: Club) {
    return club.shortName?.trim() || club.name;
  }

  function initials(club: Club) {
    const words = label(club).split(/\s+/).filter(Boolean);
    const letters = words.slice(0, 2).map((word) => word[0] ?? '').join('');
    return (letters || label(club).slice(0, 2)).toUpperCase();
  }

  async function fetchClubs() {
    loading = true; error = '';
    try {
      if (!user) user = await getProfile().catch(() => null);
      const first = await getClubs('', '', 1, 50);
      let all = first.data;
      let page = 2;
      while (all.length < first.total) {
        const next = await getClubs('', '', page, 50);
        if (next.data.length === 0) break;
        all = all.concat(next.data);
        page += 1;
      }
      clubs = all;
      total = all.length;
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar los clubes.';
    } finally { loading = false; }
  }

  function slugify(value: string) {
    return value.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
  }

  function openCreate() {
    showForm = true; error = ''; logoFile = null;
    form = { name: '', shortName: '', slug: '', description: '', primaryColor: '', secondaryColor: '', instagram: '', facebook: '', homeAddress: '', latitude: '', longitude: '', active: true };
  }

  function closeModal() { showForm = false; error = ''; logoFile = null; }

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
      description: form.description.trim() || undefined,
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
      const savedClub = await createClub(payload);
      if (logoFile) {
        try { await uploadClubLogo(savedClub.id, logoFile); }
        catch (logoErr) { notice = (logoErr instanceof Error ? logoErr.message : 'No se pudo subir el escudo.') + ' Los demás datos se guardaron correctamente.'; }
      }
      if (!notice) notice = 'Club creado correctamente.';
      showForm = false; logoFile = null;
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

  {#if loading && !clubs.length}
    <section class="loading-card">Cargando clubes...</section>
  {:else}
    {#if error}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}

    <div class="toolbar">
      <div class="search-wrap">
        <span class="search-icon" aria-hidden="true"><Search size={18} strokeWidth={2} /></span>
        <input type="search" bind:value={search} placeholder="Buscar club por nombre..." aria-label="Buscar club por nombre" />
      </div>
      <span class="club-count" aria-live="polite">
        {search.trim() ? `${filteredClubs.length} de ${total}` : `${total}`} {total === 1 ? 'club' : 'clubes'}
      </span>
      {#if canManage}
        <button class="button primary new-btn" onclick={openCreate} aria-label="Nuevo club">
          <Plus size={16} strokeWidth={2} />
          Nuevo club
        </button>
      {/if}
    </div>

    {#if filteredClubs.length === 0}
      <div class="empty-state compact-empty">
        {#if total === 0}
          <h2>Sin clubes</h2>
          <p>Creá el primer club para comenzar.</p>
        {:else}
          <h2>No encontramos clubes</h2>
          <p>Probá con otro nombre o término de búsqueda.</p>
        {/if}
      </div>
    {:else}
      <div class="club-grid">
        {#each filteredClubs as club (club.id)}
          <a class="club-card" href={`/club/${club.slug ?? ''}`} title={club.name} aria-label={club.name}>
            <span class="club-shield" style={club.primaryColor ? `--club-color: ${club.primaryColor}` : ''}>
              {#if club.logoUrl}
                <img src={club.logoUrl} alt={`Escudo de ${club.name}`} loading="lazy" />
              {:else}
                <span class="club-initials">{initials(club)}</span>
              {/if}
            </span>
            <span class="club-name">{label(club)}</span>
          </a>
        {/each}
      </div>
    {/if}
  {/if}
</main>

{#if showForm}
  <Modal onclose={closeModal}>
    <div class="modal-form">
      <p class="eyebrow">Nuevo club</p>
      <h2>Crear club</h2>
      {#if error}<p class="form-error">{error}</p>{/if}
      <form onsubmit={(event) => { event.preventDefault(); save(); }}>
        <label>Nombre<input bind:value={form.name} placeholder="Club Atlético..." disabled={saving} /></label>

        <label>Descripción / eslogan<textarea bind:value={form.description} placeholder="Pasión y trabajo en equipo..." rows="2" disabled={saving}></textarea></label>

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
            <button class="button primary" type="submit" disabled={saving}>{saving ? 'Guardando...' : 'Crear club'}</button>
          </div>
        </div>
      </form>
    </div>
  </Modal>
{/if}

<style>
  .toolbar { display: flex; align-items: center; gap: .75rem; flex-wrap: wrap; margin-bottom: 2rem; }

  .search-wrap { position: relative; flex: 1; min-width: 220px; }
  .search-icon { position: absolute; left: .9rem; top: 50%; transform: translateY(-50%); color: var(--color-text-light); pointer-events: none; }
  .search-wrap input { padding-left: 2.6rem; }

  .club-count { color: var(--color-text-muted); font-size: .9rem; font-weight: 600; white-space: nowrap; }
  .new-btn { display: inline-flex; align-items: center; gap: .45rem; white-space: nowrap; }

  .club-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: 1.5rem;
    max-width: 1280px;
    margin: 0 auto;
  }

  .club-card {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1rem;
    padding: 1.75rem 1rem 1.5rem;
    border-radius: 1.2rem;
    text-decoration: none;
    color: inherit;
    cursor: pointer;
    outline: none;
    transition: transform 180ms ease;
  }
  .club-card:hover, .club-card:focus-visible { transform: translateY(-4px); }
  .club-card:focus-visible { box-shadow: 0 0 0 3px color-mix(in srgb, var(--color-accent) 40%, transparent); }

  .club-shield {
    width: clamp(6.5rem, 9vw, 7.5rem);
    height: clamp(6.5rem, 9vw, 7.5rem);
    border-radius: 50%;
    display: grid;
    place-items: center;
    overflow: hidden;
    background: var(--color-surface);
    border: 1px solid var(--color-border);
    box-shadow: 0 8px 24px var(--color-shadow);
    transition: transform 200ms ease, box-shadow 200ms ease;
  }
  .club-card:hover .club-shield, .club-card:focus-visible .club-shield { transform: scale(1.08); box-shadow: 0 14px 32px var(--color-shadow); }
  .club-shield img { width: 100%; height: 100%; object-fit: cover; }
  .club-initials {
    width: 100%; height: 100%;
    display: grid; place-items: center;
    color: #fff;
    background: var(--club-color, var(--color-accent));
    font-family: 'Space Grotesk', sans-serif;
    font-weight: 700;
    font-size: clamp(1.5rem, 3vw, 1.9rem);
  }

  .club-name {
    display: block;
    max-width: 100%;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    font-weight: 600;
    font-size: .95rem;
    color: var(--color-text);
  }

  .modal-form h2 { margin: .5rem 0 1.5rem; font-family: 'Space Grotesk', sans-serif; font-size: 1.6rem; letter-spacing: -.04em; }
  .modal-form form { margin-top: 0; }
  input[type="file"] { padding: .6rem .8rem; font-size: .85rem; }
  .form-row-grid { display: grid; gap: .75rem 1.5rem; }
  .form-row-grid.two { grid-template-columns: 1fr 1fr; }
  .form-row-grid.three { grid-template-columns: 1fr 1fr 1fr; }
  .actions-row { align-items: center; }
  .actions-row .form-actions { justify-content: flex-end; }

  @media (max-width: 900px) {
    .club-grid { grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 1.25rem; }
  }
  @media (max-width: 600px) {
    .club-grid { grid-template-columns: repeat(2, 1fr); gap: 1rem; }
    .form-row-grid.two, .form-row-grid.three { grid-template-columns: 1fr; }
  }
</style>
