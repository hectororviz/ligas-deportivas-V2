<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import Modal from '$lib/Modal.svelte';
  import {
    assignClubToZone,
    canManageModule,
    deleteTournament,
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

  let showDeleteModal = $state(false);
  let deleteTarget: Tournament | null = $state(null);
  let deleteUsername = $state('');
  let deletePassword = $state('');
  let deleteError = $state('');
  let deleting = $state(false);

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

  function isInactiveTournament(tournament: Tournament) {
    return tournament.status !== 'ACTIVE';
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

  async function refreshData() {
    const [tournamentRows, zoneRows] = await Promise.all([getTournaments(true), getZones(true)]);
    tournaments = tournamentRows;
    zones = zoneRows;
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
      await refreshData();
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
      await refreshData();
      await openClubModal(zones.find((zone) => zone.id === clubModalZone?.id) ?? clubModalZone);
      notice = 'Club quitado de la zona.';
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo quitar el club.';
    } finally {
      savingClub = false;
    }
  }

  function zoneCanEdit(zone: Zone | null) {
    return Boolean(zone && canManageZones && (zone._count?.matches ?? 0) === 0);
  }

  function openDeleteModal(tournament: Tournament) {
    deleteTarget = tournament;
    deleteUsername = '';
    deletePassword = '';
    deleteError = '';
    showDeleteModal = true;
  }

  function closeDeleteModal() {
    if (deleting) return;
    showDeleteModal = false;
    deleteTarget = null;
  }

  async function confirmDeleteTournament() {
    if (!deleteTarget) return;
    if (!deleteUsername.trim() || !deletePassword) {
      deleteError = 'Ingresá tu usuario y contraseña.';
      return;
    }
    deleting = true;
    deleteError = '';
    try {
      await deleteTournament(deleteTarget.id, deleteUsername.trim(), deletePassword);
      notice = `Torneo "${deleteTarget.name}" eliminado.`;
      expandedTournaments.delete(deleteTarget.id);
      showDeleteModal = false;
      deleteTarget = null;
      await refreshData();
    } catch (cause) {
      deleteError = cause instanceof Error ? cause.message : 'No se pudo eliminar el torneo.';
    } finally {
      deleting = false;
    }
  }
</script>

<svelte:head><title>Torneos | Ligas Deportivas</title></svelte:head>

<main class="page-shell management-page">
  <header class="page-header">
    <div>
      <p class="eyebrow">Competencia</p>
      <h1>Torneos</h1>
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
          <div class="tree-header">
            <span class="h-spacer"></span>
            <span class="h-spacer"></span>
            <span class="h-name">Nombre</span>
            <span class="h-data">Datos</span>
            <span class="h-state">Estado</span>
            <span class="h-actions">Acciones</span>
          </div>
          {#each leagues as league}
            {@const leagueTournaments = tournamentsFor(league.id)}
            {@const leagueOpen = expandedLeagues.has(league.id)}
            <div class="tree-group">
              <div class="tree-row league-row" class:open={leagueOpen}>
                <button class="tree-toggle" onclick={() => toggleLeague(league.id)} aria-label={leagueOpen ? `Cerrar ${league.name}` : `Abrir ${league.name}`} aria-expanded={leagueOpen}>
                  <span class="toggle-symbol" class:cross={leagueOpen}>{leagueOpen ? '×' : '+'}</span>
                </button>
                <span class="row-mark league-mark" style={`--league-color:${league.colorHex}`}>{league.name.slice(0, 2).toUpperCase()}</span>
                <strong class="cell-name">{league.name}</strong>
                <span class="cell cell-day">{dayLabels[league.gameDay] ?? league.gameDay}</span>
                <span class="cell cell-state"></span>
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
                        <strong class="cell-name">{tournament.name}</strong>
                        <span class="cell cell-year">{tournament.year}</span>
                        <span class="cell cell-gender">{genderLabels[tournament.gender] ?? tournament.gender}</span>
                        <span class="cell-state {statusClass(tournament.status)}">{statusLabel(tournament.status)}</span>
                        <div class="row-actions">
                          {#if canManageTournaments}<button class="row-button" onclick={() => openEditTournament(tournament)}>Editar</button>{/if}
                          {#if canManageZones}<button class="row-button primary-row" onclick={() => openNewZone(tournament.id)}>Nueva zona</button>{/if}
                          {#if canManageTournaments && isInactiveTournament(tournament)}<button class="row-button danger" onclick={() => openDeleteModal(tournament)}>Eliminar</button>{/if}
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
                              <strong class="cell-name">Zona {zone.name}</strong>
                              <span class="cell cell-clubs" title={names.length ? names.join(', ') : 'Sin clubes asignados'}>{names.length} {names.length === 1 ? 'club' : 'clubes'}</span>
                              <span class="cell-state {statusClass(zone.status)}">{statusLabel(zone.status)}</span>
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

{#if showDeleteModal && deleteTarget}
  <Modal onclose={closeDeleteModal}>
    <div class="modal-form delete-modal">
      <p class="eyebrow">Eliminar torneo</p>
      <h2>{deleteTarget.name}</h2>
      <p class="muted">Esta acción eliminará el torneo y <strong>todos</strong> sus datos: zonas, clubes asignados, partidos, fixture, goles y resultados. No se puede deshacer.</p>
      {#if deleteError}<p class="form-error">{deleteError}</p>{/if}
      <form onsubmit={(event) => { event.preventDefault(); confirmDeleteTournament(); }}>
        <label>Usuario<input type="text" bind:value={deleteUsername} placeholder="admin" disabled={deleting} autocomplete="username" /></label>
        <label>Contraseña<input type="password" bind:value={deletePassword} placeholder="••••••••" disabled={deleting} autocomplete="current-password" /></label>
        <div class="form-actions">
          <button class="button secondary" type="button" disabled={deleting} onclick={closeDeleteModal}>Cancelar</button>
          <button class="button primary" type="submit" disabled={deleting} style="background:var(--color-error);color:#fff;">{deleting ? 'Eliminando...' : 'Eliminar definitivamente'}</button>
        </div>
      </form>
    </div>
  </Modal>
{/if}

<style>
  .management-heading { display: flex; justify-content: space-between; align-items: end; gap: 1rem; }
  .management-heading h2 { margin: .35rem 0 0; font-family: 'Space Grotesk', sans-serif; letter-spacing: -.04em; }
  .tree { margin-top: 1rem; border-top: 1px solid var(--color-border); }

  .tree-header {
    display: flex; align-items: center; gap: .7rem; padding: .4rem .5rem;
    border-bottom: 1px solid var(--color-border); background: var(--color-surface-hover);
    color: var(--color-text-muted); font-size: .7rem; font-weight: 700; text-transform: uppercase; letter-spacing: .05em;
  }
  .h-spacer { flex: 0 0 1.75rem; }
  .h-name { flex: 1 1 11rem; min-width: 0; }
  .h-data { flex: 0 0 16rem; }
  .h-state { flex: 0 0 6.5rem; }
  .h-actions { flex: 0 0 auto; text-align: right; margin-left: auto; }

  .tree-group { min-width: 0; }
  .tree-row { display: flex; align-items: center; gap: .7rem; min-height: 2.35rem; padding: .2rem .5rem; border-bottom: 1px solid var(--color-border); transition: background 150ms ease; }
  .tree-row:hover { background: var(--color-surface-hover); }
  .tree-row.open { background: color-mix(in srgb, var(--color-accent-bg) 32%, transparent); }

  .tree-toggle { width: 1.75rem; height: 1.75rem; display: grid; place-items: center; flex: 0 0 1.75rem; border: 1px solid var(--color-border); border-radius: .45rem; color: var(--color-accent-text); background: var(--color-surface); cursor: pointer; }
  .toggle-symbol { display: block; font-size: 1rem; line-height: 1; transition: transform 160ms ease; }
  .toggle-symbol.cross { transform: rotate(90deg); }

  .row-mark { width: 1.9rem; height: 1.9rem; display: grid; place-items: center; flex: 0 0 1.9rem; border-radius: .45rem; color: white; font-family: 'Space Grotesk', sans-serif; font-weight: 700; font-size: .78rem; }
  .league-mark { background: var(--league-color, var(--color-accent)); }
  .tournament-mark { color: var(--color-accent-text); background: var(--color-accent-bg); }
  .zone-mark { color: var(--color-text-muted); background: var(--color-surface-hover); }

  .cell-name { flex: 1 1 11rem; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: .9rem; }
  .cell { flex: 0 0 auto; color: var(--color-text-muted); font-size: .82rem; white-space: nowrap; }
  .cell-day { flex-basis: 8rem; }
  .cell-year { flex-basis: 4.5rem; }
  .cell-gender { flex-basis: 7.5rem; }
  .cell-clubs { flex-basis: 8rem; cursor: help; text-decoration: underline dotted var(--color-text-light); }

  .cell-state { flex: 0 0 6.5rem; justify-self: start; padding: .12rem .5rem; border-radius: 999px; background: var(--color-surface-hover); font-size: .72rem; font-weight: 700; white-space: nowrap; }
  .status-active, .status-open { color: var(--color-success); }
  .status-finished, .status-closed, .status-cancelled { color: var(--color-text-muted); }
  .status-draft { color: var(--color-accent-text); }

  .row-actions { display: flex; align-items: center; gap: .35rem; margin-left: auto; }
  .row-button { border: 0; border-radius: .45rem; padding: .3rem .55rem; color: var(--color-accent-text); background: var(--color-accent-bg); cursor: pointer; font-size: .74rem; font-weight: 700; white-space: nowrap; }
  .primary-row { color: var(--color-hero); background: var(--color-hero-accent); }
  .danger { color: var(--color-error); background: var(--color-error-bg); }
  .disabled-button { opacity: .48; cursor: not-allowed; }

  .tree-children { margin-left: 2.2rem; border-left: 1px solid var(--color-border); animation: tree-open 160ms ease both; }
  .zone-children { margin-left: 4rem; }
  .branch-mark { width: 1.75rem; flex: 0 0 1.75rem; color: var(--color-text-light); font-family: monospace; text-align: center; }
  .tree-empty { padding: .5rem 1rem; border-bottom: 1px solid var(--color-border); color: var(--color-text-muted); font-size: .8rem; }

  .club-modal h2 { margin-bottom: .35rem; }
  .club-modal-list, .available-clubs { display: grid; gap: .45rem; margin-top: 1.25rem; }
  .available-clubs { padding-top: 1rem; border-top: 1px solid var(--color-border); }
  .available-clubs h3 { margin: 0; font-size: .9rem; }
  .club-modal-row { display: flex; align-items: center; justify-content: space-between; gap: .75rem; padding: .65rem .75rem; border: 1px solid var(--color-border); border-radius: .55rem; }
  .club-modal-row div { display: grid; gap: .15rem; }
  .locked-note { margin-top: 1rem; padding: .7rem; border-radius: .55rem; color: var(--color-text-muted); background: var(--color-surface-hover); font-size: .82rem; }

  @keyframes tree-open { from { opacity: 0; transform: translateY(-.2rem); } to { opacity: 1; transform: translateY(0); } }

  @media (max-width: 760px) {
    .management-heading { align-items: start; }
    .tree-header { display: none; }
    .tree-row { flex-wrap: wrap; padding: .5rem .25rem; row-gap: .3rem; }
    .cell-name { flex-basis: calc(100% - 5rem); }
    .cell, .cell-state { flex-basis: auto; }
    .row-actions { width: 100%; margin-left: 4.4rem; flex-wrap: wrap; }
    .tree-children { margin-left: 1.2rem; }
    .zone-children { margin-left: 2.2rem; }
    .zone-row .row-actions { margin-left: 3.7rem; }
  }
</style>
