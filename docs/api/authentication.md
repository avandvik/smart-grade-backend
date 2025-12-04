# Authentication

SmartGRADE uses Supabase Auth for user authentication. All API operations require an authenticated user.

## API Keys

Supabase uses two types of keys:

| Key Type | Prefix | Usage |
|----------|--------|-------|
| **Publishable Key** | `sb_publishable_...` | Safe to expose in frontend code |
| **Secret Key** | `sb_secret_...` | Backend only, never expose to clients |

## Client Initialization

```javascript
import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
  "https://redzwiaseoavjbahsjgw.supabase.co",
  "sb_publishable_FFURYQgBt1RQh2CkPGuoag_IyF3fWXE"
);
```

## Sign Up

```javascript
const { data, error } = await supabase.auth.signUp({
  email: "user@example.com",
  password: "secure-password"
});

if (error) {
  console.error("Sign up failed:", error.message);
} else {
  console.log("User created:", data.user.id);
}
```

## Sign In

```javascript
const { data, error } = await supabase.auth.signInWithPassword({
  email: "user@example.com",
  password: "secure-password"
});

if (error) {
  console.error("Sign in failed:", error.message);
} else {
  console.log("Signed in:", data.user.email);
  console.log("Access token:", data.session.access_token);
}
```

## Session Management

### Get Current Session

```javascript
const { data: { session } } = await supabase.auth.getSession();

if (session) {
  console.log("User is logged in:", session.user.email);
}
```

### Get Current User

```javascript
const { data: { user } } = await supabase.auth.getUser();

if (user) {
  console.log("User ID:", user.id);
}
```

### Listen for Auth Changes

```javascript
const { data: { subscription } } = supabase.auth.onAuthStateChange(
  (event, session) => {
    console.log("Auth event:", event);
    if (session) {
      console.log("User:", session.user.email);
    }
  }
);

// Cleanup when done
subscription.unsubscribe();
```

## Sign Out

```javascript
await supabase.auth.signOut();
```

## Password Reset

```javascript
// Request password reset email
const { error } = await supabase.auth.resetPasswordForEmail(
  "user@example.com",
  { redirectTo: "https://yourapp.com/reset-password" }
);

// Update password (after clicking email link)
const { error } = await supabase.auth.updateUser({
  password: "new-secure-password"
});
```

## Required Headers

When using the REST API directly (without the Supabase client):

```http
apikey: sb_publishable_FFURYQgBt1RQh2CkPGuoag_IyF3fWXE
Authorization: Bearer <access_token>
Content-Type: application/json
```

Example fetch request:

```javascript
const response = await fetch(
  "https://redzwiaseoavjbahsjgw.supabase.co/rest/v1/reviews",
  {
    headers: {
      "apikey": "sb_publishable_FFURYQgBt1RQh2CkPGuoag_IyF3fWXE",
      "Authorization": `Bearer ${session.access_token}`,
      "Content-Type": "application/json"
    }
  }
);
```

## Row Level Security

All database tables use Row Level Security (RLS) policies that automatically filter data by the authenticated user:

- Users can only view their own reviews
- Users can only create reviews linked to their user ID
- Users can only modify or delete their own data
- Related data (pages, parsed results) inherits access through the parent review

## JWT Tokens

- Access tokens expire after 1 hour
- The Supabase client automatically refreshes tokens
- Refresh tokens are stored in localStorage by default

## Error Handling

Common authentication errors:

```javascript
const { data, error } = await supabase.auth.signInWithPassword({
  email,
  password
});

if (error) {
  switch (error.message) {
    case "Invalid login credentials":
      // Wrong email or password
      break;
    case "Email not confirmed":
      // User needs to verify email
      break;
    default:
      console.error("Auth error:", error.message);
  }
}
```
