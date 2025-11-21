# Storage API

Manage PDF and image files.

> **Important:** All files must be stored with the user ID as the first part of
> the path due to RLS policies. Store files with the path
> userId/reviewId/fileName.

## Upload PDF

```javascript
// Get current user ID
const { data: { user } } = await supabase.auth.getUser();

// Use the original filename from the uploaded file
const fileName = pdfFile.name || "document.pdf";

const { data } = await supabase.storage
  .from("reviews")
  .upload(`${user.id}/${reviewId}/${fileName}`, pdfFile);

// Update review with path
await supabase
  .from("reviews")
  .update({ pdf_path: data.path })
  .eq("id", reviewId);
```

## Upload Page Image

```javascript
// Get current user ID
const { data: { user } } = await supabase.auth.getUser();

const { data } = await supabase.storage
  .from("reviews")
  .upload(`${user.id}/${reviewId}/pages/page_${pageNumber}.png`, imageFile);
```

## Download File

```javascript
const { data } = await supabase.storage
  .from("reviews")
  .download(filePath);
```

## Delete File

```javascript
await supabase.storage
  .from("reviews")
  .remove([filePath]);
```

## Get Public URL

```javascript
const { data } = supabase.storage
  .from("reviews")
  .getPublicUrl(filePath);
```
