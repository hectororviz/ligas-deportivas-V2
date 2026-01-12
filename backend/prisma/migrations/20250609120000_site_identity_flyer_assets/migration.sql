DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'site_identity'
  ) THEN
    ALTER TABLE public.site_identity RENAME TO "SiteIdentity";
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'siteidentity'
  ) THEN
    ALTER TABLE public.siteidentity RENAME TO "SiteIdentity";
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS "SiteIdentity" (
  "id" INTEGER NOT NULL DEFAULT 1,
  "title" TEXT NOT NULL DEFAULT 'Ligas Deportivas',
  "iconKey" TEXT,
  "faviconHash" TEXT,
  "flyerKey" TEXT,
  "backgroundImage" TEXT,
  "layoutSvg" TEXT,
  "tokenConfig" JSONB,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "SiteIdentity_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "SiteIdentity"
  ADD COLUMN IF NOT EXISTS "id" INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS "title" TEXT NOT NULL DEFAULT 'Ligas Deportivas',
  ADD COLUMN IF NOT EXISTS "iconKey" TEXT,
  ADD COLUMN IF NOT EXISTS "faviconHash" TEXT,
  ADD COLUMN IF NOT EXISTS "flyerKey" TEXT,
  ADD COLUMN IF NOT EXISTS "backgroundImage" TEXT,
  ADD COLUMN IF NOT EXISTS "layoutSvg" TEXT,
  ADD COLUMN IF NOT EXISTS "tokenConfig" JSONB,
  ADD COLUMN IF NOT EXISTS "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'SiteIdentity_pkey'
  ) THEN
    ALTER TABLE "SiteIdentity"
      ADD CONSTRAINT "SiteIdentity_pkey" PRIMARY KEY ("id");
  END IF;
END $$;
