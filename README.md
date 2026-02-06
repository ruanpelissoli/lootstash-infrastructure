# Lootstash Infrastructure

Database migrations and Supabase configuration for the Lootstash trading platform.

## Structure

```
lootstash-infrastructure/
├── supabase/
│   ├── config.toml        # Supabase project configuration
│   └── migrations/        # Database migrations
└── README.md
```

## Setup

### Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli)
- Access to Supabase project

### Link to Project

```bash
supabase link --project-ref <project-id>
```

### Apply Migrations

```bash
# Apply all pending migrations
supabase db push

# Check migration status
supabase migration list
```

### Create New Migration

```bash
supabase migration new <migration_name>
```

## Database Schema

All tables use the `d2` schema with Row Level Security (RLS) enabled.

### Core Tables

| Table | Purpose |
|-------|---------|
| `profiles` | User profiles with premium status, ratings, linked accounts |
| `listings` | Item listings for sale/trade |
| `offers` | Trade offers on listings |
| `trades` | Active and completed trades |
| `chats` | Trade chat rooms |
| `messages` | Chat messages |
| `transactions` | Completed trade records (for ratings) |
| `ratings` | User ratings (1-5 stars) |
| `notifications` | User notifications |
| `wishlist_items` | Premium user wishlists |
| `billing_events` | Stripe billing history |
| `decline_reasons` | Offer rejection reasons |
| `marketplace_stats` | Aggregated marketplace statistics |

### Enums

- **Rarity**: normal, magic, rare, unique, legendary, set, runeword
- **Platform**: pc, xbox, playstation, switch
- **Region**: americas, europe, asia
- **Listing status**: active, pending, completed, cancelled
- **Offer status**: pending, accepted, rejected, cancelled
- **Trade status**: active, completed, cancelled
- **Notification type**: trade_request_received, trade_request_accepted, trade_request_rejected, new_message, rating_received, wishlist_match
- **Message type**: text, system, trade_update

## Related Repositories

- [lootstash-catalog-api](https://github.com/ruanpelissoli/lootstash-catalog-api) - Static D2 item data service
- [lootstash-marketplace-api](https://github.com/ruanpelissoli/lootstash-marketplace-api) - Trading platform service
