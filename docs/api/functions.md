# Edge Functions

SmartGRADE provides an edge function for AI-powered extraction of data from systematic review images.

## parse-review

Extracts structured data from forest plot and risk of bias (ROB) graph images using AI vision models.

### Endpoint

```
POST /functions/v1/parse-review
```

### Authentication

Requires a valid JWT token in the Authorization header.

```javascript
const { data, error } = await supabase.functions.invoke("parse-review", {
  body: {
    review_id: "uuid",
    forest_plot_page: 5,
    rob_graph_page: 7
  }
});
```

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `review_id` | uuid | Yes | ID of the review to parse |
| `forest_plot_page` | integer | Yes | Page number containing the forest plot |
| `rob_graph_page` | integer | Yes | Page number containing the ROB graph |

```json
{
  "review_id": "123e4567-e89b-12d3-a456-426614174000",
  "forest_plot_page": 5,
  "rob_graph_page": 7
}
```

### Response

#### Success (200)

Returns the parsed data stored in the `parsed_reviews` table.

```json
{
  "id": "uuid",
  "review_id": "uuid",
  "forest_plot_page": 5,
  "rob_graph_page": 7,
  "forest_plot_data": {
    "studies": [
      {
        "title": "Smith 2020",
        "effect_size": 0.85,
        "ci_lower": 0.72,
        "ci_upper": 1.01,
        "weight": 15.2
      }
    ],
    "overall_effect": {
      "effect_size": 0.91,
      "ci_lower": 0.85,
      "ci_upper": 0.98
    }
  },
  "rob_graph_data": {
    "domains": [
      "Random sequence generation",
      "Allocation concealment",
      "Blinding of participants",
      "Blinding of outcome assessment",
      "Incomplete outcome data",
      "Selective reporting",
      "Other bias"
    ],
    "assessments": [
      {
        "study": "Smith 2020",
        "ratings": ["low", "low", "high", "unclear", "low", "low", "low"]
      }
    ]
  },
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

#### Error Responses

| Status | Description |
|--------|-------------|
| 400 | Missing required fields |
| 401 | Authentication failed |
| 500 | Server error (page not found, download failed, AI parsing error) |

```json
{
  "error": "Missing required fields"
}
```

### How It Works

1. **Authentication**: Validates the user's JWT token
2. **Image Download**: Fetches the specified page images from storage
3. **Forest Plot Parsing**: Sends the forest plot image to an AI model to extract:
   - Study names and effect sizes
   - Confidence intervals
   - Weights
   - Overall effect estimate
4. **ROB Parsing**: Sends the ROB graph image with study names to extract:
   - Risk of bias domains
   - Per-study assessments (low/high/unclear)
5. **Storage**: Upserts the parsed data to the `parsed_reviews` table

### Upsert Behavior

If parsed data already exists for the review, it will be replaced. The function uses `upsert` with `onConflict: "review_id"`.

### Processing Time

Parsing typically takes 5-15 seconds depending on:
- Image complexity
- Number of studies in the review
- AI model response time

### Example Usage

```javascript
// Parse a review after uploading pages
async function parseReview(reviewId, forestPlotPage, robGraphPage) {
  const { data, error } = await supabase.functions.invoke("parse-review", {
    body: {
      review_id: reviewId,
      forest_plot_page: forestPlotPage,
      rob_graph_page: robGraphPage
    }
  });

  if (error) {
    console.error("Parsing failed:", error.message);
    return null;
  }

  console.log("Forest plot studies:", data.forest_plot_data.studies.length);
  console.log("ROB assessments:", data.rob_graph_data.assessments.length);

  return data;
}
```

### Error Handling

```javascript
const { data, error } = await supabase.functions.invoke("parse-review", {
  body: { review_id: reviewId, forest_plot_page: 5, rob_graph_page: 7 }
});

if (error) {
  if (error.message.includes("not found")) {
    // Page doesn't exist - check page numbers
    console.error("Page not found. Verify the page numbers are correct.");
  } else if (error.message.includes("download")) {
    // Storage issue
    console.error("Failed to download image from storage.");
  } else {
    // AI parsing or other error
    console.error("Parsing error:", error.message);
  }
}
```

### Rate Limits

There are no explicit rate limits, but be mindful of:
- AI model costs per invocation
- Processing time for large reviews
- Storage bandwidth for image downloads
