/**
 * Local test for parse-review edge function
 *
 * Prerequisites:
 * 1. supabase start
 * 2. supabase functions serve
 * 3. A review with pages must exist in the local DB
 *
 * Run: deno test --allow-net --allow-env --env=supabase/functions/tests/.env supabase/functions/tests/parse-review-local-test.ts
 */

import {
	authenticateTestUser,
	loadTestConfig,
	TEST_REVIEW_ID,
} from "./helpers/test-setup.ts";

const config = loadTestConfig();

// Page numbers - update after verifying which pages contain the forest plot and RoB graph
const FOREST_PLOT_PAGE = 12;
const ROB_GRAPH_PAGE = 10;

Deno.test(
	{
		name: "parse-review (local)",
		sanitizeResources: false,
		sanitizeOps: false,
	},
	async () => {
		const { supabase } = await authenticateTestUser(config);

		console.log("Invoking parse-review...");
		const { data, error } = await supabase.functions.invoke("parse-review", {
			body: {
				review_id: TEST_REVIEW_ID,
				forest_plot_page: FOREST_PLOT_PAGE,
				rob_graph_page: ROB_GRAPH_PAGE,
			},
		});

		if (error) {
			console.error("Error:", error);
			throw error;
		}

		console.log("Result:", JSON.stringify(data, null, 2));
		await supabase.auth.signOut();
	},
);
