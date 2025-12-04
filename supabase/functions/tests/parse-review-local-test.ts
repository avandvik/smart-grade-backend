/**
 * Test for parse-review edge function
 *
 * Local:  deno task test:local
 * Remote: deno task test:remote
 */

import {
	authenticateTestUser,
	loadTestConfig,
	TEST_REVIEW_ID,
} from "./helpers/test-setup.ts";

const config = loadTestConfig();
const isLocal = config.supabaseUrl.includes("127.0.0.1");

// Page numbers - update after verifying which pages contain the forest plot and RoB graph
const FOREST_PLOT_PAGE = 12;
const ROB_GRAPH_PAGE = 10;

Deno.test(
	{
		name: `parse-review (${isLocal ? "local" : "remote"})`,
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

		// Verify response shape
		if (
			!data.id ||
			!data.review_id ||
			!data.forest_plot_data ||
			!data.rob_graph_data
		) {
			throw new Error("Response missing expected fields");
		}
		console.log("Response shape OK");

		// Verify persistence
		const { data: dbRecord, error: dbError } = await supabase
			.from("parsed_reviews")
			.select()
			.eq("review_id", TEST_REVIEW_ID)
			.single();

		if (dbError || !dbRecord) {
			throw new Error("Record not persisted to database");
		}
		console.log("Database persistence OK");

		console.log("Result:", JSON.stringify(data, null, 2));
		await supabase.auth.signOut();
	},
);
