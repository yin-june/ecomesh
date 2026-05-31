# Project Proposal: EcoMesh

**Subtitle:** A Low-Cost, Universal Gateway for Personalized Energy Environments

## Abstract / Executive Summary
EcoMesh is a decentralized energy management prototype designed to tackle electricity waste in existing residential and commercial spaces. Moving beyond static schedules, EcoMesh utilizes low-cost Edge-processing, high-fidelity mmWave sensing (HLK-LD2410B), and Universal IR/RF mimicry to create an adaptive energy environment. By detecting micro-vibrations (like human breathing) locally on ESP32 hubs, the system autonomously cuts standby "ghost power" via smart relays and manages legacy HVAC systems without expensive retrofits. Paired with an intuitive Flutter application for real-time ESG impact tracking and dynamic zone control, EcoMesh delivers a highly viable, RM 100-per-room solution to smart energy management.

## Introduction
As urbanization accelerates and energy demands rise across Malaysia, it has become clear that current infrastructure treats buildings as static energy consumers rather than adaptive systems. While the market offers basic energy-saving solutions, they heavily rely on manual scheduling, traditional motion sensors with limited accuracy, or centralized cloud controls. These legacy approaches consistently fail because energy waste is fundamentally a behavioral and spatial problem—cooling systems and lights are left running because current systems cannot accurately adapt to the nuances of real human behavior.

Addressing the Technothon 2026 theme of "Smart Energy Management for a Sustainable Future," EcoMesh introduces a paradigm shift. We reframe buildings from passive structures into dynamic energy ecosystems. By shifting the burden of energy management from the human to an intelligent environment, power distribution continuously and autonomously adapts to human presence, intention, and predicted usage patterns.

## Problem Statement
Massive amounts of electricity are wasted daily in Malaysia due to inefficient energy usage practices in both residential and commercial spaces. The core issues include:

* **Behavioral Neglect:** Lights, air-conditioning, and appliances are frequently left running in empty rooms. Standard motion sensors often fail to detect stationary users (such as students studying or staff typing), creating "environmental friction" that leads users to disable automation.
* **Standby Waste:** "Ghost power" is continuously drawn by idle devices like monitors and chargers.
* **Inflexible Infrastructure:** Centralized HVAC and lighting systems lack the granular intelligence to adapt to micro-occupancy, leading to cooling or lighting vast empty spaces. Also, true smart homes are cost-prohibitive and require extensive wiring modifications, making them impractical for the majority of students, renters, and legacy office spaces.

## Hypothesis / Objectives

### Hypothesis
By implementing high-fidelity spatial detection and edge-based predictive AI, we can fully automate power control and eliminate "ghost" power waste, adapting to individual user behaviors seamlessly.

### Objectives
* **Occupancy & Spatial Detection:** Utilize advanced mmWave radar and BLE to identify real-time human presence (down to micro-vibrations like breathing).
* **Automated Power Control:** Execute rule-based automation to manage lighting and HVAC systems efficiently.
* **Hardware-Software Integration:** Connect physical devices through a decentralized mesh network to a real-time tracking platform.
* **Scalability & Retrofitting:** Ensure the solution is cost-effective and easily deployable in existing infrastructure without massive renovations.

## Existing Solutions & Gaps

### Building Energy Management Systems (BEMS)
*(e.g. Schneider Electric EcoStruxure, Siemens Desigo CC, Honeywell Building Management Systems, Johnson Controls OpenBlue)*

**STRENGTHS**
Integrate sensors, automation, and analytics to monitor and control:
* HVAC systems
* Lighting usage
* Electrical consumption
* Facility operations

These platforms collect real-time building data and automatically optimize energy usage to reduce operational costs and emissions. Research shows BEMS platforms improve efficiency through real-time monitoring and automated adjustment of energy-consuming systems.

**LIMITATIONS**
* Infrastructure-heavy
* Require expensive retrofitting
* Only viable for large commercial buildings
* Centralized Control: Managed by facility operators, not users or communities
* No Behavioral Intelligence: Optimizes machines, not human habits
* Not Community-Integrated: Buildings operate independently instead of forming energy ecosystems

### Smart Home Energy Systems
*(e.g. Google Nest, Ecobee, Tesla Powerwall ecosystem)*

**STRENGTHS**
* Automated temperature optimization
* Energy usage tracking
* Remote control through mobile apps
* Basic AI learning of user preferences
They successfully bring energy awareness to households.

**LIMITATIONS**
* Individual Optimization Only
* Homes act independently
* No shared optimization across neighborhoods
* Limited AI Intelligence: Reactive learning instead of predictive ecosystem modeling
* No Urban Resilience Integration: Cannot respond to climate risks, outages, or infrastructure stress
* Fragmented Platforms: Devices from different vendors rarely communicate seamlessly

## Research Data / User Insights
To ensure high adoption, EcoMesh is designed with strong user co-creation and ethical considerations:

**Occupancy Mismatch as a Primary Cause of Energy Waste**
* Buildings consume energy even when spaces are unoccupied. (Source 1)
* Occupant behaviour is one of the largest contributors to energy variability in buildings.
* Occupancy-based controls show 35.5% potential energy savings.
* Lighting energy can be reduced by ≈30%, and HVAC energy by ≈20% when systems respond to real occupancy instead of fixed schedule (Source 2)
* Energy systems are typically designed assuming maximum occupancy, but real occupancy fluctuates continuously, causing rooms to consume electricity despite being empty for long periods. (Source 3)
* 56% of total building energy consumption occurred during non-working hours, mainly because lights and equipment were left running after occupants left. (Source 4 - Malaysian Context Evidence)
* Actual energy usage significantly exceeds predicted performance, largely due to operational behaviour and occupancy factors.
* **EcoMesh’s dynamic smart-zoning directly addresses this scientifically proven “occupancy mismatch”.**

**Students Leaving AC Running Between Classes**
* HVAC systems are among the largest energy consumers in buildings. (Source 5)
* 8–10% cooling energy savings, simply by matching operation to presence data. (Source 6)
* AI occupancy prediction could reduce HVAC energy use by up to 50% compared to rule-based control systems.
* **EcoMesh enables real-time autonomous control, not just prediction.**

**Privacy & Ethics — Edge-AI and Transport Encryption**
* (Source 7) Occupancy data is difficult to deploy at scale due to privacy concerns and data limitations because centralised cloud monitoring introduces risks: surveillance concerns, data misuse, low user adoption.
* EcoMesh guarantees privacy through a two-fold strategy:
  1. **Data Minimization at the Edge:** EcoMesh processes sensor data locally using Edge-AI hubs. Raw sensor signals (movement vectors, exact coordinates) never leave the building and are destroyed locally. Only anonymized, non-identifying binary states (Occupied/Empty) are transmitted. 
  2. **MQTTS Transport Encryption:** The anonymized telemetry is transmitted using MQTTS (MQTT over TLS/SSL) with device-specific cryptographic certificates. This ensures military-grade transport encryption and prevents command spoofing, making the data pipeline exceptionally secure.

**User Pain Points**
* (Source 8) People forget to turn devices off: Behavioral studies show occupant actions strongly influence building energy performance and often cause the gap between designed and actual efficiency.
* (Source 9) Buildings Operate on Static Schedules: Research demonstrates many buildings still run systems on fixed schedules rather than real usage, creating significant waste opportunities.
* (Source 10) Users Lack Visibility into Energy Impact: Energy audits reveal organizations often know their electricity bills but lack understanding of where energy is actually wasted, limiting behavioral change.

**Inclusivity & Accessibility Benefits**
Smart environment automation research highlights that automated environmental control systems:
* reduce physical interaction requirements,
* improve accessibility for elderly and mobility-impaired users,
* support independent living environments.

**Why this matters:**
Traditional energy control assumes users can: walk to switches, adjust thermostats, manually manage appliances.
EcoMesh removes these physical barriers by enabling: automatic lighting activation, climate adjustment without movement, personalized environmental automation.

## Solution Overview

**A. Hardware & Perception Layer (The "Nerves")**
* **High-Fidelity Perception:** Moving beyond traditional PIR sensors that fail when users sit still, EcoMesh utilizes low-cost HLK-LD2410B mmWave Radar paired with ESP32-C3 SuperMini nodes. This allows the system to pass the "Breathing Test"—detecting micro-vibrations locally at the edge. The space remains intelligently active even if a user is completely motionless while studying or coding.
* **Ground-Truth Energy Monitoring:** Instead of guessing power consumption, the system integrates the PZEM-004T V3.0 energy monitor to capture reliable, real-time telemetry data for connected devices.

**B. Control & Execution Layer (The "Muscle")**
* **Zero-Barrier Universal Retrofit:** The ESP32-S3 gateway hub features an integrated IR/RF (433MHz) transceiver with a local "Learning Mode." Instead of searching for complex appliance codes, users simply point their legacy remote at the hub to clone commands (e.g., Power On, 24°C). The system instantly decodes and maps these signals to automation triggers, allowing EcoMesh to seamlessly control existing "dumb" ACs and fans without physical rewiring.
* **Active Hardware Control:** An integrated 4-Channel Relay physically switches power on our custom smart strip. When the mmWave sensor detects a vacated room, the relay physically cuts the circuit to idle monitors and chargers, actively killing "ghost power."

**C. Data & Artificial Intelligence Layer (The "Brain")**
* **Simulated Predictive Analytics:** To demonstrate long-term scalability, the system's architecture accounts for predictive demand. Our prototype utilizes a backend Machine Learning engine (Random Forest) showcasing how historical occupancy and real-time power draw (via the PZEM module) map against predictive curves to autonomously pre-cool zones or shift energy loads.
* **Flexible Two-Tier Architecture:** To accommodate different privacy requirements, EcoMesh supports dual deployment models. Consumer environments can utilize a Cloud-hosted backend. Conversely, Enterprise/Campus environments can host the MQTT Broker, databases, and FastAPI backend entirely **On-Premises**, ensuring organizational data never touches the public internet.

**D. User Experience & Orchestration (The "Experience")**
* **Intelligent Software Orchestration:** A clean, minimal Flutter app serves as the command center. Users complete a rapid onboarding flow to select an "Energy Persona" (e.g., Deep Worker, Eco-Warrior) which automatically sets their baseline comfort presets. During initial setup, the app guides users through an Interactive IR Pairing Flow—prompting them to press specific buttons on their physical remotes to teach the EcoMesh hub the necessary commands for that specific zone.
* **Dual-Layer Proximity & Follow-Me Profiles:** The app features an interactive floor plan where users can virtually "claim" a desk, instantly applying their persona presets to that physical zone. A simulated "Away Mode" demonstrates how GPS/BLE geofencing will trigger power-down sequences seamlessly as the user leaves the facility.

## Innovation / Uniqueness

**1. Innovation in User Experience: The "Follow-Me" Energy Paradigm**
Current smart buildings rely on rigid schedules managed by facility operators. EcoMesh hands control back to the user through dynamic "Follow-Me" Profiles. Demonstrated via our Flutter app's intuitive UI, users can claim specific physical outlets. The system dynamically inherits their personal logic (temperature preference, lighting) for that specific zone, bridging the gap between digital preferences and physical hardware.

**2. Innovation in Methodology: The Edge-Triggered "Ghost Power Hunter"**
Most energy-saving systems stop at turning off the lights. EcoMesh targets standby electricity waste from plugged-in devices. By pairing highly sensitive mmWave radar with physical 4-channel relays, the system doesn't just guess when to turn off a monitor—it knows precisely when human presence has left the micro-zone and physically severs the power connection to eliminate standby draw entirely.

**3. Innovation in Scalability: Hyper-Affordable Retrofitting**
Directly answering the demand for Solution Viability, EcoMesh proves that smart infrastructure doesn't require massive budgets. By utilizing an integrated IR receiver to "clone" commands from existing remotes, and transmitting via IR/RF mimicry to control "dumb" appliances, the solution avoids massive setup friction. Building sensor nodes for under RM 30 (ESP32-C3 + LD2410B) makes the solution hyper-scalable. It can be immediately deployed in aging university facilities or commercial offices with zero invasive rewiring and minimal technical configuration.

## Value Proposition & Impact

**1. Economic Viability & Rapid ROI**
Directly addressing the need for cost-effective scalability, EcoMesh eliminates the financial barriers typically associated with smart building upgrades.
* **Ultra-Low BOM:** With sensor nodes costing ~RM 28.50 and Master Hubs ~RM 100, the hardware pays for itself in months, not years.
* **Direct Cost Reduction:** By actively physically cutting standby "ghost power" and optimizing HVAC runtimes based on flawless mmWave occupancy data, facilities can realize instant operational savings without replacing a single legacy appliance.

**2. Environmental Sustainability**
EcoMesh actively combats the urgent problem of electricity waste driven by "occupancy mismatch."
* **Carbon Footprint Reduction:** By ensuring power is dynamically allocated only when human presence justifies it, the system significantly cuts unnecessary carbon emissions linked to idle lighting and air-conditioning.
* **Data Consistency:** Real-time power monitoring (PZEM-004T) ensures environmental impact reports are based on verifiable data, not rough estimates.

**3. Social Impact & Behavioral Transformation**
Beyond hardware automation, EcoMesh acts as a behavioral intervention tool designed for maximum Deployability.
* **Gamified ESG Dashboard:** The Flutter application translates raw telemetry data into tangible, gamified metrics—showing users exactly how much money they saved and representing carbon offsets visually (e.g., "Trees Saved").
* **Inclusive Automation:** Traditional energy control requires physical mobility to reach switches or thermostats. EcoMesh removes these physical barriers entirely. The fully automated mmWave detection ensures the system is accessible and seamless for users of all physical mobility levels, simply adapting to their presence.

## Implementation Plan / Roadmap

**Phase 1: Hardware Validation & Edge Logic (The Prototype)**
* **Objective:** Establish the physical perception and control layer.
* **Milestones:**
  * Assemble the "Smart Strip" using the ESP32-S3 hub and integrate the 4-channel relays.
  * Validate the HLK-LD2410B mmWave sensor to successfully pass the "Breathing Test" (keeping a localized desk lamp powered while a user sits perfectly still, and instantly cutting power upon exit).
  * Program and test the onboard IR Receiver/Transmitter loop: successfully record, decode, store, and re-transmit IR signals to mimic commands for a legacy "dumb" fan or AC unit.

**Phase 2: Software Orchestration & UX Design (The App Integration)**
* **Objective:** Deliver the user-facing command center to demonstrate the "Follow-Me" paradigm.
* **Milestones:**
  * Finalize the Flutter mobile application with the personalized onboarding flow (Energy Personas).
  * Establish local telemetry communication (MQTTS/WebSockets) between the ESP32 hubs and the app to display live power draw (via the PZEM-004T) on the ZoneStatusCard.
  * Implement simulated UI states for the predictive pre-cooling and GPS "Away Mode" geofencing to demonstrate the final user journey during the pitch.

**Phase 3: Controlled Pilot & Validation (Real-World Deployment)**
* **Objective:** Prove the economic viability and calculate exact ROI.
* **Milestones:**
  * Deploy the zero-barrier retrofitted system in a controlled environment (such as a university study room or small commercial office).
  * Run the system in "Monitor-Only" mode for one week to establish a baseline, then switch to "Active EcoMesh" mode.
  * Use the ground-truth data from the PZEM-004T to generate a comparative ESG report, validating our hypothesis of a 15–25% reduction in monthly electricity costs and proving the sub-9-month ROI.

## Challenges & Risk Mitigation

| Category | Challenge / Risk | Mitigation Strategy |
| :--- | :--- | :--- |
| **Technical Reliability** | RF/IR signal interference or failed command execution when attempting to control legacy HVAC systems or fans. | **Redundant Burst Transmission:** Because we cannot directly monitor the AC's mains power, the ESP32 utilizes a "burst" strategy, transmitting the RMT pulse train three times in quick succession to guarantee delivery. Additionally, the Flutter app allows users to manually trigger a "State Resync" if physical reality mismatches the digital dashboard. |
| **Technical Complexity** | AC remotes transmit their full device state (Temp, Fan, Mode) in massive, complex IR pulse trains, making standard signal decoding difficult. | **Native RMT Capture (ESP-IDF):** We bypass software decoding by utilizing the ESP32’s native RMT hardware peripheral. The system simply records and replays the raw IR pulse timings for baseline states (e.g., "24°C On" and "Off"), ensuring universal compatibility without device-specific libraries. |
| **Hardware Cost & Scalability** | Prohibitive costs of traditional high-fidelity smart building sensors and expensive infrastructure retrofits. | **Ultra-Low-Cost BOM Integration:** Avoided expensive commercial sensors by validating the highly affordable HLK-LD2410B mmWave radar (~RM 16.50) paired with ESP32-C3 nodes. This drastically reduces the per-room cost to under RM 100, ensuring immediate financial viability for campus-wide scaling. |
| **Privacy & Ethics** | User resistance and privacy concerns regarding continuous spatial monitoring and tracking in private areas. | **100% Edge-Processed Privacy & MQTTS:** No cameras or microphones are used. The mmWave micro-vibration data is processed locally on the ESP32 hubs, destroying raw signatures at the edge. The resulting binary states are transmitted securely using MQTTS encryption to guarantee payload privacy. |
| **System Resilience** | Campus Wi-Fi network instability or cloud server downtime causing automation failures and dead zones. | **Local-First Execution:** While the system syncs with the Flutter app via standard protocols, the core "Ghost Power Hunter" logic is hardcoded into the ESP32 edge hubs. If the external network or Central Server drops, the nodes continue to independently monitor presence and physically switch relays without disruption. |

## Conclusion
True environmental sustainability cannot rely on users constantly remembering to flip a switch. EcoMesh removes this behavioral friction entirely by introducing a comprehensive, highly original energy mesh that autonomously adapts to human presence. By synthesizing advanced mmWave perception, local Edge-AI load monitoring, and universal retrofitting, we empower existing infrastructure to think for itself. EcoMesh doesn't just cut "ghost power" and reduce Malaysia's energy waste; it creates a user-centric, ethically sound environment where energy effortlessly follows intention, proving that the smartest buildings are the ones that adapt to us.
