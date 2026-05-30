import os
from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache

class Settings(BaseSettings):
    # Core API Settings
    PROJECT_NAME: str = "EcoMesh Backend API"
    API_V1_STR: str = "/api/v1"
    
    # Security (Use openssl rand -hex 32 for production)
    SECRET_KEY: str = os.getenv("SECRET_KEY", "super-secret-ecomesh-hackathon-key-2026")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7 # 1 week

    # PostgreSQL Database
    POSTGRES_USER: str = os.getenv("POSTGRES_USER", "postgres")
    POSTGRES_PASSWORD: str = os.getenv("POSTGRES_PASSWORD", "postgres")
    POSTGRES_SERVER: str = os.getenv("POSTGRES_SERVER", "localhost")
    POSTGRES_PORT: int = int(os.getenv("POSTGRES_PORT", "5432"))
    POSTGRES_DB: str = os.getenv("POSTGRES_DB", "ecomesh_db")
    
    @property
    def SQLALCHEMY_DATABASE_URI(self) -> str:
        return f"postgresql://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}@{self.POSTGRES_SERVER}/{self.POSTGRES_DB}"

    # InfluxDB (Time-Series for mmWave/Power data)
    INFLUX_URL: str = os.getenv("INFLUX_URL", "http://localhost:8086")
    INFLUX_TOKEN: str = os.getenv("INFLUX_TOKEN", "ecomesh-secure-token")
    INFLUX_ORG: str = os.getenv("INFLUX_ORG", "um_technothon")
    INFLUX_BUCKET: str = os.getenv("INFLUX_BUCKET", "sensor_metrics")

    # model config configures Pydantic to read from a .env file if present
    model_config = SettingsConfigDict(env_file=".env", case_sensitive=True)

@lru_cache()
def get_settings() -> Settings:
    return Settings()