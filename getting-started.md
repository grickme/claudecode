---
layout: default
title: Getting Started
---

# Getting Started

This guide helps Claude Code set up a new project from scratch.

> **By using this guide, you agree to the [Disclaimer](DISCLAIMER.txt).** Provided "as is" without warranty or support. You are responsible for all costs and security.

## Instructions for Claude Code

**IMPORTANT: Claude should EXECUTE these commands directly, not just show them to the user.**

When a user references this guide:
1. Run the commands yourself using the Bash tool
2. Only pause when user input is needed (credentials, browser auth)
3. Create files directly using the Write tool
4. Verify each step succeeded before proceeding

---

### Step 0: Understand the Project

**CRITICAL: You MUST ask ALL 10 questions below before proceeding to Step 1.**

Present all questions as a numbered list in a SINGLE message. Wait for the user to answer ALL of them before continuing. Do NOT skip any questions. Do NOT proceed until you have answers to all 10.

**Ask the user:**

1. **What does your app do in one sentence?**
   - Example: "A platform where dog owners can find and book pet sitters"

2. **Do users need to log in or create accounts?**
   - Yes → Firebase Auth needed
   - No → Public site only

3. **What's the main thing users will do?**
   - Browse content, search, book, post, upload, buy, etc.

4. **What kind of data will the app store?**
   - User profiles, products, bookings, documents, images, etc.
   - This determines Firestore collections and Cloud Storage needs

5. **Do you want AI features?**
   - **Chat/Assistant** → Gemini conversational AI
   - **Search** → Semantic search with embeddings
   - **Document processing** → PDF extraction, summarization
   - **Content generation** → Descriptions, emails, reports
   - None → Skip AI setup

6. **Do you have a brand name and preferred colors?**
   - For styling and theme setup

7. **Any website you'd like yours to look or work like?**
   - Reference for design and UX patterns

8. **Do you need an admin area to manage content?**
   - Dashboard to add/edit/delete data

9. **Do you already have a domain name?**
   - Yes → Custom domain setup later
   - No → Can use Cloud Run URL or buy one

10. **What's the ONE most important feature to build first?**
    - Keeps scope focused, prevents over-building

**STOP: Do not proceed until the user has answered all 10 questions above.**

---

### Step 1: Gather Technical Details

Ask the user for:
1. **Project name** (e.g., "My App")
2. **Project ID** for GCP (lowercase, hyphens only, e.g., `my-app-prod`)
3. **Description** (one sentence - use their answer from Step 0)
4. **Region preference** (default: `us-west1`, EU: `europe-west3`)
5. **GitHub username** (for repo creation) - or "skip" if they don't use GitHub

---

### Step 2: Create CLAUDE.md

**Execute:** Create `.claude/CLAUDE.md` in their project root:

```markdown
# [Project Name] - Claude Code Configuration

## Project Info
- **Name**: [Project Name]
- **Description**: [Description]
- **GCP Project ID**: [project-id]
- **Region**: [region]
- **GitHub**: github.com/[username]/[project-id]

## Guidelines for Claude

Follow these guides when building this project:

### General Reference
- **Full Guide**: https://grick.me/
- **Quick Reference**: https://grick.me/index

### When Working On:
- **GCP/Infrastructure**: Fetch https://grick.me/infrastructure/
- **Gemini AI**: Fetch https://grick.me/ai/gemini
- **Firestore**: Fetch https://grick.me/infrastructure/firestore
- **Cloud Storage**: Fetch https://grick.me/infrastructure/gcs
- **Authentication**: Fetch https://grick.me/auth/firebase-auth
- **API Routes**: Fetch https://grick.me/backend/nextjs-api
- **Email**: Fetch https://grick.me/email/

### Security (IMPORTANT)
ALWAYS follow: https://grick.me/security/

Before EVERY git commit:
- Check for leaked secrets (API keys, passwords, tokens)
- Ensure .env files are in .gitignore
- Never hardcode credentials - use process.env

## CRITICAL: Always Use --project Flag
Every gcloud command MUST include `--project [project-id]`

## Quick Commands

### Deploy
gcloud builds submit --project [project-id] --tag gcr.io/[project-id]/app
gcloud run deploy app --project [project-id] --region [region] --image gcr.io/[project-id]/app:latest --allow-unauthenticated

### View Logs
gcloud run services logs tail app --project [project-id] --region [region]

## Environment Variables
NEXT_PUBLIC_FIREBASE_API_KEY=
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=[project-id].firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=[project-id]
GEMINI_API_KEY=

## Firestore Collections
| Collection | Description |
|------------|-------------|
| users | User profiles |

## Notes
[Add project-specific notes here]
```

---

### Step 3: GitHub Repository Setup (Optional)

**If user said "skip" or doesn't have GitHub:** Skip to Step 4. Just initialize local git:
```bash
git init
```

---

**If user wants GitHub:**

```bash
# Check if gh CLI is installed
gh --version
```

If not installed, tell user: "Install GitHub CLI from https://cli.github.com"

```bash
# Check if authenticated
gh auth status
```

If not authenticated:
```bash
gh auth login
```
(Wait for user to complete browser auth)

**Create private repository:**
```bash
# Initialize git if needed
git init

# Create private repo on GitHub and push
gh repo create PROJECT_ID --private --source=. --push
```

If repo already exists, just add remote:
```bash
git remote add origin git@github.com:USERNAME/PROJECT_ID.git
git push -u origin main
```

---

### Step 4: Google Cloud Setup

**Execute these commands directly:**

#### 4a. Check gcloud CLI
```bash
gcloud --version
```
If not installed, tell user: "Install from https://cloud.google.com/sdk/docs/install"

#### 4b. Check Authentication
```bash
gcloud auth list
```
If no active account:
```bash
gcloud auth login
```
(Wait for user to complete browser auth)

#### 4c. Get Billing Account
```bash
gcloud billing accounts list
```
If empty, tell user: "Create billing account at https://console.cloud.google.com/billing first"

Note the ACCOUNT_ID from the output.

#### 4d. Create GCP Project
**Execute:**
```bash
gcloud projects create PROJECT_ID --name="Project Name"
```

**Execute:**
```bash
gcloud billing projects link PROJECT_ID --billing-account=BILLING_ACCOUNT_ID
```

#### 4e. Enable APIs
**Execute:**
```bash
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  firestore.googleapis.com \
  storage.googleapis.com \
  secretmanager.googleapis.com \
  aiplatform.googleapis.com \
  --project PROJECT_ID
```

#### 4f. Create Firestore Database
**Execute:**
```bash
gcloud firestore databases create --location=REGION --project PROJECT_ID
```

#### 4g. Create Storage Bucket
**Execute:**
```bash
gsutil mb -l REGION -p PROJECT_ID gs://PROJECT_ID-storage
```

---

### Step 5: Get API Keys

#### Gemini API Key
Tell user:
1. Go to https://aistudio.google.com/app/apikey
2. Click "Create API Key"
3. Select the GCP project: PROJECT_ID
4. Copy the key and paste it here

Once user provides key, store it:
```bash
echo -n "THE_API_KEY" | gcloud secrets create GEMINI_API_KEY --data-file=- --project PROJECT_ID
```

#### Firebase Setup (if using auth)
Tell user:
1. Go to https://console.firebase.google.com
2. Click "Add Project" → Select existing GCP project
3. Enable Authentication → Email/Password
4. Go to Project Settings → Your apps → Add web app
5. Copy the config values

---

### Step 6: Grant Secret Access to Cloud Run

**Execute:**
```bash
# Get project number
PROJECT_NUMBER=$(gcloud projects describe PROJECT_ID --format='value(projectNumber)')

# Grant access
gcloud secrets add-iam-policy-binding GEMINI_API_KEY \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --project PROJECT_ID
```

---

## Checklist for Claude

After setup, verify:

- [ ] `.claude/CLAUDE.md` created with project details
- [ ] GitHub repo created (private) - *skip if user chose no GitHub*
- [ ] Code pushed to GitHub - *skip if user chose no GitHub*
- [ ] gcloud authenticated
- [ ] Billing account linked
- [ ] GCP project created
- [ ] APIs enabled (run, build, firestore, storage, secrets, aiplatform)
- [ ] Firestore database created
- [ ] Storage bucket created
- [ ] Gemini API key stored in Secret Manager
- [ ] Secret access granted to Cloud Run

---

## Quick Verification Commands

Run these to verify setup:

```bash
# Verify GCP project
gcloud projects describe PROJECT_ID

# Verify APIs enabled
gcloud services list --enabled --project PROJECT_ID

# Verify Firestore
gcloud firestore databases list --project PROJECT_ID

# Verify Storage bucket
gsutil ls -p PROJECT_ID

# Verify secret exists
gcloud secrets list --project PROJECT_ID

# Verify GitHub repo
gh repo view USERNAME/PROJECT_ID
```

---

## Common Issues

| Issue | Solution |
|-------|----------|
| "Billing account not found" | User creates one at console.cloud.google.com/billing |
| "Permission denied" | Run `gcloud auth login` again |
| "API not enabled" | Run the `gcloud services enable` command |
| "Project ID already exists" | Choose different ID (globally unique) |
| "gh: command not found" | Install GitHub CLI from cli.github.com |
| "not authenticated" (gh) | Run `gh auth login` |

**For more errors, see the full [Troubleshooting Guide](./troubleshooting.md).**

---

## Cost Expectations

Free tier includes:
- **Cloud Run**: 2M requests/month
- **Firestore**: 1GB storage, 50K reads/day
- **Cloud Storage**: 5GB
- **Gemini API**: Free tier for development
- **GitHub**: Unlimited private repos

Typical development costs: **$0-5/month**

---

## Next Steps

After setup is complete:

1. **Run your app locally**: See [Local Development Guide](./backend/local-dev.md)
2. **Start building**: Claude will help you create pages, API routes, and features
3. **Deploy**: Use the deploy commands in your CLAUDE.md
4. **Troubleshooting**: If something breaks, see [Troubleshooting Guide](./troubleshooting.md)

---

## Optional: Custom Domain Setup

If user wants a custom domain for their Cloud Run service:

### Step 1: Buy a Domain

Recommend one of these registrars (easy DNS management):

| Registrar | Price (.com) | Notes |
|-----------|--------------|-------|
| [Cloudflare](https://www.cloudflare.com/products/registrar/) | ~$10/yr | At-cost pricing, best DNS, free SSL, DDoS protection |
| [Squarespace Domains](https://domains.squarespace.com/) | ~$12/yr | Simple UI, formerly Google Domains |
| [Hostinger](https://www.hostinger.com/domain-name-search) | ~$10/yr | Beginner-friendly, step-by-step DNS setup |

### Step 2: Configure DNS for Cloud Run

After deploying to Cloud Run, map your domain:

```bash
# Get your Cloud Run service URL
gcloud run services describe SERVICE_NAME --project PROJECT_ID --region REGION --format='value(status.url)'

# Map custom domain
gcloud run domain-mappings create --service SERVICE_NAME --domain yourdomain.com --project PROJECT_ID --region REGION
```

Then add DNS records at your registrar:

| Type | Host | Value |
|------|------|-------|
| A | @ | (IP from gcloud output) |
| AAAA | @ | (IPv6 from gcloud output) |
| CNAME | www | ghs.googlehosted.com |

### Step 3: Verify and Wait

```bash
# Check mapping status
gcloud run domain-mappings describe --domain yourdomain.com --project PROJECT_ID --region REGION
```

DNS propagation takes 15 minutes to 48 hours. SSL certificate is automatic.

---

[← Back to Home](./)
