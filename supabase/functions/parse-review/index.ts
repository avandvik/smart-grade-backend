import "@supabase/functions-js/edge-runtime.d.ts";
import { authenticateUser } from "@shared/services/auth.service.ts";
import {
	parseForestPlot,
	parseRiskOfBias,
} from "@shared/services/llm.service.ts";
import type { ParseReviewRequest } from "@shared/types/index.ts";
import { handleCors } from "@shared/utils/cors.ts";
import { errorResponse, successResponse } from "@shared/utils/response.ts";
import type { SupabaseClient } from "@supabase/supabase-js";

async function blobToBase64(blob: Blob): Promise<string> {
	const arrayBuffer = await blob.arrayBuffer();
	const bytes = new Uint8Array(arrayBuffer);
	let binary = "";
	for (let i = 0; i < bytes.length; i++) {
		binary += String.fromCharCode(bytes[i]);
	}
	return btoa(binary);
}

async function downloadPageSections(
	supabase: SupabaseClient,
	reviewId: string,
	pageNumber: number,
): Promise<string[]> {
	const { data: sections, error: pageError } = await supabase
		.from("review_pages")
		.select("image_path, section_number")
		.eq("review_id", reviewId)
		.eq("page_number", pageNumber)
		.order("section_number");

	if (pageError || !sections || sections.length === 0) {
		throw new Error(`Page ${pageNumber} not found`);
	}

	const downloadPromises = sections.map(async (section) => {
		const { data: blob, error: downloadError } = await supabase.storage
			.from("reviews")
			.download(section.image_path);

		if (downloadError || !blob) {
			throw new Error(
				`Failed to download page ${pageNumber} section ${section.section_number}`,
			);
		}

		return blobToBase64(blob);
	});

	return Promise.all(downloadPromises);
}

Deno.serve(async (req: Request) => {
	const corsResponse = handleCors(req);
	if (corsResponse) return corsResponse;

	try {
		const { supabase } = await authenticateUser(
			req.headers.get("Authorization"),
			req.headers.get("apiKey"),
		);

		const body = (await req.json()) as ParseReviewRequest;
		const { review_id, forest_plot_page, rob_graph_page } = body;

		if (!review_id || !forest_plot_page || !rob_graph_page) {
			return errorResponse("Missing required fields", 400);
		}

		const [forestPlotImages, robImages] = await Promise.all([
			downloadPageSections(supabase, review_id, forest_plot_page),
			downloadPageSections(supabase, review_id, rob_graph_page),
		]);

		const forestPlotData = await parseForestPlot(forestPlotImages);
		const studyTitles = forestPlotData.studies.map((s) => s.title);
		const robData = await parseRiskOfBias(robImages, studyTitles);

		const { data: parsedReview, error: upsertError } = await supabase
			.from("parsed_reviews")
			.upsert(
				{
					review_id,
					forest_plot_page,
					rob_graph_page,
					forest_plot_data: forestPlotData,
					rob_graph_data: robData,
				},
				{ onConflict: "review_id" },
			)
			.select()
			.single();

		if (upsertError) {
			throw new Error(`Failed to save parsed data: ${upsertError.message}`);
		}

		return successResponse(parsedReview);
	} catch (error) {
		const message = error instanceof Error ? error.message : String(error);
		console.error("Error:", message);
		return errorResponse(message, 500);
	}
});
