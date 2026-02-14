-- Add premium subscription fields to profiles
ALTER TABLE d2.profiles
    ADD COLUMN IF NOT EXISTS is_premium boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS stripe_customer_id varchar(255),
    ADD COLUMN IF NOT EXISTS stripe_subscription_id varchar(255),
    ADD COLUMN IF NOT EXISTS subscription_status varchar(50) NOT NULL DEFAULT 'none',
    ADD COLUMN IF NOT EXISTS subscription_current_period_end timestamptz,
    ADD COLUMN IF NOT EXISTS cancel_at_period_end boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS profile_flair varchar(50);

-- Indexes for efficient lookups
CREATE INDEX IF NOT EXISTS idx_profiles_stripe_customer_id ON d2.profiles (stripe_customer_id) WHERE stripe_customer_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_is_premium ON d2.profiles (is_premium) WHERE is_premium = true;
