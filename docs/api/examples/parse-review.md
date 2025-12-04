# Parse Review

Use the AI-powered edge function to extract structured data from forest plots and risk of bias graphs.

## Basic Usage

```javascript
const { data, error } = await supabase.functions.invoke("parse-review", {
  body: {
    review_id: reviewId,
    forest_plot_page: 5,
    rob_graph_page: 7
  }
});

if (error) {
  console.error("Parsing failed:", error.message);
} else {
  console.log("Parsed data:", data);
}
```

## Complete Parsing Workflow

```javascript
async function parseReview(reviewId, forestPlotPage, robGraphPage) {
  // 1. Verify pages exist
  const { data: pages } = await supabase
    .from("review_pages")
    .select("page_number")
    .eq("review_id", reviewId)
    .in("page_number", [forestPlotPage, robGraphPage]);

  if (pages.length !== 2) {
    throw new Error("One or both pages not found");
  }

  // 2. Mark pages as special (optional, for UI purposes)
  await supabase
    .from("review_pages")
    .update({ is_forest_plot: true })
    .eq("review_id", reviewId)
    .eq("page_number", forestPlotPage);

  await supabase
    .from("review_pages")
    .update({ is_rob_graph: true })
    .eq("review_id", reviewId)
    .eq("page_number", robGraphPage);

  // 3. Invoke the parsing function
  const { data, error } = await supabase.functions.invoke("parse-review", {
    body: {
      review_id: reviewId,
      forest_plot_page: forestPlotPage,
      rob_graph_page: robGraphPage
    }
  });

  if (error) throw error;

  return data;
}
```

## Working with Parsed Data

### Access Forest Plot Data

```javascript
const { data: parsed } = await supabase
  .from("parsed_reviews")
  .select("forest_plot_data")
  .eq("review_id", reviewId)
  .single();

const { studies, overall_effect } = parsed.forest_plot_data;

// List all studies
studies.forEach(study => {
  console.log(`${study.title}: ${study.effect_size} [${study.ci_lower}, ${study.ci_upper}]`);
});

// Overall effect
console.log(`Overall: ${overall_effect.effect_size} [${overall_effect.ci_lower}, ${overall_effect.ci_upper}]`);
```

### Access Risk of Bias Data

```javascript
const { data: parsed } = await supabase
  .from("parsed_reviews")
  .select("rob_graph_data")
  .eq("review_id", reviewId)
  .single();

const { domains, assessments } = parsed.rob_graph_data;

// List domains
console.log("ROB Domains:", domains);

// Show assessments for each study
assessments.forEach(assessment => {
  console.log(`\n${assessment.study}:`);
  domains.forEach((domain, i) => {
    console.log(`  ${domain}: ${assessment.ratings[i]}`);
  });
});
```

### Get Review with All Parsed Data

```javascript
const { data: review } = await supabase
  .from("reviews")
  .select(`
    *,
    review_pages(*),
    parsed_reviews(*)
  `)
  .eq("id", reviewId)
  .single();

if (review.parsed_reviews) {
  const { forest_plot_data, rob_graph_data } = review.parsed_reviews;
  console.log("Studies:", forest_plot_data.studies.length);
  console.log("ROB domains:", rob_graph_data.domains.length);
}
```

## Re-parse a Review

The parse function uses upsert, so calling it again replaces existing data:

```javascript
// Re-parse with different pages
const { data } = await supabase.functions.invoke("parse-review", {
  body: {
    review_id: reviewId,
    forest_plot_page: 8,  // Different page
    rob_graph_page: 10    // Different page
  }
});
```

## Error Handling

```javascript
async function safeParseReview(reviewId, forestPlotPage, robGraphPage) {
  try {
    const { data, error } = await supabase.functions.invoke("parse-review", {
      body: {
        review_id: reviewId,
        forest_plot_page: forestPlotPage,
        rob_graph_page: robGraphPage
      }
    });

    if (error) {
      // Handle specific error cases
      if (error.message.includes("not found")) {
        return { success: false, error: "Page not found. Check page numbers." };
      }
      if (error.message.includes("download")) {
        return { success: false, error: "Failed to download page image." };
      }
      return { success: false, error: error.message };
    }

    return { success: true, data };
  } catch (err) {
    return { success: false, error: "Network or server error" };
  }
}
```

## Check if Review is Parsed

```javascript
async function isReviewParsed(reviewId) {
  const { data, error } = await supabase
    .from("parsed_reviews")
    .select("id")
    .eq("review_id", reviewId)
    .single();

  return !error && data !== null;
}
```

## Delete Parsed Data

Deleting parsed data allows re-parsing:

```javascript
await supabase
  .from("parsed_reviews")
  .delete()
  .eq("review_id", reviewId);
```

## UI Integration Example

```javascript
async function handleParseClick(reviewId) {
  const forestPlotPage = parseInt(document.getElementById("forestPlotPage").value);
  const robGraphPage = parseInt(document.getElementById("robGraphPage").value);

  // Show loading state
  setLoading(true);
  setError(null);

  try {
    const { data, error } = await supabase.functions.invoke("parse-review", {
      body: {
        review_id: reviewId,
        forest_plot_page: forestPlotPage,
        rob_graph_page: robGraphPage
      }
    });

    if (error) throw error;

    // Update UI with results
    displayForestPlotData(data.forest_plot_data);
    displayRobData(data.rob_graph_data);

  } catch (err) {
    setError(err.message);
  } finally {
    setLoading(false);
  }
}
```

## Export Parsed Data

```javascript
async function exportParsedData(reviewId) {
  const { data: review } = await supabase
    .from("reviews")
    .select("title, parsed_reviews(*)")
    .eq("id", reviewId)
    .single();

  if (!review.parsed_reviews) {
    throw new Error("Review has not been parsed");
  }

  const exportData = {
    review_title: review.title,
    parsed_at: review.parsed_reviews.updated_at,
    forest_plot: review.parsed_reviews.forest_plot_data,
    risk_of_bias: review.parsed_reviews.rob_graph_data
  };

  // Download as JSON
  const blob = new Blob([JSON.stringify(exportData, null, 2)], {
    type: "application/json"
  });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `${review.title.replace(/\s+/g, "_")}_parsed.json`;
  a.click();
}
```

## Aggregate Statistics

```javascript
function calculateStatistics(forestPlotData) {
  const { studies, overall_effect } = forestPlotData;

  return {
    studyCount: studies.length,
    overallEffect: overall_effect.effect_size,
    overallCI: [overall_effect.ci_lower, overall_effect.ci_upper],
    averageWeight: studies.reduce((sum, s) => sum + (s.weight || 0), 0) / studies.length,
    significantStudies: studies.filter(s =>
      s.ci_lower > 1 || s.ci_upper < 1 // Assuming odds ratio
    ).length
  };
}
```
