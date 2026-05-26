# EcoMesh: Smart Energy Management System

EcoMesh is an intelligent, decentralized energy management framework combining Edge-AI, a hybrid-wireless ESP-NOW mesh, and a FastAPI backend to eliminate "Ghost Power" waste in commercial and academic buildings.

---

## 🛠️ Prerequisites

Before you begin, ensure you have the following installed on your development machine:

* **Software:**
  * [Python 3.10+](https://www.python.org/)
  * [Flutter SDK (3.19+)](https://docs.flutter.dev/get-started/install)
  * [VS Code](https://code.visualstudio.com/) with the **PlatformIO** extension installed.
  * [Docker Desktop](https://www.docker.com/products/docker-desktop/) (for running databases easily).
* **Hardware:**
  * 1x ESP32-DevKitV1 (Gateway Hub)
  * 1+ ESP32-CP2102 (Sensory Nodes)
  * HLK-LD2410 mmWave Radar Sensor
  * 4-Channel 5V Relay Module
  * 940nm IR Emitter + 2N2222 Transistor

---

## 🐳 Step 1: Infrastructure (Databases & Broker)

To keep the local setup clean, we use Docker to spin up PostgreSQL and InfluxDB.

1. Create a `docker-compose.yml` file in the root of your workspace:

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgrespassword
      POSTGRES_DB: ecomesh_db
    ports:
      - "5432:5432"

  influxdb:
    image: influxdb:2.7
    ports:
      - "8086:8086"
    environment:
      DOCKER_INFLUXDB_INIT_MODE: setup
      DOCKER_INFLUXDB_INIT_USERNAME: admin
      DOCKER_INFLUXDB_INIT_PASSWORD: adminpassword
      DOCKER_INFLUXDB_INIT_ORG: um_technothon
      DOCKER_INFLUXDB_INIT_BUCKET: sensor_metrics
      DOCKER_INFLUXDB_INIT_ADMIN_TOKEN: ecomesh-secure-token

```

2. Run the infrastructure:

``` bash 
docker-compose up -d
```

## 🧠 Step 2: Backend API (FastAPI)

1. Navigate to the backend directory:

``` bash
cd apps/ecomesh_backend
``` 

2. Create and activate a Python virtual environment:

``` bash
# Windows
python -m venv venv
venv\Scripts\activate

# Mac/Linux
python3 -m venv venv
source venv/bin/activate
``` 

3. Install dependencies:

``` bash
pip install -r requirements.txt
``` 

4. Create a .env file in apps/ecomesh_backend:

``` Code snippet
SECRET_KEY="super-secret-ecomesh-hackathon-key-2026"
POSTGRES_USER="postgres"
POSTGRES_PASSWORD="postgrespassword"
POSTGRES_SERVER="localhost"
POSTGRES_DB="ecomesh_db"
INFLUX_URL="http://localhost:8086"
INFLUX_TOKEN="ecomesh-secure-token"
INFLUX_ORG="um_technothon"
INFLUX_BUCKET="sensor_metrics"
``` 

5. Train the AI Model (Required before starting the API):

``` bash
python -m ml_engine.pipelines.train_pipeline
```

6. Start the FastAPI Server:

``` bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
``` 

## ⚡ Step 3: Hardware Firmware (PlatformIO)
**Part A: The Gateway Hub**

1. Open the firmware/eco_zone_hub_esp32 folder in VS Code.

2. Connect your ESP32-DevKitV1 via USB.

3. Click the PlatformIO Upload button (the right arrow → on the bottom taskbar).

4. Open the Serial Monitor (the plug icon 🔌). Note the Gateway Base MAC Address printed in the console.

**Part B: The Sensory Node**

1. Open the firmware/eco_sensor_node_esp32 folder in VS Code.

2. Open src/main.cpp.

3. Locate the gatewayMacAddress array and update it with the MAC address you copied in Part A:

``` C++
uint8_t gatewayMacAddress[] = {0x24, 0x0A, 0xC4, 0xXX, 0xXX, 0xXX}; // Update this!
```

4. Connect your ESP32-CP2102 node via USB and click Upload.

## 📱 Step 4: Frontend App (Flutter)
1. Navigate to the Flutter app directory:

``` bash
cd apps/ecomesh_flutter
``` 

2. Fetch Flutter dependencies:

``` bash
flutter pub get
``` 

3. Update the API Endpoint:
Open lib/core/constants/api_constants.dart (or wherever you store base URLs) and ensure it points to your local machine's IP address (e.g., http://192.168.X.X:8000/api/v1).
(Note: Do not use localhost if testing on a physical Android/iOS device).

4. Run the app:

``` bash
flutter run
``` 

