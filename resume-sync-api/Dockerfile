# =============================================================================
# Resume Sync API - FastAPI
# =============================================================================
FROM python:3.13-slim-bookworm AS base
WORKDIR /app

# Build stage – install dependencies
FROM base AS builder
COPY requirements.txt ./
RUN python -m pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Runtime stage
FROM base AS runtime
COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages
COPY . /app
ENV PYTHONUNBUFFERED=1
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]