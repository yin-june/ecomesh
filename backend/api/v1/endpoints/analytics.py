import logging
from fastapi import APIRouter
from pydantic import BaseModel
from datetime import datetime
from ml_engine.pipelines.inference import HVACPredictor
from ml_engine.dataset_loader import InfluxDataLoader
from services.weather_api import OpenWeatherService
from services.tnb_tariff import TNBTariffCalculator

logger = logging.getLogger(__name__)
router = APIRouter()
weather_service = OpenWeatherService()

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
    Returns actual vs. ML-predicted energy consumption.
    """
    try:
        influx_loader = InfluxDataLoader()

        # Try to load the trained model for predictions
        try:
            predictor = HVACPredictor()
            model_available = True
        except FileNotFoundError:
            predictor = None
            model_available = False
            logger.warning("ML model not found – predicted_kwh will be 0.0")

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
            frames = result
        elif hasattr(result, 'empty'):
            frames = [result]
        else:
            frames = []

        for frame in frames:
            if frame is None or frame.empty:
                continue
            for _, row in frame.iterrows():
                actual = float(row['_value'])

                # Use ML model to get a predicted value for this time context
                predicted = 0.0
                if model_available:
                    try:
                        import pandas as pd
                        ts = row['_time']
                        # Estimate occupancy from energy draw (inverse of seeder formula)
                        estimated_occupancy = max(0, int((actual - 0.8) / 0.18))
                        feature_row = pd.DataFrame([{
                            'occupancy_count': estimated_occupancy,
                            'outdoor_temp': 30.0,  # conservative KL estimate
                            'hour': ts.hour,
                            'day_of_week': ts.weekday(),
                            'is_weekend': int(ts.weekday() >= 5)
                        }])
                        predicted = round(float(predictor.model.predict(feature_row)[0]), 3)
                    except Exception as pred_err:
                        logger.debug("Prediction failed for row: %s", pred_err)
                        predicted = 0.0

                readings.append(EnergyReading(
                    timestamp=row['_time'],
                    actual_kwh=actual,
                    predicted_kwh=predicted,
                ))

        return readings
    except Exception as e:
        logger.warning(f"Failed to fetch energy history for {zone_id}: {e}")
        return []