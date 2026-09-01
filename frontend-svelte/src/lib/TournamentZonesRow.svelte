<script lang="ts">
  import { onMount } from 'svelte';
  import type { HomeMatchday, HomeTournament } from './api';

  interface Props {
    tournament: HomeTournament;
  }

  let { tournament }: Props = $props();

  let scrollEl: HTMLDivElement;
  let isDragging = $state(false);
  let isHovered = $state(false);
  let dragStartX = 0;
  let dragStartScroll = 0;
  let dragMoved = false;

  function tick() {
    if (!scrollEl || isDragging || isHovered || scrollEl.scrollWidth <= scrollEl.clientWidth) return;
    scrollEl.scrollLeft += 0.5;
    if (scrollEl.scrollLeft + scrollEl.clientWidth >= scrollEl.scrollWidth - 1) scrollEl.scrollLeft = 0;
  }

  onMount(() => {
    const timer = window.setInterval(tick, 16);
    return () => window.clearInterval(timer);
  });

  function startDrag(event: PointerEvent) {
    if (!scrollEl) return;
    isDragging = true;
    dragMoved = false;
    dragStartX = event.clientX;
    dragStartScroll = scrollEl.scrollLeft;
  }

  function moveDrag(event: PointerEvent) {
    if (!isDragging || !scrollEl) return;
    const distance = event.clientX - dragStartX;
    if (Math.abs(distance) > 4) {
      dragMoved = true;
      if (!scrollEl.hasPointerCapture(event.pointerId)) scrollEl.setPointerCapture(event.pointerId);
    }
    scrollEl.scrollLeft = dragStartScroll - distance;
  }

  function endDrag(event: PointerEvent) {
    if (!isDragging) return;
    isDragging = false;
    if (scrollEl?.hasPointerCapture(event.pointerId)) scrollEl.releasePointerCapture(event.pointerId);
  }

  function handleClick(event: MouseEvent) {
    if (dragMoved) {
      event.preventDefault();
      event.stopPropagation();
    }
  }

  function formatNextMatchday(md: HomeMatchday | null): string {
    if (!md) return 'Sin próxima fecha';
    const base = `Fecha ${md.matchday}`;
    if (!md.date) return base;
    const d = new Date(md.date);
    if (isNaN(d.getTime())) return base;
    const days = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    const weekday = days[d.getUTCDay()];
    const dd = String(d.getUTCDate()).padStart(2, '0');
    const mm = String(d.getUTCMonth() + 1).padStart(2, '0');
    return `${weekday} ${dd}/${mm} - Fecha ${md.matchday}`;
  }
</script>

<section class="tournament-row">
  <header class="row-header">
    <h3>{tournament.leagueName} {tournament.name} · {tournament.year}</h3>
  </header>

  <div
    class="zones-track"
    class:dragging={isDragging}
    role="region"
    aria-label={`Zonas de ${tournament.leagueName} ${tournament.name} ${tournament.year}`}
    bind:this={scrollEl}
    onpointerenter={() => (isHovered = true)}
    onpointerleave={() => (isHovered = false)}
    onpointerdown={startDrag}
    onpointermove={moveDrag}
    onpointerup={endDrag}
    onpointercancel={endDrag}
  >
    {#each tournament.zones as zone}
      <article class="zone-card">
        <div class="zone-title-row">
          <h4>Zona {zone.name}</h4>
          <div class="zone-actions">
            <a class="zone-btn" href={`/fixtures?torneo=${tournament.id}&zona=${zone.id}`} onclick={handleClick}>Fixture</a>
            <a class="zone-btn" href={`/standings?torneo=${tournament.id}&zona=${zone.id}`} onclick={handleClick}>Tabla</a>
          </div>
        </div>

        {#if zone.top.length}
          <div class="standings">
            {#each zone.top as row, index}
              <div class="stand-row">
                <span class="stand-pos">{index + 1}</span>
                <span class="stand-club">{row.clubName}</span>
                <span class="stand-pts">{row.points} pts</span>
              </div>
            {/each}
          </div>
        {:else}
          <p class="muted compact">Todavía no hay posiciones.</p>
        {/if}

        <div class="zone-footer">
          {#if zone.nextMatchday}Próxima Fecha: {formatNextMatchday(zone.nextMatchday)}{:else}Sin próxima fecha{/if}
        </div>
      </article>
    {/each}
  </div>
</section>

<style>
  .tournament-row { margin-bottom: 1.5rem; }
  .row-header { margin-bottom: .75rem; }
  .row-header h3 {
    margin: 0;
    font-family: 'Space Grotesk', sans-serif;
    font-size: 1.15rem;
    letter-spacing: -.02em;
    color: var(--color-accent-text);
  }
  .zones-track {
    display: flex;
    gap: 1rem;
    overflow-x: auto;
    padding: .25rem .1rem .5rem;
    scrollbar-width: none;
    cursor: grab;
    touch-action: pan-y;
    user-select: none;
    -webkit-overflow-scrolling: touch;
  }
  .zones-track::-webkit-scrollbar { display: none; }
  .zones-track.dragging { cursor: grabbing; }
  .zone-card {
    flex: 0 0 auto;
    display: flex;
    flex-direction: column;
    width: min(340px, 85vw);
    padding: 1.25rem;
    border: 1px solid var(--color-border);
    border-radius: 1.2rem;
    background: var(--color-surface);
    box-shadow: 0 16px 45px var(--color-shadow);
  }
  .zone-title-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: .75rem;
  }
  .zone-title-row h4 {
    margin: 0;
    font-family: 'Space Grotesk', sans-serif;
    font-size: 1.25rem;
    letter-spacing: -.02em;
    min-width: 0;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .zone-actions {
    display: flex;
    gap: .35rem;
    flex: 0 0 auto;
  }
  .zone-btn {
    display: inline-flex;
    align-items: center;
    padding: .35rem .6rem;
    border: 1px solid var(--color-border);
    border-radius: .55rem;
    color: var(--color-accent-text);
    background: var(--color-accent-bg);
    font-size: .74rem;
    font-weight: 700;
    text-decoration: none;
    white-space: nowrap;
    transition: background 150ms ease, border-color 150ms ease;
  }
  .zone-btn:hover { background: var(--color-accent); border-color: var(--color-accent); color: #fff; }
  .standings { margin-top: .9rem; }
  .stand-row {
    display: flex;
    align-items: center;
    gap: .5rem;
    padding: .4rem 0;
    border-top: 1px solid var(--color-border);
    font-size: .88rem;
  }
  .stand-pos {
    width: 1.35rem;
    height: 1.35rem;
    display: grid;
    place-items: center;
    border-radius: 50%;
    color: var(--color-accent-text);
    background: var(--color-accent-bg);
    font-size: .68rem;
    font-weight: 700;
    flex: 0 0 auto;
  }
  .stand-club {
    min-width: 0;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    font-weight: 500;
  }
  .stand-pts {
    margin-left: auto;
    color: var(--color-text-muted);
    font-size: .78rem;
    font-weight: 700;
    white-space: nowrap;
  }
  .zone-footer {
    margin-top: auto;
    padding-top: .6rem;
    border-top: 1px solid var(--color-border);
    color: var(--color-accent-text);
    font-size: .78rem;
    font-weight: 600;
  }
  .muted { color: var(--color-text-muted); }
  .compact { font-size: .85rem; }
</style>
