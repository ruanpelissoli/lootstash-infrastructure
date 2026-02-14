-- Create completed transactions table
create table d2.transactions (
  id uuid default gen_random_uuid() primary key,
  trade_request_id uuid references d2.trade_requests(id) on delete set null unique,
  listing_id uuid references d2.listings(id) on delete set null,

  -- Participants
  seller_id uuid references d2.profiles(id) on delete set null not null,
  buyer_id uuid references d2.profiles(id) on delete set null not null,

  -- Snapshot of what was traded (in case listing is deleted)
  item_name text not null,
  item_details jsonb,
  offered_items jsonb,

  -- Timestamps
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create ratings table
create table d2.ratings (
  id uuid default gen_random_uuid() primary key,
  transaction_id uuid references d2.transactions(id) on delete cascade not null,

  -- Who is rating whom
  rater_id uuid references d2.profiles(id) on delete cascade not null,
  rated_id uuid references d2.profiles(id) on delete cascade not null,

  -- Rating details
  stars integer not null check (stars >= 1 and stars <= 5),
  comment text,

  -- Timestamps
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,

  -- One rating per user per transaction
  unique(transaction_id, rater_id)
);

-- Enable RLS
alter table d2.transactions enable row level security;
alter table d2.ratings enable row level security;

-- Transaction policies
create policy "Transactions are viewable by participants"
  on d2.transactions for select
  using (auth.uid() = seller_id or auth.uid() = buyer_id);

create policy "Public can view transaction counts"
  on d2.transactions for select
  using (true);

-- Rating policies
create policy "Ratings are viewable by everyone"
  on d2.ratings for select
  using (true);

create policy "Transaction participants can rate"
  on d2.ratings for insert
  with check (
    auth.uid() = rater_id
    and auth.uid() in (
      select seller_id from d2.transactions where id = transaction_id
      union
      select buyer_id from d2.transactions where id = transaction_id
    )
    and auth.uid() != rated_id
  );

-- Add reputation stats to profiles
alter table d2.profiles
  add column total_trades integer default 0,
  add column average_rating numeric(3,2) default 0,
  add column rating_count integer default 0;

-- Function to update user reputation after rating
create or replace function d2.update_user_reputation()
returns trigger as $$
begin
  update d2.profiles
  set
    rating_count = (select count(*) from d2.ratings where rated_id = new.rated_id),
    average_rating = (select avg(stars)::numeric(3,2) from d2.ratings where rated_id = new.rated_id)
  where id = new.rated_id;
  return new;
end;
$$ language plpgsql security definer;

-- Trigger to update reputation on new rating
create trigger on_rating_created
  after insert on d2.ratings
  for each row execute procedure d2.update_user_reputation();

-- Function to increment trade count on completed transaction
create or replace function d2.update_trade_counts()
returns trigger as $$
begin
  update d2.profiles set total_trades = total_trades + 1 where id = new.seller_id;
  update d2.profiles set total_trades = total_trades + 1 where id = new.buyer_id;
  return new;
end;
$$ language plpgsql security definer;

-- Trigger to update trade counts
create trigger on_transaction_created
  after insert on d2.transactions
  for each row execute procedure d2.update_trade_counts();

-- Indexes
create index transactions_seller_id_idx on d2.transactions(seller_id);
create index transactions_buyer_id_idx on d2.transactions(buyer_id);
create index ratings_rated_id_idx on d2.ratings(rated_id);
create index ratings_transaction_id_idx on d2.ratings(transaction_id);

-- Enable realtime for trade_requests (for notifications)
alter publication supabase_realtime add table d2.trade_requests;
