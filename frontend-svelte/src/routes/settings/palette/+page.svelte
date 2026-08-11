<script lang="ts">
  import { usePalette } from '$lib/palette.svelte';

  const paletteState = usePalette();
  let notice = $state('');
  let loaded = false;

  $effect(() => { loaded = true; });

  function selectPalette(id: string) {
    paletteState.setPalette(id);
    notice = `Paleta "${paletteState.palette.name}" aplicada.`;
    setTimeout(() => notice = '', 2500);
  }
</script>

<svelte:head><title>Paleta de colores | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div><p class="eyebrow">Apariencia</p><h1>Paleta de colores</h1><p class="muted">Elige la combinación de colores que se aplicará a todo el sistema.</p></div>
    <a class="button secondary" href="/settings">Volver</a>
  </header>

  {#if notice}<p class="success-banner">{notice}</p>{/if}

  <section class="card-surface">
    <div class="palette-grid">
      {#each paletteState.palettes as palette}
        <button
          class="palette-swatch"
          class:selected={palette.id === paletteState.id}
          onclick={() => selectPalette(palette.id)}
          aria-label={`Seleccionar paleta ${palette.name}`}
        >
          <div class="palette-dots">
            <span class="palette-dot" style={`background:${palette.colors.hero}`}></span>
            <span class="palette-dot" style={`background:${palette.colors.accent}`}></span>
            <span class="palette-dot" style={`background:${palette.colors.surface}`}></span>
            <span class="palette-dot" style={`background:${palette.colors.text}`}></span>
            <span class="palette-dot" style={`background:${palette.colors.accentLight}`}></span>
          </div>
          <strong>{palette.name}</strong>
        </button>
      {/each}
    </div>
  </section>
</main>
