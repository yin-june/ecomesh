# EcoMesh Flutter API Client & Backend Integration Guide

## Flutter Services Overview

The Flutter app now has a complete API client layer to communicate with the EcoMesh backend. All services use secure token storage and automatic JWT authentication.

### Available Services

#### 1. **AuthService** (`lib/services/auth_service.dart`)
Manages user authentication and JWT tokens.

```dart
final authService = AuthService(apiClient: apiClient);

// Register new user
await authService.register(
  email: 'user@example.com',
  password: 'secure_password',
  fullName: 'Ahmad Fariz',
);

// Login and store token
final token = await authService.login(
  email: 'user@example.com',
  password: 'secure_password',
);

// Get current user profile
final userProfile = await authService.getCurrentUser();

// Logout
await authService.logout();
```

#### 2. **ZoneService** (`lib/services/zone_service.dart`)
Fetches zones, real-time telemetry, and manages desks.

```dart
final zoneService = ZoneService(apiClient: apiClient);

// Get all zones
final zones = await zoneService.getZones();

// Get live telemetry for a zone (occupancy, temperature, energy)
final telemetry = await zoneService.getZoneTelemetry('zone-a');
// Returns: {
//   zone_id: 'zone-a',
//   occupancy_count: 5,
//   temperature: 23.5,
//   target_temp: 24.0,
//   energy_draw_kwh: 2.3,
//   status: 'active' | 'idle' | 'ghost' | 'off'
// }

// Claim a zone with a profile
await zoneService.claimZone('zone-a', 'Deep Work');

// Get desks in a zone
final desks = await zoneService.getZoneDesks('zone-a');

// Create a new desk
await zoneService.createDesk(
  'zone-a',
  label: 'Desk 1',
  xPos: 100.0,
  yPos: 200.0,
);

// Update desk claim status
await zoneService.updateDeskClaim(
  'zone-a',
  'desk-1',
  isClaimed: true,
  claimedBy: 'Ahmed',
);

// Toggle desk power
await zoneService.toggleDeskPower('zone-a', 'desk-1', isPowered: true);

// HVAC Control
await zoneService.overrideHVAC('zone-a', targetTemp: 22, mode: 'COOL');

// Emergency shutdown
await zoneService.emergencyShutdown(floorLevel: 2);
```

#### 3. **AnalyticsService** (`lib/services/analytics_service.dart`)
Gets ML predictions and ESG impact metrics.

```dart
final analyticsService = AnalyticsService(apiClient: apiClient);

// Get cooling demand prediction
final prediction = await analyticsService.predictCoolingDemand(
  zoneId: 'zone-a',
  currentOccupancy: 5,
);
// Returns: {
//   recommended_temp: 22.5,
//   strategy: 'PRECOOL', // or 'NORMAL', 'HEAT_RECOVERY'
//   estimated_savings_kwh: 1.2,
// }

// Get user's ESG impact metrics
final impact = await analyticsService.getUserImpact(kwhSavedThisWeek: 10.5);
// Returns: {
//   rm_saved: 15.75,
//   kg_co2_avoided: 8.3,
//   trees_equivalent: 0.5,
// }

// Get historical energy data
final history = await analyticsService.getEnergyHistory(
  zoneId: 'zone-a',
  daysBack: 7,
);
```

#### 4. **NotificationService** (`lib/services/notification_service.dart`)
Manages user notifications.

```dart
final notificationService = NotificationService(apiClient: apiClient);

// Get all notifications
final notifications = await notificationService.getNotifications(
  limit: 20,
  unreadOnly: false,
);

// Get unread count
final unreadCount = await notificationService.getUnreadCount();

// Mark notification as read
await notificationService.markAsRead('notification-id');

// Mark all as read
await notificationService.markAllAsRead();

// Delete notification
await notificationService.deleteNotification('notification-id');
```

### Setup Instructions

#### Step 1: Add dependencies to `pubspec.yaml`
```yaml
dependencies:
  http: ^1.1.0
  flutter_secure_storage: ^9.0.0
```

Run: `flutter pub get`

#### Step 2: Initialize API client in your main app
```dart
import 'package:ecomesh/services/api_client.dart';
import 'package:ecomesh/services/auth_service.dart';
import 'package:ecomesh/services/zone_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize API client
    final apiClient = ApiClient(
      baseUrl: 'http://localhost:8000', // or your backend URL
    );
    
    // Create services
    final authService = AuthService(apiClient: apiClient);
    final zoneService = ZoneService(apiClient: apiClient);
    
    return MaterialApp(
      // Pass services to your screens via provider or dependency injection
      home: LoginScreen(authService: authService),
    );
  }
}
```

#### Step 3: Replace mock data with API calls
```dart
// Before (mock data):
final mockUser = UserProfile(name: 'Ahmad Fariz', ...);

// After (real API):
final user = await authService.getCurrentUser();
final userProfile = UserProfile.fromJson(user);
```

### Error Handling

All services throw custom exceptions that should be caught:

```dart
try {
  final zones = await zoneService.getZones();
} on UnauthorizedException catch (e) {
  // User token expired or invalid - show login screen
  await authService.logout();
} on TimeoutException catch (e) {
  // Network timeout - show retry button
  showSnackBar('Connection timeout. Please try again.');
} on ServerException catch (e) {
  // Backend error (5xx)
  showSnackBar('Server error: ${e.message}');
} on ApiException catch (e) {
  // General API error
  showSnackBar('Error: ${e.message}');
}
```

## Backend Endpoints

### Authentication
- `POST /auth/register` - Register new user
- `POST /auth/login` - Login and receive JWT token
- `GET /auth/me` - Get current user profile

### Zones (Real-time data)
- `GET /zones/` - List all zones
- `GET /zones/{zone_id}/telemetry` - **NEW**: Get live occupancy, temperature, energy draw
- `POST /zones/{zone_id}/claim` - Claim zone with profile
- `GET /zones/{zone_id}/desks` - **NEW**: List desks in zone
- `POST /zones/{zone_id}/desks` - **NEW**: Create desk
- `PUT /zones/{zone_id}/desks/{desk_id}/claim` - **NEW**: Update desk claim status
- `POST /zones/{zone_id}/desks/{desk_id}/power` - **NEW**: Toggle desk power

### Analytics & AI
- `GET /analytics/predict-demand` - ML cooling strategy recommendation
- `GET /analytics/my-impact` - ESG impact metrics (RM saved, CO2 avoided)
- `GET /analytics/energy-history/{zone_id}` - **NEW**: Historical energy consumption

### Notifications
- `GET /notifications/` - **NEW**: Get notifications
- `GET /notifications/unread-count` - **NEW**: Get unread count
- `POST /notifications/{id}/read` - **NEW**: Mark as read
- `POST /notifications/read-all` - **NEW**: Mark all as read
- `POST /notifications/{id}/delete` - **NEW**: Delete notification

### Control (MQTT)
- `POST /control/{zone_id}/relay/{socket_id}` - Toggle relay
- `POST /control/{zone_id}/hvac` - Override AC settings
- `POST /control/emergency-shutdown` - Kill devices on floor

## Configuration

Create a config file for API settings:

```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  
  static const int requestTimeoutSeconds = 30;
  static const int retryAttempts = 3;
}
```

## Testing

To test the API locally:

```bash
# 1. Start backend (with Docker)
docker-compose up

# 2. Test endpoints with curl
curl -X GET http://localhost:8000/api/v1/zones/ \
  -H "Authorization: Bearer YOUR_TOKEN"

# 3. Or use Postman/Insomnia
# Import: http://localhost:8000/openapi.json
```

## Next Steps

1. ✅ Created Flutter HTTP client with JWT auth
2. ✅ Created service layer (auth, zones, analytics, notifications)
3. ✅ Added missing backend endpoints (telemetry, desks, notifications)
4. ⏭️ **Next**: Replace mock data calls in UI screens with service calls
5. ⏭️ **Next**: Add state management (Provider, Riverpod, or Bloc)
6. ⏭️ **Next**: Implement push notifications (Firebase Cloud Messaging)

