#ifndef RELAY_CTRL_H
#define RELAY_CTRL_H

#include <stdbool.h>

// Initialise the relay GPIO configurations (Pins: 25, 26, 27, 33)
void relay_ctrl_init(void);

// Set the state of a specific relay channel (0 to 3)
// state = true  -> Relay ON  (Pin driven LOW, closed circuit)
// state = false -> Relay OFF (Pin driven HIGH, open circuit)
void relay_ctrl_set(int channel, bool state);

// Toggle the state of a specific relay channel (0 to 3)
void relay_ctrl_toggle(int channel);

// Get the current state of a specific relay channel (0 to 3)
// Returns true if relay is ON (pin is LOW), false if OFF (pin is HIGH)
bool relay_ctrl_get(int channel);

#endif // RELAY_CTRL_H
