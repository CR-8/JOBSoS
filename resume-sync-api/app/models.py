from datetime import datetime
from sqlalchemy import Column, String, DateTime, Boolean, Text, create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
import os

Base = declarative_base()

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@postgres:5432/resume_sync")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


class ResumeRecord(Base):
    __tablename__ = "resume_records"

    id = Column(String, primary_key=True)
    title = Column(String, nullable=False)
    remote_id = Column(String, nullable=False, comment="ID in Reactive Resume")
    version = Column(String, nullable=False)
    is_default = Column(Boolean, default=False)
    synced_at = Column(DateTime, default=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "title": self.title,
            "remote_id": self.remote_id,
            "version": self.version,
            "is_default": self.is_default,
            "synced_at": self.synced_at.isoformat() if self.synced_at else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


def init_db():
    Base.metadata.create_all(bind=engine)
