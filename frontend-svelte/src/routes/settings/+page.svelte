<script lang="ts">
  import { onMount } from 'svelte';
  import { getProfile, hasSession, type AuthUser } from '$lib/api';
  import { goto } from '$app/navigation';

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
      //
    } finally {
      loading = false;
    }
  });
</script>

<svelte:head><title>Configuración | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div>
      <p class="eyebrow">Configuración</p>
      <h1>Ajustes</h1>
      <p class="muted">Administra tu cuenta y la identidad del sitio.</p>
    </div>
    <a class="button secondary" href="/">Volver al panel</a>
  </header>

  {#if loading}
    <section class="loading-card">Cargando...</section>
  {:else if user}
    <section class="card-surface" style="display:grid; gap:.8rem;">
      <a class="league-row" href="/settings/account" style="text-decoration:none; padding: 1.2rem 1rem;">
        <span class="league-color" style="--league-color: #173d35">{user.firstName.charAt(0)}{user.lastName.charAt(0)}</span>
        <div class="league-info">
          <strong>Cuenta y perfil</strong>
          <span>Actualiza tu nombre, apellido y contraseña.</span>
        </div>
      </a>
      <a class="league-row" href="/settings/site-identity" style="text-decoration:none; padding: 1.2rem 1rem;">
        <span class="league-color" style="--league-color: #d0e87c; color: #173d35;">SI</span>
        <div class="league-info">
          <strong>Identidad del sitio</strong>
          <span>Cambia el título, ícono y favicon de la plataforma.</span>
        </div>
      </a>
    </section>
  {/if}
</main>
