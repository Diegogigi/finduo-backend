import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# For local dev; in Railway you can replace with Postgres URL via env var
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./gastos.db")

# Si es PostgreSQL (Railway), no usar check_same_thread
if DATABASE_URL.startswith("postgresql"):
    engine = create_engine(DATABASE_URL)
else:
    engine = create_engine(
        DATABASE_URL, connect_args={"check_same_thread": False}
    )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()
