#include <Arduino.h>

#define RF_TX_PIN 23
#define RF_RX_PIN 14

// Circular buffer to store raw pulse durations (in microseconds)
#define BUFFER_SIZE 50
volatile unsigned long pulseWidths[BUFFER_SIZE];
volatile byte bufferHead = 0;
volatile unsigned long lastTransitionTime = 0;

// ISR to measure pulse duration (both HIGH and LOW phases)
void ICACHE_RAM_ATTR rxISR() {
  unsigned long now = micros();
  unsigned long duration = now - lastTransitionTime;
  lastTransitionTime = now;

  // Save pulse width in the circular buffer
  pulseWidths[bufferHead] = duration;
  bufferHead = (bufferHead + 1) % BUFFER_SIZE;
}

void setup() {
  Serial.begin(115200);
  while (!Serial);

  pinMode(RF_TX_PIN, OUTPUT);
  digitalWrite(RF_TX_PIN, LOW);

  pinMode(RF_RX_PIN, INPUT);
  attachInterrupt(digitalPinToInterrupt(RF_RX_PIN), rxISR, CHANGE);

  Serial.println("\n==================================================");
  Serial.println("     EcoMesh: RF Raw Timing Loopback Test");
  Serial.println("==================================================");
  Serial.printf("Transmitter (TX) on GPIO %d\n", RF_TX_PIN);
  Serial.printf("Receiver (RX) on GPIO %d\n", RF_RX_PIN);
  Serial.println("--------------------------------------------------");
  Serial.println("Measuring raw radio wave propagation directly...");
  Serial.println("==================================================\n");
}

void loop() {
  static unsigned long lastTxTime = 0;
  
  // Send a test burst of 5 slow pulses every 4 seconds
  if (millis() - lastTxTime > 4000) {
    lastTxTime = millis();

    Serial.println("📤 Sending test signature (5 pulses of 20ms)...");
    
    // Clear buffer before transmitting to only capture new pulses
    noInterrupts();
    for (int i = 0; i < BUFFER_SIZE; i++) {
      pulseWidths[i] = 0;
    }
    bufferHead = 0;
    lastTransitionTime = micros();
    interrupts();

    // Transmit: 5 cycles of 20ms HIGH, 20ms LOW
    for (int i = 0; i < 5; i++) {
      digitalWrite(RF_TX_PIN, HIGH);
      delay(20);
      digitalWrite(RF_TX_PIN, LOW);
      delay(20);
    }

    // Wait a brief moment for any final pulse processing to settle
    delay(100);

    // Analyze the received pulse durations
    int matchingPulses = 0;
    
    noInterrupts(); // Temporarily pause interrupts to read the buffer safely
    for (int i = 0; i < BUFFER_SIZE; i++) {
      unsigned long width = pulseWidths[i];
      // A 20ms pulse is 20,000 microseconds. 
      // We look for pulses between 15,000us and 25,000us (15ms to 25ms).
      if (width >= 15000 && width <= 25000) {
        matchingPulses++;
      }
    }
    interrupts();

    // Print result
    if (matchingPulses >= 4) {
      Serial.printf("🟢 SUCCESS: RF Link Verified! Captured %d signature pulses.\n", matchingPulses);
      Serial.println("   The physical RF transmitter and receiver are communicating successfully!\n");
    } else {
      Serial.printf("❌ FAILED: Captured only %d/5 signature pulses.\n", matchingPulses);
      Serial.println("   No matching RF signal detected. Check antenna, power (5V), or grounding.\n");
      
      // Print the raw captured pulse widths for debugging
      Serial.println("   --- Raw Pulse Widths Captured (ms) ---");
      noInterrupts();
      int count = 0;
      for (int i = 0; i < BUFFER_SIZE; i++) {
        if (pulseWidths[i] > 0) {
          Serial.printf("   %.2f ms | ", pulseWidths[i] / 1000.0);
          count++;
          if (count % 5 == 0) Serial.println();
        }
      }
      if (count % 5 != 0) Serial.println();
      noInterrupts(); // Keep interrupts off for a split second or just turn on
      interrupts();
      Serial.println("   --------------------------------------\n");
    }
  }
}
