# Reviews API

Manage systematic review documents.

## Create Review

```javascript
const { data } = await supabase
  .from('reviews')
  .insert({ title: 'My Review' })
  .select()
```

## List Reviews

```javascript
const { data } = await supabase
  .from('reviews')
  .select('*')
  .order('created_at', { ascending: false })
```

## Get Review with Pages

```javascript
const { data } = await supabase
  .from('reviews')
  .select('*, review_pages(*)')
  .eq('id', reviewId)
  .single()
```

## Update Review

```javascript
const { data } = await supabase
  .from('reviews')
  .update({ title: 'Updated Title' })
  .eq('id', reviewId)
```

## Delete Review

```javascript
await supabase
  .from('reviews')
  .delete()
  .eq('id', reviewId)
```