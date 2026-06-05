To move EcoMesh from proposal to hardware, here is your shopping list. I have broken these into two tables: the Sensor Node (Perception) and the Smart Strip (Control & Gateway).
1. EcoMesh Sensor Node (The "Nerves")
You will need 3 units of these to cover multiple zones. Prices are estimates based on Malaysian e-commerce listings for May 2026.
Table 1: EcoMesh Sensor Node
Goal: Deploy 3+ nodes to cover a building. Each node now costs ~RM 45 instead of RM 270.
Component
Recommendation
Est. Price (RM)
Purchase Link (Sample)
mmWave Radar
HLK-LD2410B (24GHz)
RM 16.50
https://my.cytron.io/p-ld2410-high-sensitivity-24ghz-human-presence-status-sensor-radar-module?r=1&gad_source=1&gad_campaignid=17507688159&gclid=CjwKCAjwt7XQBhBkEiwAtStpp6dzho_0mno7Fxs_JJE9BSaLTIkMH10kDRdCnl-ivtfMK5VwLXwReRoCylsQAvD_BwE
Microcontroller
ESP32-C3 SuperMini
RM 12.00
Shopee - ESP32-C3 SuperMini
Battery Charger
TP4056 (Type-C) with Protection
RM 2.50
Shopee - TP4056 Type-C
Power Source
18650 Li-ion Battery (3.7V)
RM 12.00
Shopee - 18650 Battery
Battery Holder
Single-slot 18650 Holder (99.3mm*29.3mm)
RM 2.00
https://shopee.com.my/18650-3.7V-Li-Ion-Battery-Shield-Holder-Charger-Expansion-Development-Board-Module-i.23949362.18582383130



2. EcoMesh Smart Strip (The "Brain & Muscle")
This acts as your central gateway hub. You typically need 1 master hub per zone.

Component
Recommendation
Est. Price (RM)
Purchase Link (Shopee MY)
Master MCU
ESP32-S3 N16R8
RM 33.88
Buy ESP32-S3 N16R8
Energy Monitor
PZEM-004T V3.0
RM 53.90
Buy PZEM-004T V3.0
Power Supply
HLK-PM01 (5V)
RM 19.90
Buy HLK-PM01
Relay Module
4-Channel 5V Relay (Active H/L) or SSR
RM 14.00
Buy 4-Ch Relay (Must set jumpers to 'H' / High-Level Trigger. Use SSR for laptop chargers)
IR Kit
Transmitter + Receiver
RM 5.14
Buy IR Module Set
RF Kit
433MHz XY-MK-5V
RM 4.29
Buy RF 433MHz Kit


Table 3: Additional Prototyping & Safety (The "Toolkit")
Essential for assembly and ensuring the demo doesn't fail during the pitch.
Component
Description
Est. Price (RM)
Purchase Link (Shopee MY)
Breadboard Kit
830-point board + Jumper Wires
RM 6.40
Buy Jumper Wire Set
Project Box
ABS Enclosure for Smart Strip
RM 12.00
Buy Project Box
Mains Cable
3-Core wire for the strip
RM 10.00
Search Mains Cable
Fuse Holder
Safety for 240V AC lines
RM 2.00
Search Fuse Holder
Glass Fuses 
5x20mm Fuses (Pack of 10)
RM 3.50
Buy 5x20mm Fuses 
Perf Board
5cm x 7cm Prototype PCB 
RM 3.00 




Order 1: The "Brains & Eyes" (Cytron.io)
Cytron is the most reliable for the sensitive silicon. If you buy from them, you get original parts and fast 1-2 day shipping from Penang to KL.
Component
Recommendation
Why Cytron?
Master Hub MCU
ESP32-S3-DevKitC-1
Genuine Espressif board. Essential for the AI Vector instructions you need.
Sensor Node MCU
ESP32-C3-DevKitM-1
Reliable BLE Mesh support. While not "SuperMini," it’s very easy to wire.
mmWave Radar
HLK-LD2410B
They stock the version with Bluetooth, making calibration much easier.
Prototyping
Breadboards & Jumper Wires
High-quality pins that don't snap off or lose connection.
Battery Tech
TP4056 & 18650 Holders
Safety-tested charging modules.


Order 2: The "Power & Muscle" (Shopee.com.my)
These are the specialized components for the Smart Strip. You can usually find these in one "IoT" or "Electronics" shop on Shopee (like Caltona Engineering or Xyntac) to save on shipping.
Component
Specific Search Term
Purpose
Energy Monitor
PZEM-004T V3.0
This is the specific one with the CT coil for your NILM logic.
AC-DC Converter
HLK-PM01 5V
Converts 240V to 5V inside your strip to power the ESP32.
Relay Module
4-Channel 5V Relay (Active H/L)
The "Muscle" that clicks the power on/off. Must set jumpers to 'H'. Note: Laptop chargers require SSR or NTC Thermistor due to inrush current.
IR/RF Combo
IR & 433MHz RF Kit
To control the legacy Air-Conds and Fans.
Safety
10A Fuse & Holder
Do not skip this for an AC-powered project.


