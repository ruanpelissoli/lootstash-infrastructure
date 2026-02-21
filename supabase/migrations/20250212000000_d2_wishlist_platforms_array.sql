-- Migration: Convert wishlist_items.platform (TEXT) to platforms (TEXT[]) and drop region
-- Date: 2026-02-20

BEGIN;

-- 1. Add new platforms array column
ALTER TABLE d2.wishlist_items ADD COLUMN platforms TEXT[];

-- 2. Migrate existing platform data into the new array column
UPDATE d2.wishlist_items
SET platforms = ARRAY[platform]
WHERE platform IS NOT NULL AND platform != '';

-- 3. Drop the old platform column
ALTER TABLE d2.wishlist_items DROP COLUMN platform;

-- 4. Drop the region column (no longer used for wishlist matching)
ALTER TABLE d2.wishlist_items DROP COLUMN region;

COMMIT;
