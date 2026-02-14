ALTER TABLE d2.listings DROP CONSTRAINT listings_rarity_check;
ALTER TABLE d2.listings ADD CONSTRAINT listings_rarity_check CHECK (rarity IN ('normal', 'superior',
 'magic', 'rare', 'unique', 'set', 'runeword'));
