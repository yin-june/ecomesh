import 'package:ecomesh/services/api_client.dart';

class AnalyticsService {
  final ApiClient apiClient;

  AnalyticsService({required this.apiClient});

  Map<String, dynamic> _asMap(dynamic value, String name) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw ServerException('$name: expected Map but got ${value.runtimeType}');
  }

  /// Get AI-optimized cooling strategy for a zone
  Future<Map<String, dynamic>> predictCoolingDemand({
    required String zoneId,
    required int currentOccupancy,
  }) async {
    final response = await apiClient.get(
      '/api/v1/analytics/predict-demand?zone_id=$zoneId&current_occupancy=$currentOccupancy',
    );
    return _asMap(response, 'predictCoolingDemand');
  }

  /// Get user's ESG impact metrics
  Future<Map<String, dynamic>> getUserImpact(
    double kwhSavedThisWeek,
  ) async {
    final response = await apiClient.get(
      '/api/v1/analytics/my-impact?kwh_saved_this_week=$kwhSavedThisWeek',
    );
    return _asMap(response, 'getUserImpact');
  }

  /// Get historical energy readings for a zone
  Future<List<Map<String, dynamic>>> getEnergyHistory({
    required String zoneId,
    int daysBack = 7,
  }) async {
    final response = await apiClient.get(
      '/api/v1/analytics/energy-history/$zoneId?days=$daysBack',
    );
    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
  }
}
