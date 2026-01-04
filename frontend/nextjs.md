---
layout: default
title: Next.js
---

# Next.js (App Router)

Modern React framework with server components and file-based routing.

## Project Setup

```bash
npx create-next-app@latest my-app --typescript --tailwind --eslint --app
cd my-app
npm run dev
```

## Project Structure

```
my-app/
├── app/
│   ├── layout.tsx          # Root layout
│   ├── page.tsx             # Home page (/)
│   ├── globals.css          # Global styles
│   ├── dashboard/
│   │   ├── layout.tsx       # Dashboard layout
│   │   └── page.tsx         # Dashboard page (/dashboard)
│   ├── company/
│   │   └── [id]/
│   │       └── page.tsx     # Dynamic page (/company/:id)
│   └── api/
│       └── ...              # API routes
├── components/
│   ├── ui/                  # shadcn/ui components
│   └── ...                  # Custom components
├── lib/
│   ├── utils.ts             # Utility functions
│   └── firebase.ts          # Firebase config
├── public/
│   └── ...                  # Static files
├── next.config.js
├── tailwind.config.js
└── package.json
```

## Root Layout

```tsx
// app/layout.tsx
import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'My App',
  description: 'My awesome application',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <nav className="border-b p-4">
          <a href="/" className="font-bold">My App</a>
        </nav>
        <main>{children}</main>
      </body>
    </html>
  );
}
```

## Pages

### Static Page

```tsx
// app/page.tsx
export default function HomePage() {
  return (
    <div className="container mx-auto p-8">
      <h1 className="text-3xl font-bold">Welcome</h1>
      <p className="mt-4 text-gray-600">This is the home page.</p>
    </div>
  );
}
```

### Dynamic Page

```tsx
// app/company/[id]/page.tsx
interface Props {
  params: { id: string };
}

export default async function CompanyPage({ params }: Props) {
  const company = await getCompany(params.id);

  if (!company) {
    notFound();
  }

  return (
    <div className="container mx-auto p-8">
      <h1 className="text-3xl font-bold">{company.name}</h1>
      <p className="mt-4">{company.description}</p>
    </div>
  );
}

// Generate static params for SSG
export async function generateStaticParams() {
  const companies = await getCompanies();
  return companies.map((company) => ({
    id: company.id,
  }));
}
```

## Server Components vs Client Components

### Server Component (Default)

```tsx
// app/users/page.tsx
// This runs on the server - can directly access DB
import { db } from '@/lib/firebase-admin';

export default async function UsersPage() {
  const snapshot = await db.collection('users').get();
  const users = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

  return (
    <ul>
      {users.map(user => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}
```

### Client Component

```tsx
// components/Counter.tsx
'use client';  // <-- Required for client components

import { useState } from 'react';

export function Counter() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(c => c + 1)}>Increment</button>
    </div>
  );
}
```

### When to Use Which

| Server Component | Client Component |
|-----------------|------------------|
| Fetch data | useState, useEffect |
| Access backend resources | Event handlers (onClick) |
| Keep secrets on server | Browser APIs |
| Reduce client JS | Interactive UI |

## Data Fetching

### Server Component (Recommended)

```tsx
// app/posts/page.tsx
async function getPosts() {
  const res = await fetch('https://api.example.com/posts', {
    next: { revalidate: 60 },  // Revalidate every 60 seconds
  });
  return res.json();
}

export default async function PostsPage() {
  const posts = await getPosts();

  return (
    <ul>
      {posts.map(post => (
        <li key={post.id}>{post.title}</li>
      ))}
    </ul>
  );
}
```

### Client-side Fetching

```tsx
'use client';

import { useEffect, useState } from 'react';

export function LiveData() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/data')
      .then(res => res.json())
      .then(data => {
        setData(data);
        setLoading(false);
      });
  }, []);

  if (loading) return <div>Loading...</div>;

  return <div>{JSON.stringify(data)}</div>;
}
```

## Navigation

### Link Component

```tsx
import Link from 'next/link';

export function Navigation() {
  return (
    <nav>
      <Link href="/">Home</Link>
      <Link href="/dashboard">Dashboard</Link>
      <Link href="/company/123">Company 123</Link>
    </nav>
  );
}
```

### Programmatic Navigation

```tsx
'use client';

import { useRouter } from 'next/navigation';

export function LoginButton() {
  const router = useRouter();

  const handleLogin = async () => {
    await login();
    router.push('/dashboard');
  };

  return <button onClick={handleLogin}>Login</button>;
}
```

## Loading States

```tsx
// app/dashboard/loading.tsx
export default function Loading() {
  return (
    <div className="flex items-center justify-center h-64">
      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
    </div>
  );
}
```

## Error Handling

```tsx
// app/dashboard/error.tsx
'use client';

export default function Error({
  error,
  reset,
}: {
  error: Error;
  reset: () => void;
}) {
  return (
    <div className="text-center p-8">
      <h2 className="text-2xl font-bold text-red-600">Something went wrong!</h2>
      <p className="mt-2 text-gray-600">{error.message}</p>
      <button
        onClick={reset}
        className="mt-4 px-4 py-2 bg-blue-600 text-white rounded"
      >
        Try again
      </button>
    </div>
  );
}
```

## Not Found

```tsx
// app/not-found.tsx
import Link from 'next/link';

export default function NotFound() {
  return (
    <div className="text-center p-8">
      <h2 className="text-2xl font-bold">Page Not Found</h2>
      <p className="mt-2 text-gray-600">Could not find the requested page.</p>
      <Link href="/" className="mt-4 text-blue-600">
        Go Home
      </Link>
    </div>
  );
}
```

## Metadata

```tsx
// app/about/page.tsx
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'About Us',
  description: 'Learn more about our company',
  openGraph: {
    title: 'About Us',
    description: 'Learn more about our company',
    images: ['/og-image.jpg'],
  },
};

export default function AboutPage() {
  return <div>About us...</div>;
}
```

### Dynamic Metadata

```tsx
// app/company/[id]/page.tsx
import type { Metadata } from 'next';

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const company = await getCompany(params.id);

  return {
    title: company?.name || 'Company',
    description: company?.description,
  };
}
```

## Environment Variables

```bash
# .env.local
# Server-side only
DATABASE_URL=postgresql://...
API_SECRET=secret123

# Client-side (prefix with NEXT_PUBLIC_)
NEXT_PUBLIC_APP_URL=https://myapp.com
NEXT_PUBLIC_FIREBASE_API_KEY=xxx
```

Usage:
```tsx
// Server component
const dbUrl = process.env.DATABASE_URL;

// Client component
const appUrl = process.env.NEXT_PUBLIC_APP_URL;
```

## next.config.js

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',  // For Docker

  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'logo.clearbit.com',
      },
    ],
  },

  async redirects() {
    return [
      {
        source: '/old-page',
        destination: '/new-page',
        permanent: true,
      },
    ];
  },

  async rewrites() {
    return [
      {
        source: '/api/proxy/:path*',
        destination: 'https://external-api.com/:path*',
      },
    ];
  },
};

module.exports = nextConfig;
```

---

[← Frontend Index](./index.md) | [Tailwind CSS →](./tailwind.md)
