# Customer App Copilot Instructions

Flutter customer mobile app for SV-TMS. Connects to backend Spring Boot API via REST + STOMP WebSocket for real-time notifications.

## Quick Start

```bash
# Run with backend URL (Android emulator uses 10.0.2.2, iOS uses localhost)
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

# Build for production
flutter build apk --dart-define=API_BASE_URL=https://api.production.com

# Test
flutter test

# Regenerate OpenAPI client (after backend changes)
curl http://localhost:8080/v3/api-docs > /tmp/openapi.json
openapi-generator-cli generate -i /tmp/openapi.json -g dart -o tms_customer_app/lib/api/generated_openapi
cd tms_customer_app && flutter pub get
```

## Architecture & Stack

- **Framework**: Flutter 3.x / Dart 2.18+
- **State**: Provider pattern — `MultiProvider` in `app.dart` (AuthService, GeneratedApiService, NotificationProvider)
- **Backend**: OpenAPI client (`lib/api/generated_openapi/`) + custom `AuthService` for JWT auth
- **Real-time**: STOMP WebSocket (`stomp_dart_client`) subscribes to `/user/queue/notifications`
- **i18n**: `easy_localization` with `en`/`km` (Khmer) — `assets/lang/{en,km}.json`, NotoSansKhmer font
- **Storage**: `flutter_secure_storage` (tokens encrypted, Keychain on iOS, EncryptedSharedPreferences on Android)

### Directory Layout

```
lib/
├── main.dart                   # Entry; reads API_BASE_URL from --dart-define
├── app.dart                    # MultiProvider setup (services + providers)
├── constants/api_constants.dart # Endpoints: /api/auth/*, /api/customer/* (NOT /api/admin or /api/driver)
├── models/auth_models.dart     # LoginRequest, LoginResponse, UserInfo (includes customerId)
├── services/
│   ├── auth_service.dart       # JWT login/logout, token mgmt (ChangeNotifier)
│   ├── generated_api_service.dart # Wrapper for OpenAPI CustomerApi
│   ├── local_storage.dart      # FlutterSecureStorage wrapper
│   └── notification_service.dart # Stub for future Firebase integration
├── providers/
│   ├── auth_provider.dart      # UI-level auth state
│   ├── user_provider.dart      # User profile state
│   └── notification_provider.dart # WebSocket STOMP, auto-connects on auth
├── routes/app_routes.dart      # Named routes
├── screens/                    # login/, home/, profile/, auth/ (register, forgot, change password)
└── api/generated_openapi/      # Generated CustomerApi (orders, addresses)
```

## Backend API Structure (Critical)

**This app ONLY calls customer/auth/public endpoints** — backend organizes by client type:

```
✓ /api/auth/*              All clients (login, refresh, change-password)
✓ /api/public/*            Public (app-version check)
✓ /api/customer/{id}/*     Customer-scoped data (orders, addresses) — THIS APP
✗ /api/driver/*            Driver features — driver_app only
✗ /api/admin/*             Admin/dispatcher — tms-frontend only
```

**Data isolation**: `/api/customer/{customerId}/orders` requires authenticated user owns that `customerId`. Accessing other customer data → `403 Forbidden`.

**Permissions**: `UserInfo.permissions` array (e.g., `["order:read", "order:create"]`) returned in login response. Backend enforces via `@PreAuthorize`.

## Authentication Flow (JWT + WebSocket)

1. **Login** (`AuthService.login()` → `POST /api/auth/login`):
   - Request: `{username, password, deviceId?}`
   - Response: `{code, message, token, refreshToken?, user: {username, email, roles, permissions, customerId?}}`
   - Saves token/user to `FlutterSecureStorage` (encrypted)
   - Sets `_authenticated = true`, notifies listeners

2. **Token management**:
   - `AuthService.getToken()` retrieves from secure storage
   - `AuthService.refreshAccessToken()` calls `/api/auth/refresh` (manual — not auto-invoked on 401)
   - `GeneratedApiService.setAuthToken(token)` sets `Authorization: Bearer <token>`

3. **Session restore**:
   - `AuthService.tryRestore()` called on app init (checks storage for token/user)
   - If found, sets `_authenticated = true` without re-login

4. **WebSocket auto-connect**:
   - `NotificationProvider` listens to `AuthService` changes
   - On auth success → `connectWebSocket(customerId)`
   - STOMP URL: derives from `API_BASE_URL` (http→ws, https→wss) + `/ws?token={token}`
   - Subscribes to `/user/queue/notifications` for real-time updates
   - Auto-disconnects on logout

## State Management Patterns

**Provider setup** (`app.dart`):
```dart
MultiProvider([
  Provider<GeneratedApiService>.value(apiService),
  ChangeNotifierProvider<AuthService>.value(authService),
  ChangeNotifierProvider<NotificationProvider>.value(notificationProvider),
  // ...
])
```

**Common usage**:
```dart
// Trigger login (no listen):
final authProvider = Provider.of<AuthProvider>(context, listen: false);
await authProvider.login(username, password);

// React to auth state changes:
Consumer<AuthProvider>(
  builder: (context, auth, _) => auth.isAuthenticated ? HomeScreen() : LoginScreen(),
)

// Access API client:
final api = Provider.of<GeneratedApiService>(context, listen: false);
final orders = await api.listOrdersForCustomer(customerId);
```

## WebSocket / Real-time Notifications

**Implementation**: `NotificationProvider` (STOMP over WebSocket)

**Connection lifecycle**:
- Auto-connects when `AuthService.isAuthenticated && token != null`
- Auto-disconnects on logout or auth lost
- Reconnects on token change with exponential backoff

**Endpoint**: `ws://{host}/ws?token={jwt}` (auto-derived from API_BASE_URL)  
**Subscription**: `/user/queue/notifications` (user-specific queue)

**Message format**:
```json
{
  "id": 123,
  "title": "Order Update",
  "message": "Your order #456 has been delivered",
  "createdAt": "2025-12-02T10:30:00Z",
  "read": false
}
```

**Access in UI**:
```dart
final notifications = context.watch<NotificationProvider>().notifications;
final unreadCount = context.watch<NotificationProvider>().unreadCount;
final connected = context.watch<NotificationProvider>().isConnected;
```

## Testing Conventions

**Pattern**: MockClient + in-memory storage stubs

Example (`test/services/auth_service_test.dart`):
```dart
final mockClient = MockClient((req) async => http.Response(jsonEncode({...}), 200));
final storage = _InMemoryStorage(); // Stub to avoid SecureStorage dependency
final authService = AuthService(storage: storage, client: mockClient);

final result = await authService.login('user', 'pass');
expect(result.token, 'abc123');
```

**Run tests**: `flutter test`

## Common Development Tasks

### Adding a new screen
1. Create screen file in `lib/screens/<feature>/`
2. Add route constant in `routes/app_routes.dart`
3. Register route in `app.dart` routes map
4. Navigate: `Navigator.pushNamed(context, AppRoutes.newRoute)`

### Adding a new API endpoint
1. Update backend OpenAPI spec (`/v3/api-docs`)
2. Regenerate client: `curl http://localhost:8080/v3/api-docs > /tmp/openapi.json`
3. `openapi-generator-cli generate -i /tmp/openapi.json -g dart -o tms_customer_app/lib/api/generated_openapi`
4. Add wrapper method in `GeneratedApiService` if needed
5. Use via `Provider.of<GeneratedApiService>(context)`

### Adding a new provider
1. Create class extending `ChangeNotifier` in `lib/providers/`
2. Add to `MultiProvider` in `app.dart`
3. Access: `Provider.of<NewProvider>(context)` or `Consumer<NewProvider>`

### Adding translations
1. Edit `assets/lang/en.json` and `assets/lang/km.json`
2. Access in UI: `'key'.tr()` (easy_localization)
3. Hot reload to see changes

## Known Limitations & Critical Notes

- **CustomerId in login response** — Backend includes `customerId` field for CUSTOMER role users (see `CUSTOMER_ID_IMPLEMENTATION_GUIDE.md`)
- **Secure storage** — Now using `flutter_secure_storage` (Keychain/EncryptedSharedPreferences, not plaintext)
- **WebSocket URL** — Auto-derives from `API_BASE_URL` (http→ws, https→wss)
- **⚠️ Token refresh** — Implemented but not auto-invoked on 401; add retry interceptor for long sessions
- **⚠️ Registration** — `/api/auth/register` requires ADMIN role → customer signup unavailable (contact admin)
- **⚠️ Password reset** — May not exist on backend; `AuthService.requestPasswordReset()` is UI stub
- **Android emulator**: Use `10.0.2.2:8080` for localhost backend (NOT `localhost`)
- **iOS simulator**: Use `localhost:8080` or `127.0.0.1:8080`

## Troubleshooting

**Network errors on login**:
- Verify backend running at `API_BASE_URL`
- Check `lib/constants/api_constants.dart` endpoint paths
- Android emulator: ensure `10.0.2.2:8080`, not `localhost`

**Token not persisting after restart**:
- Ensure `AuthService.tryRestore()` called on app init
- Verify `WidgetsFlutterBinding.ensureInitialized()` in `main.dart`

**WebSocket not connecting**:
- Check token exists: `await authService.getToken()` returns non-null
- Verify backend WebSocket endpoint accessible
- Check backend logs for WebSocket handshake errors
- Ensure backend security config allows WebSocket upgrade

**403 Forbidden errors**:
- Verify calling `/api/customer/*` or `/api/auth/*` (NOT `/api/admin/*` or `/api/driver/*`)
- Check user has correct roles (`["USER", "CUSTOMER"]`) in login response
- Ensure `customerId` in URL matches authenticated user's customer association

**OpenAPI client errors**:
- Regenerate if backend spec changed
- Run `flutter pub get` after regenerating
- Verify `GeneratedApiService.setAuthToken(token)` called after login

## Files of Interest

- `lib/main.dart` — entry, reads `API_BASE_URL` from `String.fromEnvironment`
- `lib/app.dart` — `MultiProvider` setup, route configuration
- `lib/services/auth_service.dart` — JWT auth, login/logout, token management
- `lib/services/local_storage.dart` — FlutterSecureStorage wrapper (encrypted tokens)
- `lib/providers/notification_provider.dart` — STOMP WebSocket client, auto-derives WS URL
- `lib/services/generated_api_service.dart` — OpenAPI client wrapper
- `lib/constants/api_constants.dart` — endpoint paths, timeouts
- `lib/models/auth_models.dart` — LoginRequest, LoginResponse, UserInfo (includes customerId)
- `pubspec.yaml` — dependencies, app version (0.1.0)
- `AUTH_INTEGRATION.md` — detailed auth flow documentation
- `CUSTOMER_ID_IMPLEMENTATION_GUIDE.md` — customer ID feature details

## Quick Guide for AI Agents

**When asked to add a feature**:
1. Check if backend endpoint exists under `/api/customer/*` (NOT `/api/admin/*` or `/api/driver/*`)
2. If endpoint missing, suggest updating backend first
3. Add UI in `screens/`, state in `providers/`, API call in `services/`
4. Regenerate OpenAPI client if backend spec changed

**When fixing auth issues**:
1. Start with `lib/services/auth_service.dart`
2. Check backend logs for 401/403 errors
3. Verify token stored/retrieved from `LocalStorage` (secure storage)
4. Confirm user has correct roles/permissions

**When updating API client**:
1. Regenerate from backend `/v3/api-docs`
2. Update `GeneratedApiService` wrappers if needed
3. Run `flutter pub get`

**When adding WebSocket features**:
1. Check `NotificationProvider.connectWebSocket()` implementation
2. Verify token exists before connecting
3. Follow existing STOMP message patterns
4. Subscribe to user-specific queues (`/user/queue/*`)

**Default workflow**:
```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080  # Android
flutter test  # before committing
```

**Backend dependency**: Expects backend running with endpoints:
- `POST /api/auth/login` → `{code, message, token, refreshToken?, user}`
- `POST /api/auth/refresh` → `{token}` or `{accessToken}`
- `GET /api/customer/{customerId}/orders` → list orders
- `GET /api/customer/{customerId}/orders/{orderId}` → order detail
- `GET /api/customer/{customerId}/addresses` → addresses
- WebSocket: `ws://{host}/ws?token={jwt}` (STOMP)

Start backend from workspace root:
```bash
docker compose -f docker-compose.dev.yml up --build
# OR manually:
cd tms-backend && ./mvnw spring-boot:run
```

