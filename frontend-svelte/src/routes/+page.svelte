<script lang="ts">
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';
  import { getHomeSummary, getProfile, hasSession, logout, type AuthUser, type HomeSummary } from '$lib/api';

  let user: AuthUser | null = null;
  let summary: HomeSummary | null = null;
  let loading = true;
  let error = '';

  onMount(async () => {
    if (!hasSession()) {
      await goto('/login');
      return;
    }
    try {
      [user, summary] = await Promise.all([getProfile(), getHomeSummary()]);
    } catch {
      error = 'No pudimos cargar el resumen de torneos.';
    } finally {
      loading = false;
    }
  });

  async function signOut() {
    await logout();
    await goto('/login');
  }
</script>

{#if loading}
  <main class="loading-screen">Cargando sesión...</main>
{:else if user}
  <main class="dashboard-shell">
    <section class="dashboard-card dashboard-hero">
      <div>
        <p class="eyebrow">Panel de administración</p>
        <h1>Hola, {user.firstName}</h1>
        <p class="muted">Resumen de torneos activos y posiciones por zona.</p>
      </div>
      <div class="user-summary">
        <span>{user.email}</span>
        <div class="dashboard-actions">
          <a class="button secondary" href="/leagues">Ver ligas</a>
          <button class="button secondary" onclick={signOut}>Cerrar sesión</button>
        </div>
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
                  <div class="zone-title"><strong>Zona {zone.name}</strong><span>{zone.nextMatchday ? `Fecha ${zone.nextMatchday.matchday}` : 'Sin próxima fecha'}</span></div>
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
                </div>
              {/each}
            </div>
          </article>
        {/each}
      </section>
    {/if}
  </main>
{/if}
