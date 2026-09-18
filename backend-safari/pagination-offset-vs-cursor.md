# Pagination: Offset-based vs Cursor-based

## 1. Why Pagination?

Returning all rows of a large dataset in a single response is expensive: slow query, high memory usage, huge payload size. Pagination (phân trang) splits data into smaller pages/chunks so the client only fetches what it needs.

## 2. Offset-based Pagination

Concept: use `LIMIT` and `OFFSET` (SQL) to skip N rows and return the next M rows.

- `limit`: number of items per page (số item mỗi trang)
- `offset`: number of items to skip (số item bỏ qua), usually `= (page - 1) * limit`

### 2.1 SQL example

```sql
SELECT * FROM jobs
ORDER BY id
LIMIT 10 OFFSET 20;
```

### 2.2 FastAPI example (SQLAlchemy)

```python
from math import ceil
from fastapi import FastAPI, Query, Depends
from sqlalchemy import select, func
from sqlalchemy.orm import Session

app = FastAPI()

@app.get("/jobs")
def list_jobs(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db),
):
    offset = (page - 1) * limit
    stmt = select(Job).order_by(Job.id).offset(offset).limit(limit)
    items = db.execute(stmt).scalars().all()
    total = db.execute(select(func.count()).select_from(Job)).scalar()

    return {
        "data": items,
        "pagination": {
            "page": page,
            "limit": limit,
            "total": total,
            "total_pages": ceil(total / limit),
        },
    }
```

### 2.3 Pros / Cons

Pros:
- Simple to implement, easy to understand
- Supports "jump to page N" (nhảy tới trang bất kỳ), can show total pages

Cons:
- Performance degrades with large offset. `OFFSET 1000000` still has to scan through and discard that many rows first.
- Inconsistent results if data changes between requests. If rows are inserted/deleted between two calls, items can be skipped or duplicated across pages. This is often called "page drift".

## 3. Cursor-based Pagination

Concept: instead of a position (offset), use a cursor (con trỏ - a pointer marking a position) that references the last item of the previous page. The cursor is usually an encoded value of a unique, sortable column (e.g. `id`, `created_at`).

- `cursor`: an opaque token (token không thể đọc/giải mã trực tiếp, thường base64 encode) pointing to a specific position
- Query pattern: `WHERE id > :cursor ORDER BY id LIMIT :limit`

### 3.1 SQL example

```sql
SELECT * FROM jobs
WHERE id > 120
ORDER BY id
LIMIT 10;
```

### 3.2 FastAPI example

```python
import base64
from typing import Optional
from fastapi import FastAPI, Query, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

app = FastAPI()

def encode_cursor(value: int) -> str:
    return base64.urlsafe_b64encode(str(value).encode()).decode()

def decode_cursor(cursor: str) -> int:
    return int(base64.urlsafe_b64decode(cursor.encode()).decode())

@app.get("/jobs")
def list_jobs(
    cursor: Optional[str] = None,
    limit: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db),
):
    stmt = select(Job).order_by(Job.id).limit(limit + 1)
    if cursor:
        last_id = decode_cursor(cursor)
        stmt = stmt.where(Job.id > last_id)

    items = db.execute(stmt).scalars().all()

    has_next = len(items) > limit
    items = items[:limit]
    next_cursor = encode_cursor(items[-1].id) if has_next else None

    return {
        "data": items,
        "pagination": {
            "next_cursor": next_cursor,
            "has_next": has_next,
        },
    }
```

Note: the query fetches `limit + 1` rows so we know whether a next page exists, without running an extra `COUNT` query.

### 3.3 Pros / Cons

Pros:
- Stable, consistent performance regardless of dataset size (không bị chậm dần khi data lớn)
- Stable results even when data is inserted/deleted (immune to page drift)

Cons:
- Cannot jump to an arbitrary page, only next/prev
- Slightly more complex: requires encoding/decoding the cursor, and the sort column must be unique and indexed

## 4. Comparison Table

| Criteria | Offset-based | Cursor-based |
|---|---|---|
| Implementation | Simple | Medium |
| Performance on large data | Degrades | Stable |
| Jump to specific page | Yes | No |
| Consistency when data changes | Can skip/duplicate | Stable |
| Best for | Admin dashboard, small/medium dataset | Infinite scroll, feed, large dataset |

## 5. When to use which

- Use **offset-based** when: dataset is small/medium and the user needs to jump to a specific page (e.g. an admin panel).
- Use **cursor-based** when: dataset is large, performance must stay stable, and the UI is infinite-scroll (e.g. newsfeed, notification list, log stream).

## 6. Common Pitfalls

- Offset-based: sort column is not unique -> duplicated or skipped records across pages.
- Cursor-based: forgetting to encode the cursor -> internal structure/ID leaks through the API response.
- Both: missing a deterministic `ORDER BY` -> pagination results become inconsistent between calls.
| Deterministic order | Thứ tự sắp xếp cố định, không đổi giữa các lần query |
