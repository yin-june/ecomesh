import 'package:ecomesh/services/api_client.dart';

// Export exception for use in this file
export 'package:ecomesh/services/api_client.dart' show ApiException;

class AuthService {
  final ApiClient apiClient;

  AuthService({required this.apiClient});

  Map<String, dynamic> _asMap(dynamic value, String name) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw ServerException('$name: expected Map but got ${value.runtimeType}');
  }

  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await apiClient.post(
      '/api/v1/auth/register',
      body: {
        'email': email,
        'password': password,
        'full_name': fullName,
      },
    );
    return _asMap(response, 'register');
  }

  /// Login user and save token
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.postForm(
      '/api/v1/auth/login',
      body: {
        'username': email, // OAuth2PasswordRequestForm uses 'username'
        'password': password,
      },
    );
    
    final data = _asMap(response, 'login');
    final token = data['access_token'] as String?;
    if (token == null) {
      throw ServerException('No token received from server');
    }
    
    await apiClient.saveToken(token);
    return token;
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await apiClient.get('/api/v1/auth/me');
    return _asMap(response, 'getCurrentUser');
  }

  /// Get the current user's saved energy profile (preset + temp).
  /// Throws [NotFoundException] if no profile has been saved yet.
  Future<Map<String, dynamic>> getEnergyProfile() async {
    final response = await apiClient.get('/api/v1/auth/energy-profile');
    return _asMap(response, 'getEnergyProfile');
  }

  /// Create or update the current user's energy profile on the backend.
  /// The desk-claim endpoint reads this to auto-apply AC settings.
  Future<Map<String, dynamic>> upsertEnergyProfile({
    required String profileName,
    required double preferredTemp,
  }) async {
    final response = await apiClient.put(
      '/api/v1/auth/energy-profile',
      body: {
        'profile_name': profileName,
        'preferred_temp': preferredTemp,
      },
    );
    return _asMap(response, 'upsertEnergyProfile');
  }

  /// Logout user
  Future<void> logout() async {
    await apiClient.clearToken();
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await apiClient.getToken();
    return token != null;
  }
}
