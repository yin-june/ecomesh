import 'package:ecomesh/services/api_client.dart';

class ZoneService {
  final ApiClient apiClient;

  ZoneService({required this.apiClient});

  Map<String, dynamic> _asMap(dynamic value, String name) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw ServerException('$name: expected Map but got ${value.runtimeType}');
  }

  /// Fetch all zones
  Future<List<Map<String, dynamic>>> getZones() async {
    final response = await apiClient.get('/api/v1/zones/');
    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
  }

  /// Fetch live telemetry for a specific zone
  Future<Map<String, dynamic>> getZoneTelemetry(String zoneId) async {
    final response = await apiClient.get('/api/v1/zones/$zoneId/telemetry');
    return _asMap(response, 'getZoneTelemetry');
  }

  /// Claim a zone with a profile
  Future<Map<String, dynamic>> claimZone(
    String zoneId,
    String profileName,
  ) async {
    final response = await apiClient.post(
      '/api/v1/zones/$zoneId/claim',
      body: {'profile_name': profileName},
    );
    return _asMap(response, 'claimZone');
  }

  /// Get desk list for a zone
  Future<List<Map<String, dynamic>>> getZoneDesks(String zoneId) async {
    final response = await apiClient.get('/api/v1/zones/$zoneId/desks');
    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
  }

  /// Create a new desk in a zone
  Future<Map<String, dynamic>> createDesk(
    String zoneId, {
    required String label,
    required double xPos,
    required double yPos,
  }) async {
    final response = await apiClient.post(
      '/api/v1/zones/$zoneId/desks',
      body: {
        'label': label,
        'x': xPos,
        'y': yPos,
      },
    );
    return _asMap(response, 'createDesk');
  }

  /// Update desk claim status
  Future<Map<String, dynamic>> updateDeskClaim(
    String zoneId,
    String deskId, {
    required bool isClaimed,
    String? claimedBy,
  }) async {
    final response = await apiClient.put(
      '/api/v1/zones/$zoneId/desks/$deskId/claim',
      body: {
        'is_claimed': isClaimed,
        'claimed_by': claimedBy,
      },
    );
    return _asMap(response, 'updateDeskClaim');
  }

  /// Toggle desk power
  Future<Map<String, dynamic>> toggleDeskPower(
    String zoneId,
    String deskId, {
    required bool isPowered,
  }) async {
    final response = await apiClient.post(
      '/api/v1/zones/$zoneId/desks/$deskId/power',
      body: {'is_powered': isPowered},
    );
    return _asMap(response, 'toggleDeskPower');
  }

  /// Override relay on a zone
  Future<Map<String, dynamic>> overrideRelay(
    String zoneId,
    int socketId, {
    required String state, // "ON" or "OFF"
  }) async {
    final response = await apiClient.post(
      '/api/v1/control/$zoneId/relay/$socketId',
      body: {'state': state},
    );
    return _asMap(response, 'overrideRelay');
  }

  /// Override HVAC settings
  Future<Map<String, dynamic>> overrideHVAC(
    String zoneId, {
    required int targetTemp,
    required String mode, // "COOL", "DRY", "FAN", "OFF"
  }) async {
    final response = await apiClient.post(
      '/api/v1/control/$zoneId/hvac',
      body: {'target_temp': targetTemp, 'mode': mode},
    );
    return _asMap(response, 'overrideHVAC');
  }

  /// Emergency shutdown for a floor
  Future<Map<String, dynamic>> emergencyShutdown(int floorLevel) async {
    final response = await apiClient.post(
      '/api/v1/control/emergency-shutdown',
      body: {'floor_level': floorLevel},
    );
    return _asMap(response, 'emergencyShutdown');
  }
}
