#ifndef IR_CTRL_H
#define IR_CTRL_H

#include <stddef.h>
#include <stdint.h>
#include "driver/rmt_types.h"
#include "esp_err.h"

// Define the GPIO pins for the IR receiver and transmitter from PINOUT.md
#define IR_TX_GPIO_NUM   12
#define IR_RX_GPIO_NUM   13

// Initialize the IR RMT transmitter and receiver
esp_err_t ir_ctrl_init(void);

// Transmit raw RMT symbols (IR modulated at 38kHz)
// symbols: Array of RMT pulse symbols to transmit
// count: Number of symbols in the array
esp_err_t ir_ctrl_send_raw(const rmt_symbol_word_t *symbols, size_t count);

// Receive raw RMT symbols from the receiver ring buffer
// symbols_out: Destination array for received symbols
// max_count: Maximum number of symbols to write to the destination array
// out_count: Pointer to write the actual number of symbols received
// timeout_ms: Maximum time to wait for data (in milliseconds)
esp_err_t ir_ctrl_receive_raw(rmt_symbol_word_t *symbols_out, size_t max_count, size_t *out_count, uint32_t timeout_ms);

// Force the IR TX pin HIGH or LOW statically for diagnostic tests
esp_err_t ir_ctrl_test_static(bool level);

// Restore RMT TX channel after running a static test
esp_err_t ir_ctrl_restore_rmt_tx(void);

#endif // IR_CTRL_H
