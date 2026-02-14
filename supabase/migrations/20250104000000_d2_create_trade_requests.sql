-- Create trade requests table
create table d2.trade_requests (
  id uuid default gen_random_uuid() primary key,
  listing_id uuid references d2.listings(id) on delete cascade not null,
  requester_id uuid references d2.profiles(id) on delete cascade not null,

  -- What the requester is offering
  offered_items jsonb not null default '[]'::jsonb, -- Array of items they're offering
  message text, -- Optional message to the seller

  -- Status workflow: pending -> accepted/rejected -> completed/cancelled
  status text not null default 'pending' check (status in ('pending', 'accepted', 'rejected', 'completed', 'cancelled')),

  -- Timestamps
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  accepted_at timestamp with time zone,
  completed_at timestamp with time zone
);

-- Enable RLS
alter table d2.trade_requests enable row level security;

-- Policies
create policy "Users can view trade requests on their listings"
  on d2.trade_requests for select
  using (
    auth.uid() = requester_id
    or auth.uid() in (select seller_id from d2.listings where id = listing_id)
  );

create policy "Users can create trade requests"
  on d2.trade_requests for insert
  with check (
    auth.uid() = requester_id
    and auth.uid() != (select seller_id from d2.listings where id = listing_id) -- Can't request own listing
  );

create policy "Requesters can update their pending requests"
  on d2.trade_requests for update
  using (
    auth.uid() = requester_id
    and status = 'pending'
  );

create policy "Listing owners can accept/reject requests"
  on d2.trade_requests for update
  using (
    auth.uid() in (select seller_id from d2.listings where id = listing_id)
  );

-- Trigger for updated_at
create trigger on_trade_requests_updated
  before update on d2.trade_requests
  for each row execute procedure d2.handle_updated_at();

-- Indexes
create index trade_requests_listing_id_idx on d2.trade_requests(listing_id);
create index trade_requests_requester_id_idx on d2.trade_requests(requester_id);
create index trade_requests_status_idx on d2.trade_requests(status);
