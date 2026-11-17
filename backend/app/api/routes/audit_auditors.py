from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.api.deps import CurrentAuditAdmin, get_current_audit_admin
from app.db.session import get_db
from app.models.audit import AuditAuditor
from app.schemas.audit import AuditAuditorCreate, AuditAuditorResponse, AuditAuditorUpdate

router = APIRouter(prefix="/audit/auditors", tags=["Audit Auditor Management"])


def _check_duplicates(
    db: Session,
    employee_id: str,
    email: str,
    exclude_id: UUID | None = None,
) -> None:
    employee_query = select(AuditAuditor.auditor_id).where(
        func.lower(func.trim(AuditAuditor.employee_id)) == employee_id.lower()
    )
    email_query = select(AuditAuditor.auditor_id).where(
        func.lower(func.trim(AuditAuditor.email)) == email.lower()
    )

    if exclude_id is not None:
        employee_query = employee_query.where(AuditAuditor.auditor_id != exclude_id)
        email_query = email_query.where(AuditAuditor.auditor_id != exclude_id)

    if db.scalar(employee_query.limit(1)) is not None:
        raise HTTPException(status_code=409, detail="Employee ID already exists.")
    if db.scalar(email_query.limit(1)) is not None:
        raise HTTPException(status_code=409, detail="Email already exists.")


@router.get("", response_model=list[AuditAuditorResponse])
def list_auditors(
    _current: CurrentAuditAdmin = Depends(get_current_audit_admin),
    db: Session = Depends(get_db),
):
    return list(
        db.scalars(
            select(AuditAuditor).order_by(AuditAuditor.auditor_name.asc())
        ).all()
    )


@router.post(
    "",
    response_model=AuditAuditorResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_auditor(
    payload: AuditAuditorCreate,
    _current: CurrentAuditAdmin = Depends(get_current_audit_admin),
    db: Session = Depends(get_db),
):
    _check_duplicates(db, payload.employee_id, payload.email)

    now = datetime.now(timezone.utc)
    auditor = AuditAuditor(
        auditor_name=payload.auditor_name.strip(),
        employee_id=payload.employee_id.strip(),
        email=payload.email.strip().lower(),
        active=payload.active,
        created_at=now,
        updated_at=now,
    )
    db.add(auditor)

    try:
        db.commit()
        db.refresh(auditor)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="Auditor conflicts with an existing record.")

    return auditor


@router.put("/{auditor_id}", response_model=AuditAuditorResponse)
def update_auditor(
    auditor_id: UUID,
    payload: AuditAuditorUpdate,
    _current: CurrentAuditAdmin = Depends(get_current_audit_admin),
    db: Session = Depends(get_db),
):
    auditor = db.get(AuditAuditor, auditor_id)
    if auditor is None:
        raise HTTPException(status_code=404, detail="Auditor not found.")

    _check_duplicates(
        db, payload.employee_id, payload.email, exclude_id=auditor_id
    )

    auditor.auditor_name = payload.auditor_name.strip()
    auditor.employee_id = payload.employee_id.strip()
    auditor.email = payload.email.strip().lower()
    auditor.active = payload.active
    auditor.updated_at = datetime.now(timezone.utc)

    try:
        db.commit()
        db.refresh(auditor)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="Auditor conflicts with an existing record.")

    return auditor


@router.delete("/{auditor_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_auditor(
    auditor_id: UUID,
    _current: CurrentAuditAdmin = Depends(get_current_audit_admin),
    db: Session = Depends(get_db),
):
    auditor = db.get(AuditAuditor, auditor_id)
    if auditor is None:
        raise HTTPException(status_code=404, detail="Auditor not found.")

    db.delete(auditor)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="This auditor is assigned to an audit schedule and cannot be deleted.",
        )

    return Response(status_code=status.HTTP_204_NO_CONTENT)
