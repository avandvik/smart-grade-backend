# Create Review Example

Complete example of creating a review with PDF upload.

```javascript
import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
  "https://redzwiaseoavjbahsjgw.supabase.co",
  "your-publishable-key",
);

async function createReview(title, pdfFile) {
  // Get current user ID
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error("User not authenticated");

  // 1. Create review record
  const { data: review, error } = await supabase
    .from("reviews")
    .insert({ title })
    .select()
    .single();

  if (error) throw error;

  // 2. Upload PDF if provided
  if (pdfFile) {
    // Use the original filename from the uploaded file
    const fileName = pdfFile.name || 'document.pdf';

    const { data: upload } = await supabase.storage
      .from("reviews")
      .upload(`${user.id}/${review.id}/${fileName}`, pdfFile);

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
