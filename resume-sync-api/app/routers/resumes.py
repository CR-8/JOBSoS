from fastapi import APIRouter, HTTPException, Depends, Body
import httpx
import os
from datetime import datetime
from sqlalchemy.orm import Session
from ..models import ResumeRecord, get_db

router = APIRouter()

# Helper to call Reactive Resume API – placeholder; expects an endpoint that returns resume list.
async def fetch_rr_resumes() -> list[dict]:
    rr_url = f"{os.getenv('REACTIVE_RESUME_URL', 'http://reactive-resume:3000')}/api/resumes"
    api_key = os.getenv('REACTIVE_RESUME_API_KEY')
    headers = {"Authorization": f"Bearer {api_key}"} if api_key else {}
    async with httpx.AsyncClient() as client:
        resp = await client.get(rr_url, headers=headers, timeout=10)
        resp.raise_for_status()
        return resp.json().get('resumes', [])

@router.get("/")
async def list_resumes(db: Session = Depends(get_db)):
    # Pull from local DB first; optionally sync with Reactive Resume on request.
    records = db.query(ResumeRecord).all()
    return [r.to_dict() for r in records]

@router.get("/{resume_id}")
async def get_resume(resume_id: str, db: Session = Depends(get_db)):
    rec = db.query(ResumeRecord).filter(ResumeRecord.id == resume_id).first()
    if not rec:
        raise HTTPException(status_code=404, detail="Resume not found")
    return rec.to_dict()

@router.post("/sync/{resume_id}")
async def sync_resume(resume_id: str, db: Session = Depends(get_db)):
    # In a real implementation, fetch resume data from Reactive Resume and push to JobOps.
    # Here we just mark the record as synced.
    rec = db.query(ResumeRecord).filter(ResumeRecord.id == resume_id).first()
    if not rec:
        raise HTTPException(status_code=404, detail="Resume not found")
    rec.synced_at = datetime.utcnow()
    db.commit()
    return {"status": "synced", "resume_id": resume_id}

@router.post("/default")
async def set_default(body: dict = Body(...), db: Session = Depends(get_db)):
    # Expect {"id": "<resume_id>"}
    resume_id = body.get("id")
    if not resume_id:
        raise HTTPException(status_code=400, detail="Missing 'id'")
    # Unset all
    db.query(ResumeRecord).update({ResumeRecord.is_default: False})
    # Set new default
    rec = db.query(ResumeRecord).filter(ResumeRecord.id == resume_id).first()
    if not rec:
        raise HTTPException(status_code=404, detail="Resume not found")
    rec.is_default = True
    db.commit()
    return {"status": "default_set", "id": resume_id}

# Future AI placeholders – return 501
@router.post("/tailor", include_in_schema=False)
async def tailor_resume():
    raise HTTPException(status_code=501, detail="Not implemented")

@router.post("/cover-letter", include_in_schema=False)
async def cover_letter():
    raise HTTPException(status_code=501, detail="Not implemented")

@router.post("/ats-score", include_in_schema=False)
async def ats_score():
    raise HTTPException(status_code=501, detail="Not implemented")

@router.post("/job-match", include_in_schema=False)
async def job_match():
    raise HTTPException(status_code=501, detail="Not implemented")
