-- CreateEnum
CREATE TYPE "MatchdayStatus" AS ENUM ('PENDING', 'IN_PROGRESS', 'INCOMPLETE', 'PLAYED');

-- CreateTable
CREATE TABLE "ZoneMatchday" (
    "id" SERIAL NOT NULL,
    "zoneId" INTEGER NOT NULL,
    "matchday" INTEGER NOT NULL,
    "status" "MatchdayStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ZoneMatchday_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ZoneMatchday_zoneId_matchday_key" ON "ZoneMatchday"("zoneId", "matchday");

-- AddForeignKey
ALTER TABLE "ZoneMatchday"
ADD CONSTRAINT "ZoneMatchday_zoneId_fkey" FOREIGN KEY ("zoneId") REFERENCES "Zone"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Seed existing matchdays
WITH matchday_status AS (
    SELECT
        "zoneId",
        "matchday",
        BOOL_AND("status" = 'FINISHED') AS all_finished
    FROM "Match"
    GROUP BY "zoneId", "matchday"
),
ordered AS (
    SELECT
        ms."zoneId",
        ms."matchday",
        ms.all_finished,
        ROW_NUMBER() OVER (PARTITION BY ms."zoneId" ORDER BY ms."matchday") AS order_index
    FROM matchday_status ms
),
augmented AS (
    SELECT
        o.*,
        MIN(CASE WHEN NOT o.all_finished THEN o.order_index END) OVER (PARTITION BY o."zoneId") AS first_open_index
    FROM ordered o
)
INSERT INTO "ZoneMatchday" ("zoneId", "matchday", "status", "createdAt", "updatedAt")
SELECT
    "zoneId",
    "matchday",
    CASE
        WHEN all_finished THEN 'PLAYED'::"MatchdayStatus"
        WHEN first_open_index IS NOT NULL AND order_index = first_open_index THEN 'IN_PROGRESS'::"MatchdayStatus"
        ELSE 'PENDING'::"MatchdayStatus"
    END,
    NOW(),
    NOW()
FROM augmented;
