---
layout: default
title: Infrastructure
---

# Infrastructure Guides

Google Cloud Platform setup and services for web applications.

## Guides

| Guide | Description |
|-------|-------------|
| [GitHub Setup](./github.md) | Account, repos, SSH keys for Claude Code |
| [GCP Setup](./gcp-setup.md) | Project creation, billing, APIs, service accounts |
| [Cloud Run](./cloud-run.md) | Container hosting, Dockerfile, deployment |
| [Firestore](./firestore.md) | NoSQL database, queries, security rules |
| [Cloud Storage](./gcs.md) | File storage, signed URLs, uploads, metadata |
| [Secret Manager](./secrets.md) | API keys, passwords, secure config |

## Quick Setup Checklist

```bash
PROJECT_ID="my-project"

# 1. Create project
gcloud projects create $PROJECT_ID

# 2. Enable billing
gcloud billing projects link $PROJECT_ID --billing-account=BILLING_ID

# 3. Enable APIs
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  firestore.googleapis.com \
  storage.googleapis.com \
  secretmanager.googleapis.com \
  --project $PROJECT_ID

# 4. Create Firestore
gcloud firestore databases create --location=us-west1 --project $PROJECT_ID

# 5. Create storage bucket
gsutil mb -l us-west1 -p $PROJECT_ID gs://${PROJECT_ID}-storage

# 6. Add secrets
echo -n "your-key" | gcloud secrets create GEMINI_API_KEY --data-file=- --project $PROJECT_ID
```

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Cloud Run                             │
│                 (Next.js Container)                      │
└────────────┬──────────────┬──────────────┬──────────────┘
             │              │              │
     ┌───────┴───┐   ┌──────┴──────┐   ┌──┴───────────┐
     │ Firestore │   │ Cloud Storage│   │Secret Manager│
     │ (Database)│   │ (Files)      │   │ (API Keys)   │
     └───────────┘   └─────────────┘   └──────────────┘
```

---

[← Back to Home](../)
