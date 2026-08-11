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

class SidebarState {
  collapsed = $state(loadCollapsed());
  drawerOpen = $state(false);
  mobile = $state(false);
  private _initialized = false;

  initMobile() {
    if (this._initialized || !browser) return;
    this._initialized = true;
    const mql = window.matchMedia('(min-width: 768px)');
    this.mobile = !mql.matches;
    mql.addEventListener('change', (e) => {
      this.mobile = !e.matches;
      if (e.matches) this.drawerOpen = false;
    });
  }

  toggleCollapsed() {
    this.collapsed = !this.collapsed;
    if (browser) localStorage.setItem(COLLAPSED_KEY, String(this.collapsed));
    if (!this.mobile) {
      if (this.collapsed) document.body.classList.add('sidebar-collapsed');
      else document.body.classList.remove('sidebar-collapsed');
    }
  }

  toggleDrawer() {
    this.drawerOpen = !this.drawerOpen;
  }

  onNavigate() {
    if (this.mobile) this.drawerOpen = false;
  }

  ensureBodyClass() {
    if (!browser || this.mobile) return;
    if (this.collapsed) document.body.classList.add('sidebar-collapsed');
    else document.body.classList.remove('sidebar-collapsed');
  }
}

export const sidebarState = new SidebarState();
