-- ============================================================================
-- REVIEW_PAGES TABLE - EXTRACTED PAGE IMAGES
-- ============================================================================

-- 1. Create review_pages table
create table public.review_pages (
  id uuid not null default gen_random_uuid(),
  review_id uuid not null references public.reviews(id) on delete cascade,
  page_number integer not null check (page_number > 0),
  image_path text not null check (length(trim(image_path)) > 0),
  is_rob_graph boolean not null default false,
  is_forest_plot boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (id),
  unique(review_id, page_number)
);

-- Indexes
create index idx_review_pages_review_id on public.review_pages(review_id);
create index idx_review_pages_special on public.review_pages(review_id) 
  where is_rob_graph = true or is_forest_plot = true;

-- 2. Enable RLS
alter table public.review_pages enable row level security;

-- 3. RLS Policies
create policy "Users can view own review pages"
  on public.review_pages for select
  to authenticated
  using (
    exists (
      select 1 from public.reviews 
      where reviews.id = review_pages.review_id 
      and reviews.user_id = auth.uid()
    )
  );

create policy "Users can insert own review pages"
  on public.review_pages for insert
  to authenticated
  with check (
    exists (
      select 1 from public.reviews 
      where reviews.id = review_pages.review_id 
      and reviews.user_id = auth.uid()
    )
  );

create policy "Users can update own review pages"
  on public.review_pages for update
  to authenticated
  using (
    exists (
      select 1 from public.reviews 
      where reviews.id = review_pages.review_id 
      and reviews.user_id = auth.uid()
    )
  );

create policy "Users can delete own review pages"
  on public.review_pages for delete
  to authenticated
  using (
    exists (
      select 1 from public.reviews 
      where reviews.id = review_pages.review_id 
      and reviews.user_id = auth.uid()
    )
  );

-- 4. Grant permissions
grant all on public.review_pages to authenticated;
