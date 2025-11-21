# Authentication

## Overview

SmartGRADE uses Supabase Auth with JWT tokens. All API requests require
authentication headers.

## Required Headers

```http
apikey: publishable-key
Authorization: Bearer your-jwt-token
```

These are placed in the header by default when using the Supabase SDK to send
requests to the backend.

## Authentication Methods

### Email/Password

```javascript
const { data, error } = await supabase.auth.signInWithPassword({
  email: "user@example.com",
  password: "password",
});
```

### Sign Up

```javascript
const { data, error } = await supabase.auth.signUp({
  email: "user@example.com",
  password: "password",
});
```

### Get Current User

```javascript
const { data: { user } } = await supabase.auth.getUser();
```

### Sign Out

```javascript
await supabase.auth.signOut();
```

## Direct API Calls

If not using the Supabase client library:

```javascript
// Get JWT token after authentication
const token = session.access_token;

// Use in API calls
fetch("https://redzwiaseoavjbahsjgw.supabase.co/rest/v1/reviews", {
  headers: {
    "apikey": "publishable-key",
    "Authorization": `Bearer ${token}`,
    "Content-Type": "application/json",
  },
});
```

## Row Level Security

All database operations are automatically scoped to the authenticated user
through RLS policies:

- Users can only see their own reviews
- Users can only modify their own data
- Cascade deletion ensures data consistency
