<script lang="ts">
  import type { Club } from './api';

  interface Props {
    clubs: Club[];
    selectedClubId: number | null;
    onSelect: (clubId: number | null) => void;
  }

  let { clubs, selectedClubId, onSelect }: Props = $props();
  let scrollEl: HTMLDivElement;
  let isDragging = $state(false);
  let dragStartX = 0;
  let dragStartScroll = 0;
  let dragMoved = false;

  $effect(() => {
    const timer = window.setInterval(() => {
      if (!scrollEl || isDragging || scrollEl.scrollWidth <= scrollEl.clientWidth) return;
      scrollEl.scrollLeft += 0.35;
      if (scrollEl.scrollLeft + scrollEl.clientWidth >= scrollEl.scrollWidth - 1) scrollEl.scrollLeft = 0;
    }, 16);
    return () => window.clearInterval(timer);
  });

  function startDrag(event: PointerEvent) {
    if (!scrollEl) return;
    isDragging = true;
    dragMoved = false;
    dragStartX = event.clientX;
    dragStartScroll = scrollEl.scrollLeft;
    scrollEl.setPointerCapture(event.pointerId);
  }

  function moveDrag(event: PointerEvent) {
    if (!isDragging || !scrollEl) return;
    const distance = event.clientX - dragStartX;
    if (Math.abs(distance) > 4) dragMoved = true;
    scrollEl.scrollLeft = dragStartScroll - distance;
  }

  function endDrag(event: PointerEvent) {
    if (!isDragging) return;
    isDragging = false;
    if (scrollEl?.hasPointerCapture(event.pointerId)) scrollEl.releasePointerCapture(event.pointerId);
  }

  function selectClub(event: MouseEvent, clubId: number) {
    if (dragMoved) {
      event.preventDefault();
      return;
    }
    onSelect(clubId);
  }

  function label(club: Club): string {
    return club.shortName?.trim() || club.name;
  }

  function initials(club: Club): string {
    return label(club).split(/\s+/).slice(0, 2).map((part) => part[0]).join('').toUpperCase();
  }
</script>

<section class="club-filter" aria-label="Filtrar por club">
  <div
    class="club-track"
    class:dragging={isDragging}
    role="region"
    aria-label="Clubes participantes"
    bind:this={scrollEl}
    onpointerdown={startDrag}
    onpointermove={moveDrag}
    onpointerup={endDrag}
    onpointercancel={endDrag}
  >
      {#each clubs as club (club.id)}
        <button
          class="club-chip"
          class:selected={selectedClubId === club.id}
          type="button"
          onclick={(event) => selectClub(event, club.id)}
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
  {#if selectedClubId != null}
    <button class="clear-button" type="button" onclick={() => onSelect(null)}>Ver todos</button>
  {/if}
</section>

<style>
  .club-filter { display: flex; align-items: center; gap: .75rem; min-width: 0; margin-bottom: 1rem; }
  .clear-button { flex: 0 0 auto; border: 0; background: transparent; color: var(--color-accent-text); cursor: pointer; font-size: .78rem; font-weight: 700; white-space: nowrap; }
  .club-track { display: flex; flex: 1; min-width: 0; gap: .9rem; overflow-x: auto; padding: .25rem .1rem .5rem; scrollbar-width: none; cursor: grab; touch-action: pan-y; user-select: none; }
  .club-track::-webkit-scrollbar { display: none; }
  .club-track.dragging { cursor: grabbing; }
  .club-chip { display: inline-flex; flex: 0 0 auto; align-items: center; flex-direction: column; gap: .35rem; max-width: 6rem; padding: .2rem .35rem; border: 0; background: transparent; color: var(--color-text-muted); cursor: pointer; font-size: .68rem; font-weight: 650; line-height: 1.1; text-align: center; white-space: normal; }
  .club-chip:hover { color: var(--color-text); }
  .club-chip.selected { color: var(--color-accent-text); }
  .club-logo { display: grid; flex: 0 0 auto; width: 3rem; height: 3rem; place-items: center; overflow: hidden; border-radius: 50%; background: var(--color-input); color: var(--color-accent-text); font-size: .8rem; font-weight: 800; transition: box-shadow 150ms ease, transform 150ms ease; }
  .club-chip.selected .club-logo { box-shadow: 0 0 0 3px var(--color-accent); transform: scale(1.04); }
  .club-logo img { width: 100%; height: 100%; object-fit: contain; }
  @media (max-width: 560px) { .club-filter { gap: .4rem; } .club-track { gap: .65rem; } .club-chip { font-size: .64rem; } }
</style>
