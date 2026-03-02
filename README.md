# Supabase Reverse Proxy on Nginx

## Overview

This service runs Nginx in DigitalOcean (Singapore) and exposes a reverse proxy with environment-driven CORS configuration.

## Container Images: 
    docker pull ghcr.io/jimsnet/nginx-supabase-proxy:latest
        or
    docker pull jimsnet/nginx-supabase-proxy:latest

## Environment Variables

Set these in DigitalOcean App Platform for your Nginx service:

| Variable | Example value | Effect |
|----------|---------------|--------|
| FRONTEND_DOMAIN | frontend.com | Allows any `*.frontend.com` origin |
| ENABLE_LOCALHOST_CORS | 1 or 0 | Toggles localhost CORS (dev only) |

### Typical Setups

| Environment | FRONTEND_DOMAIN | ENABLE_LOCALHOST_CORS | Allowed origins examples |
|-------------|-----------------|----------------------|--------------------------|
| Dev | frontend.com | 1 | https://app.frontend.com, http://localhost:5173 |
| Staging | frontend.com | 0 | https://staging.frontend.com, no localhost |
| Prod | frontend.com | 0 | https://app.frontend.com, https://foo.frontend.com |

The Nginx config uses these env vars via `env FRONTEND_DOMAIN;` and `env ENABLE_LOCALHOST_CORS;`, then matches origins with regex maps.


## Proxy Configuration

### Public URL

**Base URL**: `https://api.yourdomain.com` (via DigitalOcean App Platform)

### Pattern

```
/supabase/<project>/... → https://<project>.supabase.co/...
```

**Proxy path format**: `/supabase/<project>/...`

**Upstream**: `https://<project>.supabase.co/...`

## CORS Support

CORS is enabled for:

- Any subdomain of `frontend.com` (e.g., `https://app.frontend.com`)
- `localhost` with any port (for local dev)

## URL Mapping Examples

### Example 1: REST API request

```
Request:  https://api.yourdomain.com/supabase/myproject/rest/v1/tables
↓
Upstream: https://myproject.supabase.co/rest/v1/tables
```

### Example 2: Auth request

```
Request:  https://api.yourdomain.com/supabase/myproject/auth/v1/signup?foo=bar
↓
Upstream: https://myproject.supabase.co/auth/v1/signup?foo=bar
```

**Note**: The project name (`myproject`) is taken from the URL and used as the Supabase subdomain. The rest of the path and query string is preserved.

## Frontend Integration (Supabase JS)

### Example Setup

```typescript
import { createClient } from '@supabase/supabase-js';

const project = 'myproject';
const supabaseUrl = `https://api.yourdomain.com/supabase/${project}`;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

export const supabase = createClient(supabaseUrl, supabaseKey);
```

All calls from the frontend now hit the proxy instead of direct `*.supabase.co` endpoints.

## Testing with cURL

### Before You Begin

Replace these placeholders in the examples below:

- `myproject` - Your Supabase project name
- `api.yourdomain.com` - Your real proxy domain
- `<ANON_KEY>` - Your anon/public key (if needed for that endpoint)

### Test 1: Simple GET from localhost

Tests proxy routing only:

```bash
curl -i \
  -H "Origin: http://localhost:5173" \
  "https://api.yourdomain.com/supabase/myproject/rest/v1/your_table?select=*"
```

**What to check:**

- Response status and body should match calling Supabase directly
- Headers should include: `Access-Control-Allow-Origin: http://localhost:5173`

### Test 2: Auth or any endpoint requiring API key

```bash
curl -i \
  -H "Origin: https://app.frontend.com" \
  -H "apikey: <ANON_KEY>" \
  -H "Authorization: Bearer <ANON_KEY>" \
  "https://api.yourdomain.com/supabase/myproject/rest/v1/your_table?select=*"
```

**What to check:**

- Correct JSON data from Supabase
- Headers include: `Access-Control-Allow-Origin: https://app.frontend.com`

### Test 3: Preflight OPTIONS check

```bash
curl -i -X OPTIONS \
  -H "Origin: https://app.frontend.com" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Authorization, Content-Type, apikey" \
  "https://api.yourdomain.com/supabase/myproject/rest/v1/your_table"
```

**Expected response:**

- Status: `204`
- Headers include:
  - `Access-Control-Allow-Origin: https://app.frontend.com`
  - `Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS`
  - `Access-Control-Allow-Headers: Authorization, Content-Type, apikey, x-client-info`
