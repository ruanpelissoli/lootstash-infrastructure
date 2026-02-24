ALTER TABLE d2.runeword_bases ADD COLUMN IF NOT EXISTS base_type VARCHAR(100) DEFAULT '';

ALTER TABLE d2.runeword_bases DROP CONSTRAINT IF EXISTS runeword_bases_runeword_id_item_base_id_key;

CREATE UNIQUE INDEX IF NOT EXISTS runeword_bases_rw_base_type ON d2.runeword_bases(runeword_id, item_base_id, base_type);
