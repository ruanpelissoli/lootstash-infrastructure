-- Create listings table for items being traded
create table d2.listings (
  id uuid default gen_random_uuid() primary key,
  seller_id uuid references d2.profiles(id) on delete cascade not null,

  -- Item details
  name text not null,
  item_type text not null,
  rarity text not null check (rarity in ('normal', 'magic', 'rare', 'unique', 'legendary', 'set', 'runeword')),
  image_url text,
  category text not null,

  -- Item stats/suffixes stored as JSONB for flexibility
  stats jsonb default '[]'::jsonb,
  suffixes jsonb default '[]'::jsonb,

  -- What the seller wants in return
  asking_for jsonb default '[]'::jsonb, -- Array of items/runes they want
  asking_price text, -- Optional price string like "2.5 Ist"
  notes text, -- Additional notes from seller

  -- Game-specific metadata
  game text not null default 'diablo2',
  ladder boolean default true,
  hardcore boolean default false,
  platform text default 'pc', -- pc, xbox, playstation, switch

  -- Status
  status text not null default 'active' check (status in ('active', 'pending', 'completed', 'cancelled')),

  -- Timestamps
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  expires_at timestamp with time zone default (timezone('utc'::text, now()) + interval '30 days')
);

-- Enable RLS
alter table d2.listings enable row level security;

-- Policies
create policy "Listings are viewable by everyone"
  on d2.listings for select
  using (true);

create policy "Users can create their own listings"
  on d2.listings for insert
  with check (auth.uid() = seller_id);

create policy "Users can update their own listings"
  on d2.listings for update
  using (auth.uid() = seller_id);

create policy "Users can delete their own listings"
  on d2.listings for delete
  using (auth.uid() = seller_id);

-- Trigger for updated_at
create trigger on_listings_updated
  before update on d2.listings
  for each row execute procedure d2.handle_updated_at();

-- Indexes for common queries
create index listings_seller_id_idx on d2.listings(seller_id);
create index listings_game_idx on d2.listings(game);
create index listings_category_idx on d2.listings(category);
create index listings_status_idx on d2.listings(status);
create index listings_created_at_idx on d2.listings(created_at desc);
