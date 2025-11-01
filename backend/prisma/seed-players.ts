import { PrismaClient } from '@prisma/client';

import { seedPlayers } from '../src/prisma/seed-players';

const prisma = new PrismaClient();

async function main() {
  const inserted = await seedPlayers(prisma);
  console.log(`Jugadores insertados: ${inserted}`);
}

main()
  .catch((error) => {
    console.error('Error al sembrar jugadores:', error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
