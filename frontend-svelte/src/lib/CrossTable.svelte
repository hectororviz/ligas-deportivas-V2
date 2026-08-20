<script lang="ts">
  import { onMount } from 'svelte';
  import { getClubCrossTable, type ClubCrossTable, type CrossTableCell } from './api';

  interface Props {
    zoneId: number;
    clubId: number;
  }

  let { zoneId, clubId }: Props = $props();

  let data: ClubCrossTable | null = $state(null);
  let loading = $state(true);
  let error = $state('');

  onMount(async () => {
    loading = true;
    error = '';
    try {
      data = await getClubCrossTable(zoneId, clubId);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar los cruces.';
    } finally {
      loading = false;
    }
  });

  function resultClass(cell: CrossTableCell | null | undefined): string {
    if (!cell || !cell.closedAt) return 'cell-pending';
    if (cell.gf > cell.ga) return 'cell-win';
    if (cell.gf < cell.ga) return 'cell-loss';
    return 'cell-draw';
  }

  function cellLabel(cell: CrossTableCell | null | undefined): string {
    if (!cell) return '—';
    if (!cell.closedAt) return '—';
    return `${cell.gf} - ${cell.ga}`;
  }
</script>

{#if loading}
  <p class="cross-loading">Cargando cruces...</p>
{:else if error}
  <p class="form-error">{error}</p>
{:else if data}
  <div class="cross-head">
    <p class="eyebrow">{data.zone.leagueName} · {data.zone.tournamentName} {data.zone.tournamentYear}</p>
    <h2>{data.club.shortName || data.club.name} · Zona {data.zone.name}</h2>
  </div>

  {#if data.rows.length === 0}
    <p class="muted">Todavía no hay cruces para este club en esta zona.</p>
  {:else}
    <div class="table-scroll">
      <table class="cross-table">
        <thead>
          <tr>
            <th class="rival-col">Rival</th>
            {#each data.categories as category}
              <th>{category.categoryName}</th>
            {/each}
          </tr>
        </thead>
        <tbody>
          {#each data.rows as row}
            <tr>
              <td class="rival-col">
                <span class="rival-name">{row.rival?.shortName || row.rival?.name || '—'}</span>
                <span class="rival-meta">F{row.matchday} · {row.local ? 'Local' : 'Visitante'}</span>
              </td>
              {#each data.categories as category}
                {@const cell = row.cells[category.tournamentCategoryId]}
                <td class={resultClass(cell)}>{cellLabel(cell)}</td>
              {/each}
            </tr>
          {/each}
        </tbody>
      </table>
    </div>
  {/if}
{/if}

<style>
  .cross-loading { color: var(--color-text-muted); text-align: center; padding: 1.5rem 0; }
  .cross-head { margin-bottom: 1rem; }
  .cross-head .eyebrow { margin: 0; }
  .cross-head h2 {
    margin: .3rem 0 0;
    font-family: 'Space Grotesk', sans-serif;
    font-size: 1.25rem;
    letter-spacing: -.02em;
  }
  .table-scroll { overflow-x: auto; }
  .cross-table {
    width: 100%;
    min-width: 560px;
    border-collapse: collapse;
    font-size: .85rem;
  }
  .cross-table th {
    padding: .55rem .5rem;
    border-bottom: 2px solid var(--color-border);
    color: var(--color-accent-text);
    font-size: .72rem;
    font-weight: 700;
    text-transform: uppercase;
    text-align: center;
    white-space: nowrap;
  }
  .cross-table th.rival-col { text-align: left; }
  .cross-table td {
    padding: .5rem .5rem;
    border-top: 1px solid var(--color-border);
    text-align: center;
    font-weight: 600;
    white-space: nowrap;
  }
  .cross-table td.rival-col { text-align: left; }
  .rival-name { display: block; font-weight: 700; color: var(--color-heading); }
  .rival-meta { display: block; font-size: .72rem; color: var(--color-text-muted); }

  .cell-win { color: var(--color-success); }
  .cell-loss { color: var(--color-error); }
  .cell-draw { color: var(--color-warning, #b57800); }
  .cell-pending { color: var(--color-text-muted); }
</style>
