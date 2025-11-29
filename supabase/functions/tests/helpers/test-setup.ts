import { createClient, type SupabaseClient } from "@supabase/supabase-js";

// Seeded test IDs (from seeds/01_users.sql and seed-storage.ts)
export const TEST_USER_ID = "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d";
export const TEST_REVIEW_ID = "b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e";

export interface TestConfig {
	supabaseUrl: string;
	supabaseKey: string;
	testUserEmail: string;
	testUserPassword: string;
}

export function loadTestConfig(): TestConfig {
	const supabaseUrl = Deno.env.get("SUPABASE_URL");
	const supabaseKey = Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
	const testUserEmail = Deno.env.get("TEST_USER_EMAIL");
	const testUserPassword = Deno.env.get("TEST_USER_PASSWORD");

	if (!supabaseUrl || !supabaseKey || !testUserEmail || !testUserPassword) {
		throw new Error(
			"Missing required env vars. Run with --env=supabase/functions/tests/.env",
		);
	}

	return { supabaseUrl, supabaseKey, testUserEmail, testUserPassword };
}

export async function authenticateTestUser(config: TestConfig): Promise<{
	supabase: SupabaseClient;
	accessToken: string;
}> {
	const supabase = createClient(config.supabaseUrl, config.supabaseKey, {
		auth: { persistSession: false },
	});

	const { data, error } = await supabase.auth.signInWithPassword({
		email: config.testUserEmail,
		password: config.testUserPassword,
	});

	if (error || !data.session) {
		throw error || new Error("No session");
	}

	console.log(`Authenticated as ${data.user?.email}`);
	return { supabase, accessToken: data.session.access_token };
}
