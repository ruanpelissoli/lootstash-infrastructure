ALTER TABLE d2.profiles ADD COLUMN IF NOT EXISTS desktop_notifications_enabled BOOLEAN NOT NULL DEFAULT false;
