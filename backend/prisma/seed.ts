import { PrismaClient } from '@prisma/client';
import { seedBaseData } from '../src/prisma/base-seed';

const prisma = new PrismaClient();

async function main() {
  await seedBaseData(prisma);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
