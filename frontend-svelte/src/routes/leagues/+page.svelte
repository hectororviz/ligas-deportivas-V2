<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { createLeague, getLeagues, getProfile, updateLeague, canManageModule, type AuthUser, type League } from '$lib/api';
  import Modal from '$lib/Modal.svelte';

  const days = [
    ['DOMINGO', 'Domingo'], ['LUNES', 'Lunes'], ['MARTES', 'Martes'],
    ['MIERCOLES', 'Miércoles'], ['JUEVES', 'Jueves'], ['VIERNES', 'Viernes'], ['SABADO', 'Sábado']
  ];

  let user: AuthUser | null = $state(null);
  let leagues: League[] = $state([]);
  let loading = $state(true);
  let saving = $state(false);
  let error = $state('');
  let notice = $state('');
  let editing: League | null = $state(null);
  let showForm = $state(false);
  let form = $state({ name: '', slug: '', colorHex: '#0057B8', gameDay: 'DOMINGO' });

  onMount(async () => {
    try {
      const [u, l] = await Promise.all([getProfile(), getLeagues()]);
      user = u; leagues = l;
      const editId = Number($page.url.searchParams.get('editar'));
      const target = l.find((league) => league.id === editId);
      if (target) openEdit(target);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar las ligas.';
    } finally {
      loading = false;
    }
  });

  let canManage = $derived(canManageModule(user, 'LIGAS'));

  function openCreate() {
    editing = null; showForm = true;
    form = { name: '', slug: '', colorHex: '#0057B8', gameDay: 'DOMINGO' };
    error = '';
  }

  function openEdit(league: League) {
    editing = league; showForm = true;
    form = { name: league.name, slug: league.slug, colorHex: league.colorHex, gameDay: league.gameDay };
    error = '';
  }

  function closeModal() { showForm = false; editing = null; error = ''; }

  function slugify(value: string) {
    return value.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
  }

  async function save() {
    error = '';
    if (!form.name.trim()) { error = 'Ingresa el nombre de la liga.'; return; }
    saving = true;
    const input = { ...form, name: form.name.trim(), slug: form.slug.trim() || slugify(form.name) };
    try {
      const saved = editing ? await updateLeague(editing.id, input) : await createLeague(input);
      leagues = editing ? leagues.map((league) => league.id === saved.id ? saved : league) : [...leagues, saved].sort((a, b) => a.name.localeCompare(b.name));
      notice = editing ? 'Liga actualizada correctamente.' : 'Liga creada correctamente.';
      editing = null; showForm = false;
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo guardar la liga.';
    } finally {
      saving = false;
    }
  }
</script>

<svelte:head><title>Ligas | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div><p class="eyebrow">Configuración deportiva</p><h1>Ligas</h1><p class="muted">Organiza competiciones y define su día de juego.</p></div>
  </header>

  {#if loading}
    <section class="loading-card">Cargando ligas...</section>
  {:else}
    {#if error && !showForm}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}

    <section class="card-surface">
      <div class="list-header">
        <div><p class="eyebrow">Catálogo</p><h2>Ligas registradas</h2></div>
        <div class="list-header-right">
          <span class="count-pill">{leagues.length}</span>
          {#if canManage}<button class="button primary add-btn" onclick={openCreate} aria-label="Agregar liga">+</button>{/if}
        </div>
      </div>
      {#if leagues.length === 0}
        <div class="empty-state compact-empty"><h2>Sin ligas todavía</h2><p>Crea la primera liga para comenzar.</p></div>
      {:else}
        <div class="league-table">
          {#each leagues as league}
            <article class="league-row">
              <span class="league-color" style={`--league-color: ${league.colorHex}`}>{league.name.slice(0, 2).toUpperCase()}</span>
              <div class="league-info"><strong>{league.name}</strong><span>{league.slug} · {days.find(([value]) => value === league.gameDay)?.[1] ?? league.gameDay}</span></div>
              {#if canManage}<button class="icon-button" onclick={() => openEdit(league)} aria-label={`Editar ${league.name}`}>Editar</button>{/if}
            </article>
          {/each}
        </div>
      {/if}
    </section>
  {/if}
</main>

{#if showForm}
  <Modal onclose={closeModal}>
    <div class="modal-form">
      <p class="eyebrow">{editing ? 'Editar liga' : 'Nueva liga'}</p>
      <h2>{editing ? editing.name || 'Editar' : 'Crear liga'}</h2>
      {#if error}<p class="form-error">{error}</p>{/if}
      <form onsubmit={(event) => { event.preventDefault(); save(); }}>
        <label>Nombre<input bind:value={form.name} placeholder="Liga Metropolitana" disabled={saving} /></label>
        <label>Identificador<input bind:value={form.slug} placeholder="liga-metropolitana" disabled={saving} /></label>
        <label>Día de juego<select bind:value={form.gameDay} disabled={saving}>{#each days as [value, label]}<option value={value}>{label}</option>{/each}</select></label>
        <label>Color distintivo<div class="color-input"><input type="color" bind:value={form.colorHex} disabled={saving} /><input bind:value={form.colorHex} disabled={saving} /></div></label>
        <div class="form-actions"><button class="button primary" type="submit" disabled={saving}>{saving ? 'Guardando...' : editing ? 'Guardar cambios' : 'Crear liga'}</button></div>
      </form>
    </div>
  </Modal>
{/if}

<style>
  .list-header-right { display: flex; align-items: center; gap: .6rem; }
  .modal-form h2 { margin: .5rem 0 1.5rem; font-family: 'Space Grotesk', sans-serif; font-size: 1.6rem; letter-spacing: -.04em; }
  .modal-form form { margin-top: 0; }
</style>
