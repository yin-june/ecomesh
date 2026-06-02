import os
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from services.weather_api import OpenWeatherService


def _has_real_openweather_key() -> bool:
    api_key = os.getenv("OPENWEATHER_API_KEY", "")
    return bool(api_key) and api_key != "your_api_key_here"


pytestmark = pytest.mark.asyncio


@pytest.mark.skipif(
    not _has_real_openweather_key(),
    reason="OPENWEATHER_API_KEY is not configured with a real key",
)
async def test_openweather_connection_returns_live_weather_payload():
    service = OpenWeatherService()

    weather = await service.get_current_weather()

    assert isinstance(weather, dict)
    assert "outdoor_temp" in weather
    assert "humidity" in weather
    assert isinstance(weather["outdoor_temp"], (int, float))
    assert isinstance(weather["humidity"], (int, float))
    assert service._cache["data"] == weather
    assert service._cache["timestamp"] > 0