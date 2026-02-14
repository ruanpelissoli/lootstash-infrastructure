-- Add rune-related fields to listings table for runeword support
ALTER TABLE d2.listings
ADD COLUMN IF NOT EXISTS runes jsonb DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS rune_order text,
ADD COLUMN IF NOT EXISTS base_item_code text,
ADD COLUMN IF NOT EXISTS base_item_name text;

-- Add index on rune_order for filtering runewords by their rune combination
CREATE INDEX IF NOT EXISTS listings_rune_order_idx ON d2.listings(rune_order) WHERE rune_order IS NOT NULL;
