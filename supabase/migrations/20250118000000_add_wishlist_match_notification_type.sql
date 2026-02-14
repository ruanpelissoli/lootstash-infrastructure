-- Add wishlist_match to the notification_type enum
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'wishlist_match';
