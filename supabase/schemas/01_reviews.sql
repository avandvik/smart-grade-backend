-- ============================================================================
-- REVIEWS TABLE - SYSTEMATIC REVIEW DOCUMENTS
-- ============================================================================

-- 1. Create reviews table
create table public.reviews (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (length(trim(title)) between 1 and 500),
  pdf_path text check (pdf_path is null or length(trim(pdf_path)) > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id)
);

-- Indexes for performance
create index idx_reviews_user_id on public.reviews(user_id);
create index idx_reviews_created_at on public.reviews(created_at desc);

-- 2. Enable RLS
alter table public.reviews enable row level security;

-- 3. RLS Policies
create policy "Users can view own reviews"
  on public.reviews for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can insert own reviews"
  on public.reviews for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update own reviews"
  on public.reviews for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own reviews"
  on public.reviews for delete
  to authenticated
  using (auth.uid() = user_id);

-- 4. Trigger for updated_at
create trigger set_reviews_updated_at
  before update on public.reviews
  for each row execute function public.handle_updated_at();

-- 5. Grant permissions
grant usage on schema public to authenticated;
grant all on public.reviews to authenticated;
