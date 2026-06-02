import os
import time
import logging
import httpx
from typing import Dict, Any
from config.settings import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

class OpenWeatherService:
    def __init__(self):
        # OpenWeather One Call API 4.0 Endpoint
        self.api_url = "https://api.openweathermap.org/data/4.0/onecall"
        self.api_key = settings.OPENWEATHER_API_KEY
        self.cache_ttl = 900  # Cache weather data for 15 minutes
        self._cache = {"timestamp": 0, "data": None}

        # Coordinates for Petaling Jaya / Universiti Malaya
        self.lat = settings.OPENWEATHER_LAT
        self.lon = settings.OPENWEATHER_LON

    async def get_current_weather(self) -> Dict[str, Any]:
        """Fetches Petaling Jaya/UM weather from OpenWeather. Falls back to averages if offline."""
        now = time.time()
        
        # Return cached data if still fresh (avoids rate limiting)
        if now - self._cache["timestamp"] < self.cache_ttl and self._cache["data"]:
            return self._cache["data"]

        if self.api_key == "your_api_key_here":
            logger.warning("OpenWeather API key missing. Using fail-safe defaults.")
            return {"outdoor_temp": 32.5, "humidity": 78.0}

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                params = {
                    "lat": self.lat,
                    "lon": self.lon,
                    "appid": self.api_key,
                    "units": "metric", # Request temperature in Celsius
                    "exclude": "minutely,hourly,daily,alerts" # Save bandwidth, we only need 'current'
                }
                
                response = await client.get(self.api_url, params=params)
                response.raise_for_status() # Automatically raise an exception for 401/404/500 errors
                
                data = response.json()
                
                weather_data = {
                    "outdoor_temp": float(data["current"]["temp"]),
                    "humidity": float(data["current"]["humidity"])
                }
                
                self._cache = {"timestamp": now, "data": weather_data}
                return weather_data
            
        except httpx.HTTPStatusError as e:
            logger.error(f"OpenWeather HTTP Error {e.response.status_code}. Using defaults.")
            return {"outdoor_temp": 30.0, "humidity": 80.0}
        except Exception as e:
            logger.error(f"OpenWeather API unreachable. Using fail-safe defaults. Error: {e}")
            return {"outdoor_temp": 30.0, "humidity": 80.0}