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
  {
    id: 'octagon',
    name: 'Octágono',
    colors: {
      bg: '#f2f5f9', surface: '#ffffff', surfaceHover: '#e7edf5', border: '#d2dce9',
      text: '#141e2d', textMuted: '#4e6078', textLight: '#6b7d95', heading: '#0b1422',
      accent: '#0062a8', accentLight: '#5ba4db', accentBg: '#dae9f7', accentText: '#004b82',
      success: '#2a6b3f', successBg: '#dff0e4', error: '#a43838', errorBg: '#fde8e8',
      hero: '#14203a', heroText: '#e8eff7', heroMuted: '#b0c4db', heroAccent: '#5ba4db',
      sidebar: '#f7f9fc', sidebarBorder: '#e2e8f2', sidebarHover: '#e7edf5', sidebarActive: '#d4e2f5', sidebarActiveText: '#004b82',
      input: '#fafcfe', inputBorder: '#ced8e5', inputFocus: '#0062a8', shadow: '#141e2d12', overlay: '#0b142266',
    }
  },
  {
    id: 'octagon-dark',
    name: 'Octágono Oscuro',
    colors: {
      bg: '#10141c', surface: '#1c202a', surfaceHover: '#262b38', border: '#2e3444',
      text: '#e6ecf4', textMuted: '#8a97b0', textLight: '#66728a', heading: '#f0f5fb',
      accent: '#2b8dd6', accentLight: '#6db5e8', accentBg: '#16273d', accentText: '#6db5e8',
      success: '#3ec96b', successBg: '#13281c', error: '#e85d5d', errorBg: '#2d1a1a',
      hero: '#080c14', heroText: '#dce4f0', heroMuted: '#7a8aa5', heroAccent: '#6db5e8',
      sidebar: '#141820', sidebarBorder: '#1c202a', sidebarHover: '#262b38', sidebarActive: '#16273d', sidebarActiveText: '#6db5e8',
      input: '#181c26', inputBorder: '#2e3444', inputFocus: '#2b8dd6', shadow: '#00000040', overlay: '#080c14cc',
    }
  },
  {
    id: 'combate',
    name: 'Combate',
    colors: {
      bg: '#f4f6f8', surface: '#ffffff', surfaceHover: '#eaf0f6', border: '#d8dfe8',
      text: '#141e2c', textMuted: '#556478', textLight: '#76889c', heading: '#0c1624',
      accent: '#0b6fb8', accentLight: '#4a9dd6', accentBg: '#d4e5f5', accentText: '#085690',
      success: '#2e6e40', successBg: '#e0f2e6', error: '#b03a3a', errorBg: '#fdeaea',
      hero: '#152238', heroText: '#e8f0f6', heroMuted: '#b8c8db', heroAccent: '#4a9dd6',
      sidebar: '#f8fafb', sidebarBorder: '#e2e9f2', sidebarHover: '#eaf0f6', sidebarActive: '#d6e4f5', sidebarActiveText: '#085690',
      input: '#fbfcfe', inputBorder: '#d2dce7', inputFocus: '#0b6fb8', shadow: '#141e2c12', overlay: '#0c162466',
    }
  },
  {
    id: 'combate-dark',
    name: 'Combate Oscuro',
    colors: {
      bg: '#0e1219', surface: '#1a1f29', surfaceHover: '#252b38', border: '#303748',
      text: '#e6ecf2', textMuted: '#8492a6', textLight: '#606d82', heading: '#f0f4f8',
      accent: '#2894d8', accentLight: '#64b2e6', accentBg: '#162840', accentText: '#64b2e6',
      success: '#40cc6e', successBg: '#122a1e', error: '#e55e5e', errorBg: '#2c1c1c',
      hero: '#060a12', heroText: '#dce4ec', heroMuted: '#7e8ea5', heroAccent: '#64b2e6',
      sidebar: '#12161e', sidebarBorder: '#1a1f29', sidebarHover: '#252b38', sidebarActive: '#162840', sidebarActiveText: '#64b2e6',
      input: '#161a24', inputBorder: '#303748', inputFocus: '#2894d8', shadow: '#00000040', overlay: '#060a12cc',
    }
  },
  {
    id: 'decision',
    name: 'Decisión',
    colors: {
      bg: '#f7f8f9', surface: '#ffffff', surfaceHover: '#eff2f6', border: '#e0e5ec',
      text: '#1a2330', textMuted: '#5f6d80', textLight: '#808e9e', heading: '#111a26',
      accent: '#005696', accentLight: '#3d85c0', accentBg: '#d2e3f2', accentText: '#004070',
      success: '#346e44', successBg: '#e2f2e8', error: '#a83a3e', errorBg: '#fae8e8',
      hero: '#1c2838', heroText: '#eaf0f6', heroMuted: '#c4d0de', heroAccent: '#3d85c0',
      sidebar: '#fafbfc', sidebarBorder: '#e8ecf2', sidebarHover: '#eff2f6', sidebarActive: '#dce6f2', sidebarActiveText: '#004070',
      input: '#fcfdfe', inputBorder: '#dae0e8', inputFocus: '#005696', shadow: '#1a233012', overlay: '#111a2666',
    }
  },
  {
    id: 'sumision',
    name: 'Sumisión',
    colors: {
      bg: '#f3f8f6', surface: '#ffffff', surfaceHover: '#e8f2ee', border: '#d2e4dd',
      text: '#152520', textMuted: '#4d6e64', textLight: '#6a8a80', heading: '#0c1c18',
      accent: '#00b59c', accentLight: '#5cd4c2', accentBg: '#d4f0ea', accentText: '#008a76',
      success: '#2a6e44', successBg: '#dff2e6', error: '#b43a3a', errorBg: '#faebeb',
      hero: '#143028', heroText: '#e6f4ef', heroMuted: '#b0d5c8', heroAccent: '#5cd4c2',
      sidebar: '#f7fbf9', sidebarBorder: '#e2ede8', sidebarHover: '#e8f2ee', sidebarActive: '#d6ede4', sidebarActiveText: '#008a76',
      input: '#fafdfc', inputBorder: '#cedfd8', inputFocus: '#00b59c', shadow: '#15252012', overlay: '#0c1c1866',
    }
  },
  {
    id: 'sumision-dark',
    name: 'Sumisión Oscuro',
    colors: {
      bg: '#101816', surface: '#1c2420', surfaceHover: '#26302c', border: '#30403a',
      text: '#e2ede8', textMuted: '#7e9e92', textLight: '#5c7a6e', heading: '#ecf5f0',
      accent: '#00c6ab', accentLight: '#5cdfc8', accentBg: '#0a2a22', accentText: '#5cdfc8',
      success: '#3ac96a', successBg: '#102820', error: '#e86060', errorBg: '#281c1c',
      hero: '#0a1210', heroText: '#dce8e2', heroMuted: '#7a9a8e', heroAccent: '#5cdfc8',
      sidebar: '#141c18', sidebarBorder: '#1c2420', sidebarHover: '#26302c', sidebarActive: '#0a2a22', sidebarActiveText: '#5cdfc8',
      input: '#181e1a', inputBorder: '#30403a', inputFocus: '#00c6ab', shadow: '#00000040', overlay: '#0a1210cc',
    }
  },
  {
    id: 'golpe',
    name: 'Golpe',
    colors: {
      bg: '#f2f7f5', surface: '#ffffff', surfaceHover: '#e7f1ed', border: '#d0e2db',
      text: '#16241e', textMuted: '#4d6c60', textLight: '#6c8a7e', heading: '#0e1c16',
      accent: '#00a890', accentLight: '#4eccb4', accentBg: '#cfece4', accentText: '#007f6c',
      success: '#287040', successBg: '#def2e4', error: '#b03e3e', errorBg: '#fae8e8',
      hero: '#122a20', heroText: '#e4f2ec', heroMuted: '#aed4c4', heroAccent: '#4eccb4',
      sidebar: '#f6faf8', sidebarBorder: '#ddebe4', sidebarHover: '#e7f1ed', sidebarActive: '#d2eae0', sidebarActiveText: '#007f6c',
      input: '#fafdfb', inputBorder: '#ccddd4', inputFocus: '#00a890', shadow: '#16241e12', overlay: '#0e1c1666',
    }
  },
  {
    id: 'golpe-dark',
    name: 'Golpe Oscuro',
    colors: {
      bg: '#0f1614', surface: '#1a2420', surfaceHover: '#24302c', border: '#2e3e38',
      text: '#e0ece6', textMuted: '#7a9c8e', textLight: '#587a6c', heading: '#eaf4ee',
      accent: '#00ba9c', accentLight: '#52d4ba', accentBg: '#082820', accentText: '#52d4ba',
      success: '#38c868', successBg: '#0e281e', error: '#e65e5e', errorBg: '#261a1a',
      hero: '#08100e', heroText: '#dae8e2', heroMuted: '#76988a', heroAccent: '#52d4ba',
      sidebar: '#131a18', sidebarBorder: '#1a2420', sidebarHover: '#24302c', sidebarActive: '#082820', sidebarActiveText: '#52d4ba',
      input: '#161e1a', inputBorder: '#2e3e38', inputFocus: '#00ba9c', shadow: '#00000040', overlay: '#08100ecc',
    }
  },
  {
    id: 'esquina',
    name: 'Esquina',
    colors: {
      bg: '#f5f8f7', surface: '#ffffff', surfaceHover: '#ecf2f0', border: '#d8e4e0',
      text: '#1a2622', textMuted: '#5a7068', textLight: '#7a9088', heading: '#101c18',
      accent: '#2ec4b6', accentLight: '#78dad0', accentBg: '#daf2ee', accentText: '#20998e',
      success: '#306e48', successBg: '#e0f2e8', error: '#aa3e3e', errorBg: '#fae8e8',
      hero: '#1c302a', heroText: '#e8f4f0', heroMuted: '#bcd5cc', heroAccent: '#78dad0',
      sidebar: '#f8fbfa', sidebarBorder: '#e2ede8', sidebarHover: '#ecf2f0', sidebarActive: '#ddefe8', sidebarActiveText: '#20998e',
      input: '#fbfdfc', inputBorder: '#d2e0da', inputFocus: '#2ec4b6', shadow: '#1a262212', overlay: '#101c1866',
    }
  },
  {
    id: 'nocaut',
    name: 'Nocaut',
    colors: {
      bg: '#faf5f4', surface: '#ffffff', surfaceHover: '#f5ecea', border: '#e8d8d4',
      text: '#281a18', textMuted: '#70504c', textLight: '#8e6e6a', heading: '#1c0e0c',
      accent: '#c44a3a', accentLight: '#e88576', accentBg: '#fae0dc', accentText: '#9a3024',
      success: '#386830', successBg: '#e4f0de', error: '#a83834', errorBg: '#fce8e6',
      hero: '#3a1c18', heroText: '#f8ecea', heroMuted: '#d8bcb6', heroAccent: '#e88576',
      sidebar: '#fcf8f7', sidebarBorder: '#efe0dc', sidebarHover: '#f5ecea', sidebarActive: '#f5deda', sidebarActiveText: '#9a3024',
      input: '#fdfbfa', inputBorder: '#e4d2ce', inputFocus: '#c44a3a', shadow: '#281a1812', overlay: '#1c0e0c66',
    }
  },
  {
    id: 'cinturon',
    name: 'Cinturón',
    colors: {
      bg: '#fdfaf4', surface: '#ffffff', surfaceHover: '#faf4e4', border: '#ead8a8',
      text: '#241a08', textMuted: '#6a5428', textLight: '#8a7448', heading: '#180e02',
      accent: '#c4900a', accentLight: '#e0b840', accentBg: '#fcf0c8', accentText: '#966e04',
      success: '#3e682a', successBg: '#e8f2dc', error: '#a03e2e', errorBg: '#fce6e0',
      hero: '#3a2808', heroText: '#fcf2e0', heroMuted: '#d8c898', heroAccent: '#e0b840',
      sidebar: '#fefcf8', sidebarBorder: '#f0e2c0', sidebarHover: '#faf4e4', sidebarActive: '#f8eac8', sidebarActiveText: '#966e04',
      input: '#fefdf8', inputBorder: '#e5d4a0', inputFocus: '#c4900a', shadow: '#241a0812', overlay: '#180e0266',
    }
  },
  {
    id: 'cinturon-dark',
    name: 'Cinturón Oscuro',
    colors: {
      bg: '#18140c', surface: '#24201a', surfaceHover: '#302a22', border: '#403a30',
      text: '#efe8d8', textMuted: '#a09880', textLight: '#7a7260', heading: '#f5f0e5',
      accent: '#d4a520', accentLight: '#e8c860', accentBg: '#2a1e0a', accentText: '#e8c860',
      success: '#48c868', successBg: '#1a2818', error: '#e86860', errorBg: '#2a1c18',
      hero: '#0c0a06', heroText: '#e8e0d0', heroMuted: '#a09880', heroAccent: '#e8c860',
      sidebar: '#1c1814', sidebarBorder: '#24201a', sidebarHover: '#302a22', sidebarActive: '#2a1e0a', sidebarActiveText: '#e8c860',
      input: '#201c16', inputBorder: '#403a30', inputFocus: '#d4a520', shadow: '#00000040', overlay: '#0c0a06cc',
    }
  },
  {
    id: 'guardia',
    name: 'Guardia',
    colors: {
      bg: '#f9f6f2', surface: '#ffffff', surfaceHover: '#f2ede5', border: '#e5dccd',
      text: '#262016', textMuted: '#665840', textLight: '#867860', heading: '#1a140a',
      accent: '#8e7030', accentLight: '#b89a58', accentBg: '#f0e6d0', accentText: '#6a5220',
      success: '#3a682e', successBg: '#e6f2de', error: '#a04032', errorBg: '#fae6e2',
      hero: '#2e2414', heroText: '#f2ece0', heroMuted: '#d4c8a8', heroAccent: '#b89a58',
      sidebar: '#fbfaf6', sidebarBorder: '#ece4d6', sidebarHover: '#f2ede5', sidebarActive: '#ece0cc', sidebarActiveText: '#6a5220',
      input: '#fdfcfa', inputBorder: '#e0d8c8', inputFocus: '#8e7030', shadow: '#26201612', overlay: '#1a140a66',
    }
  },
  {
    id: 'cuadrilatero',
    name: 'Cuadrilátero',
    colors: {
      bg: '#18141c', surface: '#24202a', surfaceHover: '#302a38', border: '#42384e',
      text: '#ece6f2', textMuted: '#a098b0', textLight: '#786e88', heading: '#f2eef8',
      accent: '#9a50d0', accentLight: '#c088e8', accentBg: '#261838', accentText: '#c088e8',
      success: '#42c868', successBg: '#12281c', error: '#e66062', errorBg: '#281a1c',
      hero: '#0e0a14', heroText: '#e4def0', heroMuted: '#9a90a8', heroAccent: '#c088e8',
      sidebar: '#1c1820', sidebarBorder: '#24202a', sidebarHover: '#302a38', sidebarActive: '#261838', sidebarActiveText: '#c088e8',
      input: '#201c24', inputBorder: '#42384e', inputFocus: '#9a50d0', shadow: '#00000040', overlay: '#0e0a14cc',
    }
  },
  {
    id: 'campana',
    name: 'Campana',
    colors: {
      bg: '#161412', surface: '#22201c', surfaceHover: '#2e2a26', border: '#3e3a34',
      text: '#ece6e0', textMuted: '#a09890', textLight: '#7a7268', heading: '#f2eee8',
      accent: '#c87840', accentLight: '#e8a878', accentBg: '#281e14', accentText: '#e8a878',
      success: '#46c86a', successBg: '#18281c', error: '#e8625e', errorBg: '#281a18',
      hero: '#0a0806', heroText: '#e6e0d8', heroMuted: '#a09888', heroAccent: '#e8a878',
      sidebar: '#1a1814', sidebarBorder: '#22201c', sidebarHover: '#2e2a26', sidebarActive: '#281e14', sidebarActiveText: '#e8a878',
      input: '#1e1c18', inputBorder: '#3e3a34', inputFocus: '#c87840', shadow: '#00000040', overlay: '#0a0806cc',
    }
  },
  {
    id: 'coral',
    name: 'Coral',
    colors: {
      bg: '#fdf5f4', surface: '#ffffff', surfaceHover: '#faeae8', border: '#e8d4d2',
      text: '#2a1816', textMuted: '#765048', textLight: '#947068', heading: '#1e0e0c',
      accent: '#d46050', accentLight: '#f08478', accentBg: '#fadcd8', accentText: '#a83a2e',
      success: '#387030', successBg: '#e2f2de', error: '#ac3838', errorBg: '#fce6e6',
      hero: '#381c1a', heroText: '#f8eae8', heroMuted: '#d8bcb8', heroAccent: '#f08478',
      sidebar: '#fef8f7', sidebarBorder: '#efe0de', sidebarHover: '#faeae8', sidebarActive: '#f5dcd8', sidebarActiveText: '#a83a2e',
      input: '#fdfbfa', inputBorder: '#e4d0ce', inputFocus: '#d46050', shadow: '#2a181612', overlay: '#1e0e0c66',
    }
  },
  {
    id: 'terra',
    name: 'Terracota',
    colors: {
      bg: '#faf6f2', surface: '#ffffff', surfaceHover: '#f2ece4', border: '#e5d8c8',
      text: '#281e14', textMuted: '#685a48', textLight: '#887a68', heading: '#1c1208',
      accent: '#b87040', accentLight: '#d49868', accentBg: '#f2e2d0', accentText: '#8a5028',
      success: '#3e6e30', successBg: '#e6f4de', error: '#a83e32', errorBg: '#fae6e0',
      hero: '#322016', heroText: '#f2e8de', heroMuted: '#d4c4b0', heroAccent: '#d49868',
      sidebar: '#fcfaf6', sidebarBorder: '#ece0d4', sidebarHover: '#f2ece4', sidebarActive: '#ede0d0', sidebarActiveText: '#8a5028',
      input: '#fefcf8', inputBorder: '#e0d4c4', inputFocus: '#b87040', shadow: '#281e1412', overlay: '#1c120866',
    }
  },
  {
    id: 'tormenta',
    name: 'Tormenta',
    colors: {
      bg: '#12161e', surface: '#1e222c', surfaceHover: '#2a2e3a', border: '#363c4a',
      text: '#e2e6f0', textMuted: '#8a90a2', textLight: '#666c80', heading: '#eef0f6',
      accent: '#5a80c0', accentLight: '#8ca8e0', accentBg: '#1a2840', accentText: '#8ca8e0',
      success: '#40c868', successBg: '#14281c', error: '#e06262', errorBg: '#281a1c',
      hero: '#080c14', heroText: '#dce2ee', heroMuted: '#8a92a8', heroAccent: '#8ca8e0',
      sidebar: '#161a22', sidebarBorder: '#1e222c', sidebarHover: '#2a2e3a', sidebarActive: '#1a2840', sidebarActiveText: '#8ca8e0',
      input: '#1a1e28', inputBorder: '#363c4a', inputFocus: '#5a80c0', shadow: '#00000040', overlay: '#080c14cc',
    }
  },
  {
    id: 'cerezo',
    name: 'Cerezo',
    colors: {
      bg: '#fdf5f8', surface: '#ffffff', surfaceHover: '#faeaf0', border: '#e8d4de',
      text: '#2a1620', textMuted: '#704858', textLight: '#906878', heading: '#1e0c16',
      accent: '#c05078', accentLight: '#e080a0', accentBg: '#f8d8e4', accentText: '#983058',
      success: '#3a6830', successBg: '#e6f2de', error: '#a83c3c', errorBg: '#fce6e6',
      hero: '#381828', heroText: '#f6e8ee', heroMuted: '#d8bcc8', heroAccent: '#e080a0',
      sidebar: '#fef8fa', sidebarBorder: '#efe0e6', sidebarHover: '#faeaf0', sidebarActive: '#f4d8e4', sidebarActiveText: '#983058',
      input: '#fdfbfc', inputBorder: '#e4ced8', inputFocus: '#c05078', shadow: '#2a162012', overlay: '#1e0c1666',
    }
  },
  {
    id: 'grafito',
    name: 'Grafito',
    colors: {
      bg: '#14161a', surface: '#202226', surfaceHover: '#2a2c32', border: '#383a40',
      text: '#e4e6ea', textMuted: '#909296', textLight: '#6a6c72', heading: '#f0f2f6',
      accent: '#7a8aa0', accentLight: '#a8b4c8', accentBg: '#1e242e', accentText: '#a8b4c8',
      success: '#44c668', successBg: '#16281c', error: '#dc6262', errorBg: '#281c1c',
      hero: '#0a0c10', heroText: '#dcdee4', heroMuted: '#90949a', heroAccent: '#a8b4c8',
      sidebar: '#181a1e', sidebarBorder: '#202226', sidebarHover: '#2a2c32', sidebarActive: '#1e242e', sidebarActiveText: '#a8b4c8',
      input: '#1c1e22', inputBorder: '#383a40', inputFocus: '#7a8aa0', shadow: '#00000040', overlay: '#0a0c10cc',
    }
  },
  {
    id: 'nieve',
    name: 'Nieve',
    colors: {
      bg: '#f8f9fb', surface: '#ffffff', surfaceHover: '#f0f2f6', border: '#e2e4ea',
      text: '#1a1e26', textMuted: '#5e6270', textLight: '#808490', heading: '#12151c',
      accent: '#506080', accentLight: '#8090b0', accentBg: '#e4e8f2', accentText: '#3a4868',
      success: '#366a40', successBg: '#e2f0e6', error: '#9e3e3e', errorBg: '#fae8e8',
      hero: '#1e2230', heroText: '#eef0f6', heroMuted: '#c0c4d4', heroAccent: '#8090b0',
      sidebar: '#fcfcfe', sidebarBorder: '#eaecf2', sidebarHover: '#f0f2f6', sidebarActive: '#e8ecf4', sidebarActiveText: '#3a4868',
      input: '#fdfdfe', inputBorder: '#dce0e8', inputFocus: '#506080', shadow: '#1a1e2612', overlay: '#12151c66',
    }
  },
  {
    id: 'bronce',
    name: 'Bronce',
    colors: {
      bg: '#fbf8f4', surface: '#ffffff', surfaceHover: '#f6f0e8', border: '#e8dcc8',
      text: '#261e12', textMuted: '#685838', textLight: '#887858', heading: '#1a1208',
      accent: '#a07030', accentLight: '#c89858', accentBg: '#f2e6d0', accentText: '#785020',
      success: '#3c6a30', successBg: '#e6f0de', error: '#a23e30', errorBg: '#fae6e0',
      hero: '#2e220e', heroText: '#f4ece0', heroMuted: '#d4c8a8', heroAccent: '#c89858',
      sidebar: '#fcfaf6', sidebarBorder: '#eee2d0', sidebarHover: '#f6f0e8', sidebarActive: '#f0e4c8', sidebarActiveText: '#785020',
      input: '#fefcfa', inputBorder: '#e2d6c0', inputFocus: '#a07030', shadow: '#261e1212', overlay: '#1a120866',
    }
  },
  {
    id: 'barrido',
    name: 'Barrido',
    colors: {
      bg: '#f4f8f0', surface: '#ffffff', surfaceHover: '#ebf2e4', border: '#d4e2c8',
      text: '#182410', textMuted: '#4e6840', textLight: '#6e8860', heading: '#101c08',
      accent: '#78a030', accentLight: '#a0c858', accentBg: '#e6f2d0', accentText: '#587820',
      success: '#3e7028', successBg: '#e4f2d8', error: '#a43e30', errorBg: '#fce8e2',
      hero: '#202e14', heroText: '#ecf4e4', heroMuted: '#c8d8b0', heroAccent: '#a0c858',
      sidebar: '#f8faf4', sidebarBorder: '#e2ead4', sidebarHover: '#ebf2e4', sidebarActive: '#e0eed0', sidebarActiveText: '#587820',
      input: '#fcfdfa', inputBorder: '#cedcc0', inputFocus: '#78a030', shadow: '#18241012', overlay: '#101c0866',
    }
  },
  {
    id: 'contragolpe',
    name: 'Contragolpe',
    colors: {
      bg: '#14181a', surface: '#202428', surfaceHover: '#2a2e34', border: '#3a3e44',
      text: '#e2e6e8', textMuted: '#8e9298', textLight: '#686c72', heading: '#eef0f4',
      accent: '#507880', accentLight: '#80a0a8', accentBg: '#182429', accentText: '#80a0a8',
      success: '#42c666', successBg: '#14281a', error: '#dc6262', errorBg: '#281a1a',
      hero: '#0a0c10', heroText: '#dce0e4', heroMuted: '#8e9298', heroAccent: '#80a0a8',
      sidebar: '#181c20', sidebarBorder: '#202428', sidebarHover: '#2a2e34', sidebarActive: '#182429', sidebarActiveText: '#80a0a8',
      input: '#1c2024', inputBorder: '#3a3e44', inputFocus: '#507880', shadow: '#00000040', overlay: '#0a0c10cc',
    }
  },
  {
    id: 'candado',
    name: 'Candado',
    colors: {
      bg: '#f0f4f7', surface: '#ffffff', surfaceHover: '#e4ecf2', border: '#cedae4',
      text: '#14222e', textMuted: '#486070', textLight: '#688090', heading: '#0c1a26',
      accent: '#3090b8', accentLight: '#68b8d8', accentBg: '#d4eaf5', accentText: '#206c8e',
      success: '#306c40', successBg: '#e0f0e4', error: '#a63c3a', errorBg: '#fae8e8',
      hero: '#162838', heroText: '#e6eff5', heroMuted: '#b8ccda', heroAccent: '#68b8d8',
      sidebar: '#f4f8fa', sidebarBorder: '#dce4ee', sidebarHover: '#e4ecf2', sidebarActive: '#d2e4f2', sidebarActiveText: '#206c8e',
      input: '#fafcfd', inputBorder: '#c8d6e0', inputFocus: '#3090b8', shadow: '#14222e12', overlay: '#0c1a2666',
    }
  },
  {
    id: 'mma',
    name: 'MMA Claro',
    colors: {
      bg: '#f0f4f8', surface: '#ffffff', surfaceHover: '#e6edf4', border: '#d0dce8',
      text: '#102028', textMuted: '#486470', textLight: '#688490', heading: '#08141c',
      accent: '#0062a8', accentLight: '#2890cc', accentBg: '#d6e6f5', accentText: '#004a82',
      success: '#00a878', successBg: '#ccf0e2', error: '#b8403c', errorBg: '#fae8e6',
      hero: '#132a38', heroText: '#e4eff5', heroMuted: '#b0c8d8', heroAccent: '#00b59c',
      sidebar: '#f4f7fa', sidebarBorder: '#dce4ee', sidebarHover: '#e6edf4', sidebarActive: '#d0e2f2', sidebarActiveText: '#004a82',
      input: '#f8fafc', inputBorder: '#ccd8e4', inputFocus: '#0062a8', shadow: '#10202810', overlay: '#08141c66',
    }
  },
  {
    id: 'mma-dark',
    name: 'MMA Oscuro',
    colors: {
      bg: '#0c141a', surface: '#182028', surfaceHover: '#222c36', border: '#2e3844',
      text: '#e2eaf0', textMuted: '#8496a4', textLight: '#5c6e7c', heading: '#ecf2f6',
      accent: '#2894d8', accentLight: '#64b8e8', accentBg: '#14243a', accentText: '#64b8e8',
      success: '#00c48a', successBg: '#0a2820', error: '#e8605e', errorBg: '#281a1a',
      hero: '#060e14', heroText: '#dce6ee', heroMuted: '#7e909e', heroAccent: '#00c6ab',
      sidebar: '#101820', sidebarBorder: '#182028', sidebarHover: '#222c36', sidebarActive: '#14243a', sidebarActiveText: '#64b8e8',
      input: '#141c24', inputBorder: '#2e3844', inputFocus: '#2894d8', shadow: '#00000040', overlay: '#060e14cc',
    }
  },
];
