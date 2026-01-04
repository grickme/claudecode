---
layout: default
title: Secret Manager
---

# Google Secret Manager

Secure storage for API keys, passwords, and other sensitive configuration.

## Create Secrets

```bash
# Create secret from value
echo -n "my-api-key-value" | gcloud secrets create GEMINI_API_KEY \
  --data-file=- \
  --project PROJECT_ID

# Create secret from file
gcloud secrets create SERVICE_ACCOUNT_KEY \
  --data-file=./service-account.json \
  --project PROJECT_ID

# Create empty secret (add version later)
gcloud secrets create MY_SECRET --project PROJECT_ID
```

## Manage Versions

```bash
# Add new version
echo -n "new-value" | gcloud secrets versions add MY_SECRET \
  --data-file=- \
  --project PROJECT_ID

# List versions
gcloud secrets versions list MY_SECRET --project PROJECT_ID

# Disable old version
gcloud secrets versions disable 1 --secret=MY_SECRET --project PROJECT_ID

# Destroy version (permanent)
gcloud secrets versions destroy 1 --secret=MY_SECRET --project PROJECT_ID
```

## Access Secrets

### CLI

```bash
# Get latest version
gcloud secrets versions access latest --secret=MY_SECRET --project PROJECT_ID

# Get specific version
gcloud secrets versions access 2 --secret=MY_SECRET --project PROJECT_ID
```

### Node.js SDK

```typescript
// lib/secrets.ts
import { SecretManagerServiceClient } from '@google-cloud/secret-manager';

const client = new SecretManagerServiceClient();

export async function getSecret(secretName: string): Promise<string> {
  const projectId = process.env.GCP_PROJECT_ID;
  const name = `projects/${projectId}/secrets/${secretName}/versions/latest`;

  const [version] = await client.accessSecretVersion({ name });
  const payload = version.payload?.data?.toString();

  if (!payload) {
    throw new Error(`Secret ${secretName} not found or empty`);
  }

  return payload;
}

// Cache secrets to avoid repeated API calls
const secretCache = new Map<string, string>();

export async function getCachedSecret(secretName: string): Promise<string> {
  if (secretCache.has(secretName)) {
    return secretCache.get(secretName)!;
  }

  const value = await getSecret(secretName);
  secretCache.set(secretName, value);
  return value;
}
```

### Usage in Application

```typescript
// lib/gemini.ts
import { getCachedSecret } from './secrets';

let apiKey: string | null = null;

async function getGeminiApiKey(): Promise<string> {
  if (apiKey) return apiKey;

  // Try environment variable first (local dev)
  if (process.env.GEMINI_API_KEY) {
    apiKey = process.env.GEMINI_API_KEY;
    return apiKey;
  }

  // Fall back to Secret Manager (production)
  apiKey = await getCachedSecret('GEMINI_API_KEY');
  return apiKey;
}

export async function callGemini(prompt: string) {
  const key = await getGeminiApiKey();
  // Use key...
}
```

## Cloud Run Integration

### Using --set-secrets flag

```bash
gcloud run deploy my-service \
  --image gcr.io/PROJECT_ID/my-service:latest \
  --project PROJECT_ID \
  --region us-west1 \
  --set-secrets "GEMINI_API_KEY=gemini-key:latest,RESEND_API_KEY=resend-key:latest"
```

### As Environment Variables

```bash
gcloud run deploy my-service \
  --image gcr.io/PROJECT_ID/my-service:latest \
  --project PROJECT_ID \
  --region us-west1 \
  --update-secrets "GEMINI_API_KEY=gemini-key:latest"
```

### As Mounted Files

```bash
gcloud run deploy my-service \
  --image gcr.io/PROJECT_ID/my-service:latest \
  --project PROJECT_ID \
  --region us-west1 \
  --update-secrets "/secrets/service-account.json=service-account-key:latest"
```

## IAM Permissions

```bash
# Grant access to service account
gcloud secrets add-iam-policy-binding MY_SECRET \
  --project PROJECT_ID \
  --member="serviceAccount:my-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# Grant access to Cloud Run service identity
gcloud secrets add-iam-policy-binding MY_SECRET \
  --project PROJECT_ID \
  --member="serviceAccount:PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

## Best Practices

### Naming Convention

```
# Format: SERVICE_SECRETTYPE
GEMINI_API_KEY
RESEND_API_KEY
FIREBASE_ADMIN_KEY
STRIPE_SECRET_KEY
DATABASE_PASSWORD
```

### Local Development

Create `.env.local` (never commit):

```bash
# Development secrets
GEMINI_API_KEY=AIza...
RESEND_API_KEY=re_...
```

Create `.env.example` (commit this):

```bash
# Copy to .env.local and fill in values
GEMINI_API_KEY=
RESEND_API_KEY=
```

### Secret Rotation Pattern

```typescript
// Support multiple secret versions during rotation
async function getApiKey(): Promise<string> {
  try {
    // Try latest first
    return await getSecret('API_KEY');
  } catch (error) {
    // Fall back to previous version during rotation
    return await getSecretVersion('API_KEY', 'previous');
  }
}
```

## Complete Example

```typescript
// lib/config.ts
import { SecretManagerServiceClient } from '@google-cloud/secret-manager';

interface AppConfig {
  geminiApiKey: string;
  resendApiKey: string;
  firebaseAdminKey: object;
}

let config: AppConfig | null = null;

export async function getConfig(): Promise<AppConfig> {
  if (config) return config;

  const isProduction = process.env.NODE_ENV === 'production';

  if (isProduction) {
    const client = new SecretManagerServiceClient();
    const projectId = process.env.GCP_PROJECT_ID;

    const [geminiSecret] = await client.accessSecretVersion({
      name: `projects/${projectId}/secrets/GEMINI_API_KEY/versions/latest`,
    });

    const [resendSecret] = await client.accessSecretVersion({
      name: `projects/${projectId}/secrets/RESEND_API_KEY/versions/latest`,
    });

    const [firebaseSecret] = await client.accessSecretVersion({
      name: `projects/${projectId}/secrets/FIREBASE_ADMIN_KEY/versions/latest`,
    });

    config = {
      geminiApiKey: geminiSecret.payload?.data?.toString() || '',
      resendApiKey: resendSecret.payload?.data?.toString() || '',
      firebaseAdminKey: JSON.parse(firebaseSecret.payload?.data?.toString() || '{}'),
    };
  } else {
    // Local development - use environment variables
    config = {
      geminiApiKey: process.env.GEMINI_API_KEY || '',
      resendApiKey: process.env.RESEND_API_KEY || '',
      firebaseAdminKey: JSON.parse(process.env.FIREBASE_ADMIN_KEY || '{}'),
    };
  }

  return config;
}
```

## Audit Logging

```bash
# View access logs
gcloud logging read "resource.type=secret_version AND protoPayload.methodName=AccessSecretVersion" \
  --project PROJECT_ID \
  --limit 50
```

---

[← Cloud Storage](./gcs.md) | [Back to Infrastructure](./index.md)
