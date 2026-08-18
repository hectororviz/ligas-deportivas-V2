<script lang="ts">
  import { onMount } from 'svelte';
  import Modal from './Modal.svelte';
  import { loginModalState } from './login-modal.svelte';
  import { login, getSiteIdentity, type SiteIdentity } from './api';

  let username = $state('');
  let password = $state('');
  let loading = $state(false);
  let error = $state('');
  let identity = $state<SiteIdentity | null>(null);
  let usernameInput = $state<HTMLInputElement>();

  onMount(() => {
    getSiteIdentity().then((value) => (identity = value)).catch(() => {});
  });

  $effect(() => {
    if (loginModalState.open) usernameInput?.focus();
  });

  let iconUrl = $derived(identity?.iconUrl ?? null);
  let title = $derived(identity?.title ?? 'Ligas Deportivas');

  function handleClose() {
    if (loading) return;
    loginModalState.close();
    username = '';
    password = '';
    error = '';
  }

  async function submit() {
    error = '';
    if (!username.trim()) {
      error = 'Ingresa tu nombre de usuario.';
      return;
    }
    if (password.length < 8) {
      error = 'La contraseña debe tener al menos 8 caracteres.';
      return;
    }

    loading = true;
    try {
      await login(username.trim(), password);
      loginModalState.close();
      window.location.reload();
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'Credenciales inválidas.';
    } finally {
      loading = false;
    }
  }
</script>

{#if loginModalState.open}
  <Modal onclose={handleClose}>
    <div class="login-modal">
      <div class="brand-row">
        {#if iconUrl}
          <img class="brand-logo" src={iconUrl} alt={title} />
        {:else}
          <span class="brand-mark">LD</span>
        {/if}
        <div class="brand-text">
          <p class="eyebrow">{title}</p>
          <h2>Iniciar sesión</h2>
        </div>
      </div>

      <p class="muted">Ingresa con las credenciales de tu cuenta.</p>

      <form onsubmit={(event) => { event.preventDefault(); submit(); }}>
        <label>
          Usuario
          <input type="text" bind:value={username} bind:this={usernameInput} autocomplete="username" placeholder="admin" disabled={loading} />
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
  </Modal>
{/if}

<style>
  .brand-row {
    display: flex;
    align-items: center;
    gap: .85rem;
    margin-bottom: 1rem;
  }
  .brand-mark,
  .brand-logo {
    width: 3rem;
    height: 3rem;
    border-radius: .8rem;
    flex-shrink: 0;
  }
  .brand-mark {
    display: grid;
    place-items: center;
    color: var(--color-hero);
    background: var(--color-hero-accent);
    font-family: 'Space Grotesk', sans-serif;
    font-size: 1rem;
    font-weight: 700;
  }
  .brand-logo {
    object-fit: contain;
    border: 1px solid var(--color-border);
    background: var(--color-surface);
  }
  .brand-text .eyebrow {
    margin-bottom: .2rem;
  }
  .brand-text h2 {
    margin: 0;
    font-family: 'Space Grotesk', sans-serif;
    font-size: 1.5rem;
    letter-spacing: -.04em;
  }
</style>
