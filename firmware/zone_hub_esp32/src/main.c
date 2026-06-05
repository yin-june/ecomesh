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
#include "esp_mac.h"
#include "mqtt_client.h"
#include "cJSON.h"
#include "secrets.h"

// Include our custom modular components
#include "relay_ctrl.h"
#include "ir_ctrl.h"
#include "rf_ctrl.h"
#include "pzem_ctrl.h"

static const char *TAG = "EcoMesh_Hub_Main";

// ESP-NOW Data structure mirroring the sensory nodes
typedef struct struct_message {
    char node_id[16];
    bool presence_detected;
    uint16_t moving_distance;
    uint16_t stationary_distance;
    uint8_t energy_level;
} struct_message;

static struct_message incomingTelemetry;
static esp_mqtt_client_handle_t mqtt_client = NULL;
static char gateway_mac_str[18] = {0};
static char telemetry_topic[64] = {0};
static char command_topic[64] = {0};

typedef struct command_message {
    uint8_t command_type; // 1 = CALIBRATE
} command_message;

// Variables for IR Learning
static rmt_symbol_word_t learned_ir_symbols[1024];
static size_t learned_ir_count = 0;
static bool is_learning_mode = false;
// Test timing definitions for RMT IR (NEC protocol-like)
static const rmt_symbol_word_t TEST_IR_SYMBOLS[] = {
    { .duration0 = 9000, .level0 = 1, .duration1 = 4500, .level1 = 0 }, // Leader code
    { .duration0 =  560, .level0 = 1, .duration1 =  560, .level1 = 0 }, // Logic 0
    { .duration0 =  560, .level0 = 1, .duration1 = 1690, .level1 = 0 }, // Logic 1
    { .duration0 =  560, .level0 = 1, .duration1 =  560, .level1 = 0 }, // Logic 0
    { .duration0 =  560, .level0 = 1, .duration1 = 1690, .level1 = 0 }, // Logic 1
    { .duration0 =  560, .level0 = 1, .duration1 =  560, .level1 = 0 }, // Logic 0
    { .duration0 =  560, .level0 = 1, .duration1 =  560, .level1 = 0 }  // Stop bit
};
#define TEST_IR_COUNT (sizeof(TEST_IR_SYMBOLS) / sizeof(TEST_IR_SYMBOLS[0]))

// Non-blocking timer task for MQTT learning mode
void ir_learning_timeout_task(void *pvParameters) {
    vTaskDelay(pdMS_TO_TICKS(3000));
    is_learning_mode = false;
    ESP_LOGI(TAG, ">> 🛑 MQTT LEARNING MODE CLOSED! Successfully recorded %d total symbols.", learned_ir_count);
    vTaskDelete(NULL);
}

static void mqtt_event_handler(void *handler_args, esp_event_base_t base, int32_t event_id, void *event_data) {
    esp_mqtt_event_handle_t event = event_data;
    switch ((esp_mqtt_event_id_t)event_id) {
        case MQTT_EVENT_CONNECTED:
            ESP_LOGI(TAG, "MQTT_EVENT_CONNECTED");
            esp_mqtt_client_subscribe(mqtt_client, command_topic, 1);
            break;
        case MQTT_EVENT_DATA:
            ESP_LOGI(TAG, "MQTT_EVENT_DATA from topic: %.*s", event->topic_len, event->topic);
            if (strncmp(event->topic, command_topic, event->topic_len) == 0) {
                // Parse command payload
                cJSON *root = cJSON_Parse(event->data);
                if (root) {
                    cJSON *device = cJSON_GetObjectItem(root, "device");
                    if (device && device->valuestring && strcmp(device->valuestring, "AC") == 0) {
                        cJSON *temp = cJSON_GetObjectItem(root, "temp");
                        if (temp) {
                            ESP_LOGI(TAG, "Received MQTT Command: Set AC to %d", temp->valueint);
                            if (learned_ir_count > 0) {
                                ESP_LOGI(TAG, "Transmitting learned IR sequence...");
                                ir_ctrl_send_raw(learned_ir_symbols, learned_ir_count);
                            } else {
                                ESP_LOGW(TAG, "No IR sequence learned yet. Send test sequence.");
                                ir_ctrl_send_raw(TEST_IR_SYMBOLS, TEST_IR_COUNT);
                            }
                        }
                    } else if (device && device->valuestring && strcmp(device->valuestring, "IR_LEARN") == 0) {
                        is_learning_mode = true;
                        learned_ir_count = 0;
                        ESP_LOGI(TAG, ">> 🔴 MQTT Triggered IR LEARNING MODE ACTIVE (3 seconds)...");
                        xTaskCreate(ir_learning_timeout_task, "ir_learn_timer", 2048, NULL, 5, NULL);
                    } else if (device && device->valuestring && strcmp(device->valuestring, "RELAY") == 0) {
                        cJSON *state = cJSON_GetObjectItem(root, "state");
                        if (state) {
                            bool is_on = cJSON_IsTrue(state);
                            relay_ctrl_set(0, is_on);
                            ESP_LOGI(TAG, "MQTT Command: Relay set to %s", is_on ? "ON" : "OFF");
                        }
                    } else if (device && device->valuestring && strcmp(device->valuestring, "CALIBRATE_NODE") == 0) {
                        ESP_LOGI(TAG, ">> Start Calibration Triggered! Broadcasting to nodes...");
                        command_message cmd;
                        cmd.command_type = 1;
                        uint8_t broadcast_mac[6] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
                        esp_now_peer_info_t peerInfo = {0};
                        memcpy(peerInfo.peer_addr, broadcast_mac, 6);
                        if (!esp_now_is_peer_exist(broadcast_mac)) {
                            esp_now_add_peer(&peerInfo);
                        }
                        esp_now_send(broadcast_mac, (uint8_t *)&cmd, sizeof(cmd));
                    }
                    cJSON_Delete(root);
                }
            }
            break;
        case MQTT_EVENT_DISCONNECTED:
            ESP_LOGI(TAG, "MQTT_EVENT_DISCONNECTED");
            break;
        default:
            break;
    }
}

static void wifi_event_handler(void* arg, esp_event_base_t event_base, int32_t event_id, void* event_data) {
    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
        esp_wifi_connect();
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        esp_wifi_connect();
        ESP_LOGI(TAG, "Retrying Wi-Fi connection...");
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        ip_event_got_ip_t* event = (ip_event_got_ip_t*) event_data;
        uint8_t primary_chan = 0;
        wifi_second_chan_t second_chan = 0;
        esp_wifi_get_channel(&primary_chan, &second_chan);
        ESP_LOGI(TAG, "Wi-Fi Connected! IP Address: " IPSTR " | Channel: %d", IP2STR(&event->ip_info.ip), primary_chan);
        // Start MQTT once Wi-Fi is connected
        esp_mqtt_client_config_t mqtt_cfg = {
            .broker.address.uri = MQTT_BROKER_URI,
        };
        if (mqtt_client == NULL) {
            mqtt_client = esp_mqtt_client_init(&mqtt_cfg);
            esp_mqtt_client_register_event(mqtt_client, ESP_EVENT_ANY_ID, mqtt_event_handler, NULL);
            esp_mqtt_client_start(mqtt_client);
        }
    }
}

// Send AC OFF signal via IR
static void send_ac_off_signal() {
    static const uint16_t acOffRawSignal[] = {3400, 1750, 450, 450, 450, 1300, 450, 450}; // Truncated example
    size_t raw_len = sizeof(acOffRawSignal) / sizeof(acOffRawSignal[0]);
    size_t rmt_len = (raw_len + 1) / 2;
    rmt_symbol_word_t rmt_symbols[rmt_len];
    
    for (size_t i = 0; i < rmt_len; i++) {
        uint32_t mark = (i * 2 < raw_len) ? acOffRawSignal[i * 2] : 0;
        uint32_t space = (i * 2 + 1 < raw_len) ? acOffRawSignal[i * 2 + 1] : 0;
        rmt_symbols[i].duration0 = mark;
        rmt_symbols[i].level0 = 1;
        rmt_symbols[i].duration1 = space;
        rmt_symbols[i].level1 = 0;
    }
    ir_ctrl_send_raw(rmt_symbols, rmt_len);
}

#if ESP_IDF_VERSION >= ESP_IDF_VERSION_VAL(5, 0, 0)
static void on_data_recv(const esp_now_recv_info_t *esp_now_info, const uint8_t *data, int len) {
#else
static void on_data_recv(const uint8_t *mac_addr, const uint8_t *data, int len) {
#endif
    if (len == sizeof(struct_message)) {
        memcpy(&incomingTelemetry, data, sizeof(incomingTelemetry));
        
        ESP_LOGI(TAG, "--- Inbound Node Data Frame: %s ---", incomingTelemetry.node_id);
        ESP_LOGI(TAG, "Presence Flag: %s", incomingTelemetry.presence_detected ? "HUMAN_PRESENT" : "VACANT");
        ESP_LOGI(TAG, "Target Station Distance: %d cm", incomingTelemetry.stationary_distance);
        ESP_LOGI(TAG, "Sensor Energy Level: %d", incomingTelemetry.energy_level);

        bool current_presence = incomingTelemetry.presence_detected;

        // 1. Constantly enforce Relay state
        if (current_presence) {
            relay_ctrl_set(0, true); // Turn socket relay ON (Channel 0 -> GPIO 33)
        } else {
            relay_ctrl_set(0, false); // Cut off "Ghost/Standby Power"
        }

        // 2. Fire IR commands ONLY on state transitions
        static bool last_presence_state = false;
        if (current_presence && !last_presence_state) {
            ESP_LOGI(TAG, "Action -> Room Occupied (Rising Edge).");
            if (learned_ir_count > 0) {
                ESP_LOGI(TAG, "Transmitting learned IR sequence to power ON AC...");
                ir_ctrl_send_raw(learned_ir_symbols, learned_ir_count);
            } else {
                ESP_LOGW(TAG, "No IR sequence learned yet. Send test sequence.");
                ir_ctrl_send_raw(TEST_IR_SYMBOLS, TEST_IR_COUNT);
            }
        } else if (!current_presence && last_presence_state) {
            ESP_LOGI(TAG, "Action -> Zone Empty. Activating Vampire Shutdown sequence.");
            send_ac_off_signal();
            ESP_LOGI(TAG, "Legacy AC Off command deployed via IR.");
        }
        last_presence_state = current_presence;

        // Publish to MQTT
        if (mqtt_client) {
            char payload[128];
            snprintf(payload, sizeof(payload), "{\"type\":\"occupancy\", \"node\":\"%s\", \"presence\":%d, \"distance\":%d}",
                     incomingTelemetry.node_id, incomingTelemetry.presence_detected ? 1 : 0, incomingTelemetry.stationary_distance);
            esp_mqtt_client_publish(mqtt_client, telemetry_topic, payload, 0, 1, 0);
        }
    }
}


// Test timing definitions for RF loopback (5 cycles of 20ms HIGH, 20ms LOW)
static const uint32_t TEST_RF_PULSES[] = {
    20000, 20000,
    20000, 20000,
    20000, 20000,
    20000, 20000,
    20000, 20000
};
#define TEST_RF_COUNT (sizeof(TEST_RF_PULSES) / sizeof(TEST_RF_PULSES[0]))

// Task to read raw IR signals in the background
void ir_receiver_task(void *pvParameters) {
    ESP_LOGI(TAG, "IR receiver task started.");
    
    // Allocate buffer for incoming RMT symbols on the heap to avoid stack overflow
    #define MAX_IR_SYMBOLS 1024
    rmt_symbol_word_t *rx_buffer = (rmt_symbol_word_t *)malloc(sizeof(rmt_symbol_word_t) * MAX_IR_SYMBOLS);
    if (!rx_buffer) {
        ESP_LOGE(TAG, "Failed to allocate memory for IR rx_buffer!");
        vTaskDelete(NULL);
    }
    size_t received_count = 0;

    while (1) {
        // Try to receive a raw IR sequence (wait indefinitely)
        esp_err_t err = ir_ctrl_receive_raw(rx_buffer, MAX_IR_SYMBOLS, &received_count, portMAX_DELAY);
        if (err == ESP_OK && received_count > 0) {
            if (is_learning_mode) {
                // Append the newly captured frame to our learning buffer
                if (learned_ir_count + received_count + 1 <= MAX_IR_SYMBOLS) {
                    
                    // If we already have symbols (meaning this is Frame 2+), insert a 10ms gap symbol 
                    // to simulate the precise time delay between Panasonic frames so the AC doesn't reject it!
                    if (learned_ir_count > 0) {
                        learned_ir_symbols[learned_ir_count].duration0 = 5000;
                        learned_ir_symbols[learned_ir_count].level0 = 0;
                        learned_ir_symbols[learned_ir_count].duration1 = 5000;
                        learned_ir_symbols[learned_ir_count].level1 = 0;
                        learned_ir_count++;
                    }

                    memcpy(&learned_ir_symbols[learned_ir_count], rx_buffer, sizeof(rmt_symbol_word_t) * received_count);
                    learned_ir_count += received_count;
                    ESP_LOGI(TAG, "📥 Captured Frame part! Total symbols accumulated: %d", learned_ir_count);
                } else {
                    ESP_LOGW(TAG, "Learning buffer full! Cannot append frame.");
                }
            } else {
                ESP_LOGI(TAG, "📥 IR SIGNAL CAPTURED! Received %d symbols. (Ignored. Press 'r' to record)", received_count);
            }
        }
        // Yield to let other tasks run
        vTaskDelay(pdMS_TO_TICKS(1)); 
    }
}

// Task to monitor and print RF pulses in the background
void rf_receiver_task(void *pvParameters) {
    ESP_LOGI(TAG, "RF receiver task started.");
    
    #define MAX_RF_PULSES 100
    uint32_t rx_buffer[MAX_RF_PULSES];

    while (1) {
        // Read raw pulse transitions
        size_t read_count = rf_ctrl_read_received_pulses(rx_buffer, MAX_RF_PULSES);
        if (read_count > 0) {
            // Check if there are pulses corresponding to our 20ms test signature
            int matching_pulses = 0;
            for (size_t i = 0; i < read_count; i++) {
                // Look for pulses in the 15ms - 25ms range
                if (rx_buffer[i] >= 15000 && rx_buffer[i] <= 25000) {
                    matching_pulses++;
                }
            }

            if (matching_pulses >= 4) {
                ESP_LOGI(TAG, "🟢 RF LOOPBACK SUCCESS: Detected %d signature pulses!", matching_pulses);
            }
        }
        vTaskDelay(pdMS_TO_TICKS(500)); // Scan buffer every 500ms
    }
}

// Task to monitor power usage from the PZEM-004T module
void pzem_monitor_task(void *pvParameters) {
    ESP_LOGI(TAG, "PZEM monitor task started.");
    
    pzem_data_t data;

    while (1) {
        esp_err_t err = pzem_ctrl_read(&data);
        if (err == ESP_OK) {
            ESP_LOGI(TAG, "⚡ PZEM Data | V: %.1fV | I: %.3fA | P: %.1fW | E: %.1fWh | Hz: %.1f | PF: %.2f",
                     data.voltage, data.current, data.power, data.energy, data.frequency, data.pf);
            
            if (mqtt_client) {
                char payload[256];
                snprintf(payload, sizeof(payload), 
                         "{\"type\":\"power\", \"voltage\":%.1f, \"current\":%.3f, \"power\":%.1f, \"energy\":%.1f}",
                         data.voltage, data.current, data.power, data.energy);
                esp_mqtt_client_publish(mqtt_client, telemetry_topic, payload, 0, 1, 0);
            }
        } else if (err == ESP_ERR_TIMEOUT) {
            // Usually means AC power is not connected or module is off
            // ESP_LOGW(TAG, "PZEM read timeout. Is AC power connected?");
        } else {
            ESP_LOGE(TAG, "PZEM read error: %s", esp_err_to_name(err));
        }

        vTaskDelay(pdMS_TO_TICKS(2000)); // Query every 2 seconds
    }
}

// Task to read input from Serial terminal to trigger hardware actions
void console_input_task(void *pvParameters) {
    ESP_LOGI(TAG, "Console menu ready. Control hub using key presses:");
    printf("\n--- EcoMesh Smart Strip Hub Console Menu ---\n");
    printf("  [1] Toggle Relay Channel 0 (GPIO 33)\n");
    printf("  [2] Toggle Relay Channel 1 (GPIO 25)\n");
    printf("  [3] Toggle Relay Channel 2 (GPIO 26)\n");
    printf("  [4] Toggle Relay Channel 3 (GPIO 27)\n");
    printf("  [i] Transmit Test IR Pulse Sequence (GPIO 12)\n");
    printf("  [r] Record Custom IR Sequence (Learning Mode)\n");
    printf("  [l] Transmit Custom Learned IR Sequence (AC ON)\n");
    printf("  [t] Trigger 2-second Static IR TX Test (Verify LED)\n");
    printf("  [f] Transmit Test RF Pulse Train (GPIO 23)\n");
    printf("  [h] Reprint this Menu\n");
    printf("---------------------------------------------\n\n");

    // Configure standard input to be non-buffered
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
        // Read characters from console UART
        int length = uart_read_bytes(UART_NUM_0, (uint8_t*)&c, 1, pdMS_TO_TICKS(100));
        if (length > 0) {
            switch (c) {
                case '1':
                    relay_ctrl_toggle(0);
                    printf(">> Channel 0 state toggled to: %s\n", relay_ctrl_get(0) ? "ON" : "OFF");
                    break;
                case '2':
                    relay_ctrl_toggle(1);
                    printf(">> Channel 1 state toggled to: %s\n", relay_ctrl_get(1) ? "ON" : "OFF");
                    break;
                case '3':
                    relay_ctrl_toggle(2);
                    printf(">> Channel 2 state toggled to: %s\n", relay_ctrl_get(2) ? "ON" : "OFF");
                    break;
                case '4':
                    relay_ctrl_toggle(3);
                    printf(">> Channel 3 state toggled to: %s\n", relay_ctrl_get(3) ? "ON" : "OFF");
                    break;
                case 'i':
                case 'I':
                    printf(">> Firing test IR raw sequence...\n");
                    ir_ctrl_send_raw(TEST_IR_SYMBOLS, TEST_IR_COUNT);
                    break;
                case 'r':
                case 'R':
                    is_learning_mode = true;
                    learned_ir_count = 0; // Clear the memory
                    printf("\n>> 🔴 IR LEARNING MODE ACTIVE (You have 3 seconds)...\n");
                    printf(">> Point your AC remote at the Hub and press the ON button...\n\n");
                    
                    // Keep the window open for 3 seconds to catch all fragmented AC frames
                    vTaskDelay(pdMS_TO_TICKS(3000));
                    
                    is_learning_mode = false;
                    printf(">> 🛑 LEARNING MODE CLOSED! Successfully recorded %d total symbols.\n", learned_ir_count);
                    break;
                case 'l':
                case 'L':
                    if (learned_ir_count > 0) {
                        printf(">> Firing CUSTOM recorded IR sequence...\n");
                        ir_ctrl_send_raw(learned_ir_symbols, learned_ir_count);
                    } else {
                        printf(">> Error: No custom IR command recorded yet! Use the app to learn one first.\n");
                    }
                    break;
                case 't':
                case 'T':
                    printf(">> Static test: Pulling IR TX (GPIO 12) HIGH for 2 seconds...\n");
                    ir_ctrl_test_static(true);
                    vTaskDelay(pdMS_TO_TICKS(2000));
                    ir_ctrl_test_static(false);
                    ir_ctrl_restore_rmt_tx();
                    printf(">> Static test complete. RMT TX restored.\n");
                    break;
                case 'f':
                case 'F':
                    printf(">> Firing RF loopback pulse train...\n");
                    // Clear the receiver buffer first so it doesn't read old noise
                    rf_ctrl_clear_buffer();
                    rf_ctrl_send_raw(TEST_RF_PULSES, TEST_RF_COUNT);
                    break;
                case 'h':
                case 'H':
                    printf("\n--- EcoMesh Smart Strip Hub Console Menu ---\n");
                    printf("  [1] Toggle Relay Channel 0 (GPIO 33)\n");
                    printf("  [2] Toggle Relay Channel 1 (GPIO 25)\n");
                    printf("  [3] Toggle Relay Channel 2 (GPIO 26)\n");
                    printf("  [4] Toggle Relay Channel 3 (GPIO 27)\n");
                    printf("  [i] Transmit Test IR Pulse Sequence (GPIO 12)\n");
                    printf("  [r] Record Custom IR Sequence (Learning Mode)\n");
                    printf("  [l] Transmit Custom Learned IR Sequence (AC ON)\n");
                    printf("  [t] Trigger 2-second Static IR TX Test (Verify LED)\n");
                    printf("  [f] Transmit Test RF Pulse Train (GPIO 23)\n");
                    printf("  [h] Reprint this Menu\n");
                    printf("---------------------------------------------\n\n");
                    break;
                default:
                    // Ignore newlines and other inputs
                    break;
            }
        }
        vTaskDelay(pdMS_TO_TICKS(50));
    }
}

void app_main(void)
{
    ESP_LOGI(TAG, "==========================================");
    ESP_LOGI(TAG, "        EcoMesh Smart Strip Hub Init      ");
    ESP_LOGI(TAG, "==========================================");

    // 1. Initialize Relay Control Module
    relay_ctrl_init();

    // Init NVS and WiFi for ESP-NOW
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        nvs_flash_erase();
        nvs_flash_init();
    }
    esp_netif_init();
    esp_event_loop_create_default();
    esp_netif_create_default_wifi_sta();

    esp_event_handler_instance_t instance_any_id;
    esp_event_handler_instance_t instance_got_ip;
    esp_event_handler_instance_register(WIFI_EVENT, ESP_EVENT_ANY_ID, &wifi_event_handler, NULL, &instance_any_id);
    esp_event_handler_instance_register(IP_EVENT, IP_EVENT_STA_GOT_IP, &wifi_event_handler, NULL, &instance_got_ip);

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    esp_wifi_init(&cfg);
    
    wifi_config_t wifi_config = {
        .sta = {
            .ssid = WIFI_SSID,
            .password = WIFI_PASS,
        },
    };
    esp_wifi_set_mode(WIFI_MODE_STA);
    esp_wifi_set_config(WIFI_IF_STA, &wifi_config);
    esp_wifi_start();
    esp_wifi_set_ps(WIFI_PS_NONE); // Disable Wi-Fi power save for ESP-NOW reliability

    uint8_t mac[6];
    esp_read_mac(mac, ESP_MAC_WIFI_STA);
    snprintf(gateway_mac_str, sizeof(gateway_mac_str), "%02X%02X%02X%02X%02X%02X", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
    snprintf(telemetry_topic, sizeof(telemetry_topic), "ecomesh/zones/%s/telemetry", gateway_mac_str);
    snprintf(command_topic, sizeof(command_topic), "ecomesh/zones/%s/command", gateway_mac_str);
    
    ESP_LOGI(TAG, "Gateway Base MAC Address: %02X:%02X:%02X:%02X:%02X:%02X", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);

    if (esp_now_init() == ESP_OK) {
        esp_now_register_recv_cb(on_data_recv);
        ESP_LOGI(TAG, "ESP-NOW initialized successfully");
    } else {
        ESP_LOGE(TAG, "Failed to initialize ESP-NOW");
    }

    // 2. Initialize IR Control Module (RMT TX / RX)
    if (ir_ctrl_init() != ESP_OK) {
        ESP_LOGE(TAG, "Failed to initialize IR Controller!");
    }

    // 3. Initialize RF Control Module
    if (rf_ctrl_init() != ESP_OK) {
        ESP_LOGE(TAG, "Failed to initialize RF Controller!");
    }

    // 4. Initialize PZEM Control Module (TX=17, RX=16)
    if (pzem_ctrl_init(17, 16) != ESP_OK) {
        ESP_LOGE(TAG, "Failed to initialize PZEM Controller!");
    }

    ESP_LOGI(TAG, "Driver initializations successful. Creating FreeRTOS Tasks...");

    // 5. Spawn Background Tasks
    xTaskCreate(ir_receiver_task, "ir_receiver_task", 4096, NULL, 5, NULL);
    xTaskCreate(rf_receiver_task, "rf_receiver_task", 4096, NULL, 5, NULL);
    xTaskCreate(pzem_monitor_task, "pzem_monitor_task", 4096, NULL, 5, NULL);
    xTaskCreate(console_input_task, "console_input_task", 4096, NULL, 5, NULL);

    ESP_LOGI(TAG, "System running. Go to console to control.");
}