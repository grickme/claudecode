---
layout: default
title: Embeddings & Vector Search
---

# Embeddings & Vector Search

Convert text to vectors for semantic search, similarity, and RAG applications.

## Google Embedding Models

| Model | Dimensions | Use Case |
|-------|------------|----------|
| `text-embedding-005` | 768 | Default, general purpose |
| `text-embedding-004` | 768 | Previous version |
| `text-multilingual-embedding-002` | 768 | Multilingual |

## Vertex AI Embeddings

### Using SDK

```typescript
import { VertexAI } from '@google-cloud/vertexai';

const vertexAI = new VertexAI({
  project: process.env.GCP_PROJECT_ID!,
  location: 'us-central1',
});

const model = vertexAI.preview.getGenerativeModel({
  model: 'text-embedding-005',
});

export async function getEmbedding(text: string): Promise<number[]> {
  const result = await model.embedContent({
    content: { parts: [{ text }] },
  });

  return result.embedding.values;
}

// Batch embeddings
export async function getEmbeddings(texts: string[]): Promise<number[][]> {
  const results = await Promise.all(
    texts.map(text => getEmbedding(text))
  );
  return results;
}
```

### Using REST API

```typescript
import { GoogleAuth } from 'google-auth-library';

const auth = new GoogleAuth({
  scopes: ['https://www.googleapis.com/auth/cloud-platform'],
});

async function getEmbedding(text: string): Promise<number[]> {
  const client = await auth.getClient();
  const accessToken = await client.getAccessToken();

  const projectId = process.env.GCP_PROJECT_ID;
  const location = 'us-central1';

  const response = await fetch(
    `https://${location}-aiplatform.googleapis.com/v1/projects/${projectId}/locations/${location}/publishers/google/models/text-embedding-005:predict`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken.token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        instances: [{ content: text }],
      }),
    }
  );

  const result = await response.json();
  return result.predictions[0].embeddings.values;
}
```

## Similarity Calculation

```typescript
// Cosine similarity
function cosineSimilarity(a: number[], b: number[]): number {
  let dotProduct = 0;
  let normA = 0;
  let normB = 0;

  for (let i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }

  return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
}

// Find most similar
function findMostSimilar(
  query: number[],
  candidates: { id: string; embedding: number[] }[],
  topK: number = 5
): { id: string; score: number }[] {
  const scores = candidates.map(c => ({
    id: c.id,
    score: cosineSimilarity(query, c.embedding),
  }));

  return scores
    .sort((a, b) => b.score - a.score)
    .slice(0, topK);
}
```

## Firestore Vector Search

Firestore now supports native vector search:

```typescript
import { FieldValue } from '@google-cloud/firestore';

// Store document with embedding
await db.collection('documents').add({
  content: text,
  embedding: FieldValue.vector(embeddingArray),
  createdAt: FieldValue.serverTimestamp(),
});

// Search by similarity
const queryEmbedding = await getEmbedding('search query');

const results = await db.collection('documents')
  .findNearest('embedding', queryEmbedding, {
    limit: 10,
    distanceMeasure: 'COSINE',
  })
  .get();

results.forEach(doc => {
  console.log(doc.data().content);
});
```

## RAG Pattern (Retrieval-Augmented Generation)

```typescript
interface Document {
  id: string;
  content: string;
  embedding: number[];
}

class RAGSystem {
  private documents: Document[] = [];

  async indexDocument(id: string, content: string) {
    const embedding = await getEmbedding(content);
    this.documents.push({ id, content, embedding });
  }

  async query(question: string, topK: number = 3): Promise<string> {
    // 1. Get query embedding
    const queryEmbedding = await getEmbedding(question);

    // 2. Find relevant documents
    const relevant = findMostSimilar(queryEmbedding, this.documents, topK);

    // 3. Build context
    const context = relevant
      .map(r => this.documents.find(d => d.id === r.id)?.content)
      .filter(Boolean)
      .join('\n\n---\n\n');

    // 4. Generate answer with context
    const prompt = `Answer the question based on the following context:

CONTEXT:
${context}

QUESTION: ${question}

ANSWER:`;

    return await callGemini(prompt);
  }
}

// Usage
const rag = new RAGSystem();
await rag.indexDocument('doc1', 'Company was founded in 2020...');
await rag.indexDocument('doc2', 'Revenue grew 50% year over year...');

const answer = await rag.query('When was the company founded?');
```

## Chunking Strategies

For long documents, split into chunks before embedding:

```typescript
function chunkText(text: string, chunkSize: number = 1000, overlap: number = 200): string[] {
  const chunks: string[] = [];
  let start = 0;

  while (start < text.length) {
    const end = Math.min(start + chunkSize, text.length);
    chunks.push(text.slice(start, end));
    start += chunkSize - overlap;
  }

  return chunks;
}

// Sentence-aware chunking
function chunkBySentence(text: string, maxChunkSize: number = 1000): string[] {
  const sentences = text.match(/[^.!?]+[.!?]+/g) || [text];
  const chunks: string[] = [];
  let currentChunk = '';

  for (const sentence of sentences) {
    if ((currentChunk + sentence).length > maxChunkSize && currentChunk) {
      chunks.push(currentChunk.trim());
      currentChunk = sentence;
    } else {
      currentChunk += sentence;
    }
  }

  if (currentChunk) {
    chunks.push(currentChunk.trim());
  }

  return chunks;
}
```

## Complete Example: Document Search

```typescript
// lib/document-search.ts
import { db } from './firebase-admin';
import { FieldValue } from '@google-cloud/firestore';

export async function indexDocument(
  collectionName: string,
  docId: string,
  content: string,
  metadata: Record<string, any> = {}
) {
  const chunks = chunkBySentence(content);

  for (let i = 0; i < chunks.length; i++) {
    const embedding = await getEmbedding(chunks[i]);

    await db.collection(`${collectionName}_embeddings`).add({
      parentId: docId,
      chunkIndex: i,
      content: chunks[i],
      embedding: FieldValue.vector(embedding),
      ...metadata,
      createdAt: FieldValue.serverTimestamp(),
    });
  }
}

export async function searchDocuments(
  collectionName: string,
  query: string,
  limit: number = 5
): Promise<{ content: string; parentId: string; score: number }[]> {
  const queryEmbedding = await getEmbedding(query);

  const results = await db.collection(`${collectionName}_embeddings`)
    .findNearest('embedding', queryEmbedding, {
      limit,
      distanceMeasure: 'COSINE',
    })
    .get();

  return results.docs.map(doc => ({
    content: doc.data().content,
    parentId: doc.data().parentId,
    score: doc.data()._distance || 0,
  }));
}
```

## Performance Tips

1. **Batch embeddings** - Process multiple texts in one API call
2. **Cache embeddings** - Store computed embeddings, don't recompute
3. **Chunk appropriately** - 500-1000 tokens per chunk works well
4. **Use indexes** - Firestore vector indexes for large collections

## Alternative: Vertex AI Vector Search

For very large datasets (millions of vectors):

```bash
# Create index
gcloud ai indexes create \
  --display-name="my-index" \
  --metadata-schema-uri="gs://google-cloud-aiplatform/schema/matchingengine/metadata/nearest_neighbor_search_1.0.0.yaml" \
  --project PROJECT_ID \
  --region us-central1
```

This is more complex but scales to billions of vectors.

---

[← Vertex AI](./vertex-ai.md) | [Back to AI Index](./index.md)
