import logging
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from config.database import get_db
from database import models, schemas
from services.mqtt_broker import mqtt_bridge
from ml_engine.dataset_loader import InfluxDataLoader

logger = logging.getLogger(__name__)
router = APIRouter()

# --- Endpoints ---
@router.get("/", response_model=list[schemas.ZoneResponse])
def get_active_zones(db: Session = Depends(get_db)):
    """Fetches all zones for the Flutter Spatial Map."""
    return db.query(models.Zone).all()

@router.get("/{zone_id}/telemetry", response_model=schemas.ZoneTelemetry)
def get_zone_telemetry(zone_id: str, db: Session = Depends(get_db)):
    """
    Fetches live telemetry for a zone from InfluxDB:
    occupancy count, current temperature, energy draw.
    """
    zone = db.query(models.Zone).filter(models.Zone.id == zone_id).first()
    if not zone:
        raise HTTPException(status_code=404, detail="Zone not found")
    
    try:
        # Query latest InfluxDB data for this zone
        influx_loader = InfluxDataLoader()
        query = f"""
        from(bucket: "sensor_metrics")
          |> range(start: -1h)
          |> filter(fn: (r) => r._measurement == "zone_telemetry")
          |> filter(fn: (r) => r.zone_id == "{zone_id}")
          |> sort(columns: ["_time"], desc: true)
          |> limit(n: 1)
          |> pivot(rowKey:["_time"], columnKey: ["_field"], valueColumn: "_value")
        """
        result = influx_loader.client.query_api().query_data_frame(query, org=influx_loader.org)
        
        if isinstance(result, list) and len(result) > 0 and not result[0].empty:
            df = result[0]
            latest = df.iloc[0]
            return schemas.ZoneTelemetry(
                zone_id=zone_id,
                occupancy_count=int(latest.get('occupancy_count', 0)),
                temperature=float(latest.get('outdoor_temp', zone.base_ac_target)),
                target_temp=zone.base_ac_target,
                energy_draw_kwh=float(latest.get('energy_draw_kwh', 0.0)),
                status='active' if int(latest.get('occupancy_count', 0)) > 0 else 'idle',
            )
    except Exception as e:
        logger.warning(f"Failed to fetch InfluxDB telemetry for {zone_id}: {e}")
    
    # Fallback to defaults if InfluxDB unavailable
    return schemas.ZoneTelemetry(
        zone_id=zone_id,
        occupancy_count=0,
        temperature=zone.base_ac_target,
        target_temp=zone.base_ac_target,
        energy_draw_kwh=0.0,
        status='idle',
    )

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

@router.get("/{zone_id}/desks", response_model=list[schemas.DeskResponse])
def get_zone_desks(zone_id: str, db: Session = Depends(get_db)):
    """Fetches all desks in a zone."""
    zone = db.query(models.Zone).filter(models.Zone.id == zone_id).first()
    if not zone:
        raise HTTPException(status_code=404, detail="Zone not found")
    
    return db.query(models.Desk).filter(models.Desk.zone_id == zone_id).all()

@router.post("/{zone_id}/desks", response_model=schemas.DeskResponse, status_code=201)
def create_desk(zone_id: str, desk: schemas.DeskCreate, db: Session = Depends(get_db)):
    """Creates a new desk in a zone."""
    zone = db.query(models.Zone).filter(models.Zone.id == zone_id).first()
    if not zone:
        raise HTTPException(status_code=404, detail="Zone not found")
    
    db_desk = models.Desk(
        id=desk.id,
        zone_id=zone_id,
        label=desk.label,
        x_pos=desk.x_pos,
        y_pos=desk.y_pos
    )
    db.add(db_desk)
    db.commit()
    db.refresh(db_desk)
    return db_desk

@router.put("/{zone_id}/desks/{desk_id}/claim", response_model=schemas.DeskResponse, status_code=200)
def update_desk_claim(
    zone_id: str,
    desk_id: str,
    update: schemas.DeskUpdate,
    db: Session = Depends(get_db),
):
    """Updates desk claim status."""
    desk = db.query(models.Desk).filter(models.Desk.id == desk_id, models.Desk.zone_id == zone_id).first()
    if not desk:
        raise HTTPException(status_code=404, detail="Desk not found")
    
    desk.is_claimed = update.is_claimed
    desk.claimed_by = update.claimed_by
    db.commit()
    db.refresh(desk)
    
    # If claimed by a user, we can trigger their Energy Profile logic here
    if update.is_claimed and update.claimed_by:
        profile = db.query(models.EnergyProfile).filter(models.EnergyProfile.owner_id == update.claimed_by).first()
        if profile:
            # Trigger MQTT override
            mqtt_bridge.override_zone_ac(zone_id, target_temp=profile.preferred_temp, mode="COOL")
            
    return desk

@router.post("/{zone_id}/desks/{desk_id}/power", response_model=schemas.DeskResponse, status_code=200)
def toggle_desk_power(
    zone_id: str,
    desk_id: str,
    toggle: schemas.DeskPowerToggle,
    db: Session = Depends(get_db),
):
    """Toggles power on a desk socket."""
    desk = db.query(models.Desk).filter(models.Desk.id == desk_id, models.Desk.zone_id == zone_id).first()
    if not desk:
        raise HTTPException(status_code=404, detail="Desk not found")
    
    desk.is_powered = toggle.is_powered
    db.commit()
    db.refresh(desk)
    
    # Publish MQTT command to Gateway Hub to toggle relay
    mqtt_bridge.publish(
        topic=f"ecomesh/zones/{zone_id}/command",
        payload={"device": "RELAY", "desk_id": desk_id, "state": toggle.is_powered}
    )
    
    return desk