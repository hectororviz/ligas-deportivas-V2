import { Gender, PrismaClient } from '@prisma/client';

import { seedPlayersData } from './data/seed-players-data';

type RawPlayer = (typeof seedPlayersData)[number];

type PreparedPlayer = {
  firstName: string;
  lastName: string;
  birthDate: Date;
  dni: string;
  gender: Gender;
  clubId: number | null;
  addressCity: string | null;
};

function parseGender(rawGender: RawPlayer['gender']): Gender {
  if (Object.values(Gender).includes(rawGender as Gender)) {
    return rawGender as Gender;
  }

  throw new Error(`Género desconocido en seed: ${rawGender}`);
}

function preparePlayer(raw: RawPlayer): PreparedPlayer {
  return {
    firstName: raw.firstName,
    lastName: raw.lastName,
    birthDate: new Date(`${raw.birthDate}T00:00:00.000Z`),
    dni: raw.dni,
    gender: parseGender(raw.gender),
    clubId: raw.clubId,
    addressCity: raw.addressCity ?? null,
  };
}

export async function seedPlayers(prisma: PrismaClient): Promise<number> {
  const data = seedPlayersData.map((raw) => preparePlayer(raw));

  const { count } = await prisma.player.createMany({
    data,
    skipDuplicates: true,
  });

  return count;
}
