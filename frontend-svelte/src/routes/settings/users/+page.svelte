<script lang="ts">
  import { onMount } from 'svelte';
  import { getUsers, getRoles, assignRole, removeRole, type PaginatedUsers, type UserRow, type RoleData } from '$lib/api';
  import Modal from '$lib/Modal.svelte';

  let paginated: PaginatedUsers | null = null;
  let loading = true;
  let error = '';
  let search = '';
  let debounce: ReturnType<typeof setTimeout> | null = null;
  let page = 1;
  let showFilters = $state(false);
  let notice = $state('');

  let availableRoles: RoleData[] = [];
  let selectedUser = $state<UserRow | null>(null);
  let selectedRoleKey = $state('');
  let roleLoading = $state(false);

  onMount(async () => {
    await Promise.all([fetchUsers(), fetchRoles()]);
  });

  async function fetchUsers() {
    loading = true; error = '';
    try {
      paginated = await getUsers(search || undefined, page);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar los usuarios.';
    } finally { loading = false; }
  }

  async function fetchRoles() {
    try { availableRoles = await getRoles(); } catch {}
  }

  function onSearch() {
    if (debounce) clearTimeout(debounce);
    debounce = setTimeout(() => { page = 1; fetchUsers(); }, 300);
  }

  function roleTagClass(key: string) {
    const map: Record<string, string> = {
      ADMIN: 'tag-red',
      LEAGUE_ADMIN: 'tag-purple',
      CLUB_ADMIN: 'tag-blue',
      REFEREE: 'tag-green',
      COLLABORATOR: 'tag-purple',
      DELEGATE: 'tag-blue',
      COACH: 'tag-green',
      USER: 'tag-amber',
    };
    return map[key] ?? 'tag-amber';
  }

  function roleLabel(role: { role: { key: string; name: string }; league?: { name: string } | null; club?: { name: string } | null }) {
    let label = role.role.name;
    if (role.league) label += ` · ${role.league.name}`;
    if (role.club) label += ` · ${role.club.name}`;
    return label;
  }

  function formatVerified(verified: string | null | undefined) {
    if (!verified) return '';
    return new Date(verified).toLocaleDateString('es-AR', { day: '2-digit', month: '2-digit', year: 'numeric' });
  }

  function openRoleManager(user: UserRow) {
    selectedUser = user;
    selectedRoleKey = '';
  }

  function closeRoleManager() {
    selectedUser = null;
    selectedRoleKey = '';
  }

  async function handleAssignRole() {
    if (!selectedUser || !selectedRoleKey) return;
    roleLoading = true; error = ''; notice = '';
    try {
      await assignRole(selectedUser.id, { roleKey: selectedRoleKey });
      notice = 'Rol asignado correctamente.';
      selectedRoleKey = '';
      const updated = await getUsers(search || undefined, page);
      paginated = updated;
      if (updated) {
        const refreshed = updated.data.find((u) => u.id === selectedUser!.id);
        if (refreshed) selectedUser = refreshed;
      }
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo asignar el rol.';
    } finally {
      roleLoading = false;
      setTimeout(() => notice = '', 2500);
    }
  }

  async function handleRemoveRole(assignmentId: number) {
    roleLoading = true; error = ''; notice = '';
    try {
      await removeRole(assignmentId);
      notice = 'Rol removido correctamente.';
      const updated = await getUsers(search || undefined, page);
      paginated = updated;
      if (updated && selectedUser) {
        const user = selectedUser;
        const refreshed = updated.data.find((u) => u.id === user.id);
        if (refreshed) selectedUser = refreshed;
      }
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo remover el rol.';
    } finally {
      roleLoading = false;
      setTimeout(() => notice = '', 2500);
    }
  }

  function unassignedRoles(user: UserRow): RoleData[] {
    const assignedKeys = new Set(user.roles.map((r) => r.role.key));
    return availableRoles.filter((r) => !assignedKeys.has(r.key));
  }
</script>

<svelte:head><title>Usuarios y permisos | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div><p class="eyebrow">Configuración</p><h1>Usuarios y permisos</h1><p class="muted">Gestiona los usuarios registrados, sus roles y permisos asignados.</p></div>
  </header>

  {#if loading && !paginated}
    <section class="loading-card">Cargando usuarios...</section>
  {:else}
    {#if error}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}

    <section class="card-surface">
      <div class="filter-bar">
        <button class="button secondary" onclick={() => showFilters = !showFilters} aria-label="Filtros">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="4" y1="21" x2="4" y2="14"/><line x1="4" y1="10" x2="4" y2="3"/><line x1="12" y1="21" x2="12" y2="12"/><line x1="12" y1="8" x2="12" y2="3"/><line x1="20" y1="21" x2="20" y2="16"/><line x1="20" y1="12" x2="20" y2="3"/><line x1="1" y1="14" x2="7" y2="14"/><line x1="9" y1="8" x2="15" y2="8"/><line x1="17" y1="16" x2="23" y2="16"/></svg>
          {showFilters ? 'Ocultar filtros' : 'Filtros'}
        </button>
        <span class="count-pill">{paginated?.total ?? 0}</span>
      </div>
      {#if showFilters}
        <div class="filter-row">
          <input type="text" bind:value={search} oninput={onSearch} placeholder="Buscar por nombre o email..." />
        </div>
      {/if}

      {#if paginated && paginated.data.length === 0}
        <div class="empty-state compact-empty"><h2>Sin usuarios</h2><p>No se encontraron usuarios con ese criterio.</p></div>
      {:else if paginated}
        <div class="user-table">
          {#each paginated.data as user}
            <!-- svelte-ignore a11y_click_events_have_key_events -->
            <!-- svelte-ignore a11y_no_static_element_interactions -->
            <article class="user-row" class:selected={selectedUser?.id === user.id} onclick={() => openRoleManager(user)}>
              <div class="user-avatar">{user.firstName.slice(0, 1)}{user.lastName.slice(0, 1)}</div>
              <div class="user-info">
                <div class="user-name-row">
                  <strong>{user.firstName} {user.lastName}</strong>
                  {#if user.emailVerifiedAt}<span class="verified-badge" title="Verificado el {formatVerified(user.emailVerifiedAt)}">Verificado</span>{/if}
                </div>
                <span>{user.email}</span>
                <div class="tag-list">
                  {#each user.roles as r}
                    <span class="tag {roleTagClass(r.role.key)}">{roleLabel(r)}</span>
                  {/each}
                </div>
              </div>
            </article>
          {/each}
        </div>
        {#if paginated.total > (paginated.pageSize || 25)}
          <div class="pagination">
            <span>{paginated.total} usuarios</span>
            <div>
              <button class="button secondary" disabled={page <= 1} onclick={() => { page = Math.max(1, page - 1); fetchUsers(); }}>Anterior</button>
              <button class="button secondary" disabled={page * (paginated.pageSize || 25) >= paginated.total} onclick={() => { page++; fetchUsers(); }}>Siguiente</button>
            </div>
          </div>
        {/if}
      {/if}
    </section>
  {/if}

  {#if selectedUser}
    <Modal onclose={closeRoleManager}>
      <div class="role-manager">
        <h2>Roles de {selectedUser.firstName} {selectedUser.lastName}</h2>
        <p class="muted">{selectedUser.email}</p>

        {#if error}<p class="error-banner">{error}</p>{/if}
        {#if notice}<p class="success-banner">{notice}</p>{/if}

        <div class="role-section">
          <h3>Roles asignados</h3>
          {#if selectedUser.roles.length === 0}
            <p class="muted">No tiene roles asignados.</p>
          {:else}
            <div class="assigned-roles">
              {#each selectedUser.roles as r}
                <div class="role-item">
                  <div>
                    <span class="tag {roleTagClass(r.role.key)}">{roleLabel(r)}</span>
                  </div>
                  <button class="button secondary small" disabled={roleLoading} onclick={() => handleRemoveRole(r.id)}>
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" x2="6" y1="6" y2="18"/><line x1="6" x2="18" y1="6" y2="18"/></svg>
                    Remover
                  </button>
                </div>
              {/each}
            </div>
          {/if}
        </div>

        {#if unassignedRoles(selectedUser).length > 0}
          <div class="role-section">
            <h3>Asignar nuevo rol</h3>
            <div class="assign-row">
              <select class="role-select" bind:value={selectedRoleKey} disabled={roleLoading}>
                <option value="">Seleccionar rol...</option>
                {#each unassignedRoles(selectedUser) as role}
                  <option value={role.key}>{role.name}</option>
                {/each}
              </select>
              <button class="button primary" disabled={!selectedRoleKey || roleLoading} onclick={handleAssignRole}>
                {roleLoading ? 'Asignando...' : 'Asignar'}
              </button>
            </div>
          </div>
        {:else if availableRoles.length > 0}
          <p class="muted">El usuario ya tiene todos los roles disponibles.</p>
        {/if}
      </div>
    </Modal>
  {/if}
</main>

<style>
  .user-table { margin-top: .5rem; }
  .user-row {
    display: flex; align-items: flex-start; gap: .8rem;
    padding: 1rem 0; border-top: 1px solid var(--color-border);
    cursor: pointer; border-radius: .6rem; padding: 1rem .75rem;
    transition: background 150ms ease;
  }
  .user-row:first-child { margin-top: 0; }
  .user-row:hover { background: var(--color-surface-hover); }
  .user-row.selected { background: var(--color-accent-bg); }
  .user-avatar {
    width: 2.5rem; height: 2.5rem; display: grid; place-items: center; flex: 0 0 auto;
    border-radius: .75rem; color: var(--color-accent-text); background: var(--color-accent-bg);
    font-family: 'Space Grotesk', sans-serif; font-weight: 700; font-size: .85rem;
  }
  .user-info { display: grid; gap: .2rem; min-width: 0; }
  .user-name-row { display: flex; align-items: center; gap: .5rem; }
  .user-name-row strong { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .verified-badge {
    padding: .15rem .5rem; border-radius: 999px; color: var(--color-success);
    background: var(--color-success-bg); font-size: .68rem; font-weight: 700; white-space: nowrap;
  }

  .role-manager { display: grid; gap: 1rem; }
  .role-manager h2 { font-family: 'Space Grotesk', sans-serif; font-size: 1.15rem; margin: 0; }
  .role-manager h3 { font-family: 'Space Grotesk', sans-serif; font-size: .9rem; margin: 0 0 .5rem; }
  .role-section { display: grid; gap: .5rem; }

  .assigned-roles { display: grid; gap: .4rem; }
  .role-item {
    display: flex; align-items: center; justify-content: space-between; gap: .5rem;
    padding: .5rem .6rem; border: 1px solid var(--color-border); border-radius: .5rem;
    background: var(--color-input);
  }
  .role-item .tag { font-size: .78rem; }

  .assign-row { display: flex; gap: .5rem; align-items: center; }
  .role-select {
    flex: 1; padding: .5rem .6rem;
    border: 1px solid var(--color-input-border); border-radius: .5rem;
    background: var(--color-input); color: var(--color-text);
    font-size: .82rem; font-family: inherit;
  }
  .role-select:focus { outline: none; border-color: var(--color-input-focus); }

  .button.small { padding: .3rem .6rem; font-size: .75rem; }
</style>
