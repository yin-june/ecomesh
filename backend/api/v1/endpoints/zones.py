from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database.database import get_db
from database import models, schemas
from services.mqtt_broker import mqtt_bridge

router = APIRouter()

@router.get("/", response_model=list[schemas.ZoneResponse])
def get_active_zones(db: Session = Depends(get_db)):
    """Fetches all zones for the Flutter Spatial Map."""
    return db.query(models.Zone).all()

@router.post("/{zone_id}/claim", status_code=200)
def claim_zone(zone_id: str, profile_name: str, db: Session = Depends(get_db)):
    """
    Triggered when a user enters a room and 'claims' it via BLE.
    Activates their Follow-Me energy profile.
    """
    zone = db.query(models.Zone).filter(models.Zone.id == zone_id).first()
    if not zone:
        raise HTTPException(status_code=404, detail="Zone not found")

    # Example: If profile is "Deep Work", dim lights and set AC to 23°C
    if profile_name == "Deep Work":
        mqtt_bridge.override_zone_ac(zone_id, target_temp=23, mode="COOL")
    
    return {"status": "success", "message": f"Zone {zone_id} configured for {profile_name}"}