# Review Pages API

Manage extracted pages from review documents.

## Add Page

```javascript
const { data } = await supabase
  .from("review_pages")
  .insert({
    review_id: reviewId,
    page_number: 1,
    image_path: "path/to/page.png",
    is_rob_graph: false,
    is_forest_plot: false,
  });
```

## List Pages

```javascript
const { data } = await supabase
  .from("review_pages")
  .select("*")
  .eq("review_id", reviewId)
  .order("page_number");
```

## Update Page Classification

```javascript
const { data } = await supabase
  .from("review_pages")
  .update({
    is_rob_graph: true,
    is_forest_plot: false,
  })
  .eq("id", pageId);
```

## Get Special Pages

```javascript
// Get ROB graphs
const { data: robGraphs } = await supabase
  .from("review_pages")
  .select("*")
  .eq("review_id", reviewId)
  .eq("is_rob_graph", true);

// Get forest plots
const { data: forestPlots } = await supabase
  .from("review_pages")
  .select("*")
  .eq("review_id", reviewId)
  .eq("is_forest_plot", true);
```
