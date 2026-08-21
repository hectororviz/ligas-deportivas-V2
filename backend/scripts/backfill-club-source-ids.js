// Rellena la columna Club.sourceTeamIds (ids de equipos del origen) para los clubes
// ya existentes en v2, resolviendo por nombre/alias/canónico. Se corre una sola vez.
//
// Uso (dentro del contenedor backend):
//   node backfill-club-source-ids.js
//   DRY_RUN=1 node backfill-club-source-ids.js

const { PrismaClient } = require('@prisma/client');
const {
  supa,
  norm,
  resolveCanonicalName,
  indexClubsBySourceTeamId,
} = require('./lib/supabase-common');

const prisma = new PrismaClient();
const DRY_RUN = process.env.DRY_RUN === '1';

async function main() {
  console.log('=== Backfill Club.sourceTeamIds ===');
  console.log(DRY_RUN ? '[MODO DRY-RUN]' : '[EJECUCIÓN REAL]');

  const clubs = await prisma.club.findMany({
    select: { id: true, name: true, sourceTeamIds: true },
  });
  const clubByNormName = new Map(clubs.map((c) => [norm(c.name), c]));
  const clubBySourceTeamId = indexClubsBySourceTeamId(clubs);

  const [teams, leagueTeams] = await Promise.all([
    supa('teams?select=id,name'),
    supa('league_teams?select=team_id'),
  ]);
  const teamById = new Map(teams.map((t) => [t.id, t]));

  const acc = new Map(); // clubId -> Set(sourceTeamId)
  const unresolved = new Set();
  for (const lt of leagueTeams) {
    const team = teamById.get(lt.team_id);
    if (!team) continue;
    const { canonical, aliasName } = resolveCanonicalName(team.name);
    let club = clubBySourceTeamId.get(lt.team_id);
    if (!club) club = aliasName ? clubByNormName.get(norm(aliasName)) : undefined;
    if (!club) club = clubByNormName.get(norm(canonical));
    if (!club) {
      unresolved.add(team.name);
      continue;
    }
    if (!acc.has(club.id)) acc.set(club.id, new Set());
    acc.get(club.id).add(lt.team_id);
  }

  if (unresolved.size) {
    console.log(`⚠ Sin resolver (${unresolved.size}): ${[...unresolved].join(', ')}`);
  }

  let updated = 0;
  let unchanged = 0;
  for (const [clubId, ids] of acc) {
    const club = clubs.find((c) => c.id === clubId);
    const sorted = [...ids].sort();
    const cur = Array.isArray(club.sourceTeamIds) ? club.sourceTeamIds : [];
    const same =
      cur.length === sorted.length && sorted.every((v, i) => v === cur[i]);
    if (same) {
      unchanged++;
      continue;
    }
    updated++;
    if (!DRY_RUN) {
      await prisma.club.update({ where: { id: clubId }, data: { sourceTeamIds: sorted } });
    }
    console.log(`  ${club.name}: ${sorted.length} id(s)${DRY_RUN ? ' [DRY]' : ''}`);
  }

  console.log(`\nActualizados: ${updated}, sin cambios: ${unchanged}.`);
}

main()
  .catch((e) => {
    console.error('\nERROR:', e.message);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
