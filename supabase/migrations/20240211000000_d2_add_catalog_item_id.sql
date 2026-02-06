ALTER TABLE d2.listings
ADD COLUMN IF NOT EXISTS catalog_item_id text;

CREATE INDEX IF NOT EXISTS idx_listings_catalog_item_id ON d2.listings (catalog_item_id);
