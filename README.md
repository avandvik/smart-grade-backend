# SmartGRADE Backend

Supabase project ref: redzwiaseoavjbahsjgw

Supabase workaround

```sh
rm -rf supabase/.temp
supabase start
supabase link --project-ref redzwiaseoavjbahsjgw
supabase db push
rm -rf supabase/.temp  # Clean up after pushing
```
