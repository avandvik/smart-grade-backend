set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.delete_review_page_storage()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
begin
  -- Delete the image file
  delete from storage.objects
  where bucket_id = 'reviews'
  and name = old.image_path;

  return old;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.delete_review_storage()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
begin
  -- Delete the PDF file if it exists
  if old.pdf_path is not null then
    delete from storage.objects
    where bucket_id = 'reviews'
    and name = old.pdf_path;
  end if;

  return old;
end;
$function$
;

CREATE TRIGGER cleanup_review_page_storage BEFORE DELETE ON public.review_pages FOR EACH ROW EXECUTE FUNCTION public.delete_review_page_storage();

CREATE TRIGGER cleanup_review_storage BEFORE DELETE ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.delete_review_storage();

