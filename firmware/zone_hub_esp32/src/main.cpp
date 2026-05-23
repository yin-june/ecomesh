#include <Arduino.h>
#include <esp_now.h>
#include <WiFi.h>
#include <IRremoteESP8266.h>
#include <IRsend.h>

// Actuator Pin Definitions
#define RELAY_CH1_PIN 18 // Pin hardwired to smart strip Socket 1
#define IR_EMITTER_PIN 19 // Pin driving the 940nm IR transistor circuit

IRsend irsend(IR_EMITTER_PIN);

// Data structure mirroring the sensory nodes
typedef struct struct_message {
    char node_id[16];
    bool presence_detected;
    uint16_t moving_distance;
    uint16_t stationary_distance;
    uint8_t energy_level;
} struct_message;

struct_message incomingTelemetry;

// Raw HEX buffer containing recorded Panasonic/Daikin AC "OFF" sequence 
// Replace with raw timings cloned via learning mode if necessary
const uint16_t acOffRawSignal[99] = {3400, 1750, 450, 450, 450, 1300, 450, 450}; // Truncated example

// Callback when data is received from any sensory node in the mesh
void OnDataRecv(const uint8_t * mac, const uint8_t *incomingData, int len) {
    memcpy(&incomingTelemetry, incomingData, sizeof(incomingTelemetry));
    
    Serial.printf("\n--- Inbound Node Data Frame: %s ---\n", incomingTelemetry.node_id);
    Serial.printf("Presence Flag: %s\n", incomingTelemetry.presence_detected ? "HUMAN_PRESENT" : "VACANT");
    Serial.printf("Target Station Distance: %d cm\n", incomingTelemetry.stationary_distance);
    Serial.printf("Sensor Energy Level: %d\n", incomingTelemetry.energy_level);

    // EDGE INTERPRETATION ENGINE (The "Ghost Power Hunter" Layer)
    if (incomingTelemetry.presence_detected) {
        Serial.println("Action -> Energizing Zone Actuators.");
        digitalWrite(RELAY_CH1_PIN, HIGH); // Turn socket relay ON
    } else {
        Serial.println("Action -> Zone Empty. Activating Vampire Shutdown sequence.");
        digitalWrite(RELAY_CH1_PIN, LOW); // Cut off "Ghost/Standby Power" to Relay
        
        // Shoot IR burst to legacy AC units to force immediate power down
        irsend.sendRaw(acOffRawSignal, 99, 38); // 38kHz Carrier modulation
        Serial.println("Legacy AC Off command deployed via IR.");
    }
}

void setup() {
    Serial.begin(115200);
    
    // Configuration of physical actuation registers
    pinMode(RELAY_CH1_PIN, OUTPUT);
    digitalWrite(RELAY_CH1_PIN, LOW); // Fail-safe default: OFF
    
    irsend.begin(); // Activate PWM/RMT background timer for IR modulation

    // Configure Wi-Fi in Station mode
    WiFi.mode(WIFI_STA);
    Serial.print("Gateway Base MAC Address: ");
    Serial.println(WiFi.macAddress()); // Flash this code first to find your Gateway MAC Address!

    // Initialize ESP-NOW
    if (esp_now_init() != ESP_OK) {
        Serial.println("Fatal Error: Could not initialize local ESP-NOW loop");
        return;
    }
    
    // Register the intake callback handler
    esp_now_register_recv_cb(esp_now_recv_cb_t(OnDataRecv));
}

void loop() {
    // Local processing loop stays clear for async execution of interrupt callbacks.
    // This allows backend WebSocket / MQTT integrations to exist alongside the mesh loop.
    delay(2000);
}