# API Response Format Standardization (Success & Error) + Correct HTTP Status Codes
 
## 1. Why Standardize?
 
- Consistent structure so frontend/client can parse and handle every endpoint the same way
- Avoid an ad-hoc response shape per endpoint, which makes error handling on the client messy
- Easier debugging and logging when every response follows one envelope (lớp bao bọc chuẩn hoá cho response)
## 2. Success Response Format
 
Common envelope pattern:
 
```json
{
  "success": true,
  "data": { ... },
  "meta": { ... }
}
```
 
### 2.1 Pydantic generic response model
 
```python
from typing import Generic, TypeVar, Optional
from pydantic import BaseModel
 
T = TypeVar("T")
 
class SuccessResponse(BaseModel, Generic[T]):
    success: bool = True
    data: T
    meta: Optional[dict] = None
```
 
### 2.2 FastAPI usage
 
```python
from fastapi import FastAPI
from pydantic import BaseModel
 
app = FastAPI()
 
class JobOut(BaseModel):
    id: int
    title: str
 
@app.get("/jobs/{job_id}", response_model=SuccessResponse[JobOut])
def get_job(job_id: int):
    job = get_job_by_id(job_id)
    return SuccessResponse(data=job)
```
 
## 3. Error Response Format
 
Common envelope:
 
```json
{
  "success": false,
  "error": {
    "code": "JOB_NOT_FOUND",
    "message": "Job with id 123 not found",
    "details": null
  }
}
```
 
- `code`: application-level error code (mã lỗi ở tầng ứng dụng, khác với HTTP status code). The client uses this to distinguish specific error cases (e.g. show a specific message per code).
- `message`: human-readable message (thông báo dễ hiểu cho người dùng/dev)
- `details`: optional extra debugging info, e.g. field-level validation errors
### 3.1 Custom exception + handler in FastAPI
 
```python
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
 
class AppException(Exception):
    def __init__(self, code: str, message: str, status_code: int = 400, details=None):
        self.code = code
        self.message = message
        self.status_code = status_code
        self.details = details
 
app = FastAPI()
 
@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "error": {
                "code": exc.code,
                "message": exc.message,
                "details": exc.details,
            },
        },
    )
 
@app.get("/jobs/{job_id}")
def get_job(job_id: int):
    job = find_job(job_id)
    if not job:
        raise AppException(
            code="JOB_NOT_FOUND",
            message=f"Job with id {job_id} not found",
            status_code=404,
        )
    return SuccessResponse(data=job)
```
 
Exception handler (bộ xử lý ngoại lệ tập trung) lets every endpoint raise a typed exception instead of manually building the error JSON each time.
 
### 3.2 Handling validation errors (Pydantic/FastAPI)
 
```python
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
 
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=422,
        content={
            "success": False,
            "error": {
                "code": "VALIDATION_ERROR",
                "message": "Invalid request data",
                "details": exc.errors(),
            },
        },
    )
```
 
## 4. Correct HTTP Status Code Usage
 
The HTTP status code reflects the result at the transport/protocol layer, while `error.code` above reflects the result at the application layer. Do not mix the two purposes.
 
| Status | Meaning | When to use |
|---|---|---|
| 200 OK | Success | GET/PUT/PATCH succeeded and returns data |
| 201 Created | Resource created | POST successfully created a new resource |
| 204 No Content | Success, no body | DELETE succeeded |
| 400 Bad Request | Invalid request | Generic invalid input/logic |
| 401 Unauthorized | Not authenticated | Missing/invalid token, not logged in |
| 403 Forbidden | Not allowed | Authenticated but insufficient permission |
| 404 Not Found | Resource not found | The resource does not exist |
| 409 Conflict | Data conflict | e.g. email already exists on registration |
| 413 Payload Too Large | Body/file too large | Upload vượt quá giới hạn size cho phép |
| 415 Unsupported Media Type | Wrong content type | e.g. gửi `text/plain` khi endpoint chỉ nhận `application/json` |
| 422 Unprocessable Entity | Cannot process data (usually validation) | FastAPI's default for Pydantic validation errors |
| 429 Too Many Requests | Rate limited | Client exceeded the rate limit |
| 500 Internal Server Error | Server error | Unhandled exception (a bug) |
| 502 Bad Gateway | Lỗi ở gateway/upstream | Reverse proxy (Nginx) không nhận được response hợp lệ từ backend |
| 503 Service Unavailable | Server tạm thời không phục vụ được | Đang deploy, maintenance, hoặc quá tải |
| 504 Gateway Timeout | Upstream timeout | Backend xử lý quá lâu, gateway/proxy timeout trước |
 
## 5. Common Pitfalls
 
- Always returning `200 OK` with `"success": false` in the body. The client then has to parse the body to know it failed. Use the correct HTTP status code together with `success: false`, don't rely on only one of the two.
- Confusing a validation error (422) with a business-logic error (400/409).
- Inconsistent error shape across endpoints: some use `error`, some use `errors`, some use a completely different `message` structure.
- Leaking stack traces or raw internal exception messages in the response in production (rò rỉ thông tin nội bộ, có thể gây rủi ro bảo mật).
