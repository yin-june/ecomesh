import 'package:ecomesh/services/api_client.dart';

class NotificationService {
  final ApiClient apiClient;

  NotificationService({required this.apiClient});

  Map<String, dynamic> _asMap(dynamic value, String name) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw ServerException('$name: expected Map but got ${value.runtimeType}');
  }

  /// Get all notifications for current user
  Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final query = '?limit=$limit&unread_only=$unreadOnly';
    final response = await apiClient.get('/api/v1/notifications$query');
    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
  }

  /// Mark notification as read
  Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    final response = await apiClient.post(
      '/api/v1/notifications/$notificationId/read',
      body: {},
    );
    return _asMap(response, 'markAsRead');
  }

  /// Mark all notifications as read
  Future<Map<String, dynamic>> markAllAsRead() async {
    final response = await apiClient.post(
      '/api/v1/notifications/read-all',
      body: {},
    );
    return _asMap(response, 'markAllAsRead');
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await apiClient.post(
      '/api/v1/notifications/$notificationId/delete',
      body: {},
    );
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    final response = await apiClient.get('/api/v1/notifications/unread-count');
    final data = _asMap(response, 'getUnreadCount');
    return data['count'] as int? ?? 0;
  }
}
