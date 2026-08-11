<script lang="ts">
  import { onMount } from 'svelte';
  import { getSiteIdentity, updateSiteIdentity, uploadFavicon, type SiteIdentity } from '$lib/api';
  import { usePalette } from '$lib/palette.svelte';

  const paletteState = usePalette();

  let identity = $state<SiteIdentity | null>(null);
  let loading = $state(true);
  let saving = $state(false);
  let error = $state('');
  let notice = $state('');

  let title = $state('');
  let iconFile = $state<File | null>(null);
  let flyerFile = $state<File | null>(null);
  let faviconFile = $state<File | null>(null);

  let iconInput = $state<HTMLInputElement>();
  let flyerInput = $state<HTMLInputElement>();
  let faviconInput = $state<HTMLInputElement>();

  let selectedPaletteId = $state(paletteState.id);

  onMount(async () => {
    try {
      identity = await getSiteIdentity();
      title = identity.title;
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo cargar la identidad del sitio.';
    } finally {
      loading = false;
    }
  });

  function handleIconChange() {
    iconFile = iconInput?.files?.[0] ?? null;
  }

  function handleFlyerChange() {
    flyerFile = flyerInput?.files?.[0] ?? null;
  }

  function handleFaviconChange() {
    faviconFile = faviconInput?.files?.[0] ?? null;
  }

  function handlePaletteChange() {
    paletteState.setPalette(selectedPaletteId);
    notice = `Paleta "${paletteState.palette.name}" aplicada.`;
    savePaletteToBackend();
    setTimeout(() => notice = '', 2500);
  }

  async function saveIdentity() {
    error = '';
    notice = '';
    if (!title.trim()) { error = 'Ingresa un título para el sitio.'; return; }
    saving = true;
    try {
      const formData = new FormData();
      formData.append('title', title.trim());
      formData.append('paletteId', selectedPaletteId);
      if (iconFile) formData.append('icon', iconFile);
      if (flyerFile) formData.append('flyer', flyerFile);
      const updated = await updateSiteIdentity(formData);
      identity = updated;
      if (iconFile) { iconFile = null; if (iconInput) iconInput.value = ''; }
      if (flyerFile) { flyerFile = null; if (flyerInput) flyerInput.value = ''; }
      notice = 'Identidad del sitio actualizada correctamente.';
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo actualizar la identidad.';
    } finally {
      saving = false;
    }
  }

  async function savePaletteToBackend() {
    try {
      const formData = new FormData();
      formData.append('title', title.trim() || 'Ligas Deportivas');
      formData.append('paletteId', selectedPaletteId);
      await updateSiteIdentity(formData);
    } catch {}
  }

  async function saveFavicon() {
    error = '';
    notice = '';
    if (!faviconFile) { error = 'Selecciona un archivo para el favicon.'; return; }
    saving = true;
    try {
      await uploadFavicon(faviconFile);
      const updated = await getSiteIdentity();
      identity = updated;
      faviconFile = null;
      if (faviconInput) faviconInput.value = '';
      notice = 'Favicon actualizado correctamente.';
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo subir el favicon.';
    } finally {
      saving = false;
    }
  }
</script>

<svelte:head><title>Identidad | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div>
      <p class="eyebrow">Configuración</p>
      <h1>Identidad del sitio</h1>
      <p class="muted">Personaliza el título, ícono, flyer, favicon y paleta de colores de la plataforma.</p>
    </div>
  </header>

  {#if loading}
    <section class="loading-card">Cargando identidad del sitio...</section>
  {:else}
    {#if error}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}

    <div class="leagues-layout">
      <section class="card-surface">
        <div class="list-header">
          <div><p class="eyebrow">Marca</p><h2>Información general</h2></div>
        </div>
        <form onsubmit={(event) => { event.preventDefault(); saveIdentity(); }}>
          <label>Título del sitio<input bind:value={title} placeholder="Ligas Deportivas" disabled={saving} /></label>

          <label>
            Ícono
            <input type="file" bind:this={iconInput} onchange={handleIconChange} accept="image/*" disabled={saving} />
            {#if iconFile}<span class="muted" style="font-size:.78rem;">{iconFile.name}</span>{/if}
          </label>

          <label>
            Flyer
            <input type="file" bind:this={flyerInput} onchange={handleFlyerChange} accept="image/*" disabled={saving} />
            {#if flyerFile}<span class="muted" style="font-size:.78rem;">{flyerFile.name}</span>{/if}
          </label>

          {#if identity?.iconUrl}
            <img src={identity.iconUrl} alt="Ícono actual" style="width:64px; height:64px; border-radius:.75rem; object-fit:cover;" />
          {/if}

          <div class="form-actions">
            <button class="button primary" type="submit" disabled={saving}>{saving ? 'Guardando...' : 'Guardar cambios'}</button>
          </div>
        </form>
      </section>

      <section class="card-surface">
        <div class="list-header">
          <div><p class="eyebrow">Favicon</p><h2>Ícono del navegador</h2></div>
        </div>
        <form onsubmit={(event) => { event.preventDefault(); saveFavicon(); }}>
          <label>
            Favicon
            <input type="file" bind:this={faviconInput} onchange={handleFaviconChange} accept="image/*" disabled={saving} />
            {#if faviconFile}<span class="muted" style="font-size:.78rem;">{faviconFile.name}</span>{/if}
          </label>

          {#if identity?.faviconHash}
            <p class="muted" style="font-size:.78rem;">Favicon actual: /favicon-{identity.faviconHash}.ico</p>
          {/if}

          <div class="form-actions">
            <button class="button primary" type="submit" disabled={saving}>{saving ? 'Subiendo...' : 'Subir favicon'}</button>
          </div>
        </form>
      </section>

      <section class="card-surface">
        <div class="list-header">
          <div><p class="eyebrow">Apariencia</p><h2>Paleta de colores</h2></div>
        </div>
        <label>
          Seleccioná una paleta
          <div class="palette-select-wrapper">
            <select class="palette-select" bind:value={selectedPaletteId} onchange={handlePaletteChange}>
              {#each paletteState.palettes as palette}
                <option value={palette.id}>{palette.name}</option>
              {/each}
            </select>
            <div class="palette-preview">
              {#each paletteState.palettes as palette}
                {#if palette.id === selectedPaletteId}
                  <span class="palette-dot" style="background:{palette.colors.hero}"></span>
                  <span class="palette-dot" style="background:{palette.colors.accent}"></span>
                  <span class="palette-dot" style="background:{palette.colors.surface}; border:1px solid {palette.colors.border}"></span>
                  <span class="palette-dot" style="background:{palette.colors.text}"></span>
                  <span class="palette-dot" style="background:{palette.colors.accentLight}"></span>
                {/if}
              {/each}
            </div>
          </div>
        </label>
      </section>
    </div>
  {/if}
</main>

<style>
  .palette-select-wrapper {
    display: flex; align-items: center; gap: .75rem;
  }
  .palette-select {
    flex: 1; max-width: 240px;
    padding: .55rem .7rem;
    border: 1px solid var(--color-input-border);
    border-radius: .6rem;
    background: var(--color-input);
    color: var(--color-text);
    font-size: .85rem;
    font-family: inherit;
  }
  .palette-select:focus {
    outline: none;
    border-color: var(--color-input-focus);
    box-shadow: 0 0 0 3px color-mix(in srgb, var(--color-input-focus) 15%, transparent);
  }
  .palette-preview {
    display: flex; gap: .35rem; align-items: center;
  }
  .palette-dot {
    width: 18px; height: 18px; border-radius: 50%;
    box-shadow: 0 1px 3px var(--color-shadow);
  }
</style>
