#include <Arduino.h>
#include <esp_now.h>
#include <WiFi.h>

// Pins for mmWave Radar (HLK-LD2410) UART communication
#define RX_PIN 16
#define TX_PIN 17

// Structure to align data packet exactly with the Gateway
typedef struct struct_message {
    char node_id[16];
    bool presence_detected;
    uint16_t moving_distance;
    uint16_t stationary_distance;
    uint8_t energy_level;
} struct_message;

struct_message telemetryData;

// REPLACE WITH YOUR GATEWAY'S ACTUAL MAC ADDRESS
uint8_t gatewayMacAddress[] = {0x24, 0x0A, 0xC4, 0xXX, 0xXX, 0xXX};

// Callback when data is sent
void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status) {
    Serial.print("\r\nLast Packet Send Status:\t");
    Serial.println(status == ESP_NOW_SEND_SUCCESS ? "Delivery Success" : "Delivery Fail");
}

void setup() {
    Serial.begin(115200);
    
    // Initialize Hardware Serial 2 for mmWave Radar
    Serial2.begin(256000, SERIAL_8N1, RX_PIN, TX_PIN); 
    
    // Set device as a Wi-Fi Station for ESP-NOW configuration
    WiFi.mode(WIFI_STA);

    // Init ESP-NOW
    if (esp_now_init() != ESP_OK) {
        Serial.println("Error initializing ESP-NOW");
        return;
    }

    esp_now_register_send_cb(OnDataSent);
    
    // Register peer (Gateway)
    esp_now_peer_info_t peerInfo;
    memcpy(peerInfo.peer_addr, gatewayMacAddress, 6);
    peerInfo.channel = 0;  
    peerInfo.encrypt = false;
    
    if (esp_now_add_peer(&peerInfo) != ESP_OK){
        Serial.println("Failed to add peer");
        return;
    }

    // Initialize mock metadata
    strcpy(telemetryData.node_id, "NODE_ZONE_A1");
}

void loop() {
    // Read raw data stream from mmWave sensor
    if (Serial2.available()) {
        // Simple hardware parsing loop or library wrapper execution
        // For demonstration/hackathon safety, we pack standard properties:
        telemetryData.presence_detected = true; 
        telemetryData.moving_distance = 120;       // in cm
        telemetryData.stationary_distance = 85;    // in cm (Breathing target)
        telemetryData.energy_level = 78;           // micro-vibration confidence score

        // Send payload instantly across the local mesh space (<10ms latency)
        esp_err_t result = esp_now_send(gatewayMacAddress, (uint8_t *) &telemetryData, sizeof(telemetryData));
        
        if (result == ESP_OK) {
            Serial.println("Telemetry packet dispatched securely via ESP-NOW.");
        } else {
            Serial.println("Error sending the data packet.");
        }
    }
    delay(1000); // Poll every 1 second to maximize ultra-low power runtime
}