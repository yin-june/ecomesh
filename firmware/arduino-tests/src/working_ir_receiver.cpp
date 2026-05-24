// #include <Arduino.h>
// #include <IRremoteESP8266.h>
// #include <IRrecv.h>
// #include <IRutils.h>

// #define IR_RECEIVE_PIN 13 // Receiver Module (S)

// #define BUFFER_SIZE 1024  
// #define TIMEOUT 100 // Increased to 100 to catch the full Daikin multi-part signal

// IRrecv irrecv(IR_RECEIVE_PIN, BUFFER_SIZE, TIMEOUT, true);
// decode_results results; 

// void setup() {
//     Serial.begin(115200);
//     while (!Serial);
    
//     Serial.println("\n==================================================");
//     Serial.println("EcoMesh Node 1: Terminal & Raw Data Harvester");
//     Serial.println("Point your Daikin remote here and press a button!");
//     Serial.println("Type anything below and hit Enter to test the connection.");
//     Serial.println("==================================================\n");
    
//     irrecv.enableIRIn(); 
// }

// void loop() {
//     // ---------------------------------------------------------
//     // 1. Listen for IR Signals from the remote
//     // ---------------------------------------------------------
//     if (irrecv.decode(&results)) {
//         Serial.println("\n--- IR Signal Captured ---");
//         Serial.print("Protocol: ");
//         Serial.println(typeToString(results.decode_type));
//         Serial.print("Value   : 0x");
//         serialPrintUint64(results.value, HEX);
//         Serial.println();
        
//         // --- ADDED THIS TO GET YOUR UNO COMMAND ---
//         Serial.println("\n--- COPY THIS ENTIRE LINE FOR THE UNO ---");
//         Serial.println(resultToSourceCode(&results));
        
//         Serial.println("-----------------------------------------\n");
        
//         irrecv.resume(); 
//     }

//     // ---------------------------------------------------------
//     // 2. Listen for Text Prompts from the Serial Monitor
//     // ---------------------------------------------------------
//     if (Serial.available() > 0) {
//         // Read whatever you typed into the terminal
//         String command = Serial.readStringUntil('\n');
//         command.trim(); // Clean up invisible newline characters
        
//         // Echo it back to prove the ESP32 received it
//         Serial.print("\n[KEYBOARD] Command received: '");
//         Serial.print(command);
//         Serial.println("'");
//     }
    
//     delay(10); 
// }