// Reconciliación puntual del estado de las fechas (ZoneMatchday).
//
// Contexto: los scripts de importación/sync desde Supabase actualizan el estado
// de los partidos pero no el de las fechas, dejando fechas atascadas en PENDING
// aunque sus partidos estén terminados y sin ninguna fecha IN_PROGRESS (activa),
// lo que oculta el botón "Finalizar fecha" en la UI.
//
// Este script corrige el estado actual en v2 de una única vez:
//  - PLAYED: fechas que están PENDING pero tienen todos sus partidos FINISHED.
//  - IN_PROGRESS: la fecha activa a culminar por zona.
//
// Uso (dentro del contenedor backend):
//   DRY_RUN=1 node reconcile-matchdays.js   # muestra qué haría sin escribir
//   node reconcile-matchdays.js             # aplica los cambios

const { PrismaClient, MatchdayStatus } = require('@prisma/client');

const prisma = new PrismaClient();
const DRY_RUN = process.env.DRY_RUN === '1';

// Fechas a pasar a PLAYED (por zoneId): ya tienen todos sus partidos FINISHED.
const TO_PLAYED = {
  5: [13, 14],
  6: [11, 12],
  14: [12],
  15: [10, 11],
  13: [21],
};

// Fecha activa a setear IN_PROGRESS (por zoneId).
const TO_IN_PROGRESS = {
  5: 15,
  6: 13,
  8: 14,
  9: 10,
  12: 10,
  13: 22,
  14: 13,
  15: 12,
};

async function main() {
  console.log('=== Reconciliar estados de fechas ===');
  console.log(DRY_RUN ? '[MODO DRY-RUN: no se escribirá nada]' : '[EJECUCIÓN REAL]');

  const zoneIds = [...new Set([...Object.keys(TO_PLAYED), ...Object.keys(TO_IN_PROGRESS)].map(Number))];

  const updates = [];

  for (const zoneId of zoneIds) {
    const toPlayed = TO_PLAYED[zoneId] ?? [];
    for (const matchday of toPlayed) {
      const current = await prisma.zoneMatchday.findUnique({
        where: { zoneId_matchday: { zoneId, matchday } },
      });
      if (!current) {
        console.log(`  ⚠ Zona ${zoneId} fecha ${matchday}: no existe. Se omite.`);
        continue;
      }
      if (current.status === MatchdayStatus.PLAYED) {
        console.log(`  Zona ${zoneId} fecha ${matchday}: ya estaba PLAYED.`);
        continue;
      }
      console.log(`  Zona ${zoneId} fecha ${matchday}: ${current.status} -> PLAYED`);
      updates.push(prisma.zoneMatchday.update({
        where: { zoneId_matchday: { zoneId, matchday } },
        data: { status: MatchdayStatus.PLAYED },
      }));
    }

    const active = TO_IN_PROGRESS[zoneId];
    if (active == null) continue;
    const current = await prisma.zoneMatchday.findUnique({
      where: { zoneId_matchday: { zoneId, matchday: active } },
    });
    if (!current) {
      console.log(`  ⚠ Zona ${zoneId} fecha ${active} (activa): no existe. Se omite.`);
      continue;
    }
    if (current.status === MatchdayStatus.IN_PROGRESS) {
      console.log(`  Zona ${zoneId} fecha ${active}: ya estaba IN_PROGRESS.`);
      continue;
    }
    console.log(`  Zona ${zoneId} fecha ${active} (activa): ${current.status} -> IN_PROGRESS`);
    updates.push(prisma.zoneMatchday.update({
      where: { zoneId_matchday: { zoneId, matchday: active } },
      data: { status: MatchdayStatus.IN_PROGRESS },
    }));
  }

  if (DRY_RUN) {
    console.log(`\n[DRY-RUN] ${updates.length} actualización(es) pendiente(s). No se escribió nada.`);
    return;
  }

  if (updates.length) {
    await prisma.$transaction(updates);
  }
  console.log(`\n=== Reconciliación finalizada (${updates.length} actualizaciones) ===`);
}

main()
  .catch((e) => {
    console.error('\nERROR:', e.message);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
