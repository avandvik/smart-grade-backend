# Database Tables

## reviews

| Column | Type | Constraints |
|--------|------|------------|
| id | uuid | Primary key, auto-generated |
| user_id | uuid | Foreign key to auth.users |
| title | text | 1-500 characters |
| pdf_path | text | Optional, storage path |
| created_at | timestamptz | Auto-set |
| updated_at | timestamptz | Auto-updated |

## review_pages

| Column | Type | Constraints |
|--------|------|------------|
| id | uuid | Primary key, auto-generated |
| review_id | uuid | Foreign key to reviews |
| page_number | integer | > 0, unique per review |
| image_path | text | Required, storage path |
| is_rob_graph | boolean | Default false |
| is_forest_plot | boolean | Default false |
| created_at | timestamptz | Auto-set |

## Relationships

```sql
reviews (1) --> (N) review_pages
```

- Cascade delete: Deleting a review deletes all its pages
- RLS: All queries automatically filtered by user_id