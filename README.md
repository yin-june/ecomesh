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

## 🐳 Step 1: Fully Containerized Dev Setup

The root `docker-compose.yml` now starts PostgreSQL, InfluxDB, and the FastAPI backend together. The backend container uses the service names `postgres` and `influxdb`, so no host networking is needed.

1. Start everything:

```bash
docker compose up --build
```

2. Open the backend API:

```text
http://localhost:8000
```

3. Open InfluxDB:

```text
http://localhost:8086
```

## 🧠 Backend Container

The backend image is built from [backend/Dockerfile](backend/Dockerfile) and runs Uvicorn with auto-reload for development. The container mounts `./backend:/app`, so code changes are picked up without rebuilding the image.

If you want to run the backend outside Docker, copy `backend/.env.example` and change `POSTGRES_SERVER` to `localhost` and `INFLUX_URL` to `http://localhost:8086`.

## 🗄️ Database Setup Guide

### PostgreSQL

The database is initialized from the Compose environment:

```yaml
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgrespassword
POSTGRES_DB=ecomesh_db
```

The backend connects with:

```yaml
POSTGRES_SERVER=postgres
```

Use these connection details in psql or a GUI client:

```text
Host: localhost
Port: 5432
Database: ecomesh_db
User: postgres
Password: postgrespassword
```

### InfluxDB

InfluxDB is initialized with:

```yaml
DOCKER_INFLUXDB_INIT_USERNAME=admin
DOCKER_INFLUXDB_INIT_PASSWORD=adminpassword
DOCKER_INFLUXDB_INIT_ORG=um_technothon
DOCKER_INFLUXDB_INIT_BUCKET=sensor_metrics
DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=ecomesh-secure-token
```

The backend connects with:

```yaml
INFLUX_URL=http://influxdb:8086
```

For the Influx UI or CLI, use:

```text
URL: http://localhost:8086
Org: um_technothon
Bucket: sensor_metrics
Token: ecomesh-secure-token
```

### First Run Checklist

1. Run `docker compose up --build`.
2. Wait for PostgreSQL to finish initialization.
3. Open InfluxDB once, complete any first-time setup if needed, and confirm the bucket exists.
4. Seed or ingest telemetry before training, because the ML pipeline expects `zone_telemetry` rows with `energy_draw_kwh`, `occupancy_count`, and `outdoor_temp`.
5. Train the model with:

```bash
docker compose exec backend python -m ml_engine.pipelines.train_pipelines
```

If you do not have live telemetry yet, generate sample dev data first:

```bash
docker compose exec backend python -m ml_engine.pipelines.seed_sample_telemetry
```

## Local Non-Docker Mode

If you prefer running the backend directly on Windows:

```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python -m ml_engine.pipelines.train_pipelines
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

