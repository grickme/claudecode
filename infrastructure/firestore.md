---
layout: default
title: Firestore
---

# Google Firestore

NoSQL document database with real-time sync capabilities.

## Setup

```bash
# Create Firestore database
gcloud firestore databases create \
  --location=us-west1 \
  --project PROJECT_ID

# Or for EU
gcloud firestore databases create \
  --location=europe-west1 \
  --project PROJECT_ID
```

## Firebase Admin Setup (Server-side)

```typescript
// lib/firebase-admin.ts
import admin from 'firebase-admin';

if (!admin.apps.length) {
  // Production: Uses Application Default Credentials
  // Local: Uses GOOGLE_APPLICATION_CREDENTIALS env var
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

export const db = admin.firestore();
export const auth = admin.auth();
```

## CRUD Operations

### Create / Update

```typescript
// Set document (overwrites)
await db.collection('users').doc(userId).set({
  name: 'John Doe',
  email: 'john@example.com',
  createdAt: admin.firestore.FieldValue.serverTimestamp(),
});

// Update specific fields (merge)
await db.collection('users').doc(userId).update({
  lastLogin: admin.firestore.FieldValue.serverTimestamp(),
});

// Set with merge (create or update)
await db.collection('users').doc(userId).set({
  name: 'John Doe',
}, { merge: true });

// Add document (auto-generated ID)
const docRef = await db.collection('users').add({
  name: 'Jane Doe',
  email: 'jane@example.com',
});
console.log('New doc ID:', docRef.id);
```

### Read

```typescript
// Get single document
const doc = await db.collection('users').doc(userId).get();
if (doc.exists) {
  const data = doc.data();
  console.log(data.name);
}

// Get all documents in collection
const snapshot = await db.collection('users').get();
const users = snapshot.docs.map(doc => ({
  id: doc.id,
  ...doc.data(),
}));
```

### Query

```typescript
// Simple query
const snapshot = await db.collection('users')
  .where('role', '==', 'admin')
  .get();

// Multiple conditions
const snapshot = await db.collection('orders')
  .where('status', '==', 'pending')
  .where('total', '>', 100)
  .orderBy('total', 'desc')
  .limit(10)
  .get();

// Array contains
const snapshot = await db.collection('posts')
  .where('tags', 'array-contains', 'javascript')
  .get();

// In query
const snapshot = await db.collection('users')
  .where('role', 'in', ['admin', 'moderator'])
  .get();
```

### Delete

```typescript
// Delete document
await db.collection('users').doc(userId).delete();

// Delete field
await db.collection('users').doc(userId).update({
  temporaryField: admin.firestore.FieldValue.delete(),
});
```

## Subcollections

```typescript
// Create document in subcollection
await db.collection('companies').doc(companyId)
  .collection('employees').doc(employeeId)
  .set({ name, title, salary });

// Query subcollection
const employees = await db.collection('companies').doc(companyId)
  .collection('employees')
  .where('department', '==', 'Engineering')
  .get();

// Collection group query (across all subcollections)
const allEmployees = await db.collectionGroup('employees')
  .where('salary', '>', 100000)
  .get();
```

## Batch Operations

```typescript
const batch = db.batch();

// Add multiple operations
batch.set(db.collection('users').doc('user1'), { name: 'User 1' });
batch.update(db.collection('users').doc('user2'), { active: true });
batch.delete(db.collection('users').doc('user3'));

// Commit all at once (atomic)
await batch.commit();
```

## Transactions

```typescript
await db.runTransaction(async (transaction) => {
  const docRef = db.collection('accounts').doc(accountId);
  const doc = await transaction.get(docRef);

  if (!doc.exists) {
    throw new Error('Account not found');
  }

  const newBalance = doc.data().balance - amount;
  if (newBalance < 0) {
    throw new Error('Insufficient funds');
  }

  transaction.update(docRef, { balance: newBalance });
});
```

## Security Rules

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    function hasRole(role) {
      return isAuthenticated() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == role;
    }

    // Users collection
    match /users/{userId} {
      allow read: if isOwner(userId) || hasRole('admin');
      allow create: if isAuthenticated();
      allow update: if isOwner(userId);
      allow delete: if hasRole('admin');
    }

    // Companies collection
    match /companies/{companyId} {
      allow read: if isAuthenticated();
      allow write: if hasRole('admin') ||
        resource.data.createdBy == request.auth.uid;

      // Subcollection
      match /employees/{employeeId} {
        allow read, write: if isAuthenticated();
      }
    }

    // Public read, authenticated write
    match /posts/{postId} {
      allow read: if true;
      allow write: if isAuthenticated();
    }
  }
}
```

Deploy rules:
```bash
firebase deploy --only firestore:rules
```

## Indexes

Create `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Deploy indexes:
```bash
firebase deploy --only firestore:indexes
```

## Common Patterns

### Timestamp fields

```typescript
import admin from 'firebase-admin';

await db.collection('documents').add({
  title: 'My Doc',
  createdAt: admin.firestore.FieldValue.serverTimestamp(),
  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
});
```

### Increment counter

```typescript
await db.collection('stats').doc('global').update({
  pageViews: admin.firestore.FieldValue.increment(1),
});
```

### Array operations

```typescript
// Add to array
await db.collection('posts').doc(postId).update({
  tags: admin.firestore.FieldValue.arrayUnion('newTag'),
});

// Remove from array
await db.collection('posts').doc(postId).update({
  tags: admin.firestore.FieldValue.arrayRemove('oldTag'),
});
```

## TypeScript Types

```typescript
interface User {
  id: string;
  name: string;
  email: string;
  role: 'admin' | 'user';
  createdAt: admin.firestore.Timestamp;
}

// Typed converter
const userConverter = {
  toFirestore: (user: User) => user,
  fromFirestore: (snapshot: FirebaseFirestore.QueryDocumentSnapshot): User => {
    const data = snapshot.data();
    return { id: snapshot.id, ...data } as User;
  },
};

// Use with collection
const usersRef = db.collection('users').withConverter(userConverter);
const doc = await usersRef.doc(userId).get();
const user: User | undefined = doc.data();
```

---

[← Cloud Run](./cloud-run.md) | [Cloud Storage →](./gcs.md)
