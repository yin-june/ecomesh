import logging
from datetime import datetime
from influxdb_client import InfluxDBClient, Point, WritePrecision
from influxdb_client.client.write_api import SYNCHRONOUS
from config.settings import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

class InfluxService:
    def __init__(self):
        try:
            self.client = InfluxDBClient(url=settings.INFLUX_URL, token=settings.INFLUX_TOKEN, org=settings.INFLUX_ORG)
            self.write_api = self.client.write_api(write_options=SYNCHRONOUS)
        except Exception as e:
            logger.error(f"Failed to initialize InfluxDB client: {e}")
            self.client = None

    def write_occupancy(self, zone_id: str, payload: dict):
        if not self.client:
            return
        try:
            point = Point("occupancy") \
                .tag("zone_id", zone_id) \
                .tag("node_id", payload.get("node", "unknown")) \
                .field("presence", float(payload.get("presence", 0))) \
                .field("distance", float(payload.get("distance", 0))) \
                .time(datetime.utcnow(), WritePrecision.NS)
            self.write_api.write(bucket=settings.INFLUX_BUCKET, record=point)
            logger.debug(f"Wrote occupancy for {zone_id} to InfluxDB")
        except Exception as e:
            logger.error(f"Error writing occupancy to InfluxDB: {e}")

    def write_power(self, zone_id: str, payload: dict):
        if not self.client:
            return
        try:
            point = Point("power") \
                .tag("zone_id", zone_id) \
                .field("voltage", float(payload.get("voltage", 0.0))) \
                .field("current", float(payload.get("current", 0.0))) \
                .field("power", float(payload.get("power", 0.0))) \
                .field("energy", float(payload.get("energy", 0.0))) \
                .time(datetime.utcnow(), WritePrecision.NS)
            self.write_api.write(bucket=settings.INFLUX_BUCKET, record=point)
            logger.debug(f"Wrote power telemetry for {zone_id} to InfluxDB")
        except Exception as e:
            logger.error(f"Error writing power telemetry to InfluxDB: {e}")

influx_service = InfluxService()
