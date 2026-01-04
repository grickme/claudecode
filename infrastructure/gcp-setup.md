---
layout: default
title: GCP Project Setup
---

# Google Cloud Platform Setup

Complete guide for setting up a GCP project for web application development.

## Create Project

```bash
# Create new project
gcloud projects create PROJECT_ID --name="My Web App"

# List existing projects
gcloud projects list

# Set as active project (for convenience, but always use --project flag)
gcloud config set project PROJECT_ID
```

## Billing

```bash
# List billing accounts
gcloud billing accounts list

# Link billing to project
gcloud billing projects link PROJECT_ID --billing-account=BILLING_ACCOUNT_ID

# Verify billing is enabled
gcloud billing projects describe PROJECT_ID
```

## Enable APIs

```bash
# Enable all commonly needed APIs at once
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  firestore.googleapis.com \
  storage.googleapis.com \
  secretmanager.googleapis.com \
  aiplatform.googleapis.com \
  compute.googleapis.com \
  --project PROJECT_ID

# Check enabled services
gcloud services list --enabled --project PROJECT_ID
```

## Service Accounts

```bash
# Create service account
gcloud iam service-accounts create app-sa \
  --display-name="Application Service Account" \
  --project PROJECT_ID

# Grant roles
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:app-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/datastore.user"

gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:app-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:app-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# Create key for local development
gcloud iam service-accounts keys create ./service-account-key.json \
  --iam-account=app-sa@PROJECT_ID.iam.gserviceaccount.com
```

## Common Roles Reference

| Role | Purpose |
|------|---------|
| `roles/datastore.user` | Firestore read/write |
| `roles/storage.objectAdmin` | GCS full access |
| `roles/storage.objectViewer` | GCS read-only |
| `roles/secretmanager.secretAccessor` | Read secrets |
| `roles/run.invoker` | Invoke Cloud Run services |
| `roles/aiplatform.user` | Use Vertex AI |

## CRITICAL: Always Use --project Flag

**This is the most important rule when working with GCP.**

### The Problem

When you have multiple terminal windows, Claude Code sessions, or scripts running:
- Each can have a different `gcloud config` active project
- Running `gcloud config set project` in one terminal doesn't affect others
- Copy-pasting commands between projects can deploy to the wrong environment
- **A command without `--project` uses whatever project happens to be active**

### The Solution

**ALWAYS include `--project PROJECT_ID` in EVERY gcloud command:**

```bash
# CORRECT - Always specify project explicitly
gcloud run deploy my-service --project my-prod-project --region us-west1
gcloud builds submit --project my-prod-project --tag gcr.io/my-prod-project/app
gcloud firestore indexes create --project my-prod-project index.yaml
gcloud secrets versions access latest --secret=API_KEY --project my-prod-project

# WRONG - Relies on active config (dangerous!)
gcloud run deploy my-service --region us-west1
gcloud builds submit --tag gcr.io/my-prod-project/app
```

### Real-World Disaster Scenarios

| Scenario | What Happens |
|----------|--------------|
| Deploy without `--project` | Production app deployed to test project (or vice versa) |
| Build without `--project` | Container built in wrong project, deploy fails |
| Secret access without `--project` | Wrong credentials loaded, app crashes |
| Database query without `--project` | Wrong data modified or deleted |

### Verify Before Executing

```bash
# Check what project would be used (if you forget --project)
gcloud config get-value project

# List all your projects
gcloud projects list

# See full current config
gcloud config list
```

### Best Practice: Use Environment Variables

```bash
# Set at start of session or in .bashrc/.zshrc
export PROJECT_ID="my-project-id"

# Then use in commands
gcloud run deploy my-service --project $PROJECT_ID --region us-west1
gcloud builds submit --project $PROJECT_ID --tag gcr.io/$PROJECT_ID/app
```

### For Claude Code Users

Add this to your project's `CLAUDE.md`:

```markdown
## GCP Project
- **Project ID**: your-project-id
- **CRITICAL**: Always use `--project your-project-id` in ALL gcloud commands
```

This ensures Claude Code always specifies the correct project.

## Environment Setup Script

Save as `setup-gcp.sh`:

```bash
#!/bin/bash
PROJECT_ID="your-project-id"
BILLING_ACCOUNT="your-billing-account"
REGION="us-west1"

# Create project
gcloud projects create $PROJECT_ID --name="My Web App"

# Link billing
gcloud billing projects link $PROJECT_ID --billing-account=$BILLING_ACCOUNT

# Enable APIs
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  firestore.googleapis.com \
  storage.googleapis.com \
  secretmanager.googleapis.com \
  aiplatform.googleapis.com \
  --project $PROJECT_ID

# Create Firestore database
gcloud firestore databases create --location=$REGION --project $PROJECT_ID

# Create storage bucket
gsutil mb -l $REGION -p $PROJECT_ID gs://${PROJECT_ID}-storage

echo "GCP project $PROJECT_ID setup complete!"
```

## Regions

| Region | Location | Use Case |
|--------|----------|----------|
| `us-west1` | Oregon | Default US |
| `us-central1` | Iowa | Vertex AI |
| `europe-west1` | Belgium | EU data |
| `europe-west3` | Frankfurt | EU (Germany) |
| `asia-northeast1` | Tokyo | Asia |

## Cost Management

```bash
# Set budget alert
gcloud billing budgets create \
  --billing-account=BILLING_ACCOUNT \
  --display-name="Monthly Budget" \
  --budget-amount=100USD \
  --threshold-rule=percent=50 \
  --threshold-rule=percent=90

# View current costs
gcloud billing accounts describe BILLING_ACCOUNT
```

---

[← Back to Infrastructure](./index.md) | [Cloud Run →](./cloud-run.md)
