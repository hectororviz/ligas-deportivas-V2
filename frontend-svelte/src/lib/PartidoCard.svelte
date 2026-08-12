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
  aria-label={`${match.homeClub?.name ?? 'Local'} vs ${match.awayClub?.name ?? 'Visitante'}`}
>
  <div class="teams">
    <span class="team home">{match.homeClub?.name ?? '—'}</span>
    <span class="divider">vs</span>
    <span class="team away">{match.awayClub?.name ?? '—'}</span>
  </div>
  {#if played}
    <span class="score">{homeScore} - {awayScore}</span>
  {:else}
    <span class="badge-muted">Pendiente</span>
  {/if}
</button>

<style>
  .match-card {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
    width: 100%;
    padding: 1rem 1.25rem;
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
    gap: .6rem;
  }
  .team {
    flex: 1;
    min-width: 0;
    font-size: .95rem;
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
    font-size: .72rem;
    font-weight: 700;
    text-transform: uppercase;
  }
  .score {
    flex: 0 0 auto;
    font-family: 'Space Grotesk', sans-serif;
    font-size: 1.1rem;
    font-weight: 700;
    color: var(--color-heading);
  }
  .match-card.played .score { color: var(--color-accent-text); }
</style>
