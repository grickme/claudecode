---
layout: default
title: API Protection Pattern
---

# API Protection Pattern (Next.js + Firebase Auth)

A layered security approach combining CORS, middleware, and token verification.

---

## Architecture Overview

```
Request → Middleware (CORS + Bot) → API Route (Token Verification) → Handler
```

| Layer                    | What it does                                           |
|--------------------------|--------------------------------------------------------|
| Middleware (CORS)        | Blocks cross-origin requests from unauthorized domains |
| Middleware (Auth cookie) | Redirects unauthenticated users on frontend routes     |
| verifyAuth()             | Validates Firebase token on each API request           |
| Bot blocking             | Blocks known crawler user-agents                       |

---

## 1. Middleware Layer (middleware.ts)

Handles CORS, bot blocking, and frontend auth redirects:

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// Allowed origins for CORS
const ALLOWED_ORIGINS = [
  'https://yourdomain.com',
  'https://www.yourdomain.com',
];

// Add localhost in development
if (process.env.NODE_ENV === 'development') {
  ALLOWED_ORIGINS.push('http://localhost:3000');
}

// Known bot user agents to block
const BLOCKED_USER_AGENTS = [
  'ahrefsbot',
  'semrushbot',
  'dotbot',
  'mj12bot',
  'petalbot',
  'bytespider',
  'gptbot',
  'ccbot',
];

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const userAgent = request.headers.get('user-agent')?.toLowerCase() || '';

  // Block known scrapers
  if (BLOCKED_USER_AGENTS.some(bot => userAgent.includes(bot))) {
    return new NextResponse('Forbidden', { status: 403 });
  }

  // API routes: CORS protection
  if (pathname.startsWith('/api')) {
    const origin = request.headers.get('origin');

    // Handle preflight OPTIONS request
    if (request.method === 'OPTIONS') {
      const response = new NextResponse(null, { status: 204 });
      if (origin && ALLOWED_ORIGINS.includes(origin)) {
        response.headers.set('Access-Control-Allow-Origin', origin);
        response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
        response.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
        response.headers.set('Access-Control-Max-Age', '86400');
      }
      return response;
    }

    // Block unauthorized origins (but allow no-origin for server/curl)
    if (origin && !ALLOWED_ORIGINS.includes(origin)) {
      return NextResponse.json({ error: 'CORS: Origin not allowed' }, { status: 403 });
    }

    const response = NextResponse.next();
    if (origin) {
      response.headers.set('Access-Control-Allow-Origin', origin);
    }
    return response;
  }

  // Frontend routes: check auth cookie, redirect to signin
  if (pathname.startsWith('/dashboard') || pathname.startsWith('/app')) {
    const token = request.cookies.get('auth-token');
    if (!token) {
      return NextResponse.redirect(new URL('/auth/signin', request.url));
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/api/:path*', '/dashboard/:path*', '/app/:path*'],
};
```

---

## 2. Auth Middleware (lib/auth-middleware.ts)

Reusable token verification with detailed result:

```typescript
// lib/auth-middleware.ts
import { NextRequest } from 'next/server';
import { adminAuth } from './firebase-admin';

export interface AuthResult {
  authenticated: boolean;
  userId?: string;
  email?: string;
  error?: string;
}

export async function verifyAuth(request: NextRequest): Promise<AuthResult> {
  const authHeader = request.headers.get('Authorization');

  if (!authHeader?.startsWith('Bearer ')) {
    return { authenticated: false, error: 'Missing Authorization header' };
  }

  try {
    const token = authHeader.replace('Bearer ', '');
    const decoded = await adminAuth.verifyIdToken(token);
    return {
      authenticated: true,
      userId: decoded.uid,
      email: decoded.email
    };
  } catch {
    return { authenticated: false, error: 'Invalid or expired token' };
  }
}
```

---

## 3. API Route Pattern

Standard pattern for protected routes:

```typescript
// app/api/example/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { verifyAuth } from '@/lib/auth-middleware';

export async function GET(request: NextRequest) {
  // Require auth
  const auth = await verifyAuth(request);
  if (!auth.authenticated) {
    return NextResponse.json(
      { error: auth.error || 'Authentication required' },
      { status: 401 }
    );
  }

  // Use auth.userId for user-specific data
  const userId = auth.userId;

  // Your protected logic here...
  return NextResponse.json({ message: 'Success', userId });
}
```

---

## 4. Exceptions (No Auth Required)

Some routes don't require token verification:

| Route | Reason |
|-------|--------|
| `POST /api/auth/signin` | Login endpoint (use email allowlist instead) |
| `POST /api/stripe/webhooks` | Uses Stripe signature verification |
| `GET /api/health` | Health check for load balancers |

### Sign-in with Email Allowlist

```typescript
// app/api/auth/signin/route.ts
const ALLOWED_EMAILS = [
  'admin@company.com',
  '@company.com', // Domain allowlist
];

export async function POST(request: NextRequest) {
  const { email } = await request.json();

  const isAllowed = ALLOWED_EMAILS.some(allowed =>
    allowed.startsWith('@')
      ? email.endsWith(allowed)
      : email === allowed
  );

  if (!isAllowed) {
    return NextResponse.json({ error: 'Email not authorized' }, { status: 403 });
  }

  // Proceed with sign-in...
}
```

### Stripe Webhook Verification

```typescript
// app/api/stripe/webhooks/route.ts
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

export async function POST(request: NextRequest) {
  const body = await request.text();
  const signature = request.headers.get('stripe-signature')!;

  try {
    const event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    );

    // Handle webhook event...
    return NextResponse.json({ received: true });
  } catch (err) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }
}
```

---

## Key Security Points

### CORS Only Blocks Browsers

CORS is enforced by browsers, not servers. Direct requests (curl, Postman, server-to-server) bypass CORS entirely.

```bash
# This works even with CORS restrictions:
curl -H "Authorization: Bearer TOKEN" https://yourapi.com/api/data
```

**Implication:** CORS is one layer, not the only layer. Always verify tokens.

### No Origin = Allowed

Same-origin requests and server-to-server calls have no `Origin` header:

```typescript
// This is intentional - don't block no-origin requests
if (origin && !ALLOWED_ORIGINS.includes(origin)) {
  // Block only if origin exists AND is not allowed
}
```

### Token Verification is Mandatory

Every protected API route must verify the Firebase token. Never rely on CORS alone.

### Allowlist Over Blocklist

For sensitive endpoints like sign-in, use an allowlist (approved emails/domains) rather than trying to block bad actors.

---

## Quick Reference

```typescript
// Import pattern
import { verifyAuth, AuthResult } from '@/lib/auth-middleware';

// Usage in route
export async function GET(request: NextRequest) {
  const auth = await verifyAuth(request);
  if (!auth.authenticated) {
    return NextResponse.json({ error: auth.error }, { status: 401 });
  }

  // auth.userId and auth.email are available
}
```

---

## Related

- [Firebase Auth](../auth/firebase-auth.md) - Client-side authentication
- [Security Best Practices](./index.md) - Secrets, input validation, headers

---

[← Security Index](./index.md) | [Back to Home](../)
