import type { SupabaseClient } from "@supabase/supabase-js";
import { createClient } from "@supabase/supabase-js";

export async function authenticateUser(
  authHeader: string | null,
  apiKey: string | null,
): Promise<{ supabase: SupabaseClient }> {
  if (!authHeader || !apiKey) {
    throw new Error("Missing authorization");
  }

  const token = authHeader.replace("Bearer ", "");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");

  if (!supabaseUrl) {
    throw new Error("Missing SUPABASE_URL");
  }

  const supabase = createClient(supabaseUrl, apiKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });

  const { error } = await supabase.auth.getUser(token);
  if (error) {
    throw new Error("Authentication failed");
  }

  return { supabase };
}
