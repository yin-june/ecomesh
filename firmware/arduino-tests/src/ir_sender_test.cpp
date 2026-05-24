#include <Arduino.h>
#include <IRremoteESP8266.h>
#include <IRsend.h>

// Pin 12 is designated for the IR Transmitter
#define IR_SEND_PIN 12

IRsend irsend(IR_SEND_PIN);

// Example NEC protocol test code (common TV power toggle command)
const uint64_t kNecTestCode = 0x00FF38C7; 
const uint16_t kNecBits = 32;

// Example Raw signal timing array (simplified short sample representation)
// In a real application, copy the output of resultToSourceCode() from main.cpp here
const uint16_t kRawData[] = {
  9000, 4500, // Header
  560, 560, 560, 560, 560, 1690, 560, 560, // Data bits
  560, 1690, 560, 560, 560, 1690, 560, 1690
};
const uint16_t kRawLength = sizeof(kRawData) / sizeof(kRawData[0]);
const uint16_t kFrequency = 38; // 38kHz is standard for most AC / TV protocols

// void setup() {
//   Serial.begin(115200);
//   while (!Serial);
//   
//   Serial.println("\n==================================================");
//   Serial.println("EcoMesh Node 1: IR Transmitter Test");
//   Serial.println("Using GPIO 12 for the IR Sender");
//   Serial.println("==================================================\n");
//   
//   irsend.begin(); // Initialize the IR transmitter module
//}

// void loop() {
//   // 1. Send using a standard protocol (NEC)
//   Serial.print("Sending NEC code: 0x");
//   Serial.println(kNecTestCode, HEX);
//   irsend.sendNEC(kNecTestCode, kNecBits);
//   delay(3000); // Wait 3 seconds
//   
//   // 2. Send using raw timing array (mimicry example)
//   Serial.println("Sending a sample Raw IR Timing signal...");
//   irsend.sendRaw(kRawData, kRawLength, kFrequency);
//   delay(3000); // Wait 3 seconds
// }
