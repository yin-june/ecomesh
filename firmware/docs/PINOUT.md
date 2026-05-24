# EcoMesh Pinout Documentation

This document records the GPIO pin assignments for the two **DOIT ESP32 DEVKIT V1** microcontrollers used in the EcoMesh prototype system.

---

## 1. Microcontroller A: EcoMesh Smart Strip (Brain & Muscle)

This microcontroller serves as the central hub and gateway, controlling AC power relays and local IR communication.

### 1.1 Pin Mapping Table

| Component | Pin Label on Module | ESP32 GPIO Pin | Pin Type / Direction | Description |
| :--- | :--- | :--- | :--- | :--- |
| **IR Receiver** | `S` (Signal/Out) | **GPIO 13** | Input | Reads incoming infrared signals from legacy remotes (e.g., Daikin AC). |
| | `VCC` | **3.3V** | Power | Power supply to the IR receiver module. |
| | `GND` | **GND** | Ground | Ground connection. |
| **IR Transmitter** | `DAT` / `S` (Signal/In) | **GPIO 12** | Output | Transmits cloned infrared commands to legacy appliances (e.g., Daikin AC). |
| | `VCC` | **3.3V / 5V** | Power | Power supply to the IR transmitter module. |
| | `GND` | **GND** | Ground | Ground connection. |
| **4-Channel Relay** | `IN1` | **GPIO 25** | Output | Controls Channel 1 (Low-Level Trigger: `LOW` = ON, `HIGH` = OFF). |
| | `IN2` | **GPIO 26** | Output | Controls Channel 2 (Low-Level Trigger: `LOW` = ON, `HIGH` = OFF). |
| | `IN3` | **GPIO 27** | Output | Controls Channel 3 (Low-Level Trigger: `LOW` = ON, `HIGH` = OFF). |
| | `IN4` | **GPIO 33** | Output | Controls Channel 4 (Low-Level Trigger: `LOW` = ON, `HIGH` = OFF). |
| | `VCC` | **5V (VIN)** | Power | Relay control logic power supply (requires 5V to drive relay coils). |
| | `GND` | **GND** | Ground | Common ground. |
| **RF 433MHz Receiver** | `DATA` | **GPIO 14** | Input (via Divider) | Receives 433MHz signals from remotes (requires 5V to 3.3V shift). |
| | `VCC` | **5V (VIN)** | Power | Power supply to the RF receiver (requires 5V for sensitivity). |
| | `GND` | **GND** | Ground | Ground connection. |
| **RF 433MHz Transmitter** | `DATA` | **GPIO 23** | Output | Transmits 433MHz control signals to legacy fans/appliances. |
| | `VCC` | **5V (VIN)** | Power | Power supply to the RF transmitter (5V provides better range). |
| | `GND` | **GND** | Ground | Ground connection. |

### 1.2 Detailed Pin Explanations

#### IR Receiver Module (GPIO 13)
* **Code Reference:** [src/main.cpp](file:///C:/Users/keste/OneDrive/Documents/PlatformIO/Projects/technothon-hub/src/main.cpp#L6) / [src/working_ir_receiver.cpp](file:///C:/Users/keste/OneDrive/Documents/PlatformIO/Projects/technothon-hub/src/working_ir_receiver.cpp#L6)
* **Why GPIO 13?** Standard, safe-to-use digital input pin that does not interfere with ESP32 strapping pins or flash interface pins during boot.

#### IR Transmitter Module (GPIO 12)
* **Code Reference:** [src/ir_sender_test.cpp](file:///C:/Users/keste/OneDrive/Documents/PlatformIO/Projects/technothon-hub/src/ir_sender_test.cpp#L6)
* **Strapping Pin Warning:** GPIO 12 (MTDI) is an ESP32 strapping pin that determines the flash voltage (VDD_SDIO) during boot. Ensure that any external pull-up/pull-down components in the transmitter circuit do not pull this pin high at boot if the flash chip expects 3.3V (standard for most DOIT ESP32 boards), as it could cause boot failure.

#### 4-Channel Relay Module (GPIO 25, 26, 27, 33)
* **Code Reference:** [src/relay_test.cpp](file:///C:/Users/keste/OneDrive/Documents/PlatformIO/Projects/technothon-hub/src/relay_test.cpp#L5)
* **Trigger Type:** **Low-Level Trigger**.
  * Writing `LOW` (0V) turns the relay **ON** (closes the circuit).
  * Writing `HIGH` (3.3V) turns the relay **OFF** (opens the circuit).
* **Why these pins?**
  * General-purpose GPIOs with no bootloader strapping requirements.
  * Avoids SPI flash communication pins (GPIO 6-11) and strapping pins (GPIO 0, 2, 15).

#### RF Receiver Module (GPIO 14)
* **Purpose:** Listens to incoming 433MHz RF data from wireless appliances or remote controls.
* **Electrical Safety Warning:** The XY-MK-5V receiver requires 5V power to work properly, meaning its DATA pin output is a 5V signal. To prevent damage to the ESP32 (which is only 3.3V tolerant), you **must use a voltage divider** (e.g., 1kΩ resistor inline, and a 2kΩ resistor to GND) or a logic level shifter to step the signal down to 3.3V before connecting it to GPIO 14.

#### RF Transmitter Module (GPIO 23)
* **Purpose:** Transmits cloned 433MHz commands to legacy appliances (like ceiling fans).
* **Power Connection:** Connect VCC to the 5V (VIN) rail for maximum RF range. The ESP32's 3.3V signal output on GPIO 23 is sufficient to drive the transmitter data input even at 5V.

---

## 2. Microcontroller B: EcoMesh Sensor Node (The Nerves)

This microcontroller is a separate, dedicated physical ESP32 DevKit V1 board tasked with presence monitoring in a zone using the 24GHz FMCW mmWave Radar sensor.

### 2.1 Recommended Pin Mapping Table

| Component | Pin Label on Module | ESP32 GPIO Pin | Pin Type / Direction | Description |
| :--- | :--- | :--- | :--- | :--- |
| **mmWave Radar** | `TX` | **GPIO 16** | Input (RX2) | Receives target data from the HLK-LD2410B sensor (256000 baud). |
| | `RX` | **GPIO 17** | Output (TX2) | Sends configuration command frames to the sensor module. |
| | `VCC` | **5V (VIN)** | Power | Radar power supply (requires 5V at up to 200mA peak). |
| | `GND` | **GND** | Ground | Ground connection. |
| | `OUT` *(Optional)* | **GPIO 4** | Input | Simple digital occupancy state indicator (HIGH = active, LOW = idle). |

### 2.2 Detailed Pin Explanations

#### mmWave Radar Module (GPIO 16 / GPIO 17)
* **Code Reference:** [src/mmwave_test.cpp](file:///C:/Users/keste/OneDrive/Documents/PlatformIO/Projects/technothon-hub/src/mmwave_test.cpp#L10-L11)
  ```cpp
  #define RX_PIN 16
  #define TX_PIN 17
  ```
* **Why these pins?** They map to **Hardware Serial2 (RX2/TX2)** on the ESP32. This is the optimal hardware serial port for communicating at the high default baud rate (**256,000 bps**) required by the HLK-LD2410B sensor, avoiding SoftwareSerial CPU bottlenecks.
* **Why VCC to 5V (VIN)?** The HLK-LD2410B is highly sensitive to voltage drops and requires a stable 5V supply (drawing up to 200mA peaks). Powering it from a 3.3V rail will cause brownouts and inaccurate sensor readings.
* **OUT Pin (Optional, GPIO 4):** If you do not want to parse UART data, the sensor outputs a 3.3V High logic level on this pin whenever human presence is detected.

---

## Power Distribution Summary

* **ESP32 DevKit Boards:** Individually powered via Micro-USB (5V).
* **Smart Strip Board:**
  * **IR Receiver / Transmitter:** Connect VCC to the `3V3` pin of the ESP32 (or `5V` if the transmitter module has a built-in transistor driver that supports/requires 5V).
  * **Relay Board VCC:** Must connect to `VIN` (5V from USB) because 3.3V is typically insufficient to energize 5V relay coils.
* **Sensor Node Board:**
  * **mmWave Radar VCC:** Must connect to the `VIN` pin (5V from USB) for stable sensor performance.
