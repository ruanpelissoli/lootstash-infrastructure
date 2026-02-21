-- Performance & Scalability Improvements
-- 1. Normalized listing_stats table with sync trigger (range queries on stats)
-- 2. Partial indexes on active listings (faster filtered queries)
-- 3. Game preference columns on profiles (client-side preference caching)

BEGIN;

-- ============================================================
-- PART 1: Normalized listing_stats table
-- ============================================================

-- EAV table that mirrors the stats JSONB array on d2.listings
-- Enables efficient range queries like "FCR between 20 and 40"
CREATE TABLE d2.listing_stats (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id  UUID NOT NULL REFERENCES d2.listings(id) ON DELETE CASCADE,
    stat_code   TEXT NOT NULL,
    stat_value  NUMERIC NOT NULL
);

-- Composite index for range lookups: WHERE stat_code = 'fcr' AND stat_value BETWEEN 20 AND 40
CREATE INDEX idx_listing_stats_code_value ON d2.listing_stats(stat_code, stat_value);

-- Index for cascade/join operations back to a specific listing
CREATE INDEX idx_listing_stats_listing_id ON d2.listing_stats(listing_id);

-- Trigger function: syncs listing_stats whenever a listing is inserted or updated
CREATE OR REPLACE FUNCTION d2.sync_listing_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Remove old stats for this listing
    DELETE FROM d2.listing_stats WHERE listing_id = NEW.id;

    -- Insert new stats from the JSONB array
    -- Expected format: [{"code": "fcr", "value": 30}, {"code": "ed", "value": 250}, ...]
    IF NEW.stats IS NOT NULL AND jsonb_array_length(NEW.stats) > 0 THEN
        INSERT INTO d2.listing_stats (listing_id, stat_code, stat_value)
        SELECT
            NEW.id,
            elem->>'code',
            (elem->>'value')::NUMERIC
        FROM jsonb_array_elements(NEW.stats) AS elem
        WHERE elem->>'code' IS NOT NULL
          AND elem->>'value' IS NOT NULL
          AND (elem->>'value') ~ '^-?\d+(\.\d+)?$';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER sync_listing_stats_trigger
    AFTER INSERT OR UPDATE OF stats ON d2.listings
    FOR EACH ROW
    EXECUTE FUNCTION d2.sync_listing_stats();

-- Backfill existing listings that have stats
INSERT INTO d2.listing_stats (listing_id, stat_code, stat_value)
SELECT
    l.id,
    elem->>'code',
    (elem->>'value')::NUMERIC
FROM d2.listings l,
     jsonb_array_elements(l.stats) AS elem
WHERE l.stats IS NOT NULL
  AND jsonb_array_length(l.stats) > 0
  AND elem->>'code' IS NOT NULL
  AND elem->>'value' IS NOT NULL
  AND (elem->>'value') ~ '^-?\d+(\.\d+)?$';

-- RLS: public SELECT (same as listings), restrict writes to system/trigger only
ALTER TABLE d2.listing_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Listing stats are viewable by everyone"
    ON d2.listing_stats FOR SELECT
    USING (true);

-- No INSERT/UPDATE/DELETE policies for regular users.
-- Only the SECURITY DEFINER trigger function can write to this table.

-- ============================================================
-- PART 2: Partial indexes on active listings
-- ============================================================

-- Most queries filter on status = 'active'. Partial indexes are smaller and
-- faster than full-table indexes for these common access patterns.

CREATE INDEX idx_listings_active_created_at
    ON d2.listings(created_at DESC)
    WHERE status = 'active';

CREATE INDEX idx_listings_active_category
    ON d2.listings(category, created_at DESC)
    WHERE status = 'active';

-- ============================================================
-- PART 3: Game preference columns on profiles
-- ============================================================

-- Store user game mode preferences so the frontend loads them once per session
-- instead of requiring them in every filter request. NULL = no preference.

ALTER TABLE d2.profiles ADD COLUMN preferred_ladder BOOLEAN;
ALTER TABLE d2.profiles ADD COLUMN preferred_hardcore BOOLEAN;
ALTER TABLE d2.profiles ADD COLUMN preferred_platforms TEXT[];
ALTER TABLE d2.profiles ADD COLUMN preferred_region TEXT;

-- No indexes needed: these columns are only read on profile fetch, never queried against.
-- Existing RLS policies already allow users to update their own profile.

COMMIT;
