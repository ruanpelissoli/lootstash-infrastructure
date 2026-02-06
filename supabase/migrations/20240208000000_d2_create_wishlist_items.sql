-- Create wishlist_items table for premium users to track desired items
CREATE TABLE d2.wishlist_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES d2.profiles(id) ON DELETE CASCADE,
    name varchar(100) NOT NULL,
    category varchar(50),
    rarity varchar(50),
    stat_criteria jsonb DEFAULT '[]',
    game varchar(20) DEFAULT 'diablo2',
    ladder boolean,
    hardcore boolean,
    platform varchar(20),
    region varchar(20),
    status varchar(20) DEFAULT 'active',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX idx_wishlist_items_user_id ON d2.wishlist_items(user_id);
CREATE INDEX idx_wishlist_items_status ON d2.wishlist_items(status);
CREATE INDEX idx_wishlist_items_matching ON d2.wishlist_items(status, game, LOWER(name));

-- RLS
ALTER TABLE d2.wishlist_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own wishlist items"
    ON d2.wishlist_items FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own wishlist items"
    ON d2.wishlist_items FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own wishlist items"
    ON d2.wishlist_items FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Service role can read all wishlist items"
    ON d2.wishlist_items FOR SELECT
    TO service_role
    USING (true);
