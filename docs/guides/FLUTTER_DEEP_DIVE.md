# SV-TMS Deep Dive: Flutter Driver App

> The driver app is the phone in a truck driver's hands. It shows jobs, tracks GPS, lets drivers take photos, and chat with the office — all in real time.

---

## The Big Picture

```
Driver's Phone
     │
     ▼
tms_driver_app (Flutter)
     │
     ▼  HTTPS + WebSocket
api-gateway :8086
     │
     ├── tms-driver-app-api :8084   ← driver jobs, assignments
     ├── tms-auth-api       :8083   ← login, tokens, device approval
     └── tms-core-api       :8080   ← dispatches, chat, issues
```

**Rule:** The app always talks to `ApiConstants.baseApiUrl` — never a hardcoded IP.

---

## Folder Structure

```
tms_driver_app/lib/
├── core/
│   ├── config/        ← AppConfig — env vars, feature flags
│   ├── network/       ← DioClient, ApiConstants, error handling
│   ├── repositories/  ← data access layer (dispatch, driver, notifications)
│   ├── security/      ← token refresh, biometric, cert pinning
│   └── utils/         ← helpers (logger, validators, permissions)
├── providers/         ← state management (ChangeNotifier)
├── screens/           ← UI screens (one folder per feature)
├── models/            ← data models (Dispatch, Driver, etc.)
├── services/          ← background services (location, tracking, FCM)
├── widgets/           ← reusable UI components
├── routes/            ← named routes (AppRoutes)
└── assets/
    └── translations/  ← i18n files (en.json, km.json)
```

---

## Part 1 — Configuration & Environment

### AppConfig — single source of truth

[app_config.dart](../../tms_driver_app/lib/core/config/app_config.dart) controls all environment settings.

**API URL is set at compile time via `--dart-define`:**

```bash
# Local dev — Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8086

# Local dev — iOS simulator
flutter run --dart-define=API_BASE_URL=http://localhost:8086

# Production (default if no --dart-define given)
# Falls back to: https://svtms.svtrucking.biz/api
```

**Why `10.0.2.2` for Android?**
The Android emulator runs inside a virtual machine. `localhost` inside that VM points to the emulator itself, not your laptop. `10.0.2.2` is the special address that always points back to your laptop.

**Feature flags in AppConfig:**

| Flag | Debug | Release | Notes |
|---|---|---|---|
| `enableDebugApiOverride` | true | false | Allows localhost URLs |
| `enablePerformanceLogging` | true | false | Verbose logs |
| `enableCrashReporting` | false | true | Sentry reporting |
| `requireApprovedDevice` | false | true | Enterprise device lock |
| `reviewerMode` | false | false | Bypass device lock for App Store reviewers |

**Location tracking constants:**

```dart
static const int locationUpdateIntervalMs = 5000;    // every 5 seconds
static const double locationAccuracyMeters = 20.0;   // 20m accuracy target
static const int locationMinDistanceMeters = 10;     // skip update if < 10m moved
```

**Never hardcode a URL** in any screen or service. Always use `ApiConstants.baseApiUrl`.

---

## Part 2 — Networking

### DioClient — the HTTP client

All HTTP calls go through `DioClient`. It automatically:
- Attaches `Authorization: Bearer <token>` to every request
- Handles token refresh on 401
- Retries on transient network errors
- Logs requests in debug mode

```dart
final DioClient _dio = DioClient();

final response = await _dio.get<Map<String, dynamic>>(
  ApiConstants.endpoint('/driver/dispatches').path,
  converter: (raw) => (raw as Map).cast<String, dynamic>(),
);

if (response.success) {
  final data = response.data;
}
```

### ApiConstants — URL and token management

`ApiConstants` is the single place that knows the base URL, tokens, and tracking session.

```dart
// Build a full endpoint path
final path = ApiConstants.endpoint('/driver/current-assignment').path;

// Persist tokens after login
await ApiConstants.persistLoginResponse(loginData);

// Clear everything on logout
await ApiConstants.clearTokens();
await ApiConstants.clearUser();
await ApiConstants.clearTrackingSession();
```

### API boundary rule for Flutter

| Allowed | URL prefix |
|---|---|
| Driver features | `/api/driver/*` |
| Login / token refresh | `/api/auth/*` |
| **NEVER call** | `/api/admin/*` |

---

## Part 3 — State Management (Provider)

### Think of it like a shared whiteboard

A `Provider` holds state (data) and tells the UI when it changes. The UI listens and rebuilds automatically.

```
DispatchProvider (whiteboard)
   ↑ writes: loads dispatch list from API
   ↓ reads: HomeScreen reads the list and shows it
```

### The pattern used everywhere

```dart
// 1. Provider holds state
class DispatchProvider with ChangeNotifier {
  List<Dispatch> _dispatches = [];
  bool _isLoading = false;

  List<Dispatch> get dispatches => _dispatches;
  bool get isLoading => _isLoading;

  Future<void> loadDispatches() async {
    _isLoading = true;
    notifyListeners();  // tells the UI "I changed, please rebuild"

    _dispatches = await dispatchRepository.fetchDispatches();
    _isLoading = false;
    notifyListeners();
  }
}
```

```dart
// 2. Screen reads from provider (rebuilds on change)
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DispatchProvider>(context);

    if (provider.isLoading) return CircularProgressIndicator();
    return ListView.builder(
      itemCount: provider.dispatches.length,
      itemBuilder: (ctx, i) => DispatchCard(provider.dispatches[i]),
    );
  }
}
```

```dart
// 3. Trigger action without rebuilding (e.g. in a button handler)
final provider = Provider.of<DispatchProvider>(context, listen: false);
provider.loadDispatches();
```

### Key providers in the app

| Provider | What it manages |
|---|---|
| `SignInProvider` | Login, logout, device approval flow |
| `DispatchProvider` | Job list, status updates, proof of delivery |
| `UserProvider` | Logged-in user data and tokens |
| `AppBootstrapProvider` | Remote feature flags (policies from server) |
| `DriverProvider` | Driver profile, saved driverId |
| `ChatProvider` | Messages, WebSocket connection |

---

## Part 4 — Repository Layer

### Why a separate repository?

The repository sits between the provider and the network:

```
DispatchProvider
      ↓ calls
DispatchRepository      ← handles pagination + caching
      ↓ calls
DioClient (HTTP)
      ↓ hits
tms-driver-app-api :8084
```

It handles:
- Paginating through all result pages automatically
- Deduplicating results by ID
- Local caching with `SharedPreferences`

### Dispatch status groups (from real code)

```
Pending      → PLANNED, PENDING, SCHEDULED, ASSIGNED
In Progress  → DRIVER_CONFIRMED, IN_QUEUE, LOADING, LOADED,
               IN_TRANSIT, ARRIVED_UNLOADING, UNLOADING, UNLOADED, ...
Completed    → DELIVERED, FINANCIAL_LOCKED, CLOSED, COMPLETED,
               CANCELLED, REJECTED
```

---

## Part 5 — Sign-In Flow

What happens when a driver taps "Sign In":

```
1. SignInProvider.signIn() called
      ↓
2. Collect device info (device ID, model, OS, app version)
      ↓
3. POST /api/auth/driver/login
   headers: X-Device-Id, X-Device-Name, X-App-Version ...
      ↓
4. Server returns LOGIN_SUCCESS (or an error code)
      ↓
5. ApiConstants.persistLoginResponse() — saves tokens to secure storage
      ↓
6. TrackingSessionManager.startTrackingSession() — starts GPS tracking
      ↓
7. UserProvider.login() — saves user profile to memory
      ↓
8. Background warmups (fire-and-forget, non-blocking):
   - Start native location service
   - Subscribe to notification topics
   - Register device with server
   - Refresh remote feature flags
      ↓
9. Navigate to HomeScreen
```

**Error codes the server can return:**

| Code | Meaning |
|---|---|
| `LOGIN_SUCCESS` | All good |
| `INVALID_CREDENTIALS` | Wrong password |
| `USER_DISABLED` | Account suspended |
| `DEVICE_NOT_APPROVED` | Admin hasn't approved this phone yet |
| `DEVICE_PENDING_APPROVAL` | Approval request is waiting |
| `DEVICE_ACTIVE_ON_OTHER_PHONE` | Already logged in on another device |

**Sign-out cleanup** always stops everything:

```dart
await NativeServiceBridge.stopNativeLocationService();
await LocationService().stop();
await TrackingSessionManager.instance.stopTrackingSession();
await ApiConstants.clearTokens();
await ApiConstants.clearUser();
await TopicSubscriptionService().unsubscribeFromAllTopics();
```

---

## Part 6 — Location Tracking

GPS runs as a **native background service** so it keeps working when the app is in the background or the screen is off.

```
GPS hardware
     ↓ every 5 seconds
LocationService (Flutter/Dart)
     ↓
NativeServiceBridge (Platform Channel)
     ↓
Android Foreground Service / iOS Background Task
     ↓ HTTPS POST
tms-telematics-api :8082
```

On Android the user may be prompted to disable battery optimization — the app handles this automatically via `flutter_ignorebatteryoptimization`.

---

## Part 7 — Running & Building

### Setup (first time only)

```bash
cd tms_driver_app
flutter pub get      # install all packages
flutter doctor       # verify everything is ready
```

### Run locally

```bash
# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8086

# iOS simulator
flutter run --dart-define=API_BASE_URL=http://localhost:8086

# With WebSocket override
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8086 \
  --dart-define=WS_BASE_URL=ws://10.0.2.2:8086
```

### Build for release

```bash
# Android APK
flutter build apk --release \
  --dart-define=API_BASE_URL=https://svtms.svtrucking.biz/api

# iOS
flutter build ios --release \
  --dart-define=API_BASE_URL=https://svtms.svtrucking.biz/api
```

### App flavors (3 environments)

| Flavor | App name | Icon |
|---|---|---|
| `dev` | Trucking Dev | `dev_icon.png` |
| `uat` | Trucking UAT | `uat_icon.png` |
| `prod` | Trucking | `prod_icon.png` |

---

## Part 8 — Testing

```bash
# All unit tests
flutter test

# Widget tests only
flutter test test/widget/

# Static analysis
flutter analyze
```

**Rules:**
- Mock HTTP with `mockito` — never hit real endpoints in unit tests
- Widget tests must always settle: `await tester.pumpAndSettle()`
- Test happy path + error state for every screen

**Test naming:**

```dart
testWidgets('shows loading spinner while fetching dispatch', (tester) async {
  // arrange → act → assert
  await tester.pumpAndSettle();
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

---

## Part 9 — i18n (Khmer + English)

```
tms_driver_app/assets/translations/
├── en.json    ← English
└── km.json    ← Khmer
```

```dart
import 'package:easy_localization/easy_localization.dart';

Text('signin.error_invalid_credentials'.tr())
Text('dispatch.status_updated'.tr(args: ['IN_TRANSIT']))
```

Add every new user-visible string to **both** `en.json` and `km.json`.

---

## End-to-End Flow: Driver Taps "Start Job"

```
Screen: HomeScreen
  → calls DispatchProvider.acceptJob(id)
      ↓
Provider: DispatchProvider
  → calls DispatchRepository.updateStatus(id, 'DRIVER_CONFIRMED')
      ↓
Repository: DispatchRepository
  → calls DioClient.post('/api/driver/dispatches/{id}/status')
      ↓
Network: DioClient
  → adds Authorization: Bearer <token>
  → sends HTTPS request
      ↓
api-gateway :8086
  → validates token
  → routes to tms-driver-app-api :8084
      ↓
Backend
  → updates MySQL
  → fires Kafka event
  → responds 200 OK
      ↓
DispatchProvider
  → updates local state
  → calls notifyListeners()
      ↓
HomeScreen
  → rebuilds with new status shown on screen
```

Every layer has one job. The screen never touches the network directly.

---

## Common Mistakes Cheat Sheet

| Mistake | Correct |
|---|---|
| Hardcode `http://localhost:8080` | Use `ApiConstants.endpoint('/path').path` |
| Use raw `http` package | Use `DioClient` — auth interceptors won't fire otherwise |
| `Provider.of<X>(context)` in button handler | Add `listen: false` |
| `setState` for shared state | Use `ChangeNotifier` + `notifyListeners()` |
| `flutter run` without `--dart-define` | Always pass `API_BASE_URL` for local dev |
| Call `/api/admin/*` from the app | Only `/api/driver/*` and `/api/auth/*` |
| Hit real API in unit tests | Use `mockito` mock adapters |
