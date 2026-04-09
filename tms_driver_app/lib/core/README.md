# Core Library - Production-Ready Utilities

## 📦 New Core Components

This directory contains production-ready utilities and services for the Smart Truck Driver App.

## 🗂️ Structure

```
core/
├── constants/
│   ├── app_colors.dart          # Color palette
│   ├── app_config.dart          # ✨ NEW: App-wide configuration
│   ├── app_constants.dart       # General constants
│   ├── app_text_styles.dart     # Typography
│   └── app_theme.dart           # Theme configuration
├── exceptions/
│   └── app_exceptions.dart      # ✨ NEW: Exception hierarchy
├── mixins/
│   └── loading_state_mixin.dart # ✨ NEW: Reusable loading state
├── network/
│   ├── api_constants.dart       # API endpoints
│   ├── api_response.dart        # Response wrapper
│   └── dio_client.dart          # HTTP client with interceptors
├── services/
│   ├── error_handler_service.dart    # ✨ NEW: Centralized error handling
│   └── secure_storage_service.dart   # ✨ NEW: Encrypted storage
└── utils/
    ├── battery_optimization.dart
    ├── connectivity_service.dart     # ✨ NEW: Network monitoring
    ├── date_formatters.dart
    ├── dialog_helper.dart
    ├── extensions.dart
    ├── fcm_util.dart
    ├── image_helper.dart            # ✨ NEW: Image optimization
    ├── location_permissions.dart
    ├── logger.dart
    ├── result.dart                  # ✨ NEW: Type-safe error handling
    ├── validators.dart
    └── version_checker.dart
```

## 🚀 Quick Start

### 1. Secure Storage Service

Replace SharedPreferences for sensitive data:

```dart
import 'package:tms_tms_driver_app/core/services/secure_storage_service.dart';

final storage = SecureStorageService();

// Initialize (call once at app startup)
await storage.init();

// Save/Get tokens (encrypted)
await storage.saveAccessToken(token);
final token = await storage.getAccessToken();

// Save/Get non-sensitive data
await storage.saveDriverId(driverId);
final driverId = await storage.getDriverId();

// Logout
await storage.clearAuthData();
```

### 2. Error Handling Service

Centralized error reporting with Sentry:

```dart
import 'package:tms_tms_driver_app/core/services/error_handler_service.dart';
import 'package:tms_tms_driver_app/core/exceptions/app_exceptions.dart';

final errorHandler = ErrorHandlerService();

try {
  await riskyOperation();
} catch (e, stack) {
  await errorHandler.handleError(
    e,
    stackTrace: stack,
    context: 'UserProfile',
    extras: {'userId': userId},
  );
  
  // Get user-friendly message
  final message = errorHandler.getUserMessage(e);
  showSnackbar(message);
}
```

### 3. Result Pattern

Type-safe error handling without exceptions:

```dart
import 'package:tms_tms_driver_app/core/utils/result.dart';

// Service returns Result
Future<Result<User>> getUser(String id) async {
  try {
    final user = await api.getUser(id);
    return Success(user);
  } catch (e) {
    return Failure(e);
  }
}

// UI handles both cases
final result = await userService.getUser(id);

// Pattern matching
result.when(
  success: (user) {
    setState(() => _user = user);
  },
  failure: (error) {
    showError(error.toString());
  },
);

// Or check directly
if (result.isSuccess) {
  final user = result.valueOrNull!;
  // Use user
}
```

### 4. Loading State Mixin

Reduce boilerplate in providers:

```dart
import 'package:tms_tms_driver_app/core/mixins/loading_state_mixin.dart';

class UserProvider with ChangeNotifier, LoadingStateMixin {
  User? _user;
  
  User? get user => _user;
  // isLoading, hasError, errorMessage are from mixin

  Future<void> loadUser(String id) async {
    await executeWithLoading(
      () async {
        _user = await userService.getUser(id);
        notifyListeners();
      },
      onError: (error) {
        print('Failed to load user: $error');
      },
    );
  }
}

// In UI
Consumer<UserProvider>(
  builder: (context, provider, _) {
    if (provider.isLoading) return LoadingIndicator();
    if (provider.hasError) return ErrorWidget(provider.errorMessage);
    return UserProfile(provider.user);
  },
)
```

### 5. Image Helper

Optimize images before upload:

```dart
import 'package:tms_tms_driver_app/core/utils/image_helper.dart';

// Validate image
final error = await ImageHelper.validateImage(imageFile);
if (error != null) {
  showSnackbar(error);
  return;
}

// Compress image
final compressed = await ImageHelper.compressImage(
  imageFile,
  quality: 85,
  maxWidth: 1920,
);

// Upload compressed file
await uploadImage(compressed);

// Batch compress
final files = [image1, image2, image3];
final compressed = await ImageHelper.compressMultiple(files);
```

### 6. Connectivity Service

Monitor network status:

```dart
import 'package:tms_tms_driver_app/core/utils/connectivity_service.dart';

final connectivity = ConnectivityService();

// Initialize once at startup
await connectivity.initialize();

// Check current status
if (!connectivity.isConnected) {
  showOfflineWarning();
}

// Listen to changes
connectivity.connectionStatus.listen((isConnected) {
  if (isConnected) {
    syncOfflineData();
  } else {
    showOfflineBanner();
  }
});

// Get connection type
final type = connectivity.getConnectionType(); // "WiFi", "Mobile", etc.
```

### 7. App Configuration

Centralized constants:

```dart
import 'package:tms_tms_driver_app/core/constants/app_config.dart';

// Use configuration constants
final timeout = AppConfig.apiTimeout;
final maxRetries = AppConfig.maxRetryAttempts;
final pageSize = AppConfig.defaultPageSize;

// Validate
if (password.length < AppConfig.minPasswordLength) {
  return 'Password too short';
}

// Feature flags
if (AppConfig.enableAnalytics) {
  logEvent('user_action');
}
```

## 🎯 Exception Types

Use specific exceptions for better error handling:

```dart
import 'package:tms_tms_driver_app/core/exceptions/app_exceptions.dart';

// Network errors
throw NetworkException('Connection failed');

// Auth errors
throw AuthException('Invalid credentials', code: 'INVALID_LOGIN');

// Server errors
throw ServerException('Server error', statusCode: 500);

// Validation errors
throw ValidationException(
  'Validation failed',
  fieldErrors: {'email': 'Invalid format'},
);

// Location errors
throw LocationException('GPS unavailable');

// Cache errors
throw CacheException('Failed to save data');
```

## 📋 Best Practices

### DO ✅
- Use `SecureStorageService` for tokens
- Handle errors with try-catch and specific exceptions
- Use `Result<T>` for fallible operations
- Apply `LoadingStateMixin` to providers
- Compress images before upload
- Monitor connectivity status
- Use constants from `AppConfig`
- Report errors with `ErrorHandlerService`

### DON'T ❌
- Store tokens in `SharedPreferences`
- Use generic `Exception` or `dynamic`
- Throw exceptions in UI layer
- Duplicate loading state logic
- Upload large uncompressed images
- Assume network is always available
- Hardcode configuration values
- Swallow errors silently

## 📚 Documentation

- [CODE_QUALITY_STANDARDS.md](../CODE_QUALITY_STANDARDS.md) - Full coding guidelines
- [ARCHITECTURE.md](../ARCHITECTURE.md) - Architecture documentation
- [MIGRATION_SUMMARY.md](../MIGRATION_SUMMARY.md) - Migration guide

## 🔄 Migration Path

Gradually adopt these improvements:

1. **Phase 1**: Critical (Security)
   - [ ] Migrate to `SecureStorageService`
   - [ ] Update login/logout flows
   - [ ] Test token refresh

2. **Phase 2**: Reliability
   - [ ] Add `ErrorHandlerService`
   - [ ] Configure Sentry
   - [ ] Apply exception types

3. **Phase 3**: Quality
   - [ ] Add `LoadingStateMixin` to providers
   - [ ] Use `ImageHelper` for uploads
   - [ ] Initialize `ConnectivityService`

4. **Phase 4**: Optimization
   - [ ] Apply `Result` pattern
   - [ ] Refactor with constants
   - [ ] Fix style warnings

## 🆘 Support

For questions or issues with core utilities:
1. Check documentation in this folder
2. Review code examples above
3. See [ARCHITECTURE.md](../ARCHITECTURE.md) for context
4. Consult [CODE_QUALITY_STANDARDS.md](../CODE_QUALITY_STANDARDS.md)
