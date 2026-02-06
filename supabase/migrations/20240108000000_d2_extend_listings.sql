-- Add region column to listings
alter table d2.listings add column if not exists region text default 'americas';

-- Add GIN index for stats JSONB column for affix filtering
create index if not exists listings_stats_gin_idx on d2.listings using gin (stats);

-- Create composite index for common filter combinations
create index if not exists listings_filter_idx on d2.listings(game, status, ladder, hardcore, platform, region, category);

-- Add index on rarity
create index if not exists listings_rarity_idx on d2.listings(rarity);

-- Add index on expires_at for cleanup queries
create index if not exists listings_expires_at_idx on d2.listings(expires_at);
