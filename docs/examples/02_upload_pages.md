# Upload Pages Example

Extract and upload pages from a review PDF.

```javascript
async function uploadReviewPages(reviewId, pageImages) {
  const pages = []

  for (let i = 0; i < pageImages.length; i++) {
    const pageNumber = i + 1
    const imageFile = pageImages[i]

    // 1. Upload image to storage
    const { data: upload } = await supabase.storage
      .from('reviews')
      .upload(
        `${reviewId}/pages/page_${pageNumber}.png`,
        imageFile
      )

    // 2. Create page record
    const { data: page } = await supabase
      .from('review_pages')
      .insert({
        review_id: reviewId,
        page_number: pageNumber,
        image_path: upload.path,
        is_rob_graph: false,
        is_forest_plot: false
      })
      .select()
      .single()

    pages.push(page)
  }

  return pages
}

// Usage
const pages = await uploadReviewPages(
  reviewId,
  extractedImages
)
```