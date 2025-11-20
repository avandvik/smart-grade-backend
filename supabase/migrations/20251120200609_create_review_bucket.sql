-- Create reviews storage bucket
insert into storage.buckets (
  id, 
  name, 
  public, 
  file_size_limit, 
  allowed_mime_types
)
values (
  'reviews',
  'reviews', 
  false,
  52428800, -- 50MB
  array['application/pdf', 'image/png', 'image/jpeg']::text[]
);

-- Storage policies
create policy "Users can upload to own folder"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
  with check (((bucket_id = 'reviews'::text) AND ((auth.uid())::text = (string_to_array(name, '/'::text))[1])));

create policy "Users can view own files"
  on "storage"."objects"
  as permissive
  for select
  to authenticated
  using (((bucket_id = 'reviews'::text) AND ((auth.uid())::text = (string_to_array(name, '/'::text))[1])));

create policy "Users can update own files"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
  using (((bucket_id = 'reviews'::text) AND ((auth.uid())::text = (string_to_array(name, '/'::text))[1])));

create policy "Users can delete own files"
  on "storage"."objects"
  as permissive
  for delete
  to authenticated
  using (((bucket_id = 'reviews'::text) AND ((auth.uid())::text = (string_to_array(name, '/'::text))[1])));
  