#include "relay_ctrl.h"
#include "driver/gpio.h"
#include "esp_log.h"

static const char *TAG = "relay_ctrl";

// Define the GPIO pins for the 4 relay channels
static const gpio_num_t RELAY_PINS[] = {
    GPIO_NUM_33, // Channel 0
    GPIO_NUM_25, // Channel 1
    GPIO_NUM_26, // Channel 2
    GPIO_NUM_27  // Channel 3
};
#define NUM_CHANNELS (sizeof(RELAY_PINS) / sizeof(RELAY_PINS[0]))

// Track the state of the relays (true = ON/LOW, false = OFF/HIGH)
static bool relay_states[NUM_CHANNELS] = {false, false, false, false};

void relay_ctrl_init(void) {
    ESP_LOGI(TAG, "Initializing 4-Channel Relay GPIOs (Low-Level Trigger)...");

    // Configure the GPIO pins as output
    gpio_config_t io_conf = {
        .intr_type = GPIO_INTR_DISABLE,
        .mode = GPIO_MODE_INPUT_OUTPUT, // Read-back capability
        .pin_bit_mask = (1ULL << GPIO_NUM_25) | (1ULL << GPIO_NUM_26) | 
                        (1ULL << GPIO_NUM_27) | (1ULL << GPIO_NUM_33),
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .pull_up_en = GPIO_PULLUP_DISABLE
    };
    esp_err_t err = gpio_config(&io_conf);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to configure GPIO pins! Error: %s", esp_err_to_name(err));
        return;
    }

    // Set initial state to OFF (HIGH level for Low-Level Trigger)
    for (int i = 0; i < NUM_CHANNELS; i++) {
        gpio_set_level(RELAY_PINS[i], 1); // 1 = HIGH = Relay OFF
        relay_states[i] = false;
    }
    ESP_LOGI(TAG, "Relay initialization complete. All channels OFF.");
}

void relay_ctrl_set(int channel, bool state) {
    if (channel < 0 || channel >= NUM_CHANNELS) {
        ESP_LOGW(TAG, "Invalid relay channel: %d", channel);
        return;
    }

    // Low-Level Trigger:
    // state == true  -> pin = 0 (LOW)  -> Relay ON
    // state == false -> pin = 1 (HIGH) -> Relay OFF
    int level = state ? 0 : 1;
    gpio_set_level(RELAY_PINS[channel], level);
    relay_states[channel] = state;
    
    ESP_LOGI(TAG, "Relay Channel %d set to %s (%s)", 
             channel, state ? "ON" : "OFF", state ? "Pin LOW" : "Pin HIGH");
}

void relay_ctrl_toggle(int channel) {
    if (channel < 0 || channel >= NUM_CHANNELS) {
        ESP_LOGW(TAG, "Invalid relay channel: %d", channel);
        return;
    }
    relay_ctrl_set(channel, !relay_states[channel]);
}

bool relay_ctrl_get(int channel) {
    if (channel < 0 || channel >= NUM_CHANNELS) {
        ESP_LOGW(TAG, "Invalid relay channel: %d", channel);
        return false;
    }
    return relay_states[channel];
}
