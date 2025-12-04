# Upload Pages

Extract and upload individual pages from a systematic review PDF.

## Upload Single Page

```javascript
async function uploadPage(reviewId, pageNumber, imageFile) {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error("Not authenticated");

  // 1. Upload image to storage
  const storagePath = `${user.id}/${reviewId}/pages/page_${pageNumber}.png`;

  const { data: upload, error: uploadError } = await supabase.storage
    .from("reviews")
    .upload(storagePath, imageFile);

  if (uploadError) throw uploadError;

  // 2. Create page record
  const { data: page, error: pageError } = await supabase
    .from("review_pages")
    .insert({
      review_id: reviewId,
      page_number: pageNumber,
      image_path: upload.path
    })
    .select()
    .single();

  if (pageError) {
    // Clean up storage if database insert fails
    await supabase.storage.from("reviews").remove([upload.path]);
    throw pageError;
  }

  return page;
}
```

## Upload Multiple Pages

```javascript
async function uploadReviewPages(reviewId, pageImages) {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error("Not authenticated");

  const pages = [];

  for (let i = 0; i < pageImages.length; i++) {
    const pageNumber = i + 1;
    const imageFile = pageImages[i];

    // Upload image
    const storagePath = `${user.id}/${reviewId}/pages/page_${pageNumber}.png`;
    const { data: upload, error: uploadError } = await supabase.storage
      .from("reviews")
      .upload(storagePath, imageFile);

    if (uploadError) {
      console.error(`Failed to upload page ${pageNumber}:`, uploadError);
      continue;
    }

    // Create page record
    const { data: page, error: pageError } = await supabase
      .from("review_pages")
      .insert({
        review_id: reviewId,
        page_number: pageNumber,
        image_path: upload.path
      })
      .select()
      .single();

    if (pageError) {
      console.error(`Failed to create page record ${pageNumber}:`, pageError);
      await supabase.storage.from("reviews").remove([upload.path]);
      continue;
    }

    pages.push(page);
  }

  return pages;
}
```

## Upload Pages in Parallel

For faster uploads, process pages in parallel batches:

```javascript
async function uploadPagesBatch(reviewId, pageImages, batchSize = 5) {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error("Not authenticated");

  const pages = [];

  // Process in batches
  for (let i = 0; i < pageImages.length; i += batchSize) {
    const batch = pageImages.slice(i, i + batchSize);
    const startPage = i + 1;

    const batchPromises = batch.map(async (imageFile, index) => {
      const pageNumber = startPage + index;
      const storagePath = `${user.id}/${reviewId}/pages/page_${pageNumber}.png`;

      const { data: upload } = await supabase.storage
        .from("reviews")
        .upload(storagePath, imageFile);

      const { data: page } = await supabase
        .from("review_pages")
        .insert({
          review_id: reviewId,
          page_number: pageNumber,
          image_path: upload.path
        })
        .select()
        .single();

      return page;
    });

    const batchResults = await Promise.all(batchPromises);
    pages.push(...batchResults.filter(Boolean));
  }

  return pages;
}
```

## List Pages for a Review

```javascript
const { data: pages, error } = await supabase
  .from("review_pages")
  .select("*")
  .eq("review_id", reviewId)
  .order("page_number");

pages.forEach(page => {
  console.log(`Page ${page.page_number}: ${page.image_path}`);
  if (page.is_forest_plot) console.log("  -> Forest Plot");
  if (page.is_rob_graph) console.log("  -> ROB Graph");
});
```

## Mark Page as Forest Plot

```javascript
const { data: page, error } = await supabase
  .from("review_pages")
  .update({ is_forest_plot: true, is_rob_graph: false })
  .eq("id", pageId)
  .select()
  .single();
```

## Mark Page as ROB Graph

```javascript
const { data: page, error } = await supabase
  .from("review_pages")
  .update({ is_rob_graph: true, is_forest_plot: false })
  .eq("id", pageId)
  .select()
  .single();
```

## Mark Pages by Page Number

```javascript
async function markSpecialPages(reviewId, { forestPlotPage, robGraphPage }) {
  // Mark forest plot page
  await supabase
    .from("review_pages")
    .update({ is_forest_plot: true })
    .eq("review_id", reviewId)
    .eq("page_number", forestPlotPage);

  // Mark ROB graph page
  await supabase
    .from("review_pages")
    .update({ is_rob_graph: true })
    .eq("review_id", reviewId)
    .eq("page_number", robGraphPage);
}
```

## Get Special Pages

```javascript
// Get all special pages
const { data: specialPages } = await supabase
  .from("review_pages")
  .select("*")
  .eq("review_id", reviewId)
  .or("is_forest_plot.eq.true,is_rob_graph.eq.true");

// Get forest plot page
const { data: forestPlot } = await supabase
  .from("review_pages")
  .select("*")
  .eq("review_id", reviewId)
  .eq("is_forest_plot", true)
  .single();

// Get ROB graph page
const { data: robGraph } = await supabase
  .from("review_pages")
  .select("*")
  .eq("review_id", reviewId)
  .eq("is_rob_graph", true)
  .single();
```

## Download Page Image

```javascript
async function downloadPageImage(page) {
  const { data, error } = await supabase.storage
    .from("reviews")
    .download(page.image_path);

  if (error) throw error;

  return data; // Blob
}

// Display in browser
const blob = await downloadPageImage(page);
const url = URL.createObjectURL(blob);
document.getElementById("preview").src = url;
```

## Get Page Image URL

```javascript
const { data } = supabase.storage
  .from("reviews")
  .getPublicUrl(page.image_path);

console.log("Image URL:", data.publicUrl);
```

## Delete Single Page

Deleting a page record automatically removes the image from storage.

```javascript
const { error } = await supabase
  .from("review_pages")
  .delete()
  .eq("id", pageId);
```

## Delete All Pages for a Review

```javascript
const { error } = await supabase
  .from("review_pages")
  .delete()
  .eq("review_id", reviewId);
```

## Replace a Page Image

```javascript
async function replacePage(reviewId, pageNumber, newImageFile) {
  const { data: { user } } = await supabase.auth.getUser();

  // Delete existing page (triggers storage cleanup)
  await supabase
    .from("review_pages")
    .delete()
    .eq("review_id", reviewId)
    .eq("page_number", pageNumber);

  // Upload new page
  return uploadPage(reviewId, pageNumber, newImageFile);
}
```

## Count Pages

```javascript
const { count, error } = await supabase
  .from("review_pages")
  .select("*", { count: "exact", head: true })
  .eq("review_id", reviewId);

console.log("Total pages:", count);
```
