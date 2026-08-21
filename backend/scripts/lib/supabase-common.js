// Lógica compartida entre los scripts de importación y sincronización desde el
// Supabase público del municipio hacia ligas-deportivas-v2.
//
// Incluye: constantes de conexión, helpers de normalización de nombres, mapa de
// alias/canónico de clubes y categorías, y fetch del origen.

const SUPABASE_URL = 'https://yvwazzwwlpkfhyefnqfo.supabase.co';
const SUPABASE_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl2d2F6end3bHBrZmh5ZWZucWZvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1MTE0NjIsImV4cCI6MjA5NDA4NzQ2Mn0.3Eg9XRcZr6y98vG4rI2c0Sv-W6gQdoadzeDu7JgHRiQ';

const CLUB_LOGO_MIN = 200;
const CLUB_LOGO_MAX = 500;
const MAX_LOGO_BYTES = 512 * 1024;

// Clubes ya existentes en v2: nombre en origen (sin sufijo FEM) -> nombre en v2.
const EXISTING_CLUB_ALIAS = {
  'Deportivo Soler': 'Club Social y Deportivo Soler',
  'Dep. Soler': 'Club Social y Deportivo Soler',
  'Def. Soler': 'Club Social y Deportivo Soler',
  'Torino JR': 'Torino',
  'El Torino': 'Torino',
  'Mundialito Camp': 'Mundialito',
  Fátima: 'Fatima',
  'Dep. La Quinta': 'La Quinta',
  'Baby Olivos': 'Deportivo Baby Olivos',
  Malvinense: 'Deportivo Malvinense',
  'Malvinense JR': 'Deportivo Malvinense',
  'Dep. Guadalupe': 'Guadalupe JR',
  // Renombres hechos en v2 (el origen usa la forma abreviada).
  'Deportivo VM': 'Deportivo Villa de Mayo',
  'Unión Vecinal VM': 'Unión Vecinal Villa de Mayo',
  'SF Los Olivos': 'Sociedad de Fomento Los Olivos',
};

// Variantes de nombre de un mismo club (todas nuevas en v2) -> nombre canónico.
const CANONICAL_NAME = {
  'SF El Ombú': 'El Ombu',
  'Huracanes VDM': 'Huracanes de VDM',
  'D. Barrio Olivos': 'Dep. Barrio Olivos',
  Barca: 'El Barca FC',
  'Dep Polvorines': 'Dep. Polvorines',
};

// Nombre de categoría en el origen -> nombre de categoría en v2.
const CATEGORY_NAME_OVERRIDE = {
  2020: '2020/21',
  'SUB 9': 'Sub-9',
  'SUB 11': 'Sub-11',
  'SUB 13': 'Sub-13',
  'SUB 15': 'Sub-15',
  'SUB 17': 'Sub-17',
  '1° FEM': 'Primera',
  DAMAS: 'Damas',
};

function slugify(value) {
  return value
    .toLowerCase()
    .trim()
    .normalize('NFD')
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-');
}

function norm(s) {
  return s
    .toLowerCase()
    .normalize('NFD')
    .replace(/[^a-z0-9]/g, '');
}

function stripFem(name) {
  return name.replace(/\s+FEM\s*$/i, '').trim();
}

// Resuelve el nombre de club de v2 a partir del nombre de equipo del origen.
function resolveCanonicalName(teamName) {
  const baseName = stripFem(teamName);
  const canonical = CANONICAL_NAME[baseName] ?? baseName;
  const aliasName = EXISTING_CLUB_ALIAS[canonical];
  return { baseName, canonical, aliasName };
}

// Construye un índice sourceTeamId (uuid del origen) -> club (objeto con id).
// Los clubes de v2 almacenan en `sourceTeamIds` (Json[]) los ids de los equipos
// del origen que les corresponden; esto permite vincular por id y no por nombre.
function indexClubsBySourceTeamId(clubs) {
  const index = new Map();
  for (const c of clubs) {
    if (Array.isArray(c.sourceTeamIds)) {
      for (const sid of c.sourceTeamIds) {
        if (sid) index.set(sid, c);
      }
    }
  }
  return index;
}

async function supa(resource) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${resource}`, {
    headers: { apikey: SUPABASE_KEY, Authorization: `Bearer ${SUPABASE_KEY}` },
  });
  if (!res.ok) {
    throw new Error(`Supabase ${resource}: ${res.status} ${await res.text()}`);
  }
  return res.json();
}

// Trae todo lo necesario de una liga del origen identificada por subcadena del nombre.
async function fetchSourceLeague(sourceLeagueSubstring) {
  const leagues = await supa('leagues?select=*');
  const sourceLeague = leagues.find((l) => l.name.includes(sourceLeagueSubstring));
  if (!sourceLeague) {
    throw new Error(`No se encontró la liga "${sourceLeagueSubstring}" en el origen.`);
  }

  const [categories, leagueTeams, teams, matches] = await Promise.all([
    supa(`categories?league_id=eq.${sourceLeague.id}&select=*`),
    supa(`league_teams?league_id=eq.${sourceLeague.id}&select=*`),
    supa('teams?select=id,name,short_name,city,logo_url,colors'),
    supa(`matches?league_id=eq.${sourceLeague.id}&select=*`),
  ]);

  return { sourceLeague, categories, leagueTeams, teams, matches };
}

// Mapea categorías del origen a las TournamentCategory de v2 del torneo.
// Devuelve sourceCatToV2 (id categoría origen -> TournamentCategory) y
// v2TcToSourceCat (id TournamentCategory -> id categoría origen).
function mapCategories(sourceCategories, v2TournamentCategories) {
  const v2TcByName = new Map(v2TournamentCategories.map((tc) => [tc.category.name, tc]));
  const sourceCatToV2 = new Map();
  const v2TcToSourceCat = new Map();
  for (const c of sourceCategories) {
    const v2Name = CATEGORY_NAME_OVERRIDE[c.name] ?? c.name;
    const tc = v2TcByName.get(v2Name);
    if (tc) {
      sourceCatToV2.set(c.id, tc);
      v2TcToSourceCat.set(tc.id, c.id);
    }
  }
  return { sourceCatToV2, v2TcToSourceCat };
}

// Recalcula la tabla de posiciones de una zona + categoría (misma lógica que
// StandingsService.recalculateForCategory del backend).
async function recalcStandings(prisma, zoneId, tournamentCategoryId, tournament) {
  const clubAssignments = await prisma.clubZone.findMany({
    where: { zoneId },
    select: { clubId: true },
  });
  const clubIds = clubAssignments.map((a) => a.clubId);

  const matchCategories = await prisma.matchCategory.findMany({
    where: { tournamentCategoryId, closedAt: { not: null }, match: { zoneId } },
    include: { match: true },
  });

  const acc = new Map();
  const ensure = (clubId) => {
    if (!acc.has(clubId)) {
      acc.set(clubId, {
        clubId,
        played: 0,
        wins: 0,
        draws: 0,
        losses: 0,
        goalsFor: 0,
        goalsAgainst: 0,
      });
    }
    return acc.get(clubId);
  };
  for (const clubId of clubIds) ensure(clubId);

  for (const entry of matchCategories) {
    const homeClubId = entry.match.homeClubId;
    const awayClubId = entry.match.awayClubId;
    if (!homeClubId || !awayClubId) continue;
    const home = ensure(homeClubId);
    const away = ensure(awayClubId);
    home.played += 1;
    away.played += 1;
    home.goalsFor += entry.homeScore;
    home.goalsAgainst += entry.awayScore;
    away.goalsFor += entry.awayScore;
    away.goalsAgainst += entry.homeScore;
    if (entry.homeScore > entry.awayScore) {
      home.wins += 1;
      away.losses += 1;
    } else if (entry.homeScore < entry.awayScore) {
      away.wins += 1;
      home.losses += 1;
    } else {
      home.draws += 1;
      away.draws += 1;
    }
  }

  await prisma.categoryStanding.deleteMany({ where: { zoneId, tournamentCategoryId } });
  const standings = Array.from(acc.values()).map((row) => ({
    zoneId,
    tournamentCategoryId,
    clubId: row.clubId,
    played: row.played,
    wins: row.wins,
    draws: row.draws,
    losses: row.losses,
    goalsFor: row.goalsFor,
    goalsAgainst: row.goalsAgainst,
    points:
      row.wins * tournament.pointsWin +
      row.draws * tournament.pointsDraw +
      row.losses * tournament.pointsLoss,
    goalDifference: row.goalsFor - row.goalsAgainst,
  }));
  if (standings.length) {
    await prisma.categoryStanding.createMany({ data: standings });
  }
}

module.exports = {
  SUPABASE_URL,
  SUPABASE_KEY,
  CLUB_LOGO_MIN,
  CLUB_LOGO_MAX,
  MAX_LOGO_BYTES,
  EXISTING_CLUB_ALIAS,
  CANONICAL_NAME,
  CATEGORY_NAME_OVERRIDE,
  slugify,
  norm,
  stripFem,
  resolveCanonicalName,
  indexClubsBySourceTeamId,
  supa,
  fetchSourceLeague,
  mapCategories,
  recalcStandings,
};
