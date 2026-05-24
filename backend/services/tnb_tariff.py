class TNBTariffCalculator:
    """
    Applies TNB Commercial Tariff B (Low Voltage) and 
    Residential Tariff A rates for accurate cost tracking.
    """
    COMMERCIAL_RATE_B = 0.435  # RM per kWh
    
    @staticmethod
    def calculate_commercial_cost(kwh_used: float) -> float:
        """Standard flat rate for UM campus / Commercial buildings."""
        return round(kwh_used * TNBTariffCalculator.COMMERCIAL_RATE_B, 2)

    @staticmethod
    def calculate_residential_cost(kwh_used: float) -> float:
        """Tiered residential calculation for home-based users."""
        cost = 0.0
        if kwh_used <= 200:
            cost = kwh_used * 0.218
        elif kwh_used <= 300:
            cost = (200 * 0.218) + ((kwh_used - 200) * 0.334)
        else:
            cost = (200 * 0.218) + (100 * 0.334) + ((kwh_used - 300) * 0.516)
        return round(cost, 2)