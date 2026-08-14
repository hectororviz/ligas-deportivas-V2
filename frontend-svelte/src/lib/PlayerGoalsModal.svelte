<script lang="ts">
  import { onMount } from 'svelte';
  import Modal from './Modal.svelte';
  import {
    listAssignedPlayers,
    getMatchCategoryResult,
    recordMatchResult,
    type MatchClub,
    type AssignedPlayerRow,
  } from './api';

  interface Props {
    matchId: number;
    tournamentCategoryId: number;
    categoryName: string;
    homeClub: MatchClub | null;
    awayClub: MatchClub | null;
    controlsPlayers: boolean;
    canEdit: boolean;
    onclose: () => void;
    onsaved: () => void;
  }

  let {
    matchId,
    tournamentCategoryId,
    categoryName,
    homeClub,
    awayClub,
    controlsPlayers,
    canEdit,
    onclose,
    onsaved,
  }: Props = $props();

  let loading = $state(true);
  let saving = $state(false);
  let error = $state('');
  let notice = $state('');
  let pending = $state(false);

  interface GoalRow {
    player: AssignedPlayerRow;
    goals: number;
  }

  let homeRows = $state<GoalRow[]>([]);
  let awayRows = $state<GoalRow[]>([]);
  let homeOther = $state(0);
  let awayOther = $state(0);

  let totalHome = $derived(
    homeRows.reduce((sum, r) => sum + (r.goals || 0), 0) + (homeOther || 0)
  );
  let totalAway = $derived(
    awayRows.reduce((sum, r) => sum + (r.goals || 0), 0) + (awayOther || 0)
  );

  onMount(async () => {
    loading = true;
    error = '';
    try {
      const [home, away, result] = await Promise.all([
        controlsPlayers && homeClub ? listAssignedPlayers(homeClub.id, tournamentCategoryId) : Promise.resolve([]),
        controlsPlayers && awayClub ? listAssignedPlayers(awayClub.id, tournamentCategoryId) : Promise.resolve([]),
        getMatchCategoryResult(matchId, tournamentCategoryId),
      ]);

      homeRows = home.map((p) => ({
        player: p,
        goals: result.playerGoals.find((g) => g.playerId === p.id && g.clubId === homeClub?.id)?.goals ?? 0,
      }));
      awayRows = away.map((p) => ({
        player: p,
        goals: result.playerGoals.find((g) => g.playerId === p.id && g.clubId === awayClub?.id)?.goals ?? 0,
      }));

      homeOther = result.otherGoals.find((g) => g.clubId === homeClub?.id)?.goals ?? 0;
      awayOther = result.otherGoals.find((g) => g.clubId === awayClub?.id)?.goals ?? 0;
      pending = result.isPending ?? false;
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar los datos.';
    } finally {
      loading = false;
    }
  });

  async function save() {
    if (!homeClub || !awayClub) return;
    saving = true;
    error = '';
    try {
      if (pending) {
        await recordMatchResult(matchId, tournamentCategoryId, {
          homeScore: 0,
          awayScore: 0,
          confirm: false,
          pending: true,
          playerGoals: [],
          otherGoals: [],
        });
      } else {
        const playerGoals = [
          ...homeRows.filter((r) => (r.goals || 0) > 0).map((r) => ({ playerId: r.player.id, clubId: homeClub.id, goals: r.goals })),
          ...awayRows.filter((r) => (r.goals || 0) > 0).map((r) => ({ playerId: r.player.id, clubId: awayClub.id, goals: r.goals })),
        ];
        const otherGoals = [
          { clubId: homeClub.id, goals: homeOther || 0 },
          { clubId: awayClub.id, goals: awayOther || 0 },
        ];

        await recordMatchResult(matchId, tournamentCategoryId, {
          homeScore: totalHome,
          awayScore: totalAway,
          confirm: true,
          pending: false,
          playerGoals,
          otherGoals,
        });
      }
      notice = 'Resultado guardado.';
      onsaved();
      onclose();
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo guardar el resultado.';
    } finally {
      saving = false;
    }
  }
</script>

<Modal onclose={onclose}>
  <div class="goals-modal">
    <p class="eyebrow">Cargar resultado</p>
    <h2>{categoryName}</h2>
    {#if error}<p class="form-error">{error}</p>{/if}

    {#if loading}
      <p class="muted">Cargando jugadores...</p>
    {:else}
      <label class="pending-toggle">
        <input type="checkbox" bind:checked={pending} disabled={!canEdit || saving} />
        <span>Pendiente (sin resultado, no suma puntos)</span>
      </label>

      <div class="columns" class:dimmed={pending}>
        <div class="column">
          <h3>{homeClub?.name ?? 'Local'}</h3>
          {#if controlsPlayers && homeRows.length > 0}
            <div class="player-list">
              {#each homeRows as row}
                <div class="player-row">
                  <span class="player-name">{row.player.lastName}, {row.player.firstName}</span>
                  <input
                    type="number"
                    min="0"
                    class="goal-input"
                    bind:value={row.goals}
                    disabled={!canEdit || saving || pending}
                    aria-label={`Goles de ${row.player.lastName}, ${row.player.firstName}`}
                  />
                </div>
              {/each}
            </div>
          {:else if controlsPlayers}
            <p class="muted">Sin jugadores fichados.</p>
          {/if}

          <div class="player-row other-row">
            <span class="player-name">Otros</span>
            <input type="number" min="0" class="goal-input" bind:value={homeOther} disabled={!canEdit || saving || pending} aria-label="Otros goles local" />
          </div>
          <div class="total-row">
            <span>Total</span>
            <strong>{totalHome}</strong>
          </div>
        </div>

        <div class="column">
          <h3>{awayClub?.name ?? 'Visitante'}</h3>
          {#if controlsPlayers && awayRows.length > 0}
            <div class="player-list">
              {#each awayRows as row}
                <div class="player-row">
                  <span class="player-name">{row.player.lastName}, {row.player.firstName}</span>
                  <input
                    type="number"
                    min="0"
                    class="goal-input"
                    bind:value={row.goals}
                    disabled={!canEdit || saving || pending}
                    aria-label={`Goles de ${row.player.lastName}, ${row.player.firstName}`}
                  />
                </div>
              {/each}
            </div>
          {:else if controlsPlayers}
            <p class="muted">Sin jugadores fichados.</p>
          {/if}

          <div class="player-row other-row">
            <span class="player-name">Otros</span>
            <input type="number" min="0" class="goal-input" bind:value={awayOther} disabled={!canEdit || saving || pending} aria-label="Otros goles visitante" />
          </div>
          <div class="total-row">
            <span>Total</span>
            <strong>{totalAway}</strong>
          </div>
        </div>
      </div>

      <div class="actions">
        {#if canEdit}
          <button class="button primary" onclick={save} disabled={saving}>
            {saving ? 'Guardando...' : 'Guardar y cerrar'}
          </button>
        {/if}
        <button class="button secondary" onclick={onclose}>Cerrar</button>
      </div>
    {/if}
  </div>
</Modal>

<style>
  .goals-modal { max-width: 560px; }
  .goals-modal h2 { margin: .4rem 0 1.2rem; font-family: 'Space Grotesk', sans-serif; font-size: 1.4rem; letter-spacing: -.03em; }
  .pending-toggle {
    display: flex; align-items: center; gap: .5rem;
    margin-bottom: 1rem; padding: .6rem .8rem;
    border: 1px solid var(--color-border); border-radius: .5rem;
    background: var(--color-input); font-size: .86rem; font-weight: 600; cursor: pointer;
  }
  .columns.dimmed { opacity: .45; pointer-events: none; }
  .columns {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1.25rem;
  }
  .column h3 {
    margin: 0 0 .6rem;
    font-family: 'Space Grotesk', sans-serif;
    font-size: .95rem;
    color: var(--color-heading);
    padding-bottom: .5rem;
    border-bottom: 1px solid var(--color-border);
  }
  .player-list { display: grid; gap: .3rem; max-height: 40vh; overflow-y: auto; }
  .player-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: .75rem;
    padding: .35rem .5rem;
    border: 1px solid var(--color-border);
    border-radius: .5rem;
    background: var(--color-input);
  }
  .other-row { margin-top: .5rem; }
  .player-name {
    font-size: .84rem;
    font-weight: 500;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    min-width: 0;
  }
  .goal-input {
    width: 3.2rem;
    flex: 0 0 auto;
    padding: .3rem .35rem;
    text-align: center;
    font-size: .9rem;
    font-weight: 700;
    border: 1px solid var(--color-input-border);
    border-radius: .4rem;
    background: var(--color-input);
    color: var(--color-text);
  }
  .goal-input:focus { outline: none; border-color: var(--color-input-focus); }
  .total-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-top: .75rem;
    padding-top: .6rem;
    border-top: 1px solid var(--color-border);
    font-size: .9rem;
    font-weight: 600;
  }
  .total-row strong { font-family: 'Space Grotesk', sans-serif; font-size: 1.2rem; }
  .actions {
    display: flex;
    gap: .6rem;
    justify-content: flex-end;
    margin-top: 1.25rem;
  }
  @media (max-width: 520px) {
    .columns { grid-template-columns: 1fr; gap: 1rem; }
  }
</style>
