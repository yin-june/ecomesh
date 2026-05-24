#ifndef RF_CTRL_H
#define RF_CTRL_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include "esp_err.h"

// Define the GPIO pins for the RF receiver and transmitter from PINOUT.md
#define RF_TX_GPIO_NUM   23
#define RF_RX_GPIO_NUM   14

// Initialize the RF transmitter and receiver GPIOs and interrupts
esp_err_t rf_ctrl_init(void);

// Send a raw pulse sequence (alternating HIGH and LOW durations)
// pulse_durations_us: Array of durations in microseconds
// count: Number of pulses in the array
void rf_ctrl_send_raw(const uint32_t *pulse_durations_us, size_t count);

// Read raw pulse widths captured by the receiver interrupt
// buffer_out: Destination array for captured durations (in microseconds)
// max_count: Maximum size of the destination array
// Returns the actual number of pulse durations read from the internal circular buffer
size_t rf_ctrl_read_received_pulses(uint32_t *buffer_out, size_t max_count);

// Clear the receiver internal pulse buffer
void rf_ctrl_clear_buffer(void);

#endif // RF_CTRL_H
