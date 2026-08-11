import { browser } from '$app/environment';
import { PALETTES, type Palette } from './palettes';

const STORAGE_KEY = 'ligas:palette';
const DEFAULT_PALETTE = 'forest';

function loadPaletteId(): string {
  if (!browser) return DEFAULT_PALETTE;
  return localStorage.getItem(STORAGE_KEY) || DEFAULT_PALETTE;
}

let currentId = $state(loadPaletteId());
let currentPalette = $state(PALETTES.find((p) => p.id === currentId) || PALETTES[0]);

export function usePalette() {
  return {
    get id() { return currentId; },
    get palette() { return currentPalette; },
    setPalette(id: string) {
      const found = PALETTES.find((p) => p.id === id);
      if (!found) return;
      currentId = id;
      currentPalette = found;
      if (browser) {
        localStorage.setItem(STORAGE_KEY, id);
        applyPalette(found);
      }
    },
    initPalette() {
      applyPalette(currentPalette);
    },
    get palettes() { return PALETTES; },
  };
}

function applyPalette(palette: Palette) {
  if (!browser) return;
  const root = document.documentElement;
  root.style.setProperty('--color-bg', palette.colors.bg);
  root.style.setProperty('--color-surface', palette.colors.surface);
  root.style.setProperty('--color-surface-hover', palette.colors.surfaceHover);
  root.style.setProperty('--color-border', palette.colors.border);
  root.style.setProperty('--color-text', palette.colors.text);
  root.style.setProperty('--color-text-muted', palette.colors.textMuted);
  root.style.setProperty('--color-text-light', palette.colors.textLight);
  root.style.setProperty('--color-heading', palette.colors.heading);
  root.style.setProperty('--color-accent', palette.colors.accent);
  root.style.setProperty('--color-accent-light', palette.colors.accentLight);
  root.style.setProperty('--color-accent-bg', palette.colors.accentBg);
  root.style.setProperty('--color-accent-text', palette.colors.accentText);
  root.style.setProperty('--color-success', palette.colors.success);
  root.style.setProperty('--color-success-bg', palette.colors.successBg);
  root.style.setProperty('--color-error', palette.colors.error);
  root.style.setProperty('--color-error-bg', palette.colors.errorBg);
  root.style.setProperty('--color-hero', palette.colors.hero);
  root.style.setProperty('--color-hero-text', palette.colors.heroText);
  root.style.setProperty('--color-hero-muted', palette.colors.heroMuted);
  root.style.setProperty('--color-hero-accent', palette.colors.heroAccent);
  root.style.setProperty('--color-sidebar', palette.colors.sidebar);
  root.style.setProperty('--color-sidebar-border', palette.colors.sidebarBorder);
  root.style.setProperty('--color-sidebar-hover', palette.colors.sidebarHover);
  root.style.setProperty('--color-sidebar-active', palette.colors.sidebarActive);
  root.style.setProperty('--color-sidebar-active-text', palette.colors.sidebarActiveText);
  root.style.setProperty('--color-input', palette.colors.input);
  root.style.setProperty('--color-input-border', palette.colors.inputBorder);
  root.style.setProperty('--color-input-focus', palette.colors.inputFocus);
  root.style.setProperty('--color-shadow', palette.colors.shadow);
  root.style.setProperty('--color-overlay', palette.colors.overlay);
}
