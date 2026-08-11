<script lang="ts">
  import { goto } from '$app/navigation';
  import { register } from '$lib/api';

  let firstName = $state('');
  let lastName = $state('');
  let email = $state('');
  let password = $state('');
  let loading = $state(false);
  let error = $state('');

  function validate(): string {
    if (!firstName.trim()) return 'Ingresa tu nombre.';
    if (!lastName.trim()) return 'Ingresa tu apellido.';
    if (!email.trim() || !email.includes('@')) return 'Ingresa un correo válido.';
    if (password.length < 8) return 'La contraseña debe tener al menos 8 caracteres.';
    if (!/[A-Z]/.test(password)) return 'La contraseña debe incluir al menos una mayúscula.';
    if (!/[a-z]/.test(password)) return 'La contraseña debe incluir al menos una minúscula.';
    if (!/[0-9]/.test(password)) return 'La contraseña debe incluir al menos un dígito.';
    return '';
  }

  async function submit() {
    error = '';
    const validationError = validate();
    if (validationError) {
      error = validationError;
      return;
    }

    loading = true;
    try {
      await register({
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        password
      });
      await goto('/');
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'Error al registrarse.';
    } finally {
      loading = false;
    }
  }
</script>

<svelte:head>
  <title>Registro | Ligas Deportivas</title>
</svelte:head>

<main class="login-shell">
  <section class="login-aside">
    <div class="brand-mark">LD</div>
    <p class="eyebrow">Gestión deportiva</p>
    <h1>Sumate a la cancha.</h1>
    <p>Creá tu cuenta para administrar ligas, clubes, partidos y resultados desde cualquier dispositivo.</p>
  </section>

  <section class="login-panel">
    <div class="login-card">
      <p class="eyebrow">Nueva cuenta</p>
      <h2>Registrarse</h2>
      <p class="muted">Completá tus datos para crear una cuenta.</p>

      <form onsubmit={(event) => { event.preventDefault(); submit(); }}>
        <div class="form-row">
          <label>
            Nombre
            <input type="text" bind:value={firstName} autocomplete="given-name" placeholder="Juan" disabled={loading} />
          </label>
          <label>
            Apellido
            <input type="text" bind:value={lastName} autocomplete="family-name" placeholder="Pérez" disabled={loading} />
          </label>
        </div>
        <label>
          Correo electrónico
          <input type="email" bind:value={email} autocomplete="email" placeholder="juan@ejemplo.com" disabled={loading} />
        </label>
        <label>
          Contraseña
          <input type="password" bind:value={password} autocomplete="new-password" placeholder="Al menos 8 caracteres" disabled={loading} />
          <span class="muted hint">Debe incluir al menos una mayúscula, una minúscula y un dígito.</span>
        </label>

        {#if error}
          <p class="form-error" role="alert">{error}</p>
        {/if}

        <button class="button primary" type="submit" disabled={loading}>
          {loading ? 'Creando cuenta...' : 'Crear cuenta'}
        </button>
      </form>

      <p class="form-footer">
        ¿Ya tenés cuenta? <a href="/login">Iniciar sesión</a>
      </p>
    </div>
  </section>
</main>

<style>
  .hint {
    font-size: .76rem;
    margin-top: .15rem;
  }

  .form-footer {
    margin: 1.5rem 0 0;
    font-size: .88rem;
    color: var(--color-text-muted);
    text-align: center;
  }

  .form-footer a {
    color: var(--color-accent-text);
    font-weight: 600;
    text-decoration: none;
  }

  .form-footer a:hover {
    text-decoration: underline;
  }
</style>
