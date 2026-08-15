<script lang="ts">
  import type { Club } from './api';
  import { ChevronLeft, ChevronRight } from '@lucide/svelte';

  interface Props {
    clubs: Club[];
    selectedClubId: number | null;
    onSelect: (clubId: number | null) => void;
  }

  let { clubs, selectedClubId, onSelect }: Props = $props();
  let scrollEl: HTMLDivElement;

  function scrollBy(direction: -1 | 1) {
    scrollEl?.scrollBy({ left: direction * 280, behavior: 'smooth' });
  }

  function label(club: Club): string {
    return club.shortName?.trim() || club.name;
  }

  function initials(club: Club): string {
    return label(club).split(/\s+/).slice(0, 2).map((part) => part[0]).join('').toUpperCase();
  }
</script>

<section class="club-filter" aria-label="Filtrar por club">
  <div class="club-heading">
    <div>
      <p class="filter-label">Club</p>
      <p class="club-help">Elegí un club para ver todos sus torneos</p>
    </div>
    {#if selectedClubId != null}
      <button class="clear-button" type="button" onclick={() => onSelect(null)}>Ver todos</button>
    {/if}
  </div>

  <div class="club-carousel">
    <button class="carousel-arrow" type="button" onclick={() => scrollBy(-1)} aria-label="Club anterior">
      <ChevronLeft size={18} />
    </button>
    <div class="club-track" bind:this={scrollEl}>
      {#each clubs as club (club.id)}
        <button
          class="club-chip"
          class:selected={selectedClubId === club.id}
          type="button"
          onclick={() => onSelect(club.id)}
          aria-pressed={selectedClubId === club.id}
          title={club.name}
        >
          <span class="club-logo">
            {#if club.logoUrl}
              <img src={club.logoUrl} alt="" />
            {:else}
              {initials(club)}
            {/if}
          </span>
          <span>{label(club)}</span>
        </button>
      {/each}
    </div>
    <button class="carousel-arrow" type="button" onclick={() => scrollBy(1)} aria-label="Club siguiente">
      <ChevronRight size={18} />
    </button>
  </div>
</section>

<style>
  .club-filter { margin-bottom: 1rem; padding: 1rem 1.25rem; border: 1px solid var(--color-border); border-radius: 1rem; background: var(--color-surface); }
  .club-heading { display: flex; align-items: center; justify-content: space-between; gap: 1rem; margin-bottom: .65rem; }
  .filter-label { margin: 0; color: var(--color-text-muted); font-size: .74rem; font-weight: 700; letter-spacing: .12em; text-transform: uppercase; }
  .club-help { margin: .2rem 0 0; color: var(--color-text-light); font-size: .78rem; }
  .clear-button { border: 0; background: transparent; color: var(--color-accent-text); cursor: pointer; font-size: .78rem; font-weight: 700; white-space: nowrap; }
  .club-carousel { display: flex; align-items: center; gap: .5rem; min-width: 0; }
  .club-track { display: flex; flex: 1; min-width: 0; gap: .55rem; overflow-x: auto; padding: .15rem .1rem; scrollbar-width: none; scroll-behavior: smooth; }
  .club-track::-webkit-scrollbar { display: none; }
  .carousel-arrow { display: grid; flex: 0 0 auto; width: 2rem; height: 2rem; place-items: center; border: 1px solid var(--color-border); border-radius: .6rem; background: var(--color-surface); color: var(--color-text-muted); cursor: pointer; }
  .carousel-arrow:hover { background: var(--color-surface-hover); color: var(--color-text); }
  .club-chip { display: inline-flex; flex: 0 0 auto; align-items: center; gap: .5rem; max-width: 12rem; padding: .4rem .75rem .4rem .4rem; border: 1px solid var(--color-border); border-radius: 999px; background: var(--color-surface); color: var(--color-text-muted); cursor: pointer; font-size: .8rem; font-weight: 650; white-space: nowrap; }
  .club-chip:hover { border-color: var(--color-accent); color: var(--color-text); }
  .club-chip.selected { border-color: var(--color-accent); background: var(--color-accent-bg); color: var(--color-accent-text); }
  .club-logo { display: grid; flex: 0 0 auto; width: 2rem; height: 2rem; place-items: center; overflow: hidden; border-radius: 50%; background: var(--color-input); color: var(--color-accent-text); font-size: .65rem; font-weight: 800; }
  .club-logo img { width: 100%; height: 100%; object-fit: contain; }
  @media (max-width: 560px) { .club-filter { padding: .9rem; } .club-help { font-size: .72rem; } }
</style>
