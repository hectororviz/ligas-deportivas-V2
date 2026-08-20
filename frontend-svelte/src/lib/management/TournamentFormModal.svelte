<script lang="ts">
  import Modal from '$lib/Modal.svelte';
  import {
    createTournament,
    getTournamentCategories,
    updateTournament,
    type Category,
    type League,
    type Tournament
  } from '$lib/api';

  const genders = [
    ['MASCULINO', 'Masculino'], ['FEMENINO', 'Femenino'], ['MIXTO', 'Mixto']
  ];
  const championModes = [
    ['ROUND_AND_ANNUAL', 'Por ronda y anual'], ['GLOBAL', 'Global']
  ];

  interface FormCategory {
    categoryId: number;
    name: string;
    enabled: boolean;
    countsForGeneral: boolean;
    kickoffTime: string;
  }

  let { editing, presetLeagueId = null, leagues, allCategories, onclose, onsaved }: {
    editing: Tournament | null;
    presetLeagueId?: number | null;
    leagues: League[];
    allCategories: Category[];
    onclose: () => void;
    onsaved: () => void;
  } = $props();

  let saving = $state(false);
  let error = $state('');
  let showCatPicker = $state(false);
  let form = $state({
    leagueId: '', name: '', year: new Date().getFullYear(), gender: 'MASCULINO',
    championMode: 'ROUND_AND_ANNUAL', pointsWin: 3, pointsDraw: 1, pointsLoss: 0,
    startDate: '', endDate: '', controlsPlayers: true
  });
  let formCategories = $state<FormCategory[]>([]);
  let catPickerData = $state<FormCategory[]>([]);

  let catCount = $derived(formCategories.filter((c) => c.enabled).length);

  function genderCategories(gender: string) {
    return allCategories.filter((c) => c.active && c.gender === gender).map((c) => ({
      categoryId: c.id, name: c.name, enabled: false, countsForGeneral: true, kickoffTime: ''
    }));
  }

  $effect(() => {
    if (editing) {
      form = {
        leagueId: String(editing.leagueId),
        name: editing.name,
        year: editing.year,
        gender: editing.gender,
        championMode: editing.championMode,
        pointsWin: editing.pointsWin,
        pointsDraw: editing.pointsDraw,
        pointsLoss: editing.pointsLoss,
        startDate: editing.startDate ? editing.startDate.split('T')[0] : '',
        endDate: editing.endDate ? editing.endDate.split('T')[0] : '',
        controlsPlayers: editing.controlsPlayers ?? true
      };
    } else {
      form = {
        leagueId: presetLeagueId ? String(presetLeagueId) : '', name: '', year: new Date().getFullYear(), gender: 'MASCULINO',
        championMode: 'ROUND_AND_ANNUAL', pointsWin: 3, pointsDraw: 1, pointsLoss: 0,
        startDate: '', endDate: '', controlsPlayers: true
      };
    }
    formCategories = genderCategories(form.gender);
    error = '';
    showCatPicker = false;

    if (editing) loadExistingCategories(editing.id);
  });

  async function loadExistingCategories(tournamentId: number) {
    try {
      const existing = await getTournamentCategories(tournamentId);
      formCategories = formCategories.map((c) => {
        const ex = existing.find((e) => e.categoryId === c.categoryId);
        return ex
          ? { ...c, enabled: true, countsForGeneral: ex.countsForGeneral ?? true, kickoffTime: ex.kickoffTime || '' }
          : c;
      });
    } catch {}
  }

  function openCatPicker() {
    const genderCats = genderCategories(form.gender);
    const existingById = new Map(formCategories.map((c) => [c.categoryId, c]));
    catPickerData = genderCats.map((c) => existingById.get(c.categoryId) ?? c);
    showCatPicker = true;
  }

  function closeCatPicker() {
    showCatPicker = false;
  }

  function applyCatPicker() {
    formCategories = catPickerData.map((c) => ({ ...c }));
    showCatPicker = false;
  }

  function toggleCatEnabled(idx: number) {
    catPickerData[idx].enabled = !catPickerData[idx].enabled;
  }

  async function save() {
    error = '';
    if (!form.name.trim()) { error = 'Ingresa el nombre del torneo.'; return; }
    if (!form.leagueId) { error = 'Selecciona una liga.'; return; }
    const enabledCats = formCategories.filter((c) => c.enabled);
    if (enabledCats.length === 0) { error = 'Selecciona al menos una categoría.'; return; }

    saving = true;
    const payload: Record<string, unknown> = {
      name: form.name.trim(),
      year: Number(form.year),
      gender: form.gender,
      championMode: form.championMode,
      pointsWin: Number(form.pointsWin),
      pointsDraw: Number(form.pointsDraw),
      pointsLoss: Number(form.pointsLoss),
      leagueId: Number(form.leagueId),
      startDate: form.startDate || undefined,
      endDate: form.endDate || undefined,
      controlsPlayers: form.controlsPlayers,
      categories: formCategories.map((c) => ({
        categoryId: c.categoryId,
        enabled: c.enabled,
        countsForGeneral: c.countsForGeneral,
        kickoffTime: c.enabled ? (c.kickoffTime || undefined) : undefined
      }))
    };
    try {
      if (editing) await updateTournament(editing.id, payload);
      else await createTournament(payload);
      onsaved();
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo guardar el torneo.';
    } finally {
      saving = false;
    }
  }
</script>

<Modal {onclose}>
  <div class="modal-form">
    <p class="eyebrow">{editing ? 'Editar torneo' : 'Nuevo torneo'}</p>
    <h2>{editing ? editing.name : 'Crear torneo'}</h2>
    {#if error}<p class="form-error">{error}</p>{/if}
    <form onsubmit={(event) => { event.preventDefault(); save(); }}>
      <div class="form-row-grid two">
        <label>Liga
          <select bind:value={form.leagueId} disabled={saving}>
            <option value="">Seleccionar liga...</option>
            {#each leagues as league}<option value={league.id}>{league.name}</option>{/each}
          </select>
        </label>
        <label>Nombre<input bind:value={form.name} placeholder="Torneo Apertura 2026" disabled={saving} /></label>
      </div>

      <div class="form-row-grid three">
        <label>Género
          <select bind:value={form.gender} disabled={saving}>
            {#each genders as [value, label]}<option value={value}>{label}</option>{/each}
          </select>
        </label>
        <label>Año<input type="number" bind:value={form.year} disabled={saving} /></label>
        <label>Modo de campeón
          <select bind:value={form.championMode} disabled={saving}>
            {#each championModes as [value, label]}<option value={value}>{label}</option>{/each}
          </select>
        </label>
      </div>

      <div class="form-row-grid two">
        <label>Fecha de inicio<input type="date" bind:value={form.startDate} disabled={saving} /></label>
        <label>Fecha de fin<input type="date" bind:value={form.endDate} disabled={saving} /></label>
      </div>

      <div class="form-row-grid three">
        <label>Pts Victoria<input type="number" bind:value={form.pointsWin} disabled={saving} /></label>
        <label>Pts Empate<input type="number" bind:value={form.pointsDraw} disabled={saving} /></label>
        <label>Pts Derrota<input type="number" bind:value={form.pointsLoss} disabled={saving} /></label>
      </div>

      <div class="form-row-grid two">
        <label class="checkbox-label"><input type="checkbox" bind:checked={form.controlsPlayers} disabled={saving} /> Controlar jugadores</label>

        <div class="categories-section">
          <div style="display:flex;align-items:center;justify-content:space-between;gap:.5rem;">
            <span class="cat-label">Categorías ({catCount} seleccionadas)</span>
            <button type="button" class="button secondary small" disabled={!form.gender || saving} onclick={openCatPicker}>Seleccionar</button>
          </div>
          {#if catCount > 0}
            <div class="cat-tags">
              {#each formCategories.filter((c) => c.enabled) as c}
                <span class="cat-tag">{c.name}</span>
              {/each}
            </div>
          {/if}
        </div>
      </div>

      <div class="form-actions">
        <button class="button primary" type="submit" disabled={saving}>{saving ? 'Guardando...' : editing ? 'Guardar cambios' : 'Crear torneo'}</button>
        <button class="button secondary" type="button" onclick={onclose} disabled={saving}>Cancelar</button>
      </div>
    </form>
  </div>
</Modal>

{#if showCatPicker}
  <Modal onclose={closeCatPicker}>
    <div class="modal-form cat-picker-modal">
      <p class="eyebrow">Categorías</p>
      <h2>Seleccionar categorías</h2>
      <p class="muted">Categorías que coinciden con el género <strong>{genders.find(([v]) => v === form.gender)?.[1] ?? form.gender}</strong>.{form.gender === 'MIXTO' ? ' Se muestran todas las categorías.' : ''}</p>

      <div class="cat-table-wrapper">
        <table class="cat-table">
          <thead>
            <tr>
              <th style="width:50px">Act.</th>
              <th>Nombre</th>
              <th style="width:90px">Promocional</th>
              <th style="width:100px">Horario</th>
            </tr>
          </thead>
          <tbody>
            {#each catPickerData as cat, i}
              <tr class:cat-enabled={cat.enabled}>
                <td class="td-center"><input type="checkbox" checked={cat.enabled} onchange={() => toggleCatEnabled(i)} /></td>
                <td>{cat.name}</td>
                <td class="td-center"><input type="checkbox" checked={!cat.countsForGeneral} disabled={!cat.enabled} title="Promocional: no suma puntos para la tabla general" onchange={() => catPickerData[i].countsForGeneral = !catPickerData[i].countsForGeneral} /></td>
                <td><input type="time" bind:value={catPickerData[i].kickoffTime} disabled={!cat.enabled} style="width:100%;font-size:.82rem;padding:.25rem .35rem;" /></td>
              </tr>
            {/each}
          </tbody>
        </table>
      </div>
      {#if catPickerData.length === 0}
        <p class="muted" style="text-align:center;padding:2rem;">No hay categorías activas para este género. Crea categorías antes de continuar.</p>
      {/if}

      <div class="form-actions" style="margin-top:1rem;">
        <button class="button secondary" type="button" onclick={closeCatPicker}>Cancelar</button>
        <button class="button primary" type="button" onclick={applyCatPicker}>Aceptar</button>
      </div>
    </div>
  </Modal>
{/if}

<style>
  .form-row-grid { display: grid; gap: .75rem 1.5rem; }
  .form-row-grid.two { grid-template-columns: 1fr 1fr; }
  .form-row-grid.three { grid-template-columns: 1fr 1fr 1fr; }
  .categories-section { margin-top: .5rem; padding-top: .75rem; border-top: 1px solid var(--color-border); }
  .cat-label { font-size: .78rem; font-weight: 600; color: var(--color-text-muted); text-transform: uppercase; margin: 0; }
  .cat-tags { display: flex; flex-wrap: wrap; gap: .3rem; margin-top: .4rem; }
  .cat-tag { padding: .2rem .55rem; border-radius: 999px; font-size: .72rem; font-weight: 600; background: var(--color-accent-bg); color: var(--color-accent-text); }
  .cat-picker-modal { max-width: 620px !important; }
  .cat-table-wrapper { max-height: 50vh; overflow-y: auto; border: 1px solid var(--color-border); border-radius: .6rem; margin: .5rem 0; }
  .cat-table { width: 100%; border-collapse: collapse; font-size: .84rem; }
  .cat-table th { background: var(--color-surface-hover); color: var(--color-text-muted); font-size: .7rem; font-weight: 700; text-transform: uppercase; letter-spacing: .04em; padding: .5rem .6rem; text-align: left; position: sticky; top: 0; z-index: 1; border-bottom: 1px solid var(--color-border); }
  .cat-table td { padding: .45rem .6rem; border-bottom: 1px solid var(--color-border); }
  .cat-table tbody tr:hover { background: var(--color-surface-hover); }
  .cat-table tbody tr.cat-enabled { background: var(--color-accent-bg); }
  .td-center { text-align: center; }
  .button.small { padding: .35rem .65rem; font-size: .78rem; }
  @media (max-width: 767px) {
    .form-row-grid.two, .form-row-grid.three { grid-template-columns: 1fr; }
  }
</style>
