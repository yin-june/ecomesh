import os
import logging
import pandas as pd
from influxdb_client import InfluxDBClient

logger = logging.getLogger(__name__)

# --- MALAYSIAN CONTEXT CONSTANTS FOR HACKATHON ---
CARBON_EMISSION_FACTOR = 0.740  # kg CO2e/kWh (Energy Commission Peninsular Grid Factor)
TNB_COMMERCIAL_RATE = 0.435     # RM/kWh (TNB Tariff B - Low Voltage Commercial Base)

class InfluxDataLoader:
    def __init__(self):
        self.url = os.getenv("INFLUX_URL", "http://localhost:8086")
        self.token = os.getenv("INFLUX_TOKEN", "ecomesh-secure-token")
        self.org = os.getenv("INFLUX_ORG", "um_technothon")
        self.bucket = os.getenv("INFLUX_BUCKET", "sensor_metrics")
        self.client = InfluxDBClient(url=self.url, token=self.token, org=self.org)

    def fetch_training_data(self, days_back: int = 30) -> pd.DataFrame:
        """
        Extracts historical occupancy and energy draw to train the AI.
        """
        query = f"""
        from(bucket: "{self.bucket}")
          |> range(start: -{days_back}d)
          |> filter(fn: (r) => r._measurement == "zone_telemetry")
          |> pivot(rowKey:["_time"], columnKey: ["_field"], valueColumn: "_value")
          |> keep(columns: ["_time", "zone_id", "energy_draw_kwh", "occupancy_count", "outdoor_temp"])
        """
        try:
            result = self.client.query_api().query_data_frame(query, org=self.org)
            if isinstance(result, list) and len(result) > 0:
                df = result[0]
            else:
                df = result
            
            # Clean up time-series data
            df['_time'] = pd.to_datetime(df['_time'])
            df.set_index('_time', inplace=True)
            df = df.dropna()
            
            logger.info(f"Loaded {len(df)} rows of training data from InfluxDB.")
            return df
            
        except Exception as e:
            logger.error(f"Database extraction failed: {str(e)}")
            return pd.DataFrame()

    @staticmethod
    def calculate_impact(kwh_saved: float) -> dict:
        """Translates raw energy savings into ESG and financial metrics for the App UI"""
        return {
            "rm_saved": round(kwh_saved * TNB_COMMERCIAL_RATE, 2),
            "kg_co2_avoided": round(kwh_saved * CARBON_EMISSION_FACTOR, 3),
            "trees_equivalent": round((kwh_saved * CARBON_EMISSION_FACTOR) / 10.0, 2) # Est. 10kg CO2 per tree/month
        }