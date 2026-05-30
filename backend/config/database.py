from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from config.settings import get_settings
from database.base import Base

settings = get_settings()

# Initialize PostgreSQL Engine
engine = create_engine(
    settings.SQLALCHEMY_DATABASE_URI, 
    pool_pre_ping=True, # Checks connection health before executing queries
    pool_size=10, 
    max_overflow=20
)

# Session factory for Dependency Injection in FastAPI routers
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    """Yields a database session and safely closes it after the request completes."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()