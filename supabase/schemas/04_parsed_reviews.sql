-- ============================================================================
-- PARSED REVIEWS TABLE - LLM-EXTRACTED FOREST PLOT AND ROB DATA
-- ============================================================================

-- 1. Create parsed_review_data table
create table public.parsed_reviews (
id uuid not null default gen_random_uuid(),
review_id uuid not null references public.reviews(id) on delete cascade,
forest_plot_page integer not null check (forest_plot_page > 0),
rob_graph_page integer not null check (rob_graph_page > 0),
forest_plot_data jsonb not null,
rob_graph_data jsonb not null,
created_at timestamptz not null default now(),
updated_at timestamptz not null default now(),
primary key (id),
unique(review_id)
);

-- Indexes
create index idx_parsed_reviews_review_id on public.parsed_reviews(review_id);

-- 2. Enable RLS
alter table public.parsed_reviews enable row level security;

-- 3. RLS Policies
create policy "Users can view own parsed data"
on public.parsed_reviews for select
to authenticated
using (
    exists (
    select 1 from public.reviews
    where reviews.id = parsed_reviews.review_id
    and reviews.user_id = auth.uid()
    )
);

create policy "Users can insert own parsed data"
on public.parsed_reviews for insert
to authenticated
with check (
    exists (
    select 1 from public.reviews
    where reviews.id = parsed_reviews.review_id
    and reviews.user_id = auth.uid()
    )
);

create policy "Users can update own parsed data"
on public.parsed_reviews for update
to authenticated
using (
    exists (
    select 1 from public.reviews
    where reviews.id = parsed_reviews.review_id
    and reviews.user_id = auth.uid()
    )
);

create policy "Users can delete own parsed data"
on public.parsed_reviews for delete
to authenticated
using (
    exists (
    select 1 from public.reviews
    where reviews.id = parsed_reviews.review_id
    and reviews.user_id = auth.uid()
    )
);

-- 4. Trigger for updated_at
create trigger set_parsed_reviews_updated_at
before update on public.parsed_reviews
for each row execute function public.handle_updated_at();

-- 5. Grant permissions
grant all on public.parsed_reviews to authenticated;
