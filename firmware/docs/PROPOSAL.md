Project Proposal: EcoMesh
Subtitle: A Low-Cost, Universal Gateway for Personalized Energy Environments
Abstract / Executive Summary
EcoMesh is an intelligent, decentralized energy management framework designed to tackle Malaysia's massive electricity waste in residential and commercial spaces. Moving beyond static automation, EcoMesh utilizes Edge-AI, high-fidelity mmWave sensing, and Bluetooth mesh networking to create a novel "Follow-Me" energy paradigm. The system dynamically allocates power based on real-time human presence and predictive analytics, proactively eliminating standby "ghost" power usage without requiring user intervention. By integrating automated legacy appliance control with live cost and carbon footprint tracking, EcoMesh directly fulfills the Technothon 2026 mission by delivering a scalable, user-centric, and highly sustainable solution to intelligent electricity usage. 
Introduction
As urbanization accelerates and energy demands rise across Malaysia, it has become clear that current infrastructure treats buildings as static energy consumers rather than adaptive systems. While the market offers basic energy-saving solutions, they heavily rely on manual scheduling, traditional motion sensors with limited accuracy, or centralized cloud controls. These legacy approaches consistently fail because energy waste is fundamentally a behavioral and spatial problem—cooling systems and lights are left running because current systems cannot accurately adapt to the nuances of real human behavior.
Addressing the Technothon 2026 theme of "Smart Energy Management for a Sustainable Future," EcoMesh introduces a paradigm shift. We reframe buildings from passive structures into dynamic energy ecosystems. By shifting the burden of energy management from the human to an intelligent environment, power distribution continuously and autonomously adapts to human presence, intention, and predicted usage patterns.
Problem Statement
Massive amounts of electricity are wasted daily in Malaysia due to inefficient energy usage practices in both residential and commercial spaces. The core issues include:
Behavioral Neglect: Lights, air-conditioning, and appliances are frequently left running in empty rooms. Standard motion sensors often fail to detect stationary users (such as students studying or staff typing), creating "environmental friction" that leads users to disable automation.
Standby Waste: "Ghost power" is continuously drawn by idle devices like monitors and chargers.
Inflexible Infrastructure: Centralized HVAC and lighting systems lack the granular intelligence to adapt to micro-occupancy, leading to cooling or lighting vast empty spaces. Also, true smart homes are cost-prohibitive and require extensive wiring modifications, making them impractical for the majority of students, renters, and legacy office spaces.
Hypothesis / Objectives
HYPOTHESIS
By implementing high-fidelity spatial detection and edge-based predictive AI, we can fully automate power control and eliminate "ghost" power waste, adapting to individual user behaviors seamlessly.
OBJECTIVES
Occupancy & Spatial Detection: Utilize advanced mmWave radar and BLE to identify real-time human presence (down to micro-vibrations like breathing).
Automated Power Control: Execute rule-based automation to manage lighting and HVAC systems efficiently.
Hardware-Software Integration: Connect physical devices through a decentralized mesh network to a real-time tracking platform.
Scalability & Retrofitting: Ensure the solution is cost-effective and easily deployable in existing infrastructure without massive renovations.
Existing Solutions & Gaps
Building Energy Management Systems (BEMS) 
(e.g. Schneider Electric EcoStruxure, Siemens Desigo CC, Honeywell Building Management Systems, Johnson Controls OpenBlue)
STRENGTHS
Integrate sensors, automation, and analytics to monitor and control:
HVAC systems
Lighting usage
Electrical consumption
Facility operations
These platforms collect real-time building data and automatically optimize energy usage to reduce operational costs and emissions.
Research shows BEMS platforms improve efficiency through real-time monitoring and automated adjustment of energy-consuming systems.
LIMITATIONS
Infrastructure-heavy
Require expensive retrofitting
Only viable for large commercial buildings
Centralized Control: Managed by facility operators, not users or communities
No Behavioral Intelligence: Optimizes machines, not human habits
Not Community-Integrated: Buildings operate independently instead of forming energy ecosystems
Smart Home Energy Systems 
(e.g. Google Nest, Ecobee, Tesla Powerwall ecosystem)
STRENGTHS
Automated temperature optimization
Energy usage tracking
Remote control through mobile apps
Basic AI learning of user preferences
They successfully bring energy awareness to households.
LIMITATIONS
Individual Optimization Only
Homes act independently
No shared optimization across neighborhoods
Limited AI Intelligence: Reactive learning instead of predictive ecosystem modeling
No Urban Resilience Integration: Cannot respond to climate risks, outages, or infrastructure stress
Fragmented Platforms: Devices from different vendors rarely communicate seamlessly
Research Data / User Insights
To ensure high adoption, EcoMesh is designed with strong user co-creation and ethical considerations:
Occupancy Mismatch as a Primary Cause of Energy Waste 
Buildings consume energy even when spaces are unoccupied. 
Source 1
Occupant behaviour is one of the largest contributors to energy variability in buildings.
Occupancy-based controls show 35.5% potential energy savings.
Lighting energy can be reduced by ≈30%, and HVAC energy by ≈20% when systems respond to real occupancy instead of fixed schedule
Source 2
Energy systems are typically designed assuming maximum occupancy, but real occupancy fluctuates continuously, causing rooms to consume electricity despite being empty for long periods.
Source 3
56% of total building energy consumption occurred during non-working hours, mainly because lights and equipment were left running after occupants left. 
Source 4 (Malaysian Context Evidence)
Actual energy usage significantly exceeds predicted performance, largely due to operational behaviour and occupancy factors.
EcoMesh’s dynamic smart-zoning directly addresses this scientifically proven “occupancy mismatch”. 
Students Leaving AC Running Between Classes 
HVAC systems are among the largest energy consumers in buildings. 
Source 5
8–10% cooling energy savings, simply by matching operation to presence data. 
Source 6
AI occupancy prediction could reduce HVAC energy use by up to 50% compared to rule-based control systems. 
EcoMesh enables real-time autonomous control, not just prediction. 
Privacy & Ethics — Edge AI Processing 
Source 7
Occupancy data is difficult to deploy at scale due to privacy concerns and data limitations because centralised cloud monitoring introduces risks:
surveillance concerns
data misuse
low user adoption
EcoMesh processes sensor data locally using Edge-AI hubs:
Raw sensor signals never leave the building.
Only anonymized occupancy states are transmitted.
User Pain Points 
Source 8
People forget to turn devices off: Behavioral studies show occupant actions strongly influence building energy performance and often cause the gap between designed and actual efficiency. 
Source 9
Buildings Operate on Static Schedules: Research demonstrates many buildings still run systems on fixed schedules rather than real usage, creating significant waste opportunities.
Source 10
Users Lack Visibility into Energy Impact: Energy audits reveal organizations often know their electricity bills but lack understanding of where energy is actually wasted, limiting behavioral change. 
Inclusivity & Accessibility Benefits 
Smart environment automation research highlights that automated environmental control systems:
reduce physical interaction requirements,
improve accessibility for elderly and mobility-impaired users,
support independent living environments.
Why this matters:
Traditional energy control assumes users can:
walk to switches,
adjust thermostats,
manually manage appliances.
EcoMesh removes these physical barriers by enabling:
automatic lighting activation,
climate adjustment without movement,
personalized environmental automation.
Solution Overview 
A. Hardware & Perception Layer (The "Nerves")
High-Fidelity Perception: Utilizing distributed, battery-operated Nordic nRF52840 nodes, EcoMesh solves the traditional "stillness" problem. Advanced mmWave Radar constantly monitors for micro-vibrations (such as human breathing) to capture flawless occupancy data, ensuring user environments remain active even when they are perfectly motionless.
Decentralized Connectivity: Nodes communicate via Bluetooth Mesh, effortlessly passing data through thick concrete walls and avoiding the dead zones or complex cabling associated with Wi-Fi.
B. Control & Execution Layer (The "Muscle")
Zone Hubs & Universal Retrofit: ESP32 DevKit V1 hubs act as the mesh gateways. They utilize a Universal Actuation feature, cloning IR and RF signals (433MHz/315MHz) to mimic existing remotes. This allows EcoMesh to control legacy, "dumb" air-conditioners and ceiling fans without requiring any physical rewiring or hardware replacements.
Active Hardware Control: Integrated 4-Channel Relays physically switch power on smart strips, while an Active Endpoint Sync uses Bluetooth HID protocols to automatically send "Sleep" commands to laptops when a user exits the space.
C. Data & Artificial Intelligence Layer (The "Brain")
Edge-AI & The "Ghost Power Hunter": Moving beyond basic IF/THEN automation, the ESP32 hubs run local Edge-AI logic to perform real-time Non-Intrusive Load Monitoring (NILM). This machine learning technique identifies specific appliance power "signatures," allowing the system to autonomously detect and kill standby "ghost power" to monitors and chargers the moment a zone is vacated.
Predictive Optimization Engine: A Python/Pandas backend analytics engine conducts continuous demand forecasting. By correlating historical occupancy and energy draw data with external integrations (like the MetMalaysia weather API and TNB tariff API), the system predicts usage spikes and autonomously pre-optimizes HVAC systems (e.g., pre-cooling a specific office zone efficiently before a hot Friday afternoon).
D. User Experience & Orchestration (The "Experience")
Intelligent Software Orchestration: A React Native/Flutter app serves as the command center. Users utilize “Virtual Mapping” to "claim" specific outlets and define environmental presets (e.g., "Deep Work" or "Meeting"). 
Dual-Layer Proximity & Follow-Me Profiles: The application uses Dual-Layer Proximity—GPS Geofencing for macro-level building arrival triggers, and BLE RSSI positioning for micro-level room precision. As the user moves through the building, their personalized Follow-Me Energy Profile transitions with them via BLE tracking, instantly adapting the new zone to their presets while powering down the vacated zone.
Innovation / Uniqueness
1. Innovation in User Experience: The "Follow-Me" Energy Paradigm Current smart buildings rely on rigid, room-based schedules or manual switches. EcoMesh introduces dynamic "Follow-Me" Profiles. By utilizing a novel Dual-Layer Proximity system (GPS Geofencing for macro-level building entry and BLE Mesh for micro-level room precision), the building's environment adapts fluidly to the user's movement. Furthermore, through Virtual Mapping, users can "claim" specific physical outlets via the app, allowing the hardware to dynamically inherit their personal logic and preferences wherever they sit.
2. Innovation in Methodology: The Edge-AI "Ghost Power Hunter" Most energy-saving systems use basic PIR motion sensors that only trigger lighting. EcoMesh targets a deeply ignored problem: standby electricity waste from plugged-in devices. By deploying real-time Non-Intrusive Load Monitoring (NILM) locally on edge devices (ESP32), the system autonomously identifies appliance power "signatures". Doing this on the edge rather than the cloud not only reduces latency but ensures high data privacy, a key ethical consideration for continuous spatial monitoring. This allows the Ghost Power Hunter logic to proactively cut power to sleeping laptops, monitors, and chargers the moment a user vacates a zone. Doing this on the edge rather than the cloud also ensures high data privacy, a key ethical consideration.
3. Innovation in Scalability: Zero-Barrier Universal Retrofitting A major hurdle in energy management is the high cost of replacing existing appliances. Directly answering the hackathon's call for "Scalability & Retrofitting," EcoMesh eliminates the need for expensive "smart" appliances or complex rewiring. By using our hubs to mimic IR and RF (433MHz/315MHz) signals, the system brings modern, automated intelligence to legacy "dumb" devices like older air-conditioners, motorized blinds, and BLDC ceiling fans. This makes the solution hyper-scalable, highly affordable, and immediately deployable in any existing residential or commercial space.
Value Proposition & Impact
Economic Viability & Rapid ROI Directly addressing the need for cost-effective scalability, EcoMesh eliminates the financial barriers typically associated with smart building upgrades.
Zero-Barrier Retrofitting: Because the system uses universal actuators (IR/RF mimicry) to control existing "dumb" infrastructure, it is exceptionally retrofit-friendly and requires zero invasive rewiring or expensive appliance replacements.
Rapid Payback Period: The integration of affordable hardware (like ESP32 hubs) combined with zero installation fees results in an estimated payback period of under 9 months.
Direct Cost Reduction: By actively hunting and eliminating standby "ghost power" and optimizing HVAC runtime, the system generates estimated monthly energy savings of 15% to 25% (approximately RM 29.00 per room), drastically lowering operational costs for commercial and residential facility managers.
2. Environmental Sustainability EcoMesh actively combats the urgent, high-impact problem of Malaysia's electricity waste driven by rapid urbanization.
Carbon Footprint Reduction: By ensuring power is dynamically allocated only when human presence justifies it, the system significantly cuts unnecessary carbon emissions linked to idle lighting and air-conditioning.
Grid Optimization: The predictive modeling engine (forecasting usage via weather APIs) and active load reduction help lower peak electricity demand, supporting Malaysia's broader goals for sustainable urban growth and infrastructure resilience.
3. Social Impact & Behavioral Transformation Beyond hardware automation, EcoMesh acts as a behavioral intervention tool. It drives long-term adoption by converting abstract sustainability metrics into visible, personal rewards.
Gamified Awareness: The EcoMesh Management Dashboard visualizes energy savings dynamically, translating raw kWh data into tangible metrics like exact financial savings (Ringgit Malaysia) and relatable environmental impact (e.g., "You saved 2 trees this week").
Community Ownership & Inclusivity: By providing users with transparent "Cost & Impact Tracking" on their smartphones, EcoMesh encourages conscious, sustainable habits without sacrificing personal comfort. Furthermore, the fully automated "Follow-Me" profiles ensure that the system is inclusive and accessible, functioning seamlessly for users of all technical backgrounds or physical mobility levels.
Implementation Plan / Roadmap
Prototype Phase: Deliver a working "Smart Strip" controlled by an ESP32 responding to Nordic mmWave sensors, capable of passing the "Breathing Test" (keeping a lamp on while a user sits still, and cutting it upon exit).
Integration Phase: Finalize the App Journey, connecting GPS geofencing triggers to zone arrival, personalized configurations, and savings reports.
Deployment Phase: Utilize EcoMesh's easy retrofitting capabilities to pilot the system in a commercial office space, validating energy savings and cost tracking without major building modifications.
Challenges & Risk Mitigation
Category
Challenge / Risk
Mitigation Strategy
Technical Reliability
RF/IR signal interference or failed command execution when controlling legacy HVAC systems.
Implement power-draw feedback loops at the Smart Strip level. If an IR command is issued but no expected power change is detected, the system automatically retries the command or flags an anomaly for diagnostics.
Hardware Cost & Scalability
High deployment cost of mmWave radar sensors.
Deploy mmWave sensors only in high-value Zone Hubs requiring precise occupancy detection, while using low-cost BLE beaconing in transitional areas such as hallways and walkways to maintain scalability.
Privacy & Ethics
User concerns about occupancy tracking and surveillance.
Utilize Edge-AI processing where all sensor data is processed locally on ESP32 hubs. No cameras, facial recognition, or identifiable cloud data storage are used, ensuring privacy-preserving operation.
System Resilience
Network instability or node failure causing system disruption.
Employ a decentralized Bluetooth Mesh architecture allowing nodes to self-heal; if one node fails or disconnects, remaining nodes automatically reroute communication to maintain system continuity.

Conclusion
True environmental sustainability cannot rely on users constantly remembering to flip a switch. EcoMesh removes this behavioral friction entirely by introducing a comprehensive, highly original energy mesh that autonomously adapts to human presence. By synthesizing advanced mmWave perception, local Edge-AI load monitoring, and universal retrofitting, we empower existing infrastructure to think for itself. EcoMesh doesn't just cut "ghost power" and reduce Malaysia's energy waste; it creates a user-centric, ethically sound environment where energy effortlessly follows intention, proving that the smartest buildings are the ones that adapt to us.  
