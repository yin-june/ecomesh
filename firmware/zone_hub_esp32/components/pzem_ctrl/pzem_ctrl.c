#include "pzem_ctrl.h"
#include "driver/uart.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include <string.h>

static const char *TAG = "pzem_ctrl";

#define PZEM_UART_PORT UART_NUM_2
#define PZEM_BAUD_RATE 9600

// Modbus CRC16 Calculation
static uint16_t crc16(const uint8_t *data, uint16_t len) {
    uint16_t crc = 0xFFFF;
    for (uint16_t i = 0; i < len; i++) {
        crc ^= (uint16_t)data[i];
        for (uint8_t j = 0; j < 8; j++) {
            if (crc & 0x0001) {
                crc >>= 1;
                crc ^= 0xA001;
            } else {
                crc >>= 1;
            }
        }
    }
    return crc;
}

esp_err_t pzem_ctrl_init(int tx_pin, int rx_pin) {
    ESP_LOGI(TAG, "Initializing PZEM-004T driver on TX:%d RX:%d", tx_pin, rx_pin);

    uart_config_t uart_config = {
        .baud_rate = PZEM_BAUD_RATE,
        .data_bits = UART_DATA_8_BITS,
        .parity = UART_PARITY_DISABLE,
        .stop_bits = UART_STOP_BITS_1,
        .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
        .source_clk = UART_SCLK_DEFAULT,
    };

    esp_err_t err = uart_driver_install(PZEM_UART_PORT, 256, 0, 0, NULL, 0);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to install UART driver: %s", esp_err_to_name(err));
        return err;
    }

    err = uart_param_config(PZEM_UART_PORT, &uart_config);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to configure UART parameters: %s", esp_err_to_name(err));
        return err;
    }

    err = uart_set_pin(PZEM_UART_PORT, tx_pin, rx_pin, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to set UART pins: %s", esp_err_to_name(err));
        return err;
    }

    return ESP_OK;
}

esp_err_t pzem_ctrl_read(pzem_data_t *data) {
    if (data == NULL) return ESP_ERR_INVALID_ARG;

    // Modbus Read Input Registers command for PZEM-004T:
    // Slave ID (0x01), Function (0x04), Start Reg (0x0000), Reg Count (0x000A)
    uint8_t req[] = {0x01, 0x04, 0x00, 0x00, 0x00, 0x0A, 0x70, 0x0D};

    // Flush any pending RX bytes
    uart_flush(PZEM_UART_PORT);

    // Send request
    uart_write_bytes(PZEM_UART_PORT, (const char *)req, sizeof(req));

    // Expected response length is 25 bytes
    uint8_t resp[25];
    int len = uart_read_bytes(PZEM_UART_PORT, resp, sizeof(resp), pdMS_TO_TICKS(500));

    if (len < 25) {
        ESP_LOGW(TAG, "Timeout waiting for PZEM response (Got %d/25 bytes). Is AC power connected?", len);
        return ESP_ERR_TIMEOUT;
    }

    // Verify CRC
    uint16_t expected_crc = crc16(resp, 23);
    uint16_t received_crc = (resp[24] << 8) | resp[23]; // Little Endian CRC in Modbus
    if (expected_crc != received_crc) {
        ESP_LOGE(TAG, "CRC Error: Expected 0x%04X, got 0x%04X", expected_crc, received_crc);
        return ESP_ERR_INVALID_CRC;
    }

    // Parse Data
    // Each register is 2 bytes (Big Endian)
    // Voltage: 1 reg (0.1V)
    uint32_t raw_voltage = (resp[3] << 8) | resp[4];
    data->voltage = raw_voltage / 10.0f;

    // Current: 2 regs (0.001A)
    uint32_t raw_current = (resp[5] << 8) | resp[6] | (resp[7] << 24) | (resp[8] << 16);
    data->current = raw_current / 1000.0f;

    // Power: 2 regs (0.1W)
    uint32_t raw_power = (resp[9] << 8) | resp[10] | (resp[11] << 24) | (resp[12] << 16);
    data->power = raw_power / 10.0f;

    // Energy: 2 regs (1Wh)
    uint32_t raw_energy = (resp[13] << 8) | resp[14] | (resp[15] << 24) | (resp[16] << 16);
    data->energy = raw_energy;

    // Frequency: 1 reg (0.1Hz)
    uint32_t raw_freq = (resp[17] << 8) | resp[18];
    data->frequency = raw_freq / 10.0f;

    // Power Factor: 1 reg (0.01)
    uint32_t raw_pf = (resp[19] << 8) | resp[20];
    data->pf = raw_pf / 100.0f;

    // Alarms: 1 reg
    data->alarms = (resp[21] << 8) | resp[22];

    return ESP_OK;
}
