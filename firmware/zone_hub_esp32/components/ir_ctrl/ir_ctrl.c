#include "ir_ctrl.h"
#include "freertos/FreeRTOS.h"
#include "driver/gpio.h"
#include "freertos/queue.h"
#include "freertos/semphr.h"
#include "driver/rmt_tx.h"
#include "driver/rmt_rx.h"
#include "driver/rmt_encoder.h"
#include "esp_log.h"

static const char *TAG = "ir_ctrl";

// RMT Channel Handles
static rmt_channel_handle_t tx_channel = NULL;
static rmt_channel_handle_t rx_channel = NULL;
static rmt_encoder_handle_t copy_encoder = NULL;

// FreeRTOS queue to signal RX completion
static QueueHandle_t rx_queue = NULL;

// Buffer structure for passing RX event data from ISR to task
typedef struct {
    size_t num_symbols;
    esp_err_t err;
} ir_rx_event_t;

// RX Done Callback
static bool rx_done_callback(rmt_channel_handle_t rx_chan, const rmt_rx_done_event_data_t *edata, void *user_ctx) {
    BaseType_t high_task_wakeup = pdFALSE;
    ir_rx_event_t ev = {
        .num_symbols = edata->num_symbols,
        .err = ESP_OK
    };
    // Send event info to task
    xQueueSendFromISR(rx_queue, &ev, &high_task_wakeup);
    return high_task_wakeup == pdTRUE;
}

esp_err_t ir_ctrl_init(void) {
    ESP_LOGI(TAG, "Initializing RMT IR Transmitter on GPIO %d...", IR_TX_GPIO_NUM);

    // 1. Configure and Create RMT TX Channel
    rmt_tx_channel_config_t tx_chan_config = {
        .gpio_num = IR_TX_GPIO_NUM,
        .clk_src = RMT_CLK_SRC_DEFAULT,
        .resolution_hz = 1000000,       // 1 tick = 1 microsecond
        .mem_block_symbols = 64,        
        .trans_queue_depth = 4,         
    };
    esp_err_t err = rmt_new_tx_channel(&tx_chan_config, &tx_channel);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to create RMT TX channel: %s", esp_err_to_name(err));
        return err;
    }

    // 2. Configure 38kHz Carrier Modulation for IR LED
    rmt_carrier_config_t carrier_config = {
        .frequency_hz = 38000,          // 38kHz
        .duty_cycle = 0.33,             // 33% duty cycle
    };
    err = rmt_apply_carrier(tx_channel, &carrier_config);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to apply RMT carrier: %s", esp_err_to_name(err));
        return err;
    }

    err = rmt_enable(tx_channel);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to enable RMT TX channel: %s", esp_err_to_name(err));
        return err;
    }

    // 3. Configure and Create RMT RX Channel
    ESP_LOGI(TAG, "Initializing RMT IR Receiver on GPIO %d...", IR_RX_GPIO_NUM);
    rmt_rx_channel_config_t rx_chan_config = {
        .gpio_num = IR_RX_GPIO_NUM,
        .clk_src = RMT_CLK_SRC_DEFAULT,
        .resolution_hz = 1000000,       // 1 tick = 1 microsecond
        .mem_block_symbols = 64,
        .flags = {
            .invert_in = 1,
        }
    };
    err = rmt_new_rx_channel(&rx_chan_config, &rx_channel);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to create RMT RX channel: %s", esp_err_to_name(err));
        return err;
    }

    // Create FreeRTOS queue for RX signaling
    rx_queue = xQueueCreate(1, sizeof(ir_rx_event_t));
    if (rx_queue == NULL) {
        ESP_LOGE(TAG, "Failed to create RX queue");
        return ESP_ERR_NO_MEM;
    }

    // Register callback for receiving done
    rmt_rx_event_callbacks_t cbs = {
        .on_recv_done = rx_done_callback,
    };
    err = rmt_rx_register_event_callbacks(rx_channel, &cbs, NULL);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to register RMT RX callbacks: %s", esp_err_to_name(err));
        return err;
    }

    err = rmt_enable(rx_channel);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to enable RMT RX channel: %s", esp_err_to_name(err));
        return err;
    }

    // Create RMT copy encoder for raw symbol transmission
    rmt_copy_encoder_config_t copy_encoder_config = {};
    err = rmt_new_copy_encoder(&copy_encoder_config, &copy_encoder);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to create RMT copy encoder: %s", esp_err_to_name(err));
        return err;
    }

    ESP_LOGI(TAG, "IR RMT configuration complete.");
    return ESP_OK;
}

esp_err_t ir_ctrl_send_raw(const rmt_symbol_word_t *symbols, size_t count) {
    if (tx_channel == NULL || copy_encoder == NULL) {
        ESP_LOGE(TAG, "TX channel or encoder not initialized!");
        return ESP_ERR_INVALID_STATE;
    }

    rmt_transmit_config_t transmit_config = {
        .loop_count = 0, // No loops
    };

    ESP_LOGI(TAG, "Transmitting IR burst (%d symbols)...", count);
    esp_err_t err = rmt_transmit(tx_channel, copy_encoder, symbols, count * sizeof(rmt_symbol_word_t), &transmit_config);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "RMT transmission failed: %s", esp_err_to_name(err));
        return err;
    }

    // Wait until done
    return rmt_tx_wait_all_done(tx_channel, portMAX_DELAY);
}

esp_err_t ir_ctrl_receive_raw(rmt_symbol_word_t *symbols_out, size_t max_count, size_t *out_count, uint32_t timeout_ms) {
    if (rx_channel == NULL) {
        ESP_LOGE(TAG, "RX channel not initialized!");
        return ESP_ERR_INVALID_STATE;
    }

    // Start RMT receive engine
    rmt_receive_config_t receive_config = {
        .signal_range_min_ns = 0,               // Disable min duration filter
        .signal_range_max_ns = 60000 * 1000,    // Max pulse duration 60ms (within 65.5ms hardware register limit)
    };

    // We pass our symbols_out buffer directly to RMT receive
    esp_err_t err = rmt_receive(rx_channel, symbols_out, max_count * sizeof(rmt_symbol_word_t), &receive_config);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to initiate RMT receive: %s", esp_err_to_name(err));
        return err;
    }

    // Wait for the ISR to signal that a full packet has been received
    ir_rx_event_t ev;
    if (xQueueReceive(rx_queue, &ev, pdMS_TO_TICKS(timeout_ms)) == pdTRUE) {
        *out_count = ev.num_symbols;
        ESP_LOGI(TAG, "IR signal captured! Symbols count: %d", ev.num_symbols);
        return ev.err;
    } else {
        // Timed out before receiving a packet. Disable and enable RX receiver to abort the pending receive transaction.
        rmt_disable(rx_channel);
        rmt_enable(rx_channel);
        ESP_LOGD(TAG, "IR receive timed out (no signal).");
        return ESP_ERR_TIMEOUT;
    }
}

esp_err_t ir_ctrl_test_static(bool level) {
    if (tx_channel != NULL) {
        rmt_disable(tx_channel);
        rmt_del_channel(tx_channel);
        tx_channel = NULL;
    }
    copy_encoder = NULL; // The copy encoder belongs to the TX channel and is deleted automatically
    
    // Reset the pin and configure as standard GPIO output
    gpio_reset_pin(IR_TX_GPIO_NUM);
    gpio_set_direction(IR_TX_GPIO_NUM, GPIO_MODE_OUTPUT);
    gpio_set_level(IR_TX_GPIO_NUM, level ? 1 : 0);
    
    ESP_LOGI(TAG, "IR TX GPIO %d set to static level %d", IR_TX_GPIO_NUM, level);
    return ESP_OK;
}

esp_err_t ir_ctrl_restore_rmt_tx(void) {
    if (tx_channel != NULL) {
        return ESP_OK; // Already restored
    }
    
    ESP_LOGI(TAG, "Restoring RMT IR Transmitter on GPIO %d...", IR_TX_GPIO_NUM);

    // Re-configure and Create RMT TX Channel
    rmt_tx_channel_config_t tx_chan_config = {
        .gpio_num = IR_TX_GPIO_NUM,
        .clk_src = RMT_CLK_SRC_DEFAULT,
        .resolution_hz = 1000000,       // 1 tick = 1 microsecond
        .mem_block_symbols = 64,        
        .trans_queue_depth = 4,         
    };
    esp_err_t err = rmt_new_tx_channel(&tx_chan_config, &tx_channel);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to restore RMT TX channel: %s", esp_err_to_name(err));
        return err;
    }

    rmt_carrier_config_t carrier_config = {
        .frequency_hz = 38000,          // 38kHz
        .duty_cycle = 0.33,             // 33% duty cycle
    };
    err = rmt_apply_carrier(tx_channel, &carrier_config);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to apply RMT carrier on restore: %s", esp_err_to_name(err));
        return err;
    }

    err = rmt_enable(tx_channel);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to enable restored RMT TX channel: %s", esp_err_to_name(err));
        return err;
    }

    // Re-create RMT copy encoder
    rmt_copy_encoder_config_t copy_encoder_config = {};
    err = rmt_new_copy_encoder(&copy_encoder_config, &copy_encoder);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to restore RMT copy encoder: %s", esp_err_to_name(err));
        return err;
    }

    ESP_LOGI(TAG, "IR RMT TX restored successfully.");
    return ESP_OK;
}
