-- Classes with skill trees
CREATE TABLE IF NOT EXISTS d2.classes (
    id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    skill_suffix VARCHAR(100) NOT NULL DEFAULT '',
    skill_trees JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Description column for quest items
ALTER TABLE d2.item_bases ADD COLUMN IF NOT EXISTS description TEXT;

-- Index for quest item lookups
CREATE INDEX IF NOT EXISTS idx_item_bases_quest ON d2.item_bases(quest_item) WHERE quest_item = true;
