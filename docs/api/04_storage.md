# Storage API

Manage PDF and image files.

## Upload PDF

```javascript
const { data } = await supabase.storage
  .from('reviews')
  .upload(`${reviewId}/document.pdf`, pdfFile)

// Update review with path
await supabase
  .from('reviews')
  .update({ pdf_path: data.path })
  .eq('id', reviewId)
```

## Upload Page Image

```javascript
const { data } = await supabase.storage
  .from('reviews')
  .upload(`${reviewId}/pages/page_${pageNumber}.png`, imageFile)
```

## Download File

```javascript
const { data } = await supabase.storage
  .from('reviews')
  .download(filePath)
```

## Delete File

```javascript
await supabase.storage
  .from('reviews')
  .remove([filePath])
```

## Get Public URL

```javascript
const { data } = supabase.storage
  .from('reviews')
  .getPublicUrl(filePath)
```