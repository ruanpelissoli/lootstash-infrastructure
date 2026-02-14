-- Add last_active_at column to track when users were last active
ALTER TABLE d2.profiles
ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMPTZ DEFAULT NOW();

-- Create index for efficient online sellers query
CREATE INDEX IF NOT EXISTS idx_profiles_last_active_at ON d2.profiles(last_active_at);

-- Initialize existing profiles with current timestamp
UPDATE d2.profiles SET last_active_at = NOW() WHERE last_active_at IS NULL;
