export interface MatchFlyerTokenDto {
  token: string;
  description: string;
  example?: string;
  usage?: string;
}

export const MATCH_FLYER_TOKEN_DEFINITIONS: MatchFlyerTokenDto[] = [
  {
    token: 'site.title',
    description: 'Nombre configurado para el sitio.',
    example: 'Ligas Deportivas',
  },
  {
    token: 'tournament.name',
    description: 'Nombre del torneo al que pertenece el partido.',
    example: 'Apertura 2024',
  },
  {
    token: 'zone.name',
    description: 'Nombre de la zona del torneo.',
    example: 'Zona Norte',
  },
  {
    token: 'match.summary',
    description: 'Resumen corto (fecha, rueda y número de fecha).',
    example: '02/06 - Rueda 1 - Fecha 5',
  },
  {
    token: 'match.roundLabel',
    description: 'Nombre de la rueda del partido.',
    example: 'Rueda 1',
  },
  {
    token: 'match.matchdayLabel',
    description: 'Número de fecha del fixture.',
    example: 'Fecha 5',
  },
  {
    token: 'match.dateLabel',
    description: 'Fecha completa del partido (dd/mm/yyyy).',
    example: '02/06/2024',
  },
  {
    token: 'match.home.name',
    description: 'Nombre del club local.',
    example: 'Club Atlético Local',
  },
  {
    token: 'match.away.name',
    description: 'Nombre del club visitante.',
    example: 'Club Deportivo Visitante',
  },
  {
    token: 'address.line',
    description: 'Dirección o referencia del estadio.',
    example: 'Club Atlético Local - Dirección a confirmar',
  },
  {
    token: 'categories',
    description: 'Listado de categorías y horarios.',
    usage: '{{#categories}}{{time}} - {{name}}\n{{/categories}}',
  },
  {
    token: 'assets.background',
    description: 'Imagen de fondo en formato data URI.',
    usage: '<image href="{{{assets.background}}}" ... />',
  },
  {
    token: 'assets.homeLogo',
    description: 'Logo del club local en formato data URI (si está disponible).',
    usage: '<image href="{{{assets.homeLogo}}}" ... />',
  },
  {
    token: 'assets.awayLogo',
    description: 'Logo del club visitante en formato data URI (si está disponible).',
    usage: '<image href="{{{assets.awayLogo}}}" ... />',
  },
  {
    token: 'custom.*',
    description: 'Tokens adicionales definidos en la configuración JSON (tokenConfig).',
  },
];
