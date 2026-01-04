---
layout: default
title: FastAPI
---

# FastAPI

Modern Python web framework for building APIs.

## Installation

```bash
pip install fastapi uvicorn[standard]
```

## Basic Application

```python
# main.py
from fastapi import FastAPI

app = FastAPI(title="My API", version="1.0.0")

@app.get("/")
async def root():
    return {"message": "Hello, World!"}

@app.get("/items/{item_id}")
async def get_item(item_id: int):
    return {"item_id": item_id}
```

Run:
```bash
uvicorn main:app --reload --port 8000
```

## Request/Response Models

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

app = FastAPI()

# Request model
class ItemCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    price: float = Field(..., gt=0)
    description: Optional[str] = None
    tags: list[str] = []

# Response model
class Item(BaseModel):
    id: str
    name: str
    price: float
    description: Optional[str]
    tags: list[str]
    created_at: datetime

# In-memory storage (use Firestore in production)
items_db: dict[str, Item] = {}

@app.post("/items", response_model=Item, status_code=201)
async def create_item(item: ItemCreate):
    item_id = str(len(items_db) + 1)
    db_item = Item(
        id=item_id,
        created_at=datetime.utcnow(),
        **item.model_dump()
    )
    items_db[item_id] = db_item
    return db_item

@app.get("/items/{item_id}", response_model=Item)
async def get_item(item_id: str):
    if item_id not in items_db:
        raise HTTPException(status_code=404, detail="Item not found")
    return items_db[item_id]

@app.get("/items", response_model=list[Item])
async def list_items(skip: int = 0, limit: int = 10):
    items = list(items_db.values())
    return items[skip:skip + limit]
```

## Query Parameters

```python
from fastapi import Query

@app.get("/search")
async def search_items(
    q: str = Query(..., min_length=1, description="Search query"),
    category: Optional[str] = Query(None, description="Filter by category"),
    min_price: float = Query(0, ge=0),
    max_price: float = Query(10000, le=100000),
    limit: int = Query(10, ge=1, le=100),
):
    # Filter logic...
    return {"query": q, "category": category, "price_range": [min_price, max_price]}
```

## Path Parameters

```python
from enum import Enum

class Category(str, Enum):
    electronics = "electronics"
    clothing = "clothing"
    food = "food"

@app.get("/categories/{category}/items")
async def get_items_by_category(category: Category):
    return {"category": category, "items": []}
```

## Request Body + Path + Query

```python
@app.put("/items/{item_id}")
async def update_item(
    item_id: str,                    # Path parameter
    item: ItemCreate,                # Request body
    notify: bool = Query(False),     # Query parameter
):
    if item_id not in items_db:
        raise HTTPException(status_code=404, detail="Item not found")

    updated = Item(
        id=item_id,
        created_at=items_db[item_id].created_at,
        **item.model_dump()
    )
    items_db[item_id] = updated

    if notify:
        # Send notification...
        pass

    return updated
```

## File Uploads

```python
from fastapi import UploadFile, File

@app.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    # Validate
    if not file.filename.endswith('.pdf'):
        raise HTTPException(400, "Only PDF files allowed")

    if file.size > 10 * 1024 * 1024:  # 10MB
        raise HTTPException(400, "File too large")

    # Read content
    content = await file.read()

    # Process or save...
    return {
        "filename": file.filename,
        "size": len(content),
        "content_type": file.content_type
    }

@app.post("/upload-multiple")
async def upload_multiple(files: list[UploadFile] = File(...)):
    return {"filenames": [f.filename for f in files]}
```

## Dependency Injection

```python
from fastapi import Depends
from google.cloud import firestore

# Database dependency
def get_db():
    db = firestore.Client()
    try:
        yield db
    finally:
        pass  # Cleanup if needed

@app.get("/users/{user_id}")
async def get_user(user_id: str, db: firestore.Client = Depends(get_db)):
    doc = db.collection('users').document(user_id).get()
    if not doc.exists:
        raise HTTPException(404, "User not found")
    return doc.to_dict()
```

## Authentication

```python
from fastapi import Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import firebase_admin
from firebase_admin import auth, credentials

# Initialize Firebase Admin
if not firebase_admin._apps:
    firebase_admin.initialize_app()

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Security(security)
):
    try:
        decoded = auth.verify_id_token(credentials.credentials)
        return decoded
    except Exception:
        raise HTTPException(401, "Invalid token")

@app.get("/me")
async def get_me(user: dict = Depends(get_current_user)):
    return {"uid": user["uid"], "email": user.get("email")}

@app.get("/protected")
async def protected_route(user: dict = Depends(get_current_user)):
    return {"message": f"Hello, {user['uid']}!"}
```

## Error Handling

```python
from fastapi import Request
from fastapi.responses import JSONResponse

class AppException(Exception):
    def __init__(self, status_code: int, detail: str):
        self.status_code = status_code
        self.detail = detail

@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": exc.detail}
    )

@app.exception_handler(Exception)
async def generic_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error"}
    )
```

## Background Tasks

```python
from fastapi import BackgroundTasks

def send_email(email: str, message: str):
    # Simulate sending email
    import time
    time.sleep(5)
    print(f"Email sent to {email}: {message}")

@app.post("/register")
async def register(email: str, background_tasks: BackgroundTasks):
    # Create user...
    background_tasks.add_task(send_email, email, "Welcome!")
    return {"message": "User registered"}
```

## CORS

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yourdomain.com", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## Routers (Modular Structure)

```python
# routers/users.py
from fastapi import APIRouter

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/")
async def list_users():
    return []

@router.get("/{user_id}")
async def get_user(user_id: str):
    return {"id": user_id}

# main.py
from fastapi import FastAPI
from routers import users, items

app = FastAPI()
app.include_router(users.router)
app.include_router(items.router)
```

## Dockerfile

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8080
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
```

requirements.txt:
```
fastapi
uvicorn[standard]
firebase-admin
google-cloud-firestore
pydantic
```

## Deploy to Cloud Run

```bash
# Build and deploy
gcloud builds submit --tag gcr.io/PROJECT_ID/my-api --project PROJECT_ID

gcloud run deploy my-api \
  --image gcr.io/PROJECT_ID/my-api:latest \
  --project PROJECT_ID \
  --region us-west1 \
  --allow-unauthenticated
```

## OpenAPI Documentation

FastAPI automatically generates:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`
- OpenAPI JSON: `http://localhost:8000/openapi.json`

---

[← Python PDF](./python-pdf.md) | [Back to Backend Index](./index.md)
