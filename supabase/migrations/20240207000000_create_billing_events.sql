-- Create billing events table for tracking Stripe payment events
CREATE TABLE IF NOT EXISTS d2.billing_events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES d2.profiles(id) ON DELETE CASCADE,
    stripe_event_id varchar(255) NOT NULL UNIQUE,
    event_type varchar(100) NOT NULL,
    amount_cents integer,
    currency varchar(10),
    invoice_url text,
    created_at timestamptz NOT NULL DEFAULT now(),
    metadata jsonb
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_billing_events_user_id ON d2.billing_events (user_id);
CREATE INDEX IF NOT EXISTS idx_billing_events_stripe_event_id ON d2.billing_events (stripe_event_id);

-- RLS policies
ALTER TABLE d2.billing_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own billing events"
    ON d2.billing_events
    FOR SELECT
    USING (auth.uid() = user_id);
