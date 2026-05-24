import os
import joblib
import logging
import pandas as pd
from datetime import datetime

logger = logging.getLogger(__name__)
MODEL_PATH = os.path.join(os.path.dirname(__file__), "../models/demand_forecast.pkl")

class HVACPredictor:
    def __init__(self):
        if not os.path.exists(MODEL_PATH):
            raise FileNotFoundError(f"Model binary not found at {MODEL_PATH}. Run train_pipeline.py first.")
        self.model = joblib.load(MODEL_PATH)

    def execute_drift_strategy(self, current_occupancy: int, outdoor_temp: float) -> dict:
        """
        Executes the 'Friday Afternoon Drift' logic.
        Suggests an optimized AC temperature based on live AI prediction.
        """
        now = datetime.now()
        
        # Prepare live feature array for the model
        live_data = pd.DataFrame([{
            'occupancy_count': current_occupancy,
            'outdoor_temp': outdoor_temp,
            'hour': now.hour,
            'day_of_week': now.weekday(),
            'is_weekend': int(now.weekday() >= 5)
        }])

        # Predict the required cooling load (kWh)
        predicted_load = self.model.predict(live_data)[0]

        # --- The 'Drift' Logic Ruleset ---
        # Instead of turning the AC off, we drift the temperature to maintain comfort while slashing wattage.
        suggested_temp = 24 # Default Eco-Baseline
        
        if current_occupancy == 0:
            action = "SHUTDOWN"
            suggested_temp = None
        elif predicted_load < 1.0 and outdoor_temp < 28.0:
            action = "AGGRESSIVE_DRIFT"
            suggested_temp = 26 # Raining/Cool outside, light occupancy
        elif predicted_load > 2.5:
            action = "MAX_COOLING"
            suggested_temp = 22 # High occupancy, hot afternoon
        else:
            action = "STANDARD_ECO"
            suggested_temp = 24

        logger.info(f"Inference Complete -> Action: {action} | Target Temp: {suggested_temp}°C")
        
        return {
            "predicted_kwh_load": round(predicted_load, 2),
            "suggested_action": action,
            "target_ac_temp": suggested_temp
        }