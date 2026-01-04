---
layout: default
title: Cloud Run
---

# Google Cloud Run

Container-based serverless hosting for web applications.

## Dockerfile (Next.js)

```dockerfile
FROM node:20-alpine AS base

# Install dependencies
FROM base AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Build application
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Set build-time environment variables if needed
# ARG NEXT_PUBLIC_API_URL
# ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL

RUN npm run build

# Production image
FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy built assets
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

USER nextjs

# Cloud Run uses PORT environment variable
EXPOSE 8080
ENV PORT=8080
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
```

## next.config.js

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',  // Required for Docker
  experimental: {
    outputFileTracingRoot: undefined,
  },
};

module.exports = nextConfig;
```

## Manual Deployment

```bash
# Build and push image
gcloud builds submit --tag gcr.io/PROJECT_ID/my-service --project PROJECT_ID

# Deploy to Cloud Run
gcloud run deploy my-service \
  --image gcr.io/PROJECT_ID/my-service:latest \
  --project PROJECT_ID \
  --platform managed \
  --region us-west1 \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 10 \
  --set-env-vars "NODE_ENV=production"
```

## cloudbuild.yaml (CI/CD)

```yaml
steps:
  # Build Docker image
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'build'
      - '-t'
      - 'gcr.io/$PROJECT_ID/$_SERVICE:$COMMIT_SHA'
      - '-t'
      - 'gcr.io/$PROJECT_ID/$_SERVICE:latest'
      - '.'

  # Push to Container Registry
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/$_SERVICE:$COMMIT_SHA']

  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/$_SERVICE:latest']

  # Deploy to Cloud Run
  - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
    entrypoint: gcloud
    args:
      - 'run'
      - 'deploy'
      - '$_SERVICE'
      - '--image'
      - 'gcr.io/$PROJECT_ID/$_SERVICE:$COMMIT_SHA'
      - '--region'
      - '$_REGION'
      - '--platform'
      - 'managed'
      - '--allow-unauthenticated'
      - '--memory'
      - '512Mi'

substitutions:
  _SERVICE: my-service
  _REGION: us-west1

options:
  logging: CLOUD_LOGGING_ONLY
```

## Environment Variables

```bash
# Set environment variables
gcloud run deploy my-service \
  --image gcr.io/PROJECT_ID/my-service:latest \
  --project PROJECT_ID \
  --region us-west1 \
  --set-env-vars "GEMINI_API_KEY=xxx,RESEND_API_KEY=xxx"

# Or use Secret Manager (recommended)
gcloud run deploy my-service \
  --image gcr.io/PROJECT_ID/my-service:latest \
  --project PROJECT_ID \
  --region us-west1 \
  --set-secrets "GEMINI_API_KEY=gemini-key:latest,RESEND_API_KEY=resend-key:latest"
```

## Custom Domain

```bash
# Map custom domain
gcloud run domain-mappings create \
  --service my-service \
  --domain app.yourdomain.com \
  --project PROJECT_ID \
  --region us-west1

# Get DNS records to add
gcloud run domain-mappings describe \
  --domain app.yourdomain.com \
  --project PROJECT_ID \
  --region us-west1
```

## View Logs

```bash
# Stream logs
gcloud run services logs tail my-service \
  --project PROJECT_ID \
  --region us-west1

# Read recent logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=my-service" \
  --project PROJECT_ID \
  --limit 50
```

## Service Configuration

| Setting | Recommended | Notes |
|---------|-------------|-------|
| Memory | 512Mi - 1Gi | Increase for heavy processing |
| CPU | 1 | Increase for compute-intensive |
| Min instances | 0 | Set to 1 to avoid cold starts |
| Max instances | 10-100 | Based on expected traffic |
| Timeout | 300s | Max 3600s for background jobs |
| Concurrency | 80 | Requests per instance |

## Health Checks

Add to your app:

```typescript
// app/api/health/route.ts
import { NextResponse } from 'next/server';

export async function GET() {
  return NextResponse.json({ status: 'healthy', timestamp: new Date().toISOString() });
}
```

Configure in Cloud Run:
```bash
gcloud run deploy my-service \
  --image gcr.io/PROJECT_ID/my-service:latest \
  --project PROJECT_ID \
  --region us-west1 \
  --http2 \
  --startup-cpu-boost
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Cold start slow | Set `--min-instances 1` |
| Container crashes | Check logs, increase memory |
| 503 errors | Check health endpoint, increase timeout |
| Build fails | Check Dockerfile, ensure all files copied |

---

[← GCP Setup](./gcp-setup.md) | [Firestore →](./firestore.md)
