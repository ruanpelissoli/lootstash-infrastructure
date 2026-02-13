-- Add is_non_rotw column to listings (legacy non-expansion filter, default false = in expansion)
ALTER TABLE d2.listings ADD COLUMN is_non_rotw BOOLEAN NOT NULL DEFAULT false;

-- Add is_non_rotw column to wishlist_items (nullable = wildcard matching)
ALTER TABLE d2.wishlist_items ADD COLUMN is_non_rotw BOOLEAN DEFAULT NULL;
