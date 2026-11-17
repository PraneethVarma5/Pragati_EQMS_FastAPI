from dataclasses import dataclass
from datetime import datetime, timezone
import hashlib

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.audit import AuditAdmin, AuditAdminSession

_bearer = HTTPBearer(auto_error=False)


@dataclass(frozen=True)
class CurrentAuditAdmin:
    admin: AuditAdmin
    session: AuditAdminSession
    raw_token: str


def hash_session_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def get_current_audit_admin(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: Session = Depends(get_db),
) -> CurrentAuditAdmin:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Audit admin authentication is required.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token_hash = hash_session_token(credentials.credentials.strip())
    now = datetime.now(timezone.utc)

    row = db.execute(
        select(AuditAdminSession, AuditAdmin)
        .join(AuditAdmin, AuditAdmin.admin_id == AuditAdminSession.admin_id)
        .where(
            AuditAdminSession.token_hash == token_hash,
            AuditAdminSession.expires_at > now,
            AuditAdmin.active.is_(True),
        )
    ).first()

    if row is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Audit admin session is invalid or expired.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    session, admin = row
    return CurrentAuditAdmin(admin=admin, session=session, raw_token=credentials.credentials.strip())


def get_optional_current_audit_admin(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: Session = Depends(get_db),
) -> CurrentAuditAdmin | None:
    """Return None for anonymous requests; validate any supplied bearer token."""
    if credentials is None:
        return None

    if credentials.scheme.lower() != "bearer" or not credentials.credentials.strip():
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Audit admin session is invalid or expired.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = credentials.credentials.strip()
    token_hash = hash_session_token(token)
    now = datetime.now(timezone.utc)
    row = db.execute(
        select(AuditAdminSession, AuditAdmin)
        .join(AuditAdmin, AuditAdmin.admin_id == AuditAdminSession.admin_id)
        .where(
            AuditAdminSession.token_hash == token_hash,
            AuditAdminSession.expires_at > now,
            AuditAdmin.active.is_(True),
        )
    ).first()

    if row is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Audit admin session is invalid or expired.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    session, admin = row
    return CurrentAuditAdmin(admin=admin, session=session, raw_token=token)
