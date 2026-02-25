CREATE TABLE d2.stash_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES d2.profiles(id) ON DELETE CASCADE,
    name TEXT,
    item_type TEXT NOT NULL,
    rarity TEXT,
    image_url TEXT,
    category TEXT,
    stats JSONB DEFAULT '[]',
    suffixes JSONB DEFAULT '[]',
    runes JSONB DEFAULT '[]',
    rune_order TEXT,
    base_item_code TEXT,
    base_item_name TEXT,
    catalog_item_id TEXT,
    quantity INTEGER NOT NULL DEFAULT 1,
    game TEXT NOT NULL DEFAULT 'diablo2',
    ladder BOOLEAN DEFAULT FALSE,
    hardcore BOOLEAN DEFAULT FALSE,
    platforms TEXT[] DEFAULT '{pc}',
    region TEXT DEFAULT 'americas',
    source TEXT DEFAULT 'manual',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_stash_items_user_id ON d2.stash_items(user_id);
CREATE INDEX idx_stash_items_user_game ON d2.stash_items(user_id, game);
CREATE INDEX idx_stash_items_user_category ON d2.stash_items(user_id, category);

ALTER TABLE d2.listings ADD COLUMN stash_item_id UUID REFERENCES d2.stash_items(id) ON DELETE SET NULL;
CREATE INDEX idx_listings_stash_item_id ON d2.listings(stash_item_id) WHERE stash_item_id IS NOT NULL;

ALTER TABLE d2.stash_items ENABLE ROW LEVEL SECURITY;
