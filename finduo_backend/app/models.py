from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship
from datetime import datetime
import enum

from .database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    name = Column(String)
    password_hash = Column(String, nullable=True)  # Nullable para compatibilidad con usuarios existentes

    transactions = relationship("Transaction", back_populates="user")
    duo_memberships = relationship("DuoMembership", back_populates="user")


class DuoRole(str, enum.Enum):
    owner = "owner"
    partner = "partner"


class DuoStatus(str, enum.Enum):
    pending = "pending"
    active = "active"


class DuoRoom(Base):
    __tablename__ = "duo_rooms"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, default="FinDuo")
    invite_code = Column(String, unique=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    memberships = relationship("DuoMembership", back_populates="room")
    transactions = relationship("Transaction", back_populates="duo_room")


class DuoMembership(Base):
    __tablename__ = "duo_memberships"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    room_id = Column(Integer, ForeignKey("duo_rooms.id"))
    role = Column(Enum(DuoRole), default=DuoRole.partner)
    status = Column(Enum(DuoStatus), default=DuoStatus.pending)

    user = relationship("User", back_populates="duo_memberships")
    room = relationship("DuoRoom", back_populates="memberships")


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    duo_room_id = Column(Integer, ForeignKey("duo_rooms.id"), nullable=True)

    type = Column(String, index=True)
    description = Column(String)
    amount = Column(Integer)  # CLP
    currency = Column(String, default="CLP")
    date_time = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="transactions")
    duo_room = relationship("DuoRoom", back_populates="transactions")
