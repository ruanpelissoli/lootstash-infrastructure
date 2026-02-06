-- Create decline reasons table
create table d2.decline_reasons (
  id serial primary key,
  code text unique not null,
  message text not null,
  active boolean default true
);

-- Seed decline reasons
insert into d2.decline_reasons (code, message) values
  ('price_too_low', 'The offer is too low'),
  ('item_sold', 'The item has already been sold'),
  ('changed_mind', 'I changed my mind about selling'),
  ('wrong_offer', 'The offer doesn''t match what I''m looking for'),
  ('other', 'Other reason');

-- Add decline columns to trade_requests
alter table d2.trade_requests
  add column decline_reason_id integer references d2.decline_reasons(id),
  add column decline_note text;

-- Index for decline reason lookups
create index trade_requests_decline_reason_id_idx on d2.trade_requests(decline_reason_id);
