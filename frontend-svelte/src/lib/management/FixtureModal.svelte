<script lang="ts">
  import Modal from '$lib/Modal.svelte';
  import {
    finalizeZone,
    generateFixture,
    generateManualFixture,
    previewFixture,
    type Zone
  } from '$lib/api';

  let { zone, onclose, onchanged }: {
    zone: Zone;
    onclose: () => void;
    onchanged: () => void;
  } = $props();

  let fixtureMode = $state<'auto' | 'manual'>('auto');
  let doubleRound = $state(true);
  let autoPreview = $state<any>(null);
  let previewing = $state(false);
  let saving = $state(false);
  let error = $state('');

  let manualDates = $state<ManualDate[]>([]);
  let selectedDateIdx = $state(0);
  let autoSecondRound = $state(true);
  let draggedClub = $state<number | null>(null);

  interface ManualDate {
    matches: { homeClubId: number | null; awayClubId: number | null }[];
    byeClubId: number | null;
    warnings: string[];
  }

  interface FixtureMeta { clubCount: number; hasBye: boolean; totalDates: number; matchesPerDate: number; clubs: { id: number; name: string }[] }

  function assignedClubs(): { clubId: number; clubName: string }[] {
    return (zone.clubZones ?? []).map((cz) => ({ clubId: cz.club.id, clubName: cz.club.name }));
  }

  function switchToManual() {
    fixtureMode = 'manual';
    autoPreview = null;
    initManualBuilder(assignedClubs());
  }

  async function doPreview() {
    error = '';
    autoPreview = null;
    previewing = true;
    try {
      autoPreview = await previewFixture(zone.id, doubleRound);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo generar la vista previa.';
    } finally {
      previewing = false;
    }
  }

  async function confirmGenerateFixture() {
    if (!confirm(`¿Confirmar y fijar el fixture de la Zona ${zone.name}? Esta acción finalizará la zona y no se podrá modificar.`)) return;
    error = '';
    saving = true;
    try {
      if (zone.status === 'OPEN') {
        await finalizeZone(zone.id);
      }
      await generateFixture(zone.id, doubleRound);
      onchanged();
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo generar el fixture.';
    } finally {
      saving = false;
    }
  }

  function initManualBuilder(clubs: { clubId: number; clubName: string }[]) {
    if (clubs.length < 2) return;
    const clubList = clubs.map((c) => ({ id: c.clubId, name: c.clubName }));
    const meta = computeMeta(clubList);
    const round1Dates: ManualDate[] = [];
    for (let d = 0; d < meta.totalDates; d++) {
      const matches = Array.from({ length: meta.matchesPerDate }, () => ({ homeClubId: null as number | null, awayClubId: null as number | null }));
      round1Dates.push({ matches, byeClubId: null, warnings: [] });
    }
    manualDates = round1Dates;
    selectedDateIdx = 0;
    autoSecondRound = true;
  }

  function computeMeta(clubs: { id: number; name: string }[]): FixtureMeta {
    const clubCount = clubs.length;
    const hasBye = clubCount % 2 !== 0;
    const totalDates = hasBye ? clubCount : clubCount - 1;
    const matchesPerDate = Math.floor(clubCount / 2);
    return { clubCount, hasBye, totalDates, matchesPerDate, clubs };
  }

  function getMeta(): FixtureMeta | null {
    const clubs = assignedClubs().map((c) => ({ id: c.clubId, name: c.clubName }));
    if (clubs.length < 2) return null;
    return computeMeta(clubs);
  }

  function usedClubIds(dateIdx: number): Set<number> {
    if (!manualDates[dateIdx]) return new Set();
    const ids = new Set<number>();
    const d = manualDates[dateIdx];
    for (const m of d.matches) {
      if (m.homeClubId) ids.add(m.homeClubId);
      if (m.awayClubId) ids.add(m.awayClubId);
    }
    if (d.byeClubId) ids.add(d.byeClubId);
    return ids;
  }

  function canDropClub(clubId: number, dateIdx: number, slot: 'home' | 'away' | 'bye', matchIdx?: number): boolean {
    const d = manualDates[dateIdx];
    if (!d) return false;
    const used = usedClubIds(dateIdx);
    if (used.has(clubId)) return false;
    if (slot === 'bye') return !d.byeClubId;

    const meta = getMeta();
    if (!meta || matchIdx === undefined) return false;
    const matchSlot = d.matches[matchIdx];
    if (!matchSlot) return false;

    if (slot === 'home' && matchSlot.homeClubId) return false;
    if (slot === 'away' && matchSlot.awayClubId) return false;
    if (slot === 'home' && matchSlot.awayClubId === clubId) return false;
    if (slot === 'away' && matchSlot.homeClubId === clubId) return false;

    return true;
  }

  function dropClub(clubId: number, dateIdx: number, slot: 'home' | 'away' | 'bye', matchIdx?: number) {
    if (!canDropClub(clubId, dateIdx, slot, matchIdx)) return;
    const d = manualDates[dateIdx];
    if (slot === 'bye') {
      d.byeClubId = clubId;
    } else if (matchIdx !== undefined) {
      if (slot === 'home') d.matches[matchIdx].homeClubId = clubId;
      else d.matches[matchIdx].awayClubId = clubId;
    }
    validateAll();
  }

  function clearSlot(dateIdx: number, slot: 'home' | 'away' | 'bye', matchIdx?: number) {
    const d = manualDates[dateIdx];
    if (slot === 'bye') { d.byeClubId = null; }
    else if (matchIdx !== undefined) {
      if (slot === 'home') d.matches[matchIdx].homeClubId = null;
      else d.matches[matchIdx].awayClubId = null;
    }
    validateAll();
  }

  function validateAll() {
    for (let d = 0; d < manualDates.length; d++) {
      manualDates[d].warnings = validateDate(d);
    }
    manualDates = [...manualDates];
  }

  function validateDate(dateIdx: number): string[] {
    const warns: string[] = [];
    const d = manualDates[dateIdx];
    if (!d) return warns;

    for (const m of d.matches) {
      if (!m.homeClubId && !m.awayClubId) continue;
      if (!m.homeClubId || !m.awayClubId) { warns.push('Cruce incompleto.'); continue; }
      if (m.homeClubId === m.awayClubId) warns.push(`${clubName(m.homeClubId)} no puede enfrentarse a sí mismo.`);
    }

    const meta = getMeta();
    if (!meta) return warns;

    if (meta.hasBye && !d.byeClubId) warns.push('Falta asignar el libre.');
    const used = usedClubIds(dateIdx);
    if (used.size !== meta.clubCount) warns.push('Faltan clubes por asignar en esta fecha.');

    const pairKeys = new Set<string>();
    for (const m of d.matches) {
      if (!m.homeClubId || !m.awayClubId) continue;
      const key = `${Math.min(m.homeClubId, m.awayClubId)}-${Math.max(m.homeClubId, m.awayClubId)}`;
      if (pairKeys.has(key)) warns.push('Hay cruces duplicados en esta fecha.');
      pairKeys.add(key);
    }

    if (dateIdx > 0) {
      for (const m of d.matches) {
        if (!m.homeClubId || !m.awayClubId) continue;
        const prev = manualDates[dateIdx - 1];
        for (const pm of prev.matches) {
          if (!pm.homeClubId || !pm.awayClubId) continue;
          if (m.homeClubId === pm.homeClubId) warns.push(`${clubName(m.homeClubId)} repite local en fechas consecutivas.`);
          if (m.awayClubId === pm.awayClubId) warns.push(`${clubName(m.awayClubId)} repite visitante en fechas consecutivas.`);
        }
      }
    }

    return warns;
  }

  function buildRound2(): ManualDate[] {
    return manualDates.map((d) => ({
      byeClubId: d.byeClubId,
      warnings: [],
      matches: d.matches.map((m) => ({ homeClubId: m.awayClubId, awayClubId: m.homeClubId }))
    }));
  }

  async function saveManualFixture() {
    validateAll();

    if (!confirm(`¿Confirmar y fijar el fixture de la Zona ${zone.name}? Esta acción finalizará la zona y no se podrá modificar.`)) return;

    error = '';
    saving = true;
    const round1 = manualDates.map((d, i) => ({
      matchday: i + 1,
      round: 'FIRST',
      matches: d.matches.filter((m) => m.homeClubId && m.awayClubId).map((m) => ({ homeClubId: m.homeClubId!, awayClubId: m.awayClubId! })),
      ...(d.byeClubId ? { byeClubId: d.byeClubId } : {})
    }));
    if (round1.every((d) => d.matches.length === 0)) {
      error = 'Completá al menos un cruce antes de guardar.';
      saving = false;
      return;
    }

    const r2 = buildRound2().map((d, i) => ({
      matchday: manualDates.length + i + 1,
      round: 'SECOND',
      matches: d.matches.filter((m) => m.homeClubId && m.awayClubId).map((m) => ({ homeClubId: m.homeClubId!, awayClubId: m.awayClubId! })),
      ...(d.byeClubId ? { byeClubId: d.byeClubId } : {})
    }));

    try {
      if (zone.status === 'OPEN') {
        await finalizeZone(zone.id);
      }
      await generateManualFixture(zone.id, {
        matchdays: [...round1, ...r2],
        doubleRound: true
      });
      onchanged();
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo guardar el fixture.';
    } finally {
      saving = false;
    }
  }

  let previewMeta = $derived(getMeta());

  function clubName(id: number | null): string {
    if (!id || !previewMeta) return '';
    return previewMeta.clubs.find((c) => c.id === id)?.name ?? '';
  }
</script>

{#if fixtureMode === 'auto'}
  <Modal {onclose}>
    <div class="modal-form">
      <p class="eyebrow">Generar fixture</p>
      <h2>Zona {zone.name}</h2>
      <p class="muted">{zone.tournament.name} {zone.tournament.year} · {zone.tournament.league.name}</p>
      {#if error}<p class="form-error">{error}</p>{/if}
      <div class="fixture-mode-tabs">
        <button class="mode-tab active">Automático</button>
        <button class="mode-tab" onclick={switchToManual}>Manual</button>
      </div>

      {#if autoPreview}
        <div class="auto-preview">
          <h4>Vista previa</h4>
          {#each autoPreview.matchdays as md}
            <div class="preview-matchday">
              <div class="preview-md-header">
                <strong>Fecha {md.matchday}</strong>
                <span class="badge-muted">{md.round === 'FIRST' ? 'Ronda 1' : 'Ronda 2'}</span>
                {#if md.byeClubId && previewMeta}
                  <span class="badge-muted">Libre: {clubName(md.byeClubId)}</span>
                {/if}
              </div>
              {#each md.matches as match}
                <div class="preview-match">
                  <span>{match.homeClubId && previewMeta ? previewMeta.clubs.find((c) => c.id === match.homeClubId)?.name || '?' : '?'}</span>
                  <span class="vs">vs</span>
                  <span>{match.awayClubId && previewMeta ? previewMeta.clubs.find((c) => c.id === match.awayClubId)?.name || '?' : '?'}</span>
                </div>
              {/each}
            </div>
          {/each}
        </div>
        <div class="form-actions" style="margin-top:1rem;">
          <button class="button secondary" type="button" onclick={() => autoPreview = null}>Volver</button>
          <button class="button primary" type="button" disabled={saving} onclick={confirmGenerateFixture}>{saving ? 'Generando...' : 'Confirmar y generar'}</button>
        </div>
      {:else}
        <label class="checkbox-label"><input type="checkbox" bind:checked={doubleRound} disabled={previewing} /> Ida y vuelta</label>
        <div class="form-actions">
          <button class="button secondary" type="button" disabled={previewing} onclick={onclose}>Cancelar</button>
          <button class="button primary" type="button" disabled={previewing} onclick={doPreview}>{previewing ? 'Generando vista previa...' : 'Generar vista previa'}</button>
        </div>
      {/if}
    </div>
  </Modal>
{:else if previewMeta}
  <Modal onclose={onclose} wide={true}>
    <div class="modal-form manual-fixture-modal">
      <p class="eyebrow">Generar fixture</p>
      <h2>Zona {zone.name} · Manual</h2>
      <p class="muted">{zone.tournament.name} {zone.tournament.year} · {previewMeta.clubCount} clubes · {previewMeta.totalDates} fechas · {previewMeta.hasBye ? 'Con libre' : 'Sin libre'}</p>
      {#if error}<p class="form-error">{error}</p>{/if}
      <div class="fixture-mode-tabs">
        <button class="mode-tab" onclick={() => fixtureMode = 'auto'}>Automático</button>
        <button class="mode-tab active">Manual</button>
      </div>

      <div class="manual-builder">
        <div class="club-pool">
          <h4>Clubes</h4>
          {#each previewMeta.clubs as club}
            {@const used = manualDates[selectedDateIdx] ? usedClubIds(selectedDateIdx).has(club.id) : false}
            <div
              class="club-drag {used ? 'used' : ''}"
              draggable={!used}
              ondragstart={(e) => { if (!used) { e.dataTransfer!.effectAllowed = 'move'; draggedClub = club.id; }}}
              ondragend={() => draggedClub = null}
              role="listitem"
            >
              <span>{club.name}</span>
              {#if used}<span class="used-badge">asignado</span>{/if}
            </div>
          {/each}
        </div>

        <div class="matchdays-area">
          <div class="date-tabs">
            {#each manualDates as date, i}
              <button class="date-tab" class:active={selectedDateIdx === i} class:has-warnings={date.warnings.length > 0} onclick={() => selectedDateIdx = i}>Fecha {i + 1}</button>
            {/each}
          </div>

          {#if manualDates[selectedDateIdx]}
            <div class="matches-grid">
              {#each manualDates[selectedDateIdx].matches as match, mi}
                <div class="match-row">
                  <div
                    class="drop-slot home-slot {match.homeClubId ? 'filled' : ''} {draggedClub && canDropClub(draggedClub, selectedDateIdx, 'home', mi) ? 'valid-target' : ''}"
                    ondragover={(e) => { e.preventDefault(); }}
                    ondrop={() => { if (draggedClub) dropClub(draggedClub, selectedDateIdx, 'home', mi); }}
                    role="region"
                  >
                    {#if match.homeClubId}
                      <span class="slot-club">{clubName(match.homeClubId)}</span>
                      <button class="icon-button slot-remove" onclick={() => clearSlot(selectedDateIdx, 'home', mi)} aria-label="Remover">×</button>
                    {:else}
                      <span class="slot-hint">Local</span>
                    {/if}
                  </div>
                  <span class="vs">vs</span>
                  <div
                    class="drop-slot away-slot {match.awayClubId ? 'filled' : ''} {draggedClub && canDropClub(draggedClub, selectedDateIdx, 'away', mi) ? 'valid-target' : ''}"
                    ondragover={(e) => { e.preventDefault(); }}
                    ondrop={() => { if (draggedClub) dropClub(draggedClub, selectedDateIdx, 'away', mi); }}
                    role="region"
                  >
                    {#if match.awayClubId}
                      <span class="slot-club">{clubName(match.awayClubId)}</span>
                      <button class="icon-button slot-remove" onclick={() => clearSlot(selectedDateIdx, 'away', mi)} aria-label="Remover">×</button>
                    {:else}
                      <span class="slot-hint">Visitante</span>
                    {/if}
                  </div>
                </div>
              {/each}

              {#if previewMeta.hasBye}
                <div class="bye-row">
                  <span class="bye-label">Libre:</span>
                  <div
                    class="drop-slot bye-slot {manualDates[selectedDateIdx].byeClubId ? 'filled' : ''} {draggedClub && canDropClub(draggedClub, selectedDateIdx, 'bye') ? 'valid-target' : ''}"
                    ondragover={(e) => { e.preventDefault(); }}
                    ondrop={() => { if (draggedClub) dropClub(draggedClub, selectedDateIdx, 'bye'); }}
                    role="region"
                  >
                    {#if manualDates[selectedDateIdx].byeClubId}
                      <span class="slot-club">{clubName(manualDates[selectedDateIdx].byeClubId)}</span>
                      <button class="icon-button slot-remove" onclick={() => clearSlot(selectedDateIdx, 'bye')} aria-label="Remover">×</button>
                    {:else}
                      <span class="slot-hint">Arrastra un club</span>
                    {/if}
                  </div>
                </div>
              {/if}

              {#if manualDates[selectedDateIdx].warnings.length > 0}
                <div class="date-warnings">
                  {#each manualDates[selectedDateIdx].warnings as e}
                    <p class="form-warning">{e}</p>
                  {/each}
                </div>
              {/if}
            </div>

            <div class="manual-actions">
              <button class="button secondary" type="button" disabled={saving} onclick={onclose}>Cancelar</button>
              <button class="button primary" type="button" disabled={saving} onclick={saveManualFixture}>{saving ? 'Guardando...' : 'Guardar fixture'}</button>
            </div>
          {/if}
        </div>
      </div>
    </div>
  </Modal>
{/if}

<style>
  .fixture-mode-tabs { display: flex; gap: .5rem; margin: .75rem 0 1rem; }
  .mode-tab { padding: .45rem 1rem; border: 1px solid var(--color-border); border-radius: .5rem; background: var(--color-input); color: var(--color-text-muted); cursor: pointer; font-size: .82rem; font-weight: 500; font-family: inherit; }
  .mode-tab.active { background: var(--color-accent-bg); color: var(--color-accent-text); border-color: var(--color-accent); font-weight: 600; }
  .mode-tab:hover:not(.active) { background: var(--color-surface-hover); }

  .manual-fixture-modal { max-width: 1100px !important; }
  .manual-builder { display: grid; grid-template-columns: 200px 1fr; gap: 1.5rem; margin-top: .5rem; }
  .club-pool { display: grid; gap: .3rem; align-content: start; }
  .club-pool h4 { margin: 0 0 .25rem; font-family: 'Space Grotesk', sans-serif; font-size: .82rem; color: var(--color-text-muted); }
  .club-drag { padding: .4rem .6rem; border: 1px solid var(--color-border); border-radius: .4rem; background: var(--color-accent-bg); color: var(--color-accent-text); cursor: grab; font-size: .8rem; font-weight: 600; display: flex; align-items: center; justify-content: space-between; }
  .club-drag:active { cursor: grabbing; opacity: .7; }
  .club-drag.used { opacity: .35; cursor: default; background: var(--color-surface-hover); color: var(--color-text-muted); }
  .used-badge { font-size: .62rem; color: var(--color-text-muted); }

  .matchdays-area { min-width: 0; }
  .date-tabs { display: flex; gap: .25rem; flex-wrap: wrap; margin-bottom: 1rem; }
  .date-tab { padding: .3rem .7rem; border: 1px solid var(--color-border); border-radius: .4rem; background: var(--color-input); color: var(--color-text-muted); cursor: pointer; font-size: .78rem; font-weight: 500; font-family: inherit; }
  .date-tab.active { background: var(--color-accent-bg); color: var(--color-accent-text); border-color: var(--color-accent); }
  .date-tab.has-warnings { border-color: #d4a000; background: #fffae6; }
  .date-tab.has-warnings::after { content: ' !'; color: #d4a000; font-weight: 700; }

  .date-warnings { margin-top: .5rem; display: grid; gap: .2rem; }
  .form-warning { font-size: .78rem; color: #8a6d00; background: #fffae6; border: 1px solid #d4a000; padding: .3rem .6rem; border-radius: .4rem; margin: 0; }

  .matches-grid { display: grid; gap: .5rem; }
  .match-row { display: flex; align-items: center; gap: .5rem; }
  .drop-slot { flex: 1; min-height: 2.4rem; padding: .35rem .5rem; border: 2px dashed var(--color-border); border-radius: .5rem; display: flex; align-items: center; justify-content: space-between; transition: border-color 150ms ease, background 150ms ease; }
  .drop-slot.filled { border-style: solid; background: var(--color-accent-bg); border-color: var(--color-accent); }
  .drop-slot.valid-target { border-color: var(--color-success); background: var(--color-success-bg); }
  .slot-hint { color: var(--color-text-light); font-size: .82rem; font-style: italic; }
  .slot-club { font-size: .85rem; font-weight: 600; }
  .slot-remove { color: var(--color-error); padding: 0 .2rem; font-size: 1rem; }
  .vs { font-size: .75rem; color: var(--color-text-muted); font-weight: 700; flex-shrink: 0; width: 2rem; text-align: center; }

  .bye-row { display: flex; align-items: center; gap: .5rem; margin-top: .25rem; }
  .bye-label { font-size: .8rem; color: var(--color-text-muted); font-weight: 600; width: 4rem; flex-shrink: 0; }
  .manual-actions { display: flex; gap: .5rem; justify-content: flex-end; margin-top: 1.25rem; }

  .auto-preview { margin: .75rem 0; }
  .auto-preview h4 { margin: 0 0 .5rem; font-family: 'Space Grotesk', sans-serif; font-size: .95rem; }
  .preview-matchday { margin-bottom: .75rem; border: 1px solid var(--color-border); border-radius: .6rem; padding: .6rem .8rem; }
  .preview-md-header { display: flex; align-items: center; gap: .5rem; margin-bottom: .4rem; flex-wrap: wrap; }
  .preview-md-header strong { font-size: .85rem; }
  .preview-match { display: flex; align-items: center; gap: .5rem; padding: .25rem 0; font-size: .82rem; font-weight: 500; }
  .preview-match .vs { width: auto; padding: 0 .3rem; }

  @media (max-width: 767px) {
    .manual-builder { grid-template-columns: 1fr; }
    .club-pool { display: flex; flex-wrap: wrap; gap: .3rem; }
  }
</style>
