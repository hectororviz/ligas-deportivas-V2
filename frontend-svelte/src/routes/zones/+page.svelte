<script lang="ts">
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';
  import { assignClubToZone, generateFixture, generateTournamentFixture, getProfile, getTournamentZoneClubs, getTournaments, getZones, removeClubFromZone, type AuthUser, type Tournament, type TournamentZoneClub, type Zone } from '$lib/api';
  import Modal from '$lib/Modal.svelte';

  let user: AuthUser | null = $state(null);
  let zones: Zone[] = $state([]);
  let tournaments: Tournament[] = $state([]);
  let loading = $state(true);
  let error = $state('');
  let notice = $state('');
  let generatingZoneId: number | null = $state(null);
  let generating = $state(false);

  let showFixtureModal = $state(false);
  let fixtureZone: Zone | null = $state(null);
  let idaVuelta = $state(true);

  let selectedTournament: number | null = $state(null);
  let generatingTournament = $state(false);

  let expandedZone = $state<number | null>(null);
  let zoneClubs = $state<TournamentZoneClub[]>([]);
  let availableClubs = $state<TournamentZoneClub[]>([]);
  let loadingClubs = $state(false);

  onMount(async () => {
    try {
      const [u, z, t] = await Promise.all([getProfile(), getZones(true), getTournaments(true)]);
      user = u; zones = z; tournaments = t;
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar las zonas.';
    } finally {
      loading = false;
    }
  });

  let canManage = $derived(((user as AuthUser | null)?.roles ?? []).includes('ADMIN'));

  async function toggleZone(zone: Zone) {
    if (expandedZone === zone.id) { expandedZone = null; return; }
    expandedZone = zone.id;
    loadingClubs = true;
    try {
      const [current, available] = await Promise.all([
        getTournamentZoneClubs(zone.tournamentId),
        getTournamentZoneClubs(zone.tournamentId)
      ]);
      zoneClubs = current.filter(c => zones.some(z => z.id === zone.id && z.clubZones?.some(cz => cz.club.id === c.clubId)));
      availableClubs = available.filter(c => !zoneClubs.some(zc => zc.clubId === c.clubId));
    } catch {
      zoneClubs = [];
      availableClubs = [];
    } finally {
      loadingClubs = false;
    }
  }

  async function addClub(zoneId: number, clubId: number) {
    try {
      await assignClubToZone(zoneId, clubId);
      notice = 'Club agregado a la zona.';
      zones = await getZones(true);
      if (expandedZone === zoneId) toggleZone(zones.find(z => z.id === zoneId)!);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'Error al agregar club.';
    }
    setTimeout(() => notice = '', 2500);
  }

  async function removeClub(zoneId: number, clubId: number) {
    try {
      await removeClubFromZone(zoneId, clubId);
      notice = 'Club removido de la zona.';
      zones = await getZones(true);
      if (expandedZone === zoneId) toggleZone(zones.find(z => z.id === zoneId)!);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'Error al remover club.';
    }
    setTimeout(() => notice = '', 2500);
  }

  function statusLabel(status: string) {
    const map: Record<string, string> = { ACTIVE: 'Activa', INACTIVE: 'Inactiva', DRAFT: 'Borrador', CLOSED: 'Cerrada' };
    return map[status] ?? status;
  }

  function statusClass(status: string) {
    const map: Record<string, string> = { ACTIVE: 'badge-active', INACTIVE: 'badge-inactive', DRAFT: 'badge-draft', CLOSED: 'badge-closed' };
    return map[status] ?? 'badge-default';
  }

  function openFixtureModal(zone: Zone) { fixtureZone = zone; idaVuelta = true; showFixtureModal = true; error = ''; }
  function closeFixtureModal() { showFixtureModal = false; fixtureZone = null; }

  async function confirmGenerateFixture() {
    if (!fixtureZone) return;
    error = ''; notice = '';
    generating = true;
    try {
      await generateFixture(fixtureZone.id, idaVuelta);
      notice = `Fixture generado para Zona ${fixtureZone.name}.`;
      closeFixtureModal();
      zones = await getZones(true);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo generar el fixture.';
    } finally { generating = false; }
  }

  async function handleGenerateTournament() {
    if (!selectedTournament) return;
    error = ''; notice = '';
    generatingTournament = true;
    try {
      await generateTournamentFixture(selectedTournament, true);
      notice = 'Fixture generado para el torneo.';
      zones = await getZones(true);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo generar el fixture del torneo.';
    } finally { generatingTournament = false; }
  }
</script>

<svelte:head><title>Zonas | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div><p class="eyebrow">Competencia</p><h1>Zonas</h1><p class="muted">Administra las zonas de cada torneo, sus posiciones y la generacion de partidos.</p></div>
    <div class="header-actions">
      <a class="button secondary" href="/fixtures">Ver partidos</a>
    </div>
  </header>

  {#if loading}
    <section class="loading-card">Cargando zonas...</section>
  {:else}
    {#if error}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}

    {#if canManage}
      <section class="card-surface tournament-fixture-card">
        <div class="list-header">
          <div><p class="eyebrow">Generacion masiva</p><h2>Fixture del torneo</h2></div>
        </div>
        <p class="muted">Genera los partidos para todas las zonas de un torneo de una vez.</p>
        <div class="tournament-fixture-controls">
          <label>
            Torneo
            <select bind:value={selectedTournament}>
              <option value={null}>Seleccionar torneo...</option>
              {#each tournaments as t}<option value={t.id}>{t.name} {t.year} · {t.league.name}</option>{/each}
            </select>
          </label>
          <button class="button primary" disabled={!selectedTournament || generatingTournament} onclick={handleGenerateTournament}>
            {generatingTournament ? 'Generando...' : 'Generar fixture del torneo'}
          </button>
        </div>
      </section>
    {/if}

    <section class="zone-list card-surface">
      <div class="list-header">
        <div><p class="eyebrow">Catalogo</p><h2>Zonas registradas</h2></div>
        <span class="count-pill">{zones.length}</span>
      </div>
      {#if zones.length === 0}
        <div class="empty-state compact-empty"><h2>Sin zonas todavia</h2><p>Crea torneos y zonas para comenzar.</p></div>
      {:else}
        <div class="zone-table">
          {#each zones as zone}
            <div>
              <article class="zone-row" class:expanded={expandedZone === zone.id}>
                <!-- svelte-ignore a11y_click_events_have_key_events -->
                <!-- svelte-ignore a11y_no_static_element_interactions -->
                <div class="zone-row-main" onclick={() => toggleZone(zone)}>
                  <span class="zone-icon">Z{zone.name.slice(0, 1)}</span>
                  <div class="zone-info">
                    <div class="zone-name-row">
                      <strong>Zona {zone.name}</strong>
                      <span class="status-badge {statusClass(zone.status)}">{statusLabel(zone.status)}</span>
                    </div>
                    <span>{zone.tournament.name} {zone.tournament.year} · {zone.tournament.league.name}{#if zone.clubZones?.length} · {zone.clubZones.length} clubes{/if}</span>
                  </div>
                  <div class="zone-actions" onclick={(e) => e.stopPropagation()}>
                    <a class="button secondary" href={`/zones/${zone.id}/standings`}>Posiciones</a>
                    {#if canManage}
                      <button class="button primary" disabled={generating && generatingZoneId === zone.id} onclick={() => openFixtureModal(zone)}>
                        Generar fixture
                      </button>
                    {/if}
                  </div>
                  <svg class="chevron" class:rotated={expandedZone === zone.id} width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
                </div>

                {#if expandedZone === zone.id && canManage}
                  <div class="zone-clubs-panel">
                    {#if loadingClubs}
                      <p class="muted">Cargando clubes...</p>
                    {:else}
                      <div class="zone-clubs-grid">
                        <div class="clubs-col">
                          <h4>Clubes en la zona</h4>
                          {#if zoneClubs.length === 0}
                            <p class="muted empty-hint">Sin clubes asignados.</p>
                          {:else}
                            {#each zoneClubs as c}
                              <div class="club-chip">
                                <span>{c.clubName}</span>
                                <button class="icon-button remove-club" onclick={() => removeClub(zone.id, c.clubId)} aria-label="Remover club">
                                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" x2="6" y1="6" y2="18"/><line x1="6" x2="18" y1="6" y2="18"/></svg>
                                </button>
                              </div>
                            {/each}
                          {/if}
                        </div>
                        <div class="clubs-col">
                          <h4>Agregar club</h4>
                          {#if availableClubs.length === 0}
                            <p class="muted empty-hint">No hay mas clubes disponibles.</p>
                          {:else}
                            {#each availableClubs as c}
                              <div class="club-chip addable">
                                <span>{c.clubName}</span>
                                <button class="icon-button add-club" onclick={() => addClub(zone.id, c.clubId)} aria-label="Agregar club">
                                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" x2="12" y1="5" y2="19"/><line x1="5" x2="19" y1="12" y2="12"/></svg>
                                </button>
                              </div>
                            {/each}
                          {/if}
                        </div>
                      </div>
                    {/if}
                  </div>
                {/if}
              </article>
            </div>
          {/each}
        </div>
      {/if}
    </section>
  {/if}
</main>

{#if showFixtureModal && fixtureZone}
  <Modal onclose={closeFixtureModal}>
    <div class="modal-form">
      <p class="eyebrow">Generar fixture</p>
      <h2>Zona {fixtureZone.name}</h2>
      <p class="muted">{fixtureZone.tournament.name} {fixtureZone.tournament.year} · {fixtureZone.tournament.league.name}</p>
      {#if error}<p class="form-error">{error}</p>{/if}
      <form onsubmit={(event) => { event.preventDefault(); confirmGenerateFixture(); }}>
        <label class="checkbox-label"><input type="checkbox" bind:checked={idaVuelta} disabled={generating} /> Ida y vuelta</label>
        <div class="form-actions">
          <button class="button secondary" type="button" disabled={generating} onclick={closeFixtureModal}>Cancelar</button>
          <button class="button primary" type="submit" disabled={generating}>{generating ? 'Generando...' : 'Generar fixture'}</button>
        </div>
      </form>
    </div>
  </Modal>
{/if}

<style>
  .tournament-fixture-card { margin-bottom: 1.5rem; padding: 1.5rem clamp(1.5rem, 4vw, 2.5rem); }
  .tournament-fixture-card .muted { margin: .5rem 0 1rem; }
  .tournament-fixture-controls { display: flex; gap: .6rem; align-items: end; flex-wrap: wrap; }
  .tournament-fixture-controls label { flex: 1; min-width: 200px; }

  .zone-row { border-top: 1px solid var(--color-border); }
  .zone-row:first-child { border-top: 0; }
  .zone-row-main { display: flex; align-items: center; gap: .8rem; padding: 1rem 0; cursor: pointer; }
  .zone-row-main:hover { background: var(--color-surface-hover); margin: 0 -1rem; padding-left: 1rem; padding-right: 1rem; border-radius: .5rem; }
  .zone-icon { width: 2.2rem; height: 2.2rem; display: grid; place-items: center; flex-shrink: 0; border-radius: .6rem; background: var(--color-accent-bg); color: var(--color-accent-text); font-weight: 700; font-size: .85rem; font-family: 'Space Grotesk', sans-serif; }
  .zone-info { flex: 1; min-width: 0; }
  .zone-name-row { display: flex; align-items: center; gap: .5rem; flex-wrap: wrap; }
  .zone-name-row strong { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .zone-actions { display: flex; gap: .4rem; flex-shrink: 0; }
  .chevron { flex-shrink: 0; color: var(--color-text-muted); transition: transform 150ms ease; }
  .chevron.rotated { transform: rotate(180deg); }

  .zone-clubs-panel { padding: 0 0 1rem 3rem; }
  .zone-clubs-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; }
  .clubs-col h4 { margin: 0 0 .5rem; font-family: 'Space Grotesk', sans-serif; font-size: .85rem; color: var(--color-text-muted); }
  .club-chip {
    display: flex; align-items: center; justify-content: space-between;
    padding: .4rem .6rem; border: 1px solid var(--color-border);
    border-radius: .4rem; margin-bottom: .3rem; font-size: .82rem;
  }
  .club-chip.addable { cursor: pointer; background: var(--color-input); }
  .club-chip.addable:hover { border-color: var(--color-accent); }
  .remove-club { color: var(--color-error); }
  .add-club { color: var(--color-accent); }
  .empty-hint { font-size: .8rem; font-style: italic; }

  @media (max-width: 767px) {
    .zone-clubs-grid { grid-template-columns: 1fr; }
    .zone-actions { flex-direction: column; }
  }
</style>
