# Delete Review with Storage Cleanup

This example demonstrates how to properly delete a review while ensuring all associated files (PDF and page images) are removed from storage to prevent orphaned data.

## Problem

When a review is deleted from the database, the associated files in storage are **not automatically deleted**. This is because:
- The `pdf_path` field is just a text reference with no foreign key constraint
- Supabase Storage and PostgreSQL are decoupled systems
- There's no built-in cascade delete from database to storage

## Solution

Always delete files from storage **before** or **as part of** deleting the database record.

## Option 1: Application-Level Handler (Recommended)

### TypeScript/JavaScript Example

```typescript
import { createClient } from '@supabase/supabase-js';

/**
 * Safely deletes a review and all its associated storage files
 * @param reviewId - UUID of the review to delete
 * @returns Success status and any errors encountered
 */
async function deleteReviewWithCleanup(reviewId: string) {
  const supabase = createClient(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_ANON_KEY!
  );

  try {
    // Step 1: Get the review to find PDF path
    const { data: review, error: reviewError } = await supabase
      .from('reviews')
      .select('id, pdf_path, user_id')
      .eq('id', reviewId)
      .single();

    if (reviewError) {
      throw new Error(`Failed to fetch review: ${reviewError.message}`);
    }

    if (!review) {
      throw new Error('Review not found');
    }

    // Step 2: Get all page images for this review
    const { data: pages, error: pagesError } = await supabase
      .from('review_pages')
      .select('image_path')
      .eq('review_id', reviewId);

    if (pagesError) {
      throw new Error(`Failed to fetch pages: ${pagesError.message}`);
    }

    // Step 3: Collect all file paths to delete
    const filesToDelete: string[] = [];

    if (review.pdf_path) {
      filesToDelete.push(review.pdf_path);
    }

    if (pages && pages.length > 0) {
      filesToDelete.push(...pages.map(p => p.image_path));
    }

    // Step 4: Delete files from storage
    if (filesToDelete.length > 0) {
      const { data: deleteData, error: deleteError } = await supabase.storage
        .from('reviews')
        .remove(filesToDelete);

      if (deleteError) {
        console.error('Storage deletion error:', deleteError);
        // Continue with database deletion even if some files fail
      }
    }

    // Step 5: Delete the review record (cascades to review_pages)
    const { error: dbDeleteError } = await supabase
      .from('reviews')
      .delete()
      .eq('id', reviewId);

    if (dbDeleteError) {
      throw new Error(`Failed to delete review: ${dbDeleteError.message}`);
    }

    return {
      success: true,
      filesDeleted: filesToDelete.length,
      reviewId
    };

  } catch (error) {
    console.error('Delete review error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}
```

### Usage

```typescript
// In your API route or service
const result = await deleteReviewWithCleanup('123e4567-e89b-12d3-a456-426614174000');

if (result.success) {
  console.log(`✅ Review deleted with ${result.filesDeleted} files cleaned up`);
} else {
  console.error(`❌ Failed to delete review: ${result.error}`);
}
```

## Option 2: Using the Pending Deletions System

If you've applied the `20251121_sync_storage_database.sql` migration, the database will automatically log files for deletion when a review is deleted.

### Step 1: Delete the review (files are logged automatically)

```typescript
const { error } = await supabase
  .from('reviews')
  .delete()
  .eq('id', reviewId);
```

### Step 2: Create a background cleanup job

```typescript
/**
 * Background job to process pending file deletions
 * Run this periodically (e.g., every minute via cron)
 */
async function processFileDeletions() {
  const supabase = createClient(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY! // Use service role
  );

  // Get pending deletions
  const { data: pendingFiles, error } = await supabase
    .rpc('get_pending_file_deletions', { p_limit: 100 });

  if (error || !pendingFiles) {
    console.error('Failed to get pending deletions:', error);
    return;
  }

  console.log(`Processing ${pendingFiles.length} file deletions...`);

  for (const file of pendingFiles) {
    try {
      // Delete from storage
      const { error: deleteError } = await supabase.storage
        .from('reviews')
        .remove([file.file_path]);

      // Mark as deleted
      await supabase.rpc('mark_file_deleted', {
        p_file_path: file.file_path,
        p_error: deleteError ? deleteError.message : null
      });

      if (!deleteError) {
        console.log(`✅ Deleted: ${file.file_path}`);
      } else {
        console.error(`⚠️  Failed to delete ${file.file_path}:`, deleteError);
      }
    } catch (err) {
      console.error(`❌ Error processing ${file.file_path}:`, err);
      // Mark with error
      await supabase.rpc('mark_file_deleted', {
        p_file_path: file.file_path,
        p_error: err instanceof Error ? err.message : 'Unknown error'
      });
    }
  }
}
```

### Cron Job Setup (Node.js)

```typescript
import cron from 'node-cron';

// Run every minute
cron.schedule('* * * * *', async () => {
  console.log('Running file cleanup job...');
  await processFileDeletions();
});
```

## Option 3: Detecting and Cleaning Orphaned Records

If you've already manually deleted files and need to clean up orphaned database records:

### Find orphaned reviews

```typescript
/**
 * Detect reviews where PDFs no longer exist in storage
 */
async function findOrphanedReviews() {
  const supabase = createClient(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
  );

  const { data: reviews } = await supabase
    .from('reviews_with_pdf')
    .select('*');

  if (!reviews) return [];

  const orphanedReviews = [];

  for (const review of reviews) {
    // Check if PDF exists in storage
    const { data, error } = await supabase.storage
      .from('reviews')
      .list(review.pdf_path.substring(0, review.pdf_path.lastIndexOf('/')));

    const fileName = review.pdf_path.substring(
      review.pdf_path.lastIndexOf('/') + 1
    );

    const fileExists = data?.some(f => f.name === fileName);

    if (!fileExists) {
      orphanedReviews.push(review);
    }
  }

  return orphanedReviews;
}
```

### Clean up orphaned reviews

```typescript
/**
 * Delete orphaned reviews (reviews where PDFs no longer exist)
 * USE WITH CAUTION - This permanently deletes data
 */
async function cleanupOrphanedReviews() {
  const orphaned = await findOrphanedReviews();

  console.log(`Found ${orphaned.length} orphaned reviews`);

  for (const review of orphaned) {
    console.log(`Deleting orphaned review: ${review.id} - ${review.title}`);

    const { error } = await supabase
      .from('reviews')
      .delete()
      .eq('id', review.id);

    if (error) {
      console.error(`Failed to delete ${review.id}:`, error);
    }
  }
}
```

## Best Practices

1. **Always use Option 1 for new deletions** - Delete files explicitly before database records
2. **Implement Option 2 for resilience** - Background job ensures cleanup even if app crashes
3. **Use Option 3 for recovery** - Clean up existing orphaned data periodically
4. **Add error handling** - Log failures and retry mechanisms
5. **Consider transactions** - Use database transactions where possible to ensure consistency
6. **Audit trail** - Keep logs of what was deleted and when

## Testing

```typescript
// Test the delete function
async function testDelete() {
  // Create a test review
  const { data: review } = await supabase
    .from('reviews')
    .insert({ title: 'Test Review' })
    .select()
    .single();

  console.log('Created test review:', review.id);

  // Delete it
  const result = await deleteReviewWithCleanup(review.id);

  console.log('Delete result:', result);

  // Verify it's gone
  const { data: check } = await supabase
    .from('reviews')
    .select()
    .eq('id', review.id);

  console.log('Verification (should be empty):', check);
}
```

## Summary

- **Problem**: Storage and database are decoupled, no automatic cascade
- **Solution**: Explicit cleanup in application layer
- **Recommended**: Option 1 (immediate) + Option 2 (background failsafe)
- **Recovery**: Option 3 for cleaning existing orphaned data
