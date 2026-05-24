import numpy as np
import logging

logger = logging.getLogger(__name__)

class GhostPowerHunter:
    """
    Non-Intrusive Load Monitoring (NILM).
    Detects if a 'claimed' smart plug is wasting standby power.
    """
    def __init__(self, variance_threshold: float = 2.0, vampire_limit_watts: float = 15.0):
        self.variance_threshold = variance_threshold
        self.vampire_limit = vampire_limit_watts

    def analyze_signature(self, power_window: list[float], is_zone_occupied: bool) -> bool:
        """
        Pass a rolling window (e.g., last 60 seconds) of wattage readings.
        Returns TRUE if Ghost Power is detected and the relay should be killed.
        """
        if not power_window or len(power_window) < 10:
            return False # Not enough data to make a decision

        mean_power = np.mean(power_window)
        power_variance = np.var(power_window)
        
        # Condition 1: Is power being drawn, but it's very low? (Standby range)
        is_low_draw = 0 < mean_power <= self.vampire_limit
        
        # Condition 2: Is the power draw completely flat? (Not actively computing/charging)
        is_flatline = power_variance < self.variance_threshold

        # Condition 3: Is the human actually gone?
        is_abandoned = not is_zone_occupied

        if is_low_draw and is_flatline and is_abandoned:
            logger.warning(f"GHOST POWER DETECTED: {mean_power:.2f}W flatline. Triggering cutoff.")
            return True
            
        return False