// Sincronizador de resultados desde el Supabase público del municipio hacia ligas-deportivas-v2.
//
// Relee el origen y actualiza en v2 los resultados que se van cargando en el otro sitio:
//  - Matchea cada partido del origen contra el Match de v2 por par ordenado (local, visitante),
//    con fallback a la localía invertida (invierte el score en ese caso).
//  - finalizado -> score + closedAt; no_presentaron / pendiente real -> PENDING (isPending).
//  - Sobrescribe siempre (el origen manda), pero omite escrituras idénticas (no-op).
//  - Partidos del origen sin correspondencia en v2 se avisan y se ignoran (no se crean).
//  - Recalcula el estado de los partidos tocados y las tablas de las categorías afectadas.
//
// Uso (dentro del contenedor backend):
//   node sync-supabase.js            # sincroniza todas las zonas
//   DRY_RUN=1 node sync-supabase.js  # muestra qué haría sin escribir

const { PrismaClient, MatchStatus } = require('@prisma/client');
const {
  norm,
  resolveCanonicalName,
  indexClubsBySourceTeamId,
  fetchSourceLeague,
  mapCategories,
  recalcStandings,
} = require('./lib/supabase-common');

const prisma = new PrismaClient();
const DRY_RUN = process.env.DRY_RUN === '1';

// Config de las zonas migradas: { source: subcadena liga origen, league, tournament, zone }.
const ZONES = [
  { source: 'Domingo Super Liga', league: 'Futbol Infantil (D)', tournament: 'Domingos', zone: 'Super Liga' },
  { source: 'Domingo Liga de Ascenso', league: 'Futbol Infantil (D)', tournament: 'Domingos', zone: 'Liga de Ascenso' },
  { source: 'Grupo 1', league: 'Liga de Futbol Femenino', tournament: 'Anual 2026', zone: 'Grupo 1' },
  { source: 'Grupo 2', league: 'Liga de Futbol Femenino', tournament: 'Anual 2026', zone: 'Grupo 2' },
  { source: 'Grupo 3', league: 'Liga de Futbol Femenino', tournament: 'Anual 2026', zone: 'Grupo 3' },
  { source: 'Grupo 4', league: 'Liga de Futbol Femenino', tournament: 'Anual 2026', zone: 'Grupo 4' },
  { source: 'zona "A"', league: 'Futbol Infantil (S)', tournament: 'Sabados', zone: 'Zona A' },
  { source: '"B1"', league: 'Futbol Infantil (S)', tournament: 'Sabados', zone: 'Zona B1' },
  { source: '"B2"', league: 'Futbol Infantil (S)', tournament: 'Sabados', zone: 'Zona B2' },
];

async function syncZone(cfg) {
  const v2Tournament = await prisma.tournament.findFirst({
    where: { name: cfg.tournament, league: { name: cfg.league } },
  });
  if (!v2Tournament) {
    console.log(`  ⚠ Torneo "${cfg.tournament}" / liga "${cfg.league}" no encontrado. Se omite.`);
    return null;
  }
  const zone = await prisma.zone.findFirst({
    where: { tournamentId: v2Tournament.id, name: cfg.zone },
  });
  if (!zone) {
    console.log(`  ⚠ Zona "${cfg.zone}" no encontrada. Se omite.`);
    return null;
  }

  const src = await fetchSourceLeague(cfg.source);

  // Clubes de v2 (solo lectura) -> índices por id de origen y por nombre normalizado.
  const allClubs = await prisma.club.findMany({
    select: { id: true, name: true, sourceTeamIds: true },
  });
  const clubByNormName = new Map(allClubs.map((c) => [norm(c.name), c]));
  const clubBySourceTeamId = indexClubsBySourceTeamId(allClubs);
  const teamById = new Map(src.teams.map((t) => [t.id, t]));
  const participatingIds = new Set(src.leagueTeams.map((lt) => lt.team_id));

  const clubMap = new Map();
  const missingTeams = [];
  for (const team of src.teams) {
    if (!participatingIds.has(team.id)) continue;
    const { canonical, aliasName } = resolveCanonicalName(team.name);
    let club = clubBySourceTeamId.get(team.id);
    if (!club) club = aliasName ? clubByNormName.get(norm(aliasName)) : undefined;
    if (!club) club = clubByNormName.get(norm(canonical));
    if (club) clubMap.set(team.id, club.id);
    else missingTeams.push(team.name);
  }

  const v2TournamentCategories = await prisma.tournamentCategory.findMany({
    where: { tournamentId: v2Tournament.id },
    include: { category: true },
  });
  const { sourceCatToV2 } = mapCategories(src.categories, v2TournamentCategories);

  // Índice de partidos de v2 por par ordenado (local, visitante).
  const v2Matches = await prisma.match.findMany({
    where: { zoneId: zone.id },
    select: { id: true, homeClubId: true, awayClubId: true },
  });
  const matchByPair = new Map();
  for (const m of v2Matches) matchByPair.set(`${m.homeClubId}|${m.awayClubId}`, m);

  // MatchCategory de v2 por (matchId, tournamentCategoryId).
  const v2Mc = await prisma.matchCategory.findMany({
    where: { match: { zoneId: zone.id } },
    select: { id: true, matchId: true, tournamentCategoryId: true, homeScore: true, awayScore: true, closedAt: true, isPending: true },
  });
  const mcByKey = new Map();
  for (const mc of v2Mc) mcByKey.set(`${mc.matchId}|${mc.tournamentCategoryId}`, mc);

  const now = new Date();
  let cargados = 0;
  let actualizados = 0;
  let pendientes = 0;
  let sinCambios = 0;
  let sinMatch = 0;
  let sinClub = 0;
  let sinCategoria = 0;

  const mcUpdates = []; // { id, data }
  const touchedMatches = new Set();
  const affectedCats = new Set(); // `${zoneId}|${tcId}`

  for (const m of src.matches) {
    if (!m.away_team_id) continue; // descanso (bye)

    const homeClub = clubMap.get(m.local_team_id);
    const awayClub = clubMap.get(m.away_team_id);
    if (!homeClub || !awayClub) {
      sinClub++;
      continue;
    }

    let match = matchByPair.get(`${homeClub}|${awayClub}`);
    let swapped = false;
    if (!match) {
      match = matchByPair.get(`${awayClub}|${homeClub}`);
      swapped = true;
    }
    if (!match) {
      sinMatch++;
      continue;
    }

    const tc = sourceCatToV2.get(m.category_id);
    if (!tc) {
      sinCategoria++;
      continue;
    }
    const mc = mcByKey.get(`${match.id}|${tc.id}`);
    if (!mc) {
      sinMatch++;
      continue;
    }

    const isFinalizado = m.status === 'finalizado';
    const isPendingSrc = m.status === 'no_presentaron' || m.status === 'pendiente';

    let newHome = 0;
    let newAway = 0;
    let newIsPending = false;
    let newClosed = false;
    if (isFinalizado) {
      newHome = swapped ? m.away_goals : m.local_goals;
      newAway = swapped ? m.local_goals : m.away_goals;
      newClosed = true;
    } else if (isPendingSrc) {
      newIsPending = true;
    } else {
      continue; // estado desconocido, se ignora
    }

    const curClosed = mc.closedAt != null;
    const unchanged =
      newHome === mc.homeScore &&
      newAway === mc.awayScore &&
      newIsPending === mc.isPending &&
      newClosed === curClosed;

    if (unchanged) {
      sinCambios++;
      continue;
    }

    if (newClosed && !curClosed) cargados++;
    else if (!newClosed && curClosed) pendientes++;
    else actualizados++;

    const data = {
      homeScore: newHome,
      awayScore: newAway,
      isPending: newIsPending,
      closedAt: newClosed ? (curClosed ? mc.closedAt : now) : null,
    };
    mcUpdates.push({ id: mc.id, data });
    touchedMatches.add(match.id);
    affectedCats.add(`${zone.id}|${tc.id}`);
  }

  // Reporte de clubes sin mapeo.
  if (missingTeams.length) {
    console.log(`  ⚠ ${missingTeams.length} club(es) del origen sin mapeo en v2: ${missingTeams.join(', ')}`);
  }

  const summary = {
    cargados,
    actualizados,
    pendientes,
    sinCambios,
    sinMatch,
    sinClub,
    sinCategoria,
  };

  if (DRY_RUN) {
    console.log(`  [DRY-RUN] ${cfg.zone}: ${cargados} cargados, ${actualizados} actualizados, ${pendientes} a pendiente, ${sinCambios} sin cambios, ${sinMatch} sin match, ${sinClub} sin club, ${sinCategoria} sin categoría.`);
    return summary;
  }

  // Aplica las actualizaciones.
  if (mcUpdates.length) {
    await prisma.$transaction(
      mcUpdates.map((u) => prisma.matchCategory.update({ where: { id: u.id }, data: u.data })),
    );
  }

  // Recalcula el estado de los partidos tocados.
  for (const matchId of touchedMatches) {
    const cats = await prisma.matchCategory.findMany({
      where: { matchId },
      select: { closedAt: true, isPending: true },
    });
    const allClosed = cats.every((c) => c.closedAt != null);
    const anyPending = cats.some((c) => c.isPending);
    const status = allClosed ? MatchStatus.FINISHED : anyPending ? MatchStatus.PENDING : MatchStatus.PROGRAMMED;
    await prisma.match.update({ where: { id: matchId }, data: { status } });
  }

  // Recalcula tablas de las categorías afectadas.
  for (const key of affectedCats) {
    const [zoneId, tcId] = key.split('|').map(Number);
    await recalcStandings(prisma, zoneId, tcId, v2Tournament);
  }

  console.log(`  ${cfg.zone}: ${cargados} cargados, ${actualizados} actualizados, ${pendientes} a pendiente, ${sinCambios} sin cambios, ${sinMatch} sin match.`);
  return summary;
}

async function main() {
  console.log('=== Sync Supabase -> ligas-deportivas-v2 ===');
  console.log(DRY_RUN ? '[MODO DRY-RUN: no se escribirá nada]' : '[EJECUCIÓN REAL]');

  let total = { cargados: 0, actualizados: 0, pendientes: 0, sinCambios: 0, sinMatch: 0, sinClub: 0, sinCategoria: 0 };
  for (const cfg of ZONES) {
    try {
      const s = await syncZone(cfg);
      if (s) {
        for (const k of Object.keys(total)) total[k] += s[k];
      }
    } catch (e) {
      console.log(`  ⚠ Error en ${cfg.zone}: ${e.message}`);
    }
  }

  console.log('\n=== Resumen ===');
  console.log(`  Resultados cargados: ${total.cargados}`);
  console.log(`  Resultados actualizados: ${total.actualizados}`);
  console.log(`  Pasados a pendiente: ${total.pendientes}`);
  console.log(`  Sin cambios: ${total.sinCambios}`);
  console.log(`  Sin match en v2 (ignorados): ${total.sinMatch}`);
  console.log(`  Sin club mapeado: ${total.sinClub}`);
  console.log(`  Sin categoría mapeada: ${total.sinCategoria}`);
  console.log(DRY_RUN ? '\n[DRY-RUN] No se realizaron cambios.' : '\n=== Sync finalizado ===');
}

main()
  .catch((e) => {
    console.error('\nERROR:', e.message);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
