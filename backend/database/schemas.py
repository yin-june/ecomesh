from pydantic import BaseModel, EmailStr
from typing import Optional


# --- USER SCHEMAS ---
class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: str

class UserResponse(BaseModel):
    id: int
    email: EmailStr
    full_name: str
    esg_points: int
    is_active: bool

    class Config:
        from_attributes = True  # Allows Pydantic to read SQLAlchemy ORM models

# --- ZONE SCHEMAS ---
class ZoneCreate(BaseModel):
    id: str
    name: str
    floor_level: int
    base_ac_target: float = 24.0

class ZoneResponse(ZoneCreate):
    class Config:
        from_attributes = True

class ZoneTelemetry(BaseModel):
    zone_id: str
    occupancy_count: int
    temperature: float
    target_temp: float
    energy_draw_kwh: float
    status: str

# --- DESK SCHEMAS ---
class DeskCreate(BaseModel):
    id: str
    label: str
    x_pos: float
    y_pos: float

class DeskUpdate(BaseModel):
    is_claimed: bool
    claimed_by: Optional[int] = None

class DeskPowerToggle(BaseModel):
    is_powered: bool

class DeskResponse(BaseModel):
    id: str
    zone_id: str
    label: str
    x_pos: float
    y_pos: float
    is_claimed: bool
    claimed_by: Optional[int]
    is_powered: bool

    class Config:
        from_attributes = True

# --- AUTHENTICATION SCHEMAS ---
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class TokenPayload(BaseModel):
    sub: Optional[str] = None

# --- ENERGY PROFILE SCHEMAS ---
class EnergyProfileUpdate(BaseModel):
    profile_name: str  # e.g. "Deep Work", "Meeting", "Study", "Eco Max"
    preferred_temp: float  # degrees Celsius, 20.0–28.0

class EnergyProfileResponse(BaseModel):
    id: int
    owner_id: int
    profile_name: str
    preferred_temp: float
    auto_standby_timeout_mins: int

    class Config:
        from_attributes = True