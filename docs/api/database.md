# Database

SmartGRADE uses three main tables to store systematic review data.

## Schema Overview

```
reviews (1) ──────┬────── (N) review_pages
                  │
                  └────── (1) parsed_reviews
```

## Tables

### reviews

Core table representing systematic review documents.

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key, auto-generated |
| `user_id` | uuid | Foreign key to auth.users, auto-set from auth |
| `title` | text | Review title (1-500 characters) |
| `pdf_path` | text | Optional path to PDF in storage |
| `created_at` | timestamptz | Auto-set on insert |
| `updated_at` | timestamptz | Auto-updated on changes |

**RLS Policies**: Users can only access their own reviews.

```javascript
// Create a review
const { data } = await supabase
  .from("reviews")
  .insert({ title: "COVID-19 Treatment Efficacy" })
  .select()
  .single();

// List all reviews
const { data } = await supabase
  .from("reviews")
  .select("*")
  .order("created_at", { ascending: false });

// Get review with related data
const { data } = await supabase
  .from("reviews")
  .select("*, review_pages(*), parsed_reviews(*)")
  .eq("id", reviewId)
  .single();

// Update review
const { data } = await supabase
  .from("reviews")
  .update({ title: "Updated Title" })
  .eq("id", reviewId)
  .select()
  .single();

// Delete review (cascades to pages and parsed data)
await supabase
  .from("reviews")
  .delete()
  .eq("id", reviewId);
```

### review_pages

Individual pages extracted from review PDFs.

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key, auto-generated |
| `review_id` | uuid | Foreign key to reviews (cascade delete) |
| `page_number` | integer | Page number (must be > 0, unique per review) |
| `image_path` | text | Required path to image in storage |
| `is_rob_graph` | boolean | True if page contains ROB graph (default false) |
| `is_forest_plot` | boolean | True if page contains forest plot (default false) |
| `created_at` | timestamptz | Auto-set on insert |

**Unique Constraint**: `(review_id, page_number)` - each page number can only appear once per review.

**RLS Policies**: Users can only access pages belonging to their own reviews.

```javascript
// Add a page
const { data } = await supabase
  .from("review_pages")
  .insert({
    review_id: reviewId,
    page_number: 1,
    image_path: "user-id/review-id/pages/page_1.png"
  })
  .select()
  .single();

// List pages for a review
const { data } = await supabase
  .from("review_pages")
  .select("*")
  .eq("review_id", reviewId)
  .order("page_number");

// Mark page as forest plot
const { data } = await supabase
  .from("review_pages")
  .update({ is_forest_plot: true })
  .eq("id", pageId)
  .select()
  .single();

// Get special pages (ROB graphs and forest plots)
const { data } = await supabase
  .from("review_pages")
  .select("*")
  .eq("review_id", reviewId)
  .or("is_rob_graph.eq.true,is_forest_plot.eq.true");
```

### parsed_reviews

AI-extracted data from forest plots and ROB graphs.

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key, auto-generated |
| `review_id` | uuid | Foreign key to reviews (cascade delete, unique) |
| `forest_plot_page` | integer | Page number of the forest plot |
| `rob_graph_page` | integer | Page number of the ROB graph |
| `forest_plot_data` | jsonb | Extracted forest plot data |
| `rob_graph_data` | jsonb | Extracted ROB assessment data |
| `created_at` | timestamptz | Auto-set on insert |
| `updated_at` | timestamptz | Auto-updated on changes |

**Unique Constraint**: `review_id` - each review can only have one parsed result.

**RLS Policies**: Users can only access parsed data for their own reviews.

```javascript
// Get parsed data for a review
const { data } = await supabase
  .from("parsed_reviews")
  .select("*")
  .eq("review_id", reviewId)
  .single();

// Get review with parsed data
const { data } = await supabase
  .from("reviews")
  .select("*, parsed_reviews(*)")
  .eq("id", reviewId)
  .single();
```

## Storage

Files are stored in the `reviews` bucket with user-scoped paths:

```
reviews/
└── {user_id}/
    └── {review_id}/
        ├── document.pdf
        └── pages/
            ├── page_1.png
            ├── page_2.png
            └── ...
```

**Important**: All file paths must start with the user ID for RLS policies to work.

```javascript
// Get current user ID
const { data: { user } } = await supabase.auth.getUser();

// Upload PDF
const { data } = await supabase.storage
  .from("reviews")
  .upload(`${user.id}/${reviewId}/document.pdf`, pdfFile);

// Upload page image
const { data } = await supabase.storage
  .from("reviews")
  .upload(`${user.id}/${reviewId}/pages/page_1.png`, imageFile);

// Download file
const { data } = await supabase.storage
  .from("reviews")
  .download(filePath);
```

## Automatic Cleanup

Database triggers automatically delete storage files when records are deleted:

| Delete Action | Automatic Cleanup |
|---------------|------------------|
| Delete `reviews` row | PDF file deleted, cascades to pages |
| Delete `review_pages` row | Page image deleted |

**Always delete via database records, not directly from storage.** This ensures referential integrity.

```javascript
// Correct: Delete via database (triggers cleanup)
await supabase
  .from("reviews")
  .delete()
  .eq("id", reviewId);

// Incorrect: Direct storage deletion leaves orphan records
// await supabase.storage.from("reviews").remove([...]);
```

## Indexes

Performance indexes are created on:

- `reviews.user_id` - Fast user filtering
- `reviews.created_at DESC` - Fast recent reviews query
- `review_pages.review_id` - Fast page lookup
- `review_pages` partial index on `is_rob_graph = true OR is_forest_plot = true`
- `parsed_reviews.review_id` - Fast parsed data lookup
