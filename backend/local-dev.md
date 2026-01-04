---
layout: default
title: Local Development
---

# Local Development

How to run and test your app locally before deploying.

---

## Start the Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

You should see your app running locally.

---

## Environment Variables

Create `.env.local` in your project root (never commit this file):

```bash
# Firebase (client-side)
NEXT_PUBLIC_FIREBASE_API_KEY=your-api-key
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your-project-id

# Server-side
GEMINI_API_KEY=your-gemini-key
GOOGLE_CLOUD_PROJECT=your-project-id
```

**Important:**
- Variables starting with `NEXT_PUBLIC_` are exposed to the browser
- Other variables are server-side only
- Never commit `.env.local` to git

---

## Hot Reload

Next.js automatically reloads when you save files:

- **Save a file** → Browser updates automatically
- **No restart needed** for most changes
- **Restart required** if you change:
  - `next.config.js`
  - `.env.local`
  - `package.json`

To restart:
```bash
# Press Ctrl+C to stop, then:
npm run dev
```

---

## Testing API Routes

Your API routes are available at `http://localhost:3000/api/...`

Test with curl:
```bash
# GET request
curl http://localhost:3000/api/health

# POST request
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Test User"}'
```

Or use the browser's Network tab to inspect requests.

---

## Common Local Dev Issues

| Issue | Solution |
|-------|----------|
| Port 3000 already in use | `PORT=3001 npm run dev` or kill the other process |
| "Module not found" | Run `npm install` |
| Environment variable undefined | Check `.env.local` exists and restart dev server |
| Changes not showing | Hard refresh (Ctrl+Shift+R) or restart dev server |
| TypeScript errors | Run `npm run type-check` to see all errors |
| "Cannot connect to Firestore" | Check `GOOGLE_CLOUD_PROJECT` is set |

---

## Viewing Logs

In development, logs appear in your terminal where `npm run dev` is running.

```bash
# You'll see:
- ready started server on 0.0.0.0:3000
- [API] GET /api/health 200
- [Error] Something went wrong...
```

Use `console.log()` in your code to debug:
```typescript
export async function GET() {
  console.log('API called');  // Shows in terminal
  return Response.json({ status: 'ok' });
}
```

---

## Local vs Production Differences

| Aspect | Local | Production |
|--------|-------|------------|
| URL | localhost:3000 | your-app.run.app |
| Env vars | `.env.local` file | Cloud Run secrets |
| Logs | Terminal | Cloud Logging |
| Database | Same Firestore | Same Firestore |
| Hot reload | Yes | No (redeploy needed) |

**Tip:** Use the same Firestore database for local and production during development. Create a separate project for production later.

---

## Before Deploying

Checklist before pushing to production:

- [ ] App works locally without errors
- [ ] All environment variables documented
- [ ] No `console.log` statements with sensitive data
- [ ] No hardcoded API keys or passwords
- [ ] `.env.local` is in `.gitignore`

---

[← Back to Backend](./index)
