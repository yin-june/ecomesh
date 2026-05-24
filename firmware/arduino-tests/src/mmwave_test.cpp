#include <Arduino.h>
#include <ld2410.h>

// On ESP32 DOIT DevKit V1, Serial2 is the standard Hardware Serial port
// Connect: 
// - Radar TX pin -> ESP32 RX2 pin (GPIO 16)
// - Radar RX pin -> ESP32 TX2 pin (GPIO 17)
// - Radar VCC pin -> ESP32 VIN (5V, requires 200mA stable source)
// - Radar GND pin -> ESP32 GND
#define RX_PIN 16
#define TX_PIN 17

#define MONITOR_SERIAL Serial
#define RADAR_SERIAL Serial2

ld2410 radar;

// void setup() {
//   MONITOR_SERIAL.begin(115200);
//   while (!MONITOR_SERIAL);
//   
//   MONITOR_SERIAL.println("\n==================================================");
//   MONITOR_SERIAL.println("EcoMesh Node 1: mmWave Radar HLK-LD2410B Test");
//   MONITOR_SERIAL.println("Radar RX connected to ESP32 TX2 (GPIO 17)");
//   MONITOR_SERIAL.println("Radar TX connected to ESP32 RX2 (GPIO 16)");
//   MONITOR_SERIAL.println("==================================================\n");
// 
//   // Start Serial2 at 256000 baud (HLK-LD2410 default speed)
//   RADAR_SERIAL.begin(256000, SERIAL_8N1, RX_PIN, TX_PIN);
//   
//   MONITOR_SERIAL.print("Initializing LD2410 radar sensor... ");
//   if (radar.begin(RADAR_SERIAL)) {
//     MONITOR_SERIAL.println("SUCCESS 🟢");
//     MONITOR_SERIAL.print("Firmware version: ");
//     MONITOR_SERIAL.print(radar.firmware_major_version);
//     MONITOR_SERIAL.print(".");
//     MONITOR_SERIAL.println(radar.firmware_minor_version);
//   } else {
//     MONITOR_SERIAL.println("FAILED 🔴");
//     MONITOR_SERIAL.println("Please check your wiring (TX/RX swap) and power supply.");
//   }
// }
// 
// void loop() {
//   radar.read(); // Processes incoming data frames from the sensor; must be called constantly
//   
//   if (radar.isConnected()) {
//     // Print detection statistics every 1 second
//     static uint32_t lastPrint = 0;
//     if (millis() - lastPrint > 1000) {
//       lastPrint = millis();
//       
//       MONITOR_SERIAL.println("--- mmWave Radar Scan ---");
//       if (radar.presenceDetected()) {
//         if (radar.movingTargetDetected()) {
//           MONITOR_SERIAL.print("Moving Target       -> DETECTED! ");
//           MONITOR_SERIAL.print("Distance: ");
//           MONITOR_SERIAL.print(radar.movingTargetDistance());
//           MONITOR_SERIAL.print(" cm | Energy: ");
//           MONITOR_SERIAL.println(radar.movingTargetEnergy());
//         }
//         if (radar.stationaryTargetDetected()) {
//           MONITOR_SERIAL.print("Stationary Target   -> DETECTED! ");
//           MONITOR_SERIAL.print("Distance: ");
//           MONITOR_SERIAL.print(radar.stationaryTargetDistance());
//           MONITOR_SERIAL.print(" cm | Energy: ");
//           MONITOR_SERIAL.println(radar.stationaryTargetEnergy());
//         }
//       } else {
//         MONITOR_SERIAL.println("No occupancy detected ⚪");
//       }
//       MONITOR_SERIAL.println("------------------------\n");
//     }
//   }
//   
//   delay(1); // Small delay to yield to the CPU
// }
