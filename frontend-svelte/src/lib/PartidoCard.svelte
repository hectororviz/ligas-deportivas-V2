<script lang="ts">
  import type { ZoneMatch } from './api';

  interface Props {
    match: ZoneMatch;
    onclick: (matchId: number) => void;
  }

  let { match, onclick }: Props = $props();

  let homeScore = $derived(
    match.categories.reduce((sum, c) => sum + (c.closedAt ? c.homeScore : 0), 0)
  );
  let awayScore = $derived(
    match.categories.reduce((sum, c) => sum + (c.closedAt ? c.awayScore : 0), 0)
  );
  let played = $derived(match.status === 'FINISHED' || match.categories.some((c) => c.closedAt));
</script>

<button
  class="match-card"
  class:played
  onclick={() => onclick(match.id)}
  aria-label={`${match.homeClub?.name ?? 'Local'} vs ${match.awayClub?.name ?? 'Visitante'}, ${played ? 'jugado' : 'pendiente'}`}
>
  <div class="teams">
    <span class="team home">{match.homeClub?.name ?? '—'}</span>
    <span class="divider">vs</span>
    <span class="team away">{match.awayClub?.name ?? '—'}</span>
  </div>
  <span class="status" class:played title={played ? 'Jugado' : 'Pendiente'}>
    {#if played}
      <span class="dot"></span>
      <span class="score">{homeScore} - {awayScore}</span>
    {:else}
      <span class="dot"></span>
    {/if}
  </span>
</button>

<style>
  .match-card {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: .75rem;
    width: 100%;
    min-width: 0;
    padding: .8rem 1rem;
    border: 1px solid var(--color-border);
    border-radius: .8rem;
    background: var(--color-surface);
    cursor: pointer;
    text-align: left;
    transition: border-color 150ms ease, background 150ms ease, transform 150ms ease;
  }
  .match-card:hover {
    border-color: var(--color-accent);
    background: var(--color-surface-hover);
  }
  .match-card:active { transform: scale(.995); }
  .teams {
    flex: 1;
    min-width: 0;
    display: flex;
    align-items: center;
    gap: .5rem;
  }
  .team {
    flex: 1;
    min-width: 0;
    font-size: .92rem;
    font-weight: 600;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .team.home { text-align: right; }
  .team.away { text-align: left; }
  .divider {
    flex: 0 0 auto;
    color: var(--color-text-light);
    font-size: .7rem;
    font-weight: 700;
    text-transform: uppercase;
  }
  .status {
    flex: 0 0 auto;
    display: inline-flex;
    align-items: center;
    gap: .4rem;
  }
  .dot {
    width: .6rem;
    height: .6rem;
    border-radius: 50%;
    background: var(--color-error);
    flex: 0 0 auto;
  }
  .status.played .dot { background: var(--color-success); }
  .score {
    font-family: 'Space Grotesk', sans-serif;
    font-size: 1rem;
    font-weight: 700;
    color: var(--color-accent-text);
    white-space: nowrap;
  }
</style>
