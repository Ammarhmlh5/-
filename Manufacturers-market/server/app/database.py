"""
Database - اتصال قاعدة البيانات وإعداد SQLAlchemy
"""
import os

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from .config import get_config


class Base(DeclarativeBase):
    """Declarative base for all marketplace models."""


def build_engine(database_url: str, pool_pre_ping: bool = True):
    kwargs = {"echo": False}
    kwargs["pool_pre_ping"] = pool_pre_ping
    kwargs["pool_size"] = 10
    kwargs["pool_recycle"] = 3600
    return create_engine(database_url, **kwargs)


# Module-level engine + session factory, configured once and reused everywhere.
engine = build_engine(get_config().DATABASE_URL)
SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


def init_db():
    """Re-build the engine/session from current config (used mainly by tests)."""
    global engine, SessionLocal
    config = get_config()
    engine = build_engine(config.DATABASE_URL)
    SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)
    return engine, SessionLocal


def get_db():
    """FastAPI dependency that yields a database session (bound to global engine)."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def create_all(engine=None):
    engine = engine or globals()["engine"]
    Base.metadata.create_all(bind=engine)
