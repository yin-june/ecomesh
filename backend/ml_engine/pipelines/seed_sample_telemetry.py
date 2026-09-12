"""
EcoMesh – Enhanced InfluxDB Telemetry Seeder
=============================================
Seeds realistic 72-hour mmWave + PZEM sensor readings for ALL zones.

Realistic scenarios per zone:
  zone-a  : Mostly idle / ghost-power (low occupancy, unclaimed sockets drawing power)
  zone-b  : Busy open-plan area (high occupancy 9-17h weekdays)
  zone-c  : Meeting room (burst occupancy 10h & 14h, empty otherwise)
  zone-d  : Lab (elevated energy draw 24/7, moderate occupancy)

Usage:
    cd backend
    python ml_engine/pipelines/seed_sample_telemetry.py

Re-running will write additional data points (InfluxDB is append-only).
"""

import logging
import os
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import Iterator

from influxdb_client import InfluxDBClient, Point, WritePrecision
from influxdb_client.client.write_api import SYNCHRONOUS

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class SeedConfig:
    url: str = field(default_factory=lambda: os.getenv("INFLUX_URL", "http://localhost:8086"))
    token: str = field(default_factory=lambda: os.getenv("INFLUX_TOKEN", "ecomesh-secure-token"))
    org: str = field(default_factory=lambda: os.getenv("INFLUX_ORG", "um_technothon"))
    bucket: str = field(default_factory=lambda: os.getenv("INFLUX_BUCKET", "sensor_metrics"))


# ─── Zone profiles ────────────────────────────────────────────────────────────
ZONE_PROFILES = {
    "zone-a": {
        "name": "Zone A (Idle/Ghost)",
        # Idle zone: low peak occupancy, but unclaimed sockets draw power
        "peak_occupancy": 3,
        "base_energy_kwh": 0.42,     # ghost power from unclaimed desks
        "energy_per_person": 0.15,
        "ac_target": 26.0,
        "active_hours": (8, 17),     # sporadic use
        "ghost_power": True,
    },
    "zone-b": {
        "name": "Zone B (Active Open Plan)",
        "peak_occupancy": 8,
        "base_energy_kwh": 0.80,
        "energy_per_person": 0.18,
        "ac_target": 24.0,
        "active_hours": (8, 18),
        "ghost_power": False,
    },
    "zone-c": {
        "name": "Zone C (Meeting Room)",
        # Bursty: empty most of the day, packed during 2 meetings
        "peak_occupancy": 10,
        "base_energy_kwh": 0.10,    # projector standby
        "energy_per_person": 0.10,
        "ac_target": 23.0,
        "active_hours": (9, 11),    # morning meeting window
        "burst_hours": (13, 15),    # afternoon meeting window
        "ghost_power": False,
    },
    "zone-d": {
        "name": "Zone D (Lab)",
        # Elevated constant draw from lab equipment
        "peak_occupancy": 5,
        "base_energy_kwh": 1.20,    # always-on lab gear
        "energy_per_person": 0.22,
        "ac_target": 22.0,
        "active_hours": (7, 22),    # lab stays open late
        "ghost_power": False,
    },
}


def _occupancy_for_zone(zone_id: str, hour: int, is_weekend: bool) -> int:
    """Returns a realistic occupancy count for the zone at a given hour."""
    profile = ZONE_PROFILES[zone_id]
    start_h, end_h = profile["active_hours"]
    peak = profile["peak_occupancy"]

    if is_weekend:
        # Weekends: reduced occupancy for all zones except the lab
        peak = max(1, peak // 3) if zone_id != "zone-d" else max(1, peak // 2)

    in_window = start_h <= hour < end_h

    # Zone C has a burst window (meetings)
    if zone_id == "zone-c":
        burst_start, burst_end = profile.get("burst_hours", (13, 15))
        in_burst = burst_start <= hour < burst_end
        if in_window or in_burst:
            return peak - (hour % 3)  # slight variation
        return 0

    if not in_window:
        return 0

    # Ramp up in morning, ramp down in evening
    mid = (start_h + end_h) // 2
    if hour <= mid:
        frac = (hour - start_h) / max(1, mid - start_h)
    else:
        frac = 1.0 - (hour - mid) / max(1, end_h - mid)

    base = max(0, int(peak * frac))
    variation = hour % 3 - 1   # -1, 0, +1 variation
    return max(0, base + variation)


def _energy_for_zone(zone_id: str, occupancy: int, outdoor_temp: float) -> float:
    """Calculates realistic energy draw in kWh for a 1-hour window."""
    profile = ZONE_PROFILES[zone_id]
    base = profile["base_energy_kwh"]
    per_person = profile["energy_per_person"]

    # Ghost power: even when occupancy=0, Zone A draws more than normal base
    if profile.get("ghost_power") and occupancy == 0:
        ghost = 0.042   # 42W unclaimed sockets
        base = max(base, ghost)

    # Cooling energy increases when outdoor temp is high
    cooling_factor = max(0.0, outdoor_temp - 27.0) * 0.10

    energy = base + (occupancy * per_person) + cooling_factor
    return round(energy, 3)


def build_all_zone_points(hours_back: int = 72) -> Iterator[Point]:
    """Generates telemetry points for all zones over the past N hours."""
    now = datetime.now(timezone.utc)

    for offset in range(hours_back, 0, -1):
        timestamp = now - timedelta(hours=offset)
        hour = timestamp.hour
        is_weekend = timestamp.weekday() >= 5

        outdoor_temp = round(29.0 + (hour % 6) * 0.5 + (1.2 if not is_weekend else 0.0), 1)

        for zone_id, profile in ZONE_PROFILES.items():
            occupancy = _occupancy_for_zone(zone_id, hour, is_weekend)
            energy = _energy_for_zone(zone_id, occupancy, outdoor_temp)

            # Temperature: rises toward outdoor temp when zone is inactive
            if occupancy == 0:
                zone_temp = round(profile["ac_target"] + 2.0 + (outdoor_temp - 30) * 0.15, 1)
            else:
                # Slight overshoot when first occupied, then stabilises
                zone_temp = round(profile["ac_target"] + 0.3 * (1 - min(occupancy / 5, 1)), 1)

            yield (
                Point("zone_telemetry")
                .tag("zone_id", zone_id)
                .field("occupancy_count", occupancy)
                .field("outdoor_temp", outdoor_temp)
                .field("energy_draw_kwh", energy)
                .field("temperature", zone_temp)
                .field("target_temp", profile["ac_target"])
                .time(timestamp, WritePrecision.NS)
            )


def seed_sample_telemetry(hours_back: int = 72):
    config = SeedConfig()
    client = InfluxDBClient(url=config.url, token=config.token, org=config.org)

    try:
        logger.info("Generating telemetry points for %d hours across %d zones...",
                    hours_back, len(ZONE_PROFILES))

        points = list(build_all_zone_points(hours_back=hours_back))

        write_api = client.write_api(write_options=SYNCHRONOUS)
        # Write in batches of 500 to avoid memory pressure
        batch_size = 500
        for i in range(0, len(points), batch_size):
            batch = points[i:i + batch_size]
            write_api.write(bucket=config.bucket, org=config.org, record=batch)
            logger.info("  Written %d / %d points", min(i + batch_size, len(points)), len(points))

        logger.info("✓ Seeded %d telemetry points into %s/%s",
                    len(points), config.org, config.bucket)
        logger.info("  Zones covered: %s", ", ".join(ZONE_PROFILES.keys()))

    except Exception as e:
        logger.error("✗ Failed to seed telemetry: %s", e)
        raise
    finally:
        client.close()


if __name__ == "__main__":
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s"
    )
    seed_sample_telemetry()