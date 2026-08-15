<script lang="ts">
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { NAV_ITEMS, sidebarState, type NavItem, type NavChild } from './navigation.svelte';
  import { getProfile, hasSession, clearAuth, type AuthUser } from './api';

  let user: AuthUser | null = $state(null);
  let expandedGroups = $state<Record<string, boolean>>({});

  $effect(() => {
    sidebarState.initMobile();
    sidebarState.ensureBodyClass();
    if (hasSession()) getProfile().then((u) => user = u).catch(() => {});
  });

  function isActive(item: NavItem): boolean {
    const path = $page.url.pathname;
    if (item.children) return item.children.some((c) => path === c.path || path.startsWith(c.path + '/'));
    if (!item.path) return false;
    if (item.path === '/') return path === '/';
    return path === item.path || path.startsWith(item.path + '/');
  }

  function isChildActive(child: NavChild): boolean {
    const path = $page.url.pathname;
    return path === child.path || path.startsWith(child.path + '/');
  }

  function handleGroupClick(item: NavItem) {
    if (sidebarState.collapsed) {
      sidebarState.toggleCollapsed();
      expandedGroups[item.id] = true;
    } else if (item.children) {
      expandedGroups[item.id] = !expandedGroups[item.id];
    }
  }

  async function navigate(path: string) {
    sidebarState.onNavigate();
    await goto(path);
  }

  async function signOut() {
    await clearAuth();
    await goto('/login');
  }

  const icons: Record<string, string> = {
    home: '<path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/>',
    trophy: '<path d="M6 9H4.5a2.5 2.5 0 0 1 0-5C7 4 7 7 7 8"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5C17 4 17 7 17 8"/><path d="M4 22h16"/><path d="M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22"/><path d="M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22"/><path d="M18 2H6v7a6 6 0 0 0 12 0V2Z"/>',
    shield: '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.06 1.06 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/>',
    layers: '<path d="m12.83 2.18a2 2 0 0 0-1.66 0L2.6 6.08a1 1 0 0 0 0 1.83l8.58 3.91a2 2 0 0 0 1.66 0l8.58-3.9a1 1 0 0 0 0-1.83Z"/><path d="m22 12.5-8.58 3.91a2 2 0 0 1-1.66 0L3.18 12.5"/><path d="m22 17-8.58 3.91a2 2 0 0 1-1.66 0L3.18 17"/>',
    tournament: '<circle cx="12" cy="12" r="10"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10A15.3 15.3 0 0 1 12 2z"/><path d="M2 12h20"/>',
    grid: '<rect width="7" height="7" x="3" y="3" rx="1"/><rect width="7" height="7" x="14" y="3" rx="1"/><rect width="7" height="7" x="3" y="14" rx="1"/><rect width="7" height="7" x="14" y="14" rx="1"/>',
    table: '<path d="M3 3h18v18H3zM3 9h18M3 15h18M9 3v18"/>',
    settings: '<path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/>',
    logout: '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" x2="9" y1="12" y2="12"/>',
    collapse: '<polyline points="15 18 9 12 15 6"/>',
    expand: '<polyline points="9 18 15 12 9 6"/>',
    menu: '<line x1="4" x2="20" y1="12" y2="12"/><line x1="4" x2="20" y1="6" y2="6"/><line x1="4" x2="20" y1="18" y2="18"/>',
    close: '<line x1="18" x2="6" y1="6" y2="18"/><line x1="6" x2="18" y1="6" y2="18"/>',
    palette: '<circle cx="12" cy="12" r="10"/><path d="M12 2a10 10 0 0 1 0 20"/><path d="M12 2a4 4 0 0 0 0 8 4 4 0 0 1 0 8"/><path d="M12 18a4 4 0 0 0 0-8 4 4 0 0 1 0-8"/>',
    users: '<path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
    chevronRight: '<polyline points="9 18 15 12 9 6"/>',
    chevronDown: '<polyline points="6 9 12 15 18 9"/>',
    calendar: '<rect width="18" height="18" x="3" y="4" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/><path d="M8 13h.01M12 13h.01M16 13h.01M8 17h.01M12 17h.01M16 17h.01"/>',
  };
</script>

{#if sidebarState.mobile}
  <button class="mobile-menu-btn" onclick={() => sidebarState.toggleDrawer()} aria-label={sidebarState.drawerOpen ? 'Cerrar menú' : 'Abrir menú'}>
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">{@html icons[sidebarState.drawerOpen ? 'close' : 'menu']}</svg>
  </button>

  {#if sidebarState.drawerOpen}
    <!-- svelte-ignore a11y_click_events_have_key_events -->
    <!-- svelte-ignore a11y_no_static_element_interactions -->
    <div class="drawer-overlay" onclick={() => sidebarState.toggleDrawer()}></div>
    <aside class="sidebar sidebar-mobile">
      {#if user}
        <div class="sidebar-user">
          <div class="sidebar-avatar">{user.firstName[0]}{user.lastName[0]}</div>
          <div><strong>{user.firstName} {user.lastName}</strong><span>{user.email}</span></div>
        </div>
      {/if}
      <nav class="sidebar-nav">
        {#each NAV_ITEMS as item}
          {#if item.children}
            <button class="nav-item nav-group" class:active={isActive(item)} onclick={() => { expandedGroups[item.id] = !expandedGroups[item.id]; }} aria-expanded={expandedGroups[item.id] || isActive(item)}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">{@html icons[item.icon]}</svg>
              <span>{item.label}</span>
              <svg class="chevron" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                {@html icons[expandedGroups[item.id] || isActive(item) ? 'chevronDown' : 'chevronRight']}
              </svg>
            </button>
            {#if expandedGroups[item.id] || isActive(item)}
              {#each item.children as child}
                <button class="nav-item nav-child" class:active={isChildActive(child)} onclick={() => navigate(child.path)} aria-current={isChildActive(child) ? 'page' : undefined}>
                  <span>{child.label}</span>
                </button>
              {/each}
            {/if}
          {:else}
            <button class="nav-item" class:active={isActive(item)} onclick={() => navigate(item.path!)} aria-current={isActive(item) ? 'page' : undefined}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">{@html icons[item.icon]}</svg>
              <span>{item.label}</span>
            </button>
          {/if}
        {/each}
      </nav>
      <div class="sidebar-footer">
        {#if user}
          <button class="nav-item logout-item" onclick={signOut}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">{@html icons.logout}</svg>
            <span>Cerrar sesión</span>
          </button>
        {/if}
      </div>
    </aside>
  {/if}
{:else}
  <aside class="sidebar sidebar-desktop" class:collapsed={sidebarState.collapsed}>
    {#if !sidebarState.collapsed || user}
      <div class="sidebar-user">
        {#if user}
          <div class="sidebar-avatar">{user.firstName[0]}{user.lastName[0]}</div>
          {#if !sidebarState.collapsed}
            <div><strong>{user.firstName}</strong></div>
          {/if}
        {/if}
      </div>
    {/if}

    <nav class="sidebar-nav">
      {#each NAV_ITEMS as item}
        {#if item.children}
          <button
            class="nav-item nav-group"
            class:active={isActive(item)}
            onclick={() => handleGroupClick(item)}
            title={sidebarState.collapsed ? item.label : undefined}
            aria-expanded={expandedGroups[item.id] || isActive(item)}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">{@html icons[item.icon]}</svg>
            {#if !sidebarState.collapsed}
              <span>{item.label}</span>
              <svg class="chevron" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                {@html icons[expandedGroups[item.id] || isActive(item) ? 'chevronDown' : 'chevronRight']}
              </svg>
            {/if}
          </button>
          {#if !sidebarState.collapsed && (expandedGroups[item.id] || isActive(item))}
            {#each item.children as child}
              <button
                class="nav-item nav-child"
                class:active={isChildActive(child)}
                onclick={() => navigate(child.path)}
                aria-current={isChildActive(child) ? 'page' : undefined}
              >
                <span>{child.label}</span>
              </button>
            {/each}
          {/if}
        {:else}
          <button
            class="nav-item"
            class:active={isActive(item)}
            onclick={() => navigate(item.path!)}
            title={sidebarState.collapsed ? item.label : undefined}
            aria-current={isActive(item) ? 'page' : undefined}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">{@html icons[item.icon]}</svg>
            {#if !sidebarState.collapsed}<span>{item.label}</span>{/if}
          </button>
        {/if}
      {/each}
    </nav>

    <div class="sidebar-footer">
      {#if user && !sidebarState.collapsed}
        <button class="nav-item logout-item" onclick={signOut}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">{@html icons.logout}</svg>
          <span>Cerrar sesión</span>
        </button>
      {/if}
      <button class="nav-item collapse-btn" onclick={() => sidebarState.toggleCollapsed()} aria-label={sidebarState.collapsed ? 'Expandir menú' : 'Colapsar menú'} title={sidebarState.collapsed ? 'Expandir' : 'Colapsar'}>
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">{@html icons[sidebarState.collapsed ? 'expand' : 'collapse']}</svg>
        {#if !sidebarState.collapsed}<span>Colapsar</span>{/if}
      </button>
    </div>
  </aside>
{/if}

<style>
  .mobile-menu-btn {
    position: fixed; top: .75rem; left: .75rem; z-index: 90;
    width: 2.5rem; height: 2.5rem; display: grid; place-items: center;
    border: 1px solid var(--color-border); border-radius: .7rem; background: var(--color-surface); color: var(--color-text); cursor: pointer;
  }

  .drawer-overlay {
    position: fixed; inset: 0; z-index: 95; background: var(--color-overlay); backdrop-filter: blur(2px);
  }

  .sidebar {
    display: flex; flex-direction: column;
    border-right: 1px solid var(--color-sidebar-border); background: var(--color-sidebar);
    box-shadow: 4px 0 18px rgba(15, 26, 23, 0.12);
    transition: width 200ms ease;
  }

  .sidebar-desktop {
    position: fixed; top: 0; left: 0; bottom: 0; z-index: 30;
    width: 240px;
  }
  .sidebar-desktop.collapsed { width: 64px; }

  .sidebar-mobile {
    position: fixed; top: 0; left: 0; bottom: 0; z-index: 96;
    width: min(75vw, 280px);
  }

  .sidebar-user {
    display: flex; align-items: center; gap: .7rem;
    padding: 1.2rem 1rem; border-bottom: 1px solid var(--color-sidebar-border);
  }
  .collapsed .sidebar-user { justify-content: center; padding: 1.2rem .5rem; }
  .sidebar-user div { display: grid; gap: .1rem; min-width: 0; }
  .sidebar-user strong { font-size: .88rem; font-family: 'Space Grotesk', sans-serif; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .sidebar-user span { font-size: .72rem; color: var(--color-text-light); }

  .sidebar-avatar {
    width: 2.2rem; height: 2.2rem; display: grid; place-items: center; flex-shrink: 0;
    border-radius: .7rem; color: var(--color-hero-text); background: var(--color-hero);
    font-size: .78rem; font-weight: 700; font-family: 'Space Grotesk', sans-serif;
  }

  .sidebar-nav { flex: 1; display: flex; flex-direction: column; gap: .15rem; padding: .5rem; overflow-y: auto; }

  .nav-item {
    display: flex; align-items: center; gap: .75rem;
    border: 0; border-radius: .6rem; padding: .6rem .75rem;
    color: var(--color-text-muted); background: transparent; cursor: pointer;
    font-size: .85rem; font-weight: 500; text-align: left;
    transition: background 150ms ease, color 150ms ease;
    width: 100%;
  }
  .collapsed .nav-item { justify-content: center; padding: .6rem; }
  .nav-item:hover { background: var(--color-sidebar-hover); color: var(--color-text); }
  .nav-item.active { background: var(--color-sidebar-active); color: var(--color-sidebar-active-text); font-weight: 600; }
  .nav-item span { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

  .nav-group { position: relative; }
  .nav-group .chevron {
    margin-left: auto; flex-shrink: 0;
    transition: transform 200ms ease;
  }

  .nav-child {
    padding-left: 3rem; font-size: .82rem; font-weight: 400;
  }
  .nav-child span { color: var(--color-text-muted); }
  .nav-child:hover span { color: var(--color-text); }
  .nav-child.active span { color: var(--color-sidebar-active-text); }

  .sidebar-footer { padding: .5rem; border-top: 1px solid var(--color-sidebar-border); display: flex; flex-direction: column; gap: .15rem; }
  .logout-item { color: var(--color-error); }
  .logout-item:hover { background: var(--color-error-bg); color: var(--color-error); }
  .collapse-btn { color: var(--color-text-light); }
  .collapse-btn:hover { color: var(--color-text-muted); }
</style>
