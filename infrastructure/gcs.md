---
layout: default
title: Cloud Storage (GCS)
---

# Google Cloud Storage

Object storage for files, images, PDFs, and other binary data.

## Create Bucket

```bash
# Create bucket
gsutil mb -l us-west1 -p PROJECT_ID gs://my-app-storage

# With uniform access (recommended)
gsutil mb -l us-west1 -p PROJECT_ID -b on gs://my-app-storage

# List buckets
gsutil ls -p PROJECT_ID
```

## CLI Operations

```bash
# Upload file
gsutil cp local-file.pdf gs://my-bucket/path/file.pdf

# Upload folder
gsutil -m cp -r ./local-folder gs://my-bucket/path/

# Download file
gsutil cp gs://my-bucket/path/file.pdf ./local-file.pdf

# List files
gsutil ls gs://my-bucket/path/

# Delete file
gsutil rm gs://my-bucket/path/file.pdf

# Delete folder
gsutil -m rm -r gs://my-bucket/path/
```

## Node.js SDK

### Setup

```typescript
// lib/storage.ts
import { Storage } from '@google-cloud/storage';

const storage = new Storage({
  projectId: process.env.GCP_PROJECT_ID,
});

export const bucket = storage.bucket(process.env.GCS_BUCKET_NAME!);
```

### Upload

```typescript
// Upload buffer
async function uploadBuffer(buffer: Buffer, path: string, contentType: string) {
  const file = bucket.file(path);
  await file.save(buffer, {
    contentType,
    resumable: false,
  });
  return `gs://${bucket.name}/${path}`;
}

// Upload from file path
async function uploadFile(localPath: string, destPath: string) {
  await bucket.upload(localPath, {
    destination: destPath,
  });
}

// Upload with metadata
async function uploadWithMetadata(buffer: Buffer, path: string) {
  const file = bucket.file(path);
  await file.save(buffer, {
    contentType: 'application/pdf',
    metadata: {
      uploadedBy: 'user123',
      originalName: 'report.pdf',
    },
  });
}
```

## Custom Metadata

GCS allows storing custom metadata with each file. Use this to:
- Link files to Firestore documents
- Store document descriptions
- Track processing status

### Upload with Rich Metadata

```typescript
async function uploadWithMetadata(buffer: Buffer, path: string, meta: {
  firestoreId?: string;
  description?: string;
}) {
  await bucket.file(path).save(buffer, {
    metadata: {
      firestoreId: meta.firestoreId || '',
      description: meta.description || '',
      uploadedAt: new Date().toISOString(),
    },
  });
}
```

### Read Metadata

```typescript
async function getFileMetadata(path: string) {
  const [metadata] = await bucket.file(path).getMetadata();
  return {
    name: metadata.name,
    size: metadata.size,
    firestoreId: metadata.metadata?.firestoreId,
    description: metadata.metadata?.description,
  };
}
```

### Update Metadata

```typescript
await bucket.file(path).setMetadata({
  metadata: { description: 'Updated', status: 'processed' }
});
```

### Linking GCS to Firestore

```typescript
// Store GCS path in Firestore, Firestore ID in GCS metadata
async function uploadWithFirestoreLink(buffer: Buffer, filename: string) {
  const docRef = await db.collection('documents').add({ name: filename });
  const gcsPath = `documents/${docRef.id}/${filename}`;
  
  await bucket.file(gcsPath).save(buffer, {
    metadata: { firestoreId: docRef.id }
  });
  
  await docRef.update({ gcsPath });
  return { firestoreId: docRef.id, gcsPath };
}
```

### CLI Metadata

```bash
# View metadata
gsutil stat gs://my-bucket/file.pdf

# Set custom metadata
gsutil setmeta -h "x-goog-meta-description:Report" gs://my-bucket/file.pdf
gsutil setmeta -h "x-goog-meta-firestore-id:abc123" gs://my-bucket/file.pdf
```
### Download

```typescript
// Download to buffer
async function downloadBuffer(path: string): Promise<Buffer> {
  const file = bucket.file(path);
  const [contents] = await file.download();
  return contents;
}

// Download to file
async function downloadToFile(gcsPath: string, localPath: string) {
  await bucket.file(gcsPath).download({ destination: localPath });
}

// Stream download
async function streamDownload(path: string) {
  const file = bucket.file(path);
  return file.createReadStream();
}
```

### Signed URLs (Temporary Access)

```typescript
// Generate signed URL for download
async function getSignedDownloadUrl(path: string, expiresInMinutes = 15) {
  const file = bucket.file(path);
  const [url] = await file.getSignedUrl({
    version: 'v4',
    action: 'read',
    expires: Date.now() + expiresInMinutes * 60 * 1000,
  });
  return url;
}

// Generate signed URL for upload
async function getSignedUploadUrl(path: string, contentType: string) {
  const file = bucket.file(path);
  const [url] = await file.getSignedUrl({
    version: 'v4',
    action: 'write',
    expires: Date.now() + 15 * 60 * 1000,
    contentType,
  });
  return url;
}
```

### List and Delete

```typescript
// List files
async function listFiles(prefix: string) {
  const [files] = await bucket.getFiles({ prefix });
  return files.map(file => ({
    name: file.name,
    size: file.metadata.size,
    updated: file.metadata.updated,
  }));
}

// Check if file exists
async function fileExists(path: string): Promise<boolean> {
  const [exists] = await bucket.file(path).exists();
  return exists;
}

// Delete file
async function deleteFile(path: string) {
  await bucket.file(path).delete();
}

// Delete folder (all files with prefix)
async function deleteFolder(prefix: string) {
  await bucket.deleteFiles({ prefix });
}
```

## Next.js API Route Example

```typescript
// app/api/upload/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { bucket } from '@/lib/storage';

export async function POST(request: NextRequest) {
  const formData = await request.formData();
  const file = formData.get('file') as File;

  if (!file) {
    return NextResponse.json({ error: 'No file provided' }, { status: 400 });
  }

  const buffer = Buffer.from(await file.arrayBuffer());
  const path = `uploads/${Date.now()}-${file.name}`;

  const gcsFile = bucket.file(path);
  await gcsFile.save(buffer, {
    contentType: file.type,
  });

  // Get signed URL for access
  const [url] = await gcsFile.getSignedUrl({
    version: 'v4',
    action: 'read',
    expires: Date.now() + 7 * 24 * 60 * 60 * 1000, // 7 days
  });

  return NextResponse.json({ path, url });
}
```

## CORS Configuration

Create `cors.json`:

```json
[
  {
    "origin": ["https://yourdomain.com", "http://localhost:3000"],
    "method": ["GET", "PUT", "POST"],
    "responseHeader": ["Content-Type"],
    "maxAgeSeconds": 3600
  }
]
```

Apply:
```bash
gsutil cors set cors.json gs://my-bucket
```

## Public Access

```bash
# Make single file public
gsutil acl ch -u AllUsers:R gs://my-bucket/public/image.png

# Make folder public
gsutil -m acl ch -r -u AllUsers:R gs://my-bucket/public/
```

For uniform bucket-level access:
```bash
# Grant public read to bucket
gsutil iam ch allUsers:objectViewer gs://my-bucket
```

## Lifecycle Rules

Create `lifecycle.json`:

```json
{
  "lifecycle": {
    "rule": [
      {
        "action": { "type": "Delete" },
        "condition": { "age": 30 }
      },
      {
        "action": { "type": "SetStorageClass", "storageClass": "NEARLINE" },
        "condition": { "age": 90 }
      }
    ]
  }
}
```

Apply:
```bash
gsutil lifecycle set lifecycle.json gs://my-bucket
```

## Storage Structure Pattern

```
gs://my-app-storage/
├── uploads/
│   └── {user_id}/
│       └── {file_id}.pdf
├── processed/
│   └── {document_id}/
│       ├── original.pdf
│       └── converted.md
├── public/
│   └── logos/
│       └── company-logo.png
└── temp/
    └── {session_id}/
        └── working-file.tmp
```

## Common Issues

| Issue | Solution |
|-------|----------|
| Permission denied | Check service account roles |
| CORS error | Set CORS configuration |
| Signed URL invalid | Check system clock, regenerate |
| Large file upload fails | Use resumable upload |

---

[← Firestore](./firestore.md) | [Secret Manager →](./secrets.md)
