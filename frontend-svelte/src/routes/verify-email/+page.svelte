<script lang="ts">
  import { page } from '$app/stores';
  import { verifyEmail } from '$lib/api';

  let status = $state<'loading' | 'success' | 'error'>('loading');
  let errorMessage = $state('');

  let token = $state('');
  $effect(() => {
    const t = $page.url.searchParams.get('token');
    if (t) {
      token = t;
      verifyEmail(token)
        .then(() => status = 'success')
        .catch((cause) => {
          status = 'error';
          errorMessage = cause instanceof Error ? cause.message : 'No se pudo verificar el correo.';
        });
    } else {
      status = 'error';
      errorMessage = 'No se encontró el token de verificación en la URL.';
    }
  });
</script>

<svelte:head>
  <title>Verificar correo | Ligas Deportivas</title>
</svelte:head>

<main class="auth-shell">
  <div class="auth-card">
    <div class="brand-mark">LD</div>

    {#if status === 'loading'}
      <h2 class="auth-title">Verificando tu correo...</h2>
      <p class="muted">Esperá un momento mientras confirmamos tu dirección de correo.</p>
    {:else if status === 'success'}
      <h2 class="auth-title">¡Correo verificado!</h2>
      <p class="muted">Tu dirección de correo fue verificada correctamente. Ahora podés iniciar sesión.</p>
      <div class="success-banner">Verificación completada con éxito.</div>
      <a href="/login" class="button primary auth-button">Iniciar sesión</a>
    {:else}
      <h2 class="auth-title">Error de verificación</h2>
      <p class="muted">No se pudo verificar tu correo electrónico.</p>
      <div class="error-banner">{errorMessage}</div>
      <a href="/login" class="button primary auth-button">Ir al inicio de sesión</a>
    {/if}
  </div>
</main>

<style>
  .auth-shell {
    min-height: 100vh;
    display: grid;
    place-items: center;
    padding: 2rem;
  }

  .auth-card {
    width: min(100%, 440px);
    padding: clamp(1.5rem, 4vw, 3rem);
    border: 1px solid var(--color-border);
    border-radius: 1.5rem;
    background: var(--color-surface);
    box-shadow: 0 24px 70px var(--color-shadow);
    text-align: center;
  }

  .brand-mark {
    width: 3.5rem;
    height: 3.5rem;
    display: grid;
    place-items: center;
    border-radius: 1rem;
    margin: 0 auto 1.5rem;
    color: var(--color-hero);
    background: var(--color-hero-accent);
    font-family: 'Space Grotesk', sans-serif;
    font-size: 1.1rem;
    font-weight: 700;
  }

  .auth-title {
    margin: .5rem 0 .5rem;
    font-family: 'Space Grotesk', sans-serif;
    font-size: 1.8rem;
    letter-spacing: -.04em;
    color: var(--color-heading);
  }

  .success-banner,
  .error-banner {
    margin: 1.2rem 0;
    text-align: left;
  }

  .auth-button {
    display: inline-flex;
    margin-top: .5rem;
    text-decoration: none;
  }
</style>
