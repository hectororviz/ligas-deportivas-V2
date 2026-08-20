<script lang="ts">
  import Modal from '$lib/Modal.svelte';
  import { createZone, type Tournament } from '$lib/api';

  let { tournaments, presetTournamentId, onclose, oncreated }: {
    tournaments: Tournament[];
    presetTournamentId: number | null;
    onclose: () => void;
    oncreated: () => void;
  } = $props();

  let name = $state('');
  let tournamentId = $state<number | null>(null);
  let creating = $state(false);
  let error = $state('');

  $effect(() => {
    tournamentId = presetTournamentId;
  });

  let activeTournaments = $derived(tournaments.filter((t) => t.status === 'ACTIVE'));

  async function save() {
    error = '';
    if (!name.trim()) { error = 'Ingresa el nombre de la zona.'; return; }
    if (!tournamentId) { error = 'Selecciona un torneo.'; return; }
    creating = true;
    try {
      await createZone(tournamentId, name.trim());
      oncreated();
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo crear la zona.';
    } finally {
      creating = false;
    }
  }
</script>

<Modal {onclose}>
  <div class="modal-form">
    <p class="eyebrow">Nueva zona</p>
    <h2>Crear zona</h2>
    {#if error}<p class="form-error">{error}</p>{/if}
    <form onsubmit={(event) => { event.preventDefault(); save(); }}>
      <label>Nombre<input bind:value={name} placeholder="A" disabled={creating} /></label>
      <label>Torneo
        <select bind:value={tournamentId} disabled={creating}>
          <option value={null}>Seleccionar torneo...</option>
          {#each activeTournaments as t}<option value={t.id}>{t.name} {t.year} · {t.league.name}</option>{/each}
        </select>
      </label>
      <div class="form-actions">
        <button class="button primary" type="submit" disabled={creating}>{creating ? 'Creando...' : 'Crear zona'}</button>
      </div>
    </form>
  </div>
</Modal>
