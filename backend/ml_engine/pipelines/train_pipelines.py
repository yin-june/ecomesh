import os
import joblib
import logging
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error
from ml_engine.dataset_loader import InfluxDataLoader

logger = logging.getLogger(__name__)
MODEL_DIR = os.path.join(os.path.dirname(__file__), "../models")

def train_demand_model():
    """
    Trains the 'Friday Afternoon Drift' predictive model.
    """
    logger.info("Initializing ML Training Pipeline...")
    
    loader = InfluxDataLoader()
    df = loader.fetch_training_data(days_back=90)
    
    if df.empty:
        logger.error("No data available. Aborting training.")
        return

    # Feature Engineering (Adding context for the AI)
    df['hour'] = df.index.hour
    df['day_of_week'] = df.index.dayofweek
    df['is_weekend'] = df['day_of_week'].isin([5, 6]).astype(int)

    # Features (X) and Target (y - Ideal Cooling Load required)
    features = ['occupancy_count', 'outdoor_temp', 'hour', 'day_of_week', 'is_weekend']
    X = df[features]
    y = df['energy_draw_kwh'] # Historical baseline to optimize against

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # Random Forest is highly resilient to non-linear occupancy spikes
    model = RandomForestRegressor(n_estimators=100, max_depth=10, random_state=42)
    model.fit(X_train, y_train)

    predictions = model.predict(X_test)
    mse = mean_squared_error(y_test, predictions)
    logger.info(f"Model trained successfully. MSE: {mse:.4f}")

    # Ensure model directory exists and save binary
    os.makedirs(MODEL_DIR, exist_ok=True)
    model_path = os.path.join(MODEL_DIR, "demand_forecast.pkl")
    joblib.dump(model, model_path)
    logger.info(f"Model binary saved to {model_path}")

if __name__ == "__main__":
    train_demand_model()