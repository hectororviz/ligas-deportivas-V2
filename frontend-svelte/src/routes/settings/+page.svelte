<script lang="ts">
  import { onMount } from 'svelte';
  import { getProfile, hasSession, canManageModule, type AuthUser } from '$lib/api';
  import { goto } from '$app/navigation';

  let user: AuthUser | null = null;
  let loading = true;

  onMount(async () => {
    if (!hasSession()) { await goto('/login'); return; }
    try { user = await getProfile(); } catch {} finally { loading = false; }
  });
</script>

<svelte:head><title>Configuración | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div><p class="eyebrow">Configuración</p><h1>Ajustes</h1><p class="muted">Administra tu cuenta, la identidad del sitio y la apariencia.</p></div>
  </header>

  {#if loading}
    <section class="loading-card">Cargando...</section>
  {:else if user}
    <section class="card-surface" style="display:grid; gap:.8rem;">
      <a class="league-row settings-link" href="/settings/account"><span class="league-color settings-avatar">{user.firstName.charAt(0)}{user.lastName.charAt(0)}</span><div class="league-info"><strong>Cuenta y perfil</strong><span>Actualiza tu nombre, apellido y contraseña.</span></div></a>
      {#if canManageModule(user, 'CONFIGURACION')}
        <a class="league-row settings-link" href="/settings/users"><span class="league-color settings-icon">UP</span><div class="league-info"><strong>Usuarios y permisos</strong><span>Gestiona los usuarios registrados y sus permisos asignados.</span></div></a>
        <a class="league-row settings-link" href="/settings/site-identity"><span class="league-color settings-icon">SI</span><div class="league-info"><strong>Identidad del sitio</strong><span>Cambia el título, ícono, favicon y paleta de colores.</span></div></a>
      {/if}
    </section>
  {/if}
</main>

<style>
  .settings-link { text-decoration: none; padding: 1.2rem 1rem; cursor: pointer; }
  .settings-avatar { background: var(--color-hero); color: var(--color-hero-text); }
  .settings-icon { background: var(--color-hero-accent); color: var(--color-hero); }
</style>
