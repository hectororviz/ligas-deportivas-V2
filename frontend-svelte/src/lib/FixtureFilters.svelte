<script lang="ts">
  import type { League, Tournament, Zone } from './api';

  interface Props {
    leagues: League[];
    tournaments: Tournament[];
    zones: Zone[];
    leagueId: number | null;
    tournamentId: number | null;
    zoneId: number | null;
    onLeagueChange: (id: number | null) => void;
    onTournamentChange: (id: number | null) => void;
    onZoneChange: (id: number | null) => void;
  }

  let {
    leagues,
    tournaments,
    zones,
    leagueId,
    tournamentId,
    zoneId,
    onLeagueChange,
    onTournamentChange,
    onZoneChange,
  }: Props = $props();

  let filteredTournaments = $derived(
    tournaments.filter((t) => !leagueId || t.leagueId === leagueId)
  );
  let filteredZones = $derived(
    zones.filter((z) => !tournamentId || z.tournamentId === tournamentId)
  );

  function toNum(value: string): number | null {
    if (value === '') return null;
    const n = Number(value);
    return Number.isFinite(n) ? n : null;
  }
</script>

<div class="fixture-filters">
  <label class="filter-field">
    <span class="filter-label">Liga</span>
    <select value={leagueId ?? ''} onchange={(e) => onLeagueChange(toNum(e.currentTarget.value))}>
      <option value="">Todas las ligas</option>
      {#each leagues as league}
        <option value={league.id}>{league.name}</option>
      {/each}
    </select>
  </label>

  <label class="filter-field">
    <span class="filter-label">Torneo</span>
    <select
      value={tournamentId ?? ''}
      disabled={!leagueId}
      onchange={(e) => onTournamentChange(toNum(e.currentTarget.value))}
    >
      <option value="">Todos los torneos</option>
      {#each filteredTournaments as tournament}
        <option value={tournament.id}>{tournament.name} {tournament.year}</option>
      {/each}
    </select>
  </label>

  <label class="filter-field">
    <span class="filter-label">Zona</span>
    <select
      value={zoneId ?? ''}
      disabled={!tournamentId}
      onchange={(e) => onZoneChange(toNum(e.currentTarget.value))}
    >
      <option value="">Todas las zonas</option>
      {#each filteredZones as zone}
        <option value={zone.id}>Zona {zone.name}</option>
      {/each}
    </select>
  </label>
</div>

<style>
  .fixture-filters {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    gap: .75rem;
    padding: 1.25rem;
    border: 1px solid var(--color-border);
    border-radius: 1rem;
    background: var(--color-surface);
  }
  .filter-field {
    display: grid;
    gap: .4rem;
  }
  .filter-label {
    color: var(--color-text-muted);
    font-size: .74rem;
    font-weight: 700;
    letter-spacing: .12em;
    text-transform: uppercase;
  }
  select {
    width: 100%;
    border: 1px solid var(--color-input-border);
    border-radius: .7rem;
    padding: .75rem .9rem;
    color: var(--color-text);
    background: var(--color-input);
    outline: none;
  }
  select:focus {
    border-color: var(--color-input-focus);
    box-shadow: 0 0 0 3px color-mix(in srgb, var(--color-input-focus) 33%, transparent);
  }
  select:disabled {
    opacity: .5;
    cursor: not-allowed;
  }
</style>
