<script lang="ts">
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';
  import { generateFixture, generateTournamentFixture, getProfile, getTournaments, getZones, type AuthUser, type Tournament, type Zone } from '$lib/api';
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

  function statusLabel(status: string) {
    const map: Record<string, string> = {
      ACTIVE: 'Activa',
      INACTIVE: 'Inactiva',
      DRAFT: 'Borrador',
      CLOSED: 'Cerrada'
    };
    return map[status] ?? status;
  }

  function statusClass(status: string) {
    const map: Record<string, string> = {
      ACTIVE: 'badge-active',
      INACTIVE: 'badge-inactive',
      DRAFT: 'badge-draft',
      CLOSED: 'badge-closed'
    };
    return map[status] ?? 'badge-default';
  }

  function openFixtureModal(zone: Zone) {
    fixtureZone = zone;
    idaVuelta = true;
    showFixtureModal = true;
    error = '';
  }

  function closeFixtureModal() {
    showFixtureModal = false;
    fixtureZone = null;
  }

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
    } finally {
      generating = false;
    }
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
    } finally {
      generatingTournament = false;
    }
  }
</script>

<svelte:head><title>Zonas | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div><p class="eyebrow">Competencia</p><h1>Zonas</h1><p class="muted">Administra las zonas de cada torneo, sus posiciones y la generación de partidos.</p></div>
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
          <div><p class="eyebrow">Generación masiva</p><h2>Fixture del torneo</h2></div>
        </div>
        <p class="muted">Genera los partidos para todas las zonas de un torneo de una vez.</p>
        <div class="tournament-fixture-controls">
          <label>
            Torneo
            <select bind:value={selectedTournament}>
              <option value={null}>Seleccionar torneo...</option>
              {#each tournaments as t}
                <option value={t.id}>{t.name} {t.year} · {t.league.name}</option>
              {/each}
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
        <div><p class="eyebrow">Catálogo</p><h2>Zonas registradas</h2></div>
        <span class="count-pill">{zones.length}</span>
      </div>
      {#if zones.length === 0}
        <div class="empty-state compact-empty"><h2>Sin zonas todavía</h2><p>Crea torneos y zonas para comenzar.</p></div>
      {:else}
        <div class="zone-table">
          {#each zones as zone}
            <article class="zone-row">
              <span class="zone-icon">Z{zone.name.slice(0, 1)}</span>
              <div class="zone-info">
                <div class="zone-name-row">
                  <strong>Zona {zone.name}</strong>
                  <span class="status-badge {statusClass(zone.status)}">{statusLabel(zone.status)}</span>
                </div>
                <span>{zone.tournament.name} {zone.tournament.year} · {zone.tournament.league.name}{#if zone.clubZones?.length} · {zone.clubZones.length} clubes{/if}</span>
              </div>
              <div class="zone-actions">
                <a class="button secondary" href={`/zones/${zone.id}/standings`}>Posiciones</a>
                {#if canManage}
                  <button class="button primary" disabled={generating && generatingZoneId === zone.id} onclick={() => openFixtureModal(zone)}>
                    Generar fixture
                  </button>
                {/if}
              </div>
            </article>
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
        <label class="checkbox-label">
          <input type="checkbox" bind:checked={idaVuelta} disabled={generating} />
          Ida y vuelta
        </label>
        <div class="form-actions">
          <button class="button secondary" type="button" disabled={generating} onclick={closeFixtureModal}>Cancelar</button>
          <button class="button primary" type="submit" disabled={generating}>
            {generating ? 'Generando...' : 'Generar fixture'}
          </button>
        </div>
      </form>
    </div>
  </Modal>
{/if}

<style>
  .tournament-fixture-card { margin-bottom: 1.5rem; padding: 1.5rem clamp(1.5rem, 4vw, 2.5rem); }
  .tournament-fixture-card .muted { margin: .5rem 0 1rem; }
  .tournament-fixture-controls { display: flex; gap: .6rem; align-items: end; flex-wrap: wrap; }
  .tournament-fixture-controls label { max-width: 380px; }
  .modal-form h2 { margin: .5rem 0 .5rem; font-family: 'Space Grotesk', sans-serif; font-size: 1.6rem; letter-spacing: -.04em; }
  .modal-form .muted { margin: 0 0 1.5rem; }
  .modal-form form { margin-top: 0; }
</style>
