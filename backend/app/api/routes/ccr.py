from __future__ import annotations
from pathlib import Path
from fastapi.responses import FileResponse

"""CCR API routes for EQMS.

This module is intentionally self-contained, like app/api/routes/dcc.py.
It uses the existing PostgreSQL CCR schema and existing CCR auth/admin
functions. It does not import or modify DCC or Audit authentication.

Mount from main.py:
    from app.api.routes import ccr
    app.include_router(ccr.router, prefix=settings.api_v1_prefix)

All table and column identifiers below are server-side allow-lists. Values
are always bound parameters; client input is never interpolated as SQL.
"""

import hashlib
import json
from datetime import date, datetime, timezone
from typing import Any

from fastapi import APIRouter, Depends, File, Form, Header, HTTPException, Query, UploadFile
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db.session import get_db

router = APIRouter(prefix="/ccr", tags=["CCR"])


TABLE_COLUMNS: dict[str, set[str]] = {
    "ccr_cases": {
        "id", "ccr_number", "status", "current_stage", "complaint_date",
        "complaint_source", "customer_name", "team_leader", "group_name",
        "customer_contact_name", "customer_contact_position",
        "customer_contact_company", "customer_part_number",
        "supplier_part_number", "part_description", "part_no",
        "complaint_description", "qty", "problem_description",
        "customer_location", "detected_date", "detected_by", "created_at",
        "updated_at", "created_by", "created_by_name", "created_by_email",
        "closed_at", "closed_by", "closure_remarks", "target_closure_date",
    },
    "ccr_assignments": {
        "id", "ccr_id", "activity", "dri", "due_date", "done_date",
        "status", "remarks", "created_at", "updated_at",
    },
    "ccr_containment": {
        "id", "ccr_id", "sorting_activity", "sorting_learnings",
        "customer_protection_action", "recover_prq_schedule",
        "first_certified_good_shipment", "target_eta", "status",
        "created_at", "updated_at",
    },
    "ccr_containment_sorting": {
        "id", "containment_id", "location", "qty_ng", "qty_sorted",
        "sorting_date", "dri", "created_at", "updated_at",
    },
        "ccr_attachments": {
        "id", "ccr_id", "attachment_type", "title", "description",
        "storage_bucket", "storage_path", "original_file_name",
        "mime_type", "file_size", "uploaded_at", "is_deleted",
    },
    "ccr_fishbone_categories": {
        "id", "name", "description", "display_order", "is_active",
        "created_at", "updated_at",
    },
    "ccr_fishbone_causes": {
        "id", "ccr_id", "category_id", "cause_text", "display_order",
        "created_by", "updated_by", "created_at", "updated_at",
    },
    "ccr_root_cause_validations": {
        "id", "fishbone_cause_id", "validation_text", "relevance",
        "validated_by", "validated_at", "created_at", "updated_at",
    },
    "ccr_why_analyses": {
        "id", "validation_id", "analysis_type", "potential_root_cause",
        "created_at", "updated_at",
    },
    "ccr_why_steps": {
        "id", "analysis_id", "why_number", "why_text",
        "verification_text", "evidence_available", "created_at", "updated_at",
    },
   "ccr_corrective_actions": {
    "id",
    "ccr_id",
    "root_cause_validation_id",
    "validation_id",
    "analysis_id",
    "cause_id",
    "problem_statement",
    "result_before",
    "result_after",
    "action_type",
    "action_description",
    "corrective_action",
    "preventive_action",
    "action",
    "dri",
    "owner",
    "result_before",
    "result_after",
    "due_date",
    "target_date",
    "completion_date",
    "done_date",
    "status",
    "remarks",
    "effectiveness",
    "effectiveness_remarks",
    "created_at",
    "updated_at",
    "created_by",
    "updated_by",
},
    "ccr_teams": {
        "id", "team_leader_name", "is_active", "created_at", "updated_at",
    },
    "ccr_team_members": {
        "id", "team_id", "member_name", "created_at", "updated_at",
    },
    "ccr_case_team_members": {
        "id", "ccr_id", "team_id", "team_leader_name", "member_name",
        "created_at",
    },
    "ccr_workflow_stages": {
        "id", "stage_key", "stage_name", "display_order", "is_active",
        "created_at", "updated_at",
    },
}
WRITE_COLUMNS: dict[str, set[str]] = {
    "cases": TABLE_COLUMNS["ccr_cases"] - {
        "id", "ccr_number", "created_at", "updated_at", "closed_at", "closed_by",
    },
    "assignments": TABLE_COLUMNS["ccr_assignments"] - {"id", "created_at", "updated_at"},
    "containment": TABLE_COLUMNS["ccr_containment"] - {"id", "created_at", "updated_at"},
    "sorting": TABLE_COLUMNS["ccr_containment_sorting"] - {"id", "created_at", "updated_at"},
    "fishbone-causes": TABLE_COLUMNS["ccr_fishbone_causes"] - {"id", "created_at", "updated_at", "created_by", "updated_by"},
    "validations": TABLE_COLUMNS["ccr_root_cause_validations"] - {"id", "created_at", "updated_at", "validated_by", "validated_at"},
    "why-analyses": TABLE_COLUMNS["ccr_why_analyses"] - {"id", "created_at", "updated_at"},
    "why-steps": TABLE_COLUMNS["ccr_why_steps"] - {"id", "created_at", "updated_at"},
    "corrective-actions": TABLE_COLUMNS["ccr_corrective_actions"] - {"id", "created_at", "updated_at", "created_by", "updated_by"},
    "teams": TABLE_COLUMNS["ccr_teams"] - {"id", "created_at", "updated_at"},
    "team-members": TABLE_COLUMNS["ccr_team_members"] - {"id", "created_at", "updated_at"},
    "case-team-members": TABLE_COLUMNS["ccr_case_team_members"] - {"id", "created_at"},
}

RESOURCE_TABLE = {
    "cases": "ccr_cases",
    "assignments": "ccr_assignments",
    "containment": "ccr_containment",
    "sorting": "ccr_containment_sorting",
    "fishbone-causes": "ccr_fishbone_causes",
    "validations": "ccr_root_cause_validations",
    "why-analyses": "ccr_why_analyses",
    "why-steps": "ccr_why_steps",
    "corrective-actions": "ccr_corrective_actions",
    "teams": "ccr_teams",
    "team-members": "ccr_team_members",
    "case-team-members": "ccr_case_team_members",
}
class LoginBody(BaseModel):
    email: str
    password: str = Field(min_length=1, max_length=256)


class ChangePasswordBody(BaseModel):
    current_password: str = Field(min_length=1, max_length=256)
    new_password: str = Field(min_length=8, max_length=128)


class ChangePasswordFromLoginBody(BaseModel):
    email: str
    current_password: str = Field(min_length=1, max_length=256)
    new_password: str = Field(min_length=8, max_length=128)


class RowBody(BaseModel):
    data: dict[str, Any]


class TeamBody(BaseModel):
    team_leader_name: str = Field(min_length=1, max_length=200)
    member_names: list[str] = Field(default_factory=list)


class AdminCreateUserBody(BaseModel):
    full_name: str = Field(min_length=1, max_length=200)
    email: str = Field(min_length=3, max_length=320)
    role: str = Field(default="user", pattern="^(user|admin)$")


class CompleteStageBody(BaseModel):
    ccr_id: str = Field(min_length=1, max_length=128)
def _token_hash(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def _as_dict(value: Any) -> dict[str, Any]:
    if isinstance(value, dict):
        return value
    if isinstance(value, str):
        try:
            parsed = json.loads(value)
            if isinstance(parsed, dict):
                return parsed
        except (TypeError, ValueError):
            pass
    if hasattr(value, "_mapping"):
        return dict(value._mapping)
    raise HTTPException(status_code=500, detail="CCR database function returned an unexpected response.")


def _as_list(value: Any) -> list[dict[str, Any]]:
    if isinstance(value, str):
        try:
            value = json.loads(value)
        except (TypeError, ValueError):
            pass

    if isinstance(value, list):
        return [
            dict(item) if isinstance(item, dict) else dict(item._mapping)
            for item in value
            if isinstance(item, dict) or hasattr(item, "_mapping")
        ]

    if value is None:
        return []

    raise HTTPException(
        status_code=500,
        detail="CCR database function returned an unexpected user list.",
    )
def _function_result(db: Session, function_name: str, params: dict[str, Any]) -> Any:
    binds = ", ".join(f":{key}" for key in params)
    result = db.execute(text(f"SELECT {function_name}({binds})"), params).scalar()
    return result


def _bearer_token(authorization: str | None) -> str:
    scheme, _, token = (authorization or "").partition(" ")
    if scheme.lower() != "bearer" or not token.strip():
        raise HTTPException(status_code=401, detail="CCR bearer token is required.")
    return token.strip()




def _current_user(
    authorization: str | None = Header(default=None),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    if not authorization or not authorization.strip():
        return {
            "id": None,
            "user_id": None,
            "email": None,
            "role": "anonymous",
            "is_active": True,
        }
    token = _bearer_token(authorization)
    try:
        response = _function_result(
            db,
            "ccr_validate_session",
            {"p_session_token": token},
        )

        user = _as_dict(response)

    except HTTPException:
        raise

    except Exception as exc:
        db.rollback()
        raise HTTPException(
            status_code=401,
            detail="CCR session validation failed. Check the CCR session function.",
        ) from exc
    user_id = user.get("id") or user.get("user_id")
    email = user.get("email")
    role = str(user.get("role") or "").strip().lower()
    if not user_id or not email:
        raise HTTPException(
            status_code=401,
            detail="CCR session is invalid or expired.",
        )
    is_active = user.get("is_active")
    if is_active is False:
        raise HTTPException(
            status_code=403,
            detail="CCR account is disabled.",
        )
    user["id"] = str(user_id)
    user["user_id"] = str(user_id)
    user["email"] = str(email)
    user["role"] = role
    user["is_active"] = True if is_active is None else is_active
    return user
def _require_admin(user: dict[str, Any]) -> None:
    if not user.get("id"):
        raise HTTPException(
            status_code=401,
            detail="Admin login is required to access this feature.",
        )
    if str(user.get("role", "")).strip().lower() != "admin":
        raise HTTPException(
            status_code=403,
            detail="Only a CCR Admin can perform this operation.",
        )
def _clean_write(resource: str, data: dict[str, Any], *, partial: bool = False) -> dict[str, Any]:
    if resource not in RESOURCE_TABLE:
        raise HTTPException(status_code=404, detail="Unknown CCR resource.")
    allowed = WRITE_COLUMNS[resource]
    clean = {key: value for key, value in data.items() if key in allowed}
    if not clean:
        raise HTTPException(status_code=400, detail="No valid CCR fields supplied.")
    return clean
def _row(db: Session, table: str, row_id: str) -> dict[str, Any] | None:
    if table not in TABLE_COLUMNS:
        raise HTTPException(status_code=404, detail="Unknown CCR table.")
    result = db.execute(text(f'SELECT * FROM {table} WHERE id = :id LIMIT 1'), {"id": row_id}).mappings().first()
    return dict(result) if result else None


def _insert(db: Session, resource: str, data: dict[str, Any]) -> dict[str, Any]:
    table = RESOURCE_TABLE[resource]
    clean = _clean_write(resource, data)
    columns = list(clean)
    names = ", ".join(columns)
    binds = ", ".join(f":{column}" for column in columns)
    result = db.execute(text(f'INSERT INTO {table} ({names}) VALUES ({binds}) RETURNING *'), clean).mappings().first()
    db.commit()
    return dict(result)


def _update(db: Session, resource: str, row_id: str, data: dict[str, Any]) -> dict[str, Any]:
    table = RESOURCE_TABLE[resource]
    clean = _clean_write(resource, data, partial=True)
    clean["_id"] = row_id
    assignments = ", ".join(f'{column} = :{column}' for column in clean if column != "_id")
    if "updated_at" in TABLE_COLUMNS[table]:
        assignments += ", updated_at = NOW()"
    result = db.execute(text(f'UPDATE {table} SET {assignments} WHERE id = :_id RETURNING *'), clean).mappings().first()
    if not result:
        db.rollback()
        raise HTTPException(status_code=404, detail="CCR record not found.")
    db.commit()
    return dict(result)


def _delete(db: Session, resource: str, row_id: str) -> bool:
    table = RESOURCE_TABLE[resource]
    result = db.execute(text(f'DELETE FROM {table} WHERE id = :id'), {"id": row_id})
    db.commit()
    return result.rowcount > 0


def _list_rows(db: Session, table: str, where_column: str | None = None,
               where_value: Any = None, order_by: str = "created_at",
               ascending: bool = True) -> list[dict[str, Any]]:
    if table not in TABLE_COLUMNS or order_by not in TABLE_COLUMNS[table]:
        raise HTTPException(status_code=400, detail="Invalid CCR query.")
    sql = f'SELECT * FROM {table}'
    params: dict[str, Any] = {}
    if where_column:
        if where_column not in TABLE_COLUMNS[table]:
            raise HTTPException(status_code=400, detail="Invalid CCR filter.")
        sql += f' WHERE {where_column} = :filter_value'
        params["filter_value"] = where_value
    sql += f' ORDER BY {order_by} {"ASC" if ascending else "DESC"}'
    rows = db.execute(text(sql), params).mappings().all()
    return [dict(row) for row in rows]


def _advance_stage(db: Session, ccr_id: str) -> dict[str, Any]:
    current = db.execute(text("SELECT current_stage FROM ccr_cases WHERE id=:id FOR UPDATE"), {"id": ccr_id}).mappings().first()
    if not current:
        raise HTTPException(status_code=404, detail="CCR case not found.")
    stage_key = (current["current_stage"] or "").strip()
    if not stage_key:
        raise HTTPException(status_code=409, detail="Current CCR workflow stage is missing.")
    stage = db.execute(text("SELECT display_order FROM ccr_workflow_stages WHERE stage_key=:key LIMIT 1"), {"key": stage_key}).mappings().first()
    if not stage:
        raise HTTPException(status_code=409, detail="Current CCR workflow stage is not configured.")
    next_stage = db.execute(text("""
        SELECT stage_key FROM ccr_workflow_stages
        WHERE is_active=TRUE AND display_order > :display_order
        ORDER BY display_order ASC LIMIT 1
    """), {"display_order": stage["display_order"]}).mappings().first()
    if not next_stage:
        raise HTTPException(status_code=409, detail="No next active CCR workflow stage is configured.")
    result = db.execute(text("UPDATE ccr_cases SET current_stage=:stage, updated_at=NOW() WHERE id=:id RETURNING *"),
                        {"stage": next_stage["stage_key"], "id": ccr_id}).mappings().first()
    db.commit()
    return dict(result)
@router.post("/auth/login")
def login(body: LoginBody, db: Session = Depends(get_db)):
    email = body.email.strip().lower()
    if not email or "@" not in email:
        raise HTTPException(status_code=400, detail="A valid email address is required.")
    try:
        response = _function_result(db, "ccr_login", {"p_email": email, "p_password": body.password})
        data = _as_dict(response)
        if not data.get("session_token"):
            raise HTTPException(status_code=401, detail=str(data.get("message") or data.get("error") or "Invalid CCR email or password."))
        db.commit()
        return data
    except HTTPException:
        db.rollback()
        raise
    except Exception as exc:
        db.rollback()
        raise HTTPException(status_code=401, detail="Unable to authenticate CCR user. Check the CCR login function and database schema.") from exc


@router.get("/auth/session")
def validate_session(user: dict[str, Any] = Depends(_current_user)):
    return user


@router.post("/auth/logout")
def logout(authorization: str | None = Header(default=None), db: Session = Depends(get_db)):
    if not authorization:
        return {"success": False}
    try:
        token = _bearer_token(authorization)
        result = _function_result(db, "ccr_logout", {"p_session_token": token})
        db.commit()
        return {"success": result is not False}
    except Exception:
        db.rollback()
        return {"success": False}


@router.post("/auth/change-password")
def change_password(body: ChangePasswordBody, user: dict[str, Any] = Depends(_current_user),
                    authorization: str | None = Header(default=None), db: Session = Depends(get_db)):
    token = _bearer_token(authorization)
    if len(body.new_password.strip()) < 8:
        raise HTTPException(status_code=400, detail="New password must contain at least 8 characters.")
    try:
        result = _function_result(db, "ccr_change_password", {
            "p_session_token": token,
            "p_current_password": body.current_password,
            "p_new_password": body.new_password,
        })
        db.commit()
        if result is False:
            raise HTTPException(status_code=400, detail="Password could not be changed.")
        return {"success": True}
    except HTTPException:
        db.rollback()
        raise
    except Exception as exc:
        db.rollback()
        raise HTTPException(status_code=400, detail="Unable to change CCR password.") from exc


@router.post("/auth/change-password-from-login")
def change_password_from_login(body: ChangePasswordFromLoginBody, db: Session = Depends(get_db)):
    email = body.email.strip().lower()
    current = body.current_password.strip()
    new = body.new_password.strip()
    if "@" not in email or not current or len(new) < 8 or current == new:
        raise HTTPException(status_code=400, detail="Invalid password change details.")
    try:
        result = _function_result(db, "ccr_change_password_from_login", {
            "p_email": email,
            "p_current_password": current,
            "p_new_password": new,
        })
        db.commit()
        return {"success": result is True}
    except Exception as exc:
        db.rollback()
        raise HTTPException(status_code=400, detail="Unable to change password. Verify the CCR password function.") from exc
@router.get("/cases")
def get_cases(user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    rows = db.execute(text("""
        SELECT c.*, s.status_name, w.stage_name
        FROM ccr_cases c
        LEFT JOIN ccr_statuses s ON s.status_key = c.status
        LEFT JOIN ccr_workflow_stages w ON w.stage_key = c.current_stage
        ORDER BY c.created_at DESC
    """)).mappings().all()
    output = []
    for row in rows:
        item = dict(row)
        status_name = item.pop("status_name", None)
        stage_name = item.pop("stage_name", None)
        item["ccr_statuses"] = {"status_name": status_name} if status_name is not None else None
        item["ccr_workflow_stages"] = {"stage_name": stage_name} if stage_name is not None else None
        output.append(item)
    return output


@router.get("/dashboard")
def get_dashboard(
    user: dict[str, Any] = Depends(_current_user),
    db: Session = Depends(get_db),
):
    case_rows = db.execute(text("""
        SELECT c.*, s.status_name, w.stage_name
        FROM ccr_cases c
        LEFT JOIN ccr_statuses s ON s.status_key = c.status
        LEFT JOIN ccr_workflow_stages w ON w.stage_key = c.current_stage
        ORDER BY c.created_at DESC
    """)).mappings().all()

    cases = []

    for row in case_rows:
        item = dict(row)

        status_name = item.pop("status_name", None)
        stage_name = item.pop("stage_name", None)

        item["ccr_statuses"] = (
            {"status_name": status_name}
            if status_name is not None else None
        )

        item["ccr_workflow_stages"] = (
            {"stage_name": stage_name}
            if stage_name is not None else None
        )

        cases.append(item)
    action_rows = db.execute(
    text("""
        SELECT
            ca.*,

            COALESCE(
                (
                    SELECT NULLIF(BTRIM(ws.why_text), '')
                    FROM ccr_why_analyses a
                    JOIN ccr_why_steps ws
                        ON ws.analysis_id = a.id
                    WHERE a.validation_id = ca.validation_id
                      AND LOWER(TRIM(a.analysis_type)) = 'occurrence'
                      AND NULLIF(BTRIM(ws.why_text), '') IS NOT NULL
                    ORDER BY ws.why_number DESC
                    LIMIT 1
                ),
                (
                    SELECT NULLIF(BTRIM(a.potential_root_cause), '')
                    FROM ccr_why_analyses a
                    WHERE a.validation_id = ca.validation_id
                      AND LOWER(TRIM(a.analysis_type)) = 'occurrence'
                    LIMIT 1
                ),
                ''
            ) AS occurrence_root_cause,

            COALESCE(
                (
                    SELECT NULLIF(BTRIM(ws.why_text), '')
                    FROM ccr_why_analyses a
                    JOIN ccr_why_steps ws
                        ON ws.analysis_id = a.id
                    WHERE a.validation_id = ca.validation_id
                      AND LOWER(TRIM(a.analysis_type)) = 'non_detection'
                      AND NULLIF(BTRIM(ws.why_text), '') IS NOT NULL
                    ORDER BY ws.why_number DESC
                    LIMIT 1
                ),
                (
                    SELECT NULLIF(BTRIM(a.potential_root_cause), '')
                    FROM ccr_why_analyses a
                    WHERE a.validation_id = ca.validation_id
                      AND LOWER(TRIM(a.analysis_type)) = 'non_detection'
                    LIMIT 1
                ),
                ''
            ) AS detection_root_cause

        FROM ccr_corrective_actions ca
        INNER JOIN ccr_cases c
            ON c.id = ca.ccr_id
        ORDER BY ca.created_at ASC
    """)
).mappings().all()

    corrective_actions = [dict(row) for row in action_rows]

    return {
        "cases": cases,
        "corrective_actions": corrective_actions,
    }


@router.post("/cases")
def create_case(body: RowBody | None = None, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    data = dict(body.data) if body else {}
    data.setdefault("status", "draft")
    data.setdefault("current_stage", "registration")
    if user.get("id"):
        data["created_by"] = user["id"]
    else:
        data.pop("created_by", None)
    return _insert(db, "cases", data)


@router.get("/cases/{ccr_id}")
def get_case(ccr_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    row = db.execute(text("""
        SELECT c.*, s.status_name, w.stage_name
        FROM ccr_cases c
        LEFT JOIN ccr_statuses s ON s.status_key = c.status
        LEFT JOIN ccr_workflow_stages w ON w.stage_key = c.current_stage
        WHERE c.id=:id LIMIT 1
    """), {"id": ccr_id}).mappings().first()
    if not row:
        raise HTTPException(status_code=404, detail="CCR case not found.")
    item = dict(row)
    status_name = item.pop("status_name", None)
    stage_name = item.pop("stage_name", None)
    item["ccr_statuses"] = {"status_name": status_name} if status_name is not None else None
    item["ccr_workflow_stages"] = {"stage_name": stage_name} if stage_name is not None else None
    return item


@router.patch("/cases/{ccr_id}")
def update_case(ccr_id: str, body: RowBody, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return _update(db, "cases", ccr_id, body.data)


@router.patch("/cases/{ccr_id}/status")
def update_case_status(ccr_id: str, status_key: str = Query(...), user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return _update(db, "cases", ccr_id, {"status": status_key})


@router.patch("/cases/{ccr_id}/stage")
def update_case_stage(ccr_id: str, stage_key: str = Query(...), user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    exists = db.execute(text("SELECT 1 FROM ccr_workflow_stages WHERE stage_key=:key AND is_active=TRUE"), {"key": stage_key}).first()
    if not exists:
        raise HTTPException(status_code=400, detail="CCR workflow stage is not active or does not exist.")
    return _update(db, "cases", ccr_id, {"current_stage": stage_key})
@router.get("/cases/{ccr_id}/assignments")
def get_assignments(ccr_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    rows = db.execute(text("""
        SELECT a.*, st.status_name
        FROM ccr_assignments a
        LEFT JOIN ccr_assignment_statuses st ON st.status_key = a.status
        WHERE a.ccr_id=:id ORDER BY a.created_at ASC
    """), {"id": ccr_id}).mappings().all()
    result = []
    for row in rows:
        item = dict(row)
        status_name = item.pop("status_name", None)
        item["ccr_assignment_statuses"] = {"status_name": status_name} if status_name is not None else None
        result.append(item)
    return result


@router.post("/assignments")
def create_assignment(body: RowBody, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    data = dict(body.data)
    data.setdefault("status", "pending")
    return _insert(db, "assignments", data)


@router.patch("/assignments/{assignment_id}")
def update_assignment(assignment_id: str, body: RowBody, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return _update(db, "assignments", assignment_id, body.data)


@router.delete("/assignments/{assignment_id}")
def delete_assignment(assignment_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return {"success": _delete(db, "assignments", assignment_id)}


@router.post("/cases/{ccr_id}/assignments/complete")
def complete_assignment_stage(ccr_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return _advance_stage(db, ccr_id)
@router.get("/cases/{ccr_id}/containment")
def get_containment(ccr_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    row = db.execute(text("SELECT * FROM ccr_containment WHERE ccr_id=:id LIMIT 1"), {"id": ccr_id}).mappings().first()
    return dict(row) if row else None


@router.put("/cases/{ccr_id}/containment")
def save_containment(ccr_id: str, body: RowBody, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    data = dict(body.data)
    data["ccr_id"] = ccr_id
    existing = db.execute(text("SELECT id FROM ccr_containment WHERE ccr_id=:id LIMIT 1"), {"id": ccr_id}).mappings().first()
    if existing:
        return _update(db, "containment", str(existing["id"]), data)
    return _insert(db, "containment", data)


@router.get("/containment/{containment_id}/sorting")
def get_sorting_rows(containment_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return _list_rows(db, "ccr_containment_sorting", "containment_id", containment_id, "created_at", True)


@router.post("/sorting")
def create_sorting_row(body: RowBody, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return _insert(db, "sorting", body.data)


@router.patch("/sorting/{sorting_id}")
def update_sorting_row(sorting_id: str, body: RowBody, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return _update(db, "sorting", sorting_id, body.data)


@router.delete("/sorting/{sorting_id}")
def delete_sorting_row(sorting_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return {"success": _delete(db, "sorting", sorting_id)}


@router.post("/cases/{ccr_id}/containment/complete")
def complete_containment(ccr_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return _advance_stage(db, ccr_id)
@router.get("/fishbone/categories")
def get_fishbone_categories(user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return _list_rows(db, "ccr_fishbone_categories", order_by="display_order", ascending=True)


@router.get("/cases/{ccr_id}/fishbone/causes")
def get_fishbone_causes(ccr_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    rows = db.execute(text("""
        SELECT f.*, c.name AS category_name
        FROM ccr_fishbone_causes f
        LEFT JOIN ccr_fishbone_categories c ON c.id=f.category_id
        WHERE f.ccr_id=:id ORDER BY f.display_order ASC
    """), {"id": ccr_id}).mappings().all()
    result = []
    for row in rows:
        item = dict(row)
        category_name = item.pop("category_name", None)
        item["ccr_fishbone_categories"] = {"name": category_name} if category_name is not None else None
        result.append(item)
    return result


@router.post("/fishbone/causes")
def create_fishbone_cause(body: RowBody, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    data = dict(body.data)
    data.setdefault("created_by", user.get("id"))
    return _insert(db, "fishbone-causes", data)


@router.patch("/fishbone/causes/{cause_id}")
def update_fishbone_cause(cause_id: str, body: RowBody, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    data = dict(body.data)
    data["updated_by"] = user.get("id")
    return _update(db, "fishbone-causes", cause_id, data)


@router.delete("/fishbone/causes/{cause_id}")
def delete_fishbone_cause(cause_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return {"success": _delete(db, "fishbone-causes", cause_id)}


@router.post("/cases/{ccr_id}/fishbone/complete")
def complete_fishbone(ccr_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return _advance_stage(db, ccr_id)
@router.get("/cases/{ccr_id}/root-cause-validations")
def get_case_root_cause_validations(
    ccr_id: str,
    db: Session = Depends(get_db),
):
    rows = db.execute(
        text("""
            SELECT
                v.id,
                fc.id AS fishbone_cause_id,
                fc.ccr_id,
                fc.category_id,
                fc.cause_text,
                cat.name AS category_name,

                v.validation_text,
                v.relevance,
                v.validated_by,
                v.validated_at,
                v.created_at,
                v.updated_at

            FROM ccr_fishbone_causes fc

            LEFT JOIN ccr_fishbone_categories cat
                ON cat.id = fc.category_id

            LEFT JOIN ccr_root_cause_validations v
                ON v.fishbone_cause_id = fc.id

            WHERE fc.ccr_id = :ccr_id

            ORDER BY
                cat.display_order ASC,
                fc.display_order ASC,
                fc.created_at ASC
        """),
        {"ccr_id": ccr_id},
    ).mappings().all()

    return [dict(row) for row in rows]

@router.put("/root-cause-validations/{validation_id}")
def save_root_cause_validation(validation_id: str, body: RowBody, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    data = dict(body.data)
    data["validated_by"] = user.get("id")
    data["validated_at"] = datetime.now(timezone.utc).isoformat()
    existing = _row(db, "ccr_root_cause_validations", validation_id)
    if existing:
        return _update(db, "validations", validation_id, data)
    data.pop("id", None)
    data["fishbone_cause_id"] = validation_id
    return _insert(db, "validations", data)


@router.post("/root-cause-validations")
def upsert_root_cause_validation(body: RowBody, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    data = dict(body.data)
    cause_id = str(data.get("fishbone_cause_id") or "").strip()
    if not cause_id:
        raise HTTPException(status_code=400, detail="fishbone_cause_id is required.")
    data["validated_by"] = user.get("id")
    data["validated_at"] = datetime.now(timezone.utc).isoformat()
    existing = db.execute(text("SELECT id FROM ccr_root_cause_validations WHERE fishbone_cause_id=:id LIMIT 1"), {"id": cause_id}).mappings().first()
    if existing:
        return _update(db, "validations", str(existing["id"]), data)
    return _insert(db, "validations", data)


@router.post("/cases/{ccr_id}/root-cause-validations/complete")
def complete_root_cause_validation(ccr_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return _advance_stage(db, ccr_id)
@router.get("/cases/{ccr_id}/why-analyses")
def get_why_analyses(
    ccr_id: str,
    user: dict[str, Any] = Depends(_current_user),
    db: Session = Depends(get_db),
):
    rows = db.execute(
        text("""
            SELECT
                a.*,
                v.id AS validation_record_id,
                v.validation_text,
                v.fishbone_cause_id,
                f.ccr_id AS case_id,
                f.category_id,
                f.cause_text,
                c.name AS category_name,

                COALESCE(
                    (
                        SELECT jsonb_agg(
                            to_jsonb(ws)
                            ORDER BY ws.why_number ASC
                        )
                        FROM ccr_why_steps ws
                        WHERE ws.analysis_id = a.id
                    ),
                    '[]'::jsonb
                ) AS ccr_why_steps

            FROM ccr_why_analyses a

            JOIN ccr_root_cause_validations v
                ON v.id = a.validation_id

            JOIN ccr_fishbone_causes f
                ON f.id = v.fishbone_cause_id

            LEFT JOIN ccr_fishbone_categories c
                ON c.id = f.category_id

            WHERE f.ccr_id = :id

            ORDER BY a.created_at ASC
        """),
        {"id": ccr_id},
    ).mappings().all()

    output = []

    for row in rows:
        item = dict(row)

        validation = {
            "id": item.pop("validation_record_id", None),
            "validation_text": item.pop("validation_text", None),
            "fishbone_cause_id": item.pop("fishbone_cause_id", None),
        }

        cause = {
            "ccr_id": item.pop("case_id", None),
            "category_id": item.pop("category_id", None),
            "cause_text": item.pop("cause_text", None),
        }

        category_name = item.pop("category_name", None)

        cause["ccr_fishbone_categories"] = (
            {"name": category_name}
            if category_name is not None
            else None
        )

        validation["ccr_fishbone_causes"] = cause

        item["validation_id"] = validation["id"]
        item["ccr_root_cause_validations"] = validation
        item["ccr_why_steps"] = item.get("ccr_why_steps") or []
        output.append(item)
    return output


@router.post("/why-analyses")
def create_why_analysis(body: RowBody, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return _insert(db, "why-analyses", body.data)


@router.patch("/why-analyses/{analysis_id}")
def update_why_analysis(analysis_id: str, body: RowBody, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return _update(db, "why-analyses", analysis_id, body.data)

@router.post("/why-steps")
def create_why_step(
    body: RowBody,
    user: dict[str, Any] = Depends(_current_user),
    db: Session = Depends(get_db),
):
    data = _clean_write("why-steps", body.data)

    analysis_id = data.get("analysis_id")
    why_number = data.get("why_number")

    if not analysis_id:
        raise HTTPException(
            status_code=400,
            detail="analysis_id is required.",
        )

    if why_number is None:
        raise HTTPException(
            status_code=400,
            detail="why_number is required.",
        )

    try:
        result = db.execute(
            text("""
                INSERT INTO ccr_why_steps (
                    analysis_id,
                    why_number,
                    why_text,
                    verification_text,
                    evidence_available
                )
                VALUES (
                    :analysis_id,
                    :why_number,
                    :why_text,
                    :verification_text,
                    :evidence_available
                )
                ON CONFLICT (analysis_id, why_number)
                DO UPDATE SET
                    why_text = EXCLUDED.why_text,
                    verification_text = EXCLUDED.verification_text,
                    evidence_available = EXCLUDED.evidence_available,
                    updated_at = NOW()
                RETURNING *
            """),
            {
                "analysis_id": analysis_id,
                "why_number": why_number,
                "why_text": data.get("why_text"),
                "verification_text": data.get("verification_text"),
                "evidence_available": data.get("evidence_available"),
            },
        ).mappings().first()

        db.commit()

        return dict(result)

    except Exception:
        db.rollback()
        raise
@router.patch("/why-steps/{step_id}")
def update_why_step(step_id: str, body: RowBody, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return _update(db, "why-steps", step_id, body.data)


@router.delete("/why-steps/{step_id}")
def delete_why_step(step_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return {"success": _delete(db, "why-steps", step_id)}


@router.post("/cases/{ccr_id}/why/complete")
def complete_why_stage(ccr_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return _advance_stage(db, ccr_id)
@router.get("/cases/{ccr_id}/corrective-actions")
def get_corrective_actions(
    ccr_id: str,
    user: dict[str, Any] = Depends(_current_user),
    db: Session = Depends(get_db),
):
    rows = db.execute(
        text("""
            SELECT
    ca.*,

    COALESCE(
                    (
                        SELECT NULLIF(BTRIM(ws.why_text), '')
                        FROM ccr_why_analyses a
                        JOIN ccr_why_steps ws
                            ON ws.analysis_id = a.id
                        WHERE a.validation_id = ca.validation_id
                          AND LOWER(TRIM(a.analysis_type)) = 'occurrence'
                          AND NULLIF(BTRIM(ws.why_text), '') IS NOT NULL
                        ORDER BY ws.why_number DESC
                        LIMIT 1
                    ),
                    (
                        SELECT NULLIF(BTRIM(a.potential_root_cause), '')
                        FROM ccr_why_analyses a
                        WHERE a.validation_id = ca.validation_id
                          AND LOWER(TRIM(a.analysis_type)) = 'occurrence'
                        LIMIT 1
                    ),
                    ''
                ) AS occurrence_root_cause,

                COALESCE(
                    (
                        SELECT NULLIF(BTRIM(ws.why_text), '')
                        FROM ccr_why_analyses a
                        JOIN ccr_why_steps ws
                            ON ws.analysis_id = a.id
                        WHERE a.validation_id = ca.validation_id
                          AND LOWER(TRIM(a.analysis_type)) = 'non_detection'
                          AND NULLIF(BTRIM(ws.why_text), '') IS NOT NULL
                        ORDER BY ws.why_number DESC
                        LIMIT 1
                    ),
                    (
                        SELECT NULLIF(BTRIM(a.potential_root_cause), '')
                        FROM ccr_why_analyses a
                        WHERE a.validation_id = ca.validation_id
                          AND LOWER(TRIM(a.analysis_type)) = 'non_detection'
                        LIMIT 1
                    ),
                    ''
                ) AS detection_root_cause

            FROM ccr_corrective_actions ca

            LEFT JOIN ccr_cases c
                ON c.id = ca.ccr_id

            WHERE ca.ccr_id = :ccr_id

            ORDER BY ca.created_at ASC
        """),
        {"ccr_id": ccr_id},
    ).mappings().all()

    return [dict(row) for row in rows]
@router.post("/corrective-actions")
def create_corrective_action(body: RowBody, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    data = dict(body.data)
    data.setdefault("created_by", user.get("id"))
    return _insert(db, "corrective-actions", data)


@router.patch("/corrective-actions/{action_id}")
def update_corrective_action(action_id: str, body: RowBody, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    data = dict(body.data)
    data["updated_by"] = user.get("id")
    return _update(db, "corrective-actions", action_id, data)


@router.post("/cases/{ccr_id}/corrective-actions/complete")
def complete_corrective_actions(ccr_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return _advance_stage(db, ccr_id)
@router.get("/teams")
def get_teams(
    active_only: bool = Query(False),
    user: dict[str, Any] = Depends(_current_user),
    db: Session = Depends(get_db),
):
    if active_only:
        rows = db.execute(
            text("""
                SELECT *
                FROM ccr_teams
                WHERE is_active = TRUE
                ORDER BY team_leader_name ASC
            """)
        ).mappings().all()

        teams = [dict(row) for row in rows]

    else:
        teams = _list_rows(
            db,
            "ccr_teams",
            order_by="created_at",
            ascending=True,
        )

    if not teams:
        return []
    member_rows = db.execute(
        text("""
            SELECT *
            FROM ccr_team_members
            ORDER BY created_at ASC
        """)
    ).mappings().all()

    members_by_team = {}

    for row in member_rows:
        member = dict(row)
        team_id = str(member.get("team_id"))

        members_by_team.setdefault(team_id, []).append(member)
    for team in teams:
        team_id = str(team.get("id"))

        team["ccr_team_members"] = members_by_team.get(
            team_id,
            [],
        )

    return teams


@router.get("/teams/{team_id}")
def get_team(team_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    team = _row(db, "ccr_teams", team_id)
    if not team:
        raise HTTPException(status_code=404, detail="CCR team not found.")
    members = _list_rows(db, "ccr_team_members", "team_id", team_id, "created_at", True)
    team["ccr_team_members"] = members
    return team


@router.get("/teams/{team_id}/members")
def get_team_members(team_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return _list_rows(db, "ccr_team_members", "team_id", team_id, "created_at", True)


@router.post("/admin/teams")
def admin_create_team(body: TeamBody, authorization: str | None = Header(default=None), user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    _require_admin(user)
    try:
        result = _function_result(db, "ccr_admin_create_team", {
            "p_session_token": _bearer_token(authorization),
            "p_team_leader_name": body.team_leader_name.strip(),
            "p_member_names": [name.strip() for name in body.member_names if name.strip()],
        })
        db.commit()
        return {"id": str(result)}
    except Exception as exc:
        db.rollback()
        raise HTTPException(status_code=400, detail="Unable to create CCR team.") from exc


@router.put("/admin/teams/{team_id}")
def admin_update_team(team_id: str, body: TeamBody, authorization: str | None = Header(default=None), user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    _require_admin(user)
    try:
        _function_result(db, "ccr_admin_update_team", {
            "p_session_token": _bearer_token(authorization),
            "p_team_id": team_id,
            "p_team_leader_name": body.team_leader_name.strip(),
            "p_member_names": [name.strip() for name in body.member_names if name.strip()],
        })
        db.commit()
        return {"success": True}
    except Exception as exc:
        db.rollback()
        raise HTTPException(status_code=400, detail="Unable to update CCR team.") from exc


@router.patch("/admin/teams/{team_id}/active")
def admin_set_team_active(team_id: str, is_active: bool = Query(...), authorization: str | None = Header(default=None), user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    _require_admin(user)
    try:
        _function_result(db, "ccr_admin_set_team_active", {"p_session_token": _bearer_token(authorization), "p_team_id": team_id, "p_is_active": is_active})
        db.commit()
        return {"success": True}
    except Exception as exc:
        db.rollback()
        raise HTTPException(status_code=400, detail="Unable to update CCR team status.") from exc


@router.delete("/admin/teams/{team_id}")
def admin_delete_team(team_id: str, authorization: str | None = Header(default=None), user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    _require_admin(user)
    try:
        _function_result(db, "ccr_admin_delete_team", {"p_session_token": _bearer_token(authorization), "p_team_id": team_id})
        db.commit()
        return {"success": True}
    except Exception as exc:
        db.rollback()
        raise HTTPException(status_code=400, detail="Unable to delete CCR team.") from exc


# ---------------------------------------------------------------------------
# CCR Admin User Management
# ---------------------------------------------------------------------------

@router.get("/admin/users")
def admin_get_users(
    authorization: str | None = Header(default=None),
    user: dict[str, Any] = Depends(_current_user),
    db: Session = Depends(get_db),
):
    _require_admin(user)

    try:
        result = _function_result(
            db,
            "ccr_admin_get_users",
            {
                "p_session_token": _bearer_token(authorization),
            },
        )

        return _as_list(result)

    except HTTPException:
        raise

    except Exception as exc:
        db.rollback()
        raise HTTPException(
            status_code=400,
            detail="Unable to load CCR users.",
        ) from exc


@router.post("/admin/users")
def admin_create_user(
    body: AdminCreateUserBody,
    authorization: str | None = Header(default=None),
    user: dict[str, Any] = Depends(_current_user),
    db: Session = Depends(get_db),
):
    _require_admin(user)

    full_name = body.full_name.strip()
    email = body.email.strip().lower()
    role = body.role.strip().lower()

    if not full_name:
        raise HTTPException(
            status_code=400,
            detail="Full name is required.",
        )

    if "@" not in email:
        raise HTTPException(
            status_code=400,
            detail="A valid email address is required.",
        )

    if role not in {"user", "admin"}:
        raise HTTPException(
            status_code=400,
            detail="Invalid CCR user role.",
        )

    try:
        result = _function_result(
            db,
            "ccr_admin_create_user",
            {
                "p_session_token": _bearer_token(authorization),
                "p_full_name": full_name,
                "p_email": email,
                "p_role": role,
            },
        )

        db.commit()

        return {
            "success": True,
            "id": str(result) if result is not None else None,
        }

    except Exception as exc:
        db.rollback()
        raise HTTPException(
            status_code=400,
            detail="Unable to create CCR user.",
        ) from exc


@router.patch("/admin/users/{user_id}/active")
def admin_set_user_active(
    user_id: str,
    is_active: bool = Query(...),
    authorization: str | None = Header(default=None),
    user: dict[str, Any] = Depends(_current_user),
    db: Session = Depends(get_db),
):
    _require_admin(user)

    try:
        _function_result(
            db,
            "ccr_admin_set_user_active",
            {
                "p_session_token": _bearer_token(authorization),
                "p_user_id": user_id,
                "p_is_active": is_active,
            },
        )

        db.commit()

        return {"success": True}

    except Exception as exc:
        db.rollback()
        raise HTTPException(
            status_code=400,
            detail="Unable to update CCR user status.",
        ) from exc


@router.delete("/admin/users/{user_id}")
def admin_delete_user(
    user_id: str,
    authorization: str | None = Header(default=None),
    user: dict[str, Any] = Depends(_current_user),
    db: Session = Depends(get_db),
):
    _require_admin(user)

    try:
        _function_result(
            db,
            "ccr_admin_delete_user",
            {
                "p_session_token": _bearer_token(authorization),
                "p_user_id": user_id,
            },
        )

        db.commit()

        return {"success": True}

    except Exception as exc:
        db.rollback()
        raise HTTPException(
            status_code=400,
            detail="Unable to delete CCR user.",
        ) from exc



@router.put("/cases/{ccr_id}/team-snapshot")
def save_case_team_snapshot(ccr_id: str, body: RowBody, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    data = dict(body.data)
    members = data.get("members") or data.get("member_names") or []
    leader = str(data.get("team_leader_name") or data.get("team_leader") or "").strip()
    team_id = data.get("team_id")
    if not leader:
        raise HTTPException(status_code=400, detail="Team leader name is required.")
    db.execute(text("DELETE FROM ccr_case_team_members WHERE ccr_id=:id"), {"id": ccr_id})
    clean_members = [str(member).strip() for member in members if str(member).strip()]
    for member in clean_members:
        db.execute(
    text("""
        INSERT INTO ccr_case_team_members (
            ccr_id,
            member_name
        )
        VALUES (
            :ccr_id,
            :member
        )
    """),
    {
        "ccr_id": ccr_id,
        "member": member,
    },
)
    db.execute(
    text("""
        UPDATE ccr_cases
        SET
            team_id = :team_id,
            team_leader = :leader,
            updated_at = NOW()
        WHERE id = :id
    """),
    {
        "team_id": team_id,
        "leader": leader,
        "id": ccr_id,
    },
)
    db.commit()
    return {"success": True}


@router.get("/cases/{ccr_id}/team-snapshot")
def get_case_team_snapshot(ccr_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return _list_rows(db, "ccr_case_team_members", "ccr_id", ccr_id, "created_at", True)


# ---------------------------------------------------------------------------
# CCR attachments and private file storage
# ---------------------------------------------------------------------------

_CCR_STORAGE_ROOT = (
    Path(__file__).resolve().parents[3] / "storage" / "ccr-files"
)
_CCR_STORAGE_ROOT.mkdir(parents=True, exist_ok=True)

_CCR_MAX_UPLOAD_SIZE = 50 * 1024 * 1024


def _ccr_safe_path(relative_path: str) -> Path:
    relative_path = relative_path.replace("\\", "/").strip()

    candidate = (_CCR_STORAGE_ROOT / relative_path).resolve()
    root = _CCR_STORAGE_ROOT.resolve()

    if root not in candidate.parents:
        raise HTTPException(status_code=400, detail="Invalid CCR storage path.")

    return candidate


@router.get("/cases/{ccr_id}/attachments")
def get_ccr_attachments(
    ccr_id: str,
    user: dict[str, Any] = Depends(_current_user),
    db: Session = Depends(get_db),
):
    return [
        dict(row)
        for row in db.execute(
            text("""
                SELECT *
                FROM ccr_attachments
                WHERE ccr_id = :ccr_id
                  AND COALESCE(is_deleted, FALSE) = FALSE
                ORDER BY uploaded_at DESC
            """),
            {"ccr_id": ccr_id},
        ).mappings().all()
    ]


@router.post("/cases/{ccr_id}/attachments")
async def upload_ccr_attachment(
    ccr_id: str,
    attachment_type: str = Form(..., min_length=1, max_length=100),
    title: str = Form(..., min_length=1, max_length=500),
    description: str = Form(default="", max_length=2000),
    file: UploadFile = File(...),
    user: dict[str, Any] = Depends(_current_user),
    db: Session = Depends(get_db),
):
    case_exists = db.execute(
        text("SELECT 1 FROM ccr_cases WHERE id = :id"),
        {"id": ccr_id},
    ).first()

    if not case_exists:
        raise HTTPException(status_code=404, detail="CCR case not found.")

    original_name = Path(file.filename or "attachment").name
    if not original_name:
        raise HTTPException(status_code=400, detail="Invalid file name.")

    safe_name = "".join(
        char if char.isalnum() or char in "._-" else "_"
        for char in original_name
    ).strip("._")

    if not safe_name:
        safe_name = "attachment"

    storage_path = (
        f"ccr/{ccr_id}/registration/"
        f"{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S%f')}_"
        f"{safe_name}"
    )

    target = _ccr_safe_path(storage_path)
    target.parent.mkdir(parents=True, exist_ok=True)

    size = 0

    try:
        with target.open("xb") as output:
            while chunk := await file.read(1024 * 1024):
                size += len(chunk)

                if size > _CCR_MAX_UPLOAD_SIZE:
                    raise HTTPException(
                        status_code=413,
                        detail="CCR attachments cannot exceed 50 MB.",
                    )

                output.write(chunk)

        if size == 0:
            raise HTTPException(
                status_code=400,
                detail="The selected file is empty.",
            )

        result = db.execute(
            text("""
                INSERT INTO ccr_attachments (
                    ccr_id,
                    attachment_type,
                    title,
                    description,
                    storage_bucket,
                    storage_path,
                    original_file_name,
                    mime_type,
                    file_size,
                    uploaded_at,
                    is_deleted
                )
                VALUES (
                    :ccr_id,
                    :attachment_type,
                    :title,
                    :description,
                    'ccr-files',
                    :storage_path,
                    :original_file_name,
                    :mime_type,
                    :file_size,
                    NOW(),
                    FALSE
                )
                RETURNING *
            """),
            {
                "ccr_id": ccr_id,
                "attachment_type": attachment_type,
                "title": title,
                "description": description,
                "storage_path": storage_path,
                "original_file_name": original_name,
                "mime_type": file.content_type or "application/octet-stream",
                "file_size": size,
            },
        ).mappings().first()

        db.commit()
        return dict(result)

    except Exception:
        db.rollback()
        target.unlink(missing_ok=True)
        raise

    finally:
        await file.close()


@router.get("/attachments/{attachment_id}/file")
def download_ccr_attachment(
    attachment_id: str,
    user: dict[str, Any] = Depends(_current_user),
    db: Session = Depends(get_db),
):
    attachment = db.execute(
        text("""
            SELECT storage_path, original_file_name, mime_type
            FROM ccr_attachments
            WHERE id = :id
              AND COALESCE(is_deleted, FALSE) = FALSE
            LIMIT 1
        """),
        {"id": attachment_id},
    ).mappings().first()

    if not attachment:
        raise HTTPException(status_code=404, detail="CCR attachment not found.")

    target = _ccr_safe_path(str(attachment["storage_path"]))

    if not target.is_file():
        raise HTTPException(status_code=404, detail="CCR attachment file not found.")

    return FileResponse(
        path=str(target),
        filename=attachment["original_file_name"] or target.name,
        media_type=attachment["mime_type"] or "application/octet-stream",
    )


@router.delete("/attachments/{attachment_id}")
def delete_ccr_attachment(
    attachment_id: str,
    user: dict[str, Any] = Depends(_current_user),
    db: Session = Depends(get_db),
):
    result = db.execute(
        text("""
            UPDATE ccr_attachments
            SET is_deleted = TRUE
            WHERE id = :id
              AND COALESCE(is_deleted, FALSE) = FALSE
        """),
        {"id": attachment_id},
    )

    db.commit()
    return {"success": result.rowcount > 0}

# ---------------------------------------------------------------------------
# Admin case deletion
# ---------------------------------------------------------------------------

@router.delete("/admin/cases/{ccr_id}")
def admin_delete_case(ccr_id: str, authorization: str | None = Header(default=None), user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    _require_admin(user)
    try:
        result = _function_result(db, "ccr_admin_delete_case", {"p_session_token": _bearer_token(authorization), "p_ccr_id": ccr_id})
        db.commit()
        return {"success": result is not False}
    except Exception as exc:
        db.rollback()
        raise HTTPException(status_code=400, detail="Unable to delete CCR case.") from exc


# ---------------------------------------------------------------------------
# Workflow master
# ---------------------------------------------------------------------------

@router.get("/workflow/stages")
def get_workflow_stages(active_only: bool = Query(False), user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    if active_only:
        rows = db.execute(text("SELECT * FROM ccr_workflow_stages WHERE is_active=TRUE ORDER BY display_order ASC")).mappings().all()
        return [dict(row) for row in rows]
    return _list_rows(db, "ccr_workflow_stages", order_by="display_order", ascending=True)


@router.post("/cases/{ccr_id}/workflow/advance")
def advance_workflow(ccr_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    return _advance_stage(db, ccr_id)


@router.get("/health")
def ccr_health():
    return {"status": "ok", "module": "CCR"}


def _ccr_report_rows(
    db: Session,
    sql: str,
    params: dict[str, Any],
) -> list[dict[str, Any]]:
    """Execute a CCR report query and return plain dictionaries."""
    rows = db.execute(
        text(sql),
        params,
    ).mappings().all()

    return [dict(row) for row in rows]


@router.get("/cases/{ccr_id}/report")
def get_case_report(
    ccr_id: str,
    db: Session = Depends(get_db),
    user: dict = Depends(_current_user),
):
    """
    Return all data required by the CCR report screen.

    Public endpoint. CCR report viewing does not require login.
    """

    params = {"ccr_id": ccr_id}

    # ------------------------------------------------------------
    # CASE DETAILS
    # ------------------------------------------------------------

    case_rows = _ccr_report_rows(
        db,
        """
        SELECT
            c.*,
            CASE
                WHEN s.id IS NULL THEN NULL
                ELSE jsonb_build_object(
                    'status_name', s.status_name
                )
            END AS ccr_statuses,
            CASE
                WHEN ws.id IS NULL THEN NULL
                ELSE jsonb_build_object(
                    'stage_name', ws.stage_name
                )
            END AS ccr_workflow_stages
        FROM ccr_cases c
        LEFT JOIN ccr_statuses s
    ON s.status_key = c.status
LEFT JOIN ccr_workflow_stages ws
    ON ws.stage_key = c.current_stage
        WHERE c.id::text = :ccr_id
        LIMIT 1
        """,
        params,
    )

    if not case_rows:
        raise HTTPException(
            status_code=404,
            detail="CCR case not found.",
        )

    case = case_rows[0]

    # ------------------------------------------------------------
    # CUSTOMER AND SUPPLIER VIEWS
    # ------------------------------------------------------------

    customer_rows = _ccr_report_rows(
        db,
        """
        SELECT *
        FROM ccr_customer_view
        WHERE ccr_id::text = :ccr_id
        LIMIT 1
        """,
        params,
    )

    supplier_rows = _ccr_report_rows(
        db,
        """
        SELECT *
        FROM ccr_supplier_view
        WHERE ccr_id::text = :ccr_id
        LIMIT 1
        """,
        params,
    )

    # ------------------------------------------------------------
    # CONTAINMENT
    # ------------------------------------------------------------

    containment_rows = _ccr_report_rows(
        db,
        """
        SELECT *
        FROM ccr_containment
        WHERE ccr_id::text = :ccr_id
        LIMIT 1
        """,
        params,
    )

    containment = (
        containment_rows[0]
        if containment_rows
        else None
    )

    sorting = []

    if containment and containment.get("id") is not None:
        sorting = _ccr_report_rows(
            db,
            """
            SELECT *
            FROM ccr_containment_sorting
            WHERE containment_id::text = :containment_id
            ORDER BY sorting_date ASC
            """,
            {
                "containment_id": str(containment["id"]),
            },
        )

    # ------------------------------------------------------------
    # ASSIGNMENTS
    # ------------------------------------------------------------

    assignments = _ccr_report_rows(
        db,
        """
        SELECT *
        FROM ccr_assignments
        WHERE ccr_id::text = :ccr_id
        ORDER BY created_at ASC
        """,
        params,
    )

    # ------------------------------------------------------------
    # FISHBONE CATEGORIES
    # ------------------------------------------------------------

    categories = _ccr_report_rows(
        db,
        """
        SELECT *
        FROM ccr_fishbone_categories
        WHERE is_active = TRUE
        ORDER BY display_order ASC
        """,
        params,
    )

    # ------------------------------------------------------------
    # FISHBONE CAUSES
    # ------------------------------------------------------------

    causes = _ccr_report_rows(
        db,
        """
        SELECT *
        FROM ccr_fishbone_causes
        WHERE ccr_id::text = :ccr_id
        ORDER BY display_order ASC
        """,
        params,
    )

    # ------------------------------------------------------------
    # ROOT CAUSE VALIDATIONS
    # ------------------------------------------------------------

    validations = _ccr_report_rows(
        db,
        """
        SELECT v.*
        FROM ccr_root_cause_validations v
        INNER JOIN ccr_fishbone_causes fc
            ON fc.id = v.fishbone_cause_id
        WHERE fc.ccr_id::text = :ccr_id
        """,
        params,
    )

    # ------------------------------------------------------------
    # WHY ANALYSES
    # ------------------------------------------------------------

    why_analyses = _ccr_report_rows(
        db,
        """
        SELECT wa.*
        FROM ccr_why_analyses wa
        INNER JOIN ccr_root_cause_validations rv
            ON rv.id = wa.validation_id
        INNER JOIN ccr_fishbone_causes fc
            ON fc.id = rv.fishbone_cause_id
        WHERE fc.ccr_id::text = :ccr_id
        ORDER BY wa.created_at ASC
        """,
        params,
    )

    # ------------------------------------------------------------
    # WHY STEPS
    # ------------------------------------------------------------

    why_steps = _ccr_report_rows(
        db,
        """
        SELECT ws.*
        FROM ccr_why_steps ws
        INNER JOIN ccr_why_analyses wa
            ON wa.id = ws.analysis_id
        INNER JOIN ccr_root_cause_validations rv
            ON rv.id = wa.validation_id
        INNER JOIN ccr_fishbone_causes fc
            ON fc.id = rv.fishbone_cause_id
        WHERE fc.ccr_id::text = :ccr_id
        ORDER BY ws.why_number ASC
        """,
        params,
    )

    # ------------------------------------------------------------
    # CORRECTIVE ACTIONS
    # ------------------------------------------------------------

    actions = _ccr_report_rows(
    db,
    """
   SELECT
    ca.*,

    COALESCE(
             (
                SELECT NULLIF(BTRIM(ws.why_text), '')
                FROM ccr_why_analyses a
                JOIN ccr_why_steps ws
                    ON ws.analysis_id = a.id
                WHERE a.validation_id = ca.validation_id
                  AND LOWER(TRIM(a.analysis_type)) = 'occurrence'
                  AND NULLIF(BTRIM(ws.why_text), '') IS NOT NULL
                ORDER BY ws.why_number DESC
                LIMIT 1
            ),
            (
                SELECT NULLIF(BTRIM(a.potential_root_cause), '')
                FROM ccr_why_analyses a
                WHERE a.validation_id = ca.validation_id
                  AND LOWER(TRIM(a.analysis_type)) = 'occurrence'
                LIMIT 1
            ),
            ''
        ) AS occurrence_root_cause,

        COALESCE(
            (
                SELECT NULLIF(BTRIM(ws.why_text), '')
                FROM ccr_why_analyses a
                JOIN ccr_why_steps ws
                    ON ws.analysis_id = a.id
                WHERE a.validation_id = ca.validation_id
                  AND LOWER(TRIM(a.analysis_type)) = 'non_detection'
                  AND NULLIF(BTRIM(ws.why_text), '') IS NOT NULL
                ORDER BY ws.why_number DESC
                LIMIT 1
            ),
            (
                SELECT NULLIF(BTRIM(a.potential_root_cause), '')
                FROM ccr_why_analyses a
                WHERE a.validation_id = ca.validation_id
                  AND LOWER(TRIM(a.analysis_type)) = 'non_detection'
                LIMIT 1
            ),
            ''
        ) AS detection_root_cause

    FROM ccr_corrective_actions ca

    LEFT JOIN ccr_cases c
        ON c.id = ca.ccr_id

    WHERE ca.ccr_id::text = :ccr_id

    ORDER BY ca.created_at ASC
    """,
    params,
)

    # Verification is a one-to-one relationship.
    # The unique index confirms one verification per action.

    verifications = _ccr_report_rows(
        db,
        """
        SELECT v.*
        FROM ccr_action_verifications v
        INNER JOIN ccr_corrective_actions ca
            ON ca.id = v.corrective_action_id
        WHERE ca.ccr_id::text = :ccr_id
        """,
        params,
    )

    verification_by_action = {
        str(item["corrective_action_id"]): item
        for item in verifications
    }

    for action in actions:
        action["ccr_action_verifications"] = (
            verification_by_action.get(
                str(action["id"])
            )
        )

    # ------------------------------------------------------------
    # ALL CCR ATTACHMENTS
    # ------------------------------------------------------------

    attachments = _ccr_report_rows(
        db,
        """
        SELECT *
        FROM ccr_attachments
        WHERE ccr_id::text = :ccr_id
          AND is_deleted = FALSE
        ORDER BY uploaded_at ASC
        """,
        params,
    )

    # ------------------------------------------------------------
    # CORRECTIVE ACTION EVIDENCE
    # ------------------------------------------------------------

    action_evidence = _ccr_report_rows(
        db,
        """
        SELECT
            e.*,
            CASE
                WHEN a.id IS NULL THEN NULL
                ELSE jsonb_build_object(
                    'id', a.id,
                    'attachment_type', a.attachment_type,
                    'title', a.title,
                    'description', a.description,
                    'storage_bucket', a.storage_bucket,
                    'storage_path', a.storage_path,
                    'original_file_name', a.original_file_name,
                    'mime_type', a.mime_type,
                    'file_size', a.file_size,
                    'uploaded_at', a.uploaded_at,
                    'is_deleted', a.is_deleted
                )
            END AS ccr_attachments
        FROM ccr_action_evidence e
        INNER JOIN ccr_corrective_actions ca
            ON ca.id = e.corrective_action_id
        LEFT JOIN ccr_attachments a
            ON a.id = e.attachment_id
        WHERE ca.ccr_id::text = :ccr_id
        ORDER BY e.created_at ASC
        """,
        params,
    )

    # ------------------------------------------------------------
    # CLOSURE
    # ------------------------------------------------------------

    closure_rows = _ccr_report_rows(
        db,
        """
        SELECT *
        FROM ccr_closure
        WHERE ccr_id::text = :ccr_id
        LIMIT 1
        """,
        params,
    )

    closure = (
        closure_rows[0]
        if closure_rows
        else None
    )

    # ------------------------------------------------------------
    # RESPONSE
    # ------------------------------------------------------------

    return {
        "case": case,
        "customer_view": (
            customer_rows[0]
            if customer_rows
            else None
        ),
        "supplier_view": (
            supplier_rows[0]
            if supplier_rows
            else None
        ),
        "containment": containment,
        "sorting": sorting,
        "assignments": assignments,
        "categories": categories,
        "causes": causes,
        "validations": validations,
        "why_analyses": why_analyses,
        "why_steps": why_steps,
        "actions": actions,
        "attachments": attachments,
        "action_evidence": action_evidence,
        "closure": closure,
    }
# ============================================================
# ASSIGNMENT STATUSES
# ============================================================

@router.get("/assignment-statuses")
def get_assignment_statuses(
    db: Session = Depends(get_db),
):
    rows = db.execute(
        text("""
            SELECT
                status_key,
                status_name,
                is_active,
                display_order
            FROM ccr_assignment_statuses
            WHERE is_active = TRUE
            ORDER BY display_order ASC
        """)
    ).mappings().all()

    return [dict(row) for row in rows]

# ============================================================
# CCR CLOSURE
# ============================================================

def _save_ccr_closure_row(
    db: Session,
    ccr_id: str,
    data: dict,
    closure_status: str,
):
    """
    Insert or update one closure record for a CCR.
    Does not depend on an ON CONFLICT constraint.
    """

    params = {
        "ccr_id": ccr_id,
        "closure_status": closure_status,
        "closure_summary": data.get("closure_summary"),
        "customer_response": data.get("customer_response"),
        "final_remarks": data.get("final_remarks"),
        "closed_by": data.get("closed_by"),
        "closed_at": data.get("closed_at"),
    }

    existing = db.execute(
        text("""
            SELECT id
            FROM ccr_closure
            WHERE ccr_id = CAST(:ccr_id AS uuid)
            LIMIT 1
        """),
        {"ccr_id": ccr_id},
    ).mappings().first()

    if existing:
        result = db.execute(
            text("""
                UPDATE ccr_closure
                SET
                    closure_status = :closure_status,
                    closure_summary = :closure_summary,
                    customer_response = :customer_response,
                    final_remarks = :final_remarks,
                    closed_by = :closed_by,
                    closed_at = CAST(:closed_at AS timestamptz),
                    updated_at = NOW()
                WHERE id = :id
                RETURNING *
            """),
            {
                **params,
                "id": existing["id"],
            },
        )
    else:
        result = db.execute(
            text("""
                INSERT INTO ccr_closure (
                    ccr_id,
                    closure_status,
                    closure_summary,
                    customer_response,
                    final_remarks,
                    closed_by,
                    closed_at
                )
                VALUES (
                    CAST(:ccr_id AS uuid),
                    :closure_status,
                    :closure_summary,
                    :customer_response,
                    :final_remarks,
                    :closed_by,
                    CAST(:closed_at AS timestamptz)
                )
                RETURNING *
            """),
            params,
        )

    row = result.mappings().first()

    if not row:
        raise HTTPException(
            status_code=500,
            detail="Could not save CCR closure information.",
        )

    return dict(row)


@router.get("/cases/{ccr_id}/closure")
def get_ccr_closure(
    ccr_id: str,
    db: Session = Depends(get_db),
):
    """Get closure information for one CCR."""

    row = db.execute(
        text("""
            SELECT *
            FROM ccr_closure
            WHERE ccr_id = :ccr_id
            LIMIT 1
        """),
        {"ccr_id": ccr_id},
    ).mappings().first()

    return dict(row) if row else None


@router.put("/cases/{ccr_id}/closure")
def save_ccr_closure(
    ccr_id: str,
    payload: dict,
    db: Session = Depends(get_db),
):
    """Save closure draft."""

    data = payload.get("data", payload)

    if not isinstance(data, dict):
        raise HTTPException(
            status_code=400,
            detail="Invalid closure payload.",
        )

    closure_status = str(
        data.get("closure_status") or "pending"
    ).strip().lower()

    if closure_status not in {"pending", "closed"}:
        raise HTTPException(
            status_code=400,
            detail="Invalid closure status.",
        )

    row = _save_ccr_closure_row(
        db=db,
        ccr_id=ccr_id,
        data=data,
        closure_status=closure_status,
    )

    db.commit()

    return row


@router.post("/cases/{ccr_id}/closure/complete")
def complete_ccr_closure(
    ccr_id: str,
    payload: dict,
    db: Session = Depends(get_db),
):
    """Save final closure information and close the CCR."""

    data = payload.get("data", payload)

    if not isinstance(data, dict):
        raise HTTPException(
            status_code=400,
            detail="Invalid closure payload.",
        )

    if not str(data.get("closure_summary") or "").strip():
        raise HTTPException(
            status_code=400,
            detail="Closure Summary is required.",
        )

    if not str(data.get("closed_by") or "").strip():
        raise HTTPException(
            status_code=400,
            detail="Closed By is required.",
        )

    if not data.get("closed_at"):
        raise HTTPException(
            status_code=400,
            detail="Closed At date is required.",
        )

    closed_status = db.execute(
        text("""
            SELECT status_key
            FROM ccr_statuses
            WHERE is_active = TRUE
              AND LOWER(status_name) = 'closed'
            LIMIT 1
        """)
    ).mappings().first()

    if not closed_status:
        raise HTTPException(
            status_code=400,
            detail="No active Closed status is configured in CCR status master.",
        )

    row = _save_ccr_closure_row(
        db=db,
        ccr_id=ccr_id,
        data=data,
        closure_status="closed",
    )

    db.execute(
        text("""
            UPDATE ccr_cases
            SET
                status = :status,
                updated_at = NOW()
            WHERE id = :ccr_id
        """),
        {
            "status": closed_status["status_key"],
            "ccr_id": ccr_id,
        },
    )

    db.commit()

    return {
        "success": True,
        "message": "CCR closed successfully.",
        "closure": row,
        "status": closed_status["status_key"],
    }

# ---------------------------------------------------------------------------
# Corrective Action Evidence
# ---------------------------------------------------------------------------

@router.get("/cases/{ccr_id}/action-evidence")
def get_corrective_action_evidence(
    ccr_id: str,
    user: dict[str, Any] = Depends(_current_user),
    db: Session = Depends(get_db),
):
    rows = db.execute(
        text("""
            SELECT
                e.*,
                CASE
                    WHEN a.id IS NULL THEN NULL
                    ELSE jsonb_build_object(
                        'id', a.id,
                        'attachment_type', a.attachment_type,
                        'title', a.title,
                        'description', a.description,
                        'storage_bucket', a.storage_bucket,
                        'storage_path', a.storage_path,
                        'original_file_name', a.original_file_name,
                        'mime_type', a.mime_type,
                        'file_size', a.file_size,
                        'uploaded_at', a.uploaded_at,
                        'is_deleted', a.is_deleted
                    )
                END AS ccr_attachments
            FROM ccr_action_evidence e
            INNER JOIN ccr_corrective_actions ca
                ON ca.id = e.corrective_action_id
            LEFT JOIN ccr_attachments a
                ON a.id = e.attachment_id
            WHERE ca.ccr_id = :ccr_id
              AND (
                  a.id IS NULL
                  OR COALESCE(a.is_deleted, FALSE) = FALSE
              )
            ORDER BY e.created_at ASC
        """),
        {"ccr_id": ccr_id},
    ).mappings().all()

    return [dict(row) for row in rows]


@router.post("/action-evidence")
def create_corrective_action_evidence(
    body: RowBody,
    user: dict[str, Any] = Depends(_current_user),
    db: Session = Depends(get_db),
):
    data = dict(body.data)

    action_id = str(
        data.get("corrective_action_id") or ""
    ).strip()

    attachment_id = str(
        data.get("attachment_id") or ""
    ).strip()

    evidence_type = str(
        data.get("evidence_type") or ""
    ).strip().lower()

    if not action_id or not attachment_id:
        raise HTTPException(
            status_code=400,
            detail="Corrective action and attachment are required.",
        )

    if evidence_type not in {"before", "after"}:
        raise HTTPException(
            status_code=400,
            detail="Evidence type must be before or after.",
        )

    action = db.execute(
        text("""
            SELECT id, ccr_id
            FROM ccr_corrective_actions
            WHERE id = :id
            LIMIT 1
        """),
        {"id": action_id},
    ).mappings().first()

    if not action:
        raise HTTPException(
            status_code=404,
            detail="Corrective action not found.",
        )

    attachment = db.execute(
        text("""
            SELECT id, ccr_id
            FROM ccr_attachments
            WHERE id = :id
              AND COALESCE(is_deleted, FALSE) = FALSE
            LIMIT 1
        """),
        {"id": attachment_id},
    ).mappings().first()

    if not attachment:
        raise HTTPException(
            status_code=404,
            detail="Evidence attachment not found.",
        )

    if str(action["ccr_id"]) != str(attachment["ccr_id"]):
        raise HTTPException(
            status_code=400,
            detail="Evidence attachment does not belong to this CCR.",
        )

    result = db.execute(
        text("""
            INSERT INTO ccr_action_evidence (
                corrective_action_id,
                evidence_type,
                title,
                description,
                attachment_id,
                created_by,
                created_at
            )
            VALUES (
                :action_id,
                :evidence_type,
                :title,
                :description,
                :attachment_id,
                :created_by,
                NOW()
            )
            RETURNING *
        """),
        {
            "action_id": action_id,
            "evidence_type": evidence_type,
            "title": data.get("title"),
            "description": data.get("description"),
            "attachment_id": attachment_id,
            "created_by": user.get("id"),
        },
    ).mappings().first()

    db.commit()

    return dict(result)


@router.delete("/action-evidence/{evidence_id}")
def delete_corrective_action_evidence(
    evidence_id: str,
    user: dict[str, Any] = Depends(_current_user),
    db: Session = Depends(get_db),
):
    try:
        evidence = db.execute(
            text("""
                SELECT attachment_id
                FROM ccr_action_evidence
                WHERE id = :id
                LIMIT 1
            """),
            {"id": evidence_id},
        ).mappings().first()

        if not evidence:
            raise HTTPException(
                status_code=404,
                detail="Corrective action evidence not found.",
            )

        attachment_id = evidence.get("attachment_id")

        attachment = None

        if attachment_id:
            attachment = db.execute(
                text("""
                    SELECT storage_path
                    FROM ccr_attachments
                    WHERE id = :id
                    LIMIT 1
                """),
                {"id": attachment_id},
            ).mappings().first()

        db.execute(
            text("""
                DELETE FROM ccr_action_evidence
                WHERE id = :id
            """),
            {"id": evidence_id},
        )

        if attachment_id:
            db.execute(
                text("""
                    UPDATE ccr_attachments
                    SET is_deleted = TRUE
                    WHERE id = :id
                """),
                {"id": attachment_id},
            )

        db.commit()

        # Remove the physical file after the database transaction succeeds.
        if attachment and attachment.get("storage_path"):
            try:
                target = _ccr_safe_path(
                    str(attachment["storage_path"])
                )
                target.unlink(missing_ok=True)
            except (OSError, HTTPException):
                pass

        return {"success": True}

    except HTTPException:
        db.rollback()
        raise
    except Exception:
        db.rollback()
        raise
