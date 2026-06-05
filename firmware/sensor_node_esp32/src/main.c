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

// Global variable for channel hopping
static uint8_t current_channel = 1;

// Callback when data is sent
#if ESP_IDF_VERSION >= ESP_IDF_VERSION_VAL(5, 0, 0)
static void on_data_sent(const esp_now_send_info_t *esp_now_info, esp_now_send_status_t status) {
#else
static void on_data_sent(const uint8_t *mac_addr, esp_now_send_status_t status) {
#endif
    if (status == ESP_NOW_SEND_SUCCESS) {
        ESP_LOGI(TAG, "Last Packet Send Status: Delivery Success (Channel %d)", current_channel);
    } else {
        ESP_LOGW(TAG, "Last Packet Send Status: Delivery Fail. Switching to channel %d...", (current_channel % 13) + 1);
        current_channel++;
        if (current_channel > 13) {
            current_channel = 1;
        }
        esp_wifi_set_promiscuous(true);
        esp_wifi_set_channel(current_channel, WIFI_SECOND_CHAN_NONE);
        esp_wifi_set_promiscuous(false);
    }
}

static uint16_t max_valid_distance_cm = 200;  // Proximity filter
static uint8_t min_valid_energy = 75;         // Threshold filter
#define PRESENCE_DEBOUNCE_MS  3000 // Debounce time: Wait 3 seconds before deciding room is empty
#define CALIBRATION_MODE      1    // 1 = Print raw radar data for tuning, 0 = Quiet production mode

// Auto-calibration state
static bool is_calibrating = false;
static uint32_t calibration_end_time = 0;
static uint8_t calib_peak_energy = 0;
static uint16_t calib_peak_distance = 0;

typedef struct command_message {
    uint8_t command_type; // 1 = Start Auto-Calibration
} command_message;

#if ESP_IDF_VERSION >= ESP_IDF_VERSION_VAL(5, 0, 0)
static void on_data_recv(const esp_now_recv_info_t *esp_now_info, const uint8_t *data, int len) {
#else
static void on_data_recv(const uint8_t *mac_addr, const uint8_t *data, int len) {
#endif
    if (len == sizeof(command_message)) {
        command_message *cmd = (command_message *)data;
        if (cmd->command_type == 1) {
            ESP_LOGI(TAG, ">> Received OTA Command: Start Auto-Calibration!");
            calib_peak_energy = 0;
            calib_peak_distance = 0;
            is_calibrating = true;
            calibration_end_time = xTaskGetTickCount() * portTICK_PERIOD_MS + 15000;
        }
    }
}

void console_input_task(void *pvParameters) {
    ESP_LOGI(TAG, "Console menu ready. Control node using key presses:");
    printf("\n--- EcoMesh Sensor Node Console Menu ---\n");
    printf("  [c] Start 15-second Auto-Calibration (Leave the room!)\n");
    printf("  [h] Reprint this Menu\n");
    printf("---------------------------------------------\n\n");

    uart_config_t uart_config = {
        .baud_rate = 115200,
        .data_bits = UART_DATA_8_BITS,
        .parity    = UART_PARITY_DISABLE,
        .stop_bits = UART_STOP_BITS_1,
        .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
        .source_clk = UART_SCLK_DEFAULT,
    };
    uart_driver_install(UART_NUM_0, 256, 0, 0, NULL, 0);
    uart_param_config(UART_NUM_0, &uart_config);

    char c;
    while (1) {
        int length = uart_read_bytes(UART_NUM_0, (uint8_t*)&c, 1, pdMS_TO_TICKS(100));
        if (length > 0) {
            if (c == 'c' || c == 'C') {
                printf(">> Starting Auto-Calibration! You have 5 seconds to leave the room...\n");
                vTaskDelay(pdMS_TO_TICKS(5000));
                printf(">> Recording baseline room noise for 15 seconds...\n");
                calib_peak_energy = 0;
                calib_peak_distance = 0;
                is_calibrating = true;
                calibration_end_time = xTaskGetTickCount() * portTICK_PERIOD_MS + 15000;
            } else if (c == 'h' || c == 'H') {
                printf("\n--- EcoMesh Sensor Node Console Menu ---\n");
                printf("  [c] Start 15-second Auto-Calibration (Leave the room!)\n");
                printf("  [h] Reprint this Menu\n");
                printf("---------------------------------------------\n\n");
            }
        }
        vTaskDelay(pdMS_TO_TICKS(50));
    }
}

void radar_polling_task(void *pvParameters) {
    uint8_t rx_buffer[128];
    uint32_t last_presence_time = 0; // Tracks the last time a valid presence was detected
    
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
                    
                    uint8_t max_energy = (moving_energy > stationary_energy) ? moving_energy : stationary_energy;
                    uint16_t primary_dist = (target_status == 1 || target_status == 3) ? moving_dist : stationary_dist;

                    uint32_t current_time = xTaskGetTickCount() * portTICK_PERIOD_MS;

                    if (is_calibrating) {
                        if (current_time < calibration_end_time) {
                            if (max_energy > calib_peak_energy) calib_peak_energy = max_energy;
                            if (primary_dist > calib_peak_distance) calib_peak_distance = primary_dist;
                            // Silently log every 1 second to avoid spam
                            static uint32_t last_log = 0;
                            if (current_time - last_log > 1000) {
                                ESP_LOGI(TAG, "CALIBRATING... Peak E so far: %d, Peak Dist: %d", calib_peak_energy, calib_peak_distance);
                                last_log = current_time;
                            }
                        } else {
                            is_calibrating = false;
                            min_valid_energy = calib_peak_energy + 15; // Buffer to prevent false positives
                            if (min_valid_energy > 100) min_valid_energy = 100;
                            max_valid_distance_cm = calib_peak_distance + 50; // Add 50cm boundary buffer
                            printf("\n====================================\n");
                            printf("   AUTO-CALIBRATION COMPLETE!\n");
                            printf("   New Energy Threshold: %d\n", min_valid_energy);
                            printf("   New Distance Bound: %d cm\n", max_valid_distance_cm);
                            printf("====================================\n\n");
                        }
                    }

#if CALIBRATION_MODE
                    if (!is_calibrating) {
                        ESP_LOGI(TAG, "RAW_CALIB | Stat:%d | Move:%dcm (E:%d) | Stat:%dcm (E:%d) | MaxE:%d", 
                                 target_status, moving_dist, moving_energy, stationary_dist, stationary_energy, max_energy);
                    }
#endif

                    bool valid_detection = false;

                    // 1. FILTERING LOGIC
                    if (target_status == 0) {
                        valid_detection = false; // Naturally empty
                    } else if (max_energy < min_valid_energy) {
                        ESP_LOGW(TAG, "FILTERED [Threshold]: Energy %d is too low (Dist: %d cm)", max_energy, primary_dist);
                        valid_detection = false;
                    } else if (primary_dist > max_valid_distance_cm) {
                        ESP_LOGW(TAG, "FILTERED [Proximity]: Target at %d cm is out of bounds", primary_dist);
                        valid_detection = false;
                    } else {
                        valid_detection = true; // Valid presence detected
                    }

                    // uint32_t current_time removed from here because it was moved up
                    
                    // 2. DEBOUNCE LOGIC (Hold-Time)
                    if (valid_detection) {
                        last_presence_time = current_time;
                        telemetryData.presence_detected = true;
                    } else {
                        // If no valid detection, check if debounce period has expired
                        if ((current_time - last_presence_time) > PRESENCE_DEBOUNCE_MS) {
                            if (telemetryData.presence_detected) {
                                ESP_LOGI(TAG, "ROOM VACATED: No valid presence for %d ms", PRESENCE_DEBOUNCE_MS);
                            }
                            telemetryData.presence_detected = false;
                        } else {
                            // Still holding presence due to debounce
                            if (telemetryData.presence_detected) {
                                ESP_LOGI(TAG, "DEBOUNCE: Holding presence flag (Time left: %d ms)", 
                                         (int)(PRESENCE_DEBOUNCE_MS - (current_time - last_presence_time)));
                            }
                        }
                    }

                    telemetryData.moving_distance = moving_dist;
                    telemetryData.stationary_distance = stationary_dist;
                    telemetryData.energy_level = max_energy;

                    // Send payload across local mesh space
                    esp_err_t result = esp_now_send(gatewayMacAddress, (uint8_t *) &telemetryData, sizeof(telemetryData));
                    if (result == ESP_OK) {
                        const char* occ_str = telemetryData.presence_detected ? "[OCCUPIED]" : "[EMPTY   ]";
                        ESP_LOGI(TAG, "Telemetry dispatched | %s | Status: %d | MoveDist: %d cm | StatDist: %d cm | Energy: %d", 
                                 occ_str, target_status, moving_dist, stationary_dist, telemetryData.energy_level);
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

    // Start on channel 1; the on_data_sent callback will automatically
    // scan through channels 1-13 if it fails to find the Gateway.
    esp_wifi_set_promiscuous(true);
    esp_wifi_set_channel(current_channel, WIFI_SECOND_CHAN_NONE);
    esp_wifi_set_promiscuous(false);

    // Init ESP-NOW
    if (esp_now_init() != ESP_OK) {
        ESP_LOGE(TAG, "Error initializing ESP-NOW");
        return;
    }

    esp_now_register_send_cb(on_data_sent);
    esp_now_register_recv_cb(on_data_recv);
    
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
    xTaskCreate(console_input_task, "console_input_task", 4096, NULL, 5, NULL);
}