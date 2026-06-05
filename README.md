# EcoMesh: Smart Energy Management System
*A Low-Cost, Universal Gateway for Personalized Energy Environments*

## Abstract / Executive Summary
EcoMesh is a decentralized energy management prototype designed to tackle electricity waste in existing residential and commercial spaces. Moving beyond static schedules, EcoMesh utilizes low-cost Edge-processing, high-fidelity mmWave sensing (HLK-LD2410B), and Universal IR/RF mimicry to create an adaptive energy environment. By detecting micro-vibrations (like human breathing) locally on ESP32 hubs, the system autonomously cuts standby "ghost power" via smart relays and manages legacy HVAC systems without expensive retrofits. Paired with an intuitive Flutter application for real-time ESG impact tracking and dynamic zone control, EcoMesh delivers a highly viable solution to smart energy management.

## Problem Statement
Massive amounts of electricity are wasted daily due to inefficient energy usage practices:
- **Behavioral Neglect**: Lights, air-conditioning, and appliances are frequently left running in empty rooms. Standard motion sensors fail to detect stationary users, creating "environmental friction" that leads users to disable automation.
- **Standby Waste**: "Ghost power" is continuously drawn by idle devices like monitors and chargers.
- **Inflexible Infrastructure**: Centralized HVAC and lighting systems lack the granular intelligence to adapt to micro-occupancy. True smart homes are cost-prohibitive and require extensive wiring modifications, making them impractical for the majority of renters and legacy office spaces.

## Solution Overview & System Architecture
EcoMesh introduces a paradigm shift by reframing buildings from passive structures into dynamic energy ecosystems that autonomously adapt to human presence.

```mermaid
flowchart TD
    %% Styling
    classDef frontend fill:#02569B,stroke:#0175C2,stroke-width:2px,color:white;
    classDef backend fill:#009688,stroke:#00796B,stroke-width:2px,color:white;
    classDef firmware fill:#E65100,stroke:#F57C00,stroke-width:2px,color:white;
    classDef db fill:#455A64,stroke:#37474F,stroke-width:2px,color:white;
    
    subgraph Frontend["📱 Flutter App (UX & Orchestration)"]
        UI[Mobile Dashboard & Profiles]:::frontend
    end

    subgraph Backend["🧠 Backend (FastAPI, AI & Data)"]
        API[FastAPI Server]:::backend
        ML[Predictive ML Engine]:::backend
        Broker[MQTT Broker]:::backend
        PG[(PostgreSQL)]:::db
        TSDB[(InfluxDB)]:::db
        
        API <--> Broker
        API <--> PG
        API <--> TSDB
        ML --> API
    end

    subgraph Firmware["🔌 Firmware & Hardware (ESP32 Edge)"]
        Hub[ESP32 Gateway Hub]:::firmware
        Node[ESP32 Sensory Nodes]:::firmware
        Relay[4-Channel Smart Relay]
        IR[IR/RF Transceiver]
        Sensor[mmWave Radar & PZEM-004T]
        
        Node -- "ESP-NOW Mesh" --> Hub
        Sensor --> Node
        Hub --> Relay
        Hub --> IR
    end

    %% Cross-layer communication
    UI -- "REST API / WebSockets" --> API
    Hub -- "MQTTS Telemetry & Commands" <--> Broker
```

- **Hardware & Perception Layer (The "Nerves")**: Utilizes low-cost HLK-LD2410B mmWave Radar and ESP32-C3 nodes to detect micro-vibrations at the edge, ensuring accurate occupancy detection even when users are completely still (passing the "Breathing Test"). Ground-truth energy monitoring is captured via PZEM-004T.
- **Control & Execution Layer (The "Muscle")**: Universal retrofitting through an integrated IR/RF transceiver that clones legacy remote commands. A 4-Channel Relay physically cuts circuits to idle devices when a room is vacated, killing "ghost power".
- **Data & AI Layer (The "Brain")**: Local edge AI processing guarantees privacy (raw signals never leave the room). Dual deployment models (Cloud or On-Premises) support scalable, predictive demand routing and simulated HVAC predictive analytics.
- **User Experience (The "Experience")**: A minimal Flutter app allows users to create "Energy Personas" (e.g., Deep Worker) and "claim" physical zones, automatically syncing environmental preferences via "Follow-Me" Profiles.

## Key Features & Innovation
- **"Follow-Me" Energy Paradigm**: Hands control back to the user through dynamic profiles that follow them across physical zones, replacing rigid building schedules.
- **Edge-Triggered "Ghost Power Hunter"**: Doesn't just turn off lights; it physically severs power to standby electronics when micro-occupancy drops.
- **Zero-Barrier Retrofitting**: Hyper-affordable sub-RM100 master hubs clone existing IR remote signals, allowing deployment in aging facilities without rewiring.
- **Privacy-First Edge Processing**: Raw sensor data is destroyed locally. Only anonymized binary states are transmitted securely via MQTTS encryption.

## Tech Stack
- **Hardware**: ESP32-S3 (Gateway Hub), ESP32-C3 (Sensory Nodes), HLK-LD2410B mmWave Radar, 4-Channel Relay, PZEM-004T, IR/RF Transceiver
- **Firmware**: C++ (PlatformIO / ESP-IDF)
- **Backend API**: FastAPI (Python), SQLAlchemy
- **Databases**: PostgreSQL (Relational Data), InfluxDB (Time-Series Telemetry)
- **Frontend App**: Flutter (Dart)
- **Machine Learning**: Scikit-Learn / Pandas (HVAC Predictive Modeling)
- **IoT Messaging**: MQTT (over TLS/SSL)

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
  * 1+ ESP32-CH340 (Sensory Nodes)
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

4. Connect your ESP32-CH340 node via USB and click Upload.

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

