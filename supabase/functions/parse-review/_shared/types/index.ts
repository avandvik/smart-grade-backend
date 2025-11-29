// Request
export interface ParseReviewRequest {
  review_id: string;
  forest_plot_page: number;
  rob_graph_page: number;
}

// Forest Plot
export interface ForestPlotStudy {
  title: string;
  weight: number;
  point_estimate: number;
  lower_ci: number;
  upper_ci: number;
  sample_size: number;
}

export interface ForestPlotAggregatedStats {
  i_squared: number;
  p_value: number;
}

export interface ForestPlotData {
  effect_estimate_type: "RR" | "OR" | "MD" | "SMD";
  pooled_estimate: number;
  pooled_lower_ci: number;
  pooled_upper_ci: number;
  studies: ForestPlotStudy[];
  aggregated_stats: ForestPlotAggregatedStats;
}

// Risk of Bias
export type RiskOfBias = "low" | "uncertain" | "high";

export interface BiasClassification {
  selection_bias_1: RiskOfBias;
  selection_bias_2: RiskOfBias;
  performance_bias: RiskOfBias;
  detection_bias: RiskOfBias;
  attrition_bias: RiskOfBias;
  reporting_bias: RiskOfBias;
  other_bias: RiskOfBias;
}

export interface BiasStudy {
  title: string;
  bias_classification: BiasClassification;
}

export interface BiasStudiesData {
  bias_studies: BiasStudy[];
}
