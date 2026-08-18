<script lang="ts">
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { NAV_ITEMS, sidebarState, type NavItem, type NavChild } from './navigation.svelte';
  import { loginModalState } from './login-modal.svelte';
  import { getProfile, getSiteIdentity, hasSession, logout, canViewModule, canManageModule, type AuthUser, type SiteIdentity } from './api';
  import { MorphIcon } from 'morphicons/svelte';
  import { Menu, X, ChevronDown, ChevronRight, ChevronLeft } from 'lucide';
  import { LogOut, LogIn } from '@lucide/svelte';

  let user: AuthUser | null = $state(null);
  let identity = $state<SiteIdentity | null>(null);
  let expandedGroups = $state<Record<string, boolean>>({});

  const CHILD_MODULES: Record<string, string> = {
    leagues: 'LIGAS',
    tournaments: 'TORNEOS',
    zones: 'ZONAS',
    categories: 'CATEGORIAS'
  };

  let visibleItems = $derived.by((): NavItem[] => {
    const items = NAV_ITEMS.map((item) => {
      if (item.id === 'gestion') {
        const children = (item.children ?? []).filter((child) =>
          canViewModule(user, CHILD_MODULES[child.id] ?? '')
        );
        return children.length ? { ...item, children } : null;
      }
      if (item.id === 'players') {
        return canViewModule(user, 'JUGADORES') ? item : null;
      }
      if (item.id === 'settings') {
        if (!user) return null;
        const children = (item.children ?? []).filter((child) =>
          child.id === 'account' ? true : canManageModule(user, 'CONFIGURACION')
        );
        return children.length ? { ...item, children } : null;
      }
      return item;
    });
    return items.filter((item): item is NavItem => item !== null);
  });

  $effect(() => {
    sidebarState.initMobile();
    sidebarState.ensureBodyClass();
    if (hasSession()) getProfile().then((u) => user = u).catch(() => {});
    getSiteIdentity().then((i) => identity = i).catch(() => {});
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
    await logout();
    window.location.href = '/';
  }
</script>

{#if sidebarState.mobile}
  <button class="mobile-menu-btn" onclick={() => sidebarState.toggleDrawer()} aria-label={sidebarState.drawerOpen ? 'Cerrar menú' : 'Abrir menú'}>
    <MorphIcon icon={sidebarState.drawerOpen ? X : Menu} size={22} strokeWidth={2} spring="snappy" />
  </button>

  {#if sidebarState.drawerOpen}
    <!-- svelte-ignore a11y_click_events_have_key_events -->
    <!-- svelte-ignore a11y_no_static_element_interactions -->
    <div class="drawer-overlay" onclick={() => sidebarState.toggleDrawer()}></div>
    <aside class="sidebar sidebar-mobile">
      <div class="sidebar-user">
        {#if identity?.iconUrl}
          <img class="sidebar-logo" src={identity.iconUrl} alt={identity.title ?? 'Ligas Deportivas'} />
        {:else}
          <div class="sidebar-avatar">LD</div>
        {/if}
        <div><strong>{identity?.title ?? 'Ligas Deportivas'}</strong></div>
      </div>
      <nav class="sidebar-nav">
        {#each visibleItems as item}
          {@const Icon = item.icon}
          {#if item.children}
            <button class="nav-item nav-group" class:active={isActive(item)} onclick={() => { expandedGroups[item.id] = !expandedGroups[item.id]; }} aria-expanded={expandedGroups[item.id] || isActive(item)}>
              <Icon size={20} strokeWidth={1.8} />
              <span>{item.label}</span>
              <span class="chevron"><MorphIcon icon={expandedGroups[item.id] || isActive(item) ? ChevronDown : ChevronRight} size={14} strokeWidth={2} spring="snappy" /></span>
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
              <Icon size={20} strokeWidth={1.8} />
              <span>{item.label}</span>
            </button>
          {/if}
        {/each}
      </nav>
      <div class="sidebar-footer">
        {#if user}
          <button class="nav-item logout-item" onclick={signOut}>
            <LogOut size={20} strokeWidth={1.8} />
            <span>Cerrar sesión</span>
          </button>
        {:else}
          <button class="nav-item login-item" onclick={() => loginModalState.openModal()}>
            <LogIn size={20} strokeWidth={1.8} />
            <span>Ingresar</span>
          </button>
        {/if}
      </div>
    </aside>
  {/if}
{:else}
  <aside class="sidebar sidebar-desktop" class:collapsed={sidebarState.collapsed}>
    <div class="sidebar-user">
      {#if identity?.iconUrl}
        <img class="sidebar-logo" src={identity.iconUrl} alt={identity.title ?? 'Ligas Deportivas'} />
      {:else}
        <div class="sidebar-avatar">LD</div>
      {/if}
      {#if !sidebarState.collapsed}
        <div><strong>{identity?.title ?? 'Ligas Deportivas'}</strong></div>
      {/if}
    </div>

    <nav class="sidebar-nav">
      {#each visibleItems as item}
        {@const Icon = item.icon}
        {#if item.children}
          <button
            class="nav-item nav-group"
            class:active={isActive(item)}
            onclick={() => handleGroupClick(item)}
            title={sidebarState.collapsed ? item.label : undefined}
            aria-expanded={expandedGroups[item.id] || isActive(item)}
          >
            <Icon size={20} strokeWidth={1.8} />
            {#if !sidebarState.collapsed}
              <span>{item.label}</span>
              <span class="chevron"><MorphIcon icon={expandedGroups[item.id] || isActive(item) ? ChevronDown : ChevronRight} size={14} strokeWidth={2} spring="snappy" /></span>
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
            <Icon size={20} strokeWidth={1.8} />
            {#if !sidebarState.collapsed}<span>{item.label}</span>{/if}
          </button>
        {/if}
      {/each}
    </nav>

    <div class="sidebar-footer">
      {#if user && !sidebarState.collapsed}
        <button class="nav-item logout-item" onclick={signOut}>
          <LogOut size={20} strokeWidth={1.8} />
          <span>Cerrar sesión</span>
        </button>
      {/if}
      {#if !user}
        <button class="nav-item login-item" onclick={() => loginModalState.openModal()} title={sidebarState.collapsed ? 'Ingresar' : undefined}>
          <LogIn size={20} strokeWidth={1.8} />
          {#if !sidebarState.collapsed}<span>Ingresar</span>{/if}
        </button>
      {/if}
      <button class="nav-item collapse-btn" onclick={() => sidebarState.toggleCollapsed()} aria-label={sidebarState.collapsed ? 'Expandir menú' : 'Colapsar menú'} title={sidebarState.collapsed ? 'Expandir' : 'Colapsar'}>
        <MorphIcon icon={sidebarState.collapsed ? ChevronRight : ChevronLeft} size={20} strokeWidth={2} spring="snappy" />
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

  .sidebar-avatar {
    width: 2.2rem;
    height: 2.2rem;
    display: grid;
    place-items: center;
    flex-shrink: 0;
    border-radius: .7rem;
    color: var(--color-hero-text);
    background: var(--color-hero);
    font-size: .78rem;
    font-weight: 700;
    font-family: 'Space Grotesk', sans-serif;
  }
  .sidebar-logo {
    width: 2.2rem;
    height: 2.2rem;
    object-fit: contain;
    flex-shrink: 0;
    border-radius: .7rem;
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
    display: inline-flex; align-items: center;
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
  .login-item { color: var(--color-accent-text); }
  .login-item:hover { background: var(--color-accent-bg); color: var(--color-accent-text); }
  .collapse-btn { color: var(--color-text-light); }
  .collapse-btn:hover { color: var(--color-text-muted); }
</style>
