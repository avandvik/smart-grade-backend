# Create Review

Complete example of creating a systematic review with optional PDF upload.

## Basic Review Creation

```javascript
const { data: review, error } = await supabase
  .from("reviews")
  .insert({ title: "COVID-19 Treatment Efficacy Meta-Analysis" })
  .select()
  .single();

if (error) {
  console.error("Failed to create review:", error.message);
} else {
  console.log("Review created:", review.id);
}
```

## Create Review with PDF Upload

```javascript
async function createReviewWithPDF(title, pdfFile) {
  // Get current user
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error("Not authenticated");

  // 1. Create review record
  const { data: review, error: reviewError } = await supabase
    .from("reviews")
    .insert({ title })
    .select()
    .single();

  if (reviewError) throw reviewError;

  // 2. Upload PDF to storage
  const fileName = pdfFile.name || "document.pdf";
  const storagePath = `${user.id}/${review.id}/${fileName}`;

  const { data: upload, error: uploadError } = await supabase.storage
    .from("reviews")
    .upload(storagePath, pdfFile);

  if (uploadError) {
    // Clean up the review if upload fails
    await supabase.from("reviews").delete().eq("id", review.id);
    throw uploadError;
  }

  // 3. Update review with PDF path
  const { data: updatedReview, error: updateError } = await supabase
    .from("reviews")
    .update({ pdf_path: upload.path })
    .eq("id", review.id)
    .select()
    .single();

  if (updateError) throw updateError;

  return updatedReview;
}

// Usage
const fileInput = document.querySelector('input[type="file"]');
const pdfFile = fileInput.files[0];

const review = await createReviewWithPDF(
  "Antibiotic Resistance Patterns 2024",
  pdfFile
);
console.log("Review created with PDF:", review.pdf_path);
```

## List All Reviews

```javascript
const { data: reviews, error } = await supabase
  .from("reviews")
  .select("*")
  .order("created_at", { ascending: false });

reviews.forEach(review => {
  console.log(`${review.title} (${review.created_at})`);
});
```

## Get Review with All Related Data

```javascript
const { data: review, error } = await supabase
  .from("reviews")
  .select(`
    *,
    review_pages(*),
    parsed_reviews(*)
  `)
  .eq("id", reviewId)
  .single();

console.log("Review:", review.title);
console.log("Pages:", review.review_pages.length);
console.log("Parsed:", review.parsed_reviews ? "Yes" : "No");
```

## Update Review Title

```javascript
const { data: review, error } = await supabase
  .from("reviews")
  .update({ title: "Updated Review Title" })
  .eq("id", reviewId)
  .select()
  .single();
```

## Delete Review

Deleting a review automatically:
- Deletes the PDF from storage (via database trigger)
- Cascades to delete all `review_pages` records
- Deletes all page images from storage (via database trigger)
- Cascades to delete the `parsed_reviews` record

```javascript
const { error } = await supabase
  .from("reviews")
  .delete()
  .eq("id", reviewId);

if (error) {
  console.error("Failed to delete:", error.message);
} else {
  console.log("Review and all associated data deleted");
}
```

## Download Review PDF

```javascript
async function downloadReviewPDF(review) {
  if (!review.pdf_path) {
    console.log("No PDF attached to this review");
    return null;
  }

  const { data, error } = await supabase.storage
    .from("reviews")
    .download(review.pdf_path);

  if (error) throw error;

  return data; // Blob
}

// Usage
const blob = await downloadReviewPDF(review);
const url = URL.createObjectURL(blob);
window.open(url); // Opens PDF in new tab
```

## Search Reviews by Title

```javascript
const { data: reviews, error } = await supabase
  .from("reviews")
  .select("*")
  .ilike("title", "%covid%")
  .order("created_at", { ascending: false });
```

## Paginated Review List

```javascript
async function getReviewsPage(page = 1, pageSize = 10) {
  const from = (page - 1) * pageSize;
  const to = from + pageSize - 1;

  const { data, error, count } = await supabase
    .from("reviews")
    .select("*", { count: "exact" })
    .order("created_at", { ascending: false })
    .range(from, to);

  return {
    reviews: data,
    totalCount: count,
    currentPage: page,
    totalPages: Math.ceil(count / pageSize)
  };
}
```

## Complete Workflow Example

```javascript
async function completeReviewWorkflow(title, pdfFile) {
  // 1. Create review with PDF
  const review = await createReviewWithPDF(title, pdfFile);
  console.log("Created review:", review.id);

  // 2. Extract pages from PDF (client-side PDF.js or similar)
  const pageImages = await extractPagesFromPDF(pdfFile);
  console.log("Extracted pages:", pageImages.length);

  // 3. Upload pages (see Upload Pages example)
  const pages = await uploadReviewPages(review.id, pageImages);
  console.log("Uploaded pages:", pages.length);

  // 4. Identify special pages and mark them
  // (User identifies forest plot on page 5, ROB on page 7)
  await markSpecialPages(review.id, {
    forestPlotPage: 5,
    robGraphPage: 7
  });

  // 5. Parse the review
  const parsed = await parseReview(review.id, 5, 7);
  console.log("Parsed studies:", parsed.forest_plot_data.studies.length);

  return review;
}
```
