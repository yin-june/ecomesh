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

# --- Schemas ---
class DeskCreate(BaseModel):
    label: str
    x: float
    y: float

class DeskUpdate(BaseModel):
    is_claimed: bool
    claimed_by: str | None = None

class DeskPowerToggle(BaseModel):
    is_powered: bool

class ZoneTelemetry(BaseModel):
    zone_id: str
    occupancy_count: int
    temperature: float
    target_temp: float
    energy_draw_kwh: float
    status: str  # 'active', 'idle', 'ghost', 'off'

# --- Endpoints ---
@router.get("/", response_model=list[schemas.ZoneResponse])
def get_active_zones(db: Session = Depends(get_db)):
    """Fetches all zones for the Flutter Spatial Map."""
    return db.query(models.Zone).all()

@router.get("/{zone_id}/telemetry", response_model=ZoneTelemetry)
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
            return ZoneTelemetry(
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
    return ZoneTelemetry(
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

@router.get("/{zone_id}/desks", response_model=list[dict])
def get_zone_desks(zone_id: str, db: Session = Depends(get_db)):
    """Fetches all desks in a zone."""
    zone = db.query(models.Zone).filter(models.Zone.id == zone_id).first()
    if not zone:
        raise HTTPException(status_code=404, detail="Zone not found")
    
    # TODO: Query Desk table when it's created
    return []

@router.post("/{zone_id}/desks", status_code=201)
def create_desk(zone_id: str, desk: DeskCreate, db: Session = Depends(get_db)):
    """Creates a new desk in a zone."""
    zone = db.query(models.Zone).filter(models.Zone.id == zone_id).first()
    if not zone:
        raise HTTPException(status_code=404, detail="Zone not found")
    
    # TODO: Create Desk record in database
    return {"id": f"{zone_id}-desk-1", "label": desk.label, "x": desk.x, "y": desk.y}

@router.put("/{zone_id}/desks/{desk_id}/claim", status_code=200)
def update_desk_claim(
    zone_id: str,
    desk_id: str,
    update: DeskUpdate,
    db: Session = Depends(get_db),
):
    """Updates desk claim status."""
    zone = db.query(models.Zone).filter(models.Zone.id == zone_id).first()
    if not zone:
        raise HTTPException(status_code=404, detail="Zone not found")
    
    # TODO: Update Desk claim status
    return {"status": "success", "message": f"Desk {desk_id} claim updated"}

@router.post("/{zone_id}/desks/{desk_id}/power", status_code=200)
def toggle_desk_power(
    zone_id: str,
    desk_id: str,
    toggle: DeskPowerToggle,
    db: Session = Depends(get_db),
):
    """Toggles power on a desk socket."""
    zone = db.query(models.Zone).filter(models.Zone.id == zone_id).first()
    if not zone:
        raise HTTPException(status_code=404, detail="Zone not found")
    
    # TODO: Toggle socket power via MQTT
    return {"status": "success", "message": f"Desk {desk_id} power toggled"}