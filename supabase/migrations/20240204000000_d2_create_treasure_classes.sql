-- Treasure Class and Item Ratio Tables
-- Imported from treasureclassex.txt and itemratio.txt

-- Treasure Classes (drop tables/loot pools)
CREATE TABLE IF NOT EXISTS d2.treasure_classes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    group_id INT,
    level INT DEFAULT 0,
    picks INT DEFAULT 1,
    unique_mod INT DEFAULT 0,
    set_mod INT DEFAULT 0,
    rare_mod INT DEFAULT 0,
    magic_mod INT DEFAULT 0,
    no_drop INT DEFAULT 0,
    first_ladder_season INT,
    last_ladder_season INT,
    no_always_spawn BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Treasure Class Items (items within each treasure class)
CREATE TABLE IF NOT EXISTS d2.treasure_class_items (
    id SERIAL PRIMARY KEY,
    treasure_class_id INT NOT NULL REFERENCES d2.treasure_classes(id) ON DELETE CASCADE,
    slot INT NOT NULL,
    item_code VARCHAR(100) NOT NULL,
    is_treasure_class BOOLEAN DEFAULT FALSE,
    probability INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(treasure_class_id, slot)
);

-- Item Ratios (quality calculation ratios)
CREATE TABLE IF NOT EXISTS d2.item_ratios (
    id SERIAL PRIMARY KEY,
    function_name VARCHAR(100) NOT NULL,
    version INT DEFAULT 0,
    is_uber BOOLEAN DEFAULT FALSE,
    is_class_specific BOOLEAN DEFAULT FALSE,
    unique_ratio INT DEFAULT 0,
    unique_divisor INT DEFAULT 1,
    unique_min INT DEFAULT 0,
    rare_ratio INT DEFAULT 0,
    rare_divisor INT DEFAULT 1,
    rare_min INT DEFAULT 0,
    set_ratio INT DEFAULT 0,
    set_divisor INT DEFAULT 1,
    set_min INT DEFAULT 0,
    magic_ratio INT DEFAULT 0,
    magic_divisor INT DEFAULT 1,
    magic_min INT DEFAULT 0,
    hiquality_ratio INT DEFAULT 0,
    hiquality_divisor INT DEFAULT 1,
    normal_ratio INT DEFAULT 0,
    normal_divisor INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(version, is_uber, is_class_specific)
);

-- Indexes
CREATE INDEX idx_d2_tc_name ON d2.treasure_classes(name);
CREATE INDEX idx_d2_tc_items_tc_id ON d2.treasure_class_items(treasure_class_id);
CREATE INDEX idx_d2_tc_items_code ON d2.treasure_class_items(item_code);

-- Enable RLS
ALTER TABLE d2.treasure_classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE d2.treasure_class_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE d2.item_ratios ENABLE ROW LEVEL SECURITY;

-- Public read access
CREATE POLICY "D2 treasure_classes are publicly readable" ON d2.treasure_classes FOR SELECT USING (true);
CREATE POLICY "D2 treasure_class_items are publicly readable" ON d2.treasure_class_items FOR SELECT USING (true);
CREATE POLICY "D2 item_ratios are publicly readable" ON d2.item_ratios FOR SELECT USING (true);
