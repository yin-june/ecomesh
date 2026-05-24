#ifndef PZEM_CTRL_H
#define PZEM_CTRL_H

#include <stdint.h>
#include <stdbool.h>
#include "esp_err.h"

// Struct to hold all the parsed readings from the PZEM-004T module
typedef struct {
    float voltage;      // Voltage in Volts (V)
    float current;      // Current in Amperes (A)
    float power;        // Active Power in Watts (W)
    float energy;       // Energy consumed in Watt-hours (Wh)
    float frequency;    // Frequency in Hertz (Hz)
    float pf;           // Power Factor
    uint16_t alarms;    // Alarm status (0x0000 to 0xFFFF)
} pzem_data_t;

/**
 * @brief Initialize the PZEM-004T driver.
 * 
 * @param tx_pin GPIO number for UART TX
 * @param rx_pin GPIO number for UART RX
 * @return esp_err_t ESP_OK on success
 */
esp_err_t pzem_ctrl_init(int tx_pin, int rx_pin);

/**
 * @brief Query the PZEM-004T and read the latest data.
 * 
 * @note This function will block for roughly 100-200ms waiting for a response.
 * @note If the PZEM module is not powered by AC mains, this will return ESP_ERR_TIMEOUT.
 * 
 * @param data Pointer to a pzem_data_t struct to populate
 * @return esp_err_t ESP_OK on success, ESP_ERR_TIMEOUT if no response
 */
esp_err_t pzem_ctrl_read(pzem_data_t *data);

#endif // PZEM_CTRL_H
