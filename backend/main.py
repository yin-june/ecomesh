import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config.settings import get_settings
from core.middleware import ProcessTimeMiddleware
from api.v1.api import api_router
from services.mqtt_broker import mqtt_bridge

# Setup Logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

settings = get_settings()

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan Context Manager:
    Code before 'yield' runs on Startup. Code after 'yield' runs on Shutdown.
    """
    logger.info("Initializing EcoMesh AI & Hardware Bridges...")
    
    # Create database tables if they don't exist
    from database.base import Base
    from config.database import engine
    import database.models  # Ensure all models are imported so Base knows about them
    Base.metadata.create_all(bind=engine)
    logger.info("Database tables verified/created.")
    
    # Connect to MQTT Broker to listen/send commands to ESP32 Gateways
    mqtt_bridge.connect()
    
    yield # App is running and serving requests
    
    # Graceful Shutdown
    logger.info("Shutting down EcoMesh services...")
    mqtt_bridge.disconnect()


# Initialize FastAPI
app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    lifespan=lifespan,
    description="Backend for UM Technothon 2026: EcoMesh Smart Energy Management"
)

# Apply CORS (Critical for Flutter Web/App communication)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, restrict to your App's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Apply Custom Latency Tracking Middleware
app.add_middleware(ProcessTimeMiddleware)

# Include API Routers
app.include_router(api_router, prefix=settings.API_V1_STR)


@app.get("/")
def root_health_check():
    """Simple health check endpoint."""
    return {
        "status": "online", 
        "project": settings.PROJECT_NAME,
        "message": "EcoMesh Backend is ready for Technothon 2026!"
    }

# To run locally for testing:
# uvicorn main:app --reload --host 0.0.0.0 --port 8000