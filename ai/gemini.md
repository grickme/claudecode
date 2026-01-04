---
layout: default
title: Gemini AI
---

# Google Gemini AI

Multimodal AI for chat, vision, structured output, and web grounding.

**Official Docs:** [ai.google.dev/gemini-api/docs](https://ai.google.dev/gemini-api/docs)

## Setup

1. Get API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Store in environment variable: `GEMINI_API_KEY`

## Models

| Model | Model ID | Context | Max Output | Best For |
|-------|----------|---------|------------|----------|
| **Gemini 3 Pro** | `gemini-3-pro-preview` | 1M | 65K | Most intelligent, state-of-the-art reasoning |
| **Gemini 3 Flash** | `gemini-3-flash-preview` | 1M | 65K | Fast, frontier-class at low cost |
| **Gemini 2.5 Pro** | `gemini-2.5-pro` | 1M | 65K | Powerful reasoning, complex coding |
| **Gemini 2.5 Flash** | `gemini-2.5-flash` | 1M | 65K | Balanced performance (recommended default) |
| **Gemini 2.5 Flash-Lite** | `gemini-2.5-flash-lite` | 1M | 65K | Fastest, most cost-efficient |

## Pricing (per 1M tokens, USD)

| Model | Input | Output | Notes |
|-------|-------|--------|-------|
| **Gemini 3 Pro** | $2.00 | $12.00 | $4.00/$18.00 for prompts >200K |
| **Gemini 3 Flash** | $0.50 | $3.00 | Audio input: $1.00 |
| **Gemini 2.5 Pro** | $1.25 | $10.00 | $2.50/$15.00 for prompts >200K |
| **Gemini 2.5 Flash** | $0.30 | $2.50 | Audio input: $1.00 |

*Batch API pricing is 50% cheaper. Free tier available for development.*

## Basic Chat

```typescript
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_MODEL = 'gemini-2.5-flash';

async function chat(prompt: string): Promise<string> {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{
          role: 'user',
          parts: [{ text: prompt }]
        }],
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 8192,
        }
      })
    }
  );

  if (!response.ok) {
    throw new Error(`Gemini API error: ${response.status}`);
  }

  const result = await response.json();
  return result.candidates?.[0]?.content?.parts?.[0]?.text || '';
}
```

## Multi-turn Conversation

```typescript
interface Message {
  role: 'user' | 'model';
  parts: { text: string }[];
}

async function chatWithHistory(messages: Message[], newMessage: string): Promise<string> {
  const contents = [
    ...messages,
    { role: 'user', parts: [{ text: newMessage }] }
  ];

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ contents })
    }
  );

  const result = await response.json();
  return result.candidates?.[0]?.content?.parts?.[0]?.text || '';
}
```

## System Instructions

```typescript
const response = await fetch(
  `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`,
  {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      systemInstruction: {
        parts: [{ text: 'You are a helpful assistant specializing in data analysis.' }]
      },
      contents: [{
        role: 'user',
        parts: [{ text: 'Analyze this data...' }]
      }]
    })
  }
);
```

## Structured Output with JSON Schema

Gemini can generate responses that strictly adhere to a JSON schema, ensuring predictable and parsable results.

### Basic JSON Output

```typescript
async function extractData(text: string): Promise<any> {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{
          parts: [{ text: `Extract information from: ${text}` }]
        }],
        generationConfig: {
          temperature: 0.1,
          responseMimeType: 'application/json'
        }
      })
    }
  );

  const result = await response.json();
  return JSON.parse(result.candidates?.[0]?.content?.parts?.[0]?.text || '{}');
}
```

### With JSON Schema (Type-Safe)

Define a schema to guarantee the exact structure of the response:

```typescript
// Define the JSON schema
const companySchema = {
  type: 'object',
  properties: {
    name: {
      type: 'string',
      description: 'Company name'
    },
    industry: {
      type: 'string',
      description: 'Primary industry sector'
    },
    founded: {
      type: 'integer',
      description: 'Year the company was founded'
    },
    employees: {
      type: 'integer',
      description: 'Number of employees'
    },
    isPublic: {
      type: 'boolean',
      description: 'Whether the company is publicly traded'
    },
    products: {
      type: 'array',
      items: { type: 'string' },
      description: 'List of main products or services'
    }
  },
  required: ['name', 'industry']
};

interface Company {
  name: string;
  industry: string;
  founded?: number;
  employees?: number;
  isPublic?: boolean;
  products?: string[];
}

async function extractCompanyInfo(text: string): Promise<Company> {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{
          parts: [{
            text: `Extract company information from this text:\n\n${text}`
          }]
        }],
        generationConfig: {
          temperature: 0.1,
          responseMimeType: 'application/json',
          responseSchema: companySchema
        }
      })
    }
  );

  const result = await response.json();
  const jsonText = result.candidates?.[0]?.content?.parts?.[0]?.text || '{}';
  return JSON.parse(jsonText);
}

// Usage
const company = await extractCompanyInfo(`
  Apple Inc. was founded in 1976 by Steve Jobs and Steve Wozniak.
  It's a publicly traded technology company with over 160,000 employees.
  They make the iPhone, iPad, Mac, and Apple Watch.
`);

// Result:
// {
//   name: "Apple Inc.",
//   industry: "Technology",
//   founded: 1976,
//   employees: 160000,
//   isPublic: true,
//   products: ["iPhone", "iPad", "Mac", "Apple Watch"]
// }
```

### Using Zod for Schema Generation (TypeScript)

```typescript
import { z } from 'zod';
import { zodToJsonSchema } from 'zod-to-json-schema';

// Define schema with Zod
const RecipeSchema = z.object({
  name: z.string().describe('Name of the recipe'),
  prepTime: z.number().describe('Preparation time in minutes'),
  ingredients: z.array(z.object({
    item: z.string(),
    quantity: z.string(),
  })),
  instructions: z.array(z.string()),
  difficulty: z.enum(['easy', 'medium', 'hard']),
});

type Recipe = z.infer<typeof RecipeSchema>;

async function extractRecipe(text: string): Promise<Recipe> {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{
          parts: [{ text: `Extract recipe from:\n\n${text}` }]
        }],
        generationConfig: {
          responseMimeType: 'application/json',
          responseSchema: zodToJsonSchema(RecipeSchema)
        }
      })
    }
  );

  const result = await response.json();
  const data = JSON.parse(result.candidates?.[0]?.content?.parts?.[0]?.text || '{}');

  // Validate with Zod for runtime safety
  return RecipeSchema.parse(data);
}
```

## Vision (Images)

```typescript
async function analyzeImage(imageBase64: string, prompt: string): Promise<string> {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{
          parts: [
            { text: prompt },
            {
              inlineData: {
                mimeType: 'image/jpeg',
                data: imageBase64
              }
            }
          ]
        }]
      })
    }
  );

  const result = await response.json();
  return result.candidates?.[0]?.content?.parts?.[0]?.text || '';
}

// Usage
const imageBuffer = fs.readFileSync('image.jpg');
const base64 = imageBuffer.toString('base64');
const description = await analyzeImage(base64, 'Describe this image in detail.');
```

## PDF Analysis

```typescript
async function analyzePdf(pdfBase64: string, prompt: string): Promise<string> {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{
          parts: [
            { text: prompt },
            {
              inlineData: {
                mimeType: 'application/pdf',
                data: pdfBase64
              }
            }
          ]
        }]
      })
    }
  );

  const result = await response.json();
  return result.candidates?.[0]?.content?.parts?.[0]?.text || '';
}
```

## Web Grounding (Search)

```typescript
async function searchAndAnswer(query: string): Promise<string> {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{
          parts: [{ text: query }]
        }],
        tools: [{
          googleSearch: {}
        }]
      })
    }
  );

  const result = await response.json();
  return result.candidates?.[0]?.content?.parts?.[0]?.text || '';
}
```

## Generation Config Options

```typescript
generationConfig: {
  temperature: 0.7,           // 0-2, higher = more creative
  topP: 0.95,                 // Nucleus sampling
  topK: 40,                   // Top-k sampling
  maxOutputTokens: 65536,     // Max response length (up to 65K)
  stopSequences: ['END'],     // Stop generation at these
  responseMimeType: 'application/json',  // Force JSON output
  responseSchema: { ... },    // JSON schema for structured output
}
```

## Error Handling

```typescript
async function callGeminiSafe(prompt: string): Promise<string | null> {
  try {
    const response = await fetch(/* ... */);

    if (response.status === 429) {
      // Rate limited - wait and retry
      await new Promise(r => setTimeout(r, 60000));
      return callGeminiSafe(prompt);
    }

    if (!response.ok) {
      console.error(`Gemini API error: ${response.status}`);
      return null;
    }

    const result = await response.json();

    // Check for blocked content
    if (result.candidates?.[0]?.finishReason === 'SAFETY') {
      console.warn('Content blocked by safety filters');
      return null;
    }

    return result.candidates?.[0]?.content?.parts?.[0]?.text || null;
  } catch (error) {
    console.error('Gemini API call failed:', error);
    return null;
  }
}
```

## Reusable Gemini Client

```typescript
// lib/gemini.ts
export class GeminiClient {
  private apiKey: string;
  private model: string;

  constructor(apiKey: string, model = 'gemini-2.5-flash') {
    this.apiKey = apiKey;
    this.model = model;
  }

  async generate(prompt: string, options: {
    temperature?: number;
    maxTokens?: number;
    json?: boolean;
    schema?: object;
  } = {}): Promise<string> {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${this.model}:generateContent?key=${this.apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: options.temperature ?? 0.7,
            maxOutputTokens: options.maxTokens ?? 8192,
            ...(options.json && { responseMimeType: 'application/json' }),
            ...(options.schema && { responseSchema: options.schema }),
          }
        })
      }
    );

    const result = await response.json();
    return result.candidates?.[0]?.content?.parts?.[0]?.text || '';
  }

  async generateJson<T>(prompt: string, schema?: object): Promise<T> {
    const text = await this.generate(prompt, {
      json: true,
      temperature: 0.1,
      schema
    });
    return JSON.parse(text);
  }
}

// Usage
const gemini = new GeminiClient(process.env.GEMINI_API_KEY!);
const response = await gemini.generate('Tell me a joke');
const data = await gemini.generateJson<Company>('Extract company info...', companySchema);
```

## Model Selection Guide

| Use Case | Recommended Model |
|----------|-------------------|
| General tasks, prototyping | `gemini-2.5-flash` |
| Complex reasoning, coding | `gemini-2.5-pro` or `gemini-3-pro-preview` |
| High-volume, cost-sensitive | `gemini-2.5-flash-lite` |
| Latest capabilities | `gemini-3-flash-preview` |

---

[← AI Index](./index.md) | [Vertex AI →](./vertex-ai.md)
