// Importador de datos desde el Supabase público del municipio hacia ligas-deportivas-v2.
//
// Migra una liga del origen a una zona de un torneo de v2:
//  - Crea los clubes faltantes y mapea los existentes (por alias o nombre normalizado, quita sufijo "FEM").
//  - Descarga escudos (solo PNG cuadrado 200-500px y <=512KB) y los sube al storage.
//  - Crea la zona destino y asigna los clubes.
//  - Arma la ida COMPLETA (jugados del origen + faltantes deducidos) y genera la vuelta espejada.
//  - Localía de los faltantes por balance/alternancia de local-visitante.
//  - Carga resultados por categoría (finalizado -> score+closedAt; no_presentaron/pendiente/faltantes -> PENDING).
//  - Recalcula las tablas de posiciones.
//
// Configuración por variables de entorno:
//   SOURCE_LEAGUE     subcadena del nombre de la liga en el origen (default "Domingo Super Liga")
//   TARGET_LEAGUE     nombre de la liga en v2 (default "Futbol Infantil")
//   TARGET_TOURNAMENT nombre del torneo en v2 (default "Domingos")
//   ZONE_NAME         nombre de la zona a crear en v2 (default "Super Liga")
//
// Uso (dentro del contenedor backend):
//   node import-supabase.js                          # ejecuta el import con defaults
//   DRY_RUN=1 node import-supabase.js                # solo valida y muestra el plan
//   SOURCE_LEAGUE='Liga de Ascenso' ZONE_NAME='Liga de Ascenso' node import-supabase.js

const {
  PrismaClient,
  Round,
  MatchStatus,
  ZoneStatus,
  MatchdayStatus,
} = require('@prisma/client');
const sharp = require('sharp');
const fs = require('fs');
const path = require('path');
const { randomUUID } = require('crypto');

const {
  CLUB_LOGO_MIN,
  CLUB_LOGO_MAX,
  MAX_LOGO_BYTES,
  slugify,
  norm,
  resolveCanonicalName,
  indexClubsBySourceTeamId,
  mapCategories,
  fetchSourceLeague,
  recalcStandings,
} = require('./lib/supabase-common');

const prisma = new PrismaClient();

const SOURCE_LEAGUE_MATCH = process.env.SOURCE_LEAGUE || 'Domingo Super Liga';
const V2_LEAGUE_NAME = process.env.TARGET_LEAGUE || 'Futbol Infantil';
const V2_TOURNAMENT_NAME = process.env.TARGET_TOURNAMENT || 'Domingos';
const ZONE_NAME = process.env.ZONE_NAME || 'Super Liga';

const DRY_RUN = process.env.DRY_RUN === '1';

async function main() {
  console.log('=== Import Supabase -> ligas-deportivas-v2 ===');
  console.log(DRY_RUN ? '[MODO DRY-RUN: no se escribirá nada]' : '[EJECUCIÓN REAL]');

  // 1) Guarda de idempotencia.
  const v2Tournament = await prisma.tournament.findFirst({
    where: { name: V2_TOURNAMENT_NAME, league: { name: V2_LEAGUE_NAME } },
  });
  if (!v2Tournament) {
    throw new Error(`No se encontró el torneo "${V2_TOURNAMENT_NAME}" en la liga "${V2_LEAGUE_NAME}".`);
  }
  const existingZone = await prisma.zone.findFirst({
    where: { tournamentId: v2Tournament.id, name: ZONE_NAME },
  });
  if (existingZone) {
    const existingZoneMatches = await prisma.match.count({ where: { zoneId: existingZone.id } });
    throw new Error(
      `La zona "${ZONE_NAME}" ya existe en el torneo ${V2_TOURNAMENT_NAME} (id=${v2Tournament.id}) con ${existingZoneMatches} partidos. Abortando para no duplicar.`,
    );
  }
  console.log(`Torneo destino: ${v2Tournament.name} (id=${v2Tournament.id}, liga=${V2_LEAGUE_NAME})`);

  // 2) Datos del origen.
  const { sourceLeague, categories, leagueTeams, teams, matches } =
    await fetchSourceLeague(SOURCE_LEAGUE_MATCH);
  console.log(`Liga origen: "${sourceLeague.name}" (id=${sourceLeague.id})`);

  const teamById = new Map(teams.map((t) => [t.id, t]));
  const participatingTeamIds = Array.from(new Set(leagueTeams.map((lt) => lt.team_id)));
  const sourceTeams = participatingTeamIds
    .map((id) => teamById.get(id))
    .filter(Boolean)
    .sort((a, b) => a.name.localeCompare(b.name));
  console.log(`Clubes en origen: ${sourceTeams.length}`);

  // Categorías del origen -> TournamentCategory destino (ya existentes).
  const v2TournamentCategories = await prisma.tournamentCategory.findMany({
    where: { tournamentId: v2Tournament.id },
    include: { category: true },
  });
  if (v2TournamentCategories.length === 0) {
    throw new Error('El torneo destino no tiene categorías asignadas.');
  }
  const { sourceCatToV2, v2TcToSourceCat } = mapCategories(categories, v2TournamentCategories);
  console.log(`Categorías mapeadas: ${sourceCatToV2.size}/${categories.length}`);

  // 3) Clubes: mapear existentes / crear faltantes.
  const allClubs = await prisma.club.findMany({
    select: { id: true, name: true, slug: true, shortName: true, sourceTeamIds: true },
  });
  const clubByNormName = new Map(allClubs.map((c) => [norm(c.name), c]));
  const clubBySourceTeamId = indexClubsBySourceTeamId(allClubs);
  const usedSlugs = new Set(allClubs.map((c) => c.slug));

  const clubMap = new Map(); // source team id -> v2 club id
  const publicNameByClubId = new Map(); // v2 club id -> nombre público de equipo
  const createdClubs = [];
  const reusedClubs = [];
  const clubSourceIdUpdates = []; // { clubId, sourceTeamIds }

  for (const team of sourceTeams) {
    const { canonical, aliasName } = resolveCanonicalName(team.name);
    // 1) por id de origen; 2) por alias; 3) por nombre normalizado.
    let club = clubBySourceTeamId.get(team.id);
    if (!club) club = aliasName ? clubByNormName.get(norm(aliasName)) : undefined;
    if (!club) club = clubByNormName.get(norm(canonical));

    if (club) {
      reusedClubs.push({ team: team.name, club: club.name });
      publicNameByClubId.set(club.id, club.shortName?.trim() || club.name);
      const ids = Array.isArray(club.sourceTeamIds) ? club.sourceTeamIds : [];
      if (!ids.includes(team.id)) {
        club.sourceTeamIds = [...ids, team.id];
        clubSourceIdUpdates.push({ clubId: club.id, sourceTeamIds: club.sourceTeamIds });
      }
    } else {
      let slug = slugify(canonical);
      let suffix = 1;
      while (usedSlugs.has(slug)) {
        slug = `${slugify(canonical)}-${suffix++}`;
      }
      usedSlugs.add(slug);
      const shortName = (team.short_name || '').trim() || null;
      if (DRY_RUN) {
        club = { id: `new-${slug}`, name: canonical, slug, shortName, __new: true, sourceTeamIds: [team.id] };
      } else {
        club = await prisma.club.create({
          data: {
            name: canonical,
            shortName,
            slug,
            primaryColor: (team.colors || '').trim() || null,
            active: true,
            sourceTeamIds: [team.id],
          },
        });
      }
      createdClubs.push({ team: team.name, name: canonical, shortName, slug });
      publicNameByClubId.set(club.id, shortName || canonical);
    }
    clubMap.set(team.id, club.id);
  }

  // Persiste los ids de origen agregados a clubes existentes.
  if (!DRY_RUN && clubSourceIdUpdates.length) {
    for (const u of clubSourceIdUpdates) {
      await prisma.club.update({
        where: { id: u.clubId },
        data: { sourceTeamIds: u.sourceTeamIds },
      });
    }
  }

  console.log(`Clubes: ${reusedClubs.length} existentes, ${createdClubs.length} nuevos.`);
  for (const r of reusedClubs) console.log(`  ↻ reutiliza: ${r.team} -> ${r.club}`);
  for (const c of createdClubs) console.log(`  + crea: ${c.team}${c.name !== c.team ? ' -> ' + c.name : ''} (${c.shortName ?? '-'}, slug=${c.slug})`);

  // 4) Escudos (solo clubes nuevos, solo PNG válido).
  const createdTeamNames = new Set(createdClubs.map((c) => c.team));
  for (const team of sourceTeams) {
    if (!createdTeamNames.has(team.name) || !team.logo_url) continue;
    const clubId = clubMap.get(team.id);
    let result = { team: team.name, status: 'omitido' };
    try {
      const res = await fetch(team.logo_url);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const buf = Buffer.from(await res.arrayBuffer());
      const meta = await sharp(buf).metadata();
      const ok =
        meta.format === 'png' &&
        meta.width === meta.height &&
        meta.width >= CLUB_LOGO_MIN &&
        meta.width <= CLUB_LOGO_MAX &&
        buf.length <= MAX_LOGO_BYTES;
      if (ok) {
        if (!DRY_RUN) {
          const uploadDir = path.resolve(process.cwd(), 'storage', 'uploads');
          await fs.promises.mkdir(uploadDir, { recursive: true });
          const filename = `${randomUUID()}.png`;
          await fs.promises.writeFile(path.join(uploadDir, filename), buf);
          const logoKey = `uploads/${filename}`;
          const logoUrl = `/storage/uploads/${filename}`;
          await prisma.club.update({ where: { id: clubId }, data: { logoKey, logoUrl } });
        }
        result = { team: team.name, status: `subido (${meta.width}x${meta.height})` };
      } else {
        result = {
          team: team.name,
          status: `omitido (fmt=${meta.format} ${meta.width}x${meta.height} ${buf.length}B)`,
        };
      }
    } catch (e) {
      result = { team: team.name, status: `omitido (error: ${e.message})` };
    }
    console.log(`  escudo ${result.team}: ${result.status}`);
  }

  // 5) Fixture: unión de cruces (compartido entre categorías).
  const fixtureByKey = new Map();
  for (const m of matches) {
    if (!m.away_team_id) continue;
    const key = `${m.matchday}|${m.local_team_id}|${m.away_team_id}`;
    if (!fixtureByKey.has(key)) {
      fixtureByKey.set(key, {
        matchday: m.matchday,
        home: m.local_team_id,
        away: m.away_team_id,
        date: m.match_date,
        results: new Map(),
      });
    }
    const f = fixtureByKey.get(key);
    if (!f.date && m.match_date) f.date = m.match_date;
    f.results.set(m.category_id, { status: m.status, lg: m.local_goals, ag: m.away_goals });
  }

  const played = Array.from(fixtureByKey.values());
  const teamIds = sourceTeams.map((t) => t.id);

  // Pares completos de la ronda (ida) y pares faltantes.
  const allPairs = new Set();
  for (let i = 0; i < teamIds.length; i++) {
    for (let j = i + 1; j < teamIds.length; j++) {
      allPairs.add([teamIds[i], teamIds[j]].sort().join('|'));
    }
  }
  const playedPairs = new Set(played.map((f) => [f.home, f.away].sort().join('|')));
  const missingPairs = new Set([...allPairs].filter((p) => !playedPairs.has(p)));

  // Balance de localías para deducir la localía de los faltantes (alternancia -> 4-4).
  const homeCount = {};
  const awayCount = {};
  for (const t of teamIds) {
    homeCount[t] = 0;
    awayCount[t] = 0;
  }
  for (const f of played) {
    homeCount[f.home]++;
    awayCount[f.away]++;
  }

  const pickHomeAway = (a, b) => {
    const aHome = homeCount[a] > awayCount[a];
    const bHome = homeCount[b] > awayCount[b];
    let home;
    if (aHome && !bHome) home = b;
    else if (!aHome && bHome) home = a;
    else if (aHome && bHome) {
      const ai = homeCount[a] - awayCount[a];
      const bi = homeCount[b] - awayCount[b];
      home = ai >= bi ? b : a;
    } else {
      const ai = awayCount[a] - homeCount[a];
      const bi = awayCount[b] - homeCount[b];
      if (ai > bi) home = a;
      else if (bi > ai) home = b;
      else home = a < b ? a : b;
    }
    const away = home === a ? b : a;
    homeCount[home]++;
    awayCount[away]++;
    return { home, away };
  };

  const maxMd = played.length ? Math.max(...played.map((f) => f.matchday)) : 0;

  const missing = []; // {matchday, home, away, deduced:true}

  // a) Rellenar huecos en fechas existentes (equipos libres).
  const byMd = {};
  for (const f of played) (byMd[f.matchday] = byMd[f.matchday] || []).push(f);
  for (let md = 1; md <= maxMd; md++) {
    const rows = byMd[md] || [];
    const playing = new Set(rows.flatMap((f) => [f.home, f.away]));
    const free = teamIds.filter((t) => !playing.has(t));
    if (free.length < 2) continue;
    const used = new Set();
    const matched = [];
    for (let i = 0; i < free.length; i++) {
      if (used.has(free[i])) continue;
      for (let j = i + 1; j < free.length; j++) {
        if (used.has(free[j])) continue;
        const key = [free[i], free[j]].sort().join('|');
        if (missingPairs.has(key)) {
          matched.push([free[i], free[j]].sort());
          used.add(free[i]);
          used.add(free[j]);
          break;
        }
      }
    }
    for (const [a, b] of matched) {
      const key = [a, b].sort().join('|');
      if (!missingPairs.has(key)) continue;
      missingPairs.delete(key);
      const { home, away } = pickHomeAway(a, b);
      missing.push({ matchday: md, home, away, date: null, results: new Map(), deduced: true });
    }
  }

  // b) Resto -> fechas nuevas (sin repetir equipo en la misma fecha).
  let remaining = [...missingPairs].sort();
  let md = maxMd + 1;
  let guard = 0;
  while (remaining.length > 0 && guard++ < 1000) {
    const used = new Set();
    const next = [];
    for (const pk of remaining) {
      const [a, b] = pk.split('|');
      if (used.has(a) || used.has(b)) {
        next.push(pk);
        continue;
      }
      used.add(a);
      used.add(b);
      const { home, away } = pickHomeAway(a, b);
      missing.push({ matchday: md, home, away, date: null, results: new Map(), deduced: true });
    }
    remaining = next;
    md++;
  }

  const idaFinal = [...played.map((f) => ({ ...f })), ...missing].sort(
    (a, b) => a.matchday - b.matchday || a.home.localeCompare(b.home),
  );
  const totalIdaMatchdays = Math.max(...idaFinal.map((f) => f.matchday));

  // Vuelta = espejo de la ida (localía invertida), fechas N+1..2N.
  const generatedVuelta = idaFinal.map((f) => ({
    matchday: f.matchday + totalIdaMatchdays,
    home: f.away,
    away: f.home,
    date: null,
    results: new Map(),
    deduced: false,
  }));

  const totalMatchdays = totalIdaMatchdays * 2;
  const totalMatches = idaFinal.length + generatedVuelta.length;

  console.log(
    `Fixture: ${played.length} jugados + ${missing.length} faltantes deducidos = ${idaFinal.length} ida; vuelta = ${generatedVuelta.length}.`,
  );

  if (DRY_RUN) {
    console.log('\n[DRY-RUN] Resumen final:');
    console.log(`  - Zona "${ZONE_NAME}" en torneo ${v2Tournament.id}`);
    console.log(`  - ClubZone: ${sourceTeams.length}`);
    console.log(`  - Team (club x categoría): ${sourceTeams.length * v2TournamentCategories.length}`);
    console.log(`  - Partidos: ${totalMatches} (${idaFinal.length} ida + ${generatedVuelta.length} vuelta)`);
    console.log(`  - MatchCategory: ${totalMatches * v2TournamentCategories.length}`);
    console.log(`  - Matchdays: ${totalMatchdays}`);
    if (missing.length) {
      console.log('  - Cruces faltantes deducidos (PENDING):');
      for (const f of missing) {
        const h = teamById.get(f.home)?.name || f.home;
        const a = teamById.get(f.away)?.name || f.away;
        console.log(`      fecha ${f.matchday}: ${h} (L) vs ${a} (V)`);
      }
    }
    return;
  }

  const now = new Date();

  await prisma.$transaction(
    async (tx) => {
      const zone = await tx.zone.create({
        data: { tournamentId: v2Tournament.id, name: ZONE_NAME, status: ZoneStatus.PLAYING },
      });
      console.log(`Zona creada: ${zone.name} (id=${zone.id})`);

      await tx.clubZone.createMany({
        data: sourceTeams.map((t) => ({ clubId: clubMap.get(t.id), zoneId: zone.id })),
      });
      console.log(`ClubZone creados: ${sourceTeams.length}`);

      const teamRows = [];
      for (const t of sourceTeams) {
        const clubId = clubMap.get(t.id);
        const publicName = publicNameByClubId.get(clubId) || t.name;
        for (const tc of v2TournamentCategories) {
          teamRows.push({ clubId, tournamentCategoryId: tc.id, publicName, active: true });
        }
      }
      await tx.team.createMany({ data: teamRows, skipDuplicates: true });
      console.log(`Teams creados: ${teamRows.length}`);

      const createMatch = async (f) => {
        const categories = [];
        for (const tc of v2TournamentCategories) {
          const sourceCatId = v2TcToSourceCat.get(tc.id);
          const src = sourceCatId ? f.results.get(sourceCatId) : undefined;
          let homeScore = 0;
          let awayScore = 0;
          let closedAt = null;
          let isPending = false;
          if (src && src.status === 'finalizado') {
            homeScore = src.lg;
            awayScore = src.ag;
            closedAt = now;
          } else if (
            f.deduced ||
            (src && (src.status === 'no_presentaron' || src.status === 'pendiente'))
          ) {
            isPending = true;
          }
          categories.push({
            tournamentCategoryId: tc.id,
            kickoffTime: tc.kickoffTime,
            isPromocional: !tc.countsForGeneral,
            homeScore,
            awayScore,
            closedAt,
            isPending,
          });
        }
        const closedCount = categories.filter((c) => c.closedAt).length;
        const pendingCount = categories.filter((c) => c.isPending).length;
        const status =
          closedCount === categories.length
            ? MatchStatus.FINISHED
            : pendingCount > 0
              ? MatchStatus.PENDING
              : MatchStatus.PROGRAMMED;
        const round = f.matchday <= totalIdaMatchdays ? Round.FIRST : Round.SECOND;
        const date = f.date ? new Date(`${f.date}T00:00:00.000Z`) : null;
        return tx.match.create({
          data: {
            tournamentId: v2Tournament.id,
            zoneId: zone.id,
            matchday: f.matchday,
            round,
            date,
            status,
            homeClubId: clubMap.get(f.home),
            awayClubId: clubMap.get(f.away),
            categories: { create: categories },
          },
        });
      };

      for (const f of [...idaFinal, ...generatedVuelta]) {
        await createMatch(f);
      }
      console.log(`Partidos creados: ${totalMatches}`);

      const matchesByMatchday = await tx.match.findMany({
        where: { zoneId: zone.id },
        select: { matchday: true, status: true, date: true },
      });
      const byMatchday = new Map();
      for (const m of matchesByMatchday) {
        if (!byMatchday.has(m.matchday)) byMatchday.set(m.matchday, []);
        byMatchday.get(m.matchday).push(m);
      }
      const matchdayEntries = [];
      for (let md = 1; md <= totalMatchdays; md += 1) {
        const rows = byMatchday.get(md) ?? [];
        let status = MatchdayStatus.PENDING;
        if (rows.length > 0 && md <= totalIdaMatchdays) {
          const allFinished = rows.every((r) => r.status === MatchStatus.FINISHED);
          status = allFinished ? MatchdayStatus.PLAYED : MatchdayStatus.INCOMPLETE;
        }
        const dateRow = rows.find((r) => r.date);
        matchdayEntries.push({
          zoneId: zone.id,
          matchday: md,
          status,
          date: dateRow ? dateRow.date : null,
        });
      }
      await tx.zoneMatchday.createMany({ data: matchdayEntries });
      console.log(`Matchdays creados: ${totalMatchdays}`);
    },
    { maxWait: 15000, timeout: 180000 },
  );

  // 7) Tablas de posiciones (misma lógica que StandingsService.recalculateForCategory).
  const zone = await prisma.zone.findFirst({
    where: { tournamentId: v2Tournament.id, name: ZONE_NAME },
  });
  for (const tc of v2TournamentCategories) {
    await recalcStandings(prisma, zone.id, tc.id, v2Tournament);
  }
  console.log(`Tablas recalculadas para ${v2TournamentCategories.length} categorías.`);

  console.log('\n=== Import finalizado correctamente ===');
}

main()
  .catch((e) => {
    console.error('\nERROR:', e.message);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
