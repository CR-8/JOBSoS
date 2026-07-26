import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import resumes
from .models import init_db


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield


app = FastAPI(title="CareerHub Resume Sync API", version="0.1.0", lifespan=lifespan)

# Allow dashboard (same domain) to call API. Adjust origins if required.
app.add_middleware(
    CORSMiddleware,
    allow_origins=[os.getenv("NEXT_PUBLIC_DOMAIN", "http://localhost")],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(resumes.router, prefix="/resumes", tags=["Resumes"])

@app.get("/health")
def health_check():
    return {"status": "ok"}
