---
layout: default
title: Troubleshooting
---

# Troubleshooting

Common errors and how to fix them.

---

## Build & Install Errors

### "Module not found" or "Cannot find module"

```bash
npm install
```

If a specific package is missing:
```bash
npm install package-name
```

### "npm install" fails

```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install
```

### TypeScript errors

```bash
# See all type errors
npm run type-check

# Common fixes:
# - Add missing types: npm install @types/package-name
# - Check import paths are correct
# - Ensure function parameters have correct types
```

---

## Deployment Errors

### "Cloud Build failed"

Check the build logs:
```bash
gcloud builds list --project PROJECT_ID
gcloud builds log BUILD_ID --project PROJECT_ID
```

Common causes:
- Dockerfile syntax error
- Missing dependencies in package.json
- Build runs out of memory (increase in cloudbuild.yaml)

### "Permission denied"

Re-authenticate:
```bash
gcloud auth login
gcloud auth application-default login
```

### "API not enabled"

Enable the required API:
```bash
gcloud services enable SERVICE_NAME.googleapis.com --project PROJECT_ID
```

Common services:
- `run.googleapis.com` - Cloud Run
- `cloudbuild.googleapis.com` - Cloud Build
- `firestore.googleapis.com` - Firestore
- `secretmanager.googleapis.com` - Secret Manager

### "Billing account not linked"

```bash
gcloud billing projects link PROJECT_ID --billing-account=BILLING_ACCOUNT_ID
```

---

## Runtime Errors

### "500 Internal Server Error"

Check Cloud Run logs:
```bash
gcloud run services logs read SERVICE_NAME --project PROJECT_ID --region REGION
```

Or in the console: https://console.cloud.google.com/run

Common causes:
- Missing environment variable
- Database connection failed
- Unhandled exception in code

### "CORS error"

Add CORS headers to your API route:

```typescript
export async function GET() {
  return new Response(JSON.stringify({ data: '...' }), {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Content-Type': 'application/json',
    },
  });
}

// Handle preflight requests
export async function OPTIONS() {
  return new Response(null, {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  });
}
```

### "Unauthorized" or "401 error"

- Check Firebase token is valid and not expired
- Verify token is sent in Authorization header: `Bearer TOKEN`
- Check Firebase project ID matches

---

## Authentication Errors

### "Firebase: Error (auth/invalid-api-key)"

- Check `NEXT_PUBLIC_FIREBASE_API_KEY` is set correctly
- Verify the API key in Firebase Console → Project Settings

### "Firebase: Error (auth/unauthorized-domain)"

Add your domain to Firebase:
1. Go to Firebase Console → Authentication → Settings
2. Add your domain to "Authorized domains"

### Token verification fails on server

```typescript
// Make sure Firebase Admin is initialized
import admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp();
}

// Verify token
const decoded = await admin.auth().verifyIdToken(token);
```

---

## Database Errors

### "PERMISSION_DENIED" from Firestore

Check your Firestore security rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

Deploy rules:
```bash
firebase deploy --only firestore:rules --project PROJECT_ID
```

### "Could not reach Cloud Firestore backend"

- Check internet connection
- Verify `GOOGLE_CLOUD_PROJECT` environment variable
- Check Firestore is enabled in your project

---

## "Works Locally, Not in Production"

### Environment variables not set

Check Cloud Run has the variables:
```bash
gcloud run services describe SERVICE_NAME --project PROJECT_ID --region REGION
```

Set missing variables:
```bash
gcloud run services update SERVICE_NAME \
  --set-env-vars "VAR_NAME=value" \
  --project PROJECT_ID \
  --region REGION
```

### Secrets not accessible

Grant access to secrets:
```bash
PROJECT_NUMBER=$(gcloud projects describe PROJECT_ID --format='value(projectNumber)')

gcloud secrets add-iam-policy-binding SECRET_NAME \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --project PROJECT_ID
```

### Different Node.js version

Check your local version matches production:
```bash
node --version
```

Specify in package.json:
```json
{
  "engines": {
    "node": "20.x"
  }
}
```

---

## GCP Quota & Billing Errors

### "Quota exceeded"

Check your quotas:
```bash
gcloud compute project-info describe --project PROJECT_ID
```

Request quota increase in Console → IAM & Admin → Quotas

### "Billing must be enabled"

Link a billing account:
```bash
gcloud billing accounts list
gcloud billing projects link PROJECT_ID --billing-account=ACCOUNT_ID
```

---

## Getting Help

### 1. Check logs first

```bash
# Cloud Run logs
gcloud run services logs read SERVICE --project PROJECT_ID --region REGION

# Cloud Build logs
gcloud builds list --project PROJECT_ID
```

### 2. Search the exact error message

Copy the error message and search:
- Google
- Stack Overflow
- GitHub Issues

### 3. Ask Claude

Paste the full error message and relevant code. Claude can help diagnose.

### 4. Check service status

- GCP Status: https://status.cloud.google.com/
- Firebase Status: https://status.firebase.google.com/

---

## Quick Reference

| Problem | First thing to try |
|---------|-------------------|
| Build fails | `npm install` then check logs |
| Deploy fails | `gcloud auth login` |
| 500 error | Check Cloud Run logs |
| CORS error | Add CORS headers |
| Auth fails | Check API keys and tokens |
| Firestore denied | Check security rules |
| Works local, not prod | Check env vars in Cloud Run |

---

[← Back to Home](./)
