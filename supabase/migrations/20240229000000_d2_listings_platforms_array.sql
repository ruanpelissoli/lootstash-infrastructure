ALTER TABLE d2.listings ADD COLUMN platforms text[] NOT NULL DEFAULT ARRAY['pc'];
UPDATE d2.listings SET platforms = ARRAY[platform] WHERE platform IS NOT NULL AND platform != '';
ALTER TABLE d2.listings DROP COLUMN platform;
CREATE INDEX idx_listings_platforms ON d2.listings USING GIN (platforms);
