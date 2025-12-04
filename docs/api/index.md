# API Documentation

SmartGRADE provides a systematic review analysis API built on Supabase infrastructure.

## Core Capabilities

- **Reviews**: Store and manage systematic review documents
- **Page Extraction**: Convert PDF pages to images for analysis
- **AI Parsing**: Extract structured data from forest plots and risk of bias graphs
- **User Scoping**: All data is automatically scoped to the authenticated user

## Configuration

```javascript
import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
  "https://redzwiaseoavjbahsjgw.supabase.co",
  "sb_publishable_FFURYQgBt1RQh2CkPGuoag_IyF3fWXE"
);
```

## Quick Start

```javascript
// 1. Sign in
const { data: { user } } = await supabase.auth.signInWithPassword({
  email: "user@example.com",
  password: "password"
});

// 2. Create a review
const { data: review } = await supabase
  .from("reviews")
  .insert({ title: "My Systematic Review" })
  .select()
  .single();

// 3. Upload page images (after PDF extraction)
const { data: upload } = await supabase.storage
  .from("reviews")
  .upload(`${user.id}/${review.id}/pages/page_1.png`, imageFile);

const { data: page } = await supabase
  .from("review_pages")
  .insert({
    review_id: review.id,
    page_number: 1,
    image_path: upload.path
  })
  .select()
  .single();

// 4. Parse forest plot and ROB graph
const { data: parsed } = await supabase.functions.invoke("parse-review", {
  body: {
    review_id: review.id,
    forest_plot_page: 5,
    rob_graph_page: 7
  }
});
```

## API Reference

| Section | Description |
|---------|-------------|
| [Authentication](/api/authentication) | User sign-up, sign-in, and session management |
| [Database](/api/database) | Tables for reviews, pages, and parsed data |
| [Functions](/api/functions) | Edge function for AI-powered parsing |

## Examples

| Example | Description |
|---------|-------------|
| [Create Review](/api/examples/create-review) | Create a review and upload a PDF |
| [Upload Pages](/api/examples/upload-pages) | Extract and upload page images |
| [Parse Review](/api/examples/parse-review) | Extract data from forest plots and ROB graphs |
