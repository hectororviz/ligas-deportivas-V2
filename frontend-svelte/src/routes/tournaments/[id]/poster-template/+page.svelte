<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import Modal from '$lib/Modal.svelte';
  import {
    getProfile,
    getTournaments,
    getTournamentZones,
    getZoneMatches,
    getPosterTemplate,
    upsertPosterTemplate,
    getMatchPosterTokens,
    fetchPosterTemplatePreview,
    canManageModule,
    type AuthUser,
    type PosterLayer,
    type PosterToken,
    type PosterTemplateResponse
  } from '$lib/api';

  const CANVAS_W = 1080;
  const CANVAS_H = 1920;

  const FONT_FAMILIES = [
    '', 'DejaVu Sans', 'Arial', 'Helvetica', 'Verdana', 'Roboto',
    'Montserrat', 'Poppins', 'Oswald', 'Lato', 'Open Sans',
    'Merriweather', 'serif', 'sans-serif', 'monospace'
  ];
  const FONT_WEIGHTS = ['normal', '500', '600', '700', '800', 'bold'];
  const FONT_STYLES = ['normal', 'italic'];
  const ALIGNS: [PosterLayer['align'], string][] = [
    ['left', 'Izquierda'],
    ['center', 'Centro'],
    ['right', 'Derecha']
  ];

  interface MatchOption {
    id: number;
    label: string;
  }

  let user = $state<AuthUser | null>(null);
  let tournamentName = $state('');
  let loading = $state(true);
  let saving = $state(false);
  let previewing = $state(false);
  let error = $state('');
  let notice = $state('');

  let layers = $state<PosterLayer[]>([]);
  let backgroundUrl = $state<string | null>(null);
  let tokens = $state<PosterToken[]>([]);

  let backgroundFile = $state<File | null>(null);
  let backgroundInput = $state<HTMLInputElement>();
  let backgroundPreviewUrl = $state<string | null>(null);

  let selectedId = $state<string | null>(null);
  let selected = $derived(layers.find((l) => l.id === selectedId) ?? null);

  let canvasWrap = $state<HTMLDivElement>();
  let canvasEl = $state<HTMLDivElement>();
  let scale = $state(0.18);

  let matches = $state<MatchOption[]>([]);
  let showPreview = $state(false);
  let previewMatchId = $state<number | null>(null);
  let previewUrl = $state<string | null>(null);

  let canManage = $derived(canManageModule(user, 'CONFIGURACION'));

  const competitionId = Number($page.params.id);

  let drag = $state<{
    layer: PosterLayer;
    mode: 'move' | 'resize' | 'rotate';
    pointerX: number;
    pointerY: number;
    origX: number;
    origY: number;
    origW: number;
    origH: number;
    origR: number;
    startAngle: number;
    canvasRect: DOMRect;
  } | null>(null);

  $effect(() => {
    const el = canvasWrap;
    if (!el) return;
    const update = () => {
      scale = el.clientWidth > 0 ? el.clientWidth / CANVAS_W : 0.18;
    };
    update();
    const ro = new ResizeObserver(update);
    ro.observe(el);
    return () => ro.disconnect();
  });

  onMount(async () => {
    try {
      const [u, template, toks, tournaments] = await Promise.all([
        getProfile().catch(() => null),
        getPosterTemplate(competitionId),
        getMatchPosterTokens().catch(() => [] as PosterToken[]),
        getTournaments(true).catch(() => [])
      ]);
      user = u;
      tokens = toks;
      backgroundUrl = template.backgroundUrl;
      const loaded = [...(template.template.layers ?? [])].sort(
        (a, b) => (a.zIndex ?? 0) - (b.zIndex ?? 0)
      );
      layers = loaded.length ? loaded : defaultLayers();
      reindex();
      const tournament = tournaments.find((item) => item.id === competitionId);
      if (tournament) tournamentName = `${tournament.league.name} · ${tournament.name} ${tournament.year}`;
      await loadMatches();
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo cargar la plantilla.';
    } finally {
      loading = false;
    }
  });

  async function loadMatches() {
    try {
      const zones = await getTournamentZones(competitionId);
      const options: MatchOption[] = [];
      for (const zone of zones) {
        const data = await getZoneMatches(zone.id);
        for (const m of data.matches) {
          const home = m.homeClub?.name ?? 'Local';
          const away = m.awayClub?.name ?? 'Visitante';
          const round = m.round === 'SECOND' ? 'Rueda 2' : 'Rueda 1';
          options.push({
            id: m.id,
            label: `${zone.name} · Fecha ${m.matchday} · ${round} · ${home} vs ${away}`
          });
        }
      }
      matches = options;
    } catch {
      matches = [];
    }
  }

  function uid(prefix: string) {
    return `${prefix}-${Date.now()}-${Math.floor(Math.random() * 9999)}`;
  }

  function createBackgroundLayer(): PosterLayer {
    return {
      id: uid('background'), type: 'image', x: 0, y: 0,
      width: CANVAS_W, height: CANVAS_H, src: '', isBackground: true,
      fit: 'cover', opacity: 1, rotation: 0, zIndex: 0
    };
  }

  function createTextLayer(text = 'Texto'): PosterLayer {
    return {
      id: uid('text'), type: 'text', x: 120, y: 200, width: 840, height: 140,
      text, fontSize: 72, color: '#FFFFFF', align: 'center',
      fontFamily: '', fontWeight: 'normal', fontStyle: 'normal',
      opacity: 1, rotation: 0, zIndex: 0
    };
  }

  function createShapeLayer(): PosterLayer {
    return {
      id: uid('shape'), type: 'shape', x: 0, y: 1400, width: CANVAS_W, height: 240,
      shape: 'rect', fill: '#000000', radius: 0, opacity: 0.6, rotation: 0, zIndex: 0
    };
  }

  function createLogoLayer(isHome: boolean): PosterLayer {
    return {
      id: uid(isHome ? 'home-logo' : 'away-logo'), type: 'image',
      x: isHome ? 140 : 640, y: 820, width: 300, height: 300,
      src: isHome ? '{{homeClub.logoUrl}}' : '{{awayClub.logoUrl}}',
      fit: 'contain', opacity: 1, rotation: 0, zIndex: 0
    };
  }

  function defaultLayers(): PosterLayer[] {
    return [
      createBackgroundLayer(),
      createLogoLayer(true),
      createLogoLayer(false),
      { ...createTextLayer('{{tournament.name}}'), x: 80, y: 120, width: 920, height: 120, fontSize: 64 },
      { ...createTextLayer('Fecha {{match.matchday}} · {{match.dayName}}'), x: 80, y: 280, width: 920, height: 120, fontSize: 48 }
    ];
  }

  function reindex() {
    layers.forEach((l, i) => (l.zIndex = i));
  }

  function addLayer(layer: PosterLayer) {
    layers.push(layer);
    reindex();
    selectedId = layer.id;
  }

  function addTextLayer() {
    addLayer(createTextLayer());
  }

  function addShapeLayer() {
    addLayer(createShapeLayer());
  }

  function addLogoLayer(isHome: boolean) {
    addLayer(createLogoLayer(isHome));
  }

  function insertToken(token: PosterToken) {
    const placeholder = `{{${token.token}}}`;
    if (selected && selected.type === 'text') {
      selected.text = (selected.text ?? '') + placeholder;
    } else {
      addLayer(createTextLayer(placeholder));
    }
  }

  function removeLayer(id: string) {
    layers = layers.filter((l) => l.id !== id);
    if (selectedId === id) selectedId = null;
    reindex();
  }

  function toggleLock(id: string) {
    const layer = layers.find((l) => l.id === id);
    if (layer) layer.locked = !layer.locked;
  }

  function moveLayer(id: string, direction: -1 | 1) {
    const index = layers.findIndex((l) => l.id === id);
    const target = index + direction;
    if (index < 0 || target < 0 || target >= layers.length) return;
    const copy = [...layers];
    const [layer] = copy.splice(index, 1);
    copy.splice(target, 0, layer);
    layers = copy;
    reindex();
  }

  function startDrag(layer: PosterLayer, mode: 'move' | 'resize' | 'rotate', e: PointerEvent) {
    selectedId = layer.id;
    if (layer.locked) return;
    const canvasRect = canvasEl?.getBoundingClientRect();
    if (!canvasRect) return;
    const cx = layer.x + layer.width / 2;
    const cy = layer.y + layer.height / 2;
    const centerScreenX = canvasRect.left + cx * scale;
    const centerScreenY = canvasRect.top + cy * scale;
    const startAngle = Math.atan2(e.clientY - centerScreenY, e.clientX - centerScreenX);
    drag = {
      layer, mode,
      pointerX: e.clientX, pointerY: e.clientY,
      origX: layer.x, origY: layer.y,
      origW: layer.width, origH: layer.height,
      origR: layer.rotation ?? 0,
      startAngle, canvasRect
    };
    (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
  }

  function moveDrag(layer: PosterLayer, e: PointerEvent) {
    if (!drag || drag.layer.id !== layer.id) return;
    const dx = (e.clientX - drag.pointerX) / scale;
    const dy = (e.clientY - drag.pointerY) / scale;
    if (drag.mode === 'move') {
      layer.x = Math.round(drag.origX + dx);
      layer.y = Math.round(drag.origY + dy);
    } else if (drag.mode === 'resize') {
      layer.width = Math.max(20, Math.round(drag.origW + dx));
      layer.height = Math.max(20, Math.round(drag.origH + dy));
    } else if (drag.mode === 'rotate') {
      const cx = layer.x + layer.width / 2;
      const cy = layer.y + layer.height / 2;
      const centerScreenX = drag.canvasRect.left + cx * scale;
      const centerScreenY = drag.canvasRect.top + cy * scale;
      const angle = Math.atan2(e.clientY - centerScreenY, e.clientX - centerScreenX);
      let deg = drag.origR + ((angle - drag.startAngle) * 180) / Math.PI;
      deg = Math.round(deg * 10) / 10;
      layer.rotation = ((deg % 360) + 360) % 360;
    }
  }

  function endDrag() {
    drag = null;
  }

  function handleBackgroundChange() {
    backgroundFile = backgroundInput?.files?.[0] ?? null;
    if (backgroundPreviewUrl) URL.revokeObjectURL(backgroundPreviewUrl);
    backgroundPreviewUrl = backgroundFile ? URL.createObjectURL(backgroundFile) : null;
  }

  async function save() {
    error = '';
    notice = '';
    saving = true;
    try {
      const response = await upsertPosterTemplate(competitionId, { layers }, backgroundFile ?? undefined);
      backgroundUrl = response.backgroundUrl;
      backgroundFile = null;
      if (backgroundPreviewUrl) URL.revokeObjectURL(backgroundPreviewUrl);
      backgroundPreviewUrl = null;
      if (backgroundInput) backgroundInput.value = '';
      notice = 'Plantilla guardada correctamente.';
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo guardar la plantilla.';
    } finally {
      saving = false;
    }
  }

  function openPreview() {
    previewMatchId = null;
    previewUrl = null;
    showPreview = true;
  }

  function closePreview() {
    showPreview = false;
    if (previewUrl) URL.revokeObjectURL(previewUrl);
    previewUrl = null;
  }

  async function generatePreview() {
    if (previewMatchId == null) {
      error = 'Selecciona un partido para previsualizar.';
      return;
    }
    error = '';
    previewing = true;
    try {
      previewUrl = await fetchPosterTemplatePreview(competitionId, previewMatchId);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo generar la vista previa.';
    } finally {
      previewing = false;
    }
  }

  function backgroundSource(layer: PosterLayer): string | null {
    if (layer.isBackground) return backgroundPreviewUrl ?? backgroundUrl;
    const src = layer.src ?? '';
    if (!src || src.includes('{{')) return null;
    return src;
  }
</script>

<svelte:head><title>Plantilla de placa | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div>
      <p class="eyebrow">Competencia</p>
      <h1>Plantilla de placa</h1>
      <p class="muted">{tournamentName || `Torneo ${competitionId}`} · 1080×1920</p>
    </div>
    <a class="button secondary" href="/tournaments">Volver a torneos</a>
  </header>

  {#if loading}
    <section class="loading-card">Cargando plantilla...</section>
  {:else}
    {#if error}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}

    <section class="toolbar card-surface">
      <button class="button secondary" onclick={() => backgroundInput?.click()} disabled={!canManage || saving}>
        Cambiar fondo
      </button>
      <input class="visually-hidden" type="file" bind:this={backgroundInput} onchange={handleBackgroundChange} accept="image/*" disabled={!canManage || saving} />
      <button class="button secondary" onclick={addTextLayer} disabled={!canManage || saving}>Agregar texto</button>
      <button class="button secondary" onclick={addShapeLayer} disabled={!canManage || saving}>Agregar banda</button>
      <button class="button secondary" onclick={() => addLogoLayer(true)} disabled={!canManage || saving}>Logo local</button>
      <button class="button secondary" onclick={() => addLogoLayer(false)} disabled={!canManage || saving}>Logo visita</button>
      <span class="spacer"></span>
      <button class="button secondary" onclick={openPreview} disabled={!canManage || saving}>Previsualizar</button>
      <button class="button primary" onclick={save} disabled={!canManage || saving}>{saving ? 'Guardando...' : 'Guardar'}</button>
    </section>

    <div class="editor-layout">
      <section class="canvas-column">
        <div class="canvas-wrap" bind:this={canvasWrap} style="height: {CANVAS_H * scale}px;">
          <div class="canvas" bind:this={canvasEl} style="transform: scale({scale});">
            {#each layers as layer, i (layer.id)}
              <div
                class="layer"
                class:selected={selectedId === layer.id}
                class:locked={layer.locked}
                style="left:{layer.x}px; top:{layer.y}px; width:{layer.width}px; height:{layer.height}px; opacity:{layer.opacity ?? 1}; transform: rotate({layer.rotation ?? 0}deg);"
                onpointerdown={(e) => startDrag(layer, 'move', e)}
                onpointermove={(e) => moveDrag(layer, e)}
                onpointerup={endDrag}
                onpointercancel={endDrag}
                role="button"
                tabindex="0"
              >
                {#if layer.type === 'image'}
                  {@const src = backgroundSource(layer)}
                  {#if src}
                    <img class="layer-img" src={src} alt="" style="object-fit:{layer.fit ?? 'cover'};" />
                  {:else}
                    <div class="layer-placeholder">{layer.isBackground ? 'Fondo' : 'Logo'}</div>
                  {/if}
                {:else if layer.type === 'shape'}
                  <div class="layer-shape" style="background:{layer.fill ?? '#000000'}; border-radius:{layer.radius ?? 0}px;"></div>
                {:else}
                  <div
                    class="layer-text"
                    style="font-size:{layer.fontSize ?? 48}px; color:{layer.color ?? '#ffffff'}; font-family:{layer.fontFamily || 'sans-serif'}; font-weight:{layer.fontWeight ?? 'normal'}; font-style:{layer.fontStyle ?? 'normal'}; text-align:{layer.align ?? 'left'};"
                  >{layer.text}</div>
                {/if}

                {#if selectedId === layer.id && !layer.locked}
                  <!-- svelte-ignore a11y_no_static_element_interactions -->
                  <span class="handle resize-handle" onpointerdown={(e) => startDrag(layer, 'resize', e)} onpointermove={(e) => moveDrag(layer, e)} onpointerup={endDrag}></span>
                  <!-- svelte-ignore a11y_no_static_element_interactions -->
                  <span class="handle rotate-handle" onpointerdown={(e) => startDrag(layer, 'rotate', e)} onpointermove={(e) => moveDrag(layer, e)} onpointerup={endDrag}></span>
                {/if}
              </div>
            {/each}
          </div>
        </div>
        {#if backgroundFile}<p class="muted" style="text-align:center;font-size:.78rem;">Fondo pendiente: {backgroundFile.name}</p>{/if}
      </section>

      <section class="inspector card-surface">
        <div class="list-header">
          <div><p class="eyebrow">Capas</p><h2>Configuración</h2></div>
        </div>

        <ul class="layer-list">
          {#each layers as layer, i (layer.id)}
            <!-- svelte-ignore a11y_click_events_have_key_events a11y_no_noninteractive_element_interactions -->
            <li class:selected={selectedId === layer.id} onclick={() => selectedId = layer.id}>
              <span class="layer-type">{layer.type === 'text' ? 'T' : layer.type === 'shape' ? 'S' : 'I'}</span>
              <span class="layer-label">{layer.isBackground ? 'Fondo' : layer.type === 'text' ? (layer.text ?? 'Texto') : layer.type === 'shape' ? 'Banda' : (layer.src ?? 'Imagen')}</span>
              {#if canManage}
                <button class="mini-btn" onclick={(e) => { e.stopPropagation(); toggleLock(layer.id); }} title="Bloquear/desbloquear">{layer.locked ? '🔒' : '🔓'}</button>
                <button class="mini-btn" onclick={(e) => { e.stopPropagation(); moveLayer(layer.id, -1); }} disabled={i === 0} title="Subir">↑</button>
                <button class="mini-btn" onclick={(e) => { e.stopPropagation(); moveLayer(layer.id, 1); }} disabled={i === layers.length - 1} title="Bajar">↓</button>
                <button class="mini-btn danger" onclick={(e) => { e.stopPropagation(); removeLayer(layer.id); }} title="Eliminar">✕</button>
              {/if}
            </li>
          {/each}
        </ul>

        {#if selected}
          <div class="props">
            <p class="eyebrow">Propiedades</p>
            <div class="prop-row">
              <label>X<input type="number" value={selected.x} oninput={(e) => (selected.x = Number(e.currentTarget.value) || 0)} disabled={!canManage} /></label>
              <label>Y<input type="number" value={selected.y} oninput={(e) => (selected.y = Number(e.currentTarget.value) || 0)} disabled={!canManage} /></label>
            </div>
            <div class="prop-row">
              <label>Ancho<input type="number" value={selected.width} oninput={(e) => (selected.width = Number(e.currentTarget.value) || 0)} disabled={!canManage} /></label>
              <label>Alto<input type="number" value={selected.height} oninput={(e) => (selected.height = Number(e.currentTarget.value) || 0)} disabled={!canManage} /></label>
            </div>
            <div class="prop-row">
              <label>Opacidad<input type="number" min="0" max="1" step="0.05" value={selected.opacity ?? 1} oninput={(e) => (selected.opacity = Math.min(1, Math.max(0, Number(e.currentTarget.value) || 0)))} disabled={!canManage} /></label>
              <label>Rotación<input type="number" step="1" value={selected.rotation ?? 0} oninput={(e) => (selected.rotation = Number(e.currentTarget.value) || 0)} disabled={!canManage} /></label>
            </div>

            {#if selected.type === 'text'}
              <label class="full">Texto<textarea rows="2" bind:value={selected.text} disabled={!canManage}></textarea></label>
              <div class="prop-row">
                <label>Tamaño<input type="number" value={selected.fontSize ?? 48} oninput={(e) => (selected.fontSize = Number(e.currentTarget.value) || 0)} disabled={!canManage} /></label>
                <label>Color<input type="color" bind:value={selected.color} disabled={!canManage} style="height:2.1rem;padding:.1rem;" /></label>
              </div>
              <label class="full">Alineación
                <select bind:value={selected.align} disabled={!canManage}>
                  {#each ALIGNS as [value, label]}<option value={value}>{label}</option>{/each}
                </select>
              </label>
              <label class="full">Tipografía
                <select bind:value={selected.fontFamily} disabled={!canManage}>
                  {#each FONT_FAMILIES as font}<option value={font}>{font || 'Predeterminada'}</option>{/each}
                </select>
              </label>
              <div class="prop-row">
                <label>Peso
                  <select bind:value={selected.fontWeight} disabled={!canManage}>
                    {#each FONT_WEIGHTS as weight}<option value={weight}>{weight}</option>{/each}
                  </select>
                </label>
                <label>Estilo
                  <select bind:value={selected.fontStyle} disabled={!canManage}>
                    {#each FONT_STYLES as style}<option value={style}>{style}</option>{/each}
                  </select>
                </label>
              </div>
            {:else if selected.type === 'image'}
              <label class="full">Src<input bind:value={selected.src} disabled={!canManage || selected.isBackground} /></label>
              <label class="full">Ajuste
                <select bind:value={selected.fit} disabled={!canManage}>
                  <option value="cover">Cubrir</option>
                  <option value="contain">Contener</option>
                </select>
              </label>
            {:else if selected.type === 'shape'}
              <div class="prop-row">
                <label>Relleno<input type="color" bind:value={selected.fill} disabled={!canManage} style="height:2.1rem;padding:.1rem;" /></label>
                <label>Radio<input type="number" value={selected.radius ?? 0} oninput={(e) => (selected.radius = Number(e.currentTarget.value) || 0)} disabled={!canManage} /></label>
              </div>
            {/if}
          </div>
        {:else}
          <p class="muted">Selecciona una capa para editar sus propiedades.</p>
        {/if}
      </section>
    </div>

    <section class="card-surface tokens">
      <div class="list-header">
        <div><p class="eyebrow">Placeholders</p><h2>Tokens disponibles</h2></div>
      </div>
      {#if tokens.length === 0}
        <p class="muted">No hay tokens disponibles.</p>
      {:else}
        <ul class="token-list">
          {#each tokens as token}
            <li>
              <button class="token-btn" onclick={() => insertToken(token)} disabled={!canManage} title="Insertar en la capa de texto seleccionada">
                <code>&#123;&#123;{token.token}&#125;&#125;</code>
              </button>
              <span>{token.description}</span>
            </li>
          {/each}
        </ul>
      {/if}
    </section>
  {/if}
</main>

{#if showPreview}
  <Modal onclose={closePreview} wide>
    <div class="preview-modal">
      <p class="eyebrow">Vista previa</p>
      <h2>Placa con datos reales</h2>
      <div class="preview-controls">
        <label class="full">Partido
          <select bind:value={previewMatchId}>
            <option value={null}>Seleccionar partido...</option>
            {#each matches as m}<option value={m.id}>{m.label}</option>{/each}
          </select>
        </label>
        <button class="button primary" onclick={generatePreview} disabled={previewing || previewMatchId == null}>
          {previewing ? 'Generando...' : 'Generar vista previa'}
        </button>
      </div>
      {#if matches.length === 0}<p class="muted">Este torneo aún no tiene partidos generados.</p>{/if}
      {#if error}<p class="form-error">{error}</p>{/if}
      {#if previewUrl}
        <div class="preview-frame"><img src={previewUrl} alt="Vista previa de la placa" /></div>
      {/if}
    </div>
  </Modal>
{/if}

<style>
  .visually-hidden {
    position: absolute; width: 1px; height: 1px; padding: 0; margin: -1px;
    overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; border: 0;
  }

  .toolbar {
    display: flex; flex-wrap: wrap; gap: .5rem; align-items: center;
    padding: .75rem; margin-bottom: 1.25rem;
  }
  .toolbar .spacer { flex: 1; }

  .editor-layout {
    display: grid; grid-template-columns: minmax(0, 1fr) minmax(280px, 380px);
    gap: 1.25rem; align-items: start;
  }
  .canvas-column { display: flex; flex-direction: column; align-items: center; }

  .canvas-wrap {
    position: relative; width: 100%; max-width: 400px;
  }
  .canvas {
    position: absolute; top: 0; left: 0; width: 1080px; height: 1920px;
    transform-origin: top left;
    background: repeating-conic-gradient(#111 0% 25%, #1b1b1b 0% 50%) 0 0 / 24px 24px;
    overflow: visible;
  }
  .layer {
    position: absolute; box-sizing: border-box; cursor: move; touch-action: none;
  }
  .layer.locked { cursor: default; }
  .layer.selected { outline: 2px solid #3b82f6; }
  .layer-img, .layer-shape { width: 100%; height: 100%; display: block; }
  .layer-placeholder {
    width: 100%; height: 100%; display: grid; place-items: center;
    background: rgba(0,0,0,.25); color: #fff; font-size: 36px; font-weight: 600;
    border: 2px dashed rgba(255,255,255,.4);
  }
  .layer-text {
    width: 100%; height: 100%; white-space: pre-wrap; overflow: hidden;
    line-height: 1.2; word-break: break-word;
  }
  .handle {
    position: absolute; background: #3b82f6; border: 2px solid #fff;
    border-radius: 50%; width: 22px; height: 22px; z-index: 5; display: block;
  }
  .resize-handle { right: -11px; bottom: -11px; cursor: nwse-resize; }
  .rotate-handle { left: 50%; top: -32px; transform: translateX(-50%); cursor: grab; }
  .rotate-handle::after {
    content: ''; position: absolute; left: 50%; bottom: 100%; width: 2px;
    height: 10px; background: #3b82f6; transform: translateX(-50%);
  }

  .inspector { padding: 1rem; }
  .layer-list { list-style: none; margin: 0 0 1rem; padding: 0; display: grid; gap: .3rem; max-height: 220px; overflow-y: auto; }
  .layer-list li {
    display: flex; align-items: center; gap: .5rem; padding: .35rem .5rem;
    border: 1px solid var(--color-border); border-radius: .5rem; cursor: pointer;
    font-size: .8rem; background: var(--color-surface-hover);
  }
  .layer-list li.selected { border-color: var(--color-accent); }
  .layer-type {
    width: 20px; height: 20px; border-radius: 4px; display: grid; place-items: center;
    background: var(--color-accent); color: #fff; font-size: .68rem; font-weight: 700; flex-shrink: 0;
  }
  .layer-label { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .mini-btn {
    border: 0; background: transparent; cursor: pointer; font-size: .78rem;
    color: var(--color-text-muted); padding: .1rem .2rem; border-radius: .3rem;
  }
  .mini-btn:hover { background: var(--color-surface); }
  .mini-btn.danger { color: var(--color-error); }
  .mini-btn:disabled { opacity: .35; cursor: default; }

  .props { display: grid; gap: .6rem; }
  .prop-row { display: grid; grid-template-columns: 1fr 1fr; gap: .6rem; }
  .props label, .preview-controls label { display: block; font-size: .78rem; color: var(--color-text-muted); }
  .props input, .props select, .props textarea,
  .preview-controls select {
    width: 100%; margin-top: .2rem; padding: .45rem .55rem;
    border: 1px solid var(--color-input-border); border-radius: .5rem;
    background: var(--color-input); color: var(--color-text); font-family: inherit; font-size: .85rem;
  }
  .props label.full { grid-column: 1 / -1; }

  .tokens { margin-top: 1.25rem; padding: 1rem; }
  .token-list { list-style: none; margin: 0; padding: 0; display: grid; gap: .5rem; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); }
  .token-list li { display: flex; align-items: center; gap: .6rem; font-size: .8rem; }
  .token-btn {
    border: 1px solid var(--color-border); background: var(--color-surface-hover);
    border-radius: .5rem; cursor: pointer; padding: .35rem .5rem; flex-shrink: 0;
  }
  .token-btn:hover { border-color: var(--color-accent); }
  .token-btn code {
    font-family: ui-monospace, 'SF Mono', Menlo, monospace; font-size: .75rem;
    color: var(--color-accent-text);
  }

  .preview-modal h2 { margin: .4rem 0 1rem; font-family: 'Space Grotesk', sans-serif; }
  .preview-controls { display: flex; align-items: flex-end; gap: .75rem; margin-bottom: 1rem; }
  .preview-controls .full { flex: 1; }
  .preview-controls .button { flex-shrink: 0; }
  .preview-frame { display: flex; align-items: center; justify-content: center; max-height: 70vh; overflow: auto; }
  .preview-frame img {
    max-width: 100%; max-height: 70vh; width: auto; height: auto; object-fit: contain;
    border: 1px solid var(--color-border); border-radius: .75rem;
  }
  .form-error { color: var(--color-error); font-size: .85rem; }

  @media (max-width: 860px) {
    .editor-layout { grid-template-columns: 1fr; }
  }
</style>
