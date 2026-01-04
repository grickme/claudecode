---
layout: default
title: AI & ML
---

# AI & ML Guides

Google AI services for web applications - Gemini, Vertex AI, and Embeddings.

**Official Docs:** [ai.google.dev/gemini-api/docs](https://ai.google.dev/gemini-api/docs)

## Guides

| Guide | Description |
|-------|-------------|
| [Gemini](./gemini.md) | Chat, vision, structured output, web grounding |
| [Vertex AI](./vertex-ai.md) | Production AI with no rate limits |
| [Embeddings](./embeddings.md) | Vector search, semantic similarity, RAG |

## Model Selection

| Use Case | Model | Notes |
|----------|-------|-------|
| General tasks | `gemini-2.5-flash` | Balanced performance (recommended default) |
| Complex reasoning | `gemini-2.5-pro` | Powerful reasoning, complex coding |
| Latest capabilities | `gemini-3-flash-preview` | Fast, frontier-class |
| State-of-the-art | `gemini-3-pro-preview` | Most intelligent reasoning |
| High-volume | `gemini-2.5-flash-lite` | Fastest, most cost-efficient |
| Vision/PDF | `gemini-2.5-flash` | Multimodal: images, PDFs, audio |
| Embeddings | `text-embedding-005` | 768 dimensions |
| Production | Vertex AI | No rate limits |

## Quick Start

```typescript
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

async function askGemini(prompt: string): Promise<string> {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
      })
    }
  );
  const result = await response.json();
  return result.candidates?.[0]?.content?.parts?.[0]?.text || '';
}
```

## Pricing (per 1M tokens, USD)

| Model | Input | Output |
|-------|-------|--------|
| Gemini 3 Pro | $2.00 | $12.00 |
| Gemini 3 Flash | $0.50 | $3.00 |
| Gemini 2.5 Pro | $1.25 | $10.00 |
| Gemini 2.5 Flash | $0.30 | $2.50 |

*All models support 1M token context window and 65K max output tokens.*

---

[← Back to Home](../)
