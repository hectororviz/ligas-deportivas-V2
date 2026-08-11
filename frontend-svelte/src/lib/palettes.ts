export interface Palette {
  id: string;
  name: string;
  colors: {
    bg: string;
    surface: string;
    surfaceHover: string;
    border: string;
    text: string;
    textMuted: string;
    textLight: string;
    heading: string;
    accent: string;
    accentLight: string;
    accentBg: string;
    accentText: string;
    success: string;
    successBg: string;
    error: string;
    errorBg: string;
    hero: string;
    heroText: string;
    heroMuted: string;
    heroAccent: string;
    sidebar: string;
    sidebarBorder: string;
    sidebarHover: string;
    sidebarActive: string;
    sidebarActiveText: string;
    input: string;
    inputBorder: string;
    inputFocus: string;
    shadow: string;
    overlay: string;
  };
}

export const PALETTES: Palette[] = [
  {
    id: 'forest',
    name: 'Bosque',
    colors: {
      bg: '#f4f5ef', surface: '#ffffff', surfaceHover: '#eef1e9', border: '#dfe3d7',
      text: '#17231f', textMuted: '#66736c', textLight: '#89948d', heading: '#0f1a17',
      accent: '#759b51', accentLight: '#d0e87c', accentBg: '#e4edcf', accentText: '#527638',
      success: '#38622e', successBg: '#e4edcf', error: '#a43d36', errorBg: '#fff0ed',
      hero: '#173d35', heroText: '#eef4e9', heroMuted: '#c2d0c6', heroAccent: '#d0e87c',
      sidebar: '#fafbf8', sidebarBorder: '#e5e9e1', sidebarHover: '#eef1e9', sidebarActive: '#dce7d2', sidebarActiveText: '#38622e',
      input: '#fbfcf9', inputBorder: '#d7ddd3', inputFocus: '#759b51', shadow: '#17231f12', overlay: '#0f1f1a66',
    }
  },
  {
    id: 'ocean',
    name: 'Océano',
    colors: {
      bg: '#f2f6f9', surface: '#ffffff', surfaceHover: '#e8f0f5', border: '#d4e0ea',
      text: '#1a2530', textMuted: '#5a6b7a', textLight: '#7a8a98', heading: '#0d1a25',
      accent: '#3b82c4', accentLight: '#7cb8e4', accentBg: '#dbeafe', accentText: '#2563a0',
      success: '#1d6e4c', successBg: '#dcf5ea', error: '#b5323a', errorBg: '#fde8ec',
      hero: '#1a2d42', heroText: '#e8f0f5', heroMuted: '#b0c4d8', heroAccent: '#7cb8e4',
      sidebar: '#f6f9fb', sidebarBorder: '#e2eaf3', sidebarHover: '#e8f0f5', sidebarActive: '#d4e4f5', sidebarActiveText: '#2563a0',
      input: '#fafcfd', inputBorder: '#d0dce6', inputFocus: '#3b82c4', shadow: '#1a253012', overlay: '#0d1a2566',
    }
  },
  {
    id: 'sunset',
    name: 'Atardecer',
    colors: {
      bg: '#fdf6f2', surface: '#ffffff', surfaceHover: '#fdf0e5', border: '#ead4c5',
      text: '#2d1c15', textMuted: '#7a5e4e', textLight: '#9a7e6e', heading: '#1e0f08',
      accent: '#c46a3b', accentLight: '#e8955c', accentBg: '#fce5d5', accentText: '#a0502a',
      success: '#4a7230', successBg: '#eaf2d8', error: '#a0402e', errorBg: '#fce5e0',
      hero: '#3d2015', heroText: '#fdf0e5', heroMuted: '#d4b8a0', heroAccent: '#e8955c',
      sidebar: '#fdf8f5', sidebarBorder: '#f0dfd0', sidebarHover: '#fdf0e5', sidebarActive: '#f8ddd0', sidebarActiveText: '#a0502a',
      input: '#fefcfa', inputBorder: '#e5cebc', inputFocus: '#c46a3b', shadow: '#2d1c1512', overlay: '#1e0f0866',
    }
  },
  {
    id: 'lavender',
    name: 'Lavanda',
    colors: {
      bg: '#f8f6fc', surface: '#ffffff', surfaceHover: '#f2edfa', border: '#ded5f0',
      text: '#1f1835', textMuted: '#5e5280', textLight: '#7e7298', heading: '#140d28',
      accent: '#7c5cbf', accentLight: '#a78ad8', accentBg: '#ece3f8', accentText: '#5e3ea0',
      success: '#3d6e40', successBg: '#e2f2e0', error: '#9a3a42', errorBg: '#fce4e8',
      hero: '#2d1f4a', heroText: '#ede8f5', heroMuted: '#c0b0d8', heroAccent: '#a78ad8',
      sidebar: '#faf8fd', sidebarBorder: '#e8e0f5', sidebarHover: '#f2edfa', sidebarActive: '#e5daf5', sidebarActiveText: '#5e3ea0',
      input: '#fcfbfe', inputBorder: '#d8cfe8', inputFocus: '#7c5cbf', shadow: '#1f183512', overlay: '#140d2866',
    }
  },
  {
    id: 'midnight',
    name: 'Medianoche',
    colors: {
      bg: '#18181b', surface: '#27272a', surfaceHover: '#323236', border: '#3f3f46',
      text: '#f4f4f5', textMuted: '#a1a1aa', textLight: '#71717a', heading: '#fafafa',
      accent: '#8b5cf6', accentLight: '#a78bfa', accentBg: '#272140', accentText: '#a78bfa',
      success: '#4ade80', successBg: '#1a3028', error: '#f87171', errorBg: '#382020',
      hero: '#09090b', heroText: '#f4f4f5', heroMuted: '#a1a1aa', heroAccent: '#a78bfa',
      sidebar: '#1a1a1d', sidebarBorder: '#27272a', sidebarHover: '#323236', sidebarActive: '#272140', sidebarActiveText: '#a78bfa',
      input: '#202022', inputBorder: '#3f3f46', inputFocus: '#8b5cf6', shadow: '#00000030', overlay: '#09090baa',
    }
  },
  {
    id: 'obsidian',
    name: 'Obsidiana',
    colors: {
      bg: '#0f0f11', surface: '#1c1c1f', surfaceHover: '#28282c', border: '#2e2e33',
      text: '#e4e4e7', textMuted: '#8b8b92', textLight: '#606068', heading: '#f0f0f0',
      accent: '#16a34a', accentLight: '#4ade80', accentBg: '#0a2a18', accentText: '#4ade80',
      success: '#4ade80', successBg: '#0a2a18', error: '#ef4444', errorBg: '#2d1515',
      hero: '#050505', heroText: '#e4e4e7', heroMuted: '#8b8b92', heroAccent: '#4ade80',
      sidebar: '#131315', sidebarBorder: '#1c1c1f', sidebarHover: '#28282c', sidebarActive: '#0a2a18', sidebarActiveText: '#4ade80',
      input: '#18181a', inputBorder: '#2e2e33', inputFocus: '#16a34a', shadow: '#00000040', overlay: '#050505cc',
    }
  },
  {
    id: 'slate',
    name: 'Pizarra',
    colors: {
      bg: '#f7f8fa', surface: '#ffffff', surfaceHover: '#eeeff3', border: '#dfe0e5',
      text: '#1e2028', textMuted: '#5e6070', textLight: '#808290', heading: '#12141c',
      accent: '#4b5568', accentLight: '#8899aa', accentBg: '#e4e7ec', accentText: '#3a4560',
      success: '#2d6040', successBg: '#e0f0e4', error: '#9a3e3e', errorBg: '#fce8e8',
      hero: '#252830', heroText: '#eef0f4', heroMuted: '#b0b4c0', heroAccent: '#8899aa',
      sidebar: '#fafafc', sidebarBorder: '#e8e9ef', sidebarHover: '#eeeff3', sidebarActive: '#e0e4ec', sidebarActiveText: '#3a4560',
      input: '#fcfcfd', inputBorder: '#d8dae0', inputFocus: '#4b5568', shadow: '#1e202812', overlay: '#12141c66',
    }
  },
  {
    id: 'amber',
    name: 'Ámbar',
    colors: {
      bg: '#fefdf7', surface: '#ffffff', surfaceHover: '#fdf8e5', border: '#ead9a0',
      text: '#261e08', textMuted: '#6b5e30', textLight: '#8b7e50', heading: '#181005',
      accent: '#b8860b', accentLight: '#d4a530', accentBg: '#fcf0d0', accentText: '#8a5e08',
      success: '#4a6830', successBg: '#eaf2d8', error: '#a0402e', errorBg: '#fce5e0',
      hero: '#3d2a08', heroText: '#fdf5e0', heroMuted: '#d4c090', heroAccent: '#d4a530',
      sidebar: '#fefcfa', sidebarBorder: '#f0e5c0', sidebarHover: '#fdf8e5', sidebarActive: '#faf0d0', sidebarActiveText: '#8a5e08',
      input: '#fefdfa', inputBorder: '#e5d8a0', inputFocus: '#b8860b', shadow: '#261e0812', overlay: '#18100566',
    }
  },
];
