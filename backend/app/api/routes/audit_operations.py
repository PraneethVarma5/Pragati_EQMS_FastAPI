from __future__ import annotations

from datetime import date, datetime, timezone
from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from fastapi.encoders import jsonable_encoder
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.api.deps import CurrentAuditAdmin, get_optional_current_audit_admin
from app.db.session import get_db

router = APIRouter(prefix="/audit/operations", tags=["Audit Operations"])


# These operations change administration/configuration data or perform
# privileged maintenance/deletion. They always require a valid Audit Admin session.
ADMIN_ONLY_OPERATIONS = {
    "admin_get_audit_types",
    "admin_create_audit_type",
    "admin_update_audit_type",
    "admin_delete_audit_type",
    "admin_get_audit_categories",
    "admin_create_audit_category",
    "admin_update_audit_category",
    "admin_delete_audit_category",
    "admin_get_audit_questions",
    "admin_create_audit_question",
    "admin_update_audit_question",
    "admin_delete_audit_question",
    "admin_get_audit_master_data",
    "admin_create_audit_master_data",
    "admin_update_audit_master_data",
    "admin_delete_audit_master_data",
    "get_all_audit_schedules",
    "create_audit_schedule",
    "update_audit_schedule",
    "update_audit_schedule_status",
    "delete_audit_schedule",
    "delete_admin_audit",
    "repair_missing_mil_numbers",
}


def _one(db: Session, sql: str, params: dict[str, Any]) -> dict[str, Any] | None:
    row = db.execute(text(sql), params).mappings().first()
    return dict(row) if row is not None else None


def _many(db: Session, sql: str, params: dict[str, Any]) -> list[dict[str, Any]]:
    return [dict(row) for row in db.execute(text(sql), params).mappings().all()]


def _function_one(db: Session, function_sql: str, params: dict[str, Any]) -> Any:
    row = db.execute(text(function_sql), params).scalar_one_or_none()
    if isinstance(row, dict):
        return row
    return row


@router.post("/{operation}")
def execute_audit_operation(
    operation: str,
    payload: dict[str, Any],
    current: CurrentAuditAdmin | None = Depends(get_optional_current_audit_admin),
    db: Session = Depends(get_db),
):
    """Allowlisted operations for normal Audit users and Audit Admins.

    Normal workflow operations are available without login. Configuration,
    schedule management, deletion and repair operations require Audit Admin.
    SQL is fixed in this module; clients cannot submit arbitrary SQL/table names.
    """
    if operation in ADMIN_ONLY_OPERATIONS and current is None:
        raise HTTPException(
            status_code=401,
            detail="Audit admin authentication is required for this operation.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    p = payload or {}
    token = current.raw_token if current is not None else None
    try:
        if operation == "dashboard_stats":
            row = _one(db, """
                SELECT count(*)::int AS total,
                  count(*) FILTER (WHERE status='Draft')::int AS draft,
                  count(*) FILTER (WHERE status='In Progress')::int AS in_progress,
                  count(*) FILTER (WHERE status='Submitted')::int AS submitted,
                  count(*) FILTER (WHERE status='Completed')::int AS completed,
                  count(*) FILTER (WHERE mil_status='Open')::int AS open_mil
                FROM public.audits
            """, {})
            result = row or {}

        elif operation == "create_audit":
            if float(p.get("total_audit_hours") or 0) <= 0:
                raise HTTPException(422, "Total Audit Hours must be greater than 0.")
            result = _one(db, """
                INSERT INTO public.audits
                  (type_id,audit_date,vendor,site,lob,program,line,apn,auditor_name,
                   auditor_email,total_audit_hours,started_at,status,mil_status)
                VALUES
                  (:type_id,:audit_date,:vendor,:site,:lob,:program,:line,:apn,:auditor_name,
                   :auditor_email,:total_audit_hours,:started_at,'In Progress','Not Generated')
                RETURNING *
            """, {**p, "started_at": datetime.now(timezone.utc)})

        elif operation == "get_audit_by_id":
            result = _one(db, "SELECT * FROM public.audits WHERE audit_id=:audit_id", p)

        elif operation == "get_audit_categories":
            result = _many(db, """
                SELECT category_id,type_id,category_name,description,sort_order,active
                FROM public.audit_categories WHERE type_id=:type_id AND active=true
                ORDER BY sort_order,category_name
            """, p)

        elif operation == "get_category_progress":
            result = _many(db, "SELECT * FROM public.audit_category_progress WHERE audit_id=:audit_id", p)

        elif operation == "create_category_progress":
            result = _one(db, """
                INSERT INTO public.audit_category_progress (audit_id,category_id)
                VALUES (:audit_id,:category_id)
                ON CONFLICT (audit_id,category_id) DO UPDATE SET updated_at=now()
                RETURNING *
            """, p)

        elif operation == "add_category_time":
            hours = float(p.get("additional_hours") or 0)
            if hours <= 0:
                result = {"success": True}
            else:
                row = _one(db, "SELECT total_time_taken_hours FROM public.audits WHERE audit_id=:audit_id FOR UPDATE", p)
                if row is None:
                    raise HTTPException(404, "Audit not found.")
                updated = float(row["total_time_taken_hours"] or 0) + hours
                result = _one(db, """
                    UPDATE public.audits SET total_time_taken_hours=:hours,
                      elapsed_seconds=round(:hours * 3600), updated_at=now()
                    WHERE audit_id=:audit_id RETURNING *
                """, {"hours": updated, "audit_id": p["audit_id"]})

        elif operation == "get_category_by_id":
            result = _one(db, """
                SELECT category_id,type_id,category_name,description,sort_order,active
                FROM public.audit_categories WHERE category_id=:category_id
            """, p)

        elif operation == "get_questions":
            result = _many(db, """
                SELECT question_id,category_id,question_number,question,description,sort_order,active
                FROM public.audit_questions WHERE category_id=:category_id AND active=true
                ORDER BY sort_order,question_number
            """, p)

        elif operation == "get_checklist_answers":
            ids = p.get("question_ids") or []
            if not ids:
                result = []
            else:
                result = _many(db, """
                    SELECT * FROM public.audit_checklist_answers
                    WHERE audit_id=:audit_id AND question_id = ANY(CAST(:question_ids AS uuid[]))
                """, {"audit_id": p["audit_id"], "question_ids": ids})

        elif operation == "save_checklist_answer":
            answer = p.get("answer")
            defect = p.get("defect_type")
            description = (p.get("description") or "").strip()
            if answer not in ("Yes", "No"):
                raise HTTPException(422, "Answer must be either Yes or No.")
            if answer == "Yes":
                defect = None
            elif not description or defect not in ("Critical", "Major", "Minor"):
                raise HTTPException(422, "Every No answer requires a description and valid defect type.")
            result = _one(db, """
                INSERT INTO public.audit_checklist_answers
                  (audit_id,question_id,answer,description,defect_type,answered_at)
                VALUES (:audit_id,:question_id,:answer,:description,:defect_type,now())
                ON CONFLICT (audit_id,question_id) DO UPDATE SET
                  answer=EXCLUDED.answer, description=EXCLUDED.description,
                  defect_type=EXCLUDED.defect_type, answered_at=now(), updated_at=now()
                RETURNING *
            """, {**p, "description": description or None, "defect_type": defect})

        elif operation == "complete_category":
            result = _one(db, """
                UPDATE public.audit_category_progress
                SET completed=true,completed_at=now(),updated_at=now()
                WHERE audit_id=:audit_id AND category_id=:category_id RETURNING *
            """, p)
            if result is None:
                raise HTTPException(404, "Category progress record not found.")

        elif operation == "submit_audit":
            result = bool(_function_one(db, "SELECT public.submit_audit(CAST(:audit_id AS uuid))", p))

        elif operation == "get_mil_items":
            result = _many(db, """
                SELECT to_jsonb(m) || jsonb_build_object('audits',
                  jsonb_build_object('audit_id',a.audit_id,'status',a.status,
                    'mil_status',a.mil_status,'mil_number',a.mil_number,'audit_date',a.audit_date)) AS item
                FROM public.audit_mil_items m JOIN public.audits a ON a.audit_id=m.audit_id
                WHERE m.audit_id=:audit_id ORDER BY m.created_at
            """, p)
            result = [r["item"] for r in result]

        elif operation == "update_mil_item":
            status_value = p.get("overall_status")
            if status_value is not None and status_value not in ("Open", "In Progress", "Closed"):
                raise HTTPException(422, "Invalid MIL status.")
            result = _one(db, """
                UPDATE public.audit_mil_items SET
                  root_cause=:root_cause, corrective_action=:corrective_action,
                  dri_name=:dri_name, dri_mail=:dri_mail, deadline=:deadline,
                  overall_status=COALESCE(:overall_status,overall_status), updated_at=now()
                WHERE mil_item_id=:mil_item_id RETURNING *
            """, {**p, "root_cause": (p.get("root_cause") or "").strip() or None,
                  "corrective_action": (p.get("corrective_action") or "").strip() or None,
                  "dri_name": (p.get("dri_name") or "").strip() or None,
                  "dri_mail": (p.get("dri_mail") or "").strip() or None,
                  "deadline": p.get("deadline") or None})
            if result is None:
                raise HTTPException(404, "MIL item not found.")

        elif operation == "close_mil":
            result = bool(_function_one(db, "SELECT public.close_audit_mil(CAST(:audit_id AS uuid))", p))

        elif operation == "get_audit_report":
            audit = _one(db, """
                SELECT a.*,t.audit_type,t.description AS audit_type_description
                FROM public.audits a LEFT JOIN public.audit_types t ON t.type_id=a.type_id
                WHERE a.audit_id=:audit_id
            """, p)
            if audit is None:
                raise HTTPException(404, "Audit record was not found.")
            categories = _many(db, """
                SELECT cp.*,c.category_id,c.type_id,c.category_name,c.description,c.sort_order,c.active
                FROM public.audit_category_progress cp
                JOIN public.audit_categories c ON c.category_id=cp.category_id
                WHERE cp.audit_id=:audit_id ORDER BY c.sort_order,c.category_name
            """, p)
            answers = _many(db, """
                SELECT ans.*,q.category_id,q.question_number,q.question,
                       q.description AS question_description,q.sort_order AS question_sort_order
                FROM public.audit_checklist_answers ans
                LEFT JOIN public.audit_questions q ON q.question_id=ans.question_id
                WHERE ans.audit_id=:audit_id
                ORDER BY q.sort_order,q.question_number
            """, p)
            mil = _many(db, "SELECT * FROM public.audit_mil_items WHERE audit_id=:audit_id ORDER BY created_at", p)
            result = {"audit": audit, "categories": categories, "answers": answers, "mil_items": mil}

        elif operation == "get_all_audits":
            result = _many(db, """
                SELECT a.*,t.audit_type FROM public.audits a
                LEFT JOIN public.audit_types t ON t.type_id=a.type_id
                ORDER BY a.created_at DESC
            """, {})

        elif operation == "admin_get_audit_types":
            result = _many(db, "SELECT to_jsonb(x) AS item FROM public.admin_get_audit_types(:token) x", {"token": token})
            result = [r["item"] for r in result]

        elif operation == "admin_create_audit_type":
            result = _function_one(db, "SELECT to_jsonb(public.admin_create_audit_type(:token,:audit_type,:description,:active))", {"token":token, **p})

        elif operation == "admin_update_audit_type":
            result = _function_one(db, "SELECT to_jsonb(public.admin_update_audit_type(:token,CAST(:type_id AS uuid),:audit_type,:description,:active))", {"token":token, **p})

        elif operation == "admin_delete_audit_type":
            result = bool(_function_one(db, "SELECT public.admin_delete_audit_type(:token,CAST(:type_id AS uuid))", {"token":token, **p}))

        elif operation == "admin_get_audit_categories":
            rows = _many(db, "SELECT to_jsonb(x) AS item FROM public.admin_get_audit_categories(:token,CAST(:type_id AS uuid)) x", {"token":token, **p})
            result = [r["item"] for r in rows]

        elif operation == "admin_create_audit_category":
            result = _function_one(db, "SELECT to_jsonb(public.admin_create_audit_category(:token,CAST(:type_id AS uuid),:category_name,:description,:sort_order,:active))", {"token":token, **p})

        elif operation == "admin_update_audit_category":
            result = _function_one(db, "SELECT to_jsonb(public.admin_update_audit_category(:token,CAST(:category_id AS uuid),:category_name,:description,:sort_order,:active))", {"token":token, **p})

        elif operation == "admin_delete_audit_category":
            result = bool(_function_one(db, "SELECT public.admin_delete_audit_category(:token,CAST(:category_id AS uuid))", {"token":token, **p}))

        elif operation == "admin_get_audit_questions":
            rows = _many(db, "SELECT to_jsonb(x) AS item FROM public.admin_get_audit_questions(:token,CAST(:category_id AS uuid)) x", {"token":token, **p})
            result = [r["item"] for r in rows]

        elif operation == "admin_create_audit_question":
            result = _function_one(db, "SELECT to_jsonb(public.admin_create_audit_question(:token,CAST(:category_id AS uuid),:question_number,:question,:description,:sort_order,:active))", {"token":token, **p})

        elif operation == "admin_update_audit_question":
            result = _function_one(db, "SELECT to_jsonb(public.admin_update_audit_question(:token,CAST(:question_id AS uuid),:question_number,:question,:description,:sort_order,:active))", {"token":token, **p})

        elif operation == "admin_delete_audit_question":
            result = bool(_function_one(db, "SELECT public.admin_delete_audit_question(:token,CAST(:question_id AS uuid))", {"token":token, **p}))

        elif operation == "admin_get_audit_master_data":
            rows = _many(db, "SELECT to_jsonb(x) AS item FROM public.admin_get_audit_master_data(:token) x", {"token":token})
            result = [r["item"] for r in rows]

        elif operation == "get_active_audit_types":
            result = _many(db, "SELECT type_id,audit_type,description,active FROM public.audit_types WHERE active=true ORDER BY audit_type", {})

        elif operation == "admin_create_audit_master_data":
            result = _function_one(db, "SELECT to_jsonb(public.admin_create_audit_master_data(:token,:master_name,CAST(:audit_type_id AS uuid),:audit_type_name,:active))", {"token":token, **p})

        elif operation == "admin_update_audit_master_data":
            result = _function_one(db, "SELECT to_jsonb(public.admin_update_audit_master_data(:token,CAST(:master_id AS uuid),:master_name,CAST(:audit_type_id AS uuid),:audit_type_name,:active))", {"token":token, **p})

        elif operation == "admin_delete_audit_master_data":
            result = bool(_function_one(db, "SELECT public.admin_delete_audit_master_data(:token,CAST(:master_id AS uuid))", {"token":token, **p}))

        elif operation == "get_active_auditors":
            result = _many(db, "SELECT auditor_id,auditor_name,employee_id,email FROM public.audit_auditors WHERE active=true ORDER BY auditor_name", {})

        elif operation == "get_all_audit_schedules":
            result = _many(db, """
                SELECT s.*,t.audit_type FROM public.audit_schedules s
                LEFT JOIN public.audit_types t ON t.type_id=s.type_id
                ORDER BY s.audit_date ASC,s.created_at ASC
            """, {})

        elif operation == "create_audit_schedule":
            result = _one(db, """
                INSERT INTO public.audit_schedules
                  (audit_date,type_id,master_id,master_data_name,auditor_id,auditor_name,auditor_email,status,notes)
                VALUES (:audit_date,CAST(:type_id AS uuid),CAST(:master_id AS uuid),:master_data_name,
                        CAST(:auditor_id AS uuid),:auditor_name,:auditor_email,:status,:notes)
                RETURNING *
            """, p)

        elif operation == "update_audit_schedule":
            result = _one(db, """
                UPDATE public.audit_schedules SET audit_date=:audit_date,
                  type_id=CAST(:type_id AS uuid),master_id=CAST(:master_id AS uuid),
                  master_data_name=:master_data_name,auditor_id=CAST(:auditor_id AS uuid),
                  auditor_name=:auditor_name,auditor_email=:auditor_email,status=:status,
                  notes=:notes,updated_at=now()
                WHERE schedule_id=CAST(:schedule_id AS uuid) RETURNING *
            """, p)
            if result is None: raise HTTPException(404, "Schedule not found.")

        elif operation == "update_audit_schedule_status":
            result = _one(db, "UPDATE public.audit_schedules SET status=:status,updated_at=now() WHERE schedule_id=CAST(:schedule_id AS uuid) RETURNING *", p)
            if result is None: raise HTTPException(404, "Schedule not found.")

        elif operation == "delete_audit_schedule":
            result = _one(db, "DELETE FROM public.audit_schedules WHERE schedule_id=CAST(:schedule_id AS uuid) RETURNING schedule_id", p)
            if result is None: raise HTTPException(404, "Schedule not found.")
            result = True

        elif operation == "delete_admin_audit":
            result = bool(_function_one(db, "SELECT public.admin_delete_audit(:token,CAST(:audit_id AS uuid))", {"token":token, **p}))

        elif operation == "get_audit_mil_status":
            result = _one(db, "SELECT audit_id,status,mil_status,mil_number,audit_date FROM public.audits WHERE audit_id=CAST(:audit_id AS uuid)", p)
            if result is None: raise HTTPException(404, "Audit record was not found.")

        elif operation == "repair_missing_mil_numbers":
            audits = p.get("audits") or []
            missing: dict[str, list[str]] = {}
            for item in audits:
                if (item.get("mil_number") or "").strip(): continue
                day = str(item.get("audit_date") or "")[:10]
                aid = str(item.get("audit_id") or "")
                if day and aid: missing.setdefault(day, []).append(aid)
            repaired = []
            for day, ids in missing.items():
                rows = _many(db, "SELECT mil_number FROM public.audits WHERE mil_number LIKE :pattern", {"pattern": day + "-%"})
                highest = 0
                for row in rows:
                    try: highest = max(highest, int(str(row.get("mil_number", "")).split("-")[-1]))
                    except (ValueError, TypeError): pass
                for aid in ids:
                    highest += 1
                    number = f"{day}-{highest}"
                    _one(db, "UPDATE public.audits SET mil_number=:mil_number,updated_at=now() WHERE audit_id=CAST(:audit_id AS uuid) RETURNING audit_id", {"mil_number": number, "audit_id": aid})
                    repaired.append({"audit_id": aid, "mil_number": number})
            result = {"repaired": repaired}

        else:
            raise HTTPException(404, f"Unknown Audit operation: {operation}")

        db.commit()
        return jsonable_encoder(result)

    except HTTPException:
        db.rollback()
        raise
    except SQLAlchemyError as exc:
        db.rollback()
        # Return PostgreSQL's primary validation message (e.g. a trigger's
        # business-rule rejection), never a traceback or connection string.
        primary = getattr(getattr(exc, "orig", None), "diag", None)
        message = getattr(primary, "message_primary", None)
        raise HTTPException(400, detail=message or "Audit database operation failed. Check the FastAPI server log.") from exc
    except Exception as exc:
        db.rollback()
        raise HTTPException(400, detail=str(exc)) from exc
