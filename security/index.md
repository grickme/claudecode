---
layout: default
title: Security
---

# Security Best Practices

Guidelines for Claude Code to prevent credential leaks, secure applications, and protect against common threats.

---

## Protecting Secrets and API Keys

### Never Hardcode Credentials

**CRITICAL: Claude should NEVER write secrets directly in code.**

```typescript
// BAD - Never do this
const API_KEY = "sk-proj-abc123...";
const PASSWORD = "mypassword123";

// GOOD - Always use environment variables
const API_KEY = process.env.GEMINI_API_KEY;
const PASSWORD = process.env.DB_PASSWORD;
```

### Use Environment Variables

**Local development:** Create `.env.local` (never commit this file)
```bash
GEMINI_API_KEY=your-key-here
DATABASE_PASSWORD=your-password
STRIPE_SECRET_KEY=sk_test_...
```

**Production:** Use Google Secret Manager
```bash
# Store secret
echo -n "your-secret-value" | gcloud secrets create SECRET_NAME --data-file=- --project PROJECT_ID

# Access in Cloud Run
gcloud run deploy SERVICE \
  --set-secrets "GEMINI_API_KEY=gemini-key:latest" \
  --project PROJECT_ID
```

### Files to NEVER Commit

Add these to `.gitignore`:
```gitignore
# Environment files
.env
.env.local
.env.*.local
.env.production

# Credentials
*.pem
*.key
*.p12
*.pfx
credentials.json
service-account.json
service-account-key.json
*-credentials.json
*-service-account.json

# Firebase
firebase-adminsdk*.json
firebaseServiceAccountKey.json

# Google Cloud
gcloud-service-key.json
application_default_credentials.json

# IDE and OS
.idea/
.vscode/settings.json
.DS_Store
Thumbs.db
```

### Before Every Commit

**Claude should run these checks:**

```bash
# Search for potential secrets in staged files
git diff --cached --name-only | xargs grep -l -E "(sk-|sk_live_|sk_test_|ghp_|gho_|AKIA|password|secret|api_key)" 2>/dev/null

# Search for hardcoded keys patterns
git diff --cached | grep -E "(sk-proj-|AIza|ghp_|gho_|sk_live_|sk_test_)"
```

If any matches found, **DO NOT COMMIT**. Remove the secrets first.

---

## Securing API Routes

### Always Validate Authentication

```typescript
// app/api/protected/route.ts
import { NextRequest, NextResponse } from 'next/server';
import admin from 'firebase-admin';

export async function GET(request: NextRequest) {
  // Get token from header
  const authHeader = request.headers.get('authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const token = authHeader.split('Bearer ')[1];

  try {
    // Verify token
    const decoded = await admin.auth().verifyIdToken(token);
    const userId = decoded.uid;

    // Proceed with authenticated request
    return NextResponse.json({ userId, data: '...' });
  } catch (error) {
    return NextResponse.json({ error: 'Invalid token' }, { status: 401 });
  }
}
```

### Rate Limiting

Prevent abuse with rate limiting:

```typescript
// lib/rate-limit.ts
const rateLimitMap = new Map<string, { count: number; timestamp: number }>();

export function rateLimit(ip: string, limit: number = 100, windowMs: number = 60000): boolean {
  const now = Date.now();
  const record = rateLimitMap.get(ip);

  if (!record || now - record.timestamp > windowMs) {
    rateLimitMap.set(ip, { count: 1, timestamp: now });
    return true;
  }

  if (record.count >= limit) {
    return false; // Rate limited
  }

  record.count++;
  return true;
}

// Usage in API route
export async function GET(request: NextRequest) {
  const ip = request.headers.get('x-forwarded-for') || 'unknown';

  if (!rateLimit(ip, 100, 60000)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 });
  }

  // Continue...
}
```

### Input Validation

Never trust user input:

```typescript
import { z } from 'zod';

const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  age: z.number().int().min(0).max(150).optional(),
});

export async function POST(request: NextRequest) {
  const body = await request.json();

  const result = CreateUserSchema.safeParse(body);
  if (!result.success) {
    return NextResponse.json({ error: 'Invalid input', details: result.error }, { status: 400 });
  }

  const { email, name, age } = result.data;
  // Safe to use validated data
}
```

---

## Preventing Web Scraping

### Block Bots with robots.txt

```txt
# robots.txt
User-agent: *
Disallow: /api/
Disallow: /admin/
Disallow: /dashboard/
Disallow: /private/

# Block known bad bots
User-agent: AhrefsBot
Disallow: /

User-agent: SemrushBot
Disallow: /

User-agent: MJ12bot
Disallow: /

User-agent: DotBot
Disallow: /
```

### Add Security Headers

```typescript
// next.config.js
const securityHeaders = [
  {
    key: 'X-DNS-Prefetch-Control',
    value: 'on'
  },
  {
    key: 'X-Frame-Options',
    value: 'SAMEORIGIN'
  },
  {
    key: 'X-Content-Type-Options',
    value: 'nosniff'
  },
  {
    key: 'Referrer-Policy',
    value: 'origin-when-cross-origin'
  },
  {
    key: 'X-XSS-Protection',
    value: '1; mode=block'
  }
];

module.exports = {
  async headers() {
    return [
      {
        source: '/:path*',
        headers: securityHeaders,
      },
    ];
  },
};
```

### Detect and Block Scrapers

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

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
  const userAgent = request.headers.get('user-agent')?.toLowerCase() || '';

  // Block known scrapers
  if (BLOCKED_USER_AGENTS.some(bot => userAgent.includes(bot))) {
    return new NextResponse('Forbidden', { status: 403 });
  }

  // Block requests without user agent
  if (!userAgent || userAgent.length < 10) {
    return new NextResponse('Forbidden', { status: 403 });
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/api/:path*', '/dashboard/:path*'],
};
```

### Use Cloudflare Protection

If using Cloudflare:
1. Enable "Bot Fight Mode" in Security settings
2. Enable "Browser Integrity Check"
3. Set up firewall rules for suspicious patterns
4. Use "Under Attack Mode" if needed

---

## Firestore Security Rules

Always set proper security rules:

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Public read, authenticated write
    match /public/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }

    // Admin only
    match /admin/{document=**} {
      allow read, write: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // Deny everything else by default
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

Deploy rules:
```bash
firebase deploy --only firestore:rules --project PROJECT_ID
```

---

## Cloud Storage Security

### Signed URLs for Private Files

Never make buckets public. Use signed URLs:

```typescript
import { Storage } from '@google-cloud/storage';

const storage = new Storage();
const bucket = storage.bucket('my-private-bucket');

async function getSignedUrl(filePath: string): Promise<string> {
  const [url] = await bucket.file(filePath).getSignedUrl({
    action: 'read',
    expires: Date.now() + 15 * 60 * 1000, // 15 minutes
  });
  return url;
}
```

### Bucket Permissions

```bash
# Remove public access
gsutil iam ch -d allUsers:objectViewer gs://BUCKET_NAME

# Grant access only to service account
gsutil iam ch serviceAccount:SA_EMAIL:objectViewer gs://BUCKET_NAME
```

---

## Security Checklist for Claude

Before deploying, verify:

- [ ] No hardcoded secrets in code
- [ ] `.env` files in `.gitignore`
- [ ] Service account keys not in repo
- [ ] API routes have authentication
- [ ] Input validation on all endpoints
- [ ] Rate limiting implemented
- [ ] Firestore security rules deployed
- [ ] Cloud Storage buckets are private
- [ ] Security headers configured
- [ ] robots.txt blocks sensitive paths
- [ ] HTTPS enforced (automatic on Cloud Run)

---

## If Secrets Are Leaked

**Immediate actions:**

1. **Revoke the key immediately**
   - Google Cloud: IAM → Service Accounts → Keys → Delete
   - Firebase: Project Settings → Service Accounts → Generate New Key
   - API keys: Regenerate in respective console

2. **Remove from git history**
   ```bash
   # Install BFG Repo-Cleaner
   # Then run:
   bfg --replace-text passwords.txt repo.git
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   git push --force
   ```

3. **Audit access logs**
   - Check Cloud Logging for unauthorized access
   - Review Firestore/Storage access logs

4. **Rotate all related credentials**
   - If one key leaked, assume others may be compromised

---

## Quick Reference

| Risk | Prevention |
|------|------------|
| API key in code | Use `process.env.VAR_NAME` |
| Key in git | Add to `.gitignore`, use Secret Manager |
| Unauthorized API access | Verify Firebase token |
| Scraping | robots.txt, rate limiting, bot detection |
| Public bucket | Use signed URLs, private buckets |
| Firestore open | Deploy security rules |
| XSS/injection | Input validation with Zod |

---

[← Back to Home](../)
