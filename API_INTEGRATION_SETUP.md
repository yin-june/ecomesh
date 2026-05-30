# EcoMesh API Integration Setup

This guide walks you through setting up and running the EcoMesh Flutter app with the backend API.

## Prerequisites

- **Backend**: FastAPI running on `http://localhost:8000`
- **Flutter**: Dart SDK and Flutter SDK installed
- **Database**: PostgreSQL with proper configuration

## Backend Setup

### 1. Create Test User in Database

Run the seeder script to populate a test user:

```bash
cd backend
python seed_test_user.py
```

**Output:**
```
✓ Test user created successfully!
  Email: test@example.com
  Password: password123
  User ID: <uuid>
```

### 2. Start Backend Server

```bash
cd backend
python main.py
```

The API should be available at `http://localhost:8000` with OpenAPI docs at `http://localhost:8000/docs`.

## Flutter App Setup

### 1. Install Dependencies

```bash
cd flutter
flutter pub get
```

### 2. Run Flutter App

```bash
flutter run
```

## Authentication Flow

The app now uses real authentication instead of mock data:

### Splash Screen → Onboarding → Login
1. **Splash Screen**: 2-second logo animation
2. **Onboarding**: Choose energy persona (Deep Worker, Eco-Warrior, Standard Admin)
3. **Login Screen**: Pre-filled with test credentials
   - Email: `test@example.com`
   - Password: `password123`
   - Click "Sign In" to authenticate

### After Login
- **Dashboard**: Fetches real user data, zones, and notifications from API
- **Zones Screen**: Lists all available zones with live telemetry
- **Impact Screen**: Shows carbon offset and energy savings
- **Profile Screen**: Displays user information with logout button

## API Integration

### Architecture
- **ApiClient**: Core HTTP client with JWT token management
- **AuthService**: Authentication (register, login, getCurrentUser, logout)
- **ZoneService**: Zone management (getZones, getTelemetry, claimZone, etc.)
- **AnalyticsService**: ML predictions and ESG metrics
- **NotificationService**: User notifications
- **AppState**: Provider-based state management

### Services Location
```
flutter/lib/services/
├── api_client.dart           # Core HTTP client
├── auth_service.dart         # Authentication
├── zone_service.dart         # Zone operations
├── analytics_service.dart    # ML & metrics
├── notification_service.dart # Notifications
└── app_state.dart            # Global state with Provider
```

## Backend API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login (form-encoded OAuth2)
- `GET /api/v1/auth/me` - Get current user profile

### Zones
- `GET /api/v1/zones/` - List all zones
- `GET /api/v1/zones/{zone_id}/telemetry` - Live zone telemetry
- `POST /api/v1/zones/{zone_id}/claim` - Claim zone with profile
- `GET /api/v1/zones/{zone_id}/desks` - List zone desks
- `POST /api/v1/zones/{zone_id}/desks` - Create desk
- `PUT /api/v1/zones/{zone_id}/desks/{desk_id}/claim` - Claim desk
- `POST /api/v1/zones/{zone_id}/desks/{desk_id}/power` - Toggle desk power

### Control
- `POST /api/v1/control/hvac` - Override HVAC settings
- `POST /api/v1/control/relay` - Toggle outlet relay
- `POST /api/v1/control/emergency` - Emergency shutdown

### Analytics
- `POST /api/v1/analytics/predict` - ML cooling demand prediction
- `POST /api/v1/analytics/impact` - ESG impact metrics
- `GET /api/v1/analytics/energy-history/{zone_id}` - Energy history

### Notifications
- `GET /api/v1/notifications/` - Get notifications
- `GET /api/v1/notifications/unread-count` - Count unread
- `POST /api/v1/notifications/{id}/read` - Mark as read
- `DELETE /api/v1/notifications/{id}` - Delete notification

## Troubleshooting

### Cannot connect to backend
- Check backend is running: `curl http://localhost:8000/api/v1/auth/me`
- Verify CORS is enabled in `backend/config/settings.py`
- Default API base URL is `http://localhost:8000`

### Test user not created
- Ensure PostgreSQL is running
- Check database credentials in `backend/config/settings.py`
- Run `python seed_test_user.py` again

### Token/Authentication errors
- Clear Flutter app cache: `flutter clean`
- Rebuild app: `flutter run`
- Check backend logs for JWT validation errors

### API 404 errors
- Verify zone IDs and resource IDs exist in database
- Check API v1 prefix in URLs (should be `/api/v1/...`)

## Development Notes

### Adding new services
1. Create new service file in `flutter/lib/services/`
2. Inherit from ApiClient pattern
3. Add methods using `get()`, `post()`, `put()`, `postForm()`
4. Add to AppState initialization in `app_state.dart`
5. Use in screens via `context.read<AppState>().newService`

### Modifying authentication
- JWT tokens stored securely via `flutter_secure_storage`
- Token automatically injected in all API requests via Bearer header
- Logout clears token from storage

### Testing with curl
```bash
# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=test@example.com&password=password123"

# Get current user (requires token)
curl -X GET http://localhost:8000/api/v1/auth/me \
  -H "Authorization: Bearer <token>"
```

## Next Steps

1. ✅ Backend test user seeding
2. ✅ Frontend authentication integration
3. ✅ Dashboard/zones/profile data fetching
4. Implement desk CRUD endpoints (TODO in backend)
5. Wire notifications to database (TODO in backend)
6. Integrate ML predicted values in energy history (TODO)

---

For more details, see:
- Backend: [backend/README.md](../backend/README.md)
- Flutter: [flutter/README.md](flutter/README.md)
