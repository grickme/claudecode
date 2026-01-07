---
layout: default
title: Next.js API Routes
---

# Next.js API Routes

Server-side API endpoints using Next.js App Router.

## Basic API Route

```typescript
// app/api/hello/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  return NextResponse.json({ message: 'Hello, World!' });
}

export async function POST(request: NextRequest) {
  const body = await request.json();
  return NextResponse.json({ received: body }, { status: 201 });
}
```

## HTTP Methods

```typescript
// app/api/items/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';

// GET /api/items
export async function GET(request: NextRequest) {
  const snapshot = await db.collection('items').get();
  const items = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  return NextResponse.json({ items });
}

// POST /api/items
export async function POST(request: NextRequest) {
  const body = await request.json();
  const docRef = await db.collection('items').add(body);
  return NextResponse.json({ id: docRef.id }, { status: 201 });
}
```

## Dynamic Routes

```typescript
// app/api/items/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';

interface Params {
  params: { id: string };
}

// GET /api/items/:id
export async function GET(request: NextRequest, { params }: Params) {
  const doc = await db.collection('items').doc(params.id).get();

  if (!doc.exists) {
    return NextResponse.json({ error: 'Not found' }, { status: 404 });
  }

  return NextResponse.json({ id: doc.id, ...doc.data() });
}

// PUT /api/items/:id
export async function PUT(request: NextRequest, { params }: Params) {
  const body = await request.json();
  await db.collection('items').doc(params.id).update(body);
  return NextResponse.json({ success: true });
}

// DELETE /api/items/:id
export async function DELETE(request: NextRequest, { params }: Params) {
  await db.collection('items').doc(params.id).delete();
  return NextResponse.json({ success: true });
}
```

## Query Parameters

```typescript
// GET /api/items?status=active&limit=10
export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const status = searchParams.get('status');
  const limit = parseInt(searchParams.get('limit') || '10');

  let query = db.collection('items').limit(limit);

  if (status) {
    query = query.where('status', '==', status);
  }

  const snapshot = await query.get();
  const items = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

  return NextResponse.json({ items });
}
```

## Request Validation with Zod

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';

const CreateItemSchema = z.object({
  name: z.string().min(1).max(100),
  price: z.number().positive(),
  category: z.enum(['electronics', 'clothing', 'food']),
  tags: z.array(z.string()).optional(),
});

export async function POST(request: NextRequest) {
  const body = await request.json();

  const result = CreateItemSchema.safeParse(body);

  if (!result.success) {
    return NextResponse.json(
      { error: 'Validation failed', details: result.error.flatten() },
      { status: 400 }
    );
  }

  const item = result.data;
  const docRef = await db.collection('items').add(item);

  return NextResponse.json({ id: docRef.id }, { status: 201 });
}
```

## Authentication Middleware

> **See also:** [API Protection Pattern](../security/api-protection.md) for complete CORS + middleware guide.

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
    return { authenticated: true, userId: decoded.uid, email: decoded.email };
  } catch {
    return { authenticated: false, error: 'Invalid or expired token' };
  }
}

// Usage in API route
export async function GET(request: NextRequest) {
  const auth = await verifyAuth(request);

  if (!auth.authenticated) {
    return NextResponse.json({ error: auth.error }, { status: 401 });
  }

  // auth.userId and auth.email are available
  // ...
}
```

## Reusable Auth Wrapper

```typescript
// lib/with-auth.ts
import { NextRequest, NextResponse } from 'next/server';
import { verifyAuth } from './auth-middleware';
import { DecodedIdToken } from 'firebase-admin/auth';

type AuthHandler = (
  request: NextRequest,
  context: { params: any; user: DecodedIdToken }
) => Promise<NextResponse>;

export function withAuth(handler: AuthHandler) {
  return async (request: NextRequest, context: { params: any }) => {
    const user = await verifyAuth(request);

    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    return handler(request, { ...context, user });
  };
}

// Usage
export const GET = withAuth(async (request, { params, user }) => {
  // user is guaranteed to exist
  console.log('User ID:', user.uid);

  return NextResponse.json({ message: 'Hello, authenticated user!' });
});
```

## Error Handling

```typescript
// lib/api-error.ts
export class APIError extends Error {
  constructor(
    public statusCode: number,
    message: string
  ) {
    super(message);
  }
}

// lib/error-handler.ts
import { NextResponse } from 'next/server';
import { APIError } from './api-error';

export function handleError(error: unknown) {
  console.error('API Error:', error);

  if (error instanceof APIError) {
    return NextResponse.json(
      { error: error.message },
      { status: error.statusCode }
    );
  }

  if (error instanceof z.ZodError) {
    return NextResponse.json(
      { error: 'Validation failed', details: error.flatten() },
      { status: 400 }
    );
  }

  return NextResponse.json(
    { error: 'Internal server error' },
    { status: 500 }
  );
}

// Usage
export async function POST(request: NextRequest) {
  try {
    // Your logic...
    throw new APIError(400, 'Invalid request');
  } catch (error) {
    return handleError(error);
  }
}
```

## File Uploads

```typescript
// app/api/upload/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { bucket } from '@/lib/storage';

export async function POST(request: NextRequest) {
  const formData = await request.formData();
  const file = formData.get('file') as File;

  if (!file) {
    return NextResponse.json({ error: 'No file provided' }, { status: 400 });
  }

  // Validate file
  const maxSize = 10 * 1024 * 1024; // 10MB
  if (file.size > maxSize) {
    return NextResponse.json({ error: 'File too large' }, { status: 400 });
  }

  const allowedTypes = ['image/jpeg', 'image/png', 'application/pdf'];
  if (!allowedTypes.includes(file.type)) {
    return NextResponse.json({ error: 'Invalid file type' }, { status: 400 });
  }

  // Upload to GCS
  const buffer = Buffer.from(await file.arrayBuffer());
  const path = `uploads/${Date.now()}-${file.name}`;

  await bucket.file(path).save(buffer, {
    contentType: file.type,
  });

  return NextResponse.json({ path });
}
```

## Streaming Response

```typescript
// app/api/stream/route.ts
import { NextRequest } from 'next/server';

export async function GET(request: NextRequest) {
  const encoder = new TextEncoder();

  const stream = new ReadableStream({
    async start(controller) {
      for (let i = 0; i < 5; i++) {
        await new Promise(r => setTimeout(r, 1000));
        controller.enqueue(encoder.encode(`data: Message ${i}\n\n`));
      }
      controller.close();
    },
  });

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    },
  });
}
```

## CORS Headers

> **Recommended:** Use middleware for CORS. See [API Protection Pattern](../security/api-protection.md).

For simple per-route CORS (not recommended for production):

```typescript
// For specific routes
export async function GET(request: NextRequest) {
  const response = NextResponse.json({ data: 'hello' });

  response.headers.set('Access-Control-Allow-Origin', '*');
  response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');

  return response;
}

// OPTIONS handler for preflight
export async function OPTIONS(request: NextRequest) {
  return new NextResponse(null, {
    status: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  });
}
```

**Warning:** Using `*` for origin allows all domains. For production, use specific allowed origins in middleware.

## Rate Limiting

```typescript
// Using Upstash Redis
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '10 s'),
});

export async function POST(request: NextRequest) {
  const ip = request.ip ?? request.headers.get('x-forwarded-for') ?? 'anonymous';

  const { success, limit, reset, remaining } = await ratelimit.limit(ip);

  if (!success) {
    return NextResponse.json(
      { error: 'Too many requests' },
      {
        status: 429,
        headers: {
          'X-RateLimit-Limit': limit.toString(),
          'X-RateLimit-Remaining': remaining.toString(),
          'X-RateLimit-Reset': reset.toString(),
        },
      }
    );
  }

  // Process request...
}
```

## API Route Structure

```
app/
├── api/
│   ├── auth/
│   │   ├── signin/route.ts     # POST /api/auth/signin
│   │   ├── signup/route.ts     # POST /api/auth/signup
│   │   └── signout/route.ts    # POST /api/auth/signout
│   ├── users/
│   │   ├── route.ts            # GET, POST /api/users
│   │   └── [id]/route.ts       # GET, PUT, DELETE /api/users/:id
│   ├── companies/
│   │   ├── route.ts            # GET, POST /api/companies
│   │   ├── [id]/
│   │   │   ├── route.ts        # GET, PUT, DELETE /api/companies/:id
│   │   │   └── employees/route.ts  # /api/companies/:id/employees
│   └── upload/route.ts         # POST /api/upload
```

---

[← Backend Index](./index.md) | [Python PDF →](./python-pdf.md)
