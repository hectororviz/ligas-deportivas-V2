<script lang="ts">
  import type { HomeMatchday, HomeTournament } from './api';

  interface Props {
    tournament: HomeTournament;
  }

  let { tournament }: Props = $props();

  let trackEl: HTMLDivElement;
  let canLeft = $state(false);
  let canRight = $state(true);
  const GAP = 16;

  function onScroll(e: Event) {
    const t = e.currentTarget as HTMLDivElement;
    canLeft = t.scrollLeft > 4;
    canRight = t.scrollLeft + t.clientWidth < t.scrollWidth - 4;
  }

  function step(dir: number) {
    if (!trackEl) return;
    const card = trackEl.firstElementChild as HTMLElement | null;
    const cardWidth = card ? card.getBoundingClientRect().width + GAP : 0;
    if (cardWidth <= 0) return;
    trackEl.scrollBy({ left: dir * cardWidth, behavior: 'smooth' });
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

  <div class="zone-carousel">
    <button
      class="nav-btn"
      type="button"
      aria-label="Zonas anteriores"
      disabled={!canLeft}
      onclick={() => step(-1)}
    >
      <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6"></path></svg>
    </button>

    <div
      class="zones-track"
      role="region"
      aria-label={`Zonas de ${tournament.leagueName} ${tournament.name} ${tournament.year}`}
      bind:this={trackEl}
      onscroll={onScroll}
    >
      {#each tournament.zones as zone}
        <article class="zone-card">
          <div class="zone-title-row">
            <h4>Zona {zone.name}</h4>
            <div class="zone-actions">
              <a class="zone-btn" href={`/fixtures?torneo=${tournament.id}&zona=${zone.id}`}>Fixture</a>
              <a class="zone-btn" href={`/standings?torneo=${tournament.id}&zona=${zone.id}`}>Tabla</a>
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

    <button
      class="nav-btn"
      type="button"
      aria-label="Zonas siguientes"
      disabled={!canRight}
      onclick={() => step(1)}
    >
      <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 18 6-6-6-6"></path></svg>
    </button>
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

  .zone-carousel { display: flex; align-items: center; gap: .35rem; }
  .zones-track {
    flex: 1;
    min-width: 0;
    display: flex;
    gap: 1rem;
    overflow-x: auto;
    padding: .25rem .1rem .5rem;
    scrollbar-width: none;
    -webkit-overflow-scrolling: touch;
  }
  .zones-track::-webkit-scrollbar { display: none; }
  .nav-btn {
    flex: 0 0 auto;
    display: grid;
    place-items: center;
    width: 2.25rem;
    height: 2.25rem;
    border: 1px solid var(--color-border);
    border-radius: 50%;
    background: var(--color-surface);
    color: var(--color-accent-text);
    cursor: pointer;
    transition: background 150ms ease, border-color 150ms ease, opacity 150ms ease;
  }
  .nav-btn:hover { background: var(--color-accent-bg); border-color: var(--color-accent); }
  .nav-btn:disabled { opacity: .35; cursor: default; background: var(--color-surface); border-color: var(--color-border); }

  .zone-card {
    flex: 0 0 auto;
    display: flex;
    flex-direction: column;
    width: min(340px, 80vw);
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

  @media (max-width: 560px) {
    .zone-card { width: min(320px, 82vw); }
    .nav-btn { width: 2rem; height: 2rem; }
  }
</style>