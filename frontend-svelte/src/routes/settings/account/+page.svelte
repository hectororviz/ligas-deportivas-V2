<script lang="ts">
  import { onMount } from 'svelte';
  import { getProfile, updateProfile, changePassword, type AuthUser } from '$lib/api';

  let user: AuthUser | null = null;
  let loading = true;
  let saving = false;
  let error = '';
  let notice = '';

  let firstName = '';
  let lastName = '';
  let currentPassword = '';
  let newPassword = '';

  onMount(async () => {
    try {
      user = await getProfile();
      firstName = user.firstName;
      lastName = user.lastName;
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo cargar el perfil.';
    } finally {
      loading = false;
    }
  });

  async function saveProfile() {
    error = '';
    notice = '';
    if (!firstName.trim()) { error = 'Ingresa tu nombre.'; return; }
    if (!lastName.trim()) { error = 'Ingresa tu apellido.'; return; }
    saving = true;
    try {
      const updated = await updateProfile({ firstName: firstName.trim(), lastName: lastName.trim() });
      user = updated;
      notice = 'Perfil actualizado correctamente.';
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo actualizar el perfil.';
    } finally {
      saving = false;
    }
  }

  async function savePassword() {
    error = '';
    notice = '';
    if (!currentPassword) { error = 'Ingresa tu contraseña actual.'; return; }
    if (!newPassword || newPassword.length < 8) { error = 'La nueva contraseña debe tener al menos 8 caracteres.'; return; }
    saving = true;
    try {
      await changePassword({ currentPassword, newPassword });
      notice = 'Contraseña actualizada correctamente.';
      currentPassword = '';
      newPassword = '';
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo cambiar la contraseña.';
    } finally {
      saving = false;
    }
  }
</script>

<svelte:head><title>Cuenta | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div>
      <p class="eyebrow">Configuración</p>
      <h1>Cuenta y perfil</h1>
      <p class="muted">Actualiza tu información personal y cambia tu contraseña.</p>
    </div>
    <a class="button secondary" href="/settings">Volver a ajustes</a>
  </header>

  {#if loading}
    <section class="loading-card">Cargando perfil...</section>
  {:else}
    {#if error}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}

    <div class="leagues-layout">
      <section class="card-surface">
        <div class="list-header">
          <div><p class="eyebrow">Perfil</p><h2>Información personal</h2></div>
        </div>
        <form onsubmit={(event) => { event.preventDefault(); saveProfile(); }}>
          <div class="form-row">
            <label>Nombre<input bind:value={firstName} placeholder="Tu nombre" disabled={saving} /></label>
            <label>Apellido<input bind:value={lastName} placeholder="Tu apellido" disabled={saving} /></label>
          </div>
          <label>Correo electrónico<input value={user?.email ?? ''} disabled style="opacity:.65;" /></label>
          <div class="form-actions">
            <button class="button primary" type="submit" disabled={saving}>{saving ? 'Guardando...' : 'Guardar cambios'}</button>
          </div>
        </form>
      </section>

      <section class="card-surface">
        <div class="list-header">
          <div><p class="eyebrow">Seguridad</p><h2>Cambiar contraseña</h2></div>
        </div>
        <form onsubmit={(event) => { event.preventDefault(); savePassword(); }}>
          <label>Contraseña actual<input type="password" bind:value={currentPassword} autocomplete="current-password" placeholder="Tu contraseña actual" disabled={saving} /></label>
          <label>Nueva contraseña<input type="password" bind:value={newPassword} autocomplete="new-password" placeholder="Mínimo 8 caracteres" disabled={saving} /></label>
          <div class="form-actions">
            <button class="button primary" type="submit" disabled={saving}>{saving ? 'Cambiando...' : 'Cambiar contraseña'}</button>
          </div>
        </form>
      </section>
    </div>
  {/if}
</main>
