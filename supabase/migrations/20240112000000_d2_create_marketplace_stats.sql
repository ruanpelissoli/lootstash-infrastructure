-- Create marketplace_stats table for real-time statistics via Supabase Realtime
-- This table is pre-aggregated and updated via triggers for optimal performance

-- Step 1: Create the marketplace_stats table
CREATE TABLE d2.marketplace_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  active_listings INTEGER NOT NULL DEFAULT 0,
  trades_today INTEGER NOT NULL DEFAULT 0,
  avg_response_time_minutes NUMERIC(5,2) DEFAULT 5.0,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Step 2: Enable Realtime for marketplace_stats and listings
ALTER PUBLICATION supabase_realtime ADD TABLE d2.marketplace_stats;
ALTER PUBLICATION supabase_realtime ADD TABLE d2.listings;

-- Step 3: Set REPLICA IDENTITY FULL for realtime to broadcast all columns on UPDATE/DELETE
-- Without this, only the primary key is sent which breaks realtime subscriptions
ALTER TABLE d2.marketplace_stats REPLICA IDENTITY FULL;
ALTER TABLE d2.listings REPLICA IDENTITY FULL;

-- Step 4: Enable RLS
ALTER TABLE d2.marketplace_stats ENABLE ROW LEVEL SECURITY;

-- Step 5: Grant schema and table permissions for realtime to work
-- Without USAGE on schema, RLS policies won't help - users can't access the schema at all
-- Note: This grants USAGE on d2 schema if not already granted
GRANT USAGE ON SCHEMA d2 TO anon, authenticated;
GRANT SELECT ON d2.marketplace_stats TO anon, authenticated;
-- Also grant SELECT on listings for realtime (RLS policies still apply)
GRANT SELECT ON d2.listings TO anon, authenticated;

-- Step 6: Create RLS policies
-- Public read access for stats (anyone can view)
CREATE POLICY "Marketplace stats are viewable by everyone"
  ON d2.marketplace_stats FOR SELECT
  USING (true);

-- Step 7: Create trigger functions
-- NOTE: These functions do NOT use SECURITY DEFINER so that Supabase Realtime
-- can properly detect and broadcast the changes. The tradeoff is that we need
-- to grant UPDATE permission on marketplace_stats to authenticated users.

CREATE OR REPLACE FUNCTION d2.update_stats_on_listing_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.status = 'active' THEN
    UPDATE d2.marketplace_stats
    SET active_listings = active_listings + 1,
        updated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION d2.update_stats_on_listing_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF OLD.status = 'active' THEN
    UPDATE d2.marketplace_stats
    SET active_listings = GREATEST(active_listings - 1, 0),
        updated_at = NOW();
  END IF;
  RETURN OLD;
END;
$$;

CREATE OR REPLACE FUNCTION d2.update_stats_on_listing_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    IF OLD.status = 'active' AND NEW.status != 'active' THEN
      UPDATE d2.marketplace_stats
      SET active_listings = GREATEST(active_listings - 1, 0),
          updated_at = NOW();
    ELSIF OLD.status != 'active' AND NEW.status = 'active' THEN
      UPDATE d2.marketplace_stats
      SET active_listings = active_listings + 1,
          updated_at = NOW();
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION d2.update_stats_on_trade_complete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'completed' THEN
    UPDATE d2.marketplace_stats
    SET trades_today = trades_today + 1,
        updated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION d2.update_stats_on_offer_accepted()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  new_avg NUMERIC(5,2);
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'accepted' AND NEW.accepted_at IS NOT NULL THEN
    SELECT COALESCE(AVG(EXTRACT(EPOCH FROM (accepted_at - created_at)) / 60), 5.0)::NUMERIC(5,2)
    INTO new_avg
    FROM d2.offers
    WHERE status = 'accepted'
      AND accepted_at IS NOT NULL
      AND created_at >= NOW() - INTERVAL '7 days';

    UPDATE d2.marketplace_stats
    SET avg_response_time_minutes = new_avg,
        updated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$;

-- Step 8: Grant permissions for triggers to work and broadcast realtime events
GRANT EXECUTE ON FUNCTION d2.update_stats_on_listing_insert() TO authenticated;
GRANT EXECUTE ON FUNCTION d2.update_stats_on_listing_delete() TO authenticated;
GRANT EXECUTE ON FUNCTION d2.update_stats_on_listing_status_change() TO authenticated;
GRANT EXECUTE ON FUNCTION d2.update_stats_on_trade_complete() TO authenticated;
GRANT EXECUTE ON FUNCTION d2.update_stats_on_offer_accepted() TO authenticated;
GRANT UPDATE ON d2.marketplace_stats TO authenticated;

-- Step 9: Create triggers on listings table
CREATE TRIGGER listing_insert_stats_trigger
  AFTER INSERT ON d2.listings
  FOR EACH ROW
  EXECUTE FUNCTION d2.update_stats_on_listing_insert();

CREATE TRIGGER listing_delete_stats_trigger
  AFTER DELETE ON d2.listings
  FOR EACH ROW
  EXECUTE FUNCTION d2.update_stats_on_listing_delete();

CREATE TRIGGER listing_status_change_stats_trigger
  AFTER UPDATE OF status ON d2.listings
  FOR EACH ROW
  EXECUTE FUNCTION d2.update_stats_on_listing_status_change();

-- Step 10: Create trigger on trades table
CREATE TRIGGER trade_complete_stats_trigger
  AFTER UPDATE OF status ON d2.trades
  FOR EACH ROW
  EXECUTE FUNCTION d2.update_stats_on_trade_complete();

-- Step 11: Create trigger on offers table
CREATE TRIGGER offer_response_time_trigger
  AFTER UPDATE OF status ON d2.offers
  FOR EACH ROW
  EXECUTE FUNCTION d2.update_stats_on_offer_accepted();

-- Step 12: Initialize stats with existing data
INSERT INTO d2.marketplace_stats (active_listings, trades_today, avg_response_time_minutes, updated_at)
SELECT
  COALESCE((SELECT COUNT(*) FROM d2.listings WHERE status = 'active'), 0),
  COALESCE((SELECT COUNT(*) FROM d2.trades WHERE status = 'completed' AND completed_at >= CURRENT_DATE), 0),
  COALESCE(
    (SELECT AVG(EXTRACT(EPOCH FROM (accepted_at - created_at)) / 60)::NUMERIC(5,2)
     FROM d2.offers
     WHERE status = 'accepted'
       AND accepted_at IS NOT NULL
       AND created_at >= NOW() - INTERVAL '7 days'),
    5.0
  ),
  NOW();

-- Step 13: Create pg_cron extension and schedule daily reset of trades_today
-- Note: pg_cron must be enabled in your Supabase project settings
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule job to reset trades_today at midnight UTC
SELECT cron.schedule(
  'reset-d2-trades-today',
  '0 0 * * *',
  $$UPDATE d2.marketplace_stats SET trades_today = 0, updated_at = NOW()$$
);

-- Create index on updated_at for efficient queries
CREATE INDEX idx_marketplace_stats_updated_at ON d2.marketplace_stats(updated_at DESC);

-- ============================================================================
-- ROLLBACK SQL (run manually if needed to undo this migration)
-- ============================================================================
--
-- -- Remove cron job
-- SELECT cron.unschedule('reset-d2-trades-today');
--
-- -- Drop triggers
-- DROP TRIGGER IF EXISTS listing_insert_stats_trigger ON d2.listings;
-- DROP TRIGGER IF EXISTS listing_delete_stats_trigger ON d2.listings;
-- DROP TRIGGER IF EXISTS listing_status_change_stats_trigger ON d2.listings;
-- DROP TRIGGER IF EXISTS trade_complete_stats_trigger ON d2.trades;
-- DROP TRIGGER IF EXISTS offer_response_time_trigger ON d2.offers;
--
-- -- Drop functions
-- DROP FUNCTION IF EXISTS d2.update_stats_on_listing_insert();
-- DROP FUNCTION IF EXISTS d2.update_stats_on_listing_delete();
-- DROP FUNCTION IF EXISTS d2.update_stats_on_listing_status_change();
-- DROP FUNCTION IF EXISTS d2.update_stats_on_trade_complete();
-- DROP FUNCTION IF EXISTS d2.update_stats_on_offer_accepted();
--
-- -- Reset replica identity before removing from publication
-- ALTER TABLE d2.marketplace_stats REPLICA IDENTITY DEFAULT;
-- ALTER TABLE d2.listings REPLICA IDENTITY DEFAULT;
--
-- -- Revoke permissions
-- REVOKE UPDATE ON d2.marketplace_stats FROM authenticated;
-- REVOKE SELECT ON d2.marketplace_stats FROM anon, authenticated;
-- REVOKE EXECUTE ON FUNCTION d2.update_stats_on_listing_insert() FROM authenticated;
-- REVOKE EXECUTE ON FUNCTION d2.update_stats_on_listing_delete() FROM authenticated;
-- REVOKE EXECUTE ON FUNCTION d2.update_stats_on_listing_status_change() FROM authenticated;
-- REVOKE EXECUTE ON FUNCTION d2.update_stats_on_trade_complete() FROM authenticated;
-- REVOKE EXECUTE ON FUNCTION d2.update_stats_on_offer_accepted() FROM authenticated;
-- -- Note: Don't revoke USAGE on d2 schema as other tables may need it
--
-- -- Remove from realtime publication
-- ALTER PUBLICATION supabase_realtime DROP TABLE d2.marketplace_stats;
-- ALTER PUBLICATION supabase_realtime DROP TABLE d2.listings;
--
-- -- Drop table
-- DROP TABLE IF EXISTS d2.marketplace_stats;
