# Storage and Database Synchronization

## Overview

This document explains the relationship between Supabase Storage (file storage) and PostgreSQL (database) in the Smart Grade system, and how to maintain data consistency between them.

## The Problem

### Why Deletions Don't Cascade Automatically

Supabase Storage and PostgreSQL are **separate, decoupled systems**:

- **Database** stores metadata (review records, file paths as text)
- **Storage** stores actual files (PDFs, images)
- **No foreign key relationship** exists between them

```
┌─────────────────────────────────────────────────────────────┐
│                   Supabase Architecture                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  PostgreSQL Database          Supabase Storage               │
│  ┌──────────────────┐        ┌──────────────────┐          │
│  │ reviews table    │        │ reviews bucket   │          │
│  │ ┌──────────────┐ │        │ ┌──────────────┐ │          │
│  │ │ id: uuid     │ │        │ │ {user_id}/   │ │          │
│  │ │ pdf_path: ───┼─┼────────┼▶│  {review}/   │ │          │
│  │ │  "text"      │ │  ref   │ │   file.pdf   │ │          │
│  │ └──────────────┘ │        │ └──────────────┘ │          │
│  └──────────────────┘        └──────────────────┘          │
│                                                              │
│  ❌ No constraint validation                                 │
│  ❌ No cascade on storage delete                            │
│  ❌ No cascade on database delete                           │
└─────────────────────────────────────────────────────────────┘
```

### Impact

This decoupling leads to **orphaned data**:

1. **Delete file from storage** → Database record remains (stale `pdf_path`)
2. **Delete database record** → Files remain in storage (wasted space)
3. **Manual deletions** → No automatic synchronization

## Existing Cascade Behaviors

These work correctly:

| Action | Cascades To | Mechanism |
|--------|-------------|-----------|
| Delete user | Delete all reviews | Foreign key: `reviews.user_id` → `auth.users.id` |
| Delete review | Delete all review_pages | Foreign key: `review_pages.review_id` → `reviews.id` |

These **do not** cascade:

| Action | Should Cascade To | Current Behavior |
|--------|-------------------|------------------|
| Delete review | Delete PDF from storage | ❌ Files remain orphaned |
| Delete review | Delete page images from storage | ❌ Images remain orphaned |
| Delete storage file | Delete or update review record | ❌ Record remains with invalid path |

## Solutions

We provide **three complementary approaches** to keep storage and database in sync:

### Solution 1: Database Triggers (Automatic Logging)

**Migration**: `supabase/migrations/20251121_sync_storage_database.sql`

This migration adds:

#### A. Pending Deletions Table

```sql
CREATE TABLE public.pending_file_deletions (
  id uuid PRIMARY KEY,
  file_path text NOT NULL,
  file_type text CHECK (file_type IN ('pdf', 'image')),
  created_at timestamptz DEFAULT now(),
  deleted_at timestamptz,
  error_message text
);
```

#### B. Trigger Function

Automatically logs files when a review is deleted:

```sql
CREATE TRIGGER review_delete_cleanup_trigger
  BEFORE DELETE ON public.reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_review_delete();
```

**What it does**:
- Intercepts review deletions
- Logs PDF path to `pending_file_deletions`
- Logs all page image paths
- Returns control to continue deletion

**Benefits**:
- ✅ Automatic - no application code changes needed for logging
- ✅ Resilient - works even if app crashes during deletion
- ✅ Auditable - tracks what needs cleanup

**Limitations**:
- ⚠️ Doesn't delete files itself (need background job)
- ⚠️ Only triggers on review deletion (not direct storage deletion)

#### C. Helper Functions

```sql
-- Get files pending deletion (for cleanup jobs)
get_pending_file_deletions(p_limit integer)

-- Mark files as processed
mark_file_deleted(p_file_path text, p_error text)
```

#### D. Detection View

```sql
-- Lists all reviews with PDFs for validation
CREATE VIEW reviews_with_pdf AS ...
```

### Solution 2: Application-Level Handlers (Immediate Cleanup)

**Location**: `docs/examples/03_delete_review_with_cleanup.md`

Explicitly delete files in application code:

```typescript
async function deleteReviewWithCleanup(reviewId: string) {
  // 1. Fetch review and pages
  // 2. Collect all file paths (PDF + images)
  // 3. Delete files from storage
  // 4. Delete database record
}
```

**Benefits**:
- ✅ Immediate deletion - no lag
- ✅ Full control over error handling
- ✅ Works for any deletion path
- ✅ No background jobs needed

**Limitations**:
- ⚠️ Must update all deletion code paths
- ⚠️ If app crashes mid-delete, can leave orphans

### Solution 3: Background Cleanup Job (Fail-Safe)

Processes the `pending_file_deletions` table:

```typescript
// Cron job runs every minute
cron.schedule('* * * * *', async () => {
  const pending = await getPendingFileDeletions();
  for (const file of pending) {
    await storage.remove([file.file_path]);
    await markFileDeleted(file.file_path);
  }
});
```

**Benefits**:
- ✅ Catches files missed by application
- ✅ Retries failed deletions
- ✅ Centralized cleanup logic
- ✅ Can batch operations for efficiency

**Limitations**:
- ⚠️ Delayed deletion (up to 1 minute lag)
- ⚠️ Requires infrastructure (cron/scheduled function)

## Recommended Architecture

**Use all three solutions together** for maximum resilience:

```
User Request: Delete Review
           ↓
┌──────────────────────────────────────────────────┐
│  Application Layer (Solution 2)                  │
│  1. Fetch review + pages                         │
│  2. Delete files from storage                    │
│  3. Delete database record                       │
└──────────────────┬───────────────────────────────┘
                   ↓
┌──────────────────────────────────────────────────┐
│  Database Trigger (Solution 1)                   │
│  - Logs any remaining files to pending_deletions │
│  - Backup in case app didn't delete files        │
└──────────────────┬───────────────────────────────┘
                   ↓
┌──────────────────────────────────────────────────┐
│  Background Job (Solution 3)                     │
│  - Runs every minute                             │
│  - Processes pending_file_deletions table        │
│  - Deletes any files app missed                  │
│  - Retries failed deletions                      │
└──────────────────────────────────────────────────┘

Result: 🎯 No orphaned data
```

### Decision Matrix

| Scenario | Use This Approach |
|----------|-------------------|
| **Normal deletion flow** | Solution 2 (immediate app-level) |
| **App crash during delete** | Solution 3 (background job) catches it |
| **Manual storage deletion** | Run Solution 3 cleanup script manually |
| **Need audit trail** | Solution 1 provides logging |
| **Recovery from existing orphans** | Use detection script in Solution 2 |

## Implementation Guide

### Step 1: Apply Database Migration

```bash
# Migration runs automatically on next Supabase deploy
# Or run manually:
supabase migration up
```

This creates:
- `pending_file_deletions` table
- Trigger on review deletion
- Helper functions
- Detection view

### Step 2: Update Application Code

For all review deletion endpoints/functions:

```typescript
// Before (❌ Leaves orphaned files)
await supabase.from('reviews').delete().eq('id', reviewId);

// After (✅ Clean deletion)
await deleteReviewWithCleanup(reviewId); // See example 03
```

### Step 3: Deploy Background Job

Choose your platform:

#### Option A: Node.js with node-cron

```typescript
import cron from 'node-cron';

cron.schedule('* * * * *', processFileDeletions);
```

#### Option B: Supabase Edge Function + pg_cron

```sql
-- In database
SELECT cron.schedule(
  'cleanup-files',
  '* * * * *',
  $$SELECT net.http_post(
    'https://your-project.supabase.co/functions/v1/cleanup-files',
    '{}',
    headers:='{"Authorization": "Bearer YOUR_SERVICE_KEY"}'::jsonb
  )$$
);
```

#### Option C: External Cron (GitHub Actions, etc.)

```yaml
# .github/workflows/cleanup.yml
on:
  schedule:
    - cron: '*/5 * * * *' # Every 5 minutes

jobs:
  cleanup:
    runs-on: ubuntu-latest
    steps:
      - name: Run cleanup script
        run: node scripts/cleanup-files.js
```

### Step 4: Monitor and Alert

Add monitoring for orphaned data:

```typescript
// Daily health check
async function checkOrphanedData() {
  const pending = await getPendingFileDeletions();

  if (pending.length > 100) {
    // Alert: cleanup job might be failing
    sendAlert(`${pending.length} files pending deletion`);
  }

  // Check for old pending deletions
  const oldFiles = pending.filter(
    f => Date.now() - new Date(f.created_at).getTime() > 3600000 // 1 hour
  );

  if (oldFiles.length > 0) {
    // Alert: cleanup job definitely failing
    sendAlert(`${oldFiles.length} files stuck in deletion queue`);
  }
}
```

## Handling Manual Storage Deletions

If you manually delete files from storage (e.g., via Supabase Dashboard):

### Option 1: Keep the records (if files can be re-uploaded)

```typescript
// Mark records as missing PDF
await supabase
  .from('reviews')
  .update({ pdf_path: null })
  .eq('pdf_path', 'manually/deleted/path.pdf');
```

### Option 2: Delete the orphaned records

```typescript
// Use detection script
const orphaned = await findOrphanedReviews();

// Review and confirm before deleting
for (const review of orphaned) {
  console.log(`Will delete: ${review.id} - ${review.title}`);
}

// Delete
await cleanupOrphanedReviews();
```

## Troubleshooting

### Issue: Files not being deleted by background job

**Check**:
1. Is the cron job running? Check logs
2. Are files in `pending_file_deletions` table?
   ```sql
   SELECT * FROM pending_file_deletions WHERE deleted_at IS NULL;
   ```
3. Check `error_message` field for failures
4. Verify service role key has storage permissions

### Issue: Pending deletions table growing

**Causes**:
- Background job not running
- Permission issues (wrong API key)
- Network errors to storage

**Fix**:
```typescript
// Retry failed deletions
const failed = await supabase
  .from('pending_file_deletions')
  .select('*')
  .is('deleted_at', null)
  .not('error_message', 'is', null);

// Manually process
for (const file of failed) {
  await retryFileDeletion(file.file_path);
}
```

### Issue: Reviews with invalid paths

**Symptom**: `pdf_path` points to non-existent files

**Detection**:
```typescript
const orphaned = await findOrphanedReviews();
console.log(`Found ${orphaned.length} reviews with missing PDFs`);
```

**Fix**:
- Option A: Delete reviews
- Option B: Set `pdf_path` to NULL
- Option C: Re-upload missing PDFs

## Future Improvements

Potential enhancements to consider:

1. **Storage webhooks**: If Supabase adds webhook support for storage events
2. **Soft deletes**: Add `deleted_at` timestamp instead of hard deletes
3. **File versioning**: Keep file history for recovery
4. **Integrity checker**: Scheduled job to validate all paths
5. **Storage quotas**: Track and enforce per-user storage limits

## Summary

| Aspect | Solution |
|--------|----------|
| **Root cause** | Storage and database are decoupled systems |
| **Primary fix** | Application-level explicit cleanup (Solution 2) |
| **Backup** | Database trigger + background job (Solutions 1 & 3) |
| **Manual deletions** | Run detection and cleanup scripts |
| **Prevention** | Use all three solutions together |
| **Monitoring** | Track `pending_file_deletions` table size |

**Key Takeaway**: Supabase Storage is not a relational database. File references in PostgreSQL are just text strings. You must enforce referential integrity at the application layer.
