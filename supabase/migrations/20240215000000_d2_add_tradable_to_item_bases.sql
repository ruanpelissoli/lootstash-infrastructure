-- Add tradable column to item_bases to filter non-tradable items from search results
ALTER TABLE d2.item_bases ADD COLUMN IF NOT EXISTS tradable BOOLEAN DEFAULT true;

-- Set tradable = false for non-tradable items

-- Potions (health, mana, rejuv, antidote, stamina, thawing)
UPDATE d2.item_bases SET tradable = false
WHERE item_type IN ('hpot', 'mpot', 'rpot', 'apot', 'wpot', 'elix');

-- Scrolls and tomes
UPDATE d2.item_bases SET tradable = false
WHERE item_type IN ('scro', 'book');

-- Body parts (monster drops used for crafting - not individually tradable)
UPDATE d2.item_bases SET tradable = false
WHERE item_type = 'body';

-- Regular key (not uber keys)
UPDATE d2.item_bases SET tradable = false
WHERE code = 'key';

-- Gold
UPDATE d2.item_bases SET tradable = false
WHERE item_type = 'gold';

-- Herb
UPDATE d2.item_bases SET tradable = false
WHERE item_type = 'herb';

-- Ear (PvP drop)
UPDATE d2.item_bases SET tradable = false
WHERE item_type = 'play';

-- Torch (quest/misc item, not Hellfire Torch which is unique)
UPDATE d2.item_bases SET tradable = false
WHERE code = 'tch';

-- Quest items that are truly non-tradable (quest_item = true)
UPDATE d2.item_bases SET tradable = false
WHERE quest_item = true;

-- Ensure tradable items in 'ques' type remain tradable:
-- Essences, Token of Absolution, Uber Keys, Uber Materials, Standard of Heroes
UPDATE d2.item_bases SET tradable = true
WHERE code IN (
    'bet',  -- Burning Essence of Terror
    'ceh',  -- Charged Essence of Hatred
    'fed',  -- Festering Essence of Destruction
    'tes',  -- Twisted Essence of Suffering
    'toa',  -- Token of Absolution
    'pk1',  -- Key of Terror
    'pk2',  -- Key of Hate
    'pk3',  -- Key of Destruction
    'bey',  -- Baal's Eye
    'dhn',  -- Diablo's Horn
    'mbr',  -- Mephisto's Brain
    'std'   -- Standard of Heroes
);

-- Create index for faster filtering
CREATE INDEX IF NOT EXISTS idx_d2_item_bases_tradable ON d2.item_bases(tradable);

COMMENT ON COLUMN d2.item_bases.tradable IS 'Whether this item can be traded between players (false for potions, scrolls, quest items, etc.)';
