<script lang="ts">
  import { onMount } from 'svelte';
  import { getUsers, type PaginatedUsers, type UserRow } from '$lib/api';

  let paginated: PaginatedUsers | null = null;
  let loading = true;
  let error = '';
  let search = '';
  let debounce: ReturnType<typeof setTimeout> | null = null;
  let page = 1;
  let showFilters = $state(false);

  onMount(async () => { await fetchUsers(); });

  async function fetchUsers() {
    loading = true; error = '';
    try {
      paginated = await getUsers(search || undefined, page);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar los usuarios.';
    } finally { loading = false; }
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
      REFEREE: 'tag-green'
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
</script>

<svelte:head><title>Usuarios | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div><p class="eyebrow">Administración</p><h1>Usuarios</h1><p class="muted">Gestiona los usuarios registrados y sus roles asignados.</p></div>
  </header>

  {#if loading && !paginated}
    <section class="loading-card">Cargando usuarios...</section>
  {:else}
    {#if error}<p class="error-banner">{error}</p>{/if}

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
            <article class="user-row">
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
</main>

<style>
  .user-table { margin-top: .5rem; }
  .user-row { display: flex; align-items: flex-start; gap: .8rem; padding: 1rem 0; border-top: 1px solid var(--color-border); }
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
</style>
