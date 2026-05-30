"""
Seed a test user into the database for development/testing.
Run this script to populate test data.

Usage:
    python seed_test_user.py
"""

import os
import sys
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Add backend to path
sys.path.insert(0, os.path.dirname(__file__))

from config.settings import get_settings
from database.base import Base
from database import models
from core.security import get_password_hash

settings = get_settings()

# Create database connection
engine = create_engine(
    f"postgresql://{settings.POSTGRES_USER}:{settings.POSTGRES_PASSWORD}@"
    f"{settings.POSTGRES_SERVER}:{settings.POSTGRES_PORT}/{settings.POSTGRES_DB}"
)
SessionLocal = sessionmaker(bind=engine)

# Create tables
Base.metadata.create_all(bind=engine)

db = SessionLocal()

try:
    # Check if test user already exists
    existing_user = db.query(models.User).filter(
        models.User.email == "test@example.com"
    ).first()
    
    if existing_user:
        print("✓ Test user already exists: test@example.com")
        db.close()
        sys.exit(0)
    
    # Create test user
    test_user = models.User(
        email="test@example.com",
        hashed_password=get_password_hash("password123"),
        full_name="Ahmad Fariz",
        esg_points=0,
        is_active=True,
    )
    
    db.add(test_user)
    db.commit()
    db.refresh(test_user)
    
    print("✓ Test user created successfully!")
    print(f"  Email: test@example.com")
    print(f"  Password: password123")
    print(f"  User ID: {test_user.id}")
    
    # Optionally create test zones
    zones = [
        models.Zone(id="zone-a", name="Zone A", floor_level=1, base_ac_target=24.0),
        models.Zone(id="zone-b", name="Zone B", floor_level=2, base_ac_target=24.0),
        models.Zone(id="zone-c", name="Zone C", floor_level=3, base_ac_target=25.0),
    ]
    
    for zone in zones:
        existing_zone = db.query(models.Zone).filter(models.Zone.id == zone.id).first()
        if not existing_zone:
            db.add(zone)
    
    db.commit()
    print("✓ Test zones created successfully!")
    
except Exception as e:
    print(f"✗ Error seeding test user: {e}")
    db.rollback()
    sys.exit(1)

finally:
    db.close()
