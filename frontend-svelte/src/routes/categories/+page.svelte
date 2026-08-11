<script lang="ts">
  import { onMount } from 'svelte';
  import Modal from '$lib/Modal.svelte';
  import { getCategories, getProfile, createCategory, updateCategory, type AuthUser, type Category } from '$lib/api';

  const genders = [['MASCULINO', 'Masculino'], ['FEMENINO', 'Femenino'], ['MIXTO', 'Mixto']];

  let user: AuthUser | null = null;
  let categories: Category[] = [];
  let loading = true;
  let saving = false;
  let error = '';
  let notice = '';
  let editing: Category | null = null;
  let showForm = false;
  let form = {
    name: '', birthYearMin: 2010, birthYearMax: 2015, gender: 'MIXTO',
    minPlayers: 5, mandatory: false, promotional: false, active: true
  };

  onMount(async () => {
    try {
      [user, categories] = await Promise.all([getProfile(), getCategories()]);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar las categorías.';
    } finally {
      loading = false;
    }
  });

  $: canManage = user?.roles.includes('ADMIN') ?? false;

  function openCreate() {
    editing = null;
    form = { name: '', birthYearMin: 2010, birthYearMax: 2015, gender: 'MIXTO', minPlayers: 5, mandatory: false, promotional: false, active: true };
    error = '';
    showForm = true;
  }

  function openEdit(category: Category) {
    editing = category;
    form = {
      name: category.name, birthYearMin: category.birthYearMin, birthYearMax: category.birthYearMax,
      gender: category.gender, minPlayers: category.minPlayers, mandatory: category.mandatory,
      promotional: category.promotional, active: category.active
    };
    error = '';
    showForm = true;
  }

  function closeModal() {
    showForm = false;
    editing = null;
    error = '';
  }

  async function save() {
    error = '';
    notice = '';
    if (!form.name.trim()) { error = 'Ingresa el nombre de la categoría.'; return; }
    saving = true;
    const input: Record<string, unknown> = {
      name: form.name.trim(), birthYearMin: form.birthYearMin, birthYearMax: form.birthYearMax,
      gender: form.gender, minPlayers: form.minPlayers, mandatory: form.mandatory,
      promotional: form.promotional, active: form.active
    };
    try {
      const saved = editing ? await updateCategory(editing.id, input) : await createCategory(input);
      categories = editing
        ? categories.map((c) => c.id === saved.id ? saved : c)
        : [...categories, saved].sort((a, b) => a.name.localeCompare(b.name));
      notice = editing ? 'Categoría actualizada correctamente.' : 'Categoría creada correctamente.';
      editing = null;
      showForm = false;
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo guardar la categoría.';
    } finally {
      saving = false;
    }
  }
</script>

<svelte:head><title>Categorías | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div><p class="eyebrow">Configuración deportiva</p><h1>Categorías</h1><p class="muted">Define las categorías por edad, género y cantidad de jugadores.</p></div>
    <div style="display:flex;align-items:center;gap:.6rem">
      {#if canManage}<button class="button primary" onclick={openCreate}>Agregar categoría</button>{/if}
      <a class="button secondary" href="/">Volver al panel</a>
    </div>
  </header>

  {#if loading}
    <section class="loading-card">Cargando categorías...</section>
  {:else}
    {#if error}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}
    <section class="league-list card-surface">
      <div class="list-header"><div><p class="eyebrow">Catálogo</p><h2>Categorías registradas</h2></div><span class="count-pill">{categories.length}</span></div>
      {#if categories.length === 0}
        <div class="empty-state compact-empty"><h2>Sin categorías todavía</h2><p>Crea la primera categoría para comenzar.</p></div>
      {:else}
        <div class="categories-grid">
          {#each categories as category}
            <article class="category-card card-surface">
              <div class="category-card-header">
                <h3>{category.name}</h3>
                {#if canManage}<button class="icon-button" onclick={() => openEdit(category)} aria-label={`Editar ${category.name}`}>Editar</button>{/if}
              </div>
              <div class="category-meta">
                <span class="category-tag">{genders.find(([v]) => v === category.gender)?.[1] ?? category.gender}</span>
                <span class="category-tag">{category.birthYearMin} – {category.birthYearMax}</span>
                <span class="category-tag">Mín. {category.minPlayers} jug.</span>
              </div>
              <div class="category-flags">
                {#if category.mandatory}<span class="flag flag-mandatory">Obligatoria</span>{/if}
                {#if category.promotional}<span class="flag flag-promotional">Promocional</span>{/if}
                {#if !category.active}<span class="flag flag-inactive">Inactiva</span>{/if}
              </div>
            </article>
          {/each}
        </div>
      {/if}
    </section>
  {/if}

  {#if showForm && canManage}
    <Modal onclose={closeModal}>
      <p class="eyebrow">{editing ? 'Editar categoría' : 'Nueva categoría'}</p>
      <h2>{editing ? editing.name : 'Crear categoría'}</h2>
      <form onsubmit={(event) => { event.preventDefault(); save(); }}>
        <label>Nombre<input bind:value={form.name} placeholder="Sub-15" disabled={saving} /></label>
        <div class="form-row">
          <label>Año nac. (desde)<input type="number" bind:value={form.birthYearMin} min={1900} max={2030} disabled={saving} /></label>
          <label>Año nac. (hasta)<input type="number" bind:value={form.birthYearMax} min={1900} max={2030} disabled={saving} /></label>
        </div>
        <label>Género<select bind:value={form.gender} disabled={saving}>{#each genders as [value, label]}<option value={value}>{label}</option>{/each}</select></label>
        <label>Jugadores mínimos<input type="number" bind:value={form.minPlayers} min={1} max={99} disabled={saving} /></label>
        <label class="checkbox-label"><input type="checkbox" bind:checked={form.mandatory} disabled={saving} /> Categoría obligatoria</label>
        <label class="checkbox-label"><input type="checkbox" bind:checked={form.promotional} disabled={saving} /> Categoría promocional</label>
        <label class="checkbox-label"><input type="checkbox" bind:checked={form.active} disabled={saving} /> Categoría activa</label>
        <div class="form-actions"><button class="button primary" type="submit" disabled={saving}>{saving ? 'Guardando...' : editing ? 'Guardar cambios' : 'Crear categoría'}</button>{#if editing}<button class="button secondary" type="button" onclick={openCreate} disabled={saving}>Cancelar</button>{/if}</div>
      </form>
    </Modal>
  {/if}
</main>

<style>
  .categories-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 1rem; margin-top: 1.5rem; }
  .category-card { padding: 1.2rem; }
  .category-card-header { display: flex; justify-content: space-between; align-items: center; gap: .5rem; }
  .category-card-header h3 { margin: 0; font-family: 'Space Grotesk', sans-serif; font-size: 1.15rem; letter-spacing: -.03em; }
  .category-meta { display: flex; flex-wrap: wrap; gap: .4rem; margin-top: .8rem; }
  .category-tag { padding: .2rem .55rem; border-radius: 999px; color: var(--color-accent-text); background: var(--color-accent-bg); font-size: .72rem; font-weight: 600; }
  .category-flags { display: flex; flex-wrap: wrap; gap: .4rem; margin-top: .6rem; }
  .flag { padding: .15rem .5rem; border-radius: 999px; font-size: .68rem; font-weight: 700; }
  .flag-mandatory { color: var(--color-accent-text); background: var(--color-accent-bg); }
  .flag-promotional { color: #6b4e16; background: #fbf0d9; }
  .flag-inactive { color: var(--color-error); background: var(--color-error-bg); }
</style>
