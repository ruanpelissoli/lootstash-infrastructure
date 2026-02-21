ALTER TABLE d2.wishlist_items ADD COLUMN catalog_item_id TEXT;
CREATE INDEX idx_wishlist_items_catalog_item_id ON d2.wishlist_items(catalog_item_id);
