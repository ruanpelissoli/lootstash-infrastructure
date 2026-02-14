ALTER TABLE d2.profiles ADD COLUMN is_admin BOOLEAN NOT NULL DEFAULT false;

CREATE TABLE d2.bug_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES d2.profiles(id),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open',
    created_at TIMESTAMPTZ NOT NULL DEFAULT current_timestamp,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT current_timestamp
);

CREATE INDEX idx_bug_reports_status ON d2.bug_reports(status);
CREATE INDEX idx_bug_reports_user_id ON d2.bug_reports(user_id);
ALTER TABLE d2.bug_reports ENABLE ROW LEVEL SECURITY;
