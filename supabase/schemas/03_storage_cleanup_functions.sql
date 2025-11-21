-- ============================================================================
-- STORAGE CLEANUP TRIGGERS
-- Automatically delete files from storage when database records are deleted
-- ============================================================================

-- Function to delete review PDF from storage when review is deleted
create or replace function public.delete_review_storage()
returns trigger
language plpgsql
security definer
as $$
begin
  -- Delete the PDF file if it exists
  if old.pdf_path is not null then
    delete from storage.objects
    where bucket_id = 'reviews'
    and name = old.pdf_path;
  end if;

  return old;
end;
$$;

-- Trigger to delete review PDF before review deletion
create trigger cleanup_review_storage
  before delete on public.reviews
  for each row execute function public.delete_review_storage();

-- Function to delete review_page image from storage when page is deleted
create or replace function public.delete_review_page_storage()
returns trigger
language plpgsql
security definer
as $$
begin
  -- Delete the image file
  delete from storage.objects
  where bucket_id = 'reviews'
  and name = old.image_path;

  return old;
end;
$$;

-- Trigger to delete review_page image before page deletion
create trigger cleanup_review_page_storage
  before delete on public.review_pages
  for each row execute function public.delete_review_page_storage();
