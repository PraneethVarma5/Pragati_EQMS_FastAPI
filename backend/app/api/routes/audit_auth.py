from datetime import datetime, timedelta, timezone
import secrets
import uuid

import bcrypt
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.session import get_db
from app.models.audit import AuditAdmin, AuditAdminSession
from app.schemas.audit import AuditLoginRequest, AuditLoginResponse, AuditLogoutResponse
from app.api.deps import CurrentAuditAdmin, get_current_audit_admin, hash_session_token

router = APIRouter(prefix="/audit/auth", tags=["Audit Authentication"])


def _verify_existing_pgcrypto_bcrypt(password: str, stored_hash: str) -> bool:
    """Verify bcrypt hashes created by PostgreSQL pgcrypto crypt(..., gen_salt('bf'))."""
    try:
        normalized = stored_hash
        if normalized.startswith("$2y$"):
            normalized = "$2b$" + normalized[4:]
        return bcrypt.checkpw(password.encode("utf-8"), normalized.encode("utf-8"))
    except (ValueError, TypeError):
        return False


@router.post("/login", response_model=AuditLoginResponse)
def login(payload: AuditLoginRequest, db: Session = Depends(get_db)):
    admin = db.scalar(
        select(AuditAdmin).where(
            func.lower(AuditAdmin.email) == payload.email,
            AuditAdmin.active.is_(True),
        )
    )

    if admin is None or not _verify_existing_pgcrypto_bcrypt(
        payload.password, admin.password_hash
    ):
        # Do not reveal whether the email or password was incorrect.
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid admin email or password.",
        )

    raw_token = secrets.token_urlsafe(32)
    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(
        minutes=get_settings().audit_admin_session_minutes
    )

    session = AuditAdminSession(
        session_id=uuid.uuid4(),
        admin_id=admin.admin_id,
        token_hash=hash_session_token(raw_token),
        expires_at=expires_at,
        created_at=now,
    )
    db.add(session)
    db.commit()

    return AuditLoginResponse(
        admin_id=admin.admin_id,
        email=admin.email,
        session_token=raw_token,
        expires_at=expires_at,
    )


@router.post("/logout", response_model=AuditLogoutResponse)
def logout(
    current: CurrentAuditAdmin = Depends(get_current_audit_admin),
    db: Session = Depends(get_db),
):
    db.delete(current.session)
    db.commit()
    return AuditLogoutResponse()
