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

# --- AUTHENTICATION SCHEMAS ---
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class TokenPayload(BaseModel):
    sub: Optional[str] = None