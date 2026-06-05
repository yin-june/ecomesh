# EcoMesh Backend — Input / Output Reference

**Base URL (local):** `http://0.0.0.0:8000`  
**API prefix:** `/api/v1`  
**OpenAPI UI:** `/docs`  
**Global response header:** `X-Process-Time-ms: <float>` on every response (added by `ProcessTimeMiddleware`)

---

## Table of Contents

1. [Health Check](#1-health-check)
2. [Authentication](#2-authentication)
   - [POST /register](#post-apiv1authregister)
   - [POST /login](#post-apiv1authlogin)
   - [GET /me](#get-apiv1authme)
3. [Zones](#3-zones)
   - [GET /zones/](#get-apiv1zones)
   - [GET /zones/{zone_id}/telemetry](#get-apiv1zoneszone_idtelemetry)
   - [POST /zones/{zone_id}/claim](#post-apiv1zoneszone_idclaim)
   - [GET /zones/{zone_id}/desks](#get-apiv1zoneszone_iddesks)
   - [POST /zones/{zone_id}/desks](#post-apiv1zoneszone_iddesks)
   - [PUT /zones/{zone_id}/desks/{desk_id}/claim](#put-apiv1zoneszone_iddesksdesk_idclaim)
   - [POST /zones/{zone_id}/desks/{desk_id}/power](#post-apiv1zoneszone_iddesksdesk_idpower)
4. [Analytics](#4-analytics)
   - [GET /analytics/predict-demand](#get-apiv1analyticspredict-demand)
   - [GET /analytics/my-impact](#get-apiv1analyticsmy-impact)
   - [GET /analytics/energy-history/{zone_id}](#get-apiv1analyticsenergy-historyzone_id)
5. [Control](#5-control)
   - [POST /control/{zone_id}/relay/{socket_id}](#post-apiv1controlzone_idrelaysocket_id)
   - [POST /control/{zone_id}/hvac](#post-apiv1controlzone_idhvac)
   - [POST /control/emergency-shutdown](#post-apiv1controlemergency-shutdown)
6. [Notifications](#6-notifications)
   - [GET /notifications/](#get-apiv1notifications)
   - [GET /notifications/unread-count](#get-apiv1notificationsunread-count)
   - [POST /notifications/{notification_id}/read](#post-apiv1notificationsnotification_idread)
   - [POST /notifications/read-all](#post-apiv1notificationsread-all)
   - [POST /notifications/{notification_id}/delete](#post-apiv1notificationsnotification_iddelete)
7. [Background Processes](#7-background-processes)
   - [MQTT Listener Loop](#mqtt-listener-loop)
   - [ML Training Pipeline](#ml-training-pipeline)
   - [Telemetry Seed Script](#telemetry-seed-script)
   - [Database Seed Script](#database-seed-script)
8. [External Service Integrations](#8-external-service-integrations)
9. [Database Models](#9-database-models)
10. [Known Gaps & Implementation Notes](#10-known-gaps--implementation-notes)

---

## 1. Health Check

### `GET /`

No authentication required.

**Input:** None

**Output `200`:**
```json
{
  "status": "online",
  "project": "EcoMesh Backend API",
  "message": "EcoMesh Backend is ready for Technothon 2026!"
}
```

---

## 2. Authentication

### `POST /api/v1/auth/register`

Creates a new user account.

**Input — Request Body (JSON):**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `email` | string (EmailStr) | Yes | Unique email address |
| `password` | string | Yes | Plain-text password (hashed server-side via pbkdf2_sha256) |
| `full_name` | string | Yes | Display name |

```json
{
  "email": "alice@example.com",
  "password": "s3cr3t",
  "full_name": "Alice Tan"
}
```

**Output `201`:**
```json
{
  "id": 1,
  "email": "alice@example.com",
  "full_name": "Alice Tan",
  "esg_points": 0,
  "is_active": true
}
```

**Output `400`:**
```json
{ "detail": "Email already registered in the system." }
```

---

### `POST /api/v1/auth/login`

Returns a JWT access token using OAuth2 Password flow.

**Input — Request Body (`application/x-www-form-urlencoded`):**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `username` | string | Yes | User's **email address** (OAuth2 convention) |
| `password` | string | Yes | Plain-text password |

**Output `200`:**
```json
{
  "access_token": "<jwt_string>",
  "token_type": "bearer"
}
```

JWT payload: `{ "sub": "<user_id>", "exp": <utc_unix_timestamp> }`  
Algorithm: HS256. Default expiry: 7 days.

**Output `400`:**
```json
{ "detail": "Incorrect email or password" }
```

---

### `GET /api/v1/auth/me`

Returns the currently authenticated user's profile.

**Input — Header:**

| Header | Required | Description |
|--------|----------|-------------|
| `Authorization` | Yes | `Bearer <access_token>` |

**Output `200`:**
```json
{
  "id": 1,
  "email": "alice@example.com",
  "full_name": "Alice Tan",
  "esg_points": 120,
  "is_active": true
}
```

**Output `401`:**
```json
{ "detail": "Could not validate credentials" }
```
Response header: `WWW-Authenticate: Bearer`

---

## 3. Zones

### `GET /api/v1/zones/`

Returns all active zones from the database. No authentication required.

**Input:** None

**Output `200`:**
```json
[
  {
    "id": "zone-a",
    "name": "Zone A",
    "floor_level": 1,
    "base_ac_target": 24.0
  }
]
```

---

### `GET /api/v1/zones/{zone_id}/telemetry`

Returns real-time telemetry for a zone. Data sourced from InfluxDB (`sensor_metrics` bucket, `zone_telemetry` measurement, last 1 hour). Falls back to safe defaults if InfluxDB is unavailable.

**Input — Path Parameter:**

| Param | Type | Description |
|-------|------|-------------|
| `zone_id` | string | e.g. `"zone-a"` |

**Output `200`:**
```json
{
  "zone_id": "zone-a",
  "occupancy_count": 8,
  "temperature": 28.4,
  "target_temp": 24.0,
  "energy_draw_kwh": 1.2,
  "status": "active"
}
```

| Field | Source | Fallback |
|-------|--------|---------|
| `occupancy_count` | InfluxDB field `occupancy_count` | `0` |
| `temperature` | InfluxDB field `outdoor_temp` | `zone.base_ac_target` |
| `target_temp` | `zone.base_ac_target` from Postgres | — |
| `energy_draw_kwh` | InfluxDB field `energy_draw_kwh` | `0.0` |
| `status` | `"active"` if `occupancy_count > 0` else `"idle"` | `"idle"` |

**Output `404`:**
```json
{ "detail": "Zone not found" }
```

---

### `POST /api/v1/zones/{zone_id}/claim`

Applies a comfort profile to a zone and optionally sends an MQTT AC command.

**Input — Path Parameter:**

| Param | Type | Description |
|-------|------|-------------|
| `zone_id` | string | Target zone |

**Input — Query Parameter:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `profile_name` | string | Yes | e.g. `"Deep Work"`, `"Collaborative"` |

**Side Effect:** If `profile_name == "Deep Work"`, publishes MQTT command:
- Topic: `ecomesh/zones/{zone_id}/command`
- Payload: `{ "device": "AC", "temp": 23, "mode": "COOL" }`

**Output `200`:**
```json
{ "status": "success", "message": "Zone zone-a configured for Deep Work" }
```

**Output `404`:**
```json
{ "detail": "Zone not found" }
```

---

### `GET /api/v1/zones/{zone_id}/desks`

Returns all desks in a zone.

**Input — Path Parameter:**

| Param | Type | Description |
|-------|------|-------------|
| `zone_id` | string | Target zone |

**Output `200`:**
```json
[
  {
    "id": "desk-a1",
    "zone_id": "zone-a",
    "label": "Desk A1",
    "x_pos": 1.5,
    "y_pos": 2.0,
    "is_claimed": true,
    "claimed_by": 1,
    "is_powered": true
  }
]
```

**Output `404`:** Zone not found

---

### `POST /api/v1/zones/{zone_id}/desks`

Creates a new desk in a zone.

**Input — Path Parameter:** `zone_id`

**Input — Request Body (JSON):**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique desk identifier |
| `label` | string | Yes | Display label (e.g. `"Desk A1"`) |
| `x_pos` | float | Yes | X coordinate on floor map |
| `y_pos` | float | Yes | Y coordinate on floor map |

**Output `201`:** `DeskResponse` (see schema above)

**Output `404`:** Zone not found

---

### `PUT /api/v1/zones/{zone_id}/desks/{desk_id}/claim`

Claims or releases a desk. If claimed and user has an `EnergyProfile`, sends an MQTT AC override to the user's preferred temperature.

**Input — Path Parameters:** `zone_id`, `desk_id`

**Input — Request Body (JSON):**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `is_claimed` | boolean | Yes | `true` to claim, `false` to release |
| `claimed_by` | integer | No | User ID of the claimant |

**Side Effect (on claim):** If `claimed_by` is set and the user has an `EnergyProfile`, publishes MQTT:
- Topic: `ecomesh/zones/{zone_id}/command`
- Payload: `{ "device": "AC", "temp": <preferred_temp>, "mode": "COOL" }`

**Output `200`:** Updated `DeskResponse`

**Output `404`:** Desk not found

---

### `POST /api/v1/zones/{zone_id}/desks/{desk_id}/power`

Toggles the power state of a desk relay.

**Input — Path Parameters:** `zone_id`, `desk_id`

**Input — Request Body (JSON):**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `is_powered` | boolean | Yes | `true` to power on, `false` to power off |

**Side Effect:** Attempts to publish MQTT relay command:
- Topic: `ecomesh/zones/{zone_id}/command`
- Payload: `{ "device": "RELAY", "desk_id": "<desk_id>", "state": true|false }`

> **Note:** `mqtt_bridge.publish()` does not exist on the current `IoTGatewayBridge` implementation — this will raise a runtime `AttributeError`. See [Known Gaps](#10-known-gaps--implementation-notes).

**Output `200`:** Updated `DeskResponse`

**Output `404`:** Desk not found

---

## 4. Analytics

### `GET /api/v1/analytics/predict-demand`

Runs the ML HVAC demand-forecast model against current conditions fetched from OpenWeather. No authentication required.

**Input — Query Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `zone_id` | string | No | Accepted but **not used** by the handler |
| `current_occupancy` | integer | Yes | Current number of occupants |

**Processing pipeline:**
1. `WeatherAPIClient.get_current_weather()` → `outdoor_temp`
2. `HVACPredictor.execute_drift_strategy(occupancy, outdoor_temp)` → uses `ml_engine/models/demand_forecast.pkl`
3. Strategy thresholds (predicted kWh):
   - `< 0.5` → `SHUTDOWN` (null temp)
   - `0.5–1.0` → `AGGRESSIVE_DRIFT` (26°C)
   - `1.0–2.0` → `STANDARD_ECO` (24°C)
   - `> 2.0` → `MAX_COOLING` (22°C)

**Output `200` (success):**
```json
{
  "predicted_kwh_load": 1.45,
  "suggested_action": "STANDARD_ECO",
  "target_ac_temp": 24
}
```

**Output `200` (ML unavailable — model file missing or error):**
```json
{ "error": "ML Engine unavailable", "details": "<exception message>" }
```

> The model file `ml_engine/models/demand_forecast.pkl` must be trained before this endpoint works. Run `python -m ml_engine.pipelines.train_pipelines`.

---

### `GET /api/v1/analytics/my-impact`

Calculates ESG savings metrics from a given kWh value. No authentication required.

**Input — Query Parameter:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `kwh_saved_this_week` | float | Yes | Energy savings to compute impact for |

**Processing:**
- `rm_saved` = `kwh_saved_this_week × 0.435` (TNB commercial rate)
- `kg_co2_avoided` = `kwh_saved_this_week × 0.740` (Malaysian grid carbon factor)
- `trees_equivalent` = `kg_co2_avoided / 10.0`

**Output `200`:**
```json
{
  "rm_saved": 0.87,
  "kg_co2_avoided": 1.48,
  "trees_equivalent": 0.15
}
```

---

### `GET /api/v1/analytics/energy-history/{zone_id}`

Returns historical energy readings for a zone from InfluxDB.

**Input — Path Parameter:** `zone_id`

**Input — Query Parameter:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `days` | integer | `7` | Number of past days to retrieve |

**InfluxDB query:** Bucket `sensor_metrics`, measurement `zone_telemetry`, field `energy_draw_kwh`, filtered by `zone_id` tag, aggregated per hour (`mean`).

**Output `200`:**
```json
[
  {
    "timestamp": "2026-05-29T08:00:00+00:00",
    "actual_kwh": 1.2,
    "predicted_kwh": 0.0
  }
]
```

> `predicted_kwh` is always `0.0` (not yet implemented).

**Output `200` (on InfluxDB error):** `[]`

---

## 5. Control

All control endpoints require `Authorization: Bearer <token>`.

### `POST /api/v1/control/{zone_id}/relay/{socket_id}`

Manually toggles a specific relay socket on/off and publishes an MQTT command.

**Input — Path Parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `zone_id` | string | Target zone |
| `socket_id` | integer | Socket number on the relay board |

**Input — Query Parameter:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `state` | string | Yes | `"ON"` or `"OFF"` (case-insensitive) |

**Input — Header:** `Authorization: Bearer <token>`

**MQTT Publish:**
- Topic: `ecomesh/zones/{zone_id}/relay/{socket_id}`
- Payload: `{ "command": "ON"|"OFF", "triggered_by": "<user_email>" }`

**Output `200`:**
```json
{ "status": "success", "message": "Relay 3 turned ON" }
```

**Output `400`:** Invalid state value

**Output `401`:** Invalid or missing token

---

### `POST /api/v1/control/{zone_id}/hvac`

Sends an HVAC mode/temperature override for a zone via MQTT.

**Input — Path Parameter:** `zone_id`

**Input — Query Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `target_temp` | integer | Yes | Desired temperature in °C |
| `mode` | string | Yes | `COOL`, `DRY`, `FAN`, or `OFF` |

**Input — Header:** `Authorization: Bearer <token>`

**MQTT Publish:**
- Topic: `ecomesh/zones/{zone_id}/command`
- Payload: `{ "device": "AC", "temp": 24, "mode": "COOL" }`

**Output `200`:**
```json
{ "status": "success", "message": "HVAC in zone-a set to 24C (COOL)" }
```

**Output `400`:** Invalid mode

**Output `401`:** Auth failure

---

### `POST /api/v1/control/emergency-shutdown`

Triggers a floor-wide dead man's switch — shuts down all relays and turns off HVAC for every zone on the specified floor.

**Input — Query Parameter:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `floor_level` | integer | Yes | Floor number to shut down |

**Input — Header:** `Authorization: Bearer <token>`

**Side Effects per zone on floor:**
1. MQTT relay off:
   - Topic: `ecomesh/zones/{zone.id}/relay/all`
   - Payload: `{ "command": "OFF" }`
2. MQTT AC off:
   - Topic: `ecomesh/zones/{zone.id}/command`
   - Payload: `{ "device": "AC", "temp": 24, "mode": "OFF" }`

**Output `200`:**
```json
{
  "status": "success",
  "message": "Floor 2 shutdown complete. 3 active zones disabled."
}
```

**Output `404`:**
```json
{ "detail": "No zones found on floor 2" }
```

**Output `401`:** Auth failure

---

## 6. Notifications

All notification endpoints require `Authorization: Bearer <token>`.

> **Note:** All notification data is currently hardcoded mock data. There is no `notifications` database table. The `unread_only` filter and per-notification read/delete operations do not persist.

### `GET /api/v1/notifications/`

**Input — Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `limit` | integer | 20 | Max notifications to return (parsed but may not enforce) |
| `unread_only` | boolean | false | **Ignored** — all mock notifications are always returned |

**Input — Header:** Bearer JWT

**Output `200`:**
```json
[
  {
    "id": "n1",
    "title": "Welcome back!",
    "body": "EcoMesh is optimizing Zone B for your arrival.",
    "type": "arrival",
    "timestamp": "2026-06-05T10:00:00",
    "is_read": false
  },
  {
    "id": "n2",
    "title": "Energy Saving Alert",
    "body": "You saved 2.4 kWh today.",
    "type": "saving",
    "timestamp": "2026-06-05T09:00:00",
    "is_read": false
  }
]
```

Notification `type` values: `"arrival"`, `"saving"`, `"warning"`, `"summary"`

---

### `GET /api/v1/notifications/unread-count`

**Input — Header:** Bearer JWT

**Output `200`:**
```json
{ "count": 2 }
```
> Hardcoded value.

---

### `POST /api/v1/notifications/{notification_id}/read`

**Input — Path Parameter:** `notification_id` (string)

**Input — Header:** Bearer JWT

**Output `200`:**
```json
{ "status": "success", "message": "Notification n1 marked as read" }
```
> Does not persist — mock only.

---

### `POST /api/v1/notifications/read-all`

**Input — Header:** Bearer JWT

**Output `200`:**
```json
{ "status": "success", "message": "All notifications marked as read" }
```

---

### `POST /api/v1/notifications/{notification_id}/delete`

**Input — Path Parameter:** `notification_id` (string)

**Input — Header:** Bearer JWT

**Output `200`:**
```json
{ "status": "success", "message": "Notification n1 deleted" }
```

---

## 7. Background Processes

### MQTT Listener Loop

**Trigger:** App startup via FastAPI `lifespan` context manager in `main.py`  
**Runs as:** Background thread (`paho-mqtt` `loop_start()`)  
**Broker:** `broker.hivemq.com:1883`  
**Client ID:** `EcoMesh_Backend_Main`

**Input (inbound MQTT messages):**

| Topic | Payload Type | Payload Fields |
|-------|-------------|----------------|
| `ecomesh/zones/+/telemetry` (occupancy) | JSON | `type: "occupancy"`, `node`, `presence`, `distance` |
| `ecomesh/zones/+/telemetry` (power) | JSON | `type: "power"`, `voltage`, `current`, `power`, `energy` |

**Output (InfluxDB writes):**

| Measurement | Tags | Fields |
|-------------|------|--------|
| `occupancy` | `zone_id`, `node_id` | `presence`, `distance` |
| `power` | `zone_id` | `voltage`, `current`, `power`, `energy` |

Bucket: `sensor_metrics`

---

### ML Training Pipeline

**Trigger:** Manual — `python -m ml_engine.pipelines.train_pipelines`

**Input:**
- InfluxDB: `sensor_metrics` bucket, `zone_telemetry` measurement, last 30 days
- Features: `occupancy_count`, `outdoor_temp`, `hour`, `day_of_week`, `is_weekend`
- Target: `energy_draw_kwh`

**Output:**
- `ml_engine/models/demand_forecast.pkl` — serialised `RandomForestRegressor`
- Console: training metrics (MAE, R²)

---

### Telemetry Seed Script

**Trigger:** Manual — `python -m ml_engine.pipelines.seed_sample_telemetry`

**Input:** None (generates synthetic data)

**Output:**
- 72 hours of synthetic `zone_telemetry` records written to InfluxDB for `zone-a`
- Fields: `occupancy_count`, `outdoor_temp`, `energy_draw_kwh`

---

### Database Seed Script

**Trigger:** Manual — `python seed_test_user.py`

**Input:** None

**Output (Postgres):**
- Creates all tables via `Base.metadata.create_all()`
- Inserts user: `test@example.com` / `password123`
- Inserts zones: `zone-a`, `zone-b`, `zone-c` on floor 1

---

## 8. External Service Integrations

### MQTT Broker (HiveMQ Public)

| Direction | Topic Pattern | Payload |
|-----------|--------------|---------|
| Subscribe | `ecomesh/zones/+/telemetry` | Sensor readings (occupancy / power) |
| Publish | `ecomesh/zones/{zone_id}/command` | AC override: `{ "device": "AC", "temp": N, "mode": "..." }` |
| Publish | `ecomesh/zones/{zone_id}/relay/{socket_id}` | Relay toggle: `{ "command": "ON"/"OFF", "triggered_by": "..." }` |
| Publish | `ecomesh/zones/{zone_id}/relay/all` | Bulk relay off: `{ "command": "OFF" }` |

### InfluxDB (Time-Series)

| Operation | Measurement | Tags | Fields |
|-----------|-------------|------|--------|
| Write (MQTT) | `occupancy` | `zone_id`, `node_id` | `presence`, `distance` |
| Write (MQTT) | `power` | `zone_id` | `voltage`, `current`, `power`, `energy` |
| Write (seed) | `zone_telemetry` | `zone_id` | `occupancy_count`, `outdoor_temp`, `energy_draw_kwh` |
| Read (telemetry API) | `zone_telemetry` | `zone_id` | `occupancy_count`, `outdoor_temp`, `energy_draw_kwh` |
| Read (history API) | `zone_telemetry` | `zone_id` | `energy_draw_kwh` |
| Read (ML training) | `zone_telemetry` | `zone_id` | all fields |

Config env vars: `INFLUX_URL`, `INFLUX_TOKEN`, `INFLUX_ORG`, `INFLUX_BUCKET`

### OpenWeather API

| Field | Value |
|-------|-------|
| Endpoint | `https://api.openweathermap.org/data/4.0/onecall` |
| Params | `lat=3.1224` (Petaling Jaya), `lon=101.6561`, `units=metric`, `exclude=minutely,hourly,daily,alerts` |
| Cache | In-memory, 15-minute TTL |
| Fallback (no key) | `outdoor_temp=32.5`, `humidity=78` |
| Fallback (error) | `outdoor_temp=30.0`, `humidity=80` |

Config env vars: `OPENWEATHER_API_KEY`, `LOCATION_LAT`, `LOCATION_LON`

### PostgreSQL (Relational)

Connection built from `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_DB`.  
Pool: size 10, max overflow 20, `pool_pre_ping=True`.

### TNB Tariff (Local Calculation)

| Rate Type | Rate |
|-----------|------|
| Commercial (flat) | 0.435 RM/kWh |
| Residential tier 1 (≤ 200 kWh) | 0.218 RM/kWh |
| Residential tier 2 (201–300 kWh) | 0.334 RM/kWh |
| Residential tier 3 (> 300 kWh) | 0.516 RM/kWh |

---

## 9. Database Models

### `users`
| Column | Type | Constraints |
|--------|------|-------------|
| `id` | Integer | PK, auto-increment |
| `email` | String | Unique, indexed, not null |
| `hashed_password` | String | Not null |
| `full_name` | String | Indexed |
| `esg_points` | Integer | Default `0` |
| `is_active` | Boolean | Default `True` |

### `zones`
| Column | Type | Constraints |
|--------|------|-------------|
| `id` | String | PK (e.g. `"zone-a"`) |
| `name` | String | Not null |
| `floor_level` | Integer | Not null |
| `base_ac_target` | Float | Default `24.0` |

### `desks`
| Column | Type | Constraints |
|--------|------|-------------|
| `id` | String | PK |
| `zone_id` | String | FK → `zones.id` |
| `label` | String | Not null |
| `x_pos` | Float | |
| `y_pos` | Float | |
| `is_claimed` | Boolean | Default `False` |
| `claimed_by` | Integer | FK → `users.id`, nullable |
| `is_powered` | Boolean | Default `True` |

### `devices`
| Column | Type | Constraints |
|--------|------|-------------|
| `mac_address` | String | PK |
| `zone_id` | String | FK → `zones.id` |
| `device_type` | String | `"GATEWAY_HUB"` or `"SENSOR_NODE"` |
| `status` | String | Default `"ONLINE"` |

### `energy_profiles`
| Column | Type | Constraints |
|--------|------|-------------|
| `id` | Integer | PK, auto-increment |
| `owner_id` | Integer | FK → `users.id` |
| `profile_name` | String | e.g. `"Deep Work"` |
| `preferred_temp` | Float | |
| `auto_standby_timeout_mins` | Integer | Default `5` |

> There is no `notifications` table — all notification data is hardcoded mock data.

---

## 10. Known Gaps & Implementation Notes

| # | Location | Issue |
|---|----------|-------|
| 1 | `zones.py` — desk power toggle | `mqtt_bridge.publish()` is called but the method does not exist on `IoTGatewayBridge`; will raise `AttributeError` at runtime. Only `client.publish()` and `override_zone_ac()` are implemented. |
| 2 | `notifications.py` | All data is hardcoded. No database table, no persistence. `unread_only` query param is ignored. |
| 3 | InfluxDB measurements | Live MQTT data is written to `occupancy` and `power` measurements, but the telemetry and energy-history APIs read from `zone_telemetry`. Live sensor data will never appear in the API unless `zone_telemetry` is also populated (e.g. via the seed script). |
| 4 | `ml_engine/nilm_processor.py` | `GhostPowerHunter` is implemented and exported but is not wired to any API route or MQTT handler. |
| 5 | `analytics.py` — `/predict-demand` | `zone_id` query parameter is accepted but never used in the handler. |
| 6 | `control.py` | `BackgroundTasks` is imported but never used. |
| 7 | `analytics.py` — `/energy-history` | `predicted_kwh` is always `0.0` — model inference for historical comparison is not implemented. |
| 8 | Database migrations | No Alembic or migration framework is used. Schema changes require re-running `seed_test_user.py` or manual DDL. |
| 9 | Auth coverage | Zone and analytics endpoints are public (no auth). Only `/control` and `/notifications` enforce JWT. |
| 10 | ML model artifact | `ml_engine/models/demand_forecast.pkl` is not included in the repo. The `/predict-demand` endpoint will fail until `train_pipelines.py` is run manually. |
