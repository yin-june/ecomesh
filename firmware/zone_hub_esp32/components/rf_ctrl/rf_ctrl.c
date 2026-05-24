#include "rf_ctrl.h"
#include "driver/gpio.h"
#include "esp_timer.h"
#include "esp_log.h"
#include "esp_rom_sys.h" // For esp_rom_delay_us
#include "freertos/FreeRTOS.h"
#include "freertos/portmacro.h"

static const char *TAG = "rf_ctrl";

// Circular buffer configuration
#define RF_RX_BUFFER_SIZE 256
static volatile uint32_t rx_buffer[RF_RX_BUFFER_SIZE];
static volatile size_t rx_head = 0;
static volatile size_t rx_tail = 0;
static volatile int64_t last_transition_time = 0;

// Spinlock to protect buffer read/write access
static portMUX_TYPE rf_spinlock = portMUX_INITIALIZER_UNLOCKED;

// Interrupt Service Routine (ISR) triggered on GPIO 14 change (RISING or FALLING)
static void IRAM_ATTR rf_gpio_isr_handler(void* arg) {
    int64_t now = esp_timer_get_time();
    
    portENTER_CRITICAL_ISR(&rf_spinlock);
    if (last_transition_time > 0) {
        uint32_t duration = (uint32_t)(now - last_transition_time);
        
        // Push duration into the circular buffer
        size_t next_head = (rx_head + 1) % RF_RX_BUFFER_SIZE;
        if (next_head != rx_tail) { // Check if buffer is full
            rx_buffer[rx_head] = duration;
            rx_head = next_head;
        }
    }
    last_transition_time = now;
    portEXIT_CRITICAL_ISR(&rf_spinlock);
}

esp_err_t rf_ctrl_init(void) {
    ESP_LOGI(TAG, "Initializing RF Transmitter on GPIO %d...", RF_TX_GPIO_NUM);

    // 1. Configure Transmitter Pin (GPIO 23)
    gpio_config_t tx_conf = {
        .intr_type = GPIO_INTR_DISABLE,
        .mode = GPIO_MODE_OUTPUT,
        .pin_bit_mask = (1ULL << RF_TX_GPIO_NUM),
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .pull_up_en = GPIO_PULLUP_DISABLE
    };
    esp_err_t err = gpio_config(&tx_conf);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to configure RF TX Pin: %s", esp_err_to_name(err));
        return err;
    }
    gpio_set_level(RF_TX_GPIO_NUM, 0); // Start LOW

    // 2. Configure Receiver Pin (GPIO 14)
    ESP_LOGI(TAG, "Initializing RF Receiver on GPIO %d...", RF_RX_GPIO_NUM);
    gpio_config_t rx_conf = {
        .intr_type = GPIO_INTR_ANYEDGE, // Trigger interrupt on RISING and FALLING edges
        .mode = GPIO_MODE_INPUT,
        .pin_bit_mask = (1ULL << RF_RX_GPIO_NUM),
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .pull_up_en = GPIO_PULLUP_DISABLE
    };
    err = gpio_config(&rx_conf);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to configure RF RX Pin: %s", esp_err_to_name(err));
        return err;
    }

    // 3. Install GPIO ISR Service (checking if already installed)
    err = gpio_install_isr_service(0);
    if (err == ESP_ERR_INVALID_STATE) {
        // ISR service is already installed, which is fine
        err = ESP_OK;
    } else if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to install GPIO ISR service: %s", esp_err_to_name(err));
        return err;
    }

    // 4. Hook up ISR Handler for our receiver pin
    err = gpio_isr_handler_add(RF_RX_GPIO_NUM, rf_gpio_isr_handler, NULL);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to add ISR handler for RF RX Pin: %s", esp_err_to_name(err));
        return err;
    }

    // Reset buffer tracking variables
    rf_ctrl_clear_buffer();

    ESP_LOGI(TAG, "RF module configuration complete.");
    return ESP_OK;
}

void rf_ctrl_send_raw(const uint32_t *pulse_durations_us, size_t count) {
    if (pulse_durations_us == NULL || count == 0) {
        return;
    }

    // We toggle the pin HIGH and LOW using busy-wait delays for microsecond accuracy
    bool level = true;
    for (size_t i = 0; i < count; i++) {
        gpio_set_level(RF_TX_GPIO_NUM, level ? 1 : 0);
        esp_rom_delay_us(pulse_durations_us[i]);
        level = !level;
    }
    gpio_set_level(RF_TX_GPIO_NUM, 0); // Turn off transmitter at the end of transmission
}

size_t rf_ctrl_read_received_pulses(uint32_t *buffer_out, size_t max_count) {
    size_t count = 0;
    if (buffer_out == NULL || max_count == 0) {
        return 0;
    }

    portENTER_CRITICAL(&rf_spinlock);
    while (rx_tail != rx_head && count < max_count) {
        buffer_out[count++] = rx_buffer[rx_tail];
        rx_tail = (rx_tail + 1) % RF_RX_BUFFER_SIZE;
    }
    portEXIT_CRITICAL(&rf_spinlock);

    return count;
}

void rf_ctrl_clear_buffer(void) {
    portENTER_CRITICAL(&rf_spinlock);
    rx_head = 0;
    rx_tail = 0;
    last_transition_time = 0;
    for (int i = 0; i < RF_RX_BUFFER_SIZE; i++) {
        rx_buffer[i] = 0;
    }
    portEXIT_CRITICAL(&rf_spinlock);
}
