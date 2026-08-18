<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import Modal from '$lib/Modal.svelte';
  import {
    getProfile,
    getTournaments,
    getFlyerTemplate,
    upsertFlyerTemplate,
    deleteFlyerTemplate,
    getMatchFlyerTokens,
    fetchFlyerTemplatePreview,
    canManageModule,
    type AuthUser,
    type FlyerTemplate,
    type FlyerToken
  } from '$lib/api';

  let user: AuthUser | null = $state(null);
  let tournamentName = $state('');
  let template = $state<FlyerTemplate | null>(null);
  let tokens = $state<FlyerToken[]>([]);
  let loading = $state(true);
  let saving = $state(false);
  let previewing = $state(false);
  let deleting = $state(false);
  let error = $state('');
  let notice = $state('');

  let backgroundFile = $state<File | null>(null);
  let layoutFile = $state<File | null>(null);
  let backgroundInput = $state<HTMLInputElement>();
  let layoutInput = $state<HTMLInputElement>();

  let previewUrl = $state<string | null>(null);

  let canManage = $derived(canManageModule(user, 'CONFIGURACION'));

  const competitionId = Number($page.params.id);

  onMount(async () => {
    try {
      const [u, t, toks, tournaments] = await Promise.all([
        getProfile().catch(() => null),
        getFlyerTemplate(competitionId),
        getMatchFlyerTokens().catch(() => [] as FlyerToken[]),
        getTournaments(true).catch(() => [])
      ]);
      user = u;
      template = t;
      tokens = toks;
      const tournament = tournaments.find((item) => item.id === competitionId);
      if (tournament) tournamentName = `${tournament.league.name} · ${tournament.name} ${tournament.year}`;
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo cargar la plantilla del flyer.';
    } finally {
      loading = false;
    }
  });

  function handleBackgroundChange() {
    backgroundFile = backgroundInput?.files?.[0] ?? null;
  }

  function handleLayoutChange() {
    layoutFile = layoutInput?.files?.[0] ?? null;
  }

  async function save() {
    error = '';
    notice = '';
    if (!backgroundFile && !layoutFile) {
      error = 'Selecciona un fondo o un layout SVG para guardar.';
      return;
    }
    saving = true;
    try {
      const formData = new FormData();
      if (backgroundFile) formData.append('background', backgroundFile);
      if (layoutFile) formData.append('layout', layoutFile);
      template = await upsertFlyerTemplate(competitionId, formData);
      backgroundFile = null;
      layoutFile = null;
      if (backgroundInput) backgroundInput.value = '';
      if (layoutInput) layoutInput.value = '';
      notice = 'Plantilla del flyer guardada correctamente.';
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo guardar la plantilla.';
    } finally {
      saving = false;
    }
  }

  async function preview() {
    error = '';
    previewing = true;
    try {
      previewUrl = await fetchFlyerTemplatePreview(competitionId);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo generar la vista previa.';
    } finally {
      previewing = false;
    }
  }

  async function remove() {
    error = '';
    notice = '';
    deleting = true;
    try {
      await deleteFlyerTemplate(competitionId);
      template = await getFlyerTemplate(competitionId);
      notice = 'Plantilla eliminada. Se usará la plantilla por defecto.';
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo eliminar la plantilla.';
    } finally {
      deleting = false;
    }
  }

  function closePreview() {
    if (previewUrl) URL.revokeObjectURL(previewUrl);
    previewUrl = null;
  }
</script>

<svelte:head><title>Plantilla de flyer | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div>
      <p class="eyebrow">Competencia</p>
      <h1>Plantilla de flyer</h1>
      <p class="muted">{tournamentName || `Torneo ${competitionId}`}</p>
    </div>
    <a class="button secondary" href="/tournaments">Volver a torneos</a>
  </header>

  {#if loading}
    <section class="loading-card">Cargando plantilla...</section>
  {:else}
    {#if error}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}

    <div class="flyer-layout">
      <section class="card-surface">
        <div class="list-header">
          <div>
            <p class="eyebrow">Diseño</p>
            <h2>Fondo y layout</h2>
            <p class="muted">Configura la imagen de fondo (1080x1920) y el layout SVG con placeholders.</p>
          </div>
        </div>

        {#if canManage}
          <form onsubmit={(event) => { event.preventDefault(); save(); }}>
            <label>
              Fondo (imagen)
              <input type="file" bind:this={backgroundInput} onchange={handleBackgroundChange} accept="image/*" disabled={saving} />
              {#if backgroundFile}<span class="muted" style="font-size:.78rem;">{backgroundFile.name}</span>{/if}
            </label>

            <label>
              Layout (SVG)
              <input type="file" bind:this={layoutInput} onchange={handleLayoutChange} accept=".svg,image/svg+xml" disabled={saving} />
              {#if layoutFile}<span class="muted" style="font-size:.78rem;">{layoutFile.name}</span>{/if}
            </label>

            <div class="form-actions">
              <button class="button primary" type="submit" disabled={saving}>{saving ? 'Guardando...' : 'Guardar plantilla'}</button>
              <button class="button secondary" type="button" onclick={preview} disabled={previewing || !template?.hasCustomTemplate}>
                {previewing ? 'Generando...' : 'Previsualizar'}
              </button>
              {#if template?.hasCustomTemplate}
                <button class="button secondary" type="button" onclick={remove} disabled={deleting} style="color:var(--color-error);">
                  {deleting ? 'Eliminando...' : 'Eliminar plantilla'}
                </button>
              {/if}
            </div>
          </form>
        {:else}
          <p class="muted">No tenés permisos para editar la plantilla.</p>
        {/if}

        <div class="current-state">
          <p class="eyebrow">Estado actual</p>
          {#if template?.backgroundUrl}
            <img src={template.backgroundUrl} alt="Fondo actual" style="width:120px;height:213px;border-radius:.75rem;object-fit:cover;border:1px solid var(--color-border);" />
          {:else}
            <p class="muted">Sin fondo configurado.</p>
          {/if}
          <p class="muted" style="font-size:.82rem;">
            {#if template?.layoutFileName}
              Layout: {template.layoutFileName}
            {:else}
              Sin layout SVG configurado.
            {/if}
          </p>
          {#if !template?.hasCustomTemplate}
            <p class="muted" style="font-size:.82rem;">Se usará la plantilla por defecto (si existe).</p>
          {/if}
        </div>
      </section>

      <section class="card-surface">
        <div class="list-header">
          <div>
            <p class="eyebrow">Placeholders</p>
            <h2>Tokens disponibles</h2>
            <p class="muted">Usalos dentro del layout SVG, p. ej. <code>&#123;&#123;tournament.name&#125;&#125;</code>.</p>
          </div>
        </div>

        {#if tokens.length === 0}
          <p class="muted">No hay tokens disponibles.</p>
        {:else}
          <ul class="token-list">
            {#each tokens as token}
              <li>
                <code>&#123;&#123;{token.token}&#125;&#125;</code>
                <span>{token.description}</span>
                {#if token.usage}<code class="usage">{token.usage}</code>{/if}
              </li>
            {/each}
          </ul>
        {/if}
      </section>
    </div>
  {/if}
</main>

{#if previewUrl}
  <Modal onclose={closePreview} wide>
    <div class="preview-modal">
      <p class="eyebrow">Vista previa</p>
      <h2>Plantilla de flyer</h2>
      <div class="preview-frame">
        <img src={previewUrl} alt="Vista previa del flyer" />
      </div>
    </div>
  </Modal>
{/if}

<style>
  .flyer-layout {
    display: grid;
    grid-template-columns: 1.2fr 1fr;
    gap: 1.25rem;
    align-items: start;
  }
  .card-surface form label {
    display: block;
    margin-bottom: .9rem;
  }
  .form-actions {
    display: flex;
    flex-wrap: wrap;
    gap: .6rem;
    margin-top: 1rem;
  }
  .current-state {
    margin-top: 1.5rem;
    padding-top: 1rem;
    border-top: 1px solid var(--color-border);
    display: grid;
    gap: .5rem;
  }
  .token-list {
    list-style: none;
    margin: 0;
    padding: 0;
    display: grid;
    gap: .6rem;
  }
  .token-list li {
    display: grid;
    gap: .25rem;
    padding: .6rem .75rem;
    border: 1px solid var(--color-border);
    border-radius: .6rem;
    background: var(--color-surface-hover);
    font-size: .82rem;
  }
  .token-list code,
  .muted code {
    font-family: ui-monospace, 'SF Mono', Menlo, monospace;
    font-size: .78rem;
    color: var(--color-accent-text);
    background: var(--color-accent-bg);
    padding: .1rem .3rem;
    border-radius: .3rem;
  }
  .token-list .usage {
    color: var(--color-text-muted);
    background: transparent;
    padding: 0;
    white-space: pre-wrap;
    word-break: break-word;
  }
  .preview-modal h2 {
    margin: .4rem 0 1rem;
    font-family: 'Space Grotesk', sans-serif;
  }
  .preview-frame {
    display: flex;
    justify-content: center;
    max-height: 74vh;
    overflow: auto;
  }
  .preview-frame img {
    max-width: 100%;
    height: auto;
    border: 1px solid var(--color-border);
    border-radius: .75rem;
  }
  @media (max-width: 720px) {
    .flyer-layout { grid-template-columns: 1fr; }
  }
</style>
