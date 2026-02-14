-- Create messages table for trade chat
create table d2.messages (
  id uuid default gen_random_uuid() primary key,
  trade_request_id uuid references d2.trade_requests(id) on delete cascade not null,
  sender_id uuid references d2.profiles(id) on delete cascade not null,

  content text not null,
  message_type text not null default 'text' check (message_type in ('text', 'system', 'trade_update')),

  -- Read status
  read_at timestamp with time zone,

  -- Timestamps
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table d2.messages enable row level security;

-- Policies - only participants of the trade can see/send messages
create policy "Trade participants can view messages"
  on d2.messages for select
  using (
    auth.uid() in (
      select tr.requester_id from d2.trade_requests tr where tr.id = trade_request_id
      union
      select l.seller_id from d2.listings l
        join d2.trade_requests tr on tr.listing_id = l.id
        where tr.id = trade_request_id
    )
  );

create policy "Trade participants can send messages"
  on d2.messages for insert
  with check (
    auth.uid() = sender_id
    and auth.uid() in (
      select tr.requester_id from d2.trade_requests tr where tr.id = trade_request_id
      union
      select l.seller_id from d2.listings l
        join d2.trade_requests tr on tr.listing_id = l.id
        where tr.id = trade_request_id
    )
    and (select status from d2.trade_requests where id = trade_request_id) = 'accepted'
  );

-- Allow marking messages as read
create policy "Recipients can mark messages as read"
  on d2.messages for update
  using (
    auth.uid() != sender_id
    and auth.uid() in (
      select tr.requester_id from d2.trade_requests tr where tr.id = trade_request_id
      union
      select l.seller_id from d2.listings l
        join d2.trade_requests tr on tr.listing_id = l.id
        where tr.id = trade_request_id
    )
  );

-- Indexes
create index messages_trade_request_id_idx on d2.messages(trade_request_id);
create index messages_sender_id_idx on d2.messages(sender_id);
create index messages_created_at_idx on d2.messages(created_at);

-- Enable realtime for messages
alter publication supabase_realtime add table d2.messages;
