# Project CLAUDE.md - Full Template

Comprehensive template with all common sections. Copy to `.claude/CLAUDE.md`.

---

```markdown
# [Project Name] - Claude Code Configuration

## Tech Stack Reference

When building this application, follow guidelines from:
https://grick.me/

Specific guides:
- Getting Started: https://grick.me/getting-started
- Firestore: https://grick.me/infrastructure/firestore
- Cloud Storage: https://grick.me/infrastructure/gcs
- Cloud Run: https://grick.me/infrastructure/cloud-run
- Secrets: https://grick.me/infrastructure/secrets
- Gemini AI: https://grick.me/ai/gemini
- Vertex AI: https://grick.me/ai/vertex-ai
- Embeddings: https://grick.me/ai/embeddings
- Auth: https://grick.me/auth/firebase-auth
- API Routes: https://grick.me/backend/nextjs-api
- API Protection: https://grick.me/security/api-protection
- Email: https://grick.me/email/resend
- Security: https://grick.me/security/
- Troubleshooting: https://grick.me/troubleshooting

---

## Project Overview

| Field | Value |
|-------|-------|
| **Name** | [Project name] |
| **Description** | [Brief description] |
| **GCP Project ID** | [project-id] |
| **Region** | us-west1 |
| **Repository** | https://github.com/[user]/[repo] |

---

## Technology Stack

### Frontend
- Next.js 14+ (App Router)
- React 18+
- TypeScript
- Tailwind CSS
- shadcn/ui components

### Backend
- Next.js API Routes
- Firebase Admin SDK

### Database
- Google Firestore

### Authentication
- Firebase Auth (Email/Password)

### AI/ML
- Gemini 2.5 Flash (via API)
- Vertex AI (production)

### Infrastructure
- Google Cloud Run
- Google Cloud Storage
- Secret Manager

### Email
- Resend

---

## GCloud Commands

**CRITICAL: Always specify --project explicitly**

```bash
# Build and deploy
gcloud builds submit --config=cloudbuild.yaml --project [PROJECT_ID]

gcloud run deploy [SERVICE]   --image gcr.io/[PROJECT_ID]/[SERVICE]:latest   --project [PROJECT_ID]   --region us-west1   --allow-unauthenticated

# View logs
gcloud run services logs tail [SERVICE] --project [PROJECT_ID] --region us-west1

# List services
gcloud run services list --project [PROJECT_ID]
```

---

## Environment Variables

### Local Development (.env.local)

```bash
# Firebase Client
NEXT_PUBLIC_FIREBASE_API_KEY=
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=
NEXT_PUBLIC_FIREBASE_PROJECT_ID=

# Firebase Admin (base64 encoded service account JSON)
FIREBASE_ADMIN_PRIVATE_KEY=

# AI
GEMINI_API_KEY=
GCP_PROJECT_ID=

# Email
RESEND_API_KEY=

# App
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

### Production (Secret Manager)

Secrets stored in GCP Secret Manager:
- `GEMINI_API_KEY`
- `RESEND_API_KEY`
- `FIREBASE_ADMIN_KEY`

---

## Project Structure

```
[project-name]/
├── app/
│   ├── layout.tsx              # Root layout
│   ├── page.tsx                # Home page
│   ├── globals.css             # Global styles
│   ├── api/
│   │   ├── auth/
│   │   │   ├── signin/route.ts
│   │   │   └── signup/route.ts
│   │   ├── [resource]/
│   │   │   ├── route.ts        # GET, POST
│   │   │   └── [id]/route.ts   # GET, PUT, DELETE
│   │   └── ...
│   ├── dashboard/
│   │   ├── layout.tsx
│   │   └── page.tsx
│   └── auth/
│       ├── signin/page.tsx
│       └── signup/page.tsx
├── components/
│   ├── ui/                     # shadcn/ui
│   └── ...                     # Custom components
├── lib/
│   ├── firebase.ts             # Client config
│   ├── firebase-admin.ts       # Admin config
│   ├── gemini.ts               # AI client
│   └── utils.ts
├── hooks/
│   └── useAuth.ts
├── contexts/
│   └── AuthContext.tsx
├── types/
│   └── index.ts
├── Dockerfile
├── cloudbuild.yaml
├── next.config.js
├── tailwind.config.js
└── package.json
```

---

## Firestore Collections

| Collection | Description | Key Fields |
|------------|-------------|------------|
| `users` | User profiles | uid, email, name, role |
| `[resource]` | [Description] | [fields] |

### Security Rules Pattern

```javascript
match /users/{userId} {
  allow read: if request.auth.uid == userId;
  allow write: if request.auth.uid == userId;
}
```

---

## API Routes

| Endpoint | Method | Description | Auth |
|----------|--------|-------------|------|
| `/api/auth/signin` | POST | Sign in user | No |
| `/api/auth/signup` | POST | Create account | No |
| `/api/[resource]` | GET | List items | Yes |
| `/api/[resource]` | POST | Create item | Yes |
| `/api/[resource]/[id]` | GET | Get item | Yes |
| `/api/[resource]/[id]` | PUT | Update item | Yes |
| `/api/[resource]/[id]` | DELETE | Delete item | Yes |

---

## Development Commands

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build

# Run production build locally
npm start

# Type check
npm run type-check

# Lint
npm run lint
```

---

## Deployment

### Manual Deploy

```bash
# 1. Build and push
gcloud builds submit --tag gcr.io/[PROJECT_ID]/[SERVICE] --project [PROJECT_ID]

# 2. Deploy
gcloud run deploy [SERVICE]   --image gcr.io/[PROJECT_ID]/[SERVICE]:latest   --project [PROJECT_ID]   --region us-west1   --allow-unauthenticated   --set-secrets "GEMINI_API_KEY=gemini-key:latest"
```

### CI/CD (cloudbuild.yaml)

Triggered automatically on push to main branch.

---

## Common Tasks

### Add a new API endpoint

1. Create `app/api/[endpoint]/route.ts`
2. Implement GET/POST handlers
3. Add authentication check if needed
4. Update this documentation

### Add a new page

1. Create `app/[page]/page.tsx`
2. Add to navigation if needed
3. Add loading.tsx and error.tsx if needed

### Add Firestore collection

1. Define TypeScript interface in `types/`
2. Create collection in Firestore
3. Add security rules
4. Create API routes

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Auth not working | Check Firebase config, verify domain |
| API 401 errors | Check token, verify auth middleware |
| Deploy fails | Check cloudbuild.yaml, verify secrets |
| Firestore permission denied | Check security rules |
| Module not found | Run `npm install` |
| Port 3000 in use | Use `PORT=3001 npm run dev` |
| Environment variable undefined | Check .env.local exists and restart dev server |

---

## Debug Commands

```bash
# View Cloud Run logs (last 50 entries)
gcloud run services logs read [SERVICE] --project [PROJECT_ID] --limit 50

# View recent builds
gcloud builds list --project [PROJECT_ID] --limit 5

# Test API locally with auth token
curl http://localhost:3000/api/[resource] -H "Authorization: Bearer [TOKEN]"

# Check if secret exists
gcloud secrets versions access latest --secret=[SECRET_NAME] --project [PROJECT_ID]

# Verify deployment status
gcloud run services describe [SERVICE] --project [PROJECT_ID] --region us-west1
```

---

## Security Checklist

Before deployment:
- [ ] No hardcoded API keys or secrets in code
- [ ] .env and .env.local in .gitignore
- [ ] API routes verify authentication tokens
- [ ] Firestore rules restrict access properly
- [ ] Input validation on all forms
- [ ] CORS configured correctly

Before git commit:
- [ ] Run `git diff --cached` to review staged changes
- [ ] No passwords, tokens, or keys in code
- [ ] No .env files being committed

---

## Notes

[Add project-specific notes, decisions, or context here]

---

**Last Updated**: [Date]
```

---

## Usage Instructions

1. Create `.claude/` folder in your project root
2. Save this as `.claude/CLAUDE.md`
3. Replace all `[placeholders]` with actual values
4. Remove sections you don't need
5. Add project-specific sections as needed

Claude Code automatically reads this file and uses it for context.
