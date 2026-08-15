<script lang="ts">
  import type { ZoneMatchday } from './api';
  import { ChevronLeft, ChevronRight } from '@lucide/svelte';

  interface Props {
    matchdays: ZoneMatchday[];
    selectedMatchday: number | null;
    onSelect: (matchday: number) => void;
  }

  let { matchdays, selectedMatchday, onSelect }: Props = $props();

  let scrollEl: HTMLDivElement;

  $effect(() => {
    if (!scrollEl || selectedMatchday == null) return;
    const el = scrollEl.querySelector(`[data-matchday="${selectedMatchday}"]`);
    if (el) {
      el.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' });
    }
  });

  function scrollBy(direction: -1 | 1) {
    if (!scrollEl) return;
    scrollEl.scrollBy({ left: direction * 220, behavior: 'smooth' });
  }

  function statusClass(status: string): string {
    const map: Record<string, string> = {
      PLAYED: 'is-played',
      INCOMPLETE: 'is-played',
      IN_PROGRESS: 'is-current',
      PENDING: '',
    };
    return map[status] ?? '';
  }

  function statusLabel(status: string): string {
    const map: Record<string, string> = {
      PLAYED: 'Jugada',
      INCOMPLETE: 'Incompleta',
      IN_PROGRESS: 'En curso',
      PENDING: 'Pendiente',
    };
    return map[status] ?? status;
  }
</script>

{#if matchdays.length > 0}
  <div class="carousel">
    <button class="carousel-arrow" onclick={() => scrollBy(-1)} aria-label="Fecha anterior">
      <ChevronLeft size={18} strokeWidth={2} />
    </button>

    <div class="carousel-track" bind:this={scrollEl}>
      {#each matchdays as md}
        <button
          class="fecha-chip {statusClass(md.status)}"
          class:selected={selectedMatchday === md.matchday}
          data-matchday={md.matchday}
          onclick={() => onSelect(md.matchday)}
          aria-pressed={selectedMatchday === md.matchday}
          title={`Fecha ${md.matchday} · ${statusLabel(md.status)}`}
        >
          <span class="dot {statusClass(md.status)}"></span>
          <span class="fecha-num">Fecha {md.matchday}</span>
        </button>
      {/each}
    </div>

    <button class="carousel-arrow" onclick={() => scrollBy(1)} aria-label="Fecha siguiente">
      <ChevronRight size={18} strokeWidth={2} />
    </button>
  </div>
{/if}

<style>
  .carousel {
    display: flex;
    align-items: center;
    gap: .5rem;
    margin: 1rem 0;
    min-width: 0;
  }
  .carousel-track {
    flex: 1;
    min-width: 0;
    display: flex;
    gap: .45rem;
    overflow-x: auto;
    scroll-behavior: smooth;
    scrollbar-width: none;
    padding: .15rem .1rem;
  }
  .carousel-track::-webkit-scrollbar { display: none; }
  .carousel-arrow {
    flex: 0 0 auto;
    width: 2rem;
    height: 2rem;
    display: grid;
    place-items: center;
    border: 1px solid var(--color-border);
    border-radius: .6rem;
    background: var(--color-surface);
    color: var(--color-text-muted);
    cursor: pointer;
  }
  .carousel-arrow:hover { background: var(--color-surface-hover); color: var(--color-text); }
  .fecha-chip {
    flex: 0 0 auto;
    display: inline-flex;
    align-items: center;
    gap: .4rem;
    padding: .5rem .9rem;
    border: 1px solid var(--color-border);
    border-radius: 999px;
    background: var(--color-surface);
    color: var(--color-text-muted);
    cursor: pointer;
    font-size: .82rem;
    font-weight: 600;
    white-space: nowrap;
    transition: background 150ms ease, color 150ms ease, border-color 150ms ease;
  }
  .fecha-chip:hover { background: var(--color-surface-hover); color: var(--color-text); }
  .fecha-chip.selected {
    background: var(--color-accent-bg);
    border-color: var(--color-accent);
    color: var(--color-accent-text);
    font-weight: 700;
  }
  .dot {
    flex: 0 0 auto;
    width: .5rem;
    height: .5rem;
    border-radius: 50%;
    background: var(--color-text-light);
  }
  .dot.is-played { background: var(--color-success); }
  .dot.is-current { background: var(--color-accent); }
  .fecha-chip.is-current { border-color: var(--color-accent); border-style: dashed; }
  .fecha-num { pointer-events: none; }
</style>
