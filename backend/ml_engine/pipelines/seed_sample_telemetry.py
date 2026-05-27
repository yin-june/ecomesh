import logging
import os
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

from influxdb_client import InfluxDBClient, Point, WritePrecision
from influxdb_client.client.write_api import SYNCHRONOUS

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class SeedConfig:
    url: str = os.getenv("INFLUX_URL", "http://localhost:8086")
    token: str = os.getenv("INFLUX_TOKEN", "ecomesh-secure-token")
    org: str = os.getenv("INFLUX_ORG", "um_technothon")
    bucket: str = os.getenv("INFLUX_BUCKET", "sensor_metrics")


def build_sample_points(hours_back: int = 72):
    now = datetime.now(timezone.utc)

    for offset in range(hours_back, 0, -1):
        timestamp = now - timedelta(hours=offset)
        hour = timestamp.hour
        is_weekend = timestamp.weekday() >= 5
        occupancy = 0 if hour < 7 or hour > 21 else (2 if is_weekend else 6) + (hour % 4)
        outdoor_temp = 29.0 + (hour % 6) * 0.6 + (1.5 if not is_weekend else 0.0)
        energy_draw_kwh = round(0.8 + occupancy * 0.18 + max(outdoor_temp - 27.0, 0) * 0.12, 3)

        yield (
            Point("zone_telemetry")
            .tag("zone_id", "zone-a")
            .field("occupancy_count", occupancy)
            .field("outdoor_temp", outdoor_temp)
            .field("energy_draw_kwh", energy_draw_kwh)
            .time(timestamp, WritePrecision.NS)
        )


def seed_sample_telemetry(hours_back: int = 72):
    config = SeedConfig()
    client = InfluxDBClient(url=config.url, token=config.token, org=config.org)

    try:
        points = list(build_sample_points(hours_back=hours_back))
        client.write_api(write_options=SYNCHRONOUS).write(bucket=config.bucket, org=config.org, record=points)
        logger.info("Seeded %s telemetry points into %s/%s.", len(points), config.org, config.bucket)
    finally:
        client.close()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
    seed_sample_telemetry()