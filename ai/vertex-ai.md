---
layout: default
title: Vertex AI
---

# Vertex AI

Production-grade AI platform with no rate limits, enterprise features, and GCP billing.

## When to Use Vertex AI vs AI Studio

| Feature | AI Studio (Free Tier) | Vertex AI |
|---------|----------------------|-----------|
| Rate limits | Yes (60 req/min) | No |
| Billing | API key | GCP project |
| Authentication | API key | OAuth/ADC |
| SLA | None | Enterprise |
| Use case | Development, prototypes | Production |

## Setup

```bash
# Enable API
gcloud services enable aiplatform.googleapis.com --project PROJECT_ID

# Grant permissions to service account
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SA@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"
```

## Using @google-cloud/vertexai SDK

```bash
npm install @google-cloud/vertexai
```

```typescript
// lib/vertex-ai.ts
import { VertexAI } from '@google-cloud/vertexai';

const vertexAI = new VertexAI({
  project: process.env.GCP_PROJECT_ID!,
  location: 'us-central1',
});

const model = vertexAI.preview.getGenerativeModel({
  model: 'gemini-2.5-flash',
});

export async function generate(prompt: string): Promise<string> {
  const result = await model.generateContent({
    contents: [{ role: 'user', parts: [{ text: prompt }] }],
  });

  const response = await result.response;
  return response.candidates?.[0]?.content?.parts?.[0]?.text || '';
}
```

## Streaming Response

```typescript
export async function generateStream(prompt: string): AsyncGenerator<string> {
  const result = await model.generateContentStream({
    contents: [{ role: 'user', parts: [{ text: prompt }] }],
  });

  for await (const chunk of result.stream) {
    const text = chunk.candidates?.[0]?.content?.parts?.[0]?.text;
    if (text) yield text;
  }
}

// Usage
for await (const chunk of generateStream('Tell me a story')) {
  process.stdout.write(chunk);
}
```

## Chat Sessions

```typescript
const chat = model.startChat({
  history: [
    { role: 'user', parts: [{ text: 'Hello!' }] },
    { role: 'model', parts: [{ text: 'Hi! How can I help?' }] },
  ],
});

const result = await chat.sendMessage('What can you do?');
const response = await result.response;
console.log(response.candidates?.[0]?.content?.parts?.[0]?.text);
```

## Vision with Vertex AI

```typescript
import { VertexAI, FileDataPart, InlineDataPart } from '@google-cloud/vertexai';

// From GCS
const gcsFile: FileDataPart = {
  fileData: {
    mimeType: 'image/jpeg',
    fileUri: 'gs://my-bucket/image.jpg',
  },
};

// From base64
const inlineImage: InlineDataPart = {
  inlineData: {
    mimeType: 'image/jpeg',
    data: base64String,
  },
};

const result = await model.generateContent({
  contents: [{
    role: 'user',
    parts: [
      { text: 'Describe this image' },
      gcsFile,
    ],
  }],
});
```

## REST API Alternative

If you prefer REST API with OAuth:

```typescript
import { GoogleAuth } from 'google-auth-library';

const auth = new GoogleAuth({
  scopes: ['https://www.googleapis.com/auth/cloud-platform'],
});

async function callVertexAI(prompt: string): Promise<string> {
  const client = await auth.getClient();
  const accessToken = await client.getAccessToken();

  const projectId = process.env.GCP_PROJECT_ID;
  const location = 'us-central1';
  const model = 'gemini-2.5-flash';

  const endpoint = `https://${location}-aiplatform.googleapis.com/v1/projects/${projectId}/locations/${location}/publishers/google/models/${model}:generateContent`;

  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken.token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.7,
        maxOutputTokens: 2048,
      },
    }),
  });

  const result = await response.json();
  return result.candidates?.[0]?.content?.parts?.[0]?.text || '';
}
```

## Configuration Options

```typescript
const model = vertexAI.preview.getGenerativeModel({
  model: 'gemini-2.5-flash',
  generationConfig: {
    temperature: 0.7,
    topP: 0.95,
    topK: 40,
    maxOutputTokens: 8192,
  },
  safetySettings: [
    {
      category: 'HARM_CATEGORY_HARASSMENT',
      threshold: 'BLOCK_MEDIUM_AND_ABOVE',
    },
  ],
});
```

## Environment Variables

```bash
# For local development
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
GCP_PROJECT_ID=your-project-id

# For Cloud Run - uses Application Default Credentials automatically
GCP_PROJECT_ID=your-project-id
```

## Error Handling

```typescript
import { GoogleApiError } from '@google-cloud/vertexai';

async function safeGenerate(prompt: string): Promise<string | null> {
  try {
    return await generate(prompt);
  } catch (error) {
    if (error instanceof GoogleApiError) {
      console.error(`API Error: ${error.code} - ${error.message}`);

      if (error.code === 429) {
        // Rate limited (shouldn't happen with Vertex AI)
        await new Promise(r => setTimeout(r, 5000));
        return safeGenerate(prompt);
      }
    }
    throw error;
  }
}
```

## Batch Predictions

For large-scale processing:

```typescript
// Create batch job
const batchPredictionJob = await vertexAI.batchPrediction.create({
  displayName: 'my-batch-job',
  model: `projects/${projectId}/locations/${location}/publishers/google/models/gemini-2.5-flash`,
  inputConfig: {
    gcsSource: {
      uris: ['gs://my-bucket/input.jsonl'],
    },
  },
  outputConfig: {
    gcsDestination: {
      outputUriPrefix: 'gs://my-bucket/output/',
    },
  },
});
```

## Regions

| Region | Location | Notes |
|--------|----------|-------|
| `us-central1` | Iowa | Default, all models |
| `us-east4` | Virginia | Lower latency East Coast |
| `europe-west4` | Netherlands | EU data residency |
| `asia-southeast1` | Singapore | Asia Pacific |

## Pricing

Vertex AI uses pay-per-use GCP billing:
- Gemini 2.5 Flash: ~$0.075/1M input tokens, ~$0.30/1M output tokens
- No minimum, scales with usage

---

[← Gemini](./gemini.md) | [Embeddings →](./embeddings.md)
