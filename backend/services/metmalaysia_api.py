import time
import logging
import httpx
from typing import Dict, Any

logger = logging.getLogger(__name__)

class MetMalaysiaService:
    def __init__(self):
        # In a real scenario, use https://api.met.gov.my/v2.1/
        self.api_url = "https://api.met.gov.my/v2.1/data"
        self.cache_ttl = 900  # Cache weather data for 15 minutes
        self._cache = {"timestamp": 0, "data": None}

    async def get_current_weather(self, location_id: str = "LOCATION:151") -> Dict[str, Any]:
        """Fetches Petaling Jaya/UM weather. Falls back to averages if offline."""
        now = time.time()
        
        # Return cached data if still fresh (avoids rate limiting)
        if now - self._cache["timestamp"] < self.cache_ttl and self._cache["data"]:
            return self._cache["data"]

        try:
            # Simulate API call for the hackathon (replace with real httpx request with token)
            # async with httpx.AsyncClient() as client:
            #     response = await client.get(f"{self.api_url}?datasetid=FORECAST&locationid={location_id}")
            #     data = response.json()
            
            weather_data = {
                "outdoor_temp": 32.5,  # Typical PJ afternoon
                "humidity": 78.0
            }
            
            self._cache = {"timestamp": now, "data": weather_data}
            return weather_data
            
        except Exception as e:
            logger.error(f"MetMalaysia API unreachable. Using fail-safe defaults. Error: {e}")
            return {"outdoor_temp": 30.0, "humidity": 80.0}