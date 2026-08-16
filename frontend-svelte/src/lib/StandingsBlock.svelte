<script lang="ts">
  import type { Zone, ZoneStanding } from './api';

  interface Props {
    zone: Zone;
    standing: ZoneStanding;
  }

  let { zone, standing }: Props = $props();

  function formatStandingHeaders(): string[] {
    return ['Pos', 'Club', 'J', 'G', 'E', 'P', 'GF', 'GC', 'DG', 'Pts'];
  }
</script>

<section class="standings-section">
  <div class="zone-heading">
    <div>
      <p class="eyebrow">{zone.tournament.league.name} · {zone.tournament.name}</p>
      <h2>Zona {zone.name}</h2>
    </div>
  </div>

  {#each standing.categories as category}
    <div class="category-block">
      <h3 class="category-title">{category.categoryName}</h3>
      {#if category.standings.length === 0}
        <p class="muted compact">Sin posiciones en esta categoría.</p>
      {:else}
        <div class="table-scroll">
          <table class="standings-table">
            <thead>
              <tr>
                {#each formatStandingHeaders() as header}
                  <th>{header}</th>
                {/each}
              </tr>
            </thead>
            <tbody>
              {#each category.standings as row, index}
                <tr>
                  <td><span class="position">{index + 1}</span></td>
                  <td>{row.clubName}</td>
                  <td>{row.played}</td>
                  <td>{row.wins}</td>
                  <td>{row.draws}</td>
                  <td>{row.losses}</td>
                  <td>{row.goalsFor}</td>
                  <td>{row.goalsAgainst}</td>
                  <td>{row.goalDifference}</td>
                  <td class="pts">{row.points}</td>
                </tr>
              {/each}
            </tbody>
          </table>
        </div>
      {/if}
    </div>
  {/each}
</section>

<style>
  .standings-section { padding: 1.25rem 0; border-bottom: 1px solid var(--color-border); }
  .zone-heading h2 { margin: .25rem 0 0; font-family: 'Space Grotesk', sans-serif; font-size: 1.5rem; letter-spacing: -.04em; }
  .zone-heading .eyebrow { margin: 0; }
  .category-block { margin-top: 1.5rem; }
  .category-title { margin: 0 0 .8rem; font-family: 'Space Grotesk', sans-serif; font-size: 1.15rem; color: var(--color-text); }
  .table-scroll { overflow-x: auto; }
  .standings-table { width: 100%; min-width: 620px; border-collapse: collapse; font-size: .9rem; }
  .standings-table th { padding: .6rem .4rem; border-bottom: 2px solid var(--color-border); color: var(--color-accent-text); font-size: .75rem; font-weight: 700; text-transform: uppercase; text-align: center; }
  .standings-table th:nth-child(2) { text-align: left; }
  .standings-table td { padding: .55rem .4rem; border-top: 1px solid var(--color-border); text-align: center; }
  .standings-table td:nth-child(2) { text-align: left; font-weight: 600; }
  .standings-table .position { display: inline-grid; }
  .standings-table .pts { font-weight: 700; color: var(--color-heading); }
</style>
