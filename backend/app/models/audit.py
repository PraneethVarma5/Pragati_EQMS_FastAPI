from datetime import datetime
from uuid import UUID

from sqlalchemy import Boolean, DateTime, ForeignKey, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class AuditAdmin(Base):
    __tablename__ = "audit_admins"

    admin_id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True)
    email: Mapped[str] = mapped_column(String, nullable=False)
    password_hash: Mapped[str] = mapped_column(String, nullable=False)
    active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    sessions: Mapped[list["AuditAdminSession"]] = relationship(
        back_populates="admin", cascade="all, delete-orphan"
    )


class AuditAdminSession(Base):
    __tablename__ = "audit_admin_sessions"

    session_id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True)
    admin_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("audit_admins.admin_id", ondelete="CASCADE"),
        nullable=False,
    )
    token_hash: Mapped[str] = mapped_column(String, nullable=False, unique=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    admin: Mapped[AuditAdmin] = relationship(back_populates="sessions")


class AuditAuditor(Base):
    __tablename__ = "audit_auditors"

    auditor_id: Mapped[UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True)
    auditor_name: Mapped[str] = mapped_column(String, nullable=False)
    employee_id: Mapped[str] = mapped_column(String, nullable=False)
    email: Mapped[str] = mapped_column(String, nullable=False)
    active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
