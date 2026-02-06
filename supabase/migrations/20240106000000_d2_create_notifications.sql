-- Create notification type enum
create type notification_type as enum (
  'trade_request_received',
  'trade_request_accepted',
  'trade_request_rejected',
  'new_message',
  'rating_received'
);

-- Create notifications table
create table d2.notifications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references d2.profiles(id) on delete cascade not null,
  type notification_type not null,
  title text not null,
  body text,
  reference_type text,  -- 'trade_request', 'listing', 'message', 'transaction'
  reference_id uuid,
  read boolean default false,
  read_at timestamp with time zone,
  metadata jsonb default '{}'::jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table d2.notifications enable row level security;

-- Create policies
create policy "Users can view their own notifications"
  on d2.notifications for select
  using (auth.uid() = user_id);

create policy "System can create notifications"
  on d2.notifications for insert
  with check (true);

create policy "Users can update their own notifications"
  on d2.notifications for update
  using (auth.uid() = user_id);

-- Indexes
create index notifications_user_id_idx on d2.notifications(user_id);
create index notifications_user_id_read_idx on d2.notifications(user_id, read);
create index notifications_created_at_idx on d2.notifications(created_at desc);
create index notifications_type_idx on d2.notifications(type);

-- Enable realtime for notifications
alter publication supabase_realtime add table d2.notifications;
