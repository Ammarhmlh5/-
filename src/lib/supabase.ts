import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  const errorMessage = `
❌ Missing Supabase configuration!

Please set the following environment variables:
  - VITE_SUPABASE_URL=your_supabase_project_url
  - VITE_SUPABASE_ANON_KEY=your_supabase_anon_key

See .env.example for reference.
  `;
  console.error(errorMessage);
  throw new Error(
    'Missing Supabase configuration. Please set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY in your .env file. See .env.example for reference.'
  );
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
