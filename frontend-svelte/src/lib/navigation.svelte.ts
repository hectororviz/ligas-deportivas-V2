import { browser } from '$app/environment';

export interface NavItem {
  id: string;
  label: string;
  icon: string;
  path: string;
}

export const NAV_ITEMS: NavItem[] = [
  { id: 'dashboard', label: 'Panel', icon: 'home', path: '/' },
  { id: 'leagues', label: 'Ligas', icon: 'trophy', path: '/leagues' },
  { id: 'clubs', label: 'Clubes', icon: 'shield', path: '/clubs' },
  { id: 'players', label: 'Jugadores', icon: 'users', path: '/players' },
  { id: 'categories', label: 'Categorías', icon: 'layers', path: '/categories' },
  { id: 'tournaments', label: 'Torneos', icon: 'tournament', path: '/tournaments' },
  { id: 'zones', label: 'Zonas', icon: 'grid', path: '/zones' },
  { id: 'standings', label: 'Tablas', icon: 'table', path: '/standings' },
  { id: 'settings', label: 'Configuración', icon: 'settings', path: '/settings' },
  { id: 'palette', label: 'Paleta', icon: 'palette', path: '/settings/palette' },
];

const COLLAPSED_KEY = 'sidebar:collapsed';

function loadCollapsed(): boolean {
  if (!browser) return false;
  const stored = localStorage.getItem(COLLAPSED_KEY);
  return stored === 'true';
}

let collapsed = $state(loadCollapsed());
let drawerOpen = $state(false);
let isMobile = $state(false);

export function useSidebar() {
  function initMobile() {
    if (!browser) return;
    const mql = window.matchMedia('(min-width: 768px)');
    isMobile = !mql.matches;
    mql.addEventListener('change', (e) => { isMobile = !e.matches; if (e.matches) drawerOpen = false; });
  }

  return {
    get isCollapsed() { return collapsed; },
    set isCollapsed(v: boolean) {
      collapsed = v;
      if (browser) localStorage.setItem(COLLAPSED_KEY, String(v));
    },
    get isDrawerOpen() { return drawerOpen; },
    set isDrawerOpen(v: boolean) { drawerOpen = v; },
    get isMobile() { return isMobile; },
    initMobile,
    toggleCollapsed() { this.isCollapsed = !this.isCollapsed; },
    toggleDrawer() { this.isDrawerOpen = !this.isDrawerOpen; },
    onNavigate() { if (isMobile) drawerOpen = false; },
  };
}
