from datetime import datetime, timedelta
import hashlib
import hmac
from typing import Any, Union
from jose import jwt
from passlib.context import CryptContext
from config.settings import get_settings

settings = get_settings()

# Use pbkdf2_sha256 as default for compatibility across environments.
# Keep bcrypt in the list so existing bcrypt hashes can still be verified.
pwd_context = CryptContext(schemes=["pbkdf2_sha256", "bcrypt"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    # Legacy fallback for earlier seed scripts that stored plain SHA256 hex.
    if len(hashed_password) == 64 and all(c in "0123456789abcdef" for c in hashed_password.lower()):
        legacy_hash = hashlib.sha256(plain_password.encode("utf-8")).hexdigest()
        return hmac.compare_digest(legacy_hash, hashed_password.lower())

    try:
        return pwd_context.verify(plain_password, hashed_password)
    except Exception:
        # Return False instead of propagating verifier internals as 500 errors.
        return False

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(
    subject: Union[str, Any], expires_delta: timedelta | None = None
) -> str:
    """Generates a JWT token for the mobile app to authenticate with the backend."""
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )
    to_encode = {"exp": expire, "sub": str(subject)}
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt