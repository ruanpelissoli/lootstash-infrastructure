// Supabase Edge Function: send-push-notification
//
// Triggered by a Database Webhook on INSERT into d2.notifications.
// Looks up the user's registered device tokens and sends push notifications
// via the Expo Push API.
//
// Setup:
// 1. Deploy this function: supabase functions deploy send-push-notification
// 2. Create a Database Webhook in Supabase Dashboard:
//    - Table: d2.notifications
//    - Events: INSERT
//    - Type: Supabase Edge Function
//    - Function: send-push-notification
// 3. (Optional) Set EXPO_ACCESS_TOKEN secret for authenticated push sending:
//    supabase secrets set EXPO_ACCESS_TOKEN=your-expo-access-token

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const EXPO_PUSH_URL = 'https://exp.host/--/api/v2/push/send';

// Notification category mapping (mirrors web app)
type NotificationCategory = 'trade' | 'chat' | 'wishlist';

const CATEGORY_MAP: Record<string, NotificationCategory> = {
  trade_request_received: 'trade',
  trade_request_accepted: 'trade',
  trade_request_rejected: 'trade',
  rating_received: 'trade',
  offer_received: 'trade',
  offer_accepted: 'trade',
  offer_rejected: 'trade',
  trade_completed: 'trade',
  service_run_created: 'trade',
  service_run_completed: 'trade',
  service_run_cancelled: 'trade',
  new_message: 'chat',
  wishlist_match: 'wishlist',
};

const CHANNEL_MAP: Record<NotificationCategory, string> = {
  trade: 'trade-notifications',
  chat: 'chat-notifications',
  wishlist: 'wishlist-notifications',
};

interface NotificationRecord {
  id: string;
  user_id: string;
  type: string;
  title: string;
  body: string | null;
  reference_type: string | null;
  reference_id: string | null;
  metadata: Record<string, unknown> | null;
}

/**
 * Compute the deep link route for a notification.
 * Mirrors getNotificationRoute() from the web app.
 */
function getRoute(n: NotificationRecord): string {
  const { type, reference_type, reference_id, metadata } = n;

  // Service run notifications
  if (reference_type === 'service_run' && reference_id) {
    if (type === 'service_run_completed' || type === 'service_run_cancelled') {
      return '/d2/trades?tab=completed';
    }
    return '/d2/trades?tab=active';
  }

  if (type === 'service_run_created') return '/d2/trades?tab=active';
  if (type === 'service_run_completed') return '/d2/trades?tab=completed';
  if (type === 'service_run_cancelled') return '/d2/trades?tab=completed';

  // Trade request / offer notifications
  if ((reference_type === 'trade_request' || reference_type === 'offer') && reference_id) {
    if (type === 'new_message') return `/d2/chat?trade=${reference_id}`;
    if (type === 'trade_request_received' || type === 'offer_received')
      return '/d2/trades?tab=received';
    if (type === 'trade_request_accepted' || type === 'offer_accepted')
      return '/d2/trades?tab=active';
    if (type === 'trade_request_rejected' || type === 'offer_rejected')
      return '/d2/trades?tab=sent';
    return '/d2/trades';
  }

  // Chat notifications
  if (reference_type === 'chat' && reference_id) {
    return `/d2/chat?trade=${reference_id}`;
  }

  // Rating notifications
  if (reference_type === 'transaction' || reference_type === 'rating') {
    return '/d2/trades';
  }

  // Wishlist match — link to the listing
  if (reference_type === 'listing' && reference_id) {
    return `/d2/item/${reference_id}`;
  }

  // Fallback for listing ID in metadata
  const listingId = metadata?.listingId as string | undefined;
  if (type === 'wishlist_match' && listingId) {
    return `/d2/item/${listingId}`;
  }

  // Default fallback by type
  switch (type) {
    case 'trade_request_received':
    case 'offer_received':
      return '/d2/trades?tab=received';
    case 'trade_request_accepted':
    case 'offer_accepted':
      return '/d2/trades?tab=active';
    case 'trade_request_rejected':
    case 'offer_rejected':
      return '/d2/trades?tab=sent';
    case 'trade_completed':
      return '/d2/trades?tab=completed';
    case 'new_message':
      return '/d2/chat';
    case 'wishlist_match':
      return '/d2/wishlist';
    default:
      return '/d2';
  }
}

Deno.serve(async (req) => {
  try {
    const payload = await req.json();

    // The webhook payload contains the inserted record
    const record = payload.record as NotificationRecord | undefined;
    if (!record) {
      return new Response(JSON.stringify({ error: 'No record in payload' }), {
        status: 400,
      });
    }

    // Create Supabase client with service role key to bypass RLS
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // Look up device tokens for this user
    const { data: tokens, error: tokensError } = await supabase
      .from('device_tokens')
      .select('expo_push_token')
      .eq('user_id', record.user_id)
      .schema('d2');

    if (tokensError) {
      console.error('Failed to fetch device tokens:', tokensError);
      return new Response(JSON.stringify({ error: 'Failed to fetch tokens' }), {
        status: 500,
      });
    }

    if (!tokens || tokens.length === 0) {
      // No registered devices — nothing to send
      return new Response(JSON.stringify({ sent: 0 }), { status: 200 });
    }

    // Build push notification messages
    const category = CATEGORY_MAP[record.type] ?? 'trade';
    const channelId = CHANNEL_MAP[category];
    const route = getRoute(record);

    const messages = tokens.map(
      (t: { expo_push_token: string }) => ({
        to: t.expo_push_token,
        title: record.title,
        body: record.body ?? '',
        data: { route, notificationId: record.id },
        channelId,
        sound: 'default',
        priority: category === 'chat' ? 'high' : 'default',
      })
    );

    // Send via Expo Push API
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    };

    // Use Expo access token if available (recommended for production)
    const expoAccessToken = Deno.env.get('EXPO_ACCESS_TOKEN');
    if (expoAccessToken) {
      headers['Authorization'] = `Bearer ${expoAccessToken}`;
    }

    const pushResponse = await fetch(EXPO_PUSH_URL, {
      method: 'POST',
      headers,
      body: JSON.stringify(messages),
    });

    const pushResult = await pushResponse.json();

    console.log(
      `Sent ${messages.length} push notification(s) for ${record.type} to user ${record.user_id}`
    );

    return new Response(
      JSON.stringify({ sent: messages.length, result: pushResult }),
      { status: 200 }
    );
  } catch (error) {
    console.error('Push notification error:', error);
    return new Response(
      JSON.stringify({ error: String(error) }),
      { status: 500 }
    );
  }
});
