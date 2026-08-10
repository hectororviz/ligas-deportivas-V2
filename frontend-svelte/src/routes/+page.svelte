<script lang="ts">
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';
  import { getProfile, hasSession, logout, type AuthUser } from '$lib/api';

  let user: AuthUser | null = null;
  let loading = true;

  onMount(async () => {
    if (!hasSession()) {
      await goto('/login');
      return;
    }
    try {
      user = await getProfile();
    } catch {
      await goto('/login');
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
    <section class="dashboard-card">
      <div>
        <p class="eyebrow">Panel de administración</p>
        <h1>Hola, {user.firstName}</h1>
        <p class="muted">La nueva interfaz SvelteKit ya está conectada a la API existente.</p>
      </div>
      <div class="user-summary">
        <span>{user.email}</span>
        <button class="button secondary" onclick={signOut}>Cerrar sesión</button>
      </div>
    </section>
    <section class="migration-note">
      <strong>Próximo módulo: ligas</strong>
      <span>Consulta el seguimiento en <code>docs/migracion-frontend.md</code>.</span>
    </section>
  </main>
{/if}
