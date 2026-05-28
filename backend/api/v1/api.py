from fastapi import APIRouter
from api.v1.endpoints import zones, analytics, auth, control, notifications

api_router = APIRouter()
api_router.include_router(zones.router, prefix="/zones", tags=["Zones"])
api_router.include_router(analytics.router, prefix="/analytics", tags=["Analytics & AI"])
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(control.router, prefix="/control", tags=["Control"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])