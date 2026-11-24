from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.api.routes import audit_auth, audit_auditors, audit_operations, dcc
from app.core.config import get_settings
from app.db.session import engine
from app.api.routes import ccr


settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    description="FastAPI backend for the EQMS application.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=False,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)

app.include_router(audit_auth.router, prefix=settings.api_v1_prefix)
app.include_router(audit_auditors.router, prefix=settings.api_v1_prefix)
app.include_router(audit_operations.router, prefix=settings.api_v1_prefix)
app.include_router(dcc.router, prefix=settings.api_v1_prefix)
app.include_router(ccr.router,prefix=settings.api_v1_prefix)

@app.get("/health")
def health():
    return {"status": "ok", "service": settings.app_name}


@app.get("/health/database")
def database_health():
    with Session(engine) as db:
        db.execute(text("SELECT 1"))
    return {"status": "ok", "database": "connected"}
