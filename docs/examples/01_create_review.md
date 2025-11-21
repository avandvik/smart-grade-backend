# Create Review Example

Complete example of creating a review with PDF upload.

```javascript
import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
  "https://redzwiaseoavjbahsjgw.supabase.co",
  "your-publishable-key",
);

async function createReview(title, pdfFile) {
  // 1. Create review record
  const { data: review, error } = await supabase
    .from("reviews")
    .insert({ title })
    .select()
    .single();

  if (error) throw error;

  // 2. Upload PDF if provided
  if (pdfFile) {
    const { data: upload } = await supabase.storage
      .from("reviews")
      .upload(`${review.id}/document.pdf`, pdfFile);

    // 3. Update review with PDF path
    await supabase
      .from("reviews")
      .update({ pdf_path: upload.path })
      .eq("id", review.id);
  }

  return review;
}

// Usage
const review = await createReview(
  "COVID-19 Treatment Efficacy",
  pdfFile,
);
```
