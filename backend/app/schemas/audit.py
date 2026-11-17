from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator


class AuditLoginRequest(BaseModel):
    email: str = Field(min_length=3, max_length=320)
    password: str = Field(min_length=1, max_length=256)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: str) -> str:
        return value.strip().lower()


class AuditLoginResponse(BaseModel):
    success: bool = True
    admin_id: UUID
    email: str
    session_token: str
    expires_at: datetime


class AuditAuditorCreate(BaseModel):
    auditor_name: str = Field(min_length=1, max_length=200)
    employee_id: str = Field(min_length=1, max_length=100)
    email: str = Field(min_length=3, max_length=320)
    active: bool = True

    @field_validator("auditor_name", "employee_id")
    @classmethod
    def trim_required(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("This field is required.")
        return value

    @field_validator("email")
    @classmethod
    def normalize_and_validate_email(cls, value: str) -> str:
        value = value.strip().lower()
        if "@" not in value or value.startswith("@") or value.endswith("@"):
            raise ValueError("A valid email address is required.")
        return value


class AuditAuditorUpdate(AuditAuditorCreate):
    pass


class AuditAuditorResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    auditor_id: UUID
    auditor_name: str
    employee_id: str
    email: str
    active: bool
    created_at: datetime
    updated_at: datetime


class AuditLogoutResponse(BaseModel):
    success: bool = True
    message: str = "Logged out successfully."
