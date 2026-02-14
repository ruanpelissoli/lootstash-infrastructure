-- Add views column to listings table
ALTER TABLE d2.listings
ADD COLUMN IF NOT EXISTS views integer DEFAULT 0 NOT NULL;

-- Create index for sorting by views
CREATE INDEX IF NOT EXISTS idx_listings_views ON d2.listings (views DESC);

-- Add comment
COMMENT ON COLUMN d2.listings.views IS 'Number of times the listing has been viewed';
