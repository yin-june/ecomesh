import 'package:flutter/material.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'zone_service.dart';
import 'analytics_service.dart';
import 'notification_service.dart';

class AppState extends ChangeNotifier {
  late ApiClient _apiClient;
  late AuthService _authService;
  late ZoneService _zoneService;
  late AnalyticsService _analyticsService;
  late NotificationService _notificationService;

  bool _isAuthenticated = false;
  Map<String, dynamic>? _currentUser;
  String? _errorMessage;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  AuthService get authService => _authService;
  ZoneService get zoneService => _zoneService;
  AnalyticsService get analyticsService => _analyticsService;
  NotificationService get notificationService => _notificationService;

  AppState({String? apiBaseUrl}) {
    _initializeServices(apiBaseUrl ?? 'http://localhost:8000');
  }

  void _initializeServices(String baseUrl) {
    _apiClient = ApiClient(baseUrl: baseUrl);
    _authService = AuthService(apiClient: _apiClient);
    _zoneService = ZoneService(apiClient: _apiClient);
    _analyticsService = AnalyticsService(apiClient: _apiClient);
    _notificationService = NotificationService(apiClient: _apiClient);
  }

  /// Login with email/password
  Future<bool> login({required String email, required String password}) async {
    try {
      _errorMessage = null;
      await _authService.login(email: email, password: password);
      
      // Fetch current user profile
      _currentUser = await _authService.getCurrentUser();
      _isAuthenticated = true;
      
      notifyListeners();
      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _isAuthenticated = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  /// Register new user
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      _errorMessage = null;
      final user = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      _currentUser = user;
      notifyListeners();
      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Check if user is still authenticated
  Future<void> checkAuthentication() async {
    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        _currentUser = await _authService.getCurrentUser();
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
        _currentUser = null;
      }
    } catch (e) {
      _isAuthenticated = false;
      _currentUser = null;
    }
    notifyListeners();
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _authService.logout();
      _isAuthenticated = false;
      _currentUser = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to logout: $e';
    }
    notifyListeners();
  }

  /// Refresh user profile
  Future<void> refreshUserProfile() async {
    try {
      _currentUser = await _authService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to refresh profile: $e';
      notifyListeners();
    }
  }
}
