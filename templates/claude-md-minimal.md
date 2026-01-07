# Project CLAUDE.md - Minimal Template

Copy this to your project's `.claude/CLAUDE.md` and customize.

---

```markdown
# [Project Name]

## Tech Stack Reference

Follow guidelines from: https://grick.me/

Specific guides when needed:
- Firestore: https://grick.me/infrastructure/firestore
- Cloud Storage: https://grick.me/infrastructure/gcs
- Gemini AI: https://grick.me/ai/gemini
- Auth: https://grick.me/auth/firebase-auth
- API Routes: https://grick.me/backend/nextjs-api
- API Protection: https://grick.me/security/api-protection
- Security: https://grick.me/security/
- Troubleshooting: https://grick.me/troubleshooting

## Project Overview

- **Name**: [Your project name]
- **Type**: Web application
- **GCP Project**: [project-id]
- **Region**: us-west1

## Stack

- Next.js 14+ (App Router)
- TypeScript
- Tailwind CSS + shadcn/ui
- Firebase Auth
- Firestore
- Cloud Run
- Gemini AI

## Key Commands

```bash
# Development
npm run dev

# Build
npm run build

# Deploy (ALWAYS use --project)
gcloud builds submit --project [PROJECT_ID]
gcloud run deploy [SERVICE] --project [PROJECT_ID] --region us-west1
```

## Environment Variables

Required in `.env.local`:
- `NEXT_PUBLIC_FIREBASE_API_KEY`
- `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN`
- `NEXT_PUBLIC_FIREBASE_PROJECT_ID`
- `GEMINI_API_KEY`
- `RESEND_API_KEY`

## Project Structure

```
app/
  layout.tsx
  page.tsx
  api/
components/
lib/
  firebase.ts
  firebase-admin.ts
```

## Notes

[Add project-specific notes here]
```

---

## Usage

1. Create `.claude/` folder in project root
2. Save as `.claude/CLAUDE.md`
3. Customize the sections
4. Claude Code will read this automatically
