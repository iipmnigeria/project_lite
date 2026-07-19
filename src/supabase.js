import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://bkueblqrabvpsifdbuko.supabase.co';
const supabasePublishableKey = 'sb_publishable__H3ygSdAFOn8rrT9kpyubA_3hPn7nmS';

export const supabase = createClient(supabaseUrl, supabasePublishableKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
});
