<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import Modal from '$lib/Modal.svelte';
  import {
    assignClubToZone,
    canManageModule,
    getLeagues,
    getProfile,
    getTournaments,
    getTournamentZoneClubs,
    getZones,
    removeClubFromZone,
    type AuthUser,
    type League,
    type Tournament,
    type TournamentZoneClub,
    type Zone
  } from '$lib/api';

  const genderLabels: Record<string, string> = {
    MASCULINO: 'Masculino',
    FEMENINO: 'Femenino',
    MIXTO: 'Mixto'
  };
  const dayLabels: Record<string, string> = {
    DOMINGO: 'Domingo',
    LUNES: 'Lunes',
    MARTES: 'Martes',
    MIERCOLES: 'Miércoles',
    JUEVES: 'Jueves',
    VIERNES: 'Viernes',
    SABADO: 'Sábado'
  };
  const statusLabels: Record<string, string> = {
    ACTIVE: 'Activo',
    DRAFT: 'Borrador',
    FINISHED: 'Finalizado',
    CANCELLED: 'Cancelado',
    OPEN: 'Abierta',
    CLOSED: 'Cerrada'
  };

  let user: AuthUser | null = $state(null);
  let leagues: League[] = $state([]);
  let tournaments: Tournament[] = $state([]);
  let zones: Zone[] = $state([]);
  let loading = $state(true);
  let error = $state('');
  let notice = $state('');
  let expandedLeagues = $state(new Set<number>());
  let expandedTournaments = $state(new Set<number>());

  let clubModalOpen = $state(false);
  let clubModalZone: Zone | null = $state(null);
  let clubOptions = $state<TournamentZoneClub[]>([]);
  let clubModalLoading = $state(false);
  let savingClub = $state(false);

  const canManageLeagues = $derived(canManageModule(user, 'LIGAS'));
  const canManageTournaments = $derived(canManageModule(user, 'TORNEOS'));
  const canManageZones = $derived(canManageModule(user, 'ZONAS'));

  onMount(async () => {
    try {
      const [profile, leagueRows, tournamentRows, zoneRows] = await Promise.all([
        getProfile(),
        getLeagues(),
        getTournaments(true),
        getZones(true)
      ]);
      user = profile;
      leagues = leagueRows;
      tournaments = tournamentRows;
      zones = zoneRows;
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo cargar la gestión.';
    } finally {
      loading = false;
    }
  });

  function tournamentsFor(leagueId: number) {
    return tournaments.filter((tournament) => tournament.leagueId === leagueId);
  }

  function zonesFor(tournamentId: number) {
    return zones.filter((zone) => zone.tournamentId === tournamentId);
  }

  function toggleLeague(id: number) {
    const next = new Set(expandedLeagues);
    next.has(id) ? next.delete(id) : next.add(id);
    expandedLeagues = next;
  }

  function toggleTournament(id: number) {
    const next = new Set(expandedTournaments);
    next.has(id) ? next.delete(id) : next.add(id);
    expandedTournaments = next;
  }

  function statusLabel(status: string) {
    return statusLabels[status] ?? status;
  }

  function statusClass(status: string) {
    return `status-${status.toLowerCase()}`;
  }

  function clubNames(zone: Zone) {
    return (zone.clubZones ?? []).map((assignment) => assignment.club.name);
  }

  function fixtureAvailable(zone: Zone) {
    return canManageZones && (zone._count?.clubZones ?? 0) > 0 && (zone._count?.matches ?? 0) === 0 && zone.status === 'OPEN';
  }

  function openFixture(zone: Zone) {
    if (!fixtureAvailable(zone)) return;
    goto(`/zones?zona=${zone.id}`);
  }

  function openNewLeague() {
    goto('/leagues');
  }

  function openNewTournament(leagueId: number) {
    goto(`/tournaments?liga=${leagueId}`);
  }

  function openEditTournament(tournament: Tournament) {
    goto(`/tournaments?editar=${tournament.id}`);
  }

  function openNewZone(tournamentId: number) {
    goto(`/zones?torneo=${tournamentId}`);
  }

  function openEditLeague(league: League) {
    goto(`/leagues?editar=${league.id}`);
  }

  async function openClubModal(zone: Zone) {
    clubModalZone = zone;
    clubModalOpen = true;
    clubModalLoading = true;
    try {
      clubOptions = await getTournamentZoneClubs(zone.tournamentId, zone.id);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar los clubes.';
      clubOptions = [];
    } finally {
      clubModalLoading = false;
    }
  }

  function closeClubModal() {
    if (savingClub) return;
    clubModalOpen = false;
    clubModalZone = null;
  }

  async function addClub(clubId: number) {
    if (!clubModalZone || !zoneCanEdit(clubModalZone)) return;
    savingClub = true;
    try {
      await assignClubToZone(clubModalZone.id, clubId);
      await refreshZones();
      await openClubModal(zones.find((zone) => zone.id === clubModalZone?.id) ?? clubModalZone);
      notice = 'Club agregado a la zona.';
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo agregar el club.';
    } finally {
      savingClub = false;
    }
  }

  async function removeClub(clubId: number) {
    if (!clubModalZone || !zoneCanEdit(clubModalZone)) return;
    savingClub = true;
    try {
      await removeClubFromZone(clubModalZone.id, clubId);
      await refreshZones();
      await openClubModal(zones.find((zone) => zone.id === clubModalZone?.id) ?? clubModalZone);
      notice = 'Club quitado de la zona.';
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo quitar el club.';
    } finally {
      savingClub = false;
    }
  }

  async function refreshZones() {
    zones = await getZones(true);
  }

  function zoneCanEdit(zone: Zone | null) {
    return Boolean(zone && canManageZones && (zone._count?.matches ?? 0) === 0);
  }
</script>

<svelte:head><title>Gestión | Ligas Deportivas</title></svelte:head>

<main class="page-shell management-page">
  <header class="page-header">
    <div>
      <p class="eyebrow">Competencia</p>
      <h1>Gestión</h1>
      <p class="muted">Ligas, torneos y zonas en una sola vista.</p>
    </div>
    {#if canManageLeagues}
      <button class="button primary" onclick={openNewLeague}>Nueva liga</button>
    {/if}
  </header>

  {#if loading}
    <section class="loading-card">Cargando gestión...</section>
  {:else}
    {#if error}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}

    <section class="management-surface card-surface">
      <div class="management-heading">
        <div><p class="eyebrow">Árbol de competencia</p><h2>Estructura deportiva</h2></div>
        <span class="count-pill">{leagues.length} ligas</span>
      </div>

      {#if leagues.length === 0}
        <div class="empty-state compact-empty"><h2>Sin ligas todavía</h2><p>Creá una liga para comenzar.</p></div>
      {:else}
        <div class="tree" aria-label="Gestión de ligas, torneos y zonas">
          {#each leagues as league}
            {@const leagueTournaments = tournamentsFor(league.id)}
            {@const leagueOpen = expandedLeagues.has(league.id)}
            <div class="tree-group">
              <div class="tree-row league-row" class:open={leagueOpen}>
                <button class="tree-toggle" onclick={() => toggleLeague(league.id)} aria-label={leagueOpen ? `Cerrar ${league.name}` : `Abrir ${league.name}`} aria-expanded={leagueOpen}>
                  <span class="toggle-symbol" class:cross={leagueOpen}>{leagueOpen ? '×' : '+'}</span>
                </button>
                <span class="row-mark league-mark" style={`--league-color:${league.colorHex}`}>{league.name.slice(0, 2).toUpperCase()}</span>
                <div class="row-content"><strong>{league.name}</strong><span>{dayLabels[league.gameDay] ?? league.gameDay}</span></div>
                <div class="row-actions">
                  {#if canManageLeagues}<button class="row-button" onclick={() => openEditLeague(league)}>Editar</button>{/if}
                  {#if canManageTournaments}<button class="row-button primary-row" onclick={() => openNewTournament(league.id)}>Nuevo torneo</button>{/if}
                </div>
              </div>

              {#if leagueOpen}
                <div class="tree-children league-children">
                  {#if leagueTournaments.length === 0}
                    <div class="tree-empty">No hay torneos en esta liga.</div>
                  {/if}
                  {#each leagueTournaments as tournament}
                    {@const tournamentZones = zonesFor(tournament.id)}
                    {@const tournamentOpen = expandedTournaments.has(tournament.id)}
                    <div class="tree-group">
                      <div class="tree-row tournament-row" class:open={tournamentOpen}>
                        <button class="tree-toggle" onclick={() => toggleTournament(tournament.id)} aria-label={tournamentOpen ? `Cerrar ${tournament.name}` : `Abrir ${tournament.name}`} aria-expanded={tournamentOpen}>
                          <span class="toggle-symbol" class:cross={tournamentOpen}>{tournamentOpen ? '×' : '+'}</span>
                        </button>
                        <span class="row-mark tournament-mark">T</span>
                        <div class="row-content"><strong>{tournament.name}</strong><span>{tournament.year} · {genderLabels[tournament.gender] ?? tournament.gender} · <em class={statusClass(tournament.status)}>{statusLabel(tournament.status)}</em></span></div>
                        <div class="row-actions">
                          {#if canManageTournaments}<button class="row-button" onclick={() => openEditTournament(tournament)}>Editar</button>{/if}
                          {#if canManageZones}<button class="row-button primary-row" onclick={() => openNewZone(tournament.id)}>Nueva zona</button>{/if}
                        </div>
                      </div>

                      {#if tournamentOpen}
                        <div class="tree-children zone-children">
                          {#if tournamentZones.length === 0}<div class="tree-empty">No hay zonas en este torneo.</div>{/if}
                          {#each tournamentZones as zone}
                            {@const names = clubNames(zone)}
                            <div class="tree-row zone-row">
                              <span class="branch-mark">└─</span>
                              <span class="row-mark zone-mark">Z</span>
                              <div class="row-content"><strong>Zona {zone.name}</strong><span class="club-count" title={names.length ? names.join(', ') : 'Sin clubes asignados'}>{names.length} {names.length === 1 ? 'club' : 'clubes'}</span> <em class={statusClass(zone.status)}>{statusLabel(zone.status)}</em></div>
                              <div class="row-actions">
                                <button class="row-button" class:disabled-button={!canManageZones || (zone._count?.matches ?? 0) > 0} onclick={() => openClubModal(zone)}>Editar</button>
                                <button class="row-button primary-row" class:disabled-button={!fixtureAvailable(zone)} disabled={!fixtureAvailable(zone)} onclick={() => openFixture(zone)}>Generar fixture</button>
                              </div>
                            </div>
                          {/each}
                        </div>
                      {/if}
                    </div>
                  {/each}
                </div>
              {/if}
            </div>
          {/each}
        </div>
      {/if}
    </section>
  {/if}
</main>

{#if clubModalOpen && clubModalZone}
  <Modal onclose={closeClubModal}>
    <div class="modal-form club-modal">
      <p class="eyebrow">Administrar zona</p>
      <h2>Zona {clubModalZone.name}</h2>
      <p class="muted">{clubModalZone.tournament.name} · {clubModalZone.tournament.year}</p>
      {#if (clubModalZone._count?.matches ?? 0) > 0}
        <p class="locked-note">Esta zona ya tiene fixture generado. Los clubes se muestran en modo lectura.</p>
      {/if}
      {#if clubModalLoading}
        <p class="muted">Cargando clubes...</p>
      {:else}
        <div class="club-modal-list">
          {#each clubModalZone.clubZones ?? [] as assignment}
            <div class="club-modal-row">
              <div><strong>{assignment.club.name}</strong></div>
              {#if zoneCanEdit(clubModalZone)}<button class="icon-button" onclick={() => removeClub(assignment.club.id)} disabled={savingClub} aria-label={`Quitar ${assignment.club.name}`}>−</button>{/if}
            </div>
          {:else}
            <p class="muted">No hay clubes asignados.</p>
          {/each}
        </div>
        {#if zoneCanEdit(clubModalZone)}
          <div class="available-clubs">
            <h3>Agregar club</h3>
            {#each clubOptions as club}
              <div class="club-modal-row available"><span>{club.name}</span><button class="icon-button" onclick={() => addClub(club.id)} disabled={savingClub} aria-label={`Agregar ${club.name}`}>+</button></div>
            {:else}
              <p class="muted">No hay clubes disponibles.</p>
            {/each}
          </div>
        {/if}
      {/if}
      <div class="form-actions"><button class="button secondary" type="button" onclick={closeClubModal}>Cerrar</button></div>
    </div>
  </Modal>
{/if}

<style>
  .management-heading { display: flex; justify-content: space-between; align-items: end; gap: 1rem; }
  .management-heading h2 { margin: .35rem 0 0; font-family: 'Space Grotesk', sans-serif; letter-spacing: -.04em; }
  .tree { margin-top: 1.4rem; border-top: 1px solid var(--color-border); }
  .tree-group { min-width: 0; }
  .tree-row { display: flex; align-items: center; gap: .7rem; min-height: 4.2rem; border-bottom: 1px solid var(--color-border); transition: background 150ms ease; }
  .tree-row:hover { background: var(--color-surface-hover); }
  .tree-row.open { background: color-mix(in srgb, var(--color-accent-bg) 32%, transparent); }
  .tree-toggle { width: 2rem; height: 2rem; display: grid; place-items: center; flex: 0 0 auto; border: 1px solid var(--color-border); border-radius: .55rem; color: var(--color-accent-text); background: var(--color-surface); cursor: pointer; }
  .toggle-symbol { display: block; font-size: 1.25rem; line-height: 1; transition: transform 180ms ease; }
  .toggle-symbol.cross { transform: rotate(90deg); }
  .row-mark { width: 2.25rem; height: 2.25rem; display: grid; place-items: center; flex: 0 0 auto; border-radius: .6rem; color: white; font-family: 'Space Grotesk', sans-serif; font-weight: 700; }
  .league-mark { background: var(--league-color, var(--color-accent)); }
  .tournament-mark { color: var(--color-accent-text); background: var(--color-accent-bg); }
  .zone-mark { color: var(--color-text-muted); background: var(--color-surface-hover); }
  .row-content { display: grid; gap: .25rem; min-width: 0; flex: 1; }
  .row-content strong { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .row-content span { color: var(--color-text-muted); font-size: .8rem; }
  .row-content em { font-style: normal; font-weight: 700; }
  .row-actions { display: flex; align-items: center; justify-content: end; gap: .4rem; flex-wrap: wrap; }
  .row-button { border: 0; border-radius: .5rem; padding: .48rem .65rem; color: var(--color-accent-text); background: var(--color-accent-bg); cursor: pointer; font-size: .76rem; font-weight: 700; white-space: nowrap; }
  .primary-row { color: var(--color-hero); background: var(--color-hero-accent); }
  .disabled-button { opacity: .48; cursor: not-allowed; }
  .tree-children { margin-left: 2.9rem; border-left: 1px solid var(--color-border); animation: tree-open 180ms ease both; }
  .tree-children .tree-row { padding-left: .8rem; }
  .zone-children { margin-left: 5.8rem; }
  .zone-row { min-height: 3.7rem; }
  .branch-mark { width: 1.5rem; flex: 0 0 auto; color: var(--color-text-light); font-family: monospace; }
  .tree-empty { padding: .85rem 1rem; border-bottom: 1px solid var(--color-border); color: var(--color-text-muted); font-size: .82rem; }
  .club-count { cursor: help; text-decoration: underline dotted var(--color-text-light); }
  .status-active { color: var(--color-success); }
  .status-finished, .status-closed, .status-cancelled { color: var(--color-text-muted); }
  .status-draft, .status-open { color: var(--color-accent-text); }
  .club-modal h2 { margin-bottom: .35rem; }
  .club-modal-list, .available-clubs { display: grid; gap: .45rem; margin-top: 1.25rem; }
  .available-clubs { padding-top: 1rem; border-top: 1px solid var(--color-border); }
  .available-clubs h3 { margin: 0; font-size: .9rem; }
  .club-modal-row { display: flex; align-items: center; justify-content: space-between; gap: .75rem; padding: .65rem .75rem; border: 1px solid var(--color-border); border-radius: .55rem; }
  .club-modal-row div { display: grid; gap: .15rem; }
  .locked-note { margin-top: 1rem; padding: .7rem; border-radius: .55rem; color: var(--color-text-muted); background: var(--color-surface-hover); font-size: .82rem; }
  @keyframes tree-open { from { opacity: 0; transform: translateY(-.3rem); } to { opacity: 1; transform: translateY(0); } }
  @media (max-width: 760px) {
    .management-heading { align-items: start; }
    .tree-row { align-items: start; padding: .7rem 0; flex-wrap: wrap; }
    .tree-toggle, .row-mark { margin-top: .1rem; }
    .row-content { min-width: calc(100% - 7rem); }
    .row-actions { width: 100%; margin-left: 4.95rem; justify-content: start; }
    .tree-children { margin-left: 1.2rem; }
    .zone-children { margin-left: 2.4rem; }
    .zone-row .row-actions { margin-left: 3.7rem; }
  }
</style>
