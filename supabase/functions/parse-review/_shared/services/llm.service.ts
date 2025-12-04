import Anthropic from "@anthropic-ai/sdk";
import type { BiasStudiesData, ForestPlotData } from "../types/index.ts";

const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY") });

const forestPlotTool = {
	name: "extract_forest_plot",
	description: "Extract structured data from a forest plot image",
	input_schema: {
		type: "object" as const,
		properties: {
			effect_estimate_type: {
				type: "string" as const,
				enum: ["RR", "OR", "MD", "SMD"],
			},
			pooled_estimate: { type: "number" as const },
			pooled_lower_ci: { type: "number" as const },
			pooled_upper_ci: { type: "number" as const },
			studies: {
				type: "array" as const,
				items: {
					type: "object" as const,
					properties: {
						title: { type: "string" as const },
						weight: { type: "number" as const },
						point_estimate: { type: "number" as const },
						lower_ci: { type: "number" as const },
						upper_ci: { type: "number" as const },
						sample_size: { type: "integer" as const },
					},
					required: [
						"title",
						"weight",
						"point_estimate",
						"lower_ci",
						"upper_ci",
						"sample_size",
					],
				},
			},
			aggregated_stats: {
				type: "object" as const,
				properties: {
					i_squared: { type: "number" as const },
					p_value: { type: "number" as const },
				},
				required: ["i_squared", "p_value"],
			},
		},
		required: [
			"effect_estimate_type",
			"pooled_estimate",
			"pooled_lower_ci",
			"pooled_upper_ci",
			"studies",
			"aggregated_stats",
		],
	},
};

const riskOfBiasTool = {
	name: "extract_risk_of_bias",
	description: "Extract risk of bias data from a risk of bias graph",
	input_schema: {
		type: "object" as const,
		properties: {
			bias_studies: {
				type: "array" as const,
				items: {
					type: "object" as const,
					properties: {
						title: { type: "string" as const },
						bias_classification: {
							type: "object" as const,
							properties: {
								selection_bias_1: {
									type: "string" as const,
									enum: ["low", "uncertain", "high"],
								},
								selection_bias_2: {
									type: "string" as const,
									enum: ["low", "uncertain", "high"],
								},
								performance_bias: {
									type: "string" as const,
									enum: ["low", "uncertain", "high"],
								},
								detection_bias: {
									type: "string" as const,
									enum: ["low", "uncertain", "high"],
								},
								attrition_bias: {
									type: "string" as const,
									enum: ["low", "uncertain", "high"],
								},
								reporting_bias: {
									type: "string" as const,
									enum: ["low", "uncertain", "high"],
								},
								other_bias: {
									type: "string" as const,
									enum: ["low", "uncertain", "high"],
								},
							},
							required: [
								"selection_bias_1",
								"selection_bias_2",
								"performance_bias",
								"detection_bias",
								"attrition_bias",
								"reporting_bias",
								"other_bias",
							],
						},
					},
					required: ["title", "bias_classification"],
				},
			},
		},
		required: ["bias_studies"],
	},
};

const FOREST_PLOT_PROMPT = `Extract from this forest plot:
- Effect type (RR/OR/MD/SMD)
- Pooled estimate with CI bounds
- Each study: title (format "Author (Year)"), weight %, point estimate, CI bounds, sample size
- I² and p-value

Extract values precisely as shown.`;

function buildRobPrompt(studyTitles: string[]): string {
	return `Extract risk of bias for these studies from the graph:
${studyTitles.map((t) => `- ${t}`).join("\n")}

For each domain (selection_bias_1, selection_bias_2, performance_bias, detection_bias, attrition_bias, reporting_bias, other_bias):
- Green = "low", Yellow = "uncertain", Red = "high"`;
}

async function callClaude<T>(
	imageBase64: string,
	prompt: string,
	tool: typeof forestPlotTool | typeof riskOfBiasTool,
): Promise<T> {
	const message = await anthropic.messages.create({
		model: "claude-sonnet-4-5",
		max_tokens: 4096,
		tools: [tool],
		tool_choice: { type: "tool", name: tool.name },
		messages: [
			{
				role: "user",
				content: [
					{
						type: "image",
						source: {
							type: "base64",
							media_type: "image/png",
							data: imageBase64,
						},
					},
					{ type: "text", text: prompt },
				],
			},
		],
	});

	const toolUse = message.content.find((block) => block.type === "tool_use");
	if (!toolUse || toolUse.type !== "tool_use") {
		console.error("Claude response:", JSON.stringify(message.content));
		throw new Error("Claude did not return tool response");
	}
	return toolUse.input as T;
}

export function parseForestPlot(imageBase64: string): Promise<ForestPlotData> {
	return callClaude<ForestPlotData>(
		imageBase64,
		FOREST_PLOT_PROMPT,
		forestPlotTool,
	);
}

export function parseRiskOfBias(
	imageBase64: string,
	studyTitles: string[],
): Promise<BiasStudiesData> {
	return callClaude<BiasStudiesData>(
		imageBase64,
		buildRobPrompt(studyTitles),
		riskOfBiasTool,
	);
}
