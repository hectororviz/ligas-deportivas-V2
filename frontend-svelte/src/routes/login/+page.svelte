<script lang="ts">
  import { goto } from '$app/navigation';
  import { login } from '$lib/api';

  let email = '';
  let password = '';
  let loading = false;
  let error = '';

  async function submit() {
    error = '';
    if (!email.trim() || !email.includes('@')) {
      error = 'Ingresa un correo válido.';
      return;
    }
    if (password.length < 8) {
      error = 'La contraseña debe tener al menos 8 caracteres.';
      return;
    }

    loading = true;
    try {
      await login(email.trim(), password);
      await goto('/');
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'Credenciales inválidas.';
    } finally {
      loading = false;
    }
  }
</script>

<main class="login-shell">
  <section class="login-aside">
    <div class="brand-mark">LD</div>
    <p class="eyebrow">Gestión deportiva</p>
    <h1>Todo el torneo, en una sola cancha.</h1>
    <p>Una interfaz más ligera para administrar ligas, clubes, partidos y resultados desde cualquier dispositivo.</p>
  </section>

  <section class="login-panel">
    <div class="login-card">
      <p class="eyebrow">Bienvenido</p>
      <h2>Iniciar sesión</h2>
      <p class="muted">Ingresa con las credenciales de tu cuenta.</p>

      <form onsubmit={(event) => { event.preventDefault(); submit(); }}>
        <label>
          Correo electrónico
          <input type="email" bind:value={email} autocomplete="email" placeholder="admin@ligas.local" disabled={loading} />
        </label>
        <label>
          Contraseña
          <input type="password" bind:value={password} autocomplete="current-password" placeholder="Tu contraseña" disabled={loading} />
        </label>

        {#if error}
          <p class="form-error" role="alert">{error}</p>
        {/if}

        <button class="button primary" type="submit" disabled={loading}>
          {loading ? 'Ingresando...' : 'Ingresar'}
        </button>
      </form>
    </div>
  </section>
</main>
