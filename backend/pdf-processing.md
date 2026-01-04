---
layout: default
title: PDF Processing (Reading)
---

# PDF Processing - Extract Content from PDFs

Convert PDFs to Markdown using Marker, MinerU, and other tools.

## Tool Comparison

| Tool | Speed | Table Quality | GPU Required | Best For |
|------|-------|---------------|--------------|----------|
| **Marker** | Fast | Good | Optional | Default choice |
| **MinerU** | Slow | Excellent | Recommended | Complex tables |
| **MarkItDown** | Very Fast | Basic | No | Simple PDFs |
| **Docling** | Medium | Good | Optional | IBM solution |
| **Gemini** | Fast | Good | No (API) | Vision-based extraction |

## Marker (Recommended)

### Installation

```bash
pip install marker-pdf

# Optional: For better performance
pip install torch torchvision  # GPU support
```

### Basic Usage

```python
from marker.converters.pdf import PdfConverter
from marker.models import create_model_dict

# Load models (do this once, reuse)
models = create_model_dict()
converter = PdfConverter(artifact_dict=models)

def convert_pdf(pdf_path: str) -> str:
    """Convert PDF to Markdown."""
    rendered = converter(pdf_path)
    return rendered.markdown

# Usage
markdown = convert_pdf('/path/to/document.pdf')
print(markdown)
```

### With Options

```python
from marker.converters.pdf import PdfConverter
from marker.models import create_model_dict
from marker.config.parser import ConfigParser

# Custom configuration
config = ConfigParser({
    'output_format': 'markdown',
    'page_range': [0, 10],  # First 10 pages only
    'languages': ['en'],
})

models = create_model_dict()
converter = PdfConverter(artifact_dict=models, config=config)

rendered = converter('/path/to/document.pdf')
```

### Batch Processing

```python
import os
from pathlib import Path
from marker.converters.pdf import PdfConverter
from marker.models import create_model_dict

def batch_convert(input_dir: str, output_dir: str):
    models = create_model_dict()
    converter = PdfConverter(artifact_dict=models)

    Path(output_dir).mkdir(parents=True, exist_ok=True)

    for pdf_file in Path(input_dir).glob('*.pdf'):
        try:
            rendered = converter(str(pdf_file))
            output_path = Path(output_dir) / f'{pdf_file.stem}.md'
            output_path.write_text(rendered.markdown)
            print(f'Converted: {pdf_file.name}')
        except Exception as e:
            print(f'Failed: {pdf_file.name} - {e}')

batch_convert('./pdfs', './markdown')
```

## MinerU (Best Table Quality)

### Installation

```bash
pip install mineru

# Requires GPU for best performance
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118
```

### Basic Usage

```python
from mineru import MinerU

def convert_with_mineru(pdf_path: str) -> str:
    """Convert PDF with MinerU for best table extraction."""
    miner = MinerU()
    result = miner.extract(pdf_path)
    return result.markdown

markdown = convert_with_mineru('/path/to/document.pdf')
```

## MarkItDown (Fast Fallback)

### Installation

```bash
pip install markitdown
```

### Basic Usage

```python
from markitdown import MarkItDown

def convert_with_markitdown(pdf_path: str) -> str:
    """Fast conversion, basic table support."""
    converter = MarkItDown()
    result = converter.convert(pdf_path)
    return result.text_content

markdown = convert_with_markitdown('/path/to/document.pdf')
```

## Gemini Vision (API-based)

Use Gemini for vision-based PDF extraction:

```typescript
async function extractPdfWithGemini(pdfBuffer: Buffer): Promise<string> {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{
          parts: [
            { text: 'Extract all text content from this PDF. Preserve table formatting using markdown tables.' },
            {
              inlineData: {
                mimeType: 'application/pdf',
                data: pdfBuffer.toString('base64')
              }
            }
          ]
        }],
        generationConfig: {
          temperature: 0.1,
          maxOutputTokens: 65536,
        }
      })
    }
  );

  const result = await response.json();
  return result.candidates?.[0]?.content?.parts?.[0]?.text || '';
}
```

## Fallback Pipeline

Use multiple tools with fallback:

```python
from pathlib import Path
import logging

logger = logging.getLogger(__name__)

class PDFConverter:
    def __init__(self):
        self.marker_converter = None
        self.mineru_converter = None

    def _init_marker(self):
        if self.marker_converter is None:
            from marker.converters.pdf import PdfConverter
            from marker.models import create_model_dict
            models = create_model_dict()
            self.marker_converter = PdfConverter(artifact_dict=models)

    def _init_mineru(self):
        if self.mineru_converter is None:
            from mineru import MinerU
            self.mineru_converter = MinerU()

    def convert(self, pdf_path: str) -> tuple[str, str]:
        """
        Convert PDF to markdown.
        Returns (markdown, method_used).
        """
        # Try Marker first
        try:
            self._init_marker()
            rendered = self.marker_converter(pdf_path)
            return rendered.markdown, 'marker'
        except Exception as e:
            logger.warning(f'Marker failed: {e}')

        # Fall back to MinerU
        try:
            self._init_mineru()
            result = self.mineru_converter.extract(pdf_path)
            return result.markdown, 'mineru'
        except Exception as e:
            logger.warning(f'MinerU failed: {e}')

        # Last resort: MarkItDown
        try:
            from markitdown import MarkItDown
            converter = MarkItDown()
            result = converter.convert(pdf_path)
            return result.text_content, 'markitdown'
        except Exception as e:
            logger.error(f'All converters failed: {e}')
            raise RuntimeError(f'Could not convert {pdf_path}')

# Usage
converter = PDFConverter()
markdown, method = converter.convert('/path/to/document.pdf')
print(f'Converted with: {method}')
```

## GCS Integration

Download from GCS, convert, upload result:

```python
from google.cloud import storage
from pathlib import Path
import tempfile

def convert_gcs_pdf(bucket_name: str, pdf_path: str, output_path: str):
    """Download PDF from GCS, convert, upload markdown."""
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)

    with tempfile.TemporaryDirectory() as tmpdir:
        # Download PDF
        local_pdf = Path(tmpdir) / 'input.pdf'
        bucket.blob(pdf_path).download_to_filename(str(local_pdf))

        # Convert
        converter = PDFConverter()
        markdown, method = converter.convert(str(local_pdf))

        # Upload markdown
        bucket.blob(output_path).upload_from_string(
            markdown,
            content_type='text/markdown'
        )

    return method

# Usage
method = convert_gcs_pdf(
    'my-bucket',
    'raw/company123/report.pdf',
    'markdown/company123/report.md'
)
```

## FastAPI Service

Expose PDF conversion as an API:

```python
# pdf_service.py
from fastapi import FastAPI, UploadFile, HTTPException
from fastapi.responses import PlainTextResponse
import tempfile
from pathlib import Path

app = FastAPI()
converter = PDFConverter()

@app.post('/convert', response_class=PlainTextResponse)
async def convert_pdf(file: UploadFile):
    if not file.filename.endswith('.pdf'):
        raise HTTPException(400, 'File must be a PDF')

    with tempfile.TemporaryDirectory() as tmpdir:
        pdf_path = Path(tmpdir) / 'input.pdf'

        # Save uploaded file
        content = await file.read()
        pdf_path.write_bytes(content)

        # Convert
        try:
            markdown, method = converter.convert(str(pdf_path))
            return markdown
        except Exception as e:
            raise HTTPException(500, f'Conversion failed: {e}')

@app.get('/health')
async def health():
    return {'status': 'healthy'}
```

Run with:
```bash
uvicorn pdf_service:app --host 0.0.0.0 --port 8000
```

## Dockerfile for PDF Service

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    poppler-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000
CMD ["uvicorn", "pdf_service:app", "--host", "0.0.0.0", "--port", "8000"]
```

requirements.txt:
```
fastapi
uvicorn
marker-pdf
markitdown
google-cloud-storage
```

## Performance Tips

1. **Reuse models** - Load Marker models once, reuse for all conversions
2. **Use GPU** - Significantly faster for Marker and MinerU
3. **Batch process** - Convert multiple files in sequence with same model instance
4. **Page limits** - For large PDFs, process specific page ranges
5. **Memory** - Close/cleanup between large files to prevent memory leaks

## Common Issues

| Issue | Solution |
|-------|----------|
| Out of memory | Reduce page range, use smaller batches |
| Slow conversion | Use GPU, try MarkItDown for simple PDFs |
| Bad table extraction | Use MinerU instead of Marker |
| Missing fonts | Install system fonts, use Docker |

---

[← Next.js API](./nextjs-api.md) | [PDF Creation →](./pdf-creation.md)
