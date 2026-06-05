"""
EcoMesh – Full Development Seed Script
=======================================
Seeds ALL PostgreSQL tables with realistic development data:
  • Users (test user + 3 extra lab members)
  • Zones (4 zones across 2 floors, matching mock_data.dart layout)
  • Desks (6 per zone, with realistic x/y positions on the floor map)
  • Devices (1 Gateway Hub + 1 Sensor Node per zone)
  • EnergyProfiles (one per persona per user)

Usage:
    cd backend
    python seed_all.py

Re-running is safe – it skips records that already exist.
"""

import os
import sys
import logging

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

sys.path.insert(0, os.path.dirname(__file__))

from config.settings import get_settings
from database.base import Base
from database import models
from core.security import get_password_hash

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

settings = get_settings()

engine = create_engine(
    f"postgresql://{settings.POSTGRES_USER}:{settings.POSTGRES_PASSWORD}@"
    f"{settings.POSTGRES_SERVER}:{settings.POSTGRES_PORT}/{settings.POSTGRES_DB}"
)
SessionLocal = sessionmaker(bind=engine)

# ── Create all tables ──────────────────────────────────────────────────────────
Base.metadata.create_all(bind=engine)
logger.info("✓ Database tables ensured")

db = SessionLocal()

# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────

def upsert_user(email, full_name, password, esg_points=0):
    user = db.query(models.User).filter(models.User.email == email).first()
    if user:
        logger.info("  skip user %s (exists)", email)
        return user
    user = models.User(
        email=email,
        hashed_password=get_password_hash(password),
        full_name=full_name,
        esg_points=esg_points,
        is_active=True,
    )
    db.add(user)
    db.flush()  # get id without commit
    logger.info("  + user %s (id=%s)", email, user.id)
    return user


def upsert_zone(zone_id, name, floor_level, base_ac_target=24.0):
    zone = db.query(models.Zone).filter(models.Zone.id == zone_id).first()
    if zone:
        logger.info("  skip zone %s (exists)", zone_id)
        return zone
    zone = models.Zone(
        id=zone_id,
        name=name,
        floor_level=floor_level,
        base_ac_target=base_ac_target,
    )
    db.add(zone)
    db.flush()
    logger.info("  + zone %s – %s", zone_id, name)
    return zone


def upsert_desk(desk_id, zone_id, label, x_pos, y_pos, is_claimed=False,
                claimed_by=None, is_powered=False):
    desk = db.query(models.Desk).filter(models.Desk.id == desk_id).first()
    if desk:
        logger.info("  skip desk %s (exists)", desk_id)
        return desk
    desk = models.Desk(
        id=desk_id,
        zone_id=zone_id,
        label=label,
        x_pos=x_pos,
        y_pos=y_pos,
        is_claimed=is_claimed,
        claimed_by=claimed_by,
        is_powered=is_powered,
    )
    db.add(desk)
    db.flush()
    logger.info("  + desk %s in %s", label, zone_id)
    return desk


def upsert_device(mac, zone_id, device_type, status="ONLINE"):
    device = db.query(models.Device).filter(models.Device.mac_address == mac).first()
    if device:
        logger.info("  skip device %s (exists)", mac)
        return device
    device = models.Device(
        mac_address=mac,
        zone_id=zone_id,
        device_type=device_type,
        status=status,
    )
    db.add(device)
    db.flush()
    logger.info("  + device %s [%s] in %s", mac, device_type, zone_id)
    return device


def upsert_profile(owner_id, profile_name, preferred_temp, standby_mins=5):
    existing = (
        db.query(models.EnergyProfile)
        .filter(
            models.EnergyProfile.owner_id == owner_id,
            models.EnergyProfile.profile_name == profile_name,
        )
        .first()
    )
    if existing:
        logger.info("  skip profile '%s' for user %s (exists)", profile_name, owner_id)
        return existing
    profile = models.EnergyProfile(
        owner_id=owner_id,
        profile_name=profile_name,
        preferred_temp=preferred_temp,
        auto_standby_timeout_mins=standby_mins,
    )
    db.add(profile)
    db.flush()
    logger.info("  + profile '%s' for user %s", profile_name, owner_id)
    return profile


# ─────────────────────────────────────────────────────────────────────────────
try:
    # ── 1. USERS ──────────────────────────────────────────────────────────────
    logger.info("\n[1/5] Seeding Users...")
    main_user = upsert_user(
        email="test@example.com",
        full_name="Ahmad Fariz",
        password="password123",
        esg_points=87,  # ~8.7 kWh saved → shows meaningful impact on screen
    )
    user_siti = upsert_user(
        email="siti@example.com",
        full_name="Siti Noor",
        password="password123",
        esg_points=52,
    )
    user_raj = upsert_user(
        email="raj@example.com",
        full_name="Raj Kumar",
        password="password123",
        esg_points=30,
    )
    user_wei = upsert_user(
        email="wei@example.com",
        full_name="Wei Lin",
        password="password123",
        esg_points=10,
    )
    db.commit()
    logger.info("✓ Users seeded")

    # ── 2. ZONES ──────────────────────────────────────────────────────────────
    logger.info("\n[2/5] Seeding Zones...")
    zone_a = upsert_zone("zone-a", "Zone A",          floor_level=2, base_ac_target=26.0)
    zone_b = upsert_zone("zone-b", "Zone B",          floor_level=2, base_ac_target=24.0)
    zone_c = upsert_zone("zone-c", "Zone C – Meeting", floor_level=2, base_ac_target=23.0)
    zone_d = upsert_zone("zone-d", "Zone D – Lab",    floor_level=3, base_ac_target=22.0)
    db.commit()
    logger.info("✓ Zones seeded")

    # ── 3. DESKS ──────────────────────────────────────────────────────────────
    # x/y values are normalised 0.0–1.0 (match the Flutter floor map renderer)
    logger.info("\n[3/5] Seeding Desks...")

    # Zone A – 4 desks, mostly unclaimed (idle zone)
    upsert_desk("a1", "zone-a", "A-01", x_pos=0.20, y_pos=0.30, is_powered=False)
    upsert_desk("a2", "zone-a", "A-02", x_pos=0.40, y_pos=0.30, is_powered=False)
    upsert_desk("a3", "zone-a", "A-03", x_pos=0.60, y_pos=0.30, is_powered=True)   # ghost power!
    upsert_desk("a4", "zone-a", "A-04", x_pos=0.20, y_pos=0.65, is_powered=False)

    # Zone B – 6 desks, 4 claimed (active zone)
    upsert_desk("b1", "zone-b", "B-01", x_pos=0.20, y_pos=0.25,
                is_claimed=True, claimed_by=main_user.id, is_powered=True)
    upsert_desk("b2", "zone-b", "B-02", x_pos=0.50, y_pos=0.25,
                is_claimed=True, claimed_by=user_siti.id, is_powered=True)
    upsert_desk("b3", "zone-b", "B-03", x_pos=0.78, y_pos=0.25,
                is_claimed=True, claimed_by=user_raj.id, is_powered=True)
    upsert_desk("b4", "zone-b", "B-04", x_pos=0.20, y_pos=0.60, is_powered=False)
    upsert_desk("b5", "zone-b", "B-05", x_pos=0.50, y_pos=0.60,
                is_claimed=True, claimed_by=user_wei.id, is_powered=True)
    upsert_desk("b6", "zone-b", "B-06", x_pos=0.78, y_pos=0.60, is_powered=True)  # ghost power

    # Zone C – 2 desks (meeting room, empty)
    upsert_desk("c1", "zone-c", "C-01", x_pos=0.30, y_pos=0.40, is_powered=False)
    upsert_desk("c2", "zone-c", "C-02", x_pos=0.70, y_pos=0.40, is_powered=False)

    # Zone D – 4 desks (lab, partially occupied)
    upsert_desk("d1", "zone-d", "D-01", x_pos=0.25, y_pos=0.30,
                is_claimed=True, claimed_by=main_user.id, is_powered=True)
    upsert_desk("d2", "zone-d", "D-02", x_pos=0.55, y_pos=0.30,
                is_claimed=True, claimed_by=user_siti.id, is_powered=True)
    upsert_desk("d3", "zone-d", "D-03", x_pos=0.25, y_pos=0.65, is_powered=False)
    upsert_desk("d4", "zone-d", "D-04", x_pos=0.55, y_pos=0.65,
                is_claimed=True, claimed_by=user_raj.id, is_powered=True)

    db.commit()
    logger.info("✓ Desks seeded")

    # ── 4. DEVICES ────────────────────────────────────────────────────────────
    logger.info("\n[4/5] Seeding Devices (ESP32 Hubs & Sensor Nodes)...")
    # Zone A
    upsert_device("AA:BB:CC:DD:01:01", "zone-a", "GATEWAY_HUB",  status="ONLINE")
    upsert_device("AA:BB:CC:DD:01:02", "zone-a", "SENSOR_NODE",  status="ONLINE")
    # Zone B
    upsert_device("AA:BB:CC:DD:02:01", "zone-b", "GATEWAY_HUB",  status="ONLINE")
    upsert_device("AA:BB:CC:DD:02:02", "zone-b", "SENSOR_NODE",  status="ONLINE")
    # Zone C
    upsert_device("AA:BB:CC:DD:03:01", "zone-c", "GATEWAY_HUB",  status="ONLINE")
    upsert_device("AA:BB:CC:DD:03:02", "zone-c", "SENSOR_NODE",  status="OFFLINE")  # simulates a downed node
    # Zone D
    upsert_device("AA:BB:CC:DD:04:01", "zone-d", "GATEWAY_HUB",  status="ONLINE")
    upsert_device("AA:BB:CC:DD:04:02", "zone-d", "SENSOR_NODE",  status="ONLINE")

    db.commit()
    logger.info("✓ Devices seeded")

    # ── 5. ENERGY PROFILES ────────────────────────────────────────────────────
    # Each user gets all 3 personas; the active one is set in the Flutter UI
    logger.info("\n[5/5] Seeding EnergyProfiles...")
    for uid, label in [
        (main_user.id, "Ahmad Fariz"),
        (user_siti.id, "Siti Noor"),
        (user_raj.id,  "Raj Kumar"),
        (user_wei.id,  "Wei Lin"),
    ]:
        upsert_profile(uid, "Deep Work",      preferred_temp=24.0, standby_mins=2)
        upsert_profile(uid, "Eco-Warrior",    preferred_temp=26.0, standby_mins=1)
        upsert_profile(uid, "Standard Admin", preferred_temp=25.0, standby_mins=5)
        upsert_profile(uid, "Meeting",        preferred_temp=23.0, standby_mins=10)
        upsert_profile(uid, "Eco Max",        preferred_temp=27.0, standby_mins=1)

    db.commit()
    logger.info("✓ EnergyProfiles seeded")

    # ── Summary ───────────────────────────────────────────────────────────────
    n_users   = db.query(models.User).count()
    n_zones   = db.query(models.Zone).count()
    n_desks   = db.query(models.Desk).count()
    n_devices = db.query(models.Device).count()
    n_profiles= db.query(models.EnergyProfile).count()

    print()
    print("=" * 50)
    print("  EcoMesh Dev Seed Complete")
    print("=" * 50)
    print(f"  Users          : {n_users}")
    print(f"  Zones          : {n_zones}")
    print(f"  Desks          : {n_desks}")
    print(f"  Devices        : {n_devices}")
    print(f"  EnergyProfiles : {n_profiles}")
    print("=" * 50)
    print()
    print("  Login credentials:")
    print("  Email                          | Password")
    print("  -------------------------------|------------")
    print("  test@example.com (main user)   | password123")
    print("  siti@example.com               | password123")
    print("  raj@example.com                | password123")
    print("  wei@example.com                | password123")
    print()
    print("  Next: run the InfluxDB telemetry seeder:")
    print("  python ml_engine/pipelines/seed_sample_telemetry.py")
    print()

except Exception as e:
    logger.error("✗ Seed failed: %s", e)
    db.rollback()
    sys.exit(1)

finally:
    db.close()
