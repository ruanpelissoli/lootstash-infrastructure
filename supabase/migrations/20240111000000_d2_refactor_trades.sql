-- Refactor trade flow: TradeRequest -> Offer, add Trade and Chat entities
-- This migration restructures the trading system with clear entity separation

-- Step 1: Rename trade_requests to offers
ALTER TABLE d2.trade_requests RENAME TO offers;

-- Step 2: Rename constraint names and indexes for offers table
-- Note: PostgreSQL keeps the old constraint names, but they still work

-- Step 3: Remove completed_at from offers (will be on trades)
ALTER TABLE d2.offers DROP COLUMN IF EXISTS completed_at;

-- Step 4: Create trades table
CREATE TABLE d2.trades (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  offer_id uuid REFERENCES d2.offers(id) UNIQUE NOT NULL,
  listing_id uuid REFERENCES d2.listings(id) NOT NULL,
  seller_id uuid REFERENCES d2.profiles(id) NOT NULL,
  buyer_id uuid REFERENCES d2.profiles(id) NOT NULL,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
  cancel_reason text,
  cancelled_by uuid REFERENCES d2.profiles(id),
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL,
  completed_at timestamptz,
  cancelled_at timestamptz
);

-- Step 5: Create chats table
CREATE TABLE d2.chats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trade_id uuid REFERENCES d2.trades(id) UNIQUE NOT NULL,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- Step 6: Add chat_id to messages table and make trade_request_id nullable
ALTER TABLE d2.messages ADD COLUMN chat_id uuid REFERENCES d2.chats(id);

-- Make trade_request_id nullable since we're transitioning to chat_id
ALTER TABLE d2.messages ALTER COLUMN trade_request_id DROP NOT NULL;

-- Step 7: Add trade_id to transactions table
ALTER TABLE d2.transactions ADD COLUMN trade_id uuid REFERENCES d2.trades(id);

-- Step 8: Create indexes for new tables
CREATE INDEX idx_trades_offer_id ON d2.trades(offer_id);
CREATE INDEX idx_trades_listing_id ON d2.trades(listing_id);
CREATE INDEX idx_trades_seller_id ON d2.trades(seller_id);
CREATE INDEX idx_trades_buyer_id ON d2.trades(buyer_id);
CREATE INDEX idx_trades_status ON d2.trades(status);

CREATE INDEX idx_chats_trade_id ON d2.chats(trade_id);

CREATE INDEX idx_messages_chat_id ON d2.messages(chat_id);

CREATE INDEX idx_transactions_trade_id ON d2.transactions(trade_id);

-- Step 9: Add trigger for updated_at on trades
CREATE TRIGGER update_trades_updated_at
  BEFORE UPDATE ON d2.trades
  FOR EACH ROW
  EXECUTE PROCEDURE d2.handle_updated_at();

-- Step 10: Add trigger for updated_at on chats
CREATE TRIGGER update_chats_updated_at
  BEFORE UPDATE ON d2.chats
  FOR EACH ROW
  EXECUTE PROCEDURE d2.handle_updated_at();

-- Step 11: Enable RLS on new tables
ALTER TABLE d2.trades ENABLE ROW LEVEL SECURITY;
ALTER TABLE d2.chats ENABLE ROW LEVEL SECURITY;

-- Step 12: Create RLS policies for trades
CREATE POLICY "Users can view their own trades"
  ON d2.trades FOR SELECT
  USING (auth.uid() = seller_id OR auth.uid() = buyer_id);

CREATE POLICY "Users can update their own trades"
  ON d2.trades FOR UPDATE
  USING (auth.uid() = seller_id OR auth.uid() = buyer_id);

CREATE POLICY "System can insert trades"
  ON d2.trades FOR INSERT
  WITH CHECK (true);

-- Step 13: Create RLS policies for chats
CREATE POLICY "Users can view chats for their trades"
  ON d2.chats FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM d2.trades t
      WHERE t.id = trade_id
      AND (t.seller_id = auth.uid() OR t.buyer_id = auth.uid())
    )
  );

CREATE POLICY "System can insert chats"
  ON d2.chats FOR INSERT
  WITH CHECK (true);

CREATE POLICY "System can update chats"
  ON d2.chats FOR UPDATE
  USING (true);

-- Step 14: Update messages RLS to use chat_id
-- First drop old policies on messages
DROP POLICY IF EXISTS "Users can view their own messages" ON d2.messages;
DROP POLICY IF EXISTS "Users can send messages" ON d2.messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON d2.messages;

-- Create new policies for messages using chat_id
CREATE POLICY "Users can view messages in their chats"
  ON d2.messages FOR SELECT
  USING (
    chat_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM d2.chats c
      JOIN d2.trades t ON t.id = c.trade_id
      WHERE c.id = chat_id
      AND (t.seller_id = auth.uid() OR t.buyer_id = auth.uid())
    )
  );

CREATE POLICY "Users can send messages to their chats"
  ON d2.messages FOR INSERT
  WITH CHECK (
    chat_id IS NOT NULL AND auth.uid() = sender_id AND EXISTS (
      SELECT 1 FROM d2.chats c
      JOIN d2.trades t ON t.id = c.trade_id
      WHERE c.id = chat_id
      AND (t.seller_id = auth.uid() OR t.buyer_id = auth.uid())
    )
  );

CREATE POLICY "Users can update their received messages"
  ON d2.messages FOR UPDATE
  USING (
    chat_id IS NOT NULL AND sender_id != auth.uid() AND EXISTS (
      SELECT 1 FROM d2.chats c
      JOIN d2.trades t ON t.id = c.trade_id
      WHERE c.id = chat_id
      AND (t.seller_id = auth.uid() OR t.buyer_id = auth.uid())
    )
  );

-- Step 15: Update offers RLS policy names (rename from trade_requests policies)
-- Drop old policies
DROP POLICY IF EXISTS "Users can view their own trade requests" ON d2.offers;
DROP POLICY IF EXISTS "Users can create trade requests" ON d2.offers;
DROP POLICY IF EXISTS "Users can update their own trade requests" ON d2.offers;

-- Create new policies with updated names
CREATE POLICY "Users can view their own offers"
  ON d2.offers FOR SELECT
  USING (
    auth.uid() = requester_id
    OR EXISTS (
      SELECT 1 FROM d2.listings l
      WHERE l.id = listing_id AND l.seller_id = auth.uid()
    )
  );

CREATE POLICY "Users can create offers"
  ON d2.offers FOR INSERT
  WITH CHECK (auth.uid() = requester_id);

CREATE POLICY "Users can update their own offers"
  ON d2.offers FOR UPDATE
  USING (
    auth.uid() = requester_id
    OR EXISTS (
      SELECT 1 FROM d2.listings l
      WHERE l.id = listing_id AND l.seller_id = auth.uid()
    )
  );
