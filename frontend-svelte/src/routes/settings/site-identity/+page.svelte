<script lang="ts">
  import { onMount } from 'svelte';
  import { getSiteIdentity, updateSiteIdentity, uploadFavicon, type SiteIdentity } from '$lib/api';

  let identity: SiteIdentity | null = null;
  let loading = true;
  let saving = false;
  let error = '';
  let notice = '';

  let title = '';
  let iconFile: File | null = null;
  let flyerFile: File | null = null;
  let faviconFile: File | null = null;

  let iconInput: HTMLInputElement;
  let flyerInput: HTMLInputElement;
  let faviconInput: HTMLInputElement;

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

  async function saveIdentity() {
    error = '';
    notice = '';
    if (!title.trim()) { error = 'Ingresa un título para el sitio.'; return; }
    saving = true;
    try {
      const formData = new FormData();
      formData.append('title', title.trim());
      if (iconFile) formData.append('icon', iconFile);
      if (flyerFile) formData.append('flyer', flyerFile);
      const updated = await updateSiteIdentity(formData);
      identity = updated;
      if (iconFile) { iconFile = null; iconInput.value = ''; }
      if (flyerFile) { flyerFile = null; flyerInput.value = ''; }
      notice = 'Identidad del sitio actualizada correctamente.';
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo actualizar la identidad.';
    } finally {
      saving = false;
    }
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
      faviconInput.value = '';
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
      <p class="muted">Personaliza el título, ícono, flyer y favicon de la plataforma.</p>
    </div>
    <a class="button secondary" href="/settings">Volver a ajustes</a>
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
    </div>
  {/if}
</main>
