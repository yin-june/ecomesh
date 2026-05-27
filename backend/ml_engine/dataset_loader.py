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
            if isinstance(result, list):
                frames = [frame for frame in result if isinstance(frame, pd.DataFrame) and not frame.empty]
                if not frames:
                    logger.warning("InfluxDB returned no usable training rows.")
                    return pd.DataFrame()
                df = pd.concat(frames, ignore_index=True, sort=False)
            elif isinstance(result, pd.DataFrame):
                df = result.copy()
            else:
                logger.warning("Unexpected InfluxDB query result type: %s", type(result).__name__)
                return pd.DataFrame()

            if df.empty:
                logger.warning("InfluxDB returned an empty training frame.")
                return pd.DataFrame()

            if "_time" not in df.columns:
                if "time" in df.columns:
                    df = df.rename(columns={"time": "_time"})
                else:
                    logger.error("Training data is missing a time column. Available columns: %s", list(df.columns))
                    return pd.DataFrame()

            # Clean up time-series data
            df["_time"] = pd.to_datetime(df["_time"], errors="coerce")
            df = df.dropna(subset=["_time"])
            df = df.set_index("_time")
            df = df.dropna()

            required_columns = {"occupancy_count", "outdoor_temp", "energy_draw_kwh"}
            missing_columns = required_columns.difference(df.columns)
            if missing_columns:
                logger.error("Training data is missing required columns: %s", sorted(missing_columns))
                return pd.DataFrame()
            
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