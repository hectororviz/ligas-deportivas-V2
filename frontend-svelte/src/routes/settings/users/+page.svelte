<script lang="ts">
  import { onMount } from 'svelte';
  import {
    getUsers,
    createUser,
    updateUser,
    setUserPermissions,
    setUserPassword,
    deleteUser,
    listAllClubs,
    MATRIX_MODULES,
    type PaginatedUsers,
    type UserRow,
    type Club,
    type PermissionLevel,
    type MatrixModule
  } from '$lib/api';
  import Modal from '$lib/Modal.svelte';
  import { SlidersHorizontal, X } from '@lucide/svelte';

  const MODULES: Array<[string, string]> = [
    ['LIGAS', 'Ligas'],
    ['TORNEOS', 'Torneos'],
    ['ZONAS', 'Zonas'],
    ['CATEGORIAS', 'Categorías'],
    ['JUGADORES', 'Jugadores'],
    ['CLUBES', 'Clubes'],
    ['CONFIGURACION', 'Configuración'],
  ];

  const LEVELS: Array<[PermissionLevel, string]> = [
    ['TOTAL', 'Total'],
    ['MODIFICACION', 'Modificación'],
    ['LECTURA', 'Lectura'],
    ['LECTURA_CLUB', 'Lectura del club'],
    ['MODIFICACION_CLUB', 'Modificación del club'],
    ['NO', 'No'],
  ];

  let paginated = $state<PaginatedUsers | null>(null);
  let clubs = $state<Club[]>([]);
  let loading = $state(true);
  let error = $state('');
  let search = $state('');
  let debounce: ReturnType<typeof setTimeout> | null = null;
  let page = $state(1);
  let showFilters = $state(false);
  let notice = $state('');

  let showForm = $state(false);
  let editingUser = $state<UserRow | null>(null);
  let saving = $state(false);
  let formError = $state('');

  let form = $state({
    username: '',
    firstName: '',
    lastName: '',
    password: '',
    clubId: 0,
  });
  let levels = $state<Record<string, PermissionLevel>>({});

  onMount(async () => {
    await Promise.all([fetchUsers(), fetchClubs()]);
  });

  async function fetchUsers() {
    loading = true; error = '';
    try {
      paginated = await getUsers(search || undefined, page);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar los usuarios.';
    } finally { loading = false; }
  }

  async function fetchClubs() {
    try { clubs = await listAllClubs(); } catch {}
  }

  function onSearch() {
    if (debounce) clearTimeout(debounce);
    debounce = setTimeout(() => { page = 1; fetchUsers(); }, 300);
  }

  function defaultLevels(): Record<string, PermissionLevel> {
    const map: Record<string, PermissionLevel> = {};
    for (const module of MATRIX_MODULES) map[module] = 'NO';
    return map;
  }

  function openCreate() {
    editingUser = null;
    form = { username: '', firstName: '', lastName: '', password: '', clubId: 0 };
    levels = defaultLevels();
    formError = '';
    showForm = true;
  }

  function openEdit(user: UserRow) {
    editingUser = user;
    form = {
      username: user.username,
      firstName: user.firstName,
      lastName: user.lastName,
      password: '',
      clubId: user.club?.id ?? 0,
    };
    levels = { ...defaultLevels(), ...user.moduleLevels };
    formError = '';
    showForm = true;
  }

  function closeForm() {
    showForm = false;
    editingUser = null;
    formError = '';
  }

  function permissionsPayload(): { module: MatrixModule; level: PermissionLevel }[] {
    return MATRIX_MODULES.map((module) => ({ module, level: levels[module] ?? 'NO' }));
  }

  function levelLabel(level: PermissionLevel): string {
    return LEVELS.find(([value]) => value === level)?.[1] ?? 'No';
  }

  async function saveUser() {
    formError = '';
    error = '';
    notice = '';

    if (editingUser) {
      if (editingUser.isAdmin) {
        if (form.password && form.password.length < 8) {
          formError = 'La contraseña debe tener al menos 8 caracteres.';
          return;
        }
        saving = true;
        try {
          if (form.password) await setUserPassword(editingUser.id, form.password);
          notice = 'Contraseña actualizada.';
          closeForm();
          await fetchUsers();
        } catch (cause) {
          formError = cause instanceof Error ? cause.message : 'No se pudo actualizar el usuario.';
        } finally { saving = false; }
        return;
      }

      if (!form.firstName.trim() || !form.lastName.trim()) {
        formError = 'Ingresá nombre y apellido.';
        return;
      }
      saving = true;
      try {
        await updateUser(editingUser.id, {
          firstName: form.firstName.trim(),
          lastName: form.lastName.trim(),
          clubId: form.clubId || null,
        });
        await setUserPermissions(editingUser.id, permissionsPayload());
        if (form.password) await setUserPassword(editingUser.id, form.password);
        notice = 'Usuario actualizado correctamente.';
        closeForm();
        await fetchUsers();
      } catch (cause) {
        formError = cause instanceof Error ? cause.message : 'No se pudo actualizar el usuario.';
      } finally { saving = false; }
      return;
    }

    if (!form.username.trim()) { formError = 'Ingresá un nombre de usuario.'; return; }
    if (!form.firstName.trim() || !form.lastName.trim()) {
      formError = 'Ingresá nombre y apellido.';
      return;
    }
    if (!form.password || form.password.length < 8) {
      formError = 'La contraseña debe tener al menos 8 caracteres.';
      return;
    }

    saving = true;
    try {
      await createUser({
        username: form.username.trim(),
        password: form.password,
        firstName: form.firstName.trim(),
        lastName: form.lastName.trim(),
        clubId: form.clubId || null,
        permissions: permissionsPayload(),
      });
      notice = 'Usuario creado correctamente.';
      closeForm();
      await fetchUsers();
    } catch (cause) {
      formError = cause instanceof Error ? cause.message : 'No se pudo crear el usuario.';
    } finally { saving = false; }
  }

  async function handleDelete(user: UserRow) {
    if (!window.confirm(`¿Eliminar al usuario "${user.username}"?`)) return;
    error = '';
    notice = '';
    try {
      await deleteUser(user.id);
      notice = 'Usuario eliminado.';
      if (editingUser?.id === user.id) closeForm();
      await fetchUsers();
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo eliminar el usuario.';
    }
  }

  function activeLevels(user: UserRow): Array<[string, PermissionLevel]> {
    return MATRIX_MODULES
      .map((module) => [module, user.moduleLevels?.[module] ?? 'NO'] as [string, PermissionLevel])
      .filter(([, level]) => level !== 'NO');
  }
</script>

<svelte:head><title>Usuarios y permisos | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div>
      <p class="eyebrow">Configuración</p>
      <h1>Usuarios y permisos</h1>
      <p class="muted">Gestiona los usuarios registrados, su club y los permisos asignados.</p>
    </div>
    <button class="button primary" onclick={openCreate}>Nuevo usuario</button>
  </header>

  {#if loading && !paginated}
    <section class="loading-card">Cargando usuarios...</section>
  {:else}
    {#if error}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}

    <section class="card-surface">
      <div class="filter-bar">
        <button class="button secondary" onclick={() => showFilters = !showFilters} aria-label="Filtros">
          <SlidersHorizontal size={16} strokeWidth={2} />
          {showFilters ? 'Ocultar filtros' : 'Filtros'}
        </button>
        <span class="count-pill">{paginated?.total ?? 0}</span>
      </div>
      {#if showFilters}
        <div class="filter-row">
          <input type="text" bind:value={search} oninput={onSearch} placeholder="Buscar por usuario o nombre..." />
        </div>
      {/if}

      {#if paginated && paginated.data.length === 0}
        <div class="empty-state compact-empty"><h2>Sin usuarios</h2><p>No se encontraron usuarios con ese criterio.</p></div>
      {:else if paginated}
        <div class="user-table">
          {#each paginated.data as user}
            <!-- svelte-ignore a11y_click_events_have_key_events -->
            <!-- svelte-ignore a11y_no_static_element_interactions -->
            <article class="user-row" onclick={() => openEdit(user)}>
              <div class="user-avatar">{user.firstName.slice(0, 1)}{user.lastName.slice(0, 1)}</div>
              <div class="user-info">
                <div class="user-name-row">
                  <strong>{user.firstName} {user.lastName}</strong>
                  {#if user.isAdmin}<span class="tag tag-red">Admin</span>{/if}
                </div>
                <span>@{user.username}{user.club ? ` · ${user.club.name}` : ''}</span>
                <div class="tag-list">
                  {#if activeLevels(user).length === 0}
                    <span class="tag tag-muted">Sin permisos</span>
                  {:else}
                    {#each activeLevels(user) as [module, level]}
                      <span class="tag tag-blue">{MODULES.find(([m]) => m === module)?.[1] ?? module}: {levelLabel(level)}</span>
                    {/each}
                  {/if}
                </div>
              </div>
            </article>
          {/each}
        </div>
        {#if paginated.total > (paginated.pageSize || 20)}
          <div class="pagination">
            <span>{paginated.total} usuarios</span>
            <div>
              <button class="button secondary" disabled={page <= 1} onclick={() => { page = Math.max(1, page - 1); fetchUsers(); }}>Anterior</button>
              <button class="button secondary" disabled={page * (paginated.pageSize || 20) >= paginated.total} onclick={() => { page++; fetchUsers(); }}>Siguiente</button>
            </div>
          </div>
        {/if}
      {/if}
    </section>
  {/if}

  {#if showForm}
    <Modal onclose={closeForm}>
      <div class="user-form">
        <div class="user-form-head">
          <h2>{editingUser ? `Editar ${editingUser.username}` : 'Nuevo usuario'}</h2>
          {#if editingUser && !editingUser.isAdmin}
            <button class="button secondary small danger" onclick={() => handleDelete(editingUser!)}>Eliminar</button>
          {/if}
        </div>

        {#if formError}<p class="error-banner">{formError}</p>{/if}

        <div class="form-grid">
          <label>
            Usuario
            <input type="text" bind:value={form.username} disabled={!!editingUser} placeholder="juan.perez" />
          </label>
          <label>
            Nombre
            <input type="text" bind:value={form.firstName} disabled={editingUser?.isAdmin} placeholder="Juan" />
          </label>
          <label>
            Apellido
            <input type="text" bind:value={form.lastName} disabled={editingUser?.isAdmin} placeholder="Pérez" />
          </label>
          <label>
            Contraseña
            <input type="password" bind:value={form.password} placeholder={editingUser ? 'Dejar en blanco para no cambiar' : 'Mínimo 8 caracteres'} />
          </label>
          <label>
            Club
            <select bind:value={form.clubId} disabled={editingUser?.isAdmin}>
              <option value={0}>Sin club</option>
              {#each clubs as club}
                <option value={club.id}>{club.name}</option>
              {/each}
            </select>
          </label>
        </div>

        {#if !editingUser?.isAdmin}
          <div class="matrix">
            <div class="matrix-head">
              <span>Módulo</span><span>Permiso</span>
            </div>
            {#each MODULES as [module, label]}
              <div class="matrix-row">
                <span>{label}</span>
                <select bind:value={levels[module]}>
                  {#each LEVELS as [value, levelLabel]}
                    <option value={value}>{levelLabel}</option>
                  {/each}
                </select>
              </div>
            {/each}
          </div>
        {:else}
          <p class="muted">El administrador tiene acceso total. Solo podés modificar su contraseña.</p>
        {/if}

        <div class="form-actions">
          <button class="button secondary" onclick={closeForm} disabled={saving}>Cancelar</button>
          <button class="button primary" onclick={saveUser} disabled={saving}>{saving ? 'Guardando...' : 'Guardar'}</button>
        </div>
      </div>
    </Modal>
  {/if}
</main>

<style>
  .user-table { margin-top: .5rem; }
  .user-row {
    display: flex; align-items: flex-start; gap: .8rem;
    padding: 1rem .75rem; border-top: 1px solid var(--color-border);
    cursor: pointer; border-radius: .6rem;
    transition: background 150ms ease;
  }
  .user-row:first-child { margin-top: 0; }
  .user-row:hover { background: var(--color-surface-hover); }
  .user-avatar {
    width: 2.5rem; height: 2.5rem; display: grid; place-items: center; flex: 0 0 auto;
    border-radius: .75rem; color: var(--color-accent-text); background: var(--color-accent-bg);
    font-family: 'Space Grotesk', sans-serif; font-weight: 700; font-size: .85rem;
  }
  .user-info { display: grid; gap: .2rem; min-width: 0; }
  .user-name-row { display: flex; align-items: center; gap: .5rem; }
  .user-name-row strong { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

  .user-form { display: grid; gap: 1rem; }
  .user-form h2 { font-family: 'Space Grotesk', sans-serif; font-size: 1.15rem; margin: 0; }
  .user-form-head { display: flex; align-items: center; justify-content: space-between; gap: 1rem; }

  .form-grid {
    display: grid; grid-template-columns: 1fr 1fr; gap: .7rem;
  }
  .form-grid label { display: grid; gap: .3rem; font-size: .8rem; color: var(--color-text-muted); }
  .form-grid input, .form-grid select {
    padding: .55rem .6rem; border: 1px solid var(--color-input-border); border-radius: .5rem;
    background: var(--color-input); color: var(--color-text); font-family: inherit; font-size: .88rem;
  }
  .form-grid input:focus, .form-grid select:focus { outline: none; border-color: var(--color-input-focus); }

  .matrix { border: 1px solid var(--color-border); border-radius: .6rem; overflow: hidden; }
  .matrix-head, .matrix-row {
    display: grid; grid-template-columns: 1fr 1fr; align-items: center;
  }
  .matrix-head {
    padding: .5rem .7rem; font-size: .7rem; text-transform: uppercase; letter-spacing: .04em;
    color: var(--color-text-muted); background: var(--color-surface-hover); font-weight: 700;
  }
  .matrix-row { padding: .3rem .7rem; border-top: 1px solid var(--color-border); }
  .matrix-row span { font-size: .84rem; }
  .matrix-row select {
    padding: .4rem .5rem; border: 1px solid var(--color-input-border); border-radius: .45rem;
    background: var(--color-input); color: var(--color-text); font-family: inherit; font-size: .82rem;
  }

  .form-actions { display: flex; justify-content: flex-end; gap: .6rem; }
  .button.small { padding: .3rem .6rem; font-size: .75rem; }
  .button.danger { color: var(--color-error); }

  @media (max-width: 640px) {
    .form-grid { grid-template-columns: 1fr; }
  }
</style>
