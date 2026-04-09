# Driver App (Flutter) - Copilot Instructions

## Project Overview

This Flutter application is the **driver mobile app** for the SV-TMS (SV Trucking Management System). It provides drivers with tools to manage deliveries, track routes, update location, upload proof of delivery, and communicate with dispatchers in real-time.

**Key Technologies:**
- Flutter 3.5.4+ / Dart ^3.5.4
- Provider state management
- Firebase (FCM, Analytics)
- WebSocket/STOMP for real-time updates
- Google Maps integration
- Easy Localization (en/km)
- Flavors: dev, uat, prod

## Essential Commands

```bash
# Setup
flutter pub get

# Run (development)
flutter run --flavor dev -t lib/main.dart

# Run (production)
flutter run --flavor prod -t lib/main.dart

# Build APK
flutter build apk --flavor prod --release

# Build iOS
flutter build ios --flavor prod --release

# Run tests
flutter test

# Generate launcher icons
flutter pub run flutter_launcher_icons

# Clean rebuild
flutter clean && flutter pub get && flutter run
```

## Backend API Integration

### API Structure & Isolation

**CRITICAL:** This driver app uses **ONLY** the driver-specific endpoints:
- `/api/driver/*` - Driver operations (profile, deliveries, location, documents)
- `/api/auth/*` - Authentication (login, refresh tokens)

**DO NOT** use:
- `/api/customer/*` - Customer-only endpoints
- `/api/admin/*` - Admin/dispatcher-only endpoints (except for legacy endpoints being migrated)

### API Base URL Configuration

The app uses dynamic base URL management via `ApiConstants`:

```dart
// Default (production)
static const String _defaultApiUrl = 'https://svtms.svtrucking.biz/api';
static const String _defaultImageUrl = 'https://svtms.svtrucking.biz';

// Development (local)
static const String _defaultApiUrl = 'http://localhost:8080/api';
static const String _defaultImageUrl = 'http://localhost:8080';
```

**Compile-time override:**
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8080/api
```

**Runtime override:**
```dart
await ApiConstants.setBaseUrlOverride('http://staging.server:8080/api');
await ApiConstants.clearBaseUrlOverride(); // revert to default
```

### Driver API Endpoints

#### Authentication
- `POST /api/auth/driver/login` - Driver login with username/password
- `POST /api/auth/refresh` - Refresh access token using refresh token

#### Driver Profile & Management
- `GET /api/driver/profile` - Get current driver profile
- `POST /api/driver/update-device-token` - Register FCM device token
- `POST /api/driver/{driverId}/heartbeat` - Send heartbeat status

#### Deliveries & Orders
- `GET /api/driver/deliveries` - List assigned deliveries
- `GET /api/driver/deliveries/{id}` - Get delivery details
- `POST /api/driver/deliveries/{id}/status` - Update delivery status
- `POST /api/driver/deliveries/{id}/proof` - Upload proof of delivery

#### Location Tracking
- `POST /api/driver/location` - Update current location (single)
- `POST /api/driver/location/update/batch` - Batch location updates
- WebSocket: `/topic/driver/{driverId}/location` - Real-time location stream

#### Documents & Licenses
- `GET /api/driver/documents` - List driver documents
- `POST /api/driver/documents` - Upload new document
- `DELETE /api/driver/documents/{id}` - Delete document

#### Dashboard & KPIs
- `GET /api/driver/dashboard/{driverId}` - Get driver dashboard data (stats, earnings, active orders)

### Authentication Flow

1. **Login:**
   ```dart
   final response = await http.post(
     ApiConstants.login,
     headers: ApiConstants.defaultHeaders,
     body: jsonEncode({
       'username': username,
       'password': password,
     }),
   );
   
   if (response.statusCode == 200) {
     final data = jsonDecode(response.body);
     await ApiConstants.persistLoginResponse(data);
   }
   ```

2. **Automatic Token Refresh:**
   ```dart
   final headers = await ApiConstants.getHeaders(); // auto-refreshes if expired
   final response = await http.get(endpoint, headers: headers);
   ```

3. **Manual Token Refresh:**
   ```dart
   final newToken = await ApiConstants.refreshAccessToken();
   if (newToken == null) {
     // Redirect to login
   }
   ```

4. **Check Login Status:**
   ```dart
   final isLoggedIn = await ApiConstants.isLoggedIn();
   if (!isLoggedIn) Navigator.pushReplacementNamed(context, '/login');
   ```

## State Management

This app uses **Provider** for state management. Key providers:

### UserProvider
Manages authentication state and user profile.

```dart
class UserProvider extends ChangeNotifier {
  String? accessToken;
  String? refreshToken;
  int? userId;
  String? username;
  String? status; // PENDING, ACTIVE, INACTIVE
  List<String> roles; // ['DRIVER']
  
  Future<void> login(String username, String password);
  Future<void> logout();
  Future<void> loadUserData();
}
```

### DashboardKpiProvider
Manages driver dashboard data (stats, earnings, active orders).

```dart
class DashboardKpiProvider extends ChangeNotifier {
  Map<String, dynamic>? dashboardData;
  
  Future<void> fetchDashboard(int driverId);
}
```

### LocationProvider
Manages GPS location tracking and background location updates.

```dart
class LocationProvider extends ChangeNotifier {
  Position? currentPosition;
  bool isTracking = false;
  
  Future<void> startTracking();
  Future<void> stopTracking();
  Future<void> sendLocation(Position position);
}
```

## WebSocket Integration

### STOMP Client Setup

```dart
import 'package:stomp_dart_client/stomp_dart_client.dart';

StompClient stompClient = StompClient(
  config: StompConfig(
    url: await ApiConstants.getSockJsWebSocketUrl(),
    onConnect: onConnectCallback,
    beforeConnect: () async {
      await Future.delayed(const Duration(milliseconds: 200));
    },
    onWebSocketError: (dynamic error) => print('WebSocket error: $error'),
    stompConnectHeaders: {
      'Authorization': 'Bearer ${await ApiConstants.getAccessToken()}',
    },
  ),
);

stompClient.activate();
```

### Subscribe to Topics

```dart
// Location updates
stompClient.subscribe(
  destination: '/topic/driver/$driverId/location',
  callback: (StompFrame frame) {
    final data = jsonDecode(frame.body!);
    // Handle location update
  },
);

// Dispatch assignments
stompClient.subscribe(
  destination: '/topic/driver/$driverId/dispatch',
  callback: (StompFrame frame) {
    final data = jsonDecode(frame.body!);
    // Show notification for new dispatch
  },
);
```

## Firebase Integration

### FCM Setup

The app registers FCM tokens on login and syncs them with the backend:

```dart
// lib/core/utils/fcm_util.dart
static Future<void> syncTokenToBackend(
  BuildContext context,
  UserProvider userProvider,
  {Function(bool success)? onResult}
) async {
  final fcmToken = await FirebaseMessaging.instance.getToken();
  
  final response = await http.post(
    Uri.parse('${ApiConstants.baseUrl}/api/driver/update-device-token'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${userProvider.accessToken}',
    },
    body: jsonEncode({
      'driverId': userProvider.userId,
      'deviceToken': fcmToken,
    }),
  );
}
```

### Push Notification Handling

```dart
// Foreground messages
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  NotificationHelper.showRemoteMessage(message);
});

// Background/terminated app taps
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  final type = message.data['type'];
  if (type == 'dispatch') {
    Navigator.pushNamed(context, AppRoutes.dispatchDetail, arguments: message.data);
  }
});
```

## Location Tracking

### GPS Permission & Setup

```dart
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

// Request location permission
final status = await Permission.location.request();
if (!status.isGranted) {
  // Handle permission denied
}

// Get current location
Position position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high,
);

// Background location tracking
StreamSubscription<Position> positionStream = Geolocator.getPositionStream(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // meters
  ),
).listen((Position position) {
  // Send to backend
  sendLocationToBackend(position);
});
```

### Batch Location Updates

```dart
Future<void> sendBatchLocations(List<Position> positions) async {
  final batch = positions.map((p) => {
    'latitude': p.latitude,
    'longitude': p.longitude,
    'timestamp': p.timestamp.toIso8601String(),
    'accuracy': p.accuracy,
    'speed': p.speed,
  }).toList();
  
  await http.post(
    ApiConstants.updateLocationBatch,
    headers: await ApiConstants.getHeaders(),
    body: jsonEncode({'locations': batch}),
  );
}
```

## Localization (i18n)

The app supports English and Khmer using `easy_localization`.

### Translation Files

- `assets/translations/en.json`
- `assets/translations/km.json`

### Usage

```dart
import 'package:easy_localization/easy_localization.dart';

// In main.dart
await EasyLocalization.ensureInitialized();

runApp(
  EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('km')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    child: MyApp(),
  ),
);

// In widgets
Text('welcome_message'.tr()),
Text('hello_user'.tr(namedArgs: {'name': userName})),

// Change language
context.setLocale(const Locale('km'));
```

## Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/auth_service_test.dart

# Run with coverage
flutter test --coverage
```

### Test Structure

```
test/
├── unit/
│   ├── providers/
│   ├── services/
│   └── utils/
├── widget/
│   └── screens/
└── integration/
    └── auth_flow_test.dart
```

## API Versioning Strategy

### Mobile App Versioning

The app version follows semantic versioning: `MAJOR.MINOR.PATCH+BUILD`

Example: `1.2.3+45`
- `1.2.3` - Semantic version (user-facing)
- `45` - Build number (incremented for each release)

Update in `pubspec.yaml`:
```yaml
version: 1.2.3+45
```

### Backend API Compatibility

The backend API currently uses **implicit versioning** via client-isolated endpoints:
- Driver app → `/api/driver/*`
- Customer app → `/api/customer/*`
- Admin panel → `/api/admin/*`

**Future considerations:**
- Accept-Version header support
- Deprecation warnings in API responses
- Minimum supported client version checks

### Handling Backend API Changes

1. **Backward-compatible changes** (new fields, new endpoints):
   - Safe to deploy without app update
   - Use null-safe Dart code to handle missing fields

2. **Breaking changes** (removed fields, changed response structure):
   - Backend should maintain old + new versions temporarily
   - App should check API version and adapt
   - Force update users on older app versions

3. **Deprecation flow:**
   - Backend adds `deprecated: true` to response metadata
   - App shows "Update Available" message
   - After grace period, backend returns 426 Upgrade Required

## Troubleshooting

### Common Issues

1. **Login fails with 401:**
   - Check API base URL is correct
   - Verify username/password
   - Check backend logs for authentication errors

2. **FCM token not syncing:**
   - Ensure Firebase is initialized: `await Firebase.initializeApp()`
   - Check FCM token endpoint: `/api/driver/update-device-token`
   - Verify Authorization header includes valid JWT

3. **Location not updating:**
   - Check location permissions granted
   - Verify battery optimization disabled (Android)
   - Check background execution permissions
   - Verify WebSocket connection active

4. **WebSocket disconnects frequently:**
   - Check network stability
   - Verify JWT token not expired (refresh before WS connect)
   - Check backend STOMP configuration
   - Enable heartbeat pings in STOMP config

5. **Images not loading:**
   - Check `ApiConstants.imageUrl` points to correct base URL
   - Verify image paths start with `/uploads/` or full URL
   - Check network connectivity
   - Use `cached_network_image` for better error handling

### Debugging Tools

```dart
// Enable verbose API logging
debugPrint('[API] Request: $uri | Headers: $headers | Body: $body');
debugPrint('[API] Response: ${response.statusCode} | ${response.body}');

// Check token validity
final isExpired = await ApiConstants.isTokenExpired();
debugPrint('[Auth] Token expired: $isExpired');

// Verify WebSocket connection
stompClient.config = StompConfig(
  onDebugMessage: (String message) => print('[STOMP] $message'),
);
```

## Security Best Practices

1. **Never commit sensitive data:**
   - Firebase config files (google-services.json, GoogleService-Info.plist)
   - API keys, secrets
   - Production server URLs

2. **Use secure storage for tokens:**
   - `flutter_secure_storage` for access/refresh tokens
   - SharedPreferences fallback for development only

3. **Validate user input:**
   - Sanitize text inputs before API calls
   - Validate file uploads (size, type)
   - Check image dimensions before upload

4. **Handle permissions properly:**
   - Request only necessary permissions
   - Explain why permissions are needed
   - Handle denial gracefully

## File Structure Summary

```
tms_driver_app/
├── lib/
│   ├── core/
│   │   ├── network/
│   │   │   ├── api_constants.dart    # API config & endpoints
│   │   │   └── dio_client.dart       # HTTP client with interceptors
│   │   └── utils/
│   │       ├── fcm_util.dart         # FCM token sync
│   │       └── location_util.dart    # Location helpers
│   ├── models/                       # Data models (Delivery, Driver, etc.)
│   ├── providers/                    # State management (Provider)
│   │   ├── user_provider.dart
│   │   ├── dashboard_kpi_provider.dart
│   │   └── location_provider.dart
│   ├── screens/                      # UI screens
│   ├── services/                     # Business logic services
│   │   ├── firebase_messaging_service.dart
│   │   └── web_socket_service.dart
│   ├── widgets/                      # Reusable widgets
│   ├── routes/                       # App routing
│   ├── firebase/                     # Firebase setup
│   ├── themes/                       # App theming
│   └── main.dart                     # App entry point
├── assets/
│   ├── translations/                 # i18n JSON files
│   └── images/                       # Static images
├── android/                          # Android config
├── ios/                              # iOS config
├── test/                             # Unit/widget/integration tests
└── pubspec.yaml                      # Dependencies
```

## Next Steps When Making Changes

1. **Adding new driver endpoints:**
   - Ensure endpoint is under `/api/driver/*`
   - Add to `ApiConstants` for centralized management
   - Update API response models
   - Add error handling for 403/401/500 responses

2. **Implementing new features:**
   - Create Provider for state management
   - Add service layer for business logic
   - Create UI screens/widgets
   - Add tests (unit + widget)
   - Update localization files (en.json, km.json)

3. **Modifying authentication:**
   - Update `ApiConstants.persistLoginResponse()` if response format changes
   - Test token refresh flow
   - Verify FCM token sync after auth changes

4. **Changing location tracking:**
   - Update `LocationProvider`
   - Test battery impact
   - Verify background execution on both iOS and Android

---

**Remember:** This is the **driver app** - only use `/api/driver/*` and `/api/auth/*` endpoints. Never mix customer or admin endpoints.
