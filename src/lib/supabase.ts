import { createClient } from '@supabase/supabase-js';

// SAYED must use its own Supabase project.
const DEFAULT_SAYED_URL = 'https://nahptrsihcidcxkjzwdp.supabase.co';
const DEFAULT_SAYED_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5haHB0cnNpaGNpZGN4a2p6d2RwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgwMjI5OTgsImV4cCI6MjEwMzU5ODk5OH0.Q01osKJJrRDsg94LRsY70kytk8Ktoe2-lSUYG7I1S-8';

const supabaseUrl =
  (import.meta.env.VITE_SUPABASE_URL as string | undefined)?.trim() || DEFAULT_SAYED_URL;
const supabaseAnonKey =
  (import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined)?.trim() || DEFAULT_SAYED_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('SAYED Supabase configuration is missing. Set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY.');
}

if (!supabaseUrl.includes('nahptrsihcidcxkjzwdp.supabase.co')) {
  throw new Error(`Invalid SAYED Supabase project: ${supabaseUrl}`);
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
});
