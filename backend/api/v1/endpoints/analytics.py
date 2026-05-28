import logging
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime, timedelta
from config.database import get_db
from ml_engine.pipelines.inference import HVACPredictor
from ml_engine.dataset_loader import InfluxDataLoader
from services.metmalaysia_api import MetMalaysiaService
from services.tnb_tariff import TNBTariffCalculator

logger = logging.getLogger(__name__)
router = APIRouter()
weather_service = MetMalaysiaService()

class EnergyReading(BaseModel):
    timestamp: datetime
    actual_kwh: float
    predicted_kwh: float

@router.get("/predict-demand")
async def get_ai_cooling_strategy(zone_id: str, current_occupancy: int):
    """
    Executes the ML model to find the optimal AC temperature based on live weather.
    """
    try:
        # 1. Fetch live weather
        weather = await weather_service.get_current_weather()
        
        # 2. Run Inference
        predictor = HVACPredictor()
        strategy = predictor.execute_drift_strategy(
            current_occupancy=current_occupancy,
            outdoor_temp=weather["outdoor_temp"]
        )
        return strategy
    except Exception as e:
        return {"error": "ML Engine unavailable", "details": str(e)}

@router.get("/my-impact")
def get_user_esg_impact(kwh_saved_this_week: float):
    """Converts raw energy savings into UI-friendly gamification metrics."""
    # Using the local dataset loader to parse emissions
    esg_data = InfluxDataLoader.calculate_impact(kwh_saved_this_week)
    
    # Using TNB tariff calculator
    rm_saved = TNBTariffCalculator.calculate_commercial_cost(kwh_saved_this_week)
    esg_data["rm_saved"] = rm_saved
    
    return esg_data

@router.get("/energy-history/{zone_id}", response_model=list[EnergyReading])
def get_zone_energy_history(zone_id: str, days: int = 7):
    """
    Fetches historical energy readings for a zone from InfluxDB.
    Returns actual vs. predicted energy consumption.
    """
    try:
        influx_loader = InfluxDataLoader()
        
        # Query energy readings for the zone over the past N days
        query = f"""
        from(bucket: "sensor_metrics")
          |> range(start: -{days}d)
          |> filter(fn: (r) => r._measurement == "zone_telemetry")
          |> filter(fn: (r) => r.zone_id == "{zone_id}")
          |> filter(fn: (r) => r._field == "energy_draw_kwh")
          |> sort(columns: ["_time"])
        """
        
        result = influx_loader.client.query_api().query_data_frame(query, org=influx_loader.org)
        
        readings = []
        if isinstance(result, list):
            for frame in result:
                if not frame.empty:
                    for _, row in frame.iterrows():
                        readings.append(EnergyReading(
                            timestamp=row['_time'],
                            actual_kwh=float(row['_value']),
                            predicted_kwh=0.0,  # TODO: Get from ML model predictions
                        ))
        
        return readings
    except Exception as e:
        logger.warning(f"Failed to fetch energy history for {zone_id}: {e}")
        return []