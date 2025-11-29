
  create table "public"."parsed_reviews" (
    "id" uuid not null default gen_random_uuid(),
    "review_id" uuid not null,
    "forest_plot_page" integer not null,
    "rob_graph_page" integer not null,
    "forest_plot_data" jsonb not null,
    "rob_graph_data" jsonb not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."parsed_reviews" enable row level security;


  create table "public"."review_pages" (
    "id" uuid not null default gen_random_uuid(),
    "review_id" uuid not null,
    "page_number" integer not null,
    "image_path" text not null,
    "is_rob_graph" boolean not null default false,
    "is_forest_plot" boolean not null default false,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."review_pages" enable row level security;


  create table "public"."reviews" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "title" text not null,
    "pdf_path" text,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."reviews" enable row level security;

CREATE INDEX idx_parsed_reviews_review_id ON public.parsed_reviews USING btree (review_id);

CREATE INDEX idx_review_pages_review_id ON public.review_pages USING btree (review_id);

CREATE INDEX idx_review_pages_special ON public.review_pages USING btree (review_id) WHERE ((is_rob_graph = true) OR (is_forest_plot = true));

CREATE INDEX idx_reviews_created_at ON public.reviews USING btree (created_at DESC);

CREATE INDEX idx_reviews_user_id ON public.reviews USING btree (user_id);

CREATE UNIQUE INDEX parsed_reviews_pkey ON public.parsed_reviews USING btree (id);

CREATE UNIQUE INDEX parsed_reviews_review_id_key ON public.parsed_reviews USING btree (review_id);

CREATE UNIQUE INDEX review_pages_pkey ON public.review_pages USING btree (id);

CREATE UNIQUE INDEX review_pages_review_id_page_number_key ON public.review_pages USING btree (review_id, page_number);

CREATE UNIQUE INDEX reviews_pkey ON public.reviews USING btree (id);

alter table "public"."parsed_reviews" add constraint "parsed_reviews_pkey" PRIMARY KEY using index "parsed_reviews_pkey";

alter table "public"."review_pages" add constraint "review_pages_pkey" PRIMARY KEY using index "review_pages_pkey";

alter table "public"."reviews" add constraint "reviews_pkey" PRIMARY KEY using index "reviews_pkey";

alter table "public"."parsed_reviews" add constraint "parsed_reviews_forest_plot_page_check" CHECK ((forest_plot_page > 0)) not valid;

alter table "public"."parsed_reviews" validate constraint "parsed_reviews_forest_plot_page_check";

alter table "public"."parsed_reviews" add constraint "parsed_reviews_review_id_fkey" FOREIGN KEY (review_id) REFERENCES public.reviews(id) ON DELETE CASCADE not valid;

alter table "public"."parsed_reviews" validate constraint "parsed_reviews_review_id_fkey";

alter table "public"."parsed_reviews" add constraint "parsed_reviews_review_id_key" UNIQUE using index "parsed_reviews_review_id_key";

alter table "public"."parsed_reviews" add constraint "parsed_reviews_rob_graph_page_check" CHECK ((rob_graph_page > 0)) not valid;

alter table "public"."parsed_reviews" validate constraint "parsed_reviews_rob_graph_page_check";

alter table "public"."review_pages" add constraint "review_pages_image_path_check" CHECK ((length(TRIM(BOTH FROM image_path)) > 0)) not valid;

alter table "public"."review_pages" validate constraint "review_pages_image_path_check";

alter table "public"."review_pages" add constraint "review_pages_page_number_check" CHECK ((page_number > 0)) not valid;

alter table "public"."review_pages" validate constraint "review_pages_page_number_check";

alter table "public"."review_pages" add constraint "review_pages_review_id_fkey" FOREIGN KEY (review_id) REFERENCES public.reviews(id) ON DELETE CASCADE not valid;

alter table "public"."review_pages" validate constraint "review_pages_review_id_fkey";

alter table "public"."review_pages" add constraint "review_pages_review_id_page_number_key" UNIQUE using index "review_pages_review_id_page_number_key";

alter table "public"."reviews" add constraint "reviews_pdf_path_check" CHECK (((pdf_path IS NULL) OR (length(TRIM(BOTH FROM pdf_path)) > 0))) not valid;

alter table "public"."reviews" validate constraint "reviews_pdf_path_check";

alter table "public"."reviews" add constraint "reviews_title_check" CHECK (((length(TRIM(BOTH FROM title)) >= 1) AND (length(TRIM(BOTH FROM title)) <= 500))) not valid;

alter table "public"."reviews" validate constraint "reviews_title_check";

alter table "public"."reviews" add constraint "reviews_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."reviews" validate constraint "reviews_user_id_fkey";

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

CREATE OR REPLACE FUNCTION public.handle_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.updated_at = now();
  return new;
end;
$function$
;

grant delete on table "public"."parsed_reviews" to "anon";

grant insert on table "public"."parsed_reviews" to "anon";

grant references on table "public"."parsed_reviews" to "anon";

grant select on table "public"."parsed_reviews" to "anon";

grant trigger on table "public"."parsed_reviews" to "anon";

grant truncate on table "public"."parsed_reviews" to "anon";

grant update on table "public"."parsed_reviews" to "anon";

grant delete on table "public"."parsed_reviews" to "authenticated";

grant insert on table "public"."parsed_reviews" to "authenticated";

grant references on table "public"."parsed_reviews" to "authenticated";

grant select on table "public"."parsed_reviews" to "authenticated";

grant trigger on table "public"."parsed_reviews" to "authenticated";

grant truncate on table "public"."parsed_reviews" to "authenticated";

grant update on table "public"."parsed_reviews" to "authenticated";

grant delete on table "public"."parsed_reviews" to "service_role";

grant insert on table "public"."parsed_reviews" to "service_role";

grant references on table "public"."parsed_reviews" to "service_role";

grant select on table "public"."parsed_reviews" to "service_role";

grant trigger on table "public"."parsed_reviews" to "service_role";

grant truncate on table "public"."parsed_reviews" to "service_role";

grant update on table "public"."parsed_reviews" to "service_role";

grant delete on table "public"."review_pages" to "anon";

grant insert on table "public"."review_pages" to "anon";

grant references on table "public"."review_pages" to "anon";

grant select on table "public"."review_pages" to "anon";

grant trigger on table "public"."review_pages" to "anon";

grant truncate on table "public"."review_pages" to "anon";

grant update on table "public"."review_pages" to "anon";

grant delete on table "public"."review_pages" to "authenticated";

grant insert on table "public"."review_pages" to "authenticated";

grant references on table "public"."review_pages" to "authenticated";

grant select on table "public"."review_pages" to "authenticated";

grant trigger on table "public"."review_pages" to "authenticated";

grant truncate on table "public"."review_pages" to "authenticated";

grant update on table "public"."review_pages" to "authenticated";

grant delete on table "public"."review_pages" to "service_role";

grant insert on table "public"."review_pages" to "service_role";

grant references on table "public"."review_pages" to "service_role";

grant select on table "public"."review_pages" to "service_role";

grant trigger on table "public"."review_pages" to "service_role";

grant truncate on table "public"."review_pages" to "service_role";

grant update on table "public"."review_pages" to "service_role";

grant delete on table "public"."reviews" to "anon";

grant insert on table "public"."reviews" to "anon";

grant references on table "public"."reviews" to "anon";

grant select on table "public"."reviews" to "anon";

grant trigger on table "public"."reviews" to "anon";

grant truncate on table "public"."reviews" to "anon";

grant update on table "public"."reviews" to "anon";

grant delete on table "public"."reviews" to "authenticated";

grant insert on table "public"."reviews" to "authenticated";

grant references on table "public"."reviews" to "authenticated";

grant select on table "public"."reviews" to "authenticated";

grant trigger on table "public"."reviews" to "authenticated";

grant truncate on table "public"."reviews" to "authenticated";

grant update on table "public"."reviews" to "authenticated";

grant delete on table "public"."reviews" to "service_role";

grant insert on table "public"."reviews" to "service_role";

grant references on table "public"."reviews" to "service_role";

grant select on table "public"."reviews" to "service_role";

grant trigger on table "public"."reviews" to "service_role";

grant truncate on table "public"."reviews" to "service_role";

grant update on table "public"."reviews" to "service_role";


  create policy "Users can delete own parsed data"
  on "public"."parsed_reviews"
  as permissive
  for delete
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.reviews
  WHERE ((reviews.id = parsed_reviews.review_id) AND (reviews.user_id = auth.uid())))));



  create policy "Users can insert own parsed data"
  on "public"."parsed_reviews"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.reviews
  WHERE ((reviews.id = parsed_reviews.review_id) AND (reviews.user_id = auth.uid())))));



  create policy "Users can update own parsed data"
  on "public"."parsed_reviews"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.reviews
  WHERE ((reviews.id = parsed_reviews.review_id) AND (reviews.user_id = auth.uid())))));



  create policy "Users can view own parsed data"
  on "public"."parsed_reviews"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.reviews
  WHERE ((reviews.id = parsed_reviews.review_id) AND (reviews.user_id = auth.uid())))));



  create policy "Users can delete own review pages"
  on "public"."review_pages"
  as permissive
  for delete
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.reviews
  WHERE ((reviews.id = review_pages.review_id) AND (reviews.user_id = auth.uid())))));



  create policy "Users can insert own review pages"
  on "public"."review_pages"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.reviews
  WHERE ((reviews.id = review_pages.review_id) AND (reviews.user_id = auth.uid())))));



  create policy "Users can update own review pages"
  on "public"."review_pages"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.reviews
  WHERE ((reviews.id = review_pages.review_id) AND (reviews.user_id = auth.uid())))));



  create policy "Users can view own review pages"
  on "public"."review_pages"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.reviews
  WHERE ((reviews.id = review_pages.review_id) AND (reviews.user_id = auth.uid())))));



  create policy "Users can delete own reviews"
  on "public"."reviews"
  as permissive
  for delete
  to authenticated
using ((auth.uid() = user_id));



  create policy "Users can insert own reviews"
  on "public"."reviews"
  as permissive
  for insert
  to authenticated
with check ((auth.uid() = user_id));



  create policy "Users can update own reviews"
  on "public"."reviews"
  as permissive
  for update
  to authenticated
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));



  create policy "Users can view own reviews"
  on "public"."reviews"
  as permissive
  for select
  to authenticated
using ((auth.uid() = user_id));


CREATE TRIGGER set_parsed_reviews_updated_at BEFORE UPDATE ON public.parsed_reviews FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER cleanup_review_page_storage BEFORE DELETE ON public.review_pages FOR EACH ROW EXECUTE FUNCTION public.delete_review_page_storage();

CREATE TRIGGER cleanup_review_storage BEFORE DELETE ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.delete_review_storage();

CREATE TRIGGER set_reviews_updated_at BEFORE UPDATE ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();


