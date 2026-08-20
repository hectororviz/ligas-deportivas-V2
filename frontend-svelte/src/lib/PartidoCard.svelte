<script lang="ts">
  import type { ZoneMatch } from './api';

  interface Props {
    match: ZoneMatch;
    onclick: (matchId: number) => void;
  }

  let { match, onclick }: Props = $props();

  let played = $derived(match.status === 'FINISHED' || match.categories.some((c) => c.closedAt));
  let homeName = $derived(match.homeClub?.shortName ?? match.homeClub?.name ?? '—');
  let awayName = $derived(match.awayClub?.shortName ?? match.awayClub?.name ?? '—');
</script>

<button
  class="match-card"
  class:played
  onclick={() => onclick(match.id)}
  title={played ? 'Jugado' : 'Pendiente'}
  aria-label={`${homeName} vs ${awayName}, ${played ? 'jugado' : 'pendiente'}`}
>
  <span class="team home">{homeName}</span>
  <span class="center">
    {#if played}
      <span class="score">{match.pointsHome} - {match.pointsAway}</span>
    {:else}
      <span class="divider">vs</span>
    {/if}
  </span>
  <span class="team away">{awayName}</span>
</button>

<style>
  .match-card {
    display: flex;
    align-items: center;
    gap: .75rem;
    width: 100%;
    min-width: 0;
    padding: .8rem 1rem;
    border: 1px solid var(--color-border);
    border-radius: .8rem;
    background: var(--color-surface);
    color: var(--color-text);
    cursor: pointer;
    text-align: left;
    transition: border-color 150ms ease, background 150ms ease, transform 150ms ease;
  }
  .match-card:hover {
    border-color: var(--color-accent);
    background: var(--color-surface-hover);
  }
  .match-card:active { transform: scale(.995); }

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

  .center {
    flex: 0 0 auto;
    min-width: 4.5rem;
    text-align: center;
    font-family: 'Space Grotesk', sans-serif;
  }
  .score {
    font-size: 1rem;
    font-weight: 700;
    color: var(--color-accent-text);
    white-space: nowrap;
  }
  .divider {
    color: var(--color-text-light);
    font-size: .7rem;
    font-weight: 700;
    text-transform: uppercase;
  }
</style>
