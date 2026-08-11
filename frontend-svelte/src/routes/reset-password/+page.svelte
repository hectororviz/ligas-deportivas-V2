<script lang="ts">
  import { page } from '$app/stores';
  import { requestPasswordReset, resetPassword } from '$lib/api';

  let hasToken = $state(false);
  let token = $state('');

  let email = $state('');
  let password = $state('');
  let confirm = $state('');
  let loading = $state(false);
  let error = $state('');
  let success = $state('');

  $effect(() => {
    const t = $page.url.searchParams.get('token');
    if (t) {
      hasToken = true;
      token = t;
    }
  });

  async function submitRequest() {
    error = '';
    success = '';
    if (!email.trim() || !email.includes('@')) {
      error = 'Ingresa un correo válido.';
      return;
    }
    loading = true;
    try {
      await requestPasswordReset(email.trim());
      success = 'Si el correo está registrado, recibirás un enlace para restablecer tu contraseña.';
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo enviar la solicitud.';
    } finally {
      loading = false;
    }
  }

  async function submitReset() {
    error = '';
    success = '';
    if (password.length < 8) {
      error = 'La contraseña debe tener al menos 8 caracteres.';
      return;
    }
    if (!/[A-Z]/.test(password)) {
      error = 'La contraseña debe incluir al menos una mayúscula.';
      return;
    }
    if (!/[a-z]/.test(password)) {
      error = 'La contraseña debe incluir al menos una minúscula.';
      return;
    }
    if (!/[0-9]/.test(password)) {
      error = 'La contraseña debe incluir al menos un dígito.';
      return;
    }
    if (password !== confirm) {
      error = 'Las contraseñas no coinciden.';
      return;
    }
    loading = true;
    try {
      await resetPassword(token, password);
      success = 'Contraseña restablecida correctamente. Ya podés iniciar sesión.';
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo restablecer la contraseña.';
    } finally {
      loading = false;
    }
  }
</script>

<svelte:head>
  <title>Recuperar contraseña | Ligas Deportivas</title>
</svelte:head>

<main class="auth-shell">
  <div class="auth-card">
    <div class="brand-mark">LD</div>

    {#if hasToken}
      <h2 class="auth-title">Nueva contraseña</h2>
      <p class="muted">Elegí una nueva contraseña para tu cuenta.</p>

      <form onsubmit={(event) => { event.preventDefault(); submitReset(); }}>
        <label>
          Nueva contraseña
          <input type="password" bind:value={password} autocomplete="new-password" placeholder="Al menos 8 caracteres" disabled={loading} />
          <span class="muted hint">Debe incluir mayúscula, minúscula y un dígito.</span>
        </label>
        <label>
          Confirmar contraseña
          <input type="password" bind:value={confirm} autocomplete="new-password" placeholder="Repetí la contraseña" disabled={loading} />
        </label>

        {#if error}
          <p class="form-error" role="alert">{error}</p>
        {/if}
        {#if success}
          <div class="success-banner">{success}</div>
        {/if}

        <button class="button primary" type="submit" disabled={loading}>
          {loading ? 'Restableciendo...' : 'Restablecer contraseña'}
        </button>
      </form>

      {#if success}
        <a href="/login" class="button primary auth-button">Iniciar sesión</a>
      {/if}
    {:else}
      <h2 class="auth-title">Recuperar contraseña</h2>
      <p class="muted">Ingresá tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.</p>

      <form onsubmit={(event) => { event.preventDefault(); submitRequest(); }}>
        <label>
          Correo electrónico
          <input type="email" bind:value={email} autocomplete="email" placeholder="juan@ejemplo.com" disabled={loading} />
        </label>

        {#if error}
          <p class="form-error" role="alert">{error}</p>
        {/if}
        {#if success}
          <div class="success-banner">{success}</div>
        {/if}

        <button class="button primary" type="submit" disabled={loading}>
          {loading ? 'Enviando...' : 'Enviar enlace'}
        </button>
      </form>
    {/if}

    <p class="form-footer">
      <a href="/login">Volver al inicio de sesión</a>
    </p>
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

  .hint {
    font-size: .76rem;
    margin-top: .15rem;
    text-align: left;
  }

  .success-banner {
    margin: 1.2rem 0;
    text-align: left;
  }

  form {
    margin-top: 1.5rem;
    text-align: left;
  }

  .form-footer {
    margin: 1.5rem 0 0;
    font-size: .88rem;
  }

  .form-footer a {
    color: var(--color-accent-text);
    font-weight: 600;
    text-decoration: none;
  }

  .form-footer a:hover {
    text-decoration: underline;
  }

  .auth-button {
    display: inline-flex;
    margin-top: .5rem;
    text-decoration: none;
  }
</style>
