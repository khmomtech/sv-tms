# Driver App - Architecture Documentation

## 📱 Application Overview

The Smart Truck Driver App is a Flutter-based mobile application for truck drivers to manage deliveries, track locations, and communicate with dispatchers.

## 🏛️ High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  (Screens, Widgets, UI Components)                      │
└────────────────┬────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────┐
│                 State Management Layer                   │
│  (Providers - Business Logic & State)                   │
└────────────────┬────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────┐
│                   Service Layer                          │
│  (API Client, Location Service, WebSocket, Firebase)    │
└────────────────┬────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────┐
│                    Data Layer                            │
│  (Models, Secure Storage, Cache)                        │
└──────────────────────────────────────────────────────────┘
```

## 🔧 Core Components

### 1. Network Layer

**Location**: `lib/core/network/`

**Components**:
- `DioClient`: Singleton HTTP client with interceptors
- `ApiConstants`: API endpoints and configuration
- `ApiResponse<T>`: Generic response wrapper
- `_AuthInterceptor`: Handles token injection and refresh

**Features**:
- Automatic token refresh on 401
- Request queueing during token refresh
- Timeout handling
- Error transformation
- Base URL synchronization

**Example Usage**:
```dart
final dio = DioClient();
final response = await dio.get<User>(
  '/api/users/me',
  converter: (data) => User.fromJson(data),
);

if (response.success) {
  final user = response.data;
  // Handle success
} else {
  // Handle error
}
```

### 2. State Management

**Pattern**: Provider

**Location**: `lib/providers/`

**Key Providers**:
- `AuthProvider`: Authentication state
- `DriverProvider`: Driver profile and status
- `DispatchProvider`: Delivery assignments
- `NotificationProvider`: Real-time notifications
- `LocationProvider`: GPS tracking
- `SettingsProvider`: App settings

**Provider Lifecycle**:
```dart
// Initialize in main.dart
MultiProvider(
  providers: AppProviders.all,
  child: MyApp(),
)

// Access in widgets
final provider = Provider.of<DriverProvider>(context);
// or
final provider = context.watch<DriverProvider>();
```

### 3. Services

**Location**: `lib/services/`

**Core Services**:

#### LocationService
- Manages GPS tracking
- Sends location updates to server
- Handles permission requests
- Battery-optimized tracking

#### FirebaseMessagingService
- Push notifications
- FCM token management
- Background message handling
- Notification routing

#### WebSocketService
- Real-time communication
- Auto-reconnection
- Message queuing
- Topic subscriptions

#### NativeServiceBridge
- Platform channel communication
- Background service control
- Battery optimization settings

### 4. Security

**Secure Storage**: `lib/core/services/secure_storage_service.dart`

**Token Management**:
- Access tokens stored in FlutterSecureStorage
- Refresh tokens encrypted
- Automatic token refresh before expiry
- Secure logout (clears all tokens)

**Data Protection**:
- TLS/HTTPS for all API calls
- Certificate pinning (production)
- No sensitive data in logs
- Encrypted local storage

### 5. Error Handling

**Exception Hierarchy**: `lib/core/exceptions/app_exceptions.dart`

```
AppException
├── NetworkException (connectivity issues)
├── AuthException (401, 403)
├── ServerException (4xx, 5xx)
├── ValidationException (invalid input)
├── CacheException (storage errors)
└── LocationException (GPS errors)
```

**Error Service**: `lib/core/services/error_handler_service.dart`
- Centralized error logging
- Sentry integration
- User-friendly error messages
- Error context tracking

## 🔄 Data Flow

### Authentication Flow
```
1. User enters credentials
2. SignInProvider validates input
3. AuthProvider calls API
4. Tokens stored in SecureStorage
5. User redirected to dashboard
6. Providers initialize with user context
```

### Location Tracking Flow
```
1. App starts → Check permissions
2. LocationService.start()
3. GPS position → DriverProvider
4. Position sent to API every 30s
5. WebSocket broadcasts to admin
6. Location displayed on admin map
```

### Notification Flow
```
1. FCM receives message
2. FirebaseMessagingService processes
3. NotificationProvider updates state
4. UI shows notification badge
5. User taps → Navigate to detail
6. Mark as read → API call
```

## 🗄️ Data Models

**Location**: `lib/models/`

**Key Models**:
- `DriverUser`: Driver profile and credentials
- `NotificationItem`: Push notification data
- `DriverIssue`: Issue reports
- `Contact`: Emergency contacts
- `Post`: Announcements
- `LocationUpdate`: GPS coordinates

**Model Guidelines**:
- Use `freezed` for immutability (future)
- Implement `fromJson` and `toJson`
- Use strong typing (no `dynamic`)
- Add validation methods

## 🎯 Feature Modules

### Dashboard
- Task list view
- Quick actions
- Statistics summary
- Notification preview

### Delivery Management
- View assigned deliveries
- Update delivery status
- Upload proof of delivery
- Digital signatures
- Real-time updates

### Location Tracking
- Background GPS tracking
- Battery optimization
- Offline queueing
- Geofencing (planned)

### Issue Reporting
- Report vehicle issues
- Photo attachments
- Status tracking
- History view

### Profile Management
- View driver info
- Update profile photo
- View assigned vehicle
- Emergency contacts

## 🔌 External Integrations

### Backend API
- **Base URL**: Configurable per environment
- **Authentication**: JWT (Bearer token)
- **Format**: JSON
- **Versioning**: `/api/v1/`

### Firebase
- **FCM**: Push notifications
- **Analytics**: Usage tracking
- **Crashlytics**: Error reporting

### Google Maps
- Route visualization
- Delivery locations
- Driver tracking map

### Sentry
- Error monitoring
- Performance tracking
- Release tracking

## 🚀 Deployment Architecture

### Environments
1. **Development** (`dev`)
   - Dev backend server
   - Debug logging enabled
   - Test FCM credentials

2. **UAT** (`uat`)
   - Staging backend
   - QA testing
   - Pre-production validation

3. **Production** (`prod`)
   - Live backend
   - Minimal logging
   - Production FCM

### Build Flavors
```bash
# Development
flutter run --flavor dev

# UAT
flutter run --flavor uat

# Production
flutter run --flavor prod --release
```

## 📊 Performance Considerations

### Memory Management
- Dispose controllers and subscriptions
- Clear cached data periodically
- Use `const` constructors
- Optimize image loading

### Network Optimization
- Pagination for large lists
- Request debouncing
- Response caching
- Offline queue

### Battery Optimization
- Adaptive location tracking
- Background service management
- Wake lock control
- Network batch operations

## 🧪 Testing Strategy

### Unit Tests
- Provider logic
- Utility functions
- Model serialization
- Validation rules

### Widget Tests
- Screen rendering
- User interactions
- Navigation flows
- Error states

### Integration Tests
- End-to-end flows
- API integration
- Offline scenarios
- Push notifications

## 🔮 Future Enhancements

- [ ] Offline-first architecture
- [ ] GraphQL integration
- [ ] Chat messaging
- [ ] Route optimization
- [ ] AR navigation
- [ ] Voice commands
- [ ] Biometric authentication
- [ ] Multi-language support expansion
