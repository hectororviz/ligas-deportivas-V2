<script lang="ts">
  import { onMount } from 'svelte';
  import { getHomeSummary, getProfile, hasSession, logout, type AuthUser, type HomeSummary, type HomeMatchday } from '$lib/api';
  import { loginModalState } from '$lib/login-modal.svelte';

  let user: AuthUser | null = null;
  let summary: HomeSummary | null = null;
  let loading = true;
  let error = '';

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
        <span class="count-pill">{summary?.tournaments.length ?? 0} torneos</span>
      </section>
      <section class="tournament-grid">
        {#each summary?.tournaments ?? [] as tournament}
          <article class="tournament-card">
            <p class="card-kicker">{tournament.leagueName}</p>
            <h3>{tournament.name} <span>{tournament.year}</span></h3>
            <div class="zone-list">
              {#each tournament.zones as zone}
                <div class="zone-block">
                  <div class="zone-title"><strong>Zona {zone.name}</strong></div>
                  {#if zone.top.length}
                    {#each zone.top as row, index}
                      <div class="standing-row">
                        <span class="position">{index + 1}</span>
                        <span>{row.clubName}</span>
                        <strong>{row.points} pts</strong>
                      </div>
                    {/each}
                  {:else}
                    <p class="muted compact">Todavía no hay posiciones.</p>
                  {/if}
                  <div class="zone-footer">{formatNextMatchday(zone.nextMatchday)}</div>
                </div>
              {/each}
            </div>
          </article>
        {/each}
      </section>
    {/if}
  </main>
{/if}

<style>
  .zone-footer {
    margin-top: .6rem;
    padding-top: .6rem;
    border-top: 1px solid var(--color-border);
    color: var(--color-accent-text);
    font-size: .78rem;
    font-weight: 600;
  }
</style>
