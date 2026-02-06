-- Ensure d2 schema exists
CREATE SCHEMA IF NOT EXISTS d2;

-- Create profiles table
create table d2.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  username text unique not null,
  display_name text,
  avatar_url text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table d2.profiles enable row level security;

-- Create policies
create policy "Public profiles are viewable by everyone."
  on d2.profiles for select
  using (true);

create policy "Users can insert their own profile."
  on d2.profiles for insert
  with check (auth.uid() = id);

create policy "Users can update their own profile."
  on d2.profiles for update
  using (auth.uid() = id);

-- Create function to handle updated_at
create or replace function d2.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Create trigger for updated_at
create trigger on_profiles_updated
  before update on d2.profiles
  for each row execute procedure d2.handle_updated_at();

-- Create function to handle new user
create or replace function d2.handle_new_user()
returns trigger as $$
begin
  insert into d2.profiles (id, username, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1))
  );
  return new;
end;
$$ language plpgsql security definer;

-- Create trigger for new user
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure d2.handle_new_user();
