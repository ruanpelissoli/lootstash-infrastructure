-- Runeword Base Items Junction Table
-- Pre-computed valid base items for each runeword based on type matching and socket requirements

CREATE TABLE IF NOT EXISTS d2.runeword_bases (
    id SERIAL PRIMARY KEY,
    runeword_id INT NOT NULL REFERENCES d2.runewords(id) ON DELETE CASCADE,
    item_base_id INT NOT NULL REFERENCES d2.item_bases(id) ON DELETE CASCADE,
    item_base_code VARCHAR(10) NOT NULL,
    item_base_name VARCHAR(100) NOT NULL,
    category VARCHAR(20) NOT NULL,
    max_sockets INT NOT NULL,
    required_sockets INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(runeword_id, item_base_id)
);

CREATE INDEX idx_d2_runeword_bases_runeword ON d2.runeword_bases(runeword_id);
CREATE INDEX idx_d2_runeword_bases_item_base ON d2.runeword_bases(item_base_id);

-- Enable RLS
ALTER TABLE d2.runeword_bases ENABLE ROW LEVEL SECURITY;

-- Public read access
CREATE POLICY "D2 runeword_bases are publicly readable" ON d2.runeword_bases FOR SELECT USING (true);
