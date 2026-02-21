-- V4: Category/subcategory rework
ALTER TABLE d2.item_bases ALTER COLUMN category TYPE VARCHAR(50);
ALTER TABLE d2.item_bases ADD COLUMN IF NOT EXISTS subcategory TEXT[] DEFAULT '{}';
CREATE INDEX IF NOT EXISTS idx_item_bases_subcategory ON d2.item_bases USING GIN (subcategory);
ALTER TABLE d2.unique_items ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT '';
ALTER TABLE d2.unique_items ADD COLUMN IF NOT EXISTS subcategory TEXT[] DEFAULT '{}';
CREATE INDEX IF NOT EXISTS idx_unique_items_category ON d2.unique_items(category);
CREATE INDEX IF NOT EXISTS idx_unique_items_subcategory ON d2.unique_items USING GIN (subcategory);
ALTER TABLE d2.set_items ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT '';
ALTER TABLE d2.set_items ADD COLUMN IF NOT EXISTS subcategory TEXT[] DEFAULT '{}';
CREATE INDEX IF NOT EXISTS idx_set_items_category ON d2.set_items(category);
CREATE INDEX IF NOT EXISTS idx_set_items_subcategory ON d2.set_items USING GIN (subcategory);
ALTER TABLE d2.runewords ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT '';
ALTER TABLE d2.runewords ADD COLUMN IF NOT EXISTS subcategory TEXT[] DEFAULT '{}';
CREATE INDEX IF NOT EXISTS idx_runewords_category ON d2.runewords(category);
CREATE INDEX IF NOT EXISTS idx_runewords_subcategory ON d2.runewords USING GIN (subcategory);
