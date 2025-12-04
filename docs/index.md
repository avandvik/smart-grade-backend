# SmartGRADE Backend

Systematic Review Analysis API with AI-powered data extraction from forest plots and risk of bias graphs.

## Features

- **Review Management**: Upload and organize systematic review PDFs
- **Page Extraction**: Convert PDF pages to images for analysis
- **AI-Powered Parsing**: Extract structured data from forest plots and risk of bias graphs
- **Built on Supabase**: Authentication, database, storage, and edge functions

## Quick Start

```javascript
import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
  "https://redzwiaseoavjbahsjgw.supabase.co",
  "sb_publishable_FFURYQgBt1RQh2CkPGuoag_IyF3fWXE"
);

// Sign in
const { data: { user } } = await supabase.auth.signInWithPassword({
  email: "user@example.com",
  password: "password"
});

// Fetch your reviews
const { data: reviews } = await supabase
  .from("reviews")
  .select("*, review_pages(*), parsed_reviews(*)")
  .order("created_at", { ascending: false });

// Parse a review using the edge function
const { data: parsed } = await supabase.functions.invoke("parse-review", {
  body: {
    review_id: "review-uuid",
    forest_plot_page: 5,
    rob_graph_page: 7
  }
});
```

## Documentation

- [API Documentation](/api/) - Complete API reference
- [Authentication](/api/authentication) - User authentication with Supabase Auth
- [Database](/api/database) - Schema and table documentation
- [Functions](/api/functions) - Edge function for parsing reviews

## Examples

- [Create Review](/api/examples/create-review) - Upload a systematic review PDF
- [Upload Pages](/api/examples/upload-pages) - Extract and store page images
- [Parse Review](/api/examples/parse-review) - Extract data using AI
