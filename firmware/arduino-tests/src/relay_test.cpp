// #include <Arduino.h>

// // Safe general-purpose GPIOs for ESP32
// // (Avoided pins 6-11, and strapping pins like 0, 2, 12, 15)
// const int relayPins[] = {25, 26, 27, 33};
// const int numPins = 4;

// void setup() {
//   // Optimized for ESP32 high-speed debugging
//   Serial.begin(115200); 
//   while (!Serial); // Wait for Serial Monitor to catch up
  
//   // Set each pin to OUTPUT mode and turn it OFF to start
//   for (int i = 0; i < numPins; i++) {
//     pinMode(relayPins[i], OUTPUT);
//     digitalWrite(relayPins[i], HIGH); // HIGH keeps a Low-Level Trigger relay OFF
//   }
  
//   Serial.println("\n=== ESP32 4-Channel Relay Sequence Test Started ===");
// }

// void loop() {
//   for (int i = 0; i < numPins; i++) {
//     Serial.print("Clicking Relay on GPIO ");
//     Serial.print(relayPins[i]);
//     Serial.println(" -> ON 🟢");
    
//     digitalWrite(relayPins[i], LOW); // Turn ON (Low-Level Trigger)
//     delay(1000);                     
    
//     Serial.print("Clicking Relay on GPIO ");
//     Serial.print(relayPins[i]);
//     Serial.println(" -> OFF 🔴\n");

//     digitalWrite(relayPins[i], HIGH); // Turn OFF
//     delay(1000);                      
//   }
// }