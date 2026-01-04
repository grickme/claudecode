---
layout: default
title: Tailwind CSS
---

# Tailwind CSS

Utility-first CSS framework for rapid UI development.

## Setup

Already included with `create-next-app --tailwind`. Manual setup:

```bash
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

## Configuration

```javascript
// tailwind.config.js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#eff6ff',
          100: '#dbeafe',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
        },
        secondary: '#64748b',
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
      },
    },
  },
  plugins: [],
};
```

## Common Utilities

### Layout

```html
<!-- Flexbox -->
<div class="flex items-center justify-between">
  <div>Left</div>
  <div>Right</div>
</div>

<!-- Grid -->
<div class="grid grid-cols-3 gap-4">
  <div>1</div>
  <div>2</div>
  <div>3</div>
</div>

<!-- Container -->
<div class="container mx-auto px-4">
  Centered content with padding
</div>
```

### Spacing

```html
<!-- Padding -->
<div class="p-4">All sides</div>
<div class="px-4 py-2">Horizontal/Vertical</div>
<div class="pt-4 pb-2 pl-6 pr-8">Individual</div>

<!-- Margin -->
<div class="m-4">All sides</div>
<div class="mx-auto">Center horizontally</div>
<div class="mt-4 mb-8">Top/Bottom</div>

<!-- Space between children -->
<div class="space-y-4">
  <div>Item 1</div>
  <div>Item 2</div>
  <div>Item 3</div>
</div>
```

### Typography

```html
<!-- Size -->
<p class="text-sm">Small</p>
<p class="text-base">Base (default)</p>
<p class="text-lg">Large</p>
<p class="text-xl">Extra large</p>
<p class="text-2xl">2x large</p>

<!-- Weight -->
<p class="font-normal">Normal</p>
<p class="font-medium">Medium</p>
<p class="font-semibold">Semibold</p>
<p class="font-bold">Bold</p>

<!-- Color -->
<p class="text-gray-600">Muted text</p>
<p class="text-blue-600">Primary color</p>
<p class="text-red-500">Error text</p>
```

### Colors

```html
<!-- Text -->
<p class="text-blue-600">Blue text</p>

<!-- Background -->
<div class="bg-blue-100">Light blue bg</div>
<div class="bg-gray-50">Light gray bg</div>

<!-- Border -->
<div class="border border-gray-200">Gray border</div>

<!-- Hover -->
<button class="bg-blue-600 hover:bg-blue-700">Button</button>
```

### Sizing

```html
<!-- Width -->
<div class="w-full">Full width</div>
<div class="w-1/2">Half width</div>
<div class="w-64">Fixed 256px</div>
<div class="max-w-lg">Max width large</div>

<!-- Height -->
<div class="h-screen">Full viewport height</div>
<div class="h-64">Fixed 256px</div>
<div class="min-h-screen">Minimum full height</div>
```

### Borders & Rounded

```html
<!-- Border -->
<div class="border">1px border</div>
<div class="border-2">2px border</div>
<div class="border-t">Top only</div>

<!-- Rounded -->
<div class="rounded">Slightly rounded</div>
<div class="rounded-md">Medium rounded</div>
<div class="rounded-lg">Large rounded</div>
<div class="rounded-full">Fully rounded</div>
```

### Shadows

```html
<div class="shadow-sm">Small shadow</div>
<div class="shadow">Default shadow</div>
<div class="shadow-md">Medium shadow</div>
<div class="shadow-lg">Large shadow</div>
```

## Responsive Design

```html
<!-- Mobile-first -->
<div class="text-sm md:text-base lg:text-lg">
  Small on mobile, base on tablet, large on desktop
</div>

<!-- Grid responsive -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  <div>1</div>
  <div>2</div>
  <div>3</div>
</div>

<!-- Hide/Show -->
<div class="hidden md:block">Only on tablet+</div>
<div class="block md:hidden">Only on mobile</div>
```

Breakpoints:
- `sm`: 640px
- `md`: 768px
- `lg`: 1024px
- `xl`: 1280px
- `2xl`: 1536px

## Common Components

### Card

```html
<div class="bg-white rounded-lg border shadow-sm p-6">
  <h3 class="text-lg font-semibold">Card Title</h3>
  <p class="mt-2 text-gray-600">Card description goes here.</p>
</div>
```

### Button

```html
<!-- Primary -->
<button class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors">
  Primary Button
</button>

<!-- Secondary -->
<button class="px-4 py-2 border border-gray-300 rounded-md hover:bg-gray-50 transition-colors">
  Secondary Button
</button>

<!-- Disabled -->
<button class="px-4 py-2 bg-gray-300 text-gray-500 rounded-md cursor-not-allowed" disabled>
  Disabled
</button>
```

### Form Input

```html
<input
  type="text"
  placeholder="Enter name"
  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
/>
```

### Badge

```html
<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
  Active
</span>

<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
  Success
</span>
```

### Alert

```html
<!-- Info -->
<div class="p-4 bg-blue-50 border border-blue-200 rounded-md">
  <p class="text-blue-800">This is an info message.</p>
</div>

<!-- Error -->
<div class="p-4 bg-red-50 border border-red-200 rounded-md">
  <p class="text-red-800">This is an error message.</p>
</div>
```

## Dark Mode

```javascript
// tailwind.config.js
module.exports = {
  darkMode: 'class',  // or 'media'
  // ...
};
```

```html
<div class="bg-white dark:bg-gray-900">
  <p class="text-gray-900 dark:text-white">
    This text adapts to dark mode
  </p>
</div>
```

## Custom Classes with @apply

```css
/* globals.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer components {
  .btn-primary {
    @apply px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors;
  }

  .input {
    @apply w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500;
  }

  .card {
    @apply bg-white rounded-lg border shadow-sm p-6;
  }
}
```

Usage:
```html
<button class="btn-primary">Click me</button>
<input class="input" placeholder="Type here" />
<div class="card">Card content</div>
```

## Animations

```html
<!-- Spin -->
<div class="animate-spin h-5 w-5 border-2 border-blue-600 rounded-full border-t-transparent"></div>

<!-- Pulse -->
<div class="animate-pulse bg-gray-200 h-4 w-full rounded"></div>

<!-- Bounce -->
<div class="animate-bounce">👆</div>

<!-- Fade in (custom) -->
<div class="transition-opacity duration-300 opacity-0 hover:opacity-100">
  Hover to reveal
</div>
```

## Plugins

```bash
npm install -D @tailwindcss/forms @tailwindcss/typography
```

```javascript
// tailwind.config.js
module.exports = {
  // ...
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
};
```

---

[← Next.js](./nextjs.md) | [Components →](./components.md)
