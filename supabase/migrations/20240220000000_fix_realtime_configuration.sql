-- Consolidated Realtime Configuration Fix
-- This migration ensures all realtime-dependent tables are properly configured
-- Run after all table structures are in place (after 20240111 trades refactor)

-- ============================================================================
-- NOTIFICATIONS TABLE
-- ============================================================================

-- Set REPLICA IDENTITY FULL so Realtime broadcasts all columns on INSERT/UPDATE/DELETE
-- Without this, realtime only sends primary key, breaking filtered subscriptions
ALTER TABLE d2.notifications REPLICA IDENTITY FULL;

-- Grant SELECT permission to authenticated users for Realtime to work
-- (RLS policies still apply for row-level filtering)
GRANT SELECT ON d2.notifications TO authenticated;

-- ============================================================================
-- MESSAGES TABLE
-- ============================================================================

-- Set REPLICA IDENTITY FULL so Realtime broadcasts all columns
ALTER TABLE d2.messages REPLICA IDENTITY FULL;

-- Grant SELECT permission to authenticated users for Realtime to work
GRANT SELECT ON d2.messages TO authenticated;

-- Add participant columns to messages table for simpler RLS
-- Complex RLS policies with JOINs don't work well with Realtime
ALTER TABLE d2.messages ADD COLUMN IF NOT EXISTS seller_id uuid REFERENCES d2.profiles(id);
ALTER TABLE d2.messages ADD COLUMN IF NOT EXISTS buyer_id uuid REFERENCES d2.profiles(id);

-- Backfill existing messages with participant IDs from trades
UPDATE d2.messages m
SET
  seller_id = t.seller_id,
  buyer_id = t.buyer_id
FROM d2.chats c
JOIN d2.trades t ON t.id = c.trade_id
WHERE m.chat_id = c.id
  AND (m.seller_id IS NULL OR m.buyer_id IS NULL);

-- Create indexes for the new columns
CREATE INDEX IF NOT EXISTS idx_messages_seller_id ON d2.messages(seller_id);
CREATE INDEX IF NOT EXISTS idx_messages_buyer_id ON d2.messages(buyer_id);

-- Replace complex RLS policy with simple one that Realtime can evaluate
DROP POLICY IF EXISTS "Users can view messages in their chats" ON d2.messages;
DROP POLICY IF EXISTS "Trade participants can view messages" ON d2.messages;

CREATE POLICY "Users can view messages in their chats"
  ON d2.messages FOR SELECT
  USING (
    auth.uid() = seller_id OR auth.uid() = buyer_id
  );

-- ============================================================================
-- CHATS TABLE
-- ============================================================================

-- Add chats table to realtime publication (was missing from trades refactor)
-- Use DO block to handle case where table is already in publication
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE d2.chats;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Set REPLICA IDENTITY FULL so Realtime broadcasts all columns
ALTER TABLE d2.chats REPLICA IDENTITY FULL;

-- Grant SELECT permission to authenticated users for Realtime to work
GRANT SELECT ON d2.chats TO authenticated;

-- ============================================================================
-- TRADES TABLE
-- ============================================================================

-- Add trades table to realtime publication for trade status updates
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE d2.trades;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Set REPLICA IDENTITY FULL so Realtime broadcasts all columns
ALTER TABLE d2.trades REPLICA IDENTITY FULL;

-- Grant SELECT permission to authenticated users for Realtime to work
GRANT SELECT ON d2.trades TO authenticated;

-- ============================================================================
-- OFFERS TABLE (formerly trade_requests)
-- ============================================================================

-- Set REPLICA IDENTITY FULL for offers table
ALTER TABLE d2.offers REPLICA IDENTITY FULL;

-- Grant SELECT permission to authenticated users for Realtime to work
GRANT SELECT ON d2.offers TO authenticated;
