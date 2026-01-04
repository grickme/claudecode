---
layout: default
title: PDF Creation (Generation)
---

# PDF Creation - Generate PDFs

Create PDFs from HTML, Markdown, or programmatically.

## Tool Comparison

| Tool | Language | Best For | Notes |
|------|----------|----------|-------|
| **Playwright** | Node.js | HTML to PDF | Best quality, headless browser |
| **Puppeteer** | Node.js | HTML to PDF | Chrome-based |
| **jsPDF** | Node.js/Browser | Programmatic | No browser needed |
| **PDFKit** | Node.js | Programmatic | Low-level control |
| **WeasyPrint** | Python | HTML/CSS to PDF | Good CSS support |
| **ReportLab** | Python | Programmatic | Enterprise-grade |

## Playwright (Recommended for HTML to PDF)

Best quality for converting HTML reports to PDF.

### Installation

```bash
npm install playwright
npx playwright install chromium
```

### Basic HTML to PDF

```typescript
import { chromium } from 'playwright';

async function htmlToPdf(html: string, outputPath: string): Promise<Buffer> {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  await page.setContent(html, { waitUntil: 'networkidle' });

  const pdfBuffer = await page.pdf({
    format: 'A4',
    printBackground: true,
    margin: {
      top: '1in',
      right: '1in',
      bottom: '1.25in',
      left: '1in',
    },
  });

  await browser.close();
  return pdfBuffer;
}

// Usage
const html = '<html><body><h1>My Report</h1><p>Content here...</p></body></html>';
const pdf = await htmlToPdf(html);
```

### With Custom Styling

```typescript
async function generateStyledPdf(content: string, title: string): Promise<Buffer> {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        @page {
          size: A4;
          margin: 1in;
        }
        body {
          font-family: 'Helvetica Neue', Arial, sans-serif;
          font-size: 12pt;
          line-height: 1.5;
          color: #1f2937;
        }
        h1 {
          font-size: 24pt;
          color: #1e3a8a;
          border-bottom: 2px solid #1e3a8a;
          padding-bottom: 10px;
        }
        h2 {
          font-size: 18pt;
          color: #1e40af;
          margin-top: 24pt;
        }
        table {
          width: 100%;
          border-collapse: collapse;
          margin: 16pt 0;
        }
        th, td {
          border: 1px solid #d1d5db;
          padding: 8pt;
          text-align: left;
        }
        th {
          background-color: #f3f4f6;
          font-weight: bold;
        }
        .page-break {
          page-break-before: always;
        }
      </style>
    </head>
    <body>
      <h1>${title}</h1>
      ${content}
    </body>
    </html>
  `;

  await page.setContent(html, { waitUntil: 'networkidle' });

  const pdfBuffer = await page.pdf({
    format: 'A4',
    printBackground: true,
    displayHeaderFooter: true,
    headerTemplate: '<div></div>',
    footerTemplate: `
      <div style="font-size: 10px; text-align: center; width: 100%;">
        Page <span class="pageNumber"></span> of <span class="totalPages"></span>
      </div>
    `,
    margin: {
      top: '1in',
      right: '1in',
      bottom: '1.25in',
      left: '1in',
    },
  });

  await browser.close();
  return pdfBuffer;
}
```

### Cover Page with Main Content

```typescript
async function generateReportWithCover(
  title: string,
  subtitle: string,
  content: string,
  date: string
): Promise<Buffer> {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        @page { size: A4; margin: 0; }
        body { font-family: Arial, sans-serif; margin: 0; }

        .cover-page {
          height: 100vh;
          display: flex;
          flex-direction: column;
          justify-content: center;
          align-items: center;
          text-align: center;
          background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);
          color: white;
          page-break-after: always;
        }
        .cover-title { font-size: 48pt; margin-bottom: 20pt; }
        .cover-subtitle { font-size: 24pt; opacity: 0.9; }
        .cover-date { font-size: 14pt; margin-top: 40pt; opacity: 0.8; }

        .content-page {
          padding: 1in;
          font-size: 12pt;
          line-height: 1.6;
        }
        h1 { font-size: 24pt; color: #1e3a8a; }
        h2 { font-size: 18pt; color: #1e40af; }
      </style>
    </head>
    <body>
      <div class="cover-page">
        <div class="cover-title">${title}</div>
        <div class="cover-subtitle">${subtitle}</div>
        <div class="cover-date">${date}</div>
      </div>
      <div class="content-page">
        ${content}
      </div>
    </body>
    </html>
  `;

  await page.setContent(html, { waitUntil: 'networkidle' });
  const pdfBuffer = await page.pdf({ format: 'A4', printBackground: true });

  await browser.close();
  return pdfBuffer;
}
```

## jsPDF (Programmatic, No Browser)

Good for simple PDFs without needing a browser.

### Installation

```bash
npm install jspdf
```

### Basic Usage

```typescript
import { jsPDF } from 'jspdf';

function createSimplePdf(): Buffer {
  const doc = new jsPDF();

  // Title
  doc.setFontSize(24);
  doc.setTextColor(30, 58, 138); // Blue
  doc.text('My Report', 20, 30);

  // Content
  doc.setFontSize(12);
  doc.setTextColor(31, 41, 55); // Dark gray
  doc.text('This is the report content.', 20, 50);

  // Table
  doc.setFontSize(10);
  const tableData = [
    ['Name', 'Value', 'Status'],
    ['Item 1', '100', 'Active'],
    ['Item 2', '200', 'Pending'],
  ];

  let y = 70;
  tableData.forEach((row, i) => {
    row.forEach((cell, j) => {
      doc.text(cell, 20 + j * 50, y);
    });
    y += 10;
  });

  return Buffer.from(doc.output('arraybuffer'));
}
```

### With Auto-Table Plugin

```bash
npm install jspdf jspdf-autotable
```

```typescript
import { jsPDF } from 'jspdf';
import autoTable from 'jspdf-autotable';

function createTablePdf(data: any[]): Buffer {
  const doc = new jsPDF();

  doc.setFontSize(18);
  doc.text('Data Report', 14, 22);

  autoTable(doc, {
    startY: 30,
    head: [['ID', 'Name', 'Email', 'Status']],
    body: data.map(item => [
      item.id,
      item.name,
      item.email,
      item.status,
    ]),
    styles: { fontSize: 10 },
    headStyles: { fillColor: [30, 58, 138] },
  });

  return Buffer.from(doc.output('arraybuffer'));
}
```

## PDFKit (Low-level Control)

### Installation

```bash
npm install pdfkit
```

### Basic Usage

```typescript
import PDFDocument from 'pdfkit';

async function createPdfWithPdfKit(): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument();
    const chunks: Buffer[] = [];

    doc.on('data', chunk => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    // Title
    doc.fontSize(24).fillColor('#1e3a8a').text('Report Title', { align: 'center' });
    doc.moveDown();

    // Content
    doc.fontSize(12).fillColor('#1f2937').text('This is the report content.');
    doc.moveDown();

    // Add image
    // doc.image('path/to/image.png', { width: 200 });

    // Table-like structure
    doc.fontSize(10);
    doc.text('Column 1', 50, doc.y);
    doc.text('Column 2', 200, doc.y);
    doc.text('Column 3', 350, doc.y);

    doc.end();
  });
}
```

## WeasyPrint (Python)

Excellent CSS support for HTML to PDF.

### Installation

```bash
pip install weasyprint
```

### Basic Usage

```python
from weasyprint import HTML, CSS

def html_to_pdf(html_content: str, output_path: str):
    """Convert HTML to PDF with WeasyPrint."""
    css = CSS(string='''
        @page {
            size: A4;
            margin: 1in;
        }
        body {
            font-family: Arial, sans-serif;
            font-size: 12pt;
            line-height: 1.5;
        }
        h1 {
            color: #1e3a8a;
            font-size: 24pt;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            border: 1px solid #ccc;
            padding: 8px;
        }
    ''')

    HTML(string=html_content).write_pdf(output_path, stylesheets=[css])

# Usage
html = '<html><body><h1>Report</h1><p>Content</p></body></html>'
html_to_pdf(html, 'report.pdf')
```

## Next.js API Route

```typescript
// app/api/generate-pdf/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { chromium } from 'playwright';

export async function POST(request: NextRequest) {
  const { html, filename = 'document.pdf' } = await request.json();

  if (!html) {
    return NextResponse.json({ error: 'HTML content required' }, { status: 400 });
  }

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  await page.setContent(html, { waitUntil: 'networkidle' });

  const pdfBuffer = await page.pdf({
    format: 'A4',
    printBackground: true,
    margin: { top: '1in', right: '1in', bottom: '1in', left: '1in' },
  });

  await browser.close();

  return new NextResponse(pdfBuffer, {
    headers: {
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename="${filename}"`,
    },
  });
}
```

## Cloud Run Dockerfile

```dockerfile
FROM node:20-slim

# Install Playwright dependencies
RUN apt-get update && apt-get install -y \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./
RUN npm ci

# Install Playwright browsers
RUN npx playwright install chromium

COPY . .
RUN npm run build

EXPOSE 8080
ENV PORT=8080
CMD ["node", "server.js"]
```

## Save to GCS

```typescript
import { Storage } from '@google-cloud/storage';

async function generateAndUpload(
  html: string,
  bucketName: string,
  path: string
): Promise<string> {
  // Generate PDF
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.setContent(html);
  const pdfBuffer = await page.pdf({ format: 'A4' });
  await browser.close();

  // Upload to GCS
  const storage = new Storage();
  const bucket = storage.bucket(bucketName);
  const file = bucket.file(path);

  await file.save(pdfBuffer, {
    contentType: 'application/pdf',
    metadata: {
      generatedAt: new Date().toISOString(),
    },
  });

  // Get signed URL
  const [url] = await file.getSignedUrl({
    action: 'read',
    expires: Date.now() + 7 * 24 * 60 * 60 * 1000, // 7 days
  });

  return url;
}
```

## Best Practices

1. **Playwright for quality** - Best HTML/CSS rendering for complex layouts
2. **jsPDF for simplicity** - No browser dependency, good for simple documents
3. **Reuse browser instance** - For high volume, keep browser open between requests
4. **Use print stylesheets** - `@media print` and `@page` CSS rules
5. **Handle long content** - Use `page-break-before: always` for section breaks
6. **Test fonts** - Ensure fonts are available in production environment

## Common Issues

| Issue | Solution |
|-------|----------|
| Fonts missing | Install fonts in Docker, or use web fonts |
| CSS not applied | Use `waitUntil: 'networkidle'` for external resources |
| Page breaks wrong | Use CSS `page-break-*` properties |
| Slow generation | Reuse browser instance, increase Cloud Run memory |
| Images not loading | Use base64 inline images or wait for load |

---

[← PDF Processing](./pdf-processing.md) | [FastAPI →](./fastapi.md)
