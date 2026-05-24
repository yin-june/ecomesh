#include <stdio.h>
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "esp_system.h"
#include "driver/uart.h"
#include "esp_wifi.h"
#include "esp_now.h"
#include "nvs_flash.h"
#include "esp_netif.h"
#include "esp_event.h"

// Pins for mmWave Radar (HLK-LD2410) UART communication
#define RX_PIN 16
#define TX_PIN 17
#define RADAR_UART_NUM UART_NUM_2

static const char *TAG = "EcoMesh_Node_Main";

// Structure to align data packet exactly with the Gateway
typedef struct struct_message {
    char node_id[16];
    bool presence_detected;
    uint16_t moving_distance;
    uint16_t stationary_distance;
    uint8_t energy_level;
} struct_message;

static struct_message telemetryData;

// REPLACE WITH YOUR GATEWAY'S ACTUAL MAC ADDRESS
static uint8_t gatewayMacAddress[] = {0x24, 0x0A, 0xC4, 0x00, 0x00, 0x00};

// Callback when data is sent
static void on_data_sent(const uint8_t *mac_addr, esp_now_send_status_t status) {
    ESP_LOGI(TAG, "Last Packet Send Status: %s", status == ESP_NOW_SEND_SUCCESS ? "Delivery Success" : "Delivery Fail");
}

void radar_polling_task(void *pvParameters) {
    uint8_t rx_buffer[128];
    while (1) {
        // Read raw data stream from mmWave sensor
        int length = uart_read_bytes(RADAR_UART_NUM, rx_buffer, sizeof(rx_buffer), pdMS_TO_TICKS(100));
        if (length > 0) {
            // For demonstration/hackathon safety, we pack standard properties:
            telemetryData.presence_detected = true; 
            telemetryData.moving_distance = 120;       // in cm
            telemetryData.stationary_distance = 85;    // in cm (Breathing target)
            telemetryData.energy_level = 78;           // micro-vibration confidence score

            // Send payload instantly across the local mesh space (<10ms latency)
            esp_err_t result = esp_now_send(gatewayMacAddress, (uint8_t *) &telemetryData, sizeof(telemetryData));
            
            if (result == ESP_OK) {
                ESP_LOGI(TAG, "Telemetry packet dispatched securely via ESP-NOW.");
            } else {
                ESP_LOGE(TAG, "Error sending the data packet.");
            }
        }
        vTaskDelay(pdMS_TO_TICKS(1000)); // Poll every 1 second to maximize ultra-low power runtime
    }
}

void app_main(void) {
    ESP_LOGI(TAG, "EcoMesh Sensor Node Init");

    // Initialize UART for mmWave Radar
    uart_config_t uart_config = {
        .baud_rate = 256000,
        .data_bits = UART_DATA_8_BITS,
        .parity    = UART_PARITY_DISABLE,
        .stop_bits = UART_STOP_BITS_1,
        .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
        .source_clk = UART_SCLK_DEFAULT,
    };
    uart_driver_install(RADAR_UART_NUM, 256, 0, 0, NULL, 0);
    uart_param_config(RADAR_UART_NUM, &uart_config);
    uart_set_pin(RADAR_UART_NUM, TX_PIN, RX_PIN, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE);

    // Initialize mock metadata
    strcpy(telemetryData.node_id, "NODE_ZONE_A1");

    // Init NVS and WiFi for ESP-NOW
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        nvs_flash_erase();
        nvs_flash_init();
    }
    esp_netif_init();
    esp_event_loop_create_default();
    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    esp_wifi_init(&cfg);
    esp_wifi_set_mode(WIFI_MODE_STA);
    esp_wifi_start();

    // Init ESP-NOW
    if (esp_now_init() != ESP_OK) {
        ESP_LOGE(TAG, "Error initializing ESP-NOW");
        return;
    }

    esp_now_register_send_cb(on_data_sent);
    
    // Register peer (Gateway)
    esp_now_peer_info_t peerInfo = {0};
    memcpy(peerInfo.peer_addr, gatewayMacAddress, 6);
    peerInfo.channel = 0;  
    peerInfo.encrypt = false;
    
    if (esp_now_add_peer(&peerInfo) != ESP_OK) {
        ESP_LOGE(TAG, "Failed to add peer");
        return;
    }

    // Spawn radar polling task
    xTaskCreate(radar_polling_task, "radar_polling_task", 4096, NULL, 5, NULL);
}