<script lang="ts">
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { NAV_ITEMS, useSidebar, type NavItem } from './navigation.svelte';
  import { getProfile, hasSession, clearAuth, type AuthUser } from './api';

  const sidebar = useSidebar();
  let user: AuthUser | null = $state(null);

  $effect(() => {
    sidebar.initMobile();
    if (hasSession()) getProfile().then((u) => user = u).catch(() => {});
  });

  $effect(() => {
    if (sidebar.isCollapsed && !sidebar.isMobile) {
      document.body.classList.add('sidebar-collapsed');
    } else {
      document.body.classList.remove('sidebar-collapsed');
    }
  });

  function isActive(item: NavItem): boolean {
    const path = $page.url.pathname;
    if (item.path === '/') return path === '/';
    return path === item.path || path.startsWith(item.path + '/');
  }

  async function navigate(path: string) {
    sidebar.onNavigate();
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
  };
</script>

{#if sidebar.isMobile}
  <!-- Mobile hamburger top bar -->
  <button class="mobile-menu-btn" onclick={sidebar.toggleDrawer} aria-label={sidebar.isDrawerOpen ? 'Cerrar menú' : 'Abrir menú'}>
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">{@html icons[sidebar.isDrawerOpen ? 'close' : 'menu']}</svg>
  </button>

  <!-- Mobile drawer overlay -->
  {#if sidebar.isDrawerOpen}
    <!-- svelte-ignore a11y_click_events_have_key_events -->
    <!-- svelte-ignore a11y_no_static_element_interactions -->
    <div class="drawer-overlay" onclick={sidebar.toggleDrawer}></div>
    <aside class="sidebar sidebar-mobile">
      {#if user}
        <div class="sidebar-user">
          <div class="sidebar-avatar">{user.firstName[0]}{user.lastName[0]}</div>
          <div><strong>{user.firstName} {user.lastName}</strong><span>{user.email}</span></div>
        </div>
      {/if}
      <nav class="sidebar-nav">
        {#each NAV_ITEMS as item}
          <button class="nav-item" class:active={isActive(item)} onclick={() => navigate(item.path)} aria-current={isActive(item) ? 'page' : undefined}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">{@html icons[item.icon]}</svg>
            <span>{item.label}</span>
          </button>
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
  <!-- Desktop sidebar -->
  <aside class="sidebar sidebar-desktop" class:collapsed={sidebar.isCollapsed}>
    {#if !sidebar.isCollapsed || user}
      <div class="sidebar-user">
        {#if user}
          <div class="sidebar-avatar">{user.firstName[0]}{user.lastName[0]}</div>
          {#if !sidebar.isCollapsed}
            <div><strong>{user.firstName}</strong></div>
          {/if}
        {/if}
      </div>
    {/if}

    <nav class="sidebar-nav">
      {#each NAV_ITEMS as item}
        <button
          class="nav-item"
          class:active={isActive(item)}
          onclick={() => navigate(item.path)}
          title={sidebar.isCollapsed ? item.label : undefined}
          aria-current={isActive(item) ? 'page' : undefined}
        >
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">{@html icons[item.icon]}</svg>
          {#if !sidebar.isCollapsed}<span>{item.label}</span>{/if}
        </button>
      {/each}
    </nav>

    <div class="sidebar-footer">
      {#if user && !sidebar.isCollapsed}
        <button class="nav-item logout-item" onclick={signOut}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">{@html icons.logout}</svg>
          <span>Cerrar sesión</span>
        </button>
      {/if}
      <button class="nav-item collapse-btn" onclick={sidebar.toggleCollapsed} aria-label={sidebar.isCollapsed ? 'Expandir menú' : 'Colapsar menú'} title={sidebar.isCollapsed ? 'Expandir' : 'Colapsar'}>
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">{@html icons[sidebar.isCollapsed ? 'expand' : 'collapse']}</svg>
        {#if !sidebar.isCollapsed}<span>Colapsar</span>{/if}
      </button>
    </div>
  </aside>
{/if}

<style>
  .mobile-menu-btn {
    position: fixed; top: .75rem; left: .75rem; z-index: 90;
    width: 2.5rem; height: 2.5rem; display: grid; place-items: center;
    border: 1px solid #dfe3d7; border-radius: .7rem; background: #fff; color: #33423b; cursor: pointer;
  }

  .drawer-overlay {
    position: fixed; inset: 0; z-index: 95; background: #0f1f1a66; backdrop-filter: blur(2px);
  }

  .sidebar {
    display: flex; flex-direction: column;
    border-right: 1px solid #e5e9e1; background: #fafbf8;
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
    padding: 1.2rem 1rem; border-bottom: 1px solid #e5e9e1;
  }
  .collapsed .sidebar-user { justify-content: center; padding: 1.2rem .5rem; }
  .sidebar-user div { display: grid; gap: .1rem; min-width: 0; }
  .sidebar-user strong { font-size: .88rem; font-family: 'Space Grotesk', sans-serif; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .sidebar-user span { font-size: .72rem; color: #89948d; }

  .sidebar-avatar {
    width: 2.2rem; height: 2.2rem; display: grid; place-items: center; flex-shrink: 0;
    border-radius: .7rem; color: #eef4e9; background: #173d35;
    font-size: .78rem; font-weight: 700; font-family: 'Space Grotesk', sans-serif;
  }

  .sidebar-nav { flex: 1; display: flex; flex-direction: column; gap: .15rem; padding: .5rem; overflow-y: auto; }

  .nav-item {
    display: flex; align-items: center; gap: .75rem;
    border: 0; border-radius: .6rem; padding: .6rem .75rem;
    color: #53635c; background: transparent; cursor: pointer;
    font-size: .85rem; font-weight: 500; text-align: left;
    transition: background 150ms ease, color 150ms ease;
  }
  .collapsed .nav-item { justify-content: center; padding: .6rem; }
  .nav-item:hover { background: #eef1e9; color: #33423b; }
  .nav-item.active { background: #dce7d2; color: #38622e; font-weight: 600; }
  .nav-item span { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

  .sidebar-footer { padding: .5rem; border-top: 1px solid #e5e9e1; display: flex; flex-direction: column; gap: .15rem; }
  .logout-item { color: #a43d36; }
  .logout-item:hover { background: #fff0ed; color: #a43d36; }
  .collapse-btn { color: #89948d; }
  .collapse-btn:hover { color: #53635c; }
</style>
