// Mock Data Models & JSON

class UserProfile {
  final String name;
  final String persona;
  final double tempPreference;
  final int standbyTimeout;
  final double todaySaved;
  final double weekSaved;
  final double carbonOffset;
  final int treesEquivalent;
  final String currentZone;
  final bool isHome;

  const UserProfile({
    required this.name,
    required this.persona,
    required this.tempPreference,
    required this.standbyTimeout,
    required this.todaySaved,
    required this.weekSaved,
    required this.carbonOffset,
    required this.treesEquivalent,
    required this.currentZone,
    required this.isHome,
  });
}

class Zone {
  final String id;
  final String name;
  final String floor;
  final bool isOccupied;
  final bool isPrecooling;
  final double temperature;
  final double targetTemp;
  final double energyDraw; // watts
  final int occupancyCount;
  final String status; // 'active', 'idle', 'ghost', 'off'
  final List<Desk> desks;

  const Zone({
    required this.id,
    required this.name,
    required this.floor,
    required this.isOccupied,
    required this.isPrecooling,
    required this.temperature,
    required this.targetTemp,
    required this.energyDraw,
    required this.occupancyCount,
    required this.status,
    required this.desks,
  });
}

class Desk {
  final String id;
  final String label;
  bool isClaimed;
  String? claimedBy;
  bool isPowered;
  final double x; // position on floor map (0-1)
  final double y;

  Desk({
    required this.id,
    required this.label,
    required this.isClaimed,
    this.claimedBy,
    required this.isPowered,
    required this.x,
    required this.y,
  });
}

class EnergyReading {
  final DateTime time;
  final double actual;
  final double predicted;

  const EnergyReading({
    required this.time,
    required this.actual,
    required this.predicted,
  });
}

class Notification {
  final String id;
  final String title;
  final String body;
  final String type; // 'arrival', 'saving', 'warning', 'summary'
  final DateTime timestamp;
  final bool isRead;

  const Notification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    required this.isRead,
  });
}

// ──────────────────────────────
// MOCK DATA
// ──────────────────────────────

final mockUser = UserProfile(
  name: 'Ahmad Fariz',
  persona: 'Deep Worker',
  tempPreference: 24.0,
  standbyTimeout: 2,
  todaySaved: 1.2,
  weekSaved: 8.7,
  carbonOffset: 4.35,
  treesEquivalent: 2,
  currentZone: 'Zone B',
  isHome: true,
);

final mockZones = [
  Zone(
    id: 'zone-a',
    name: 'Zone A',
    floor: 'Level 2',
    isOccupied: false,
    isPrecooling: false,
    temperature: 28.0,
    targetTemp: 26.0,
    energyDraw: 42.0,
    occupancyCount: 0,
    status: 'idle',
    desks: [
      Desk(id: 'a1', label: 'A-01', isClaimed: false, isPowered: false, x: 0.2, y: 0.3),
      Desk(id: 'a2', label: 'A-02', isClaimed: false, isPowered: false, x: 0.4, y: 0.3),
      Desk(id: 'a3', label: 'A-03', isClaimed: false, isPowered: true, x: 0.6, y: 0.3),
      Desk(id: 'a4', label: 'A-04', isClaimed: false, isPowered: false, x: 0.2, y: 0.65),
    ],
  ),
  Zone(
    id: 'zone-b',
    name: 'Zone B',
    floor: 'Level 2',
    isOccupied: true,
    isPrecooling: false,
    temperature: 24.0,
    targetTemp: 24.0,
    energyDraw: 318.0,
    occupancyCount: 7,
    status: 'active',
    desks: [
      Desk(id: 'b1', label: 'B-01', isClaimed: true, claimedBy: 'Ahmad Fariz', isPowered: true, x: 0.2, y: 0.25),
      Desk(id: 'b2', label: 'B-02', isClaimed: true, claimedBy: 'Siti Noor', isPowered: true, x: 0.5, y: 0.25),
      Desk(id: 'b3', label: 'B-03', isClaimed: true, claimedBy: 'Raj Kumar', isPowered: true, x: 0.78, y: 0.25),
      Desk(id: 'b4', label: 'B-04', isClaimed: false, isPowered: false, x: 0.2, y: 0.6),
      Desk(id: 'b5', label: 'B-05', isClaimed: true, claimedBy: 'Wei Lin', isPowered: true, x: 0.5, y: 0.6),
      Desk(id: 'b6', label: 'B-06', isClaimed: false, isPowered: true, x: 0.78, y: 0.6),
    ],
  ),
  Zone(
    id: 'zone-c',
    name: 'Zone C – Meeting',
    floor: 'Level 2',
    isOccupied: false,
    isPrecooling: true,
    temperature: 26.5,
    targetTemp: 23.0,
    energyDraw: 85.0,
    occupancyCount: 0,
    status: 'ghost',
    desks: [
      Desk(id: 'c1', label: 'C-01', isClaimed: false, isPowered: false, x: 0.3, y: 0.4),
      Desk(id: 'c2', label: 'C-02', isClaimed: false, isPowered: false, x: 0.7, y: 0.4),
    ],
  ),
  Zone(
    id: 'zone-d',
    name: 'Zone D – Lab',
    floor: 'Level 3',
    isOccupied: true,
    isPrecooling: false,
    temperature: 22.5,
    targetTemp: 22.0,
    energyDraw: 520.0,
    occupancyCount: 4,
    status: 'active',
    desks: [
      Desk(id: 'd1', label: 'D-01', isClaimed: true, claimedBy: 'Lim Boon', isPowered: true, x: 0.25, y: 0.3),
      Desk(id: 'd2', label: 'D-02', isClaimed: true, claimedBy: 'Priya S.', isPowered: true, x: 0.55, y: 0.3),
      Desk(id: 'd3', label: 'D-03', isClaimed: false, isPowered: false, x: 0.25, y: 0.65),
      Desk(id: 'd4', label: 'D-04', isClaimed: true, claimedBy: 'Hafiz M.', isPowered: true, x: 0.55, y: 0.65),
    ],
  ),
];

final mockEnergyReadings = [
  EnergyReading(time: DateTime(2025, 1, 13, 8), actual: 120, predicted: 130),
  EnergyReading(time: DateTime(2025, 1, 13, 9), actual: 280, predicted: 260),
  EnergyReading(time: DateTime(2025, 1, 13, 10), actual: 410, predicted: 390),
  EnergyReading(time: DateTime(2025, 1, 13, 11), actual: 520, predicted: 500),
  EnergyReading(time: DateTime(2025, 1, 13, 12), actual: 350, predicted: 380),
  EnergyReading(time: DateTime(2025, 1, 13, 13), actual: 290, predicted: 320),
  EnergyReading(time: DateTime(2025, 1, 13, 14), actual: 460, predicted: 440),
  EnergyReading(time: DateTime(2025, 1, 13, 15), actual: 510, predicted: 490),
  EnergyReading(time: DateTime(2025, 1, 13, 16), actual: 380, predicted: 400),
  EnergyReading(time: DateTime(2025, 1, 13, 17), actual: 210, predicted: 250),
];

final mockNotifications = [
  Notification(
    id: 'n1',
    title: 'Welcome back, Ahmad!',
    body: 'EcoMesh is pre-cooling Zone B (Level 2) for your arrival. Est. cost: RM0.05',
    type: 'arrival',
    timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
    isRead: true,
  ),
  Notification(
    id: 'n2',
    title: 'Away Mode Active',
    body: 'Lights dimmed to 30%. Standby power cut on your Smart Strip.',
    type: 'saving',
    timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
    isRead: false,
  ),
  Notification(
    id: 'n3',
    title: 'Ghost Power Detected',
    body: 'Zone A has 3 unclaimed sockets drawing 42W. Cutting in 2 mins.',
    type: 'warning',
    timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    isRead: false,
  ),
];

// Weekly savings by day
final weeklyData = [
  {'day': 'Mon', 'kwh': 2.1, 'rm': 1.05},
  {'day': 'Tue', 'kwh': 3.4, 'rm': 1.70},
  {'day': 'Wed', 'kwh': 1.8, 'rm': 0.90},
  {'day': 'Thu', 'kwh': 2.9, 'rm': 1.45},
  {'day': 'Fri', 'kwh': 0.0, 'rm': 0.0},
  {'day': 'Sat', 'kwh': 0.0, 'rm': 0.0},
  {'day': 'Sun', 'kwh': 0.0, 'rm': 0.0},
];