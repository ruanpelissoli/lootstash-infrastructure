-- Create device_tokens table for mobile push notifications
create table d2.device_tokens (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references d2.profiles(id) on delete cascade not null,
  expo_push_token text not null,
  device_name text,
  platform text not null check (platform in ('ios', 'android')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  constraint uq_device_tokens_user_token unique (user_id, expo_push_token)
);

-- Enable RLS
alter table d2.device_tokens enable row level security;

-- Users can view their own device tokens
create policy "Users can view their own device tokens"
  on d2.device_tokens for select
  using (auth.uid() = user_id);

-- Users can insert their own device tokens
create policy "Users can insert their own device tokens"
  on d2.device_tokens for insert
  with check (auth.uid() = user_id);

-- Users can update their own device tokens
create policy "Users can update their own device tokens"
  on d2.device_tokens for update
  using (auth.uid() = user_id);

-- Users can delete their own device tokens
create policy "Users can delete their own device tokens"
  on d2.device_tokens for delete
  using (auth.uid() = user_id);

-- System/service role can read all device tokens (needed for push sending)
create policy "Service role can read all device tokens"
  on d2.device_tokens for select
  using (auth.role() = 'service_role');

-- Indexes
create index device_tokens_user_id_idx on d2.device_tokens(user_id);

-- Trigger for updated_at
create trigger on_device_tokens_updated
  before update on d2.device_tokens
  for each row execute procedure d2.handle_updated_at();
