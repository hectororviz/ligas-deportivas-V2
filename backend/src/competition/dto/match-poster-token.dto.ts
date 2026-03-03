export interface MatchPosterTokenDto {
  token: string;
  description: string;
  example?: string;
}

export const MATCH_POSTER_TOKEN_DEFINITIONS: MatchPosterTokenDto[] = [
  {
    token: 'league.name',
    description: 'Nombre de la liga.',
    example: 'Liga Metropolitana',
  },
  {
    token: 'tournament.name',
    description: 'Nombre del torneo.',
    example: 'Apertura 2024',
  },
  {
    token: 'match.round',
    description: 'Rueda del partido.',
    example: 'Rueda 1',
  },
  {
    token: 'match.matchday',
    description: 'Número de fecha del fixture.',
    example: '5',
  },
  {
    token: 'match.date',
    description: 'Fecha del partido (dd/mm/yyyy).',
    example: '02/06/2024',
  },
  {
    token: 'match.dayName',
    description: 'Nombre del día de la semana.',
    example: 'Sábado',
  },
  {
    token: 'tournament.timeSlots',
    description: 'Listado de horarios (categorías).',
    example: '09:00 Sub 12 · 10:30 Sub 14',
  },
  {
    token: 'homeClub.name',
    description: 'Nombre del club local.',
    example: 'Club Atlético Local',
  },
  {
    token: 'homeClub.address',
    description: 'Dirección de localía del club local.',
    example: 'Estadio Central · Av. Principal 123',
  },
  {
    token: 'awayClub.name',
    description: 'Nombre del club visitante.',
    example: 'Club Deportivo Visitante',
  },
  {
    token: 'venue.name',
    description: 'Nombre de la sede/estadio (si está disponible).',
  },
  {
    token: 'venue.address',
    description: 'Dirección de la sede/estadio (si está disponible).',
  },
  {
    token: 'homeClub.logoUrl',
    description: 'Logo del club local (data URI).',
  },
  {
    token: 'awayClub.logoUrl',
    description: 'Logo del club visitante (data URI).',
  },
];
