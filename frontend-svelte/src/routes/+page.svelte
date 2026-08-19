<script lang="ts">
  import { onMount } from 'svelte';
  import { getHomeSummary, getProfile, hasSession, logout, type AuthUser, type HomeSummary, type HomeMatchday } from '$lib/api';
  import { loginModalState } from '$lib/login-modal.svelte';

  let user: AuthUser | null = null;
  let summary: HomeSummary | null = null;
  let loading = true;
  let error = '';
  let selectedTournamentId: number | null = null;

  onMount(async () => {
    try {
      const profilePromise = hasSession() ? getProfile().catch(() => null) : Promise.resolve(null);
      [user, summary] = await Promise.all([profilePromise, getHomeSummary()]);
    } catch {
      error = 'No pudimos cargar el resumen de torneos.';
    } finally {
      loading = false;
    }
  });

  function toggleTournament(id: number) {
    selectedTournamentId = selectedTournamentId === id ? null : id;
  }

  async function signOut() {
    await logout();
    window.location.href = '/';
  }

  function formatNextMatchday(md: HomeMatchday | null): string {
    if (!md) return 'Sin próxima fecha';
    const base = `Fecha ${md.matchday}`;
    if (!md.date) return base;
    const d = new Date(md.date);
    if (isNaN(d.getTime())) return base;
    const weekday = d.toLocaleDateString('es-AR', { weekday: 'long' });
    const capitalized = weekday.charAt(0).toUpperCase() + weekday.slice(1);
    const dayMonth = d.toLocaleDateString('es-AR', { day: '2-digit', month: '2-digit' });
    return `${capitalized} ${dayMonth} - Fecha ${md.matchday}`;
  }
</script>

{#if loading}
  <main class="loading-screen">Cargando sesión...</main>
{:else}
  <main class="dashboard-shell">
    <section class="dashboard-card dashboard-hero">
      <div>
        <p class="eyebrow">Ligas Deportivas</p>
        <h1>{user ? `Hola, ${user.firstName}` : 'Torneos vigentes'}</h1>
        <p class="muted">Resumen de torneos activos y posiciones por zona.</p>
      </div>
      <div class="user-summary">
        {#if user}
          <span>@{user.username}</span>
          <div class="dashboard-actions">
            <a class="button secondary" href="/leagues">Ver ligas</a>
            <button class="button secondary" onclick={signOut}>Cerrar sesión</button>
          </div>
        {:else}
          <div class="dashboard-actions">
            <button class="button primary" onclick={() => loginModalState.openModal()}>Ingresar</button>
          </div>
        {/if}
      </div>
    </section>
    {#if error}
      <section class="error-banner">{error}</section>
    {:else if summary?.tournaments.length === 0}
      <section class="empty-state">
        <span class="empty-icon">+</span>
        <h2>No hay torneos vigentes</h2>
        <p>Cuando haya torneos activos podrás ver aquí el resumen por zonas.</p>
      </section>
    {:else}
      <section class="section-heading">
        <div>
          <p class="eyebrow">Competencia</p>
          <h2>Torneos vigentes</h2>
        </div>
      </section>

      <div class="tournament-chips">
        {#each summary?.tournaments ?? [] as tournament}
          <button
            class="chip"
            class:active={selectedTournamentId === tournament.id}
            onclick={() => toggleTournament(tournament.id)}
          >
            {tournament.leagueName} - {tournament.year}
          </button>
        {/each}
      </div>

      <section class="zone-grid">
        {#each summary?.tournaments ?? [] as tournament}
          {#if selectedTournamentId == null || tournament.id === selectedTournamentId}
            {#each tournament.zones as zone}
              <article class="zone-card">
                <div class="zone-header">
                  <div class="zone-heading">
                    <p class="card-kicker">{tournament.leagueName} · {tournament.year}</p>
                    <h3>Zona {zone.name}</h3>
                  </div>
                  <div class="zone-actions">
                    <a class="zone-btn" href={`/fixtures?torneo=${tournament.id}&zona=${zone.id}`}>Fixture</a>
                    <a class="zone-btn" href={`/standings?torneo=${tournament.id}&zona=${zone.id}`}>Tabla</a>
                  </div>
                </div>

                {#if zone.top.length}
                  <div class="standings">
                    {#each zone.top as row, index}
                      <div class="stand-row">
                        <span class="stand-pos">{index + 1}</span>
                        <span class="stand-club">{row.clubName}</span>
                        <span class="stand-pts">{row.points} pts</span>
                      </div>
                    {/each}
                  </div>
                {:else}
                  <p class="muted compact">Todavía no hay posiciones.</p>
                {/if}

                <div class="zone-footer">
                  {#if zone.nextMatchday}Próxima Fecha: {formatNextMatchday(zone.nextMatchday)}{:else}Sin próxima fecha{/if}
                </div>
              </article>
            {/each}
          {/if}
        {/each}
      </section>
    {/if}
  </main>
{/if}

<style>
  .tournament-chips {
    display: flex;
    flex-wrap: wrap;
    gap: .5rem;
    margin: .75rem 0 1.5rem;
  }
  .chip {
    border: 1px solid var(--color-border);
    background: var(--color-surface);
    color: var(--color-text-muted);
    padding: .45rem .95rem;
    border-radius: 999px;
    font-size: .84rem;
    font-weight: 600;
    cursor: pointer;
    transition: background 150ms ease, color 150ms ease, border-color 150ms ease;
  }
  .chip:hover { background: var(--color-surface-hover); color: var(--color-text); }
  .chip.active {
    background: var(--color-accent-bg);
    border-color: var(--color-accent);
    color: var(--color-accent-text);
  }

  .zone-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
    gap: 1rem;
  }
  .zone-card {
    display: flex;
    flex-direction: column;
    padding: 1.25rem;
    border: 1px solid var(--color-border);
    border-radius: 1.2rem;
    background: var(--color-surface);
    box-shadow: 0 16px 45px var(--color-shadow);
  }
  .zone-header {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: .75rem;
  }
  .zone-heading { min-width: 0; }
  .zone-heading h3 {
    margin: .25rem 0 0;
    font-family: 'Space Grotesk', sans-serif;
    font-size: 1.25rem;
    letter-spacing: -.02em;
  }
  .card-kicker {
    margin: 0;
    color: var(--color-accent-text);
    font-size: .72rem;
    font-weight: 700;
    letter-spacing: .08em;
    text-transform: uppercase;
  }
  .zone-actions {
    display: flex;
    gap: .35rem;
    flex: 0 0 auto;
  }
  .zone-btn {
    display: inline-flex;
    align-items: center;
    padding: .35rem .6rem;
    border: 1px solid var(--color-border);
    border-radius: .55rem;
    color: var(--color-accent-text);
    background: var(--color-accent-bg);
    font-size: .74rem;
    font-weight: 700;
    text-decoration: none;
    white-space: nowrap;
    transition: background 150ms ease, border-color 150ms ease;
  }
  .zone-btn:hover { background: var(--color-accent); border-color: var(--color-accent); color: #fff; }

  .standings { margin-top: .9rem; }
  .stand-row {
    display: flex;
    align-items: center;
    gap: .5rem;
    padding: .4rem 0;
    border-top: 1px solid var(--color-border);
    font-size: .88rem;
  }
  .stand-pos {
    width: 1.35rem;
    height: 1.35rem;
    display: grid;
    place-items: center;
    border-radius: 50%;
    color: var(--color-accent-text);
    background: var(--color-accent-bg);
    font-size: .68rem;
    font-weight: 700;
    flex: 0 0 auto;
  }
  .stand-club {
    min-width: 0;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    font-weight: 500;
  }
  .stand-pts {
    color: var(--color-text-muted);
    font-size: .78rem;
    font-weight: 700;
    white-space: nowrap;
  }

  .zone-footer {
    margin-top: auto;
    padding-top: .6rem;
    border-top: 1px solid var(--color-border);
    color: var(--color-accent-text);
    font-size: .78rem;
    font-weight: 600;
  }
</style>
