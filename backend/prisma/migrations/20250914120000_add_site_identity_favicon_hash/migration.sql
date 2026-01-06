ALTER TABLE "SiteIdentity"
  DROP COLUMN "faviconKey",
  ADD COLUMN "faviconHash" TEXT;
