#include <Arduino.h>
#include <IRremoteESP8266.h>
#include <IRsend.h>
#include <IRrecv.h>
#include <IRutils.h>

#define IR_SEND_PIN 12
#define IR_RECEIVE_PIN 13

#define BUFFER_SIZE 1024  
#define TIMEOUT 100

IRsend irsend(IR_SEND_PIN);
IRrecv irrecv(IR_RECEIVE_PIN, BUFFER_SIZE, TIMEOUT, true);
decode_results results; 

// Example Raw signal timing array
const uint16_t kRawData[] = {
  9000, 4500, // Header
  560, 560, 560, 560, 560, 1690, 560, 560, // Data bits
  560, 1690, 560, 560, 560, 1690, 560, 1690
};
const uint16_t kRawLength = sizeof(kRawData) / sizeof(kRawData[0]);
const uint16_t kFrequency = 38; 

void setup() {
    Serial.begin(115200);
    while (!Serial);
    
    Serial.println("\n==================================================");
    Serial.println("EcoMesh Hub: IR Transmitter & Receiver Loopback Test");
    Serial.println("Type 'test' in the console and hit Enter to fire the transmitter.");
    Serial.println("Point a remote at it to test the receiver separately.");
    Serial.println("==================================================\n");
    
    irsend.begin();
    irrecv.enableIRIn(); 
}

void loop() {
    // 1. Listen for IR Signals
    if (irrecv.decode(&results)) {
        Serial.println("\n--- IR Signal Captured ---");
        Serial.print("Protocol: ");
        Serial.println(typeToString(results.decode_type));
        Serial.print("Value   : 0x");
        serialPrintUint64(results.value, HEX);
        Serial.println();
        Serial.println(resultToSourceCode(&results));
        Serial.println("-----------------------------------------\n");
        irrecv.resume(); 
    }

    // 2. Listen for 'test' command to fire TX
    if (Serial.available() > 0) {
        String command = Serial.readStringUntil('\n');
        command.trim(); 
        
        if (command.equalsIgnoreCase("test")) {
            Serial.println("\n[TX] Firing raw test sequence...");
            irsend.sendRaw(kRawData, kRawLength, kFrequency);
        } else {
            Serial.print("\n[KEYBOARD] Command received: '");
            Serial.print(command);
            Serial.println("'");
        }
    }
    
    delay(10); 
}