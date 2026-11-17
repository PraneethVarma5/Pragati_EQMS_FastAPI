# EQMS FastAPI Backend - Phase 1

This starter migrates only the first Audit vertical slice:

- Audit admin login and logout
- Audit admin session validation
- Auditor list/create/update/delete

The existing Flutter UI is not changed by this package.

## Important safety notes

1. This backend expects the existing `audit_admins`, `audit_admin_sessions`, and
   `audit_auditors` tables to exist.
2. It does **not** create tables or run migrations automatically.
3. It verifies the existing PostgreSQL `pgcrypto crypt(..., gen_salt('bf'))`
   bcrypt password hashes in Python.
4. It stores only a SHA-256 hash of each newly issued session token.
5. Every auditor-management endpoint requires an active Audit admin bearer token.
6. Keep `.env` private. Never commit database credentials.

## Setup (Windows PowerShell)

```powershell
cd backend
py -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
Copy-Item .env.example .env
```

Edit `.env` and set `DATABASE_URL` to the development Supabase PostgreSQL
connection string. Do not paste the password into chat or commit the file.

Run:

```powershell
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Open:

- Health: http://127.0.0.1:8000/health
- Database health: http://127.0.0.1:8000/health/database
- API docs: http://127.0.0.1:8000/docs

## API endpoints

| Method | Endpoint | Authentication |
|---|---|---|
| POST | `/api/v1/audit/auth/login` | No |
| POST | `/api/v1/audit/auth/logout` | Bearer token |
| GET | `/api/v1/audit/auditors` | Bearer token |
| POST | `/api/v1/audit/auditors` | Bearer token |
| PUT | `/api/v1/audit/auditors/{auditor_id}` | Bearer token |
| DELETE | `/api/v1/audit/auditors/{auditor_id}` | Bearer token |

Login request:

```json
{
  "email": "audit-admin@example.com",
  "password": "your-admin-password"
}
```

Use the returned `session_token` as:

```http
Authorization: Bearer <session_token>
```

## Database portability

The application uses SQLAlchemy's portable UUID, string, boolean, and datetime
types and avoids PostgreSQL-only SQL in these endpoints. The existing database
schema itself remains PostgreSQL for now. Moving to another database later will
still require a reviewed schema migration and verification of UUID, index,
constraint, and transaction behavior.

## Not migrated yet

- Audit type/category/question/master-data administration
- Audit schedules and execution/checklists
- MIL findings and reports
- The active-auditor lookup used by the schedule screen
- Other modules (DCC, CCR, NCR)

These will be migrated only after the current Audit admin/auth slice is tested.
