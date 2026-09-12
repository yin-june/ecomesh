import 'package:flutter/material.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'zone_service.dart';
import 'analytics_service.dart';
import 'notification_service.dart';
import '../models/user_model.dart';

class AppState extends ChangeNotifier {
  late ApiClient _apiClient;
  late AuthService _authService;
  late ZoneService _zoneService;
  late AnalyticsService _analyticsService;
  late NotificationService _notificationService;

  bool _isAuthenticated = false;
  UserModel? _currentUser;
  String? _errorMessage;

  // Energy profile state — persisted to backend on change
  double _tempPref = 24.0;
  String _selectedPreset = 'Deep Work';
  bool _isSavingProfile = false;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  double get tempPref => _tempPref;
  String get selectedPreset => _selectedPreset;
  bool get isSavingProfile => _isSavingProfile;

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
      final userMap = await _authService.getCurrentUser();
      _currentUser = UserModel.fromMap(userMap);
      _isAuthenticated = true;

      // Load saved energy profile (best-effort — defaults remain if 404)
      await _loadEnergyProfile();

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
      final userMap = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      _currentUser = UserModel.fromMap(userMap);
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
        final userMap = await _authService.getCurrentUser();
        _currentUser = UserModel.fromMap(userMap);
        _isAuthenticated = true;
        await _loadEnergyProfile();
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
      _tempPref = 24.0;
      _selectedPreset = 'Deep Work';
    } catch (e) {
      _errorMessage = 'Failed to logout: $e';
    }
    notifyListeners();
  }

  /// Refresh user profile (re-fetches ESG points etc. from backend)
  Future<void> refreshUserProfile() async {
    try {
      final userMap = await _authService.getCurrentUser();
      _currentUser = UserModel.fromMap(userMap);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to refresh profile: $e';
      notifyListeners();
    }
  }

  /// Load energy profile from backend on login/app-start.
  /// Silently ignored if no profile has been saved yet (404).
  Future<void> _loadEnergyProfile() async {
    try {
      final profileMap = await _authService.getEnergyProfile();
      final profile = EnergyProfileModel.fromMap(profileMap);
      _tempPref = profile.preferredTemp;
      _selectedPreset = profile.profileName;
    } on NotFoundException {
      // No profile saved yet — keep defaults (24.0 / 'Deep Work')
    } catch (_) {
      // Network failure — keep defaults silently
    }
  }

  /// Persist energy profile to backend. Returns true on success.
  /// Called from ProfileScreen when the user changes preset or temperature.
  Future<bool> saveEnergyProfile({
    required String profileName,
    required double preferredTemp,
  }) async {
    // Optimistic local update
    _tempPref = preferredTemp;
    _selectedPreset = profileName;
    _isSavingProfile = true;
    notifyListeners();

    try {
      await _authService.upsertEnergyProfile(
        profileName: profileName,
        preferredTemp: preferredTemp,
      );
      _isSavingProfile = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Still keep local values — offline fallback
      _isSavingProfile = false;
      notifyListeners();
      return false;
    }
  }
}
