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

// REPLACE WITH YOUR GATEWAY'S ACTUAL MAC ADDRESS (80:F3:DA:53:D6:30)
static uint8_t gatewayMacAddress[] = {0x80, 0xF3, 0xDA, 0x53, 0xD6, 0x30};

// Callback when data is sent
#if ESP_IDF_VERSION >= ESP_IDF_VERSION_VAL(5, 0, 0)
static void on_data_sent(const esp_now_send_info_t *esp_now_info, esp_now_send_status_t status) {
#else
static void on_data_sent(const uint8_t *mac_addr, esp_now_send_status_t status) {
#endif
    ESP_LOGI(TAG, "Last Packet Send Status: %s", status == ESP_NOW_SEND_SUCCESS ? "Delivery Success" : "Delivery Fail");
}

void radar_polling_task(void *pvParameters) {
    uint8_t rx_buffer[128];
    while (1) {
        // Read raw data stream from mmWave sensor
        int length = uart_read_bytes(RADAR_UART_NUM, rx_buffer, sizeof(rx_buffer), pdMS_TO_TICKS(100));
        if (length > 0) {
            // Find frame header: 0xF4, 0xF3, 0xF2, 0xF1
            for (int i = 0; i < length - 8; i++) {
                if (rx_buffer[i] == 0xF4 && rx_buffer[i+1] == 0xF3 && rx_buffer[i+2] == 0xF2 && rx_buffer[i+3] == 0xF1) {
                    
                    // Byte 8 is the Target Status (0: None, 1: Moving, 2: Stationary, 3: Both)
                    uint8_t target_status = rx_buffer[i+8];
                    
                    // Parse moving distance (bytes 9-10) and energy (byte 11)
                    uint16_t moving_dist = rx_buffer[i+9] | (rx_buffer[i+10] << 8);
                    uint8_t moving_energy = rx_buffer[i+11];
                    
                    // Parse stationary distance (bytes 12-13) and energy (byte 14)
                    uint16_t stationary_dist = rx_buffer[i+12] | (rx_buffer[i+13] << 8);
                    uint8_t stationary_energy = rx_buffer[i+14];
                    
                    telemetryData.presence_detected = (target_status > 0);
                    telemetryData.moving_distance = moving_dist;
                    telemetryData.stationary_distance = stationary_dist;
                    telemetryData.energy_level = (moving_energy > stationary_energy) ? moving_energy : stationary_energy;

                    // Send payload across local mesh space
                    esp_err_t result = esp_now_send(gatewayMacAddress, (uint8_t *) &telemetryData, sizeof(telemetryData));
                    if (result == ESP_OK) {
                        ESP_LOGI(TAG, "Telemetry packet dispatched. Status: %d", target_status);
                    }
                    break; // Processed one frame, break out of search loop
                }
            }
        }
        vTaskDelay(pdMS_TO_TICKS(500)); // Poll every 500ms
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

    // Force Wi-Fi channel to match the Gateway's router channel (Channel 6)
    // ESP-NOW requires both devices to be on the same Wi-Fi channel.
    esp_wifi_set_promiscuous(true);
    esp_wifi_set_channel(6, WIFI_SECOND_CHAN_NONE);
    esp_wifi_set_promiscuous(false);

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