-- Migration: Sync storage and database for reviews
-- This migration adds mechanisms to track and clean up orphaned files

-- Table to track files that need deletion from storage
CREATE TABLE public.pending_file_deletions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  file_path text NOT NULL,
  file_type text NOT NULL CHECK (file_type IN ('pdf', 'image')),
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  error_message text,
  PRIMARY KEY (id)
);

-- Index for efficient querying of pending deletions
CREATE INDEX idx_pending_file_deletions_pending
  ON public.pending_file_deletions(created_at)
  WHERE deleted_at IS NULL;

-- Function to log files for deletion when a review is deleted
CREATE OR REPLACE FUNCTION public.handle_review_delete()
RETURNS TRIGGER AS $$
BEGIN
  -- Log PDF for deletion if it exists
  IF OLD.pdf_path IS NOT NULL THEN
    INSERT INTO public.pending_file_deletions (file_path, file_type)
    VALUES (OLD.pdf_path, 'pdf');
  END IF;

  -- Log all page images for deletion
  INSERT INTO public.pending_file_deletions (file_path, file_type)
  SELECT image_path, 'image'
  FROM public.review_pages
  WHERE review_id = OLD.id;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to execute before review deletion
CREATE TRIGGER review_delete_cleanup_trigger
  BEFORE DELETE ON public.reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_review_delete();

-- View to help detect orphaned reviews (reviews with missing PDFs)
-- Note: This cannot automatically check if files exist in storage
-- You'll need to validate file existence from your application
CREATE OR REPLACE VIEW public.reviews_with_pdf AS
SELECT
  r.id,
  r.user_id,
  r.title,
  r.pdf_path,
  r.created_at,
  r.updated_at,
  COUNT(rp.id) as page_count
FROM public.reviews r
LEFT JOIN public.review_pages rp ON r.id = rp.review_id
WHERE r.pdf_path IS NOT NULL
GROUP BY r.id, r.user_id, r.title, r.pdf_path, r.created_at, r.updated_at;

-- Function to manually mark a file as deleted (call from your cleanup job)
CREATE OR REPLACE FUNCTION public.mark_file_deleted(
  p_file_path text,
  p_error text DEFAULT NULL
)
RETURNS void AS $$
BEGIN
  UPDATE public.pending_file_deletions
  SET
    deleted_at = now(),
    error_message = p_error
  WHERE file_path = p_file_path
    AND deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get pending file deletions (for your cleanup job)
CREATE OR REPLACE FUNCTION public.get_pending_file_deletions(
  p_limit integer DEFAULT 100
)
RETURNS TABLE (
  id uuid,
  file_path text,
  file_type text,
  created_at timestamptz
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    pfd.id,
    pfd.file_path,
    pfd.file_type,
    pfd.created_at
  FROM public.pending_file_deletions pfd
  WHERE pfd.deleted_at IS NULL
  ORDER BY pfd.created_at ASC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT SELECT ON public.pending_file_deletions TO authenticated;
GRANT SELECT ON public.reviews_with_pdf TO authenticated;

-- RLS policies
ALTER TABLE public.pending_file_deletions ENABLE ROW LEVEL SECURITY;

-- Users can only see their own pending deletions
CREATE POLICY "Users can view own pending deletions"
  ON public.pending_file_deletions FOR SELECT
  TO authenticated
  USING (
    -- Extract user_id from file path (format: {user_id}/{review_id}/...)
    (string_to_array(file_path, '/'))[1] = auth.uid()::text
  );

-- Only service role can modify pending deletions
CREATE POLICY "Service role can manage pending deletions"
  ON public.pending_file_deletions FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Comment documentation
COMMENT ON TABLE public.pending_file_deletions IS
  'Tracks files that need to be deleted from storage after a review is deleted';
COMMENT ON FUNCTION public.handle_review_delete() IS
  'Trigger function that logs files for deletion when a review is deleted';
COMMENT ON VIEW public.reviews_with_pdf IS
  'Helper view to list all reviews that have PDFs attached';
COMMENT ON FUNCTION public.mark_file_deleted(text, text) IS
  'Marks a file as successfully deleted from storage';
COMMENT ON FUNCTION public.get_pending_file_deletions(integer) IS
  'Returns pending file deletions for cleanup job to process';
