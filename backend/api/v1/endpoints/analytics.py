from fastapi import APIRouter
from ml_engine.pipelines.inference import HVACPredictor
from ml_engine.dataset_loader import InfluxDataLoader
from services.metmalaysia_api import MetMalaysiaService
from services.tnb_tariff import TNBTariffCalculator

router = APIRouter()
weather_service = MetMalaysiaService()

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