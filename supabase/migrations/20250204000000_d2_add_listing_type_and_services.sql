ALTER TABLE d2.listings ADD COLUMN listing_type text NOT NULL DEFAULT 'item';
ALTER TABLE d2.listings ADD COLUMN service_type text;
ALTER TABLE d2.listings ADD COLUMN description text;

ALTER TABLE d2.listings ALTER COLUMN item_type DROP NOT NULL;
ALTER TABLE d2.listings ALTER COLUMN rarity DROP NOT NULL;
ALTER TABLE d2.listings ALTER COLUMN category DROP NOT NULL;

CREATE INDEX idx_listings_listing_type ON d2.listings(listing_type);
CREATE INDEX idx_listings_service_type ON d2.listings(service_type) WHERE service_type IS NOT NULL;
