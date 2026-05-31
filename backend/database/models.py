from sqlalchemy import Boolean, Column, Integer, String, Float, ForeignKey
from sqlalchemy.orm import relationship
from database.base import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, index=True)
    
    # ESG / Gamification tracking
    esg_points = Column(Integer, default=0) 
    is_active = Column(Boolean, default=True)

    # Relationship to customized energy profiles (Deep Work, Meeting, etc.)
    profiles = relationship("EnergyProfile", back_populates="owner")


class Zone(Base):
    __tablename__ = "zones"

    id = Column(String, primary_key=True, index=True) # e.g., "ZONE_A1"
    name = Column(String)
    floor_level = Column(Integer)
    base_ac_target = Column(Float, default=24.0)
    
    devices = relationship("Device", back_populates="zone")
    desks = relationship("Desk", back_populates="zone")


class Desk(Base):
    __tablename__ = "desks"

    id = Column(String, primary_key=True, index=True)
    zone_id = Column(String, ForeignKey("zones.id"))
    label = Column(String)
    x_pos = Column(Float)
    y_pos = Column(Float)
    is_claimed = Column(Boolean, default=False)
    claimed_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    is_powered = Column(Boolean, default=True)

    zone = relationship("Zone", back_populates="desks")
    user = relationship("User")


class Device(Base):
    __tablename__ = "devices"

    mac_address = Column(String, primary_key=True, index=True)
    zone_id = Column(String, ForeignKey("zones.id"))
    device_type = Column(String) # 'GATEWAY_HUB' or 'SENSOR_NODE'
    status = Column(String, default="ONLINE")

    zone = relationship("Zone", back_populates="devices")


class EnergyProfile(Base):
    __tablename__ = "energy_profiles"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"))
    profile_name = Column(String) # "Deep Work"
    preferred_temp = Column(Float)
    auto_standby_timeout_mins = Column(Integer, default=5)

    owner = relationship("User", back_populates="profiles")