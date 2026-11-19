from __future__ import annotations

import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

from fastapi import (
    APIRouter,
    Depends,
    File,
    Header,
    HTTPException,
    Query,
    UploadFile,
    status,
)
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db.session import get_db

router = APIRouter(prefix="/dcc", tags=["DCC"])

# Explicit allow-lists. Never accept table or column names directly from clients.
TABLES = {
    "documents": ("dcc_documents", {
        "id","document_no","document_name","department","document_type","revision",
        "attachment_name","attachment_path","released_pdf_name","released_pdf_path",
        "created_by_name","created_by_email","hod_name","hod_email","dcc_name","dcc_email",
        "status","submitted_at","hod_action_at","dcc_action_at","rejection_reason","remarks",
        "candidate_name","employee_id","released_by_name","released_by_email","revision_date","folder_name"
    }),
    "folders": ("dcc_folders", {"id","name","created_by_name","created_by_email","created_at"}),
    "master-data": ("dcc_master_data", {
        "document_no","document_name","document_type","department","candidate_name",
        "candidate_email","created_by_name","created_by_email","updated_at","revision"
    }),
    "activities": ("dcc_activities", {
        "id","user_email","user_name","action","description","document_no","timestamp","created_at"
    }),
    "notifications": ("dcc_notifications", {
        "id","recipient_email","title","message","type","document_no","document_request_id","created_at","is_read"
    }),
    "document-requests": ("dcc_document_requests", {
        "id","document_name","user_name","user_email","description","document_no","document_type",
        "department","candidate_name","candidate_email","status","created_at","notified_at"
    }),
    "dmr-requests": ("dcc_dmr_requests", {
        "id","document_id","document_no","document_name","document_type","department",
        "requested_by_name","requested_by_email","hod_name","hod_email","current_revision",
        "request_reason","status","rejection_reason","created_date","hod_action_date","dcc_action_date",
        "source_file_path","source_file_name","revised_file_path","revised_file_name",
        "revised_submitted_date","revised_rejection_reason","modification_access_granted","updated_at"
    }),
}
READ_ROLES = {"ADMIN", "DCC", "HOD", "USER"}
WRITE_ROLES = {"ADMIN", "DCC", "HOD", "USER"}

class LoginBody(BaseModel):
    email: str
    password: str = Field(min_length=1, max_length=256)

class UserCreate(BaseModel):
    id: str = Field(min_length=1, max_length=128)
    name: str = Field(min_length=1, max_length=200)
    email: str
    role: str
    hod_name: str = ""
    hod_email: str = ""
    password: str = Field(min_length=8, max_length=128)
    active: bool = True

class PasswordChange(BaseModel):
    current_password: str = Field(min_length=1, max_length=256)
    new_password: str = Field(min_length=8, max_length=128)

class RowBody(BaseModel):
    data: dict[str, Any]

def _hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()

def _user_for_token(db: Session, token: str | None) -> dict[str, Any]:
    if not token:
        raise HTTPException(status_code=401, detail="DCC login is required.")
    token_hash = _hash_token(token)
    row = db.execute(text("""
        SELECT u.id, u.name, u.email, u.role, u.hod_name, u.hod_email, u.active
        FROM dcc_sessions s
        JOIN dcc_users u ON u.id = s.user_id
        WHERE s.token_hash = :token_hash
          AND s.revoked_at IS NULL
          AND s.expires_at > NOW()
          AND u.active = TRUE
          AND COALESCE(u.deleted_at, NULL) IS NULL
        LIMIT 1
    """), {"token_hash": token_hash}).mappings().first()
    if not row:
        raise HTTPException(status_code=401, detail="DCC session is invalid or expired.")
    db.execute(text("UPDATE dcc_sessions SET last_seen_at = NOW() WHERE token_hash = :h"),
               {"h": token_hash})
    return dict(row)

def current_user(db: Session = Depends(get_db),
                 authorization: str | None = None) -> dict[str, Any]:
    # Header extraction is done by FastAPI Header in the wrapper below.
    raise RuntimeError("Use _current_user dependency")

from fastapi import Header
def _current_user(authorization: str | None = Header(default=None),
                  db: Session = Depends(get_db)) -> dict[str, Any]:
    scheme, _, token = (authorization or "").partition(" ")
    if scheme.lower() != "bearer" or not token.strip():
        raise HTTPException(status_code=401, detail="DCC bearer token is required.")
    return _user_for_token(db, token.strip())

def _require(user: dict[str, Any], *roles: str):
    if str(user["role"]).upper() not in set(roles):
        raise HTTPException(status_code=403, detail="You are not authorized for this DCC operation.")

def _safe_data(resource: str, data: dict[str, Any], *, partial: bool = False) -> dict[str, Any]:
    if resource not in TABLES:
        raise HTTPException(status_code=404, detail="Unknown DCC resource.")
    allowed = TABLES[resource][1]
    clean = {k: v for k, v in data.items() if k in allowed}
    if not clean:
        raise HTTPException(status_code=400, detail="No valid fields supplied.")
    return clean

@router.post("/auth/login")
def login(body: LoginBody, db: Session = Depends(get_db)):
    row = db.execute(text("""
        SELECT id, name, email, role, hod_name, hod_email, active, password,
               COALESCE(deleted_at, NULL) AS deleted_at
        FROM dcc_users WHERE LOWER(email)=LOWER(:email) LIMIT 1
    """), {"email": body.email.strip()}).mappings().first()
    # Password comparison is performed by pgcrypto, never in application code.
    if "@" not in body.email or not row or not row["password"] or not db.execute(
        text("SELECT crypt(:pw, :hash) = :hash"),
        {"pw": body.password, "hash": row["password"]}
    ).scalar():
        return {"status": "INVALID"}
    if row["deleted_at"] is not None:
        return {"status": "DELETED"}
    if not row["active"]:
        return {"status": "DISABLED"}
    token = secrets.token_hex(32)
    expires = datetime.now(timezone.utc) + timedelta(hours=8)
    db.execute(text("""
        INSERT INTO dcc_sessions(token_hash,user_id,expires_at,last_seen_at)
        VALUES (:h,:uid,:exp,NOW())
    """), {"h": _hash_token(token), "uid": row["id"], "exp": expires})
    db.commit()
    return {
        "status": "SUCCESS", "session_token": token, "expires_at": expires.isoformat(),
        "user": {k: row[k] for k in ("id","name","email","role","hod_name","hod_email","active")}
    }

@router.get("/auth/session")
def validate_session(user: dict[str, Any] = Depends(_current_user)):
    return {"valid": True, "user": user}

@router.post("/auth/logout")
def logout(authorization: str | None = Header(default=None), db: Session = Depends(get_db)):
    scheme, _, token = (authorization or "").partition(" ")
    if scheme.lower() != "bearer" or not token.strip():
        return {"success": False}
    result = db.execute(text("""
        UPDATE dcc_sessions SET revoked_at=NOW()
        WHERE token_hash=:h AND revoked_at IS NULL
    """), {"h": _hash_token(token.strip())})
    db.commit()
    return {"success": result.rowcount > 0}

@router.post("/auth/change-password")
def change_password(body: PasswordChange, user: dict[str, Any] = Depends(_current_user),
                    authorization: str | None = Header(default=None), db: Session = Depends(get_db)):
    token = authorization.split(" ",1)[1].strip()
    result = db.execute(text("""
        UPDATE dcc_users SET password=crypt(:new, gen_salt('bf')), updated_at=NOW()
        WHERE id=:uid AND active=TRUE
          AND password=crypt(:old,password)
    """), {"new": body.new_password, "uid": user["id"], "old": body.current_password})
    if result.rowcount != 1:
        db.rollback()
        return {"success": False}
    db.execute(text("""
        UPDATE dcc_sessions SET revoked_at=NOW()
        WHERE user_id=:uid AND revoked_at IS NULL
    """), {"uid": user["id"]})
    db.commit()
    return {"success": True, "message": "Password changed. Please log in again."}

@router.get("/users")
def get_users(user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    _require(user, "ADMIN")
    rows = db.execute(text("""
        SELECT id,name,email,role,hod_name,hod_email,active,created_at,updated_at,deleted_at
        FROM dcc_users ORDER BY created_at ASC
    """)).mappings().all()
    return [dict(r) for r in rows]

@router.post("/users")
def create_user(body: UserCreate, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    _require(user, "ADMIN")
    role = body.role.strip().upper()
    if "@" not in body.email or role not in {"ADMIN","DCC","HOD","USER"}:
        raise HTTPException(400, "Invalid DCC role.")
    db.execute(text("""
        INSERT INTO dcc_users(id,name,email,role,hod_name,hod_email,password,active,created_at,updated_at,deleted_at)
        VALUES (:id,:name,LOWER(:email),:role,:hod_name,LOWER(:hod_email),crypt(:password,gen_salt('bf')),:active,NOW(),NOW(),NULL)
    """), {**body.model_dump(), "email": body.email, "role": role})
    db.commit()
    return {"success": True}

@router.patch("/users/{user_id}/active")
def set_user_active(user_id: str, active: bool = Query(...),
                    user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    _require(user, "ADMIN")
    target = db.execute(text("SELECT role,active,deleted_at FROM dcc_users WHERE id=:id FOR UPDATE"),
                        {"id": user_id}).mappings().first()
    if not target: raise HTTPException(404, "User not found.")
    if target["deleted_at"] is not None: raise HTTPException(409, "Deleted account must be restored first.")
    if not active:
        if user_id == user["id"]: raise HTTPException(400, "You cannot deactivate your own account.")
        if str(target["role"]).upper() == "ADMIN" and target["active"]:
            count = db.execute(text("SELECT COUNT(*) FROM dcc_users WHERE UPPER(role)='ADMIN' AND active AND deleted_at IS NULL")).scalar_one()
            if count <= 1: raise HTTPException(400, "Cannot deactivate the last active Admin.")
    db.execute(text("UPDATE dcc_users SET active=:a,updated_at=NOW() WHERE id=:id"),
               {"a": active, "id": user_id})
    if not active:
        db.execute(text("UPDATE dcc_sessions SET revoked_at=NOW() WHERE user_id=:id AND revoked_at IS NULL"), {"id": user_id})
    db.commit()
    return {"success": True}

@router.delete("/users/{user_id}")
def delete_user(user_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    _require(user, "ADMIN")
    if user_id == user["id"]: raise HTTPException(400, "You cannot delete your own account.")
    target = db.execute(text("SELECT role,active,deleted_at FROM dcc_users WHERE id=:id FOR UPDATE"), {"id": user_id}).mappings().first()
    if not target: raise HTTPException(404, "User not found.")
    if target["deleted_at"] is not None: return {"success": False}
    if str(target["role"]).upper() == "ADMIN" and target["active"]:
        count = db.execute(text("SELECT COUNT(*) FROM dcc_users WHERE UPPER(role)='ADMIN' AND active AND deleted_at IS NULL")).scalar_one()
        if count <= 1: raise HTTPException(400, "Cannot delete the last active Admin.")
    db.execute(text("UPDATE dcc_users SET active=FALSE,deleted_at=NOW(),updated_at=NOW() WHERE id=:id"), {"id": user_id})
    db.execute(text("UPDATE dcc_sessions SET revoked_at=NOW() WHERE user_id=:id AND revoked_at IS NULL"), {"id": user_id})
    db.commit()
    return {"success": True}

@router.post("/users/{user_id}/restore")
def restore_user(user_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    _require(user, "ADMIN")
    result = db.execute(text("UPDATE dcc_users SET active=TRUE,deleted_at=NULL,updated_at=NOW() WHERE id=:id AND deleted_at IS NOT NULL"), {"id": user_id})
    db.commit()
    return {"success": result.rowcount == 1}

@router.post("/master-data/upsert")
def master_data_upsert(body: RowBody, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    _require(user, "ADMIN", "DCC")
    data = _safe_data("master-data", body.data)
    if not data.get("document_no"):
        raise HTTPException(400, "document_no is required")
    cols = list(data)
    params = {f"v_{k}":v for k,v in data.items()}
    updates = [f"{k}=EXCLUDED.{k}" for k in cols if k != "document_no"]
    sql = f"INSERT INTO dcc_master_data ({','.join(cols)}) VALUES ({','.join(':'+f'v_{k}' for k in cols)}) ON CONFLICT (document_no) DO UPDATE SET {','.join(updates)}"
    db.execute(text(sql), params); db.commit()
    row = db.execute(text("SELECT * FROM dcc_master_data WHERE document_no=:no"), {"no":data["document_no"]}).mappings().first()
    return dict(row) if row else {"success":True}

@router.post("/notifications/read-all")
def notifications_read_all(user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    db.execute(text("UPDATE dcc_notifications SET is_read=TRUE WHERE LOWER(recipient_email)=LOWER(:e) AND is_read=FALSE"), {"e":user["email"]})
    db.commit(); return {"success":True}

@router.delete("/notifications/clear")
def notifications_clear(user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    result=db.execute(text("DELETE FROM dcc_notifications WHERE LOWER(recipient_email)=LOWER(:e)"), {"e":user["email"]})
    db.commit(); return {"success":True,"deleted":result.rowcount}
@router.get("/{resource}")
def list_resource(
    resource: str,
    authorization: str | None = Header(default=None),
    limit: int = Query(200, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    email: str | None = None,
    status_filter: str | None = None,
    db: Session = Depends(get_db),
):
    if resource not in TABLES:
        raise HTTPException(
            status_code=404,
            detail="Unknown DCC resource.",
        )

    table, columns = TABLES[resource]

    # ---------------------------------------------------------
    # AUTHENTICATION IS OPTIONAL FOR PUBLIC DCC CONTENT
    # ---------------------------------------------------------

    user = None

    if authorization:
        scheme, _, token = authorization.partition(" ")

        if scheme.lower() == "bearer" and token.strip():
            user = _user_for_token(db, token.strip())

    # ---------------------------------------------------------
    # PUBLIC ACCESS
    #
    # Released documents:
    #   No login required
    #
    # Folders/sidebar:
    #   No login required
    # ---------------------------------------------------------

    if user is None:

        if resource == "folders":
            rows = db.execute(
                text(
                    f"""
                    SELECT *
                    FROM {table}
                    ORDER BY name ASC
                    LIMIT :limit
                    OFFSET :offset
                    """
                ),
                {
                    "limit": limit,
                    "offset": offset,
                },
            ).mappings().all()

            return [dict(row) for row in rows]

        if resource == "documents":
            rows = db.execute(
                text(
                    f"""
                    SELECT *
                    FROM {table}
                    WHERE LOWER(COALESCE(status, '')) = 'released'
                    ORDER BY revision_date DESC
                    LIMIT :limit
                    OFFSET :offset
                    """
                ),
                {
                    "limit": limit,
                    "offset": offset,
                },
            ).mappings().all()

            return [dict(row) for row in rows]

        # All other resources require authentication.
        raise HTTPException(
            status_code=401,
            detail="Login is required to access this DCC resource.",
        )

    # ---------------------------------------------------------
    # AUTHENTICATED ACCESS
    # ---------------------------------------------------------

    _require(user, *READ_ROLES)

    clauses = []
    params = {
        "limit": limit,
        "offset": offset,
    }

    role = str(user["role"]).upper()

    # ---------------------------------------------------------
    # USER ROLE RESTRICTIONS
    # ---------------------------------------------------------

    if resource in {
        "documents",
        "dmr-requests",
        "document-requests",
        "activities",
        "notifications",
    }:

        if role == "USER":

            if resource == "documents":
                clauses.append(
                    """
                    (
                        LOWER(created_by_email) = LOWER(:email)
                        OR LOWER(status) = 'released'
                    )
                    """
                )

            elif resource == "dmr-requests":
                clauses.append(
                    "LOWER(requested_by_email)=LOWER(:email)"
                )

            elif resource == "document-requests":
                clauses.append(
                    "LOWER(user_email)=LOWER(:email)"
                )

            elif resource == "activities":
                clauses.append(
                    "LOWER(user_email)=LOWER(:email)"
                )

            elif resource == "notifications":
                clauses.append(
                    "LOWER(recipient_email)=LOWER(:email)"
                )

            params["email"] = user["email"]

        elif role == "HOD":

            if resource == "documents":
                clauses.append(
                    "LOWER(hod_email)=LOWER(:email)"
                )

            elif resource == "dmr-requests":
                clauses.append(
                    "LOWER(hod_email)=LOWER(:email)"
                )

            elif resource == "activities":
                clauses.append(
                    "LOWER(user_email)=LOWER(:email)"
                )

            elif resource == "notifications":
                clauses.append(
                    "LOWER(recipient_email)=LOWER(:email)"
                )

            params["email"] = user["email"]

    # ---------------------------------------------------------
    # EMAIL FILTER
    # ---------------------------------------------------------

    if email:

        if role not in {"ADMIN", "DCC"}:
            raise HTTPException(
                status_code=403,
                detail="Email filtering is not permitted.",
            )

        field = {
            "activities": "user_email",
            "notifications": "recipient_email",
            "dmr-requests": "requested_by_email",
            "document-requests": "user_email",
            "documents": "created_by_email",
        }.get(resource)

        if field:
            clauses.append(
                f"LOWER({field})=LOWER(:filter_email)"
            )

            params["filter_email"] = email

    # ---------------------------------------------------------
    # STATUS FILTER
    # ---------------------------------------------------------

    if status_filter and "status" in columns:
        clauses.append("status=:status")
        params["status"] = status_filter

    # ---------------------------------------------------------
    # QUERY
    # ---------------------------------------------------------

    where = ""

    if clauses:
        where = " WHERE " + " AND ".join(clauses)

    order = {
        "documents": "revision_date",
        "folders": "created_at",
        "master-data": "document_no",
        "activities": "timestamp",
        "notifications": "created_at",
        "document-requests": "created_at",
        "dmr-requests": "created_date",
    }[resource]

    rows = db.execute(
        text(
            f"""
            SELECT *
            FROM {table}
            {where}
            ORDER BY {order} DESC
            LIMIT :limit
            OFFSET :offset
            """
        ),
        params,
    ).mappings().all()

    return [dict(row) for row in rows]
@router.get("/files/download")
def download_file(
    path: str = Query(...),
    access_token: str | None = Query(default=None),
    authorization: str | None = Header(default=None),
    db: Session = Depends(get_db),
):
    # Normalize the requested path
    normalized_path = path.replace("\\", "/").strip()

    # Remove leading slash and harmless ./ segments
    while normalized_path.startswith("/"):
        normalized_path = normalized_path[1:]

    normalized_path = normalized_path.replace("./", "")

    if not normalized_path:
        raise HTTPException(
            status_code=400,
            detail="File path is required.",
        )

    # ---------------------------------------------------------
    # PUBLIC RELEASED DOCUMENTS
    # ---------------------------------------------------------

    is_public_released = (
        normalized_path.lower().startswith("released/")
    )

    if is_public_released:

        target = _safe_path(normalized_path)

        if not target.is_file():
            raise HTTPException(
                status_code=404,
                detail=f"Released file not found: {normalized_path}",
            )

        # Verify that this exact file is associated with a released
        # document in the database.
        released_record = db.execute(
            text(
                """
                SELECT id
                FROM dcc_documents
                WHERE LOWER(COALESCE(status, '')) = 'released'
                  AND (
                        released_pdf_path = :path
                        OR attachment_path = :path
                  )
                LIMIT 1
                """
            ),
            {
                "path": normalized_path,
            },
        ).first()

        if not released_record:
            raise HTTPException(
                status_code=403,
                detail="This file is not associated with a released DCC document.",
            )

        return FileResponse(
    path=str(target),
    filename=target.name,
    content_disposition_type="inline",
)

    # ---------------------------------------------------------
    # PRIVATE DOCUMENTS
    # ---------------------------------------------------------

    token = access_token

    if not token and authorization:
        scheme, _, bearer_value = authorization.partition(" ")

        if scheme.lower() == "bearer":
            token = bearer_value.strip()

    user = _user_for_token(
        db,
        token,
    )

    target = _safe_path(normalized_path)

    if not target.is_file():
        raise HTTPException(
            status_code=404,
            detail="Document file not found.",
        )

    return FileResponse(
    path=str(target),
    filename=target.name,
    content_disposition_type="inline",
)
@router.get("/{resource}/{row_id}")
def get_resource(resource: str, row_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    if resource not in TABLES: raise HTTPException(404, "Unknown DCC resource.")
    table, cols = TABLES[resource]
    key = "document_no" if resource == "master-data" else "id"
    if key not in cols: raise HTTPException(400, "Unsupported resource key.")
    row = db.execute(text(f"SELECT * FROM {table} WHERE {key}=:id LIMIT 1"), {"id": row_id}).mappings().first()
    if not row: raise HTTPException(404, "Record not found.")
    role = str(user["role"]).upper()
    if resource == "documents":
        if role == "USER":
            allowed = (str(row.get("created_by_email") or "").lower() == user["email"].lower()
                       or str(row.get("status") or "").upper() == "RELEASED")
            if not allowed:
                raise HTTPException(403, "You are not authorized to view this document.")
        elif role == "HOD" and str(row.get("hod_email") or "").lower() != user["email"].lower():
            raise HTTPException(403, "This document is not assigned to your HOD account.")
    elif role == "USER":
        owner = row.get("created_by_email") or row.get("requested_by_email") or row.get("user_email") or row.get("recipient_email")
        if owner and owner.lower() != user["email"].lower():
            raise HTTPException(403, "Not authorized.")
    elif role == "HOD":
        if resource == "dmr-requests" and str(row.get("hod_email") or "").lower() != user["email"].lower():
            raise HTTPException(403, "This DMR is not assigned to your HOD account.")
        if resource == "documents" and str(row.get("hod_email") or "").lower() != user["email"].lower():
            raise HTTPException(403, "This document is not assigned to your HOD account.")
        if resource == "notifications" and str(row.get("recipient_email") or "").lower() != user["email"].lower():
            raise HTTPException(403, "Not authorized.")
    return dict(row)

@router.post("/{resource}")
def create_resource(resource: str, body: RowBody, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    if resource not in TABLES: raise HTTPException(404, "Unknown DCC resource.")
    table, cols = TABLES[resource]
    data = _safe_data(resource, body.data)
    role = str(user["role"]).upper()
    if resource in {"folders","master-data"}: _require(user, "ADMIN","DCC")
    elif resource in {"documents","dmr-requests","document-requests"}: _require(user, "ADMIN","DCC","HOD","USER")
    else: _require(user, "ADMIN","DCC","HOD","USER")
    # Never let clients spoof the actor for audit/activity rows.
    if resource == "activities":
        data["user_email"] = user["email"]; data["user_name"] = user["name"]
    if resource == "document-requests" and role == "USER":
        data["user_email"] = user["email"]; data["user_name"] = user["name"]
    if resource == "dmr-requests" and role == "USER":
        data["requested_by_email"] = user["email"]; data["requested_by_name"] = user["name"]
    if resource == "dmr-requests" and role == "HOD":
        data["hod_email"] = user["email"]; data["hod_name"] = user["name"]
    if resource == "documents":
        if role == "USER":
            data["created_by_email"] = user["email"]
            data["created_by_name"] = user["name"]
        elif role == "HOD":
            data["created_by_email"] = user["email"]
            data["created_by_name"] = user["name"]
    if resource == "notifications" and role not in {"ADMIN","DCC"}:
        data["recipient_email"] = user["email"]
    keys = list(data)
    params = {f"v_{k}": v for k,v in data.items()}
    sql = f"INSERT INTO {table} ({','.join(keys)}) VALUES ({','.join(':'+f'v_{k}' for k in keys)})"
    db.execute(text(sql), params); db.commit()
    return {"success": True}

@router.patch("/{resource}/{row_id}")
def update_resource(resource: str, row_id: str, body: RowBody,
                    user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    if resource not in TABLES: raise HTTPException(404, "Unknown DCC resource.")
    table, cols = TABLES[resource]
    data = _safe_data(resource, body.data, partial=True)
    role = str(user["role"]).upper()
    if resource in {"folders","master-data"}: _require(user, "ADMIN","DCC")
    elif resource in {"documents","dmr-requests","document-requests"}: _require(user, "ADMIN","DCC","HOD","USER")
    else: _require(user, "ADMIN","DCC","HOD","USER")
    if resource == "activities": raise HTTPException(405, "Activity records are append-only.")
    key = "document_no" if resource == "master-data" else "id"
    if resource in {"dmr-requests", "document-requests", "notifications"}:
        existing = db.execute(text(f"SELECT * FROM {table} WHERE {key}=:id"), {"id":row_id}).mappings().first()
        if not existing: raise HTTPException(404, "Record not found.")
        if role == "USER":
            owner = existing.get("requested_by_email") or existing.get("user_email") or existing.get("recipient_email")
            if not owner or owner.lower() != user["email"].lower(): raise HTTPException(403, "You can only modify your own record.")
            if resource == "dmr-requests":
                allowed_user = {"revised_file_path","revised_file_name","revised_submitted_date","status","updated_at"}
                data = {k:v for k,v in data.items() if k in allowed_user}
            elif resource == "document-requests":
                data = {k:v for k,v in data.items() if k in {"status","updated_at"}}
            else:
                data = {k:v for k,v in data.items() if k in {"is_read"}}
        elif role == "HOD":
            if resource == "dmr-requests" and str(existing.get("hod_email") or "").lower() != user["email"].lower(): raise HTTPException(403, "This DMR is not assigned to your HOD account.")
            if resource == "notifications" and str(existing.get("recipient_email") or "").lower() != user["email"].lower(): raise HTTPException(403, "Not authorized.")
            if resource == "dmr-requests": data={k:v for k,v in data.items() if k in {"status","rejection_reason","hod_action_date","modification_access_granted","updated_at"}}
            if resource == "notifications": data={k:v for k,v in data.items() if k in {"is_read"}}
    if resource == "documents":
        existing = db.execute(text("SELECT created_by_email,hod_email FROM dcc_documents WHERE id=:id"), {"id": row_id}).mappings().first()
        if not existing: raise HTTPException(404, "Document not found.")
        if role == "USER" and str(existing["created_by_email"] or "").lower() != user["email"].lower():
            raise HTTPException(403, "You can only update documents created by your account.")
        if role == "HOD" and str(existing["hod_email"] or "").lower() != user["email"].lower():
            raise HTTPException(403, "This document is not assigned to your HOD account.")
        if role == "USER":
            allowed_user_fields = {"attachment_path", "attachment_name", "updated_at"}
            data = {k: v for k, v in data.items() if k in allowed_user_fields}
        elif role == "HOD":
            allowed_hod_fields = {"status", "rejection_reason", "hod_action_at", "updated_at"}
            data = {k: v for k, v in data.items() if k in allowed_hod_fields}
    params = {f"v_{k}": v for k,v in data.items()}; params["row_id"] = row_id
    sets = ",".join(f"{k}=:{'v_'+k}" for k in data)
    result = db.execute(text(f"UPDATE {table} SET {sets} WHERE {key}=:row_id"), params)
    db.commit()
    if result.rowcount == 0: raise HTTPException(404, "Record not found.")
    return {"success": True}

@router.delete("/files/file")
def delete_file(path: str = Query(...), user: dict[str, Any] = Depends(_current_user)):
    _require(user, "ADMIN","DCC")
    target = _safe_path(path)
    if target.exists() and target.is_file(): target.unlink()
    return {"success": True}

@router.delete("/{resource}/{row_id}")
def delete_resource(resource: str, row_id: str, user: dict[str, Any] = Depends(_current_user), db: Session = Depends(get_db)):
    if resource not in TABLES: raise HTTPException(404, "Unknown DCC resource.")
    table, cols = TABLES[resource]
    role = str(user["role"]).upper()
    key = "document_no" if resource == "master-data" else "id"
    if resource == "notifications" and role in {"USER","HOD"}:
        result = db.execute(text("DELETE FROM dcc_notifications WHERE id=:id AND LOWER(recipient_email)=LOWER(:email)"), {"id":row_id,"email":user["email"]})
        db.commit(); return {"success":result.rowcount>0}
    _require(user, "ADMIN","DCC")
    if resource == "documents":
        # Document deletion is intentionally limited to Admin/DCC.
        pass
    if resource == "activities":
        raise HTTPException(405, "Activity records cannot be deleted.")
    result = db.execute(text(f"DELETE FROM {table} WHERE {key}=:id"), {"id": row_id})
    db.commit()
    return {"success": result.rowcount > 0}

# Private local storage. Files are never exposed as a public static directory.
_STORAGE_ROOT = Path(__file__).resolve().parents[3] / "storage" / "dcc-documents"
_STORAGE_ROOT.mkdir(parents=True, exist_ok=True)

def _safe_path(relative: str) -> Path:
    candidate = (_STORAGE_ROOT / relative).resolve()
    if _STORAGE_ROOT.resolve() not in candidate.parents:
        raise HTTPException(400, "Invalid storage path.")
    return candidate

@router.post("/files/upload")
async def upload_file(path: str = Query(..., min_length=1, max_length=500),
                      file: UploadFile = File(...),
                      user: dict[str, Any] = Depends(_current_user)):
    _require(user, "ADMIN","DCC","HOD","USER")
    target = _safe_path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists(): raise HTTPException(409, "A file already exists at this path.")
    size = 0
    with target.open("xb") as out:
        while chunk := await file.read(1024 * 1024):
            size += len(chunk)
            if size > 50 * 1024 * 1024:
                out.close(); target.unlink(missing_ok=True)
                raise HTTPException(413, "Maximum upload size is 50 MB.")
            out.write(chunk)
    return {"path": path, "filename": file.filename, "size": size}

