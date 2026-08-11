import { browser } from '$app/environment';

export interface NavChild {
  id: string;
  label: string;
  path: string;
}

export interface NavItem {
  id: string;
  label: string;
  icon: string;
  path?: string;
  children?: NavChild[];
}

export const NAV_ITEMS: NavItem[] = [
  { id: 'dashboard', label: 'Home', icon: 'home', path: '/' },
  {
    id: 'gestion',
    label: 'Gestión',
    icon: 'trophy',
    children: [
      { id: 'leagues', label: 'Ligas', path: '/leagues' },
      { id: 'tournaments', label: 'Torneos', path: '/tournaments' },
      { id: 'zones', label: 'Zonas', path: '/zones' },
      { id: 'categories', label: 'Categorías', path: '/categories' },
    ]
  },
  { id: 'clubs', label: 'Clubes', icon: 'shield', path: '/clubs' },
  { id: 'players', label: 'Jugadores', icon: 'users', path: '/players' },
  { id: 'standings', label: 'Tablas', icon: 'table', path: '/standings' },
  {
    id: 'settings',
    label: 'Configuración',
    icon: 'settings',
    path: '/settings',
    children: [
      { id: 'account', label: 'Cuenta y perfil', path: '/settings/account' },
      { id: 'users', label: 'Usuarios y permisos', path: '/settings/users' },
      { id: 'site-identity', label: 'Identidad del sitio', path: '/settings/site-identity' },
    ]
  },
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
