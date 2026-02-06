-- Add Battle.net account linking fields to profiles
ALTER TABLE d2.profiles ADD COLUMN battle_net_id BIGINT UNIQUE;
ALTER TABLE d2.profiles ADD COLUMN battle_tag VARCHAR(255);
ALTER TABLE d2.profiles ADD COLUMN battle_net_linked_at TIMESTAMPTZ;

-- Index for fast Battle.net ID lookups (partial index for non-null values only)
CREATE INDEX idx_profiles_battle_net_id ON d2.profiles(battle_net_id) WHERE battle_net_id IS NOT NULL;
